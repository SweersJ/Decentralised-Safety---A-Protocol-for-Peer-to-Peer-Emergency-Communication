#!/usr/bin/env python3
"""quint_runner.py – GUI for Quint verifications, tests, and simulations.

Usage:
    python quint_runner.py [path/to/spec.qnt]
"""

import json
import os
import queue
import re
import shlex
import socket
import platform
import subprocess
import tempfile
import threading
from datetime import datetime
from pathlib import Path
from typing import Callable
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# ─── paths ──────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).parent.resolve()
VERIFY_CMD = SCRIPT_DIR / "verify.cmd"
APALACHE_DEFAULT_PORT = 8822


def _next_available_port(start: int = APALACHE_DEFAULT_PORT) -> int:
    """Return the first TCP port available for an Apalache server."""
    for port in range(start, 65536):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            try:
                sock.bind(("127.0.0.1", port))
            except OSError:
                continue
            return port
    raise RuntimeError(f"No available TCP port found from {start} onward")


def _apalache_env() -> dict[str, str]:
    """Build an environment that directs verify.cmd to a free server port."""
    env = os.environ.copy()
    env["PORT"] = str(_next_available_port())
    return env

# ─── parsing ────────────────────────────────────────────────────────────────

# Match declarations whose body starts on the next line, plus inline test bodies
# written as `run testName = all {`. Limit indentation to exclude action-local vals.
_DECL_RE = re.compile(
    r"^[ \t]{0,8}(val|temporal)\s+(\w+)\s*=\s*$"
    r"|^[ \t]{0,8}(run)\s+(\w+)\s*=\s*(?:all\s*\{\s*)?$",
    re.MULTILINE,
)

# Quint file imports use a relative source after `from`, for example:
# `import helpers.* from "./helpers"`. The extension is conventionally omitted.
_IMPORT_SOURCE_RE = re.compile(
    r"^[ \t]*(?:import|export)\b.*?\bfrom\s+[''\"]([^''\"]+)[''\"]",
    re.MULTILINE | re.DOTALL,
)
# val names starting with `can_` are witnesses; all other vals are safety invariants.
_INSTANTIATED_IMPORT_RE = re.compile(
    r"^[ \t]*import\s+(\w+)\s*\(.*?\)\s*\.\*\s+from\s+['\"]([^'\"]+)['\"]",
    re.MULTILINE | re.DOTALL,
)
_WITNESS_RE = re.compile(r"^can_")

# Hide machine-specific WSL prefixes in command output.
_WSL_THESIS_REPO_RE = re.compile(
    r"(?<![\.\w.-])/mnt/c(?:/[^/\r\n]+)*/thesis_repo(?=/|\s|$)",
    re.IGNORECASE,
)
# SCRIPT_DIR is formal_verification/; two parents up is the thesis_repo root.
_WIN_THESIS_REPO_RE = re.compile(re.escape(str(SCRIPT_DIR.parent.parent)), re.IGNORECASE)

# Hide the OS temp directory (e.g. C:\Users\<user>\AppData\Local\Temp).
_TEMP_DIR_RE = re.compile(re.escape(tempfile.gettempdir()), re.IGNORECASE)

# Hide the user home directory (C:\Users\<user> or C:/Users/<user>).
_HOME_DIR_RE = re.compile(
    re.escape(str(Path.home())).replace(r"\/", r"[/\\]").replace("/", r"[/\\]").replace("\\\\", r"[/\\]"),
    re.IGNORECASE,
)

_QUINT_JAR_HOME_RE = re.compile(r"jar:file:/home/[^/\r\n]+/\.quint(?=/|\s|$)")


def _shorten_log_paths(text: str) -> str:
    text = _QUINT_JAR_HOME_RE.sub("jar:file:/~/.quint", text)
    text = _WSL_THESIS_REPO_RE.sub("...", text)
    text = _WIN_THESIS_REPO_RE.sub("...", text)
    text = _TEMP_DIR_RE.sub("<tmp>", text)
    text = _HOME_DIR_RE.sub("...", text)
    return text

_CATEGORIES: dict[str, dict] = {
    "tests":    {"label": "Tests",              "folder": "tests"},
    "safety":   {"label": "Safety (invariant)", "folder": "safety"},
    "witness":  {"label": "Witness",            "folder": "witness"},
    "liveness": {"label": "Liveness (temporal)", "folder": "liveness"},
    "fairness": {"label": "Fairness diagnostic", "folder": "fairness"},
}


def _imported_qnt_paths(path: Path, text: str) -> list[Path]:
    """Return existing local Quint files imported directly by *path*."""
    imported: list[Path] = []
    for match in _IMPORT_SOURCE_RE.finditer(text):
        source = Path(match.group(1))
        candidate = source if source.is_absolute() else path.parent / source
        if candidate.suffix == "":
            candidate = candidate.with_suffix(".qnt")
        candidate = candidate.resolve()
        if candidate.is_file():
            imported.append(candidate)
    return imported


def parse_qnt(path: Path) -> dict[str, list[str]]:
    """Collect runnable declarations from a file and all its transitive imports."""
    seen: set[str] = set()
    visited: set[Path] = set()
    groups: dict[str, list[str]] = {k: [] for k in _CATEGORIES}

    def visit(current: Path) -> None:
        current = current.resolve()
        if current in visited:
            return
        visited.add(current)
        text = current.read_text(encoding="utf-8")

        # Keep declarations in selected-file-first, import-discovery order.
        for m in _DECL_RE.finditer(text):
            kind, name = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
            if name in seen:
                continue
            seen.add(name)
            if kind == "run":
                groups["tests"].append(name)
            elif kind == "temporal":
                target = "fairness" if name.endswith("_fairness") else "liveness"
                groups[target].append(name)
            else:  # val
                target = "witness" if _WITNESS_RE.match(name) else "safety"
                groups[target].append(name)

        for imported_path in _imported_qnt_paths(current, text):
            visit(imported_path)

    visit(path)
    return groups


def _instantiated_imports(path: Path) -> list[tuple[str, Path]]:
    """Return direct parameterized imports as (instance name, source path)."""
    imports: list[tuple[str, Path]] = []
    for match in _INSTANTIATED_IMPORT_RE.finditer(path.read_text(encoding="utf-8")):
        source = Path(match.group(2))
        candidate = source if source.is_absolute() else path.parent / source
        if candidate.suffix == "":
            candidate = candidate.with_suffix(".qnt")
        candidate = candidate.resolve()
        if candidate.is_file():
            imports.append((match.group(1), candidate))
    return imports


# ─── syntax highlighting (from quint-vscode-highlighting grammar) ───────────────────

_GRAMMAR_PATH = (SCRIPT_DIR / "quint-vscode-highlighting" / "syntaxes"
                 / "quint.tmLanguage.json")

# TextMate scope prefix → tkinter tag name (more-specific prefixes must come first)
_SCOPE_TAG: dict[str, str] = {
    "keyword.control":         "kw",
    "keyword.operator":        "operator",
    "keyword.other":           "kw",
    "storage.type":            "kw",
    "support.function":        "function",
    "support.type":            "type_name",
    "support.constant":        "type_name",   # Int, Nat, Bool
    "constant.language":       "constant",    # true, false
    "constant.numeric":        "number",
    "constant.other":          "constant",    # ALL_CAPS identifiers like ALICE
    "entity.name.type":        "type_name",
    "entity.name.namespace":   "namespace",
    "variable.other.primed":   "primed",
    "variable.other.property": "property",
    "variable.language":       "variable",    # wildcard _
    "punctuation":             "operator",
    "comment":                 "comment",
}


def _scope_to_tag(name: str) -> str | None:
    for prefix, tag in _SCOPE_TAG.items():
        if name.startswith(prefix):
            return tag
    return None


def _collect_grammar_patterns() -> tuple[
    list[tuple[re.Pattern, str]],
    list[tuple[re.Pattern, re.Pattern, str]],
]:
    """Parse tmLanguage.json into (line-match patterns, begin/end block patterns)."""
    line_pats: list[tuple[re.Pattern, str]] = []
    block_pats: list[tuple[re.Pattern, re.Pattern, str]] = []

    def _extract(node: dict) -> None:
        name = node.get("name", "")
        tag = _scope_to_tag(name)
        if "match" in node and tag:
            try:
                line_pats.append((re.compile(node["match"]), tag))
            except re.error:
                pass
        elif "begin" in node and "end" in node and tag:
            # strings are handled separately with an escape-aware line regex
            # MULTILINE on end so `$\n?` (line-comment end) works per-line
            if tag != "string":
                try:
                    block_pats.append((
                        re.compile(node["begin"]),
                        re.compile(node["end"], re.MULTILINE),
                        tag,
                    ))
                except re.error:
                    pass
        for sub in node.get("patterns", []):
            _extract(sub)

    if _GRAMMAR_PATH.exists():
        try:
            grammar = json.loads(_GRAMMAR_PATH.read_text(encoding="utf-8"))
            repo = grammar.get("repository", {})
            for ref in grammar.get("patterns", []):
                key = ref.get("include", "#")[1:]
                if key in repo:
                    _extract(repo[key])
        except Exception:
            pass

    if not line_pats:  # fallback when grammar file is unavailable
        line_pats = [
            (re.compile(r'\b(module|import|from|export|as|if|else|not|or|and|implies|iff|'
                        r'all|any|leadsTo|type|assume|const|var|val|nondet|def|pure|action|'
                        r'temporal|run|Tup|Rec|Set|List|int|str|bool)\b'), "kw"),
            (re.compile(r'\b(false|true|Bool|Int|Nat)\b'), "constant"),
            (re.compile(r'//.*$'), "comment"),
            (re.compile(r'\b\d+\b'), "number"),
        ]

    # escape-aware string regex added regardless of grammar source
    line_pats.append((re.compile(r'"[^"\n\\]*(?:\\.[^"\n\\]*)*"'), "string"))
    return line_pats, block_pats


_LINE_PATS, _BLOCK_PATS = _collect_grammar_patterns()


# ─── TLA+ syntax highlighting ────────────────────────────────────────────────

# Tag colours for the TLA+ viewer (configured low-priority first in _open_viewer_window)
_TLA_TAG_COLORS: list[tuple[str, str]] = [
    ("tla_function",   "#dcdcaa"),  # operator/function names
    ("tla_definition", "#4ec9b0"),  # names being defined  (word ==)
    ("tla_operator",   "#d7ba7d"),  # embedded \land, etc.
    ("tla_temporal",   "#d7ba7d"),  # [] <> ~>
    ("tla_kw",         "#569cd6"),  # EXTENDS, VARIABLES, …
    ("tla_ctrl",       "#c586c0"),  # IF THEN ELSE CASE OTHER
    ("tla_primed",     "#9cdcfe"),  # x'
    ("tla_constant",   "#4fc1ff"),  # TRUE FALSE
    ("tla_number",     "#b5cea8"),
    ("tla_string",     "#ce9178"),
    ("tla_comment",    "#6a9955"),  # highest priority – overrides everything
]

# Line-match patterns applied in order (later entries override earlier)
_TLA_LINE_PATS: list[tuple[re.Pattern, str]] = [
    (re.compile(
        r'\b(?:EXTENDS|VARIABLES?|CONSTANTS?|LET|IN|EXCEPT|ENABLED|UNCHANGED|'
        r'LAMBDA|DOMAIN|CHOOSE|LOCAL|ASSUME|ASSUMPTION|AXIOM|RECURSIVE|INSTANCE|'
        r'WITH|THEOREM|SUBSET|UNION|SF_|WF_|USE|DEFS|BY|DEF|SUFFICES|PROVE|'
        r'OBVIOUS|NEW|QED|PICK|HIDE|DEFINE|WITNESS|HAVE|TAKE|PROOF|ACTION|'
        r'COROLLARY|LEMMA|OMITTED|ONLY|PROPOSITION|STATE|TEMPORAL)\b'
    ), "tla_kw"),
    (re.compile(r'\b(?:IF|THEN|ELSE|CASE|OTHER)\b'), "tla_ctrl"),
    (re.compile(r'\b(?:TRUE|FALSE)\b'), "tla_constant"),
    (re.compile(
        r'\\(?:land|lor|lnot|neg|equiv|implies|iff|in|notin|subseteq|supseteq|'
        r'union|intersect|cup|cap|leq|geq|forall|exists|times|div|cdot|star|'
        r'circ|oplus|ominus|otimes|bullet|[a-zA-Z]+)\b'
    ), "tla_operator"),
    (re.compile(r'\[\]|<>|~>'), "tla_temporal"),
    (re.compile(r"\b\w+'"), "tla_primed"),
    # definition name: word before == (not ===)
    (re.compile(r'\b\w+(?=\s*==(?!=))'), "tla_definition"),
    # operator/function call: word before (
    (re.compile(r'\b\w+(?=\s*\()'), "tla_function"),
    (re.compile(r'\b\d+\b'), "tla_number"),
    # strings override keywords that fall inside them
    (re.compile(r'"[^"\\]*(?:\\.[^"\\]*)*"'), "tla_string"),
    # line comment: \* to end of line (highest priority, applied last)
    (re.compile(r'\\\*.*$'), "tla_comment"),
]


def _highlight_tla(widget: tk.Text, lines: list[str]) -> None:
    """Apply TLA+ syntax highlighting."""
    full_text = "\n".join(lines)

    # Block comments (* ... *) – span multiple lines
    for m in re.finditer(r'\(\*.*?\*\)', full_text, re.DOTALL):
        sl = full_text.count("\n", 0, m.start()) + 1
        sc = m.start() - (full_text.rfind("\n", 0, m.start()) + 1)
        el = full_text.count("\n", 0, m.end()) + 1
        ec = m.end() - (full_text.rfind("\n", 0, m.end()) + 1)
        widget.tag_add("tla_comment", f"{sl}.{sc}", f"{el}.{ec}")

    for i, line in enumerate(lines, 1):
        # Separator lines ----+ / ====+
        if re.match(r'^[\-=]{4,}\s*$', line):
            widget.tag_add("tla_comment", f"{i}.0", f"{i}.end")
            continue
        for pat, tag in _TLA_LINE_PATS:
            for m in pat.finditer(line):
                widget.tag_add(tag, f"{i}.{m.start()}", f"{i}.{m.end()}")


def _highlight_qnt(widget: tk.Text, lines: list[str]) -> None:
    """Apply Quint syntax highlighting from the loaded grammar patterns."""
    # block patterns (/* ... */ comments) require full-text span tracking
    full_text = "\n".join(lines)
    for begin_re, end_re, tag in _BLOCK_PATS:
        pos = 0
        while pos < len(full_text):
            bm = begin_re.search(full_text, pos)
            if not bm:
                break
            em = end_re.search(full_text, bm.end())
            end_idx = em.end() if em else len(full_text)
            sl = full_text.count("\n", 0, bm.start()) + 1
            sc = bm.start() - (full_text.rfind("\n", 0, bm.start()) + 1)
            el = full_text.count("\n", 0, end_idx) + 1
            ec = end_idx - (full_text.rfind("\n", 0, end_idx) + 1)
            widget.tag_add(tag, f"{sl}.{sc}", f"{el}.{ec}")
            pos = end_idx

    # line-match patterns; comment/string patterns come last in _LINE_PATS
    # so they overwrite keywords/numbers that fall inside them
    for i, line in enumerate(lines, 1):
        for pat, tag in _LINE_PATS:
            for m in pat.finditer(line):
                widget.tag_add(tag, f"{i}.{m.start()}", f"{i}.{m.end()}")


# ─── command building ────────────────────────────────────────────────────────

def _verify_base(qnt: Path, opts: dict) -> list[str]:
    """Return the base quint verify invocation, using verify.cmd on Windows when available."""
    if platform.system() == "Windows" and VERIFY_CMD.exists():
        return ["cmd", "/c", str(VERIFY_CMD), str(qnt)]
    return ["quint", "verify", str(qnt)]


def build_command(
    qnt: Path,
    effective_cat: str,
    name: str,
    out_file: Path,
    opts: dict,
) -> list[str]:
    """
    effective_cat: 'tests' | 'safety_run' | 'safety_verify' | 'witness' | 'liveness' | 'fairness'
    out_file: .itf.json for run/test commands, .log path for verify (captured separately).
    """
    run_flags: list[str] = []
    if opts.get("mbt"):
        run_flags.append("--mbt")
    if opts.get("seed", "").strip():
        run_flags += ["--seed", opts["seed"].strip()]
    if opts.get("max_steps", "").strip():
        run_flags += ["--max-steps", opts["max_steps"].strip()]

    if effective_cat == "tests":
        return ["quint", "test", str(qnt), "--match", re.escape(name),
                "--out-itf", str(out_file)]

    if effective_cat == "safety_run":
        return ["quint", "run", str(qnt), "--invariant", name,
                "--out-itf", str(out_file)] + run_flags

    if effective_cat == "witness":
        return ["quint", "run", str(qnt), "--witnesses", name,
                "--out-itf", str(out_file)] + run_flags

    # verify-based categories; --out-itf saves the counterexample trace if supported
    flag_map = {"safety_verify": "--invariant", "liveness": "--temporal",
                "fairness": "--temporal"}
    cmd = _verify_base(qnt, opts) + [flag_map[effective_cat], name,
                                      "--out-itf", str(out_file)]
    if opts.get("backend") == "tlc":
        cmd += ["--backend", "tlc"]
    # --keep-server only understood by verify.cmd wrapper
    if platform.system() == "Windows" and VERIFY_CMD.exists() and opts.get("keep_server"):
        cmd.append("--keep-server")
    if platform.system() == "Windows" and VERIFY_CMD.exists():
        cmd.append("--close-terminal")
    return cmd


def _determine_status(returncode: int, output: str) -> str:
    """Classify a run result as 'ok', 'violation', or 'error'."""
    lower = output.lower()
    # Temporal verification can emit its successful result while a wrapper exits
    # non-zero. Prefer Quint's explicit verdict over that wrapper exit code.
    if re.search(r"\[ok\]\s+no violation found\b", lower):
        return "ok"
    if returncode == 0:
        return "ok"
    if (any(kw in lower for kw in ("violated", "counterexample",
                                    "invariant not", "failed", "assertion"))
            or ("violation" in lower and "no violation" not in lower)):
        return "violation"
    return "error"


def _expected_status(category: str, status: str) -> str:
    """Interpret a raw verifier result according to the category expectation."""
    if category != "fairness" or status == "error":
        return status
    # A standalone fairness diagnostic succeeds when it exposes an unfair trace.
    return "ok" if status == "violation" else "violation"


# ─── GUI ─────────────────────────────────────────────────────────────────────

class QuintRunner(tk.Tk):
    def __init__(self, initial_file: str | None = None) -> None:
        super().__init__()
        self.title("Quint Runner")
        self.minsize(980, 720)

        self._qnt_path: Path | None = None
        self._groups: dict[str, list[str]] = {}
        self._checks: dict[str, dict[str, tk.BooleanVar]] = {}
        self._status: dict[tuple[str, str], str] = {}
        self._status_labels: dict[tuple[str, str], tk.Label] = {}
        self._date_labels: dict[tuple[str, str], tk.Label] = {}
        self._last_files: dict[tuple[str, str], Path | None] = {}
        self._log_queue: queue.Queue[tuple[str, str | None]] = queue.Queue()
        self._ui_queue: queue.Queue[Callable[[], None]] = queue.Queue()
        self._running = False
        self._file_viewer: tk.Toplevel | None = None
        self._compiled_file_viewer: tk.Toplevel | None = None

        self._build_ui()
        self._setup_scroll_routing()
        self._poll_log()

        if initial_file:
            self.file_var.set(initial_file)
            self._scan()

    # ── UI construction ───────────────────────────────────────────────────────

    def _build_ui(self) -> None:
        ttk.Style(self).theme_use("clam")

        # file + config row
        top = ttk.Frame(self, padding=6)
        top.pack(fill="x", padx=8, pady=(8, 0))

        file_frame = ttk.Frame(top)
        file_frame.pack(fill="x")
        ttk.Label(file_frame, text="Quint file:").pack(side="left")
        self.file_var = tk.StringVar()
        ttk.Entry(file_frame, textvariable=self.file_var, width=60).pack(
            side="left", padx=4, fill="x", expand=True)
        ttk.Button(file_frame, text="Browse…", command=self._browse).pack(side="left", padx=2)
        ttk.Button(file_frame, text="Scan", command=self._scan).pack(side="left", padx=2)

        cfg_frame = ttk.Frame(top)
        cfg_frame.pack(fill="x", pady=(4, 0))
        ttk.Button(cfg_frame, text="Import config", command=self._import_config).pack(side="left", padx=2)
        ttk.Button(cfg_frame, text="Export config", command=self._export_config).pack(side="left", padx=2)
        self._instantiated_imports_frame = ttk.LabelFrame(
            top, text="Instantiated imports", padding=4)

        # Vertically split the controls from output; the controls retain their
        # own horizontal declaration/options split.
        main_paned = ttk.PanedWindow(self, orient="vertical")
        main_paned.pack(fill="both", expand=True, padx=8, pady=(6, 8))

        paned = ttk.PanedWindow(main_paned, orient="horizontal")
        main_paned.add(paned, weight=3)

        self._build_declarations_panel(paned)
        self._build_options_panel(paned)

        # output
        out_frame = ttk.LabelFrame(main_paned, text="Output", padding=4)
        main_paned.add(out_frame, weight=2)
        btn_row = ttk.Frame(out_frame)
        btn_row.pack(fill="x", pady=(0, 4))
        ttk.Button(btn_row, text="View file", command=self._open_file_viewer).pack(side="left", padx=2)
        ttk.Button(btn_row, text="View compiled file", command=self._open_compiled_file_viewer).pack(side="left", padx=2)
        ttk.Button(btn_row, text="Clear", command=self._log_clear).pack(side="right", padx=2)

        out_inner = ttk.Frame(out_frame)
        out_inner.pack(fill="both", expand=True)
        out_sb = ttk.Scrollbar(out_inner, orient="vertical")
        out_sb.pack(side="right", fill="y")
        self.output_text = tk.Text(
            out_inner, height=10, font=("Consolas", 9), state="disabled",
            wrap="word", bg="#1e1e1e", fg="#d4d4d4",
            insertbackground="white", selectbackground="#264f78",
            yscrollcommand=out_sb.set,
        )
        out_sb.configure(command=self.output_text.yview)
        self.output_text.pack(side="left", fill="both", expand=True)

        self.output_text.tag_configure("cmd",  foreground="#4ec9b0")  # command lines
        self.output_text.tag_configure("ok",   foreground="#4caf50")  # success
        self.output_text.tag_configure("err",  foreground="#f44336")  # error
        self.output_text.tag_configure("info", foreground="#9cdcfe")  # info
        self.output_text.tag_configure("warn", foreground="#dcdcaa")  # warning

    def _build_declarations_panel(self, paned: ttk.PanedWindow) -> None:
        left = ttk.LabelFrame(paned, text="Declarations", padding=4)
        paned.add(left, weight=3)

        canvas = tk.Canvas(left, highlightthickness=0)
        self._decl_canvas = canvas
        sb = ttk.Scrollbar(left, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=sb.set)
        sb.pack(side="right", fill="y")
        canvas.pack(fill="both", expand=True)
        self._inner = ttk.Frame(canvas)
        win_id = canvas.create_window((0, 0), window=self._inner, anchor="nw")
        self._inner.bind("<Configure>", lambda e: canvas.configure(
            scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", lambda e: canvas.itemconfig(win_id, width=e.width))
        btn_row = ttk.Frame(left)
        btn_row.pack(fill="x", pady=(4, 0))
        ttk.Button(btn_row, text="Select all",
                   command=lambda: self._set_all(True)).pack(side="left", padx=2)
        ttk.Button(btn_row, text="Deselect all",
                   command=lambda: self._set_all(False)).pack(side="left", padx=2)

    def _build_options_panel(self, paned: ttk.PanedWindow) -> None:
        right = ttk.Frame(paned, padding=4)
        paned.add(right, weight=2)

        nb = ttk.Notebook(right)
        nb.pack(fill="both", expand=True)

        # ── quint run tab ──────────────────────────────────────────────────
        run_tab = ttk.Frame(nb, padding=10)
        nb.add(run_tab, text="quint run")

        self.opt_mbt = tk.BooleanVar()
        ttk.Checkbutton(run_tab, text="--mbt  (model-based testing)",
                        variable=self.opt_mbt).grid(
            row=0, column=0, columnspan=2, sticky="w", pady=2)

        ttk.Label(run_tab, text="--seed").grid(row=1, column=0, sticky="w", pady=3)
        self.opt_seed = tk.StringVar()
        ttk.Entry(run_tab, textvariable=self.opt_seed, width=14).grid(
            row=1, column=1, sticky="w", padx=6)

        ttk.Label(run_tab, text="--max-steps").grid(row=2, column=0, sticky="w", pady=3)
        self.opt_max_steps = tk.StringVar()
        ttk.Entry(run_tab, textvariable=self.opt_max_steps, width=14).grid(
            row=2, column=1, sticky="w", padx=6)

        ttk.Separator(run_tab, orient="horizontal").grid(
            row=3, column=0, columnspan=2, sticky="ew", pady=10)
        ttk.Label(run_tab, text="Safety invariants – run with:").grid(
            row=4, column=0, columnspan=2, sticky="w")
        self.opt_safety_cmd = tk.StringVar(value="run")
        ttk.Radiobutton(run_tab, text="quint run --invariant  (simulation)",
                        variable=self.opt_safety_cmd, value="run").grid(
            row=5, column=0, columnspan=2, sticky="w")
        ttk.Radiobutton(run_tab, text="quint verify --invariant  (formal)",
                        variable=self.opt_safety_cmd, value="verify").grid(
            row=6, column=0, columnspan=2, sticky="w")

        self.opt_combined_invariants = tk.BooleanVar()
        ttk.Checkbutton(
            run_tab,
            text="Run selected invariants together (--invariants)",
            variable=self.opt_combined_invariants,
        ).grid(row=7, column=0, columnspan=2, sticky="w", pady=(8, 0))

        # ── quint verify tab ───────────────────────────────────────────────
        verify_tab = ttk.Frame(nb, padding=10)
        nb.add(verify_tab, text="quint verify")

        ttk.Label(verify_tab, text="--backend").grid(
            row=0, column=0, sticky="w", pady=2)
        self.opt_backend = tk.StringVar(value="apalache")
        ttk.Radiobutton(verify_tab, text="apalache  (default)",
                        variable=self.opt_backend, value="apalache").grid(
            row=1, column=0, columnspan=2, sticky="w")
        ttk.Radiobutton(verify_tab, text="tlc  (supports temporal properties)",
                        variable=self.opt_backend, value="tlc").grid(
            row=2, column=0, columnspan=2, sticky="w")

        self.opt_keep_server = tk.BooleanVar()
        ttk.Checkbutton(verify_tab, text="--keep-server  (Windows / verify.cmd only)",
                        variable=self.opt_keep_server).grid(
            row=3, column=0, columnspan=2, sticky="w", pady=6)

        ttk.Label(verify_tab,
                  text="Liveness properties always use quint verify.",
                  foreground="gray").grid(row=4, column=0, columnspan=2, sticky="w")

        # ── run button ─────────────────────────────────────────────────────
        self.run_btn = ttk.Button(right, text=">>  Run selected", command=self._run_selected)
        self.run_btn.pack(fill="x", padx=4, pady=10)

    def _setup_scroll_routing(self) -> None:
        """Scroll only the pane whose bounding box contains the mouse pointer."""
        def _is_descendant(widget: tk.Misc | None, ancestor: tk.Misc) -> bool:
            while widget is not None:
                if widget is ancestor:
                    return True
                widget = getattr(widget, "master", None)
            return False

        def _route(e: tk.Event) -> str | None:
            hovered = self.winfo_containing(e.x_root, e.y_root)
            if hovered is None:
                return None

            if e.delta:
                delta = -1 if e.delta > 0 else 1
            else:
                delta = -1 if e.num == 4 else 1

            if _is_descendant(hovered, self._decl_canvas):
                self._decl_canvas.yview_scroll(delta, "units")
                return "break"
            if _is_descendant(hovered, self.output_text):
                self.output_text.yview_scroll(delta, "units")
                return "break"
            return None

        self.bind_all("<MouseWheel>", _route)
        self.bind_all("<Button-4>",   _route)
        self.bind_all("<Button-5>",   _route)

    # ── file handling ─────────────────────────────────────────────────────────

    def _browse(self) -> None:
        path = filedialog.askopenfilename(
            title="Select Quint file",
            filetypes=[("Quint files", "*.qnt"), ("All files", "*.*")])
        if path:
            self.file_var.set(path)

    def _scan(self) -> None:
        raw = self.file_var.get().strip()
        if not raw:
            messagebox.showwarning("No file", "Please select a .qnt file first.")
            return
        p = Path(raw)
        if not p.exists():
            messagebox.showerror("File not found", f"Cannot find:\n{p}")
            return
        self._qnt_path = p
        self._groups = parse_qnt(p)
        self._populate_declarations()
        self._populate_instantiated_imports()
        total = sum(len(v) for v in self._groups.values())
        self._log(f"Scanned {p.name}: {total} declarations found.\n", "info")

    def _populate_instantiated_imports(self) -> None:
        for child in self._instantiated_imports_frame.winfo_children():
            child.destroy()
        self._instantiated_imports_frame.pack_forget()
        imports = _instantiated_imports(self._qnt_path) if self._qnt_path else []
        if not imports:
            return
        self._instantiated_imports_frame.pack(fill="x", pady=(4, 0))
        for instance_name, source_path in imports:
            row = ttk.Frame(self._instantiated_imports_frame)
            row.pack(fill="x", pady=1)
            ttk.Label(row, text=f"{instance_name} → {source_path.name}").pack(
                side="left", fill="x", expand=True)
            ttk.Button(
                row, text="Compile",
                command=lambda name=instance_name:
                    self._open_compiled_file_viewer(name),
            ).pack(side="right", padx=2)

    # ── declaration checkboxes ────────────────────────────────────────────────

    _SECTION_LABELS = {
        "tests":    "Tests  →  quint test --match",
        "safety":   "Safety  →  quint run --invariant  /  quint verify --invariant",
        "witness":  "Witness  →  quint run --witnesses",
        "liveness": "Liveness  →  quint verify --temporal",
        "fairness": "Fairness diagnostics (counterexample expected)  →  quint verify --temporal",
    }

    _STATUS_ICON:  dict[str, str]  = {"ok": "[ok]", "violation": "[!]", "error": "[x]", "unknown": "[?]"}
    _STATUS_COLOR: dict[str, str]  = {"ok": "#4caf50", "violation": "#ff9800", "error": "#f44336", "unknown": "#858585"}

    def _last_result_for(self, cat: str, name: str) -> tuple[str, str | None, Path | None]:
        """Return (status, datetime_str, file_path) from the most recent output file."""
        if not self._qnt_path:
            return "unknown", None, None
        folder = _CATEGORIES[cat]["folder"]
        out_dir = self._qnt_path.parent / "output" / folder / name
        if not out_dir.is_dir():
            return "unknown", None, None
        files = sorted(
            [f for f in out_dir.iterdir() if f.suffix in (".json", ".log")],
            key=lambda f: f.name,
        )
        if not files:
            return "unknown", None, None
        last = files[-1]
        m = re.match(r'^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})', last.name)
        dt_str = f"{m.group(1)}-{m.group(2)}-{m.group(3)} {m.group(4)}:{m.group(5)}" if m else None
        status = "unknown"
        try:
            if last.suffix == ".json":
                data = json.loads(last.read_text(encoding="utf-8"))
                meta_status = data.get("#meta", {}).get("status", "")
                if meta_status == "ok":
                    status = "ok"
                elif meta_status:
                    status = "violation"
            elif last.suffix == ".log":
                content = last.read_text(encoding="utf-8")
                lower = content.lower()
                if (any(kw in lower for kw in ("violated", "counterexample",
                                                "invariant not", "assertion"))
                        or ("violation" in lower and "no violation" not in lower)):
                    status = "violation"
                elif any(kw in lower for kw in ("[ok]", "no error", "verified", "the outcome is ok")):
                    status = "ok"
                elif "error" in lower or "exception" in lower:
                    status = "error"
        except Exception:
            pass
        return _expected_status(cat, status), dt_str, last

    def _populate_declarations(self) -> None:
        for w in self._inner.winfo_children():
            w.destroy()
        self._checks.clear()
        self._status_labels.clear()
        self._date_labels.clear()
        self._last_files.clear()

        for cat, label in self._SECTION_LABELS.items():
            names = self._groups.get(cat, [])
            if not names:
                continue
            section = ttk.LabelFrame(self._inner, padding=6)
            section.pack(fill="x", padx=4, pady=4)
            self._checks[cat] = {}

            header = ttk.Frame(section)
            ttk.Label(header, text=label).pack(side="left")
            ttk.Button(
                header,
                text="Select all",
                width=9,
                command=lambda c=cat: self._set_category(c, True),
            ).pack(side="left", padx=(6, 2))
            ttk.Button(
                header,
                text="Deselect all",
                width=11,
                command=lambda c=cat: self._set_category(c, False),
            ).pack(side="left")
            section.configure(labelwidget=header)
            for name in names:
                hist_status, hist_dt, hist_file = self._last_result_for(cat, name)
                if (cat, name) not in self._status:
                    self._status[(cat, name)] = hist_status
                self._last_files[(cat, name)] = hist_file
                cur_status = self._status[(cat, name)]
                icon  = self._STATUS_ICON.get(cur_status, "[?]")
                color = self._STATUS_COLOR.get(cur_status, "#858585")

                var = tk.BooleanVar(value=True)
                self._checks.setdefault(cat, {})[name] = var
                row = ttk.Frame(section)
                row.pack(fill="x", anchor="w")

                # status + datetime on the left for column alignment
                lbl = tk.Label(row, text=icon, font=("Consolas", 9), anchor="w",
                               width=9, foreground=color)
                lbl.pack(side="left", padx=(0, 2))
                self._status_labels[(cat, name)] = lbl

                date_lbl = tk.Label(row, text=hist_dt or "", font=("Consolas", 9),
                                    foreground="#4e9fce", anchor="w", width=16,
                                    cursor="hand2")
                date_lbl.pack(side="left", padx=(0, 6))
                date_lbl.bind("<Button-1>", lambda e, c=cat, n=name: self._open_last_file(c, n))
                self._date_labels[(cat, name)] = date_lbl

                ttk.Checkbutton(row, text=name, variable=var).pack(side="left")

    def _open_last_file(self, cat: str, name: str) -> None:
        path = self._last_files.get((cat, name))
        if not path or not path.exists():
            messagebox.showinfo("No output", f"No output file found for '{name}'.")
            return
        if platform.system() == "Windows":
            os.startfile(path)
        elif platform.system() == "Darwin":
            subprocess.run(["open", str(path)], check=False)
        else:
            # WSL: convert to Windows path and delegate to explorer.exe
            is_wsl = Path("/proc/version").exists() and "microsoft" in Path("/proc/version").read_text().lower()
            if is_wsl:
                result = subprocess.run(["wslpath", "-w", str(path)], capture_output=True, text=True)
                win_path = result.stdout.strip()
                subprocess.run(["explorer.exe", win_path], check=False)
            else:
                subprocess.run(["xdg-open", str(path)], check=False)

    def _set_all(self, value: bool) -> None:
        for cat_vars in self._checks.values():
            for var in cat_vars.values():
                var.set(value)

    def _set_category(self, cat: str, value: bool) -> None:
        for var in self._checks.get(cat, {}).values():
            var.set(value)

    def _update_status_label(self, cat: str, name: str, status: str,
                              file_path: Path | None = None) -> None:
        self._status[(cat, name)] = status
        if file_path is not None:
            self._last_files[(cat, name)] = file_path
        lbl = self._status_labels.get((cat, name))
        if lbl and lbl.winfo_exists():
            lbl.configure(
                text=self._STATUS_ICON.get(status, "[?]"),
                foreground=self._STATUS_COLOR.get(status, "#858585"),
            )
        date_lbl = self._date_labels.get((cat, name))
        if date_lbl and date_lbl.winfo_exists():
            date_lbl.configure(text=datetime.now().strftime("%Y-%m-%d %H:%M"))

    # ── run logic ─────────────────────────────────────────────────────────────

    def _collect_opts(self) -> dict:
        return {
            "mbt":        self.opt_mbt.get(),
            "seed":       self.opt_seed.get(),
            "max_steps":  self.opt_max_steps.get(),
            "backend":    self.opt_backend.get(),
            "keep_server": self.opt_keep_server.get(),
            "safety_cmd": self.opt_safety_cmd.get(),
            "combined_invariants": self.opt_combined_invariants.get(),
        }

    def _run_selected(self) -> None:
        if self._running:
            return
        if not self._qnt_path:
            messagebox.showwarning("No file", "Scan a .qnt file first.")
            return
        opts = self._collect_opts()
        tasks: list[tuple[str, str, str]] = []  # (original_cat, effective_cat, name)
        for cat, cat_vars in self._checks.items():
            for name, var in cat_vars.items():
                if not var.get():
                    continue
                if cat == "safety":
                    eff = "safety_run" if opts["safety_cmd"] == "run" else "safety_verify"
                else:
                    eff = cat
                tasks.append((cat, eff, name))
        if not tasks:
            messagebox.showinfo("Nothing selected", "Select at least one declaration to run.")
            return
        self._log_clear()
        self._set_running(True)
        threading.Thread(target=self._run_tasks, args=(tasks, opts), daemon=True).start()

    def _set_running(self, state: bool) -> None:
        self._running = state
        self.run_btn.configure(state="disabled" if state else "normal")

    def _run_tasks(self, tasks: list[tuple[str, str, str]], opts: dict) -> None:
        if opts.get("combined_invariants"):
            invariants = [name for _, eff_cat, name in tasks if eff_cat == "safety_run"]
            if invariants:
                self._run_invariants_together(invariants, opts)
                tasks = [task for task in tasks if task[1] != "safety_run"]
        for cat, eff_cat, name in tasks:
            self._run_one(cat, eff_cat, name, opts)
        self._enqueue("\n[OK]  All done.\n", "ok")
        self._enqueue_ui(lambda: self._set_running(False))

    _FOLDER: dict[str, str] = {
        "tests": "tests", "safety_run": "safety", "safety_verify": "safety",
        "witness": "witness", "liveness": "liveness", "fairness": "fairness",
    }

    def _run_invariants_together(self, names: list[str], opts: dict) -> None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        out_dir = self._qnt_path.parent / "output" / "safety" / "combined"
        out_dir.mkdir(parents=True, exist_ok=True)
        itf_file = out_dir / f"{timestamp}.itf.json"
        log_file = out_dir / f"{timestamp}_error.log"
        rel_itf = itf_file.relative_to(self._qnt_path.parent)
        cmd = ["quint", "run", self._qnt_path.name, "--invariants", *names,
               "--out-itf", str(rel_itf)]
        if opts.get("mbt"):
            cmd.append("--mbt")
        if opts.get("seed", "").strip():
            cmd += ["--seed", opts["seed"].strip()]
        if opts.get("max_steps", "").strip():
            cmd += ["--max-steps", opts["max_steps"].strip()]

        display = (subprocess.list2cmdline(cmd) if platform.system() == "Windows"
                   else shlex.join(cmd))
        self._enqueue(f"\n>>  {display}\n", "cmd")
        rc, output = self._exec(cmd, log_file=None)
        status = _determine_status(rc, output)
        result_file = itf_file
        if status != "ok":
            log_file.write_text(output, encoding="utf-8")
            result_file = log_file
        elif itf_file.exists():
            try:
                itf_file.write_text(
                    json.dumps(json.loads(itf_file.read_text(encoding="utf-8")), indent=2),
                    encoding="utf-8",
                )
            except Exception:
                pass
        for name in names:
            self._enqueue_ui(lambda n=name, s=status, f=result_file:
                             self._update_status_label("safety", n, s, f))

    def _run_one(self, cat: str, effective_cat: str, name: str, opts: dict) -> None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        folder = self._FOLDER[effective_cat]
        out_dir = self._qnt_path.parent / "output" / folder / name
        out_dir.mkdir(parents=True, exist_ok=True)

        itf_file = out_dir / f"{timestamp}.itf.json"
        log_file  = out_dir / f"{timestamp}.log"

        # use paths relative to qnt's parent; cwd in _exec is set to that directory
        rel_qnt = Path(self._qnt_path.name)
        rel_itf = itf_file.relative_to(self._qnt_path.parent)
        cmd = build_command(rel_qnt, effective_cat, name, rel_itf, opts)
        # quote for display only; subprocess receives the list directly
        display = (subprocess.list2cmdline(cmd) if platform.system() == "Windows"
                   else shlex.join(cmd))
        self._enqueue(f"\n>>  {display}\n", "cmd")
        # Verify categories always capture stdout; every category captures it on errors.
        save_log = effective_cat in ("safety_verify", "liveness", "fairness")
        rc, output = self._exec(cmd, log_file=None)
        if not save_log and itf_file.exists():
            try:
                itf_file.write_text(
                    json.dumps(json.loads(itf_file.read_text(encoding="utf-8")), indent=2),
                    encoding="utf-8",
                )
            except Exception:
                pass
        raw_status = _determine_status(rc, output)
        status = _expected_status(cat, raw_status)
        if cat == "fairness" and raw_status == "violation" and itf_file.exists():
            try:
                itf_file.write_text(
                    json.dumps(json.loads(itf_file.read_text(encoding="utf-8")), indent=2),
                    encoding="utf-8",
                )
            except Exception:
                pass
            result_file = itf_file
        elif status != "ok":
            log_file = out_dir / f"{timestamp}_error.log"
            log_file.write_text(output, encoding="utf-8")
            result_file = log_file
        elif save_log:
            log_file.write_text(output, encoding="utf-8")
            result_file = log_file
        else:
            result_file = itf_file
        self._enqueue_ui(lambda s=status, f=result_file: self._update_status_label(cat, name, s, f))

    def _exec(self, cmd: list[str], log_file: Path | None) -> tuple[int, str]:
        env = None
        if platform.system() == "Windows" and any(
                Path(part).name.lower() == "verify.cmd" for part in cmd):
            env = _apalache_env()
        # On Windows, npm-installed quint is quint.cmd; CreateProcess can't find .cmd files
        if platform.system() == "Windows" and cmd and cmd[0] == "quint":
            cmd = ["cmd", "/c"] + cmd
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                stdin=subprocess.PIPE,
                text=True,
                cwd=str(self._qnt_path.parent),
                env=env,
            )
            # auto-confirm any interactive prompts (e.g. quint verify temporal warning)
            try:
                proc.stdin.write("y\n")
                proc.stdin.close()
            except OSError:
                pass
            captured: list[str] = []
            for line in proc.stdout:
                line = _shorten_log_paths(line)
                captured.append(line)
                self._enqueue(line)
            proc.wait()
            text = "".join(captured)
            if log_file:
                log_file.write_text(text, encoding="utf-8")
            if proc.returncode == 0:
                self._enqueue("[OK]\n", "ok")
            else:
                failure = f"[FAIL]  exit {proc.returncode}\n"
                self._enqueue(failure, "err")
                text += failure
            return proc.returncode, text
        except FileNotFoundError as exc:
            message = f"[ERROR]  Command not found: {exc}\n"
            self._enqueue(message, "err")
            return -1, message

    # ── thread-safe logging ───────────────────────────────────────────────────

    def _enqueue(self, text: str, tag: str | None = None) -> None:
        self._log_queue.put((text, tag))

    def _enqueue_ui(self, callback: Callable[[], None]) -> None:
        """Schedule a GUI callback for execution by Tk's main thread."""
        self._ui_queue.put(callback)

    def _poll_log(self) -> None:
        while True:
            try:
                text, tag = self._log_queue.get_nowait()
                self._log(text, tag)
            except queue.Empty:
                break
        while True:
            try:
                self._ui_queue.get_nowait()()
            except queue.Empty:
                break
        self.after(40, self._poll_log)

    def _log(self, text: str, tag: str | None = None) -> None:
        self.output_text.configure(state="normal")
        if tag:
            self.output_text.insert("end", text, tag)
        else:
            self.output_text.insert("end", text)
        self.output_text.see("end")
        self.output_text.configure(state="disabled")

    def _log_clear(self) -> None:
        self.output_text.configure(state="normal")
        self.output_text.delete("1.0", "end")
        self.output_text.configure(state="disabled")

    # ── config import / export ──────────────────────────────────────────────────────

    def _import_config(self, startup_path: str | None = None) -> None:
        path = startup_path or filedialog.askopenfilename(
            title="Import config",
            filetypes=[("JSON config", "*.json"), ("All files", "*.*")])
        if not path:
            return
        try:
            cfg = json.loads(Path(path).read_text(encoding="utf-8"))
        except Exception as exc:
            messagebox.showerror("Import error", str(exc))
            return
        if "file" in cfg:
            self.file_var.set(cfg["file"])
            self._scan()
        if "opts" in cfg:
            o = cfg["opts"]
            self.opt_mbt.set(o.get("mbt", False))
            self.opt_seed.set(o.get("seed", ""))
            self.opt_max_steps.set(o.get("max_steps", ""))
            self.opt_backend.set(o.get("backend", "apalache"))
            self.opt_keep_server.set(o.get("keep_server", False))
            self.opt_safety_cmd.set(o.get("safety_cmd", "run"))
            self.opt_combined_invariants.set(o.get("combined_invariants", False))
        if "checks" in cfg:
            for cat, names in cfg["checks"].items():
                for name, value in names.items():
                    if cat in self._checks and name in self._checks[cat]:
                        self._checks[cat][name].set(value)
        self._log(f"Config imported from {Path(path).name}\n", "info")

    def _export_config(self) -> None:
        if not self._qnt_path:
            messagebox.showwarning("No file", "Scan a .qnt file first.")
            return
        path = filedialog.asksaveasfilename(
            title="Export config",
            defaultextension=".json",
            initialfile=f"{self._qnt_path.stem}_config.json",
            filetypes=[("JSON config", "*.json"), ("All files", "*.*")])
        if not path:
            return
        cfg = {
            "file": str(self._qnt_path),
            "checks": {
                cat: {name: var.get() for name, var in cat_vars.items()}
                for cat, cat_vars in self._checks.items()
            },
            "opts": self._collect_opts(),
        }
        Path(path).write_text(json.dumps(cfg, indent=2), encoding="utf-8")
        self._log(f"Config exported to {Path(path).name}\n", "info")

    # ── file viewer (shared helper + per-format entry points) ───────────────────────

    def _open_viewer_window(
        self,
        file_path: Path,
        title: str,
        tag_colors: list[tuple[str, str]],
        highlight_fn,
        viewer_ref_setter,
    ) -> None:
        """Open a read-only syntax-highlighted file viewer window."""
        win = tk.Toplevel(self)
        viewer_ref_setter(win)
        win.title(title)
        win.geometry("900x650")

        frame = ttk.Frame(win)
        frame.pack(fill="both", expand=True)

        ysb = ttk.Scrollbar(frame, orient="vertical")
        xsb = ttk.Scrollbar(win,   orient="horizontal")
        ysb.pack(side="right", fill="y")
        xsb.pack(side="bottom", fill="x")

        ln_text = tk.Text(
            frame, width=5, font=("Consolas", 9), state="disabled",
            bg="#2d2d2d", fg="#858585", relief="flat", cursor="arrow",
        )
        ln_text.pack(side="left", fill="y")

        content = tk.Text(
            frame, font=("Consolas", 9), wrap="none",
            bg="#1e1e1e", fg="#d4d4d4", xscrollcommand=xsb.set,
            cursor="arrow",
        )
        for tag, color in tag_colors:  # configure lowest-priority first
            content.tag_configure(tag, foreground=color)
        content.pack(side="left", fill="both", expand=True)

        def _sync_yview(*args: object) -> None:
            content.yview(*args)
            ln_text.yview(*args)

        ysb.configure(command=_sync_yview)
        xsb.configure(command=content.xview)
        content.configure(yscrollcommand=lambda *a: (ysb.set(*a), ln_text.yview_moveto(a[0])))

        lines = file_path.read_text(encoding="utf-8").splitlines()
        ln_text.configure(state="normal")
        for i, line in enumerate(lines, 1):
            ln_text.insert("end", f"{i:>4}\n")
            content.insert("end", line + "\n")
        highlight_fn(content, lines)
        ln_text.configure(state="disabled")

        content.bind("<Key>", lambda e: "break" if not (e.state & 0x4) else None)
        content.bind("<<Paste>>", lambda e: "break")

        def _viewer_scroll(e: tk.Event) -> str:
            delta = -1 * (e.delta // 120) if e.delta else (-1 if e.num == 4 else 1)
            _sync_yview("scroll", delta, "units")
            return "break"

        for w in (content, ln_text):
            w.bind("<MouseWheel>", _viewer_scroll)
            w.bind("<Button-4>",   _viewer_scroll)
            w.bind("<Button-5>",   _viewer_scroll)

    def _open_file_viewer(self) -> None:
        if not self._qnt_path or not self._qnt_path.exists():
            messagebox.showwarning("No file", "Scan a .qnt file first.")
            return
        if self._file_viewer and self._file_viewer.winfo_exists():
            self._file_viewer.lift()
            return
        _QNT_TAG_COLORS = [
            ("namespace", "#c8c8c8"),
            ("kw",        "#569cd6"),
            ("operator",  "#d7ba7d"),
            ("number",    "#b5cea8"),
            ("function",  "#dcdcaa"),
            ("type_name", "#4ec9b0"),
            ("constant",  "#4fc1ff"),
            ("variable",  "#9cdcfe"),
            ("property",  "#9cdcfe"),
            ("primed",    "#9cdcfe"),
            ("string",    "#ce9178"),
            ("comment",   "#6a9955"),
        ]
        self._open_viewer_window(
            self._qnt_path,
            f"View: {self._qnt_path.name}",
            _QNT_TAG_COLORS,
            _highlight_qnt,
            lambda w: setattr(self, "_file_viewer", w),
        )

    def _open_compiled_file_viewer(
        self, instance_name: str | None = None,
    ) -> None:
        if not self._qnt_path or not self._qnt_path.exists():
            messagebox.showwarning("No file", "Scan a .qnt file first.")
            return
        if (instance_name is None and self._compiled_file_viewer
                and self._compiled_file_viewer.winfo_exists()):
            self._compiled_file_viewer.lift()
            return

        suffix = f"_{instance_name}" if instance_name else ""
        tla_path = self._qnt_path.with_name(f"{self._qnt_path.stem}{suffix}.tla")
        main_args = ["--main", instance_name] if instance_name else []
        if platform.system() == "Windows":
            compile_cmd = ["cmd", "/d", "/c", "call", str(VERIFY_CMD),
                           str(self._qnt_path), "--compile", *main_args]
        else:
            compile_cmd = ["quint", "compile", self._qnt_path.name,
                           "--target", "tlaplus", *main_args]
        display = (subprocess.list2cmdline(compile_cmd) if platform.system() == "Windows"
                   else shlex.join(compile_cmd))
        self._log(f"Compiling {self._qnt_path.name} → TLA+…\n>>  {display}\n", "info")

        def _compile() -> None:
            try:
                if platform.system() == "Windows":
                    # Compilation uses Apalache too. Route it through verify.cmd so
                    # Windows gets the same managed server lifecycle as verification.
                    result = subprocess.run(
                        compile_cmd,
                        capture_output=True,
                        text=True,
                        cwd=str(self._qnt_path.parent),
                        env=_apalache_env(),
                    )
                else:
                    result = subprocess.run(
                        compile_cmd,
                        capture_output=True,
                        text=True,
                        cwd=str(self._qnt_path.parent),
                    )
            except FileNotFoundError:
                self._enqueue("[ERROR]  quint not found. Is it installed and on PATH?\n", "err")
                return
            if result.stderr:
                self._enqueue(result.stderr, "warn")
            if result.returncode != 0:
                self._enqueue(f"[FAIL]  Compile failed (exit {result.returncode})\n", "err")
                return
            try:
                raw = result.stdout
                # A generated TLA+ module begins with its four-or-more-dash delimiter.
                m = re.search(r'^-{4,}', raw, re.MULTILINE)
                if not m:
                    self._enqueue("[ERROR]  Compile produced no TLA+ module.\n", "err")
                    return
                module = raw[m.start():]
                end = re.search(r'^={4,}\s*$', module, re.MULTILINE)
                if end:
                    module = module[:end.end()] + "\n"
                tla_path.write_text(module, encoding="utf-8")
            except OSError as exc:
                self._enqueue(f"[ERROR]  Could not read compiled file: {exc}\n", "err")
                return
            self._enqueue(f"[OK]  Compiled -> {tla_path.name}\n", "ok")
            self._enqueue_ui(lambda: self._open_viewer_window(
                tla_path,
                f"View compiled: {tla_path.name}",
                _TLA_TAG_COLORS,
                _highlight_tla,
                (lambda w: setattr(self, "_compiled_file_viewer", w))
                if instance_name is None else (lambda _w: None),
            ))

        threading.Thread(target=_compile, daemon=True).start()

# ─── entry point ─────────────────────────────────────────────────────────────

def main() -> None:
    import argparse
    parser = argparse.ArgumentParser(description="Quint verification runner GUI")
    parser.add_argument("file", nargs="?", metavar="SPEC.qnt",
                        help="Quint spec file to pre-load")
    parser.add_argument("--config", metavar="CONFIG.json",
                        help="JSON config file to load on startup")
    args = parser.parse_args()

    app = QuintRunner(initial_file=args.file)
    if args.config:
        app._import_config(startup_path=args.config)
    app.mainloop()


if __name__ == "__main__":
    main()
