# Version

This version is based on version [0.32.0](https://github.com/quint-co/quint/releases#release-v0.32.0) of the npm quint package. It adds several fixes.

Fixes:
- chooseSome() not being implemented in runtime. Now functional in typescript and rust backend.
- Properly logging ok, violation and error state after a formal verification in the itf json output files.
- Adds command to itf json output for the itf trace viewer. 
- Fix for error formatting on windows systems with incorrectly formatted keys with windows paths.
- Update config to work with version 0.59.0 of apalache.

These edits were directly made in the compiled dist folder, but could be compiled from the quint code base.

# How to use

## Windows

1. Unzip the folder in the `C:\Users\<user_name>\AppData\Roaming\npm\node_modules\@informalsystems\quint\` if there isn't anything yet. Otherwise remove the current code and put the zip folder and extract it in that location.

## WSL

1. Unzip the folder in the `/mnt/c/Users/<user_name>/AppData/Roaming/npm/quint/` if there isn't anything yet. Otherwise remove the current code and put the zip folder and extract it in that location.

## Linux

1.  Unzip the folder in the `/usr/local/lib/node_modules/@informalsystems/quint/` if there isn't anything yet. Otherwise remove the current code and put the zip folder and extract it in that location.
