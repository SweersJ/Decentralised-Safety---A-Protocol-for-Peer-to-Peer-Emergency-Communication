const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const vscode = require("vscode");

const MODULE_RE = /^\s*module\s+([A-Za-z_]\w*)\s*\{/gm;

function resolveRunner(document) {
  const configured = vscode.workspace
    .getConfiguration("quintRunner", document.uri)
    .get("runnerPath", "formal_verification/quint_runner.py");

  if (path.isAbsolute(configured)) {
    return configured;
  }

  const folder = vscode.workspace.getWorkspaceFolder(document.uri);
  if (folder) {
    return path.join(folder.uri.fsPath, configured);
  }

  return path.join(path.dirname(document.uri.fsPath), configured);
}

class QuintRunnerCodeLensProvider {
  provideCodeLenses(document) {
    const lenses = [];
    const text = document.getText();
    let match;

    MODULE_RE.lastIndex = 0;
    while ((match = MODULE_RE.exec(text)) !== null) {
      const position = document.positionAt(match.index);
      const range = new vscode.Range(position, position);
      lenses.push(
        new vscode.CodeLens(range, {
          title: "$(play) Run with Quint Runner",
          command: "quintRunner.runFile",
          arguments: [document.uri, match[1]],
          tooltip: `Open ${document.fileName} in Quint Runner (module ${match[1]})`,
        })
      );
    }

    return lenses;
  }
}

async function runFile(uri, moduleName) {
  const document = await vscode.workspace.openTextDocument(uri);
  if (document.isDirty && !(await document.save())) {
    vscode.window.showErrorMessage("Quint Runner: could not save the Quint file.");
    return;
  }

  const runner = resolveRunner(document);
  if (!fs.existsSync(runner)) {
    vscode.window.showErrorMessage(
      `Quint Runner not found at ${runner}. Configure quintRunner.runnerPath in VS Code settings.`
    );
    return;
  }

  const python = vscode.workspace
    .getConfiguration("quintRunner", uri)
    .get("pythonCommand", "python");

  try {
    const child = spawn(python, [runner, uri.fsPath], {
      cwd: path.dirname(runner),
      detached: true,
      stdio: "ignore",
      windowsHide: true,
    });
    child.on("error", (error) => {
      vscode.window.showErrorMessage(`Could not start Quint Runner: ${error.message}`);
    });
    child.unref();
    vscode.window.setStatusBarMessage(
      `Quint Runner opened for ${moduleName || path.basename(uri.fsPath)}`,
      3000
    );
  } catch (error) {
    vscode.window.showErrorMessage(`Could not start Quint Runner: ${error.message}`);
  }
}

function activate(context) {
  const selector = { scheme: "file", pattern: "**/*.qnt" };
  context.subscriptions.push(
    vscode.languages.registerCodeLensProvider(
      selector,
      new QuintRunnerCodeLensProvider()
    ),
    vscode.commands.registerCommand("quintRunner.runFile", runFile)
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
