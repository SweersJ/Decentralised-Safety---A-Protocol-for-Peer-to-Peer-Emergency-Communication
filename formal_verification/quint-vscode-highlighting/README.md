# Quint Syntax Highlighting for VS Code

This extension adds basic syntax highlighting support for Quint files (`.qnt`).

## Features

- Quint language registration
- TextMate grammar-based syntax highlighting
- Basic language configuration:
  - `//` line comments
  - bracket matching
  - auto-closing and surrounding pairs

## Use locally (without publishing)

1. Open this folder (`quint-vscode-highlighting`) in VS Code.
2. Press `F5` to launch an Extension Development Host.
3. Open a `.qnt` file in the new window.

## Package as a VSIX

1. Install packaging tool:
   - `npm i -g @vscode/vsce`
2. Run in extension folder:
   - `vsce package`
3. Install the generated `.vsix` via:
   - Command Palette -> `Extensions: Install from VSIX...`

## Notes

This is a lightweight starting point. It can be expanded with snippets, semantic tokens, diagnostics, and richer grammar rules as needed.
