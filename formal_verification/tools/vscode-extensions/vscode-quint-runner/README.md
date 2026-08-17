# Quint Runner CodeLens

Adds a **Run with Quint Runner** CodeLens above every `module` declaration in
Quint (`.qnt`) files. Clicking the action saves the file and opens it in
`formal_verification/quint_runner.py`.

Settings:

- `quintRunner.pythonCommand`: Python executable (default: `python`).
- `quintRunner.runnerPath`: workspace-relative or absolute runner path
  (default: `formal_verification/quint_runner.py`).
