#!/usr/bin/env python3
"""Find Mermaid diagrams and export selected files with Mermaid CLI."""
from __future__ import annotations
import argparse, os, queue, shutil, subprocess, threading
from collections import defaultdict
from datetime import datetime
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_ROOT = SCRIPT_DIR.parent
SUFFIXES = {".mmd", ".mermaid"}
IGNORED_DIRS = {".git", ".venv", "node_modules", "__pycache__"}
THEMES = ("neutral", "default", "forest", "dark")
ENV_FILE = SCRIPT_DIR / ".env"
OUTPUT_ROOT_KEY = "MERMAID_OUTPUT_ROOT"


def load_output_root(env_file: Path = ENV_FILE) -> Path | None:
    """Read MERMAID_OUTPUT_ROOT without requiring python-dotenv."""
    if not env_file.is_file():
        return None
    for raw_line in env_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() == OUTPUT_ROOT_KEY:
            value = value.strip().strip('"').strip("'")
            if not value:
                return None
            root = Path(value).expanduser()
            return (root if root.is_absolute() else env_file.parent / root).resolve()
    return None


def save_output_root(value: str, env_file: Path = ENV_FILE) -> None:
    """Update MERMAID_OUTPUT_ROOT in .env while retaining unrelated settings."""
    lines = env_file.read_text(encoding="utf-8").splitlines() if env_file.exists() else []
    setting = f"{OUTPUT_ROOT_KEY}={value.strip()}"
    for index, line in enumerate(lines):
        if line.strip().split("=", 1)[0].strip() == OUTPUT_ROOT_KEY:
            lines[index] = setting
            break
    else:
        lines.append(setting)
    env_file.write_text("\n".join(lines) + "\n", encoding="utf-8")


def resolve_output_root(value: str) -> Path | None:
    """Resolve the editable output field relative to formal_verification."""
    value = value.strip().strip('"').strip("'")
    if not value:
        return None
    root = Path(value).expanduser()
    return (root if root.is_absolute() else SCRIPT_DIR / root).resolve()

def output_path(source: Path, output_root: Path | None, output_format: str,
                timestamp: str, scan_root: Path = DEFAULT_ROOT) -> Path:
    """Return the timestamped output path, omitting a `diagrams` path level."""
    if output_root is None:
        folder = source.parent
    else:
        try:
            relative = source.resolve().relative_to(SCRIPT_DIR)
        except ValueError:
            relative = source.resolve().relative_to(scan_root.resolve())
        parts = list(relative.parent.parts)
        if "diagrams" in [part.lower() for part in parts]:
            index = [part.lower() for part in parts].index("diagrams")
            parts.pop(index)
        folder = output_root.joinpath(*parts)
    return folder / f"{source.stem}_{timestamp}.{output_format}"


def find_mermaid_files(root: Path) -> list[Path]:
    """Return Mermaid files below root in stable relative-path order."""
    root = root.resolve()
    found = (path for path in root.rglob("*") if path.is_file()
             and path.suffix.lower() in SUFFIXES
             and not any(part in IGNORED_DIRS for part in path.relative_to(root).parts))
    return sorted(found, key=lambda path: path.relative_to(root).as_posix().lower())


def build_command(source: Path, output: Path, theme: str, background: str) -> list[str]:
    return ["mmdc", "-i", str(source), "-o", str(output), "-t", theme, "-b", background]


class MermaidRunner(tk.Tk):
    def __init__(self, root: Path) -> None:
        super().__init__()
        self.title("Mermaid image exporter")
        self.geometry("900x680")
        self.minsize(680, 480)
        self.root_var = tk.StringVar(value=str(root.resolve()))
        self.format_var = tk.StringVar(value="svg")
        self.theme_var = tk.StringVar(value="neutral")
        self.background_var = tk.StringVar(value="transparent")
        self.status_var = tk.StringVar(value="Ready")
        self.file_vars: dict[Path, tk.BooleanVar] = {}
        self.file_labels: dict[Path, tk.StringVar] = {}
        self.messages: queue.Queue[tuple[str, str]] = queue.Queue()
        configured_output = load_output_root()
        self.output_root_var = tk.StringVar(value=str(configured_output) if configured_output else "")
        self._build_ui()
        self.output_root_var.trace_add("write", self._refresh_output_previews)
        self.format_var.trace_add("write", self._refresh_output_previews)
        self.scan()
        self.after(50, self._poll_messages)

    def _build_ui(self) -> None:
        outer = ttk.Frame(self, padding=10)
        outer.pack(fill="both", expand=True)
        row = ttk.Frame(outer)
        row.pack(fill="x")
        ttk.Label(row, text="Search root:").pack(side="left")
        ttk.Entry(row, textvariable=self.root_var).pack(side="left", fill="x", expand=True, padx=6)
        ttk.Button(row, text="Browse...", command=self._browse).pack(side="left")
        ttk.Button(row, text="Scan", command=self.scan).pack(side="left", padx=(6, 0))
        output_row = ttk.Frame(outer)
        output_row.pack(fill="x", pady=(8, 0))
        ttk.Label(output_row, text="Output root:").pack(side="left")
        ttk.Entry(output_row, textvariable=self.output_root_var).pack(side="left", fill="x", expand=True, padx=6)
        ttk.Button(output_row, text="Browse...", command=self._browse_output).pack(side="left")
        ttk.Button(output_row, text="Save to .env", command=self._save_output).pack(side="left", padx=(6, 0))
        options = ttk.Frame(outer)
        options.pack(fill="x", pady=(10, 6))
        ttk.Button(options, text="Select all", command=lambda: self._set_all(True)).pack(side="left")
        ttk.Button(options, text="Deselect all", command=lambda: self._set_all(False)).pack(side="left", padx=6)
        ttk.Label(options, text="Format:").pack(side="left", padx=(18, 4))
        ttk.Combobox(options, textvariable=self.format_var, values=("svg", "png"), state="readonly", width=6).pack(side="left")
        ttk.Label(options, text="Theme:").pack(side="left", padx=(12, 4))
        ttk.Combobox(options, textvariable=self.theme_var, values=THEMES, state="readonly", width=9).pack(side="left")
        ttk.Label(options, text="Background:").pack(side="left", padx=(12, 4))
        ttk.Combobox(options, textvariable=self.background_var,
                     values=("transparent", "black", "white"), width=13).pack(side="left")
        area = ttk.Frame(outer)
        area.pack(fill="both", expand=True)
        self.canvas = tk.Canvas(area, highlightthickness=0)
        scrollbar = ttk.Scrollbar(area, orient="vertical", command=self.canvas.yview)
        self.files_frame = ttk.Frame(self.canvas)
        window = self.canvas.create_window((0, 0), window=self.files_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=scrollbar.set)
        self.files_frame.bind("<Configure>", lambda _e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))
        self.canvas.bind("<Configure>", lambda e: self.canvas.itemconfigure(window, width=e.width))
        self.canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        bottom = ttk.Frame(outer)
        bottom.pack(fill="x", pady=(8, 0))
        ttk.Label(bottom, textvariable=self.status_var).pack(side="left", fill="x", expand=True)
        self.export_button = ttk.Button(bottom, text="Export selected", command=self.export_selected)
        self.export_button.pack(side="right")

    def _browse(self) -> None:
        selected = filedialog.askdirectory(title="Select search folder", initialdir=self.root_var.get())
        if selected:
            self.root_var.set(selected)
            self.scan()

    def _browse_output(self) -> None:
        initial = self.output_root_var.get().strip() or str(SCRIPT_DIR)
        selected = filedialog.askdirectory(title="Select output root", initialdir=initial)
        if selected:
            self.output_root_var.set(selected)

    def _save_output(self) -> None:
        save_output_root(self.output_root_var.get())
        self.status_var.set(f"Saved output root to {ENV_FILE.name}")

    def _set_all(self, selected: bool) -> None:
        for variable in self.file_vars.values():
            variable.set(selected)

    def _file_label(self, source: Path) -> str:
        """Show where a source will be written using a timestamp placeholder."""
        output_root = resolve_output_root(self.output_root_var.get())
        scan_root = Path(self.root_var.get()).expanduser()
        output = output_path(source, output_root, self.format_var.get(),
                             "YYYYMMDD-HHMMSS", scan_root)
        if output_root is None:
            preview = Path(".") / output.name
        else:
            preview = Path("<output-root>") / output.relative_to(output_root)
        return f"{source.name}  ->  {preview.as_posix()}"

    def _refresh_output_previews(self, *_args: object) -> None:
        for source, label in self.file_labels.items():
            label.set(self._file_label(source))

    def scan(self) -> None:
        root = Path(self.root_var.get()).expanduser()
        if not root.is_dir():
            messagebox.showerror("Invalid search root", f"Folder does not exist:\n{root}")
            return
        for child in self.files_frame.winfo_children():
            child.destroy()
        self.file_vars.clear()
        self.file_labels.clear()
        grouped: dict[Path, list[Path]] = defaultdict(list)
        for path in find_mermaid_files(root):
            grouped[path.parent.relative_to(root)].append(path)
        if not grouped:
            ttk.Label(self.files_frame, text="No .mmd or .mermaid files found.", padding=12).pack(anchor="w")
        for folder, paths in grouped.items():
            title = ". (search root)" if str(folder) == "." else folder.as_posix()
            group = ttk.LabelFrame(self.files_frame, text=title, padding=(8, 4))
            group.pack(fill="x", padx=2, pady=4)
            for path in paths:
                variable = tk.BooleanVar(value=True)
                label = tk.StringVar(value=self._file_label(path))
                self.file_vars[path] = variable
                self.file_labels[path] = label
                ttk.Checkbutton(group, textvariable=label, variable=variable).pack(anchor="w")
        count = len(self.file_vars)
        self.status_var.set(f"Found {count} Mermaid file{'s' if count != 1 else ''}")

    def export_selected(self) -> None:
        selected = [path for path, variable in self.file_vars.items() if variable.get()]
        background = self.background_var.get().strip()
        if not selected:
            messagebox.showwarning("Nothing selected", "Select at least one Mermaid file to export.")
            return
        if not background:
            messagebox.showwarning("Missing background", "Enter a background color or 'transparent'.")
            return
        if shutil.which("mmdc") is None:
            messagebox.showerror("Mermaid CLI not found", "Install it with:\n\nnpm install -g @mermaid-js/mermaid-cli")
            return
        self.export_button.configure(state="disabled")
        self.status_var.set(f"Exporting 0/{len(selected)}...")
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        output_root = resolve_output_root(self.output_root_var.get())
        threading.Thread(target=self._export_worker,
                         args=(selected, self.format_var.get(), self.theme_var.get(),
                               background, timestamp, Path(self.root_var.get()).expanduser(), output_root),
                         daemon=True).start()

    def _export_worker(self, selected: list[Path], output_format: str, theme: str,
                       background: str, timestamp: str, scan_root: Path, output_root: Path | None) -> None:
        failures = []
        for index, source in enumerate(selected, 1):
            output = output_path(source, output_root, output_format, timestamp, scan_root)
            output.parent.mkdir(parents=True, exist_ok=True)
            command = build_command(source, output, theme, background)
            if os.name == "nt":
                command = ["cmd", "/d", "/c", *command]
            result = subprocess.run(command, capture_output=True, text=True)
            if result.returncode:
                failures.append(f"{source}: {(result.stderr or result.stdout).strip() or 'mmdc failed'}")
            self.messages.put(("progress", f"Exporting {index}/{len(selected)}..."))
        text = "\n\n".join(failures) if failures else f"Exported {len(selected)} file(s)."
        self.messages.put(("error" if failures else "done", text))

    def _poll_messages(self) -> None:
        while not self.messages.empty():
            kind, text = self.messages.get_nowait()
            self.status_var.set(text if kind != "error" else "Export completed with errors")
            if kind in {"done", "error"}:
                self.export_button.configure(state="normal")
                (messagebox.showerror if kind == "error" else messagebox.showinfo)("Export result", text)
        self.after(50, self._poll_messages)


def main() -> None:
    parser = argparse.ArgumentParser(description="Find and export Mermaid diagrams using a GUI")
    parser.add_argument("root", nargs="?", type=Path, default=DEFAULT_ROOT,
                        help="folder to scan (default: repository root)")
    args = parser.parse_args()
    MermaidRunner(args.root).mainloop()


if __name__ == "__main__":
    main()
