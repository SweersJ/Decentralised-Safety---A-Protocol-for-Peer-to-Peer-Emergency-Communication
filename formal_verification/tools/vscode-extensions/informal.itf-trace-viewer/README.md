# Version

This version is based on version [0.0.6](https://marketplace.visualstudio.com/items?itemName=informal.itf-trace-viewer) of the vscode itf trace viewer. It adds several fixes.

Fixes:
- Adds open view button when `<file_name>.itf.json` is set to JSON instead of ITF.
- Adds status, source, and command form the meta data to the bottom bar.

These edits were directly made in the vscode extension folder.

# How to use

## Windows

1. Check the version of the extension. If it is 0.6.0, the following steps can be used, otherwise the contents of the zip folder need to be compared first with the new version. The code changes can be seen at the bottom of this file.
2. Put the unzipped content of the folder `informal.itf-trace-viewer-0.0.6` in the folder `C:Users\<user_name>\.vscode\extensions\informal.itf-trace-viewer-0.0.6\` if there isn't anything yet. Otherwise remove the current code and put the zip folder and extract it in that location. Replace <user_name> with the correct name. 


## WSL

1. Check the version of the extension. If it is 0.6.0, the following steps can be used, otherwise the contents of the zip folder need to be compared first with the new version. The code changes can be seen at the bottom of this file.
2. Put the unzipped content of the folder `informal.itf-trace-viewer-0.0.6` in the folder `/home/<user_name>/.vscode-server/extensions/informal.itf-trace-viewer-0.0.6/` if there isn't anything yet. Otherwise remove the current code and put the zip folder and extract it in that location. Replace <user_name> with the correct name.

## Linux

1. Check the version of the extension. If it is 0.6.0, the following steps can be used, otherwise the contents of the zip folder need to be compared first with the new version. The code changes can be seen at the bottom of this file.
2. Put the unzipped content of the folder `informal.itf-trace-viewer-0.0.6` in the folder `/home/<user_name>/.vscode/extensions/informal.itf-trace-viewer-0.0.6/` if there isn't anything yet. Otherwise remove the current code and put the zip folder and extract it in that location. Replace <user_name> with the correct name. 

# Code changes

##  `dist\extension.js`
```javascript
_makeBottomBar() {
    var content = "";
    const meta = this._trace["#meta"];
    if (meta) {
        const description = meta.description;
        if (description) {
            content = description.replace("Apalache", `<a href="https://apalache.informal.systems/">Apalache</a>`);
        }
        const fields = [];
        const escapeHtml = (value) => String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
            .replace(/'/g, "&#39;");
        const formatValue = (value) => typeof value === "string" ? value : JSON.stringify(value);
        if (meta.command !== undefined) {
            const command = escapeHtml(formatValue(meta.command));
            fields.push(`<div><strong>command:</strong><pre>${command}</pre></div>`);
        }
        if (meta.status !== undefined) {
            const statusRaw = formatValue(meta.status);
            const status = escapeHtml(statusRaw);
            const statusColor = statusRaw === "ok"
                ? "green"
                : statusRaw === "error"
                    ? "red"
                    : "inherit";
            fields.push(`<strong>status:</strong> <span style="color: ${statusColor};">${status}</span>`);
        }
        if (meta.source !== undefined) {
            const source = escapeHtml(formatValue(meta.source));
            fields.push(`<strong>source:</strong> <span style="color: lightblue;">${source}</span>`);
        }
        if (fields.length > 0) {
            content = [content, fields.join("<br/>")].filter(x => x).join("<br/>");
        }
    }
    return `<div>${content}</div>`;
}
```

## `package.json`

Each when line needs to be updated to this version.
```json
"when": "editorLangId == itf || resourceFilename =~ /.*\\.itf\\.json$/"
```