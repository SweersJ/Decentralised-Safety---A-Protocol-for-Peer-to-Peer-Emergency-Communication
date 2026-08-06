# Version

This version has several fixes based on version [0.6.0](https://github.com/quint-co/quint/releases/tag/evaluator%2Fv0.6.0).

Fixes:
- chooseSome() not being implemented in runtime. Now functional in typescript and rust backend.
- Execute quint with windows instead of only with linux systems.
- Properly logging ok, violation and error state after a formal verification in the itf json output files.

This was needed for the init action in the version 01 of batch. These versions has been compiled on windows and linux systems separately with `carge build --release` which generates the files (`quint_evaluator` (linux) and `quint_evaluator.exe` (Windows)) in `target/release`.

# How to use

## Windows

1. Put the entire dist specific folder `rust-evaluator-v0.6.0-dev_2` in the folder `C:Users\<user_name>\.quint\`. Replace <user_name> with the correct name.
2. Edit the npm quint package to use the updated apalache distribution. Open the file `C:\Users\<user_name>\AppData\Roaming\npm\node_modules\@informalsystems\quint\dist\src\apalache.js`, edit the line with `exports.QUINT_EVALUATOR_VERSION = '<rust_evaluator_version>';;` and replace the <rust_evaluator_version> with `v0.6.0-dev_2` in this example or the string after `rust-evaluator-` of the dist specific folder.

## WSL

1. Put the entire dist specific folder `rust-evaluator-v0.6.0-dev_2` in the folder `/home/<user_name>/.quint`. Replace <user_name> with the correct name.
2. Edit the npm quint package to use the updated apalache distribution. Open the file `/mnt/c/Users/<user_name>/AppData/Roaming/npm/quint/dist/src/rust/binaryManager.js`, edit the line with `exports.QUINT_EVALUATOR_VERSION = '<rust_evaluator_version>';` and replace the <rust_evaluator_version> with `v0.6.0-dev_2` in this example or the string after `rust-evaluator-` of the dist specific folder.
3. Make the file `quint_evaluator` executable. (`chmod ugo+x quint_evaluator`).

## Linux

1. Put the entire dist specific folder `rust-evaluator-v0.6.0-dev_2` in the folder `/home/<user_name>/.quint`. Replace <user_name> with the correct name.
2. Edit the npm quint package to use the updated apalache distribution. Open the file `/usr/local/lib/node_modules/@informalsystems/quint/dist/src/rust/binaryManager.js`, edit the line with `exports.QUINT_EVALUATOR_VERSION = '<rust_evaluator_version>';` and replace the <rust_evaluator_version> with `v0.6.0-dev_2` in this example or the string after `rust-evaluator-` of the dist specific folder.
3. Make the file `quint_evaluator` executable. (`chmod ugo+x quint_evaluator`).