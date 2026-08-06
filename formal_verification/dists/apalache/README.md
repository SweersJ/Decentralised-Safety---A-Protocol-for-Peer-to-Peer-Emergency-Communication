# Version

This version is a fix made for filtering over powersets. This was needed for the init action in the version 01 of batch. The version has been compiled on basis of the apalache version [0.59.0](https://github.com/apalache-mc/apalache/releases/tag/v0.59.0). The zip file `apalache.zip` will be generated with `make dist` in `target/universal`. Note this apalache project can only be compiled under an non-windows OS as, folders have been named aux which is a reserved name in Windows systems.

# How to use

## Windows

1. Put the entire dist specific folder `apalache-dist-powsetfilter` in the folder `C:Users\<user_name>\.quint\`. Replace <user_name> with the correct name.
2. Edit the npm quint package to use the updated apalache distribution. Open the file `C:\Users\<user_name>\AppData\Roaming\npm\node_modules\@informalsystems\quint\dist\src\apalache.js`, edit the line with `exports.DEFAULT_APALACHE_VERSION_TAG = '<apalache_version_tag>';` and replace the <apalache_version_tag> with `powsetfilter` in this example or the string after `apalache-dist-` of the dist specific folder.

## WSL

1. Put the entire dist specific folder `apalache-dist-powsetfilter` in the folder `/home/<user_name>/.quint`. Replace <user_name> with the correct name.
2. Edit the npm quint package to use the updated apalache distribution. Open the file `/mnt/c/Users/<user_name>/AppData/Roaming/npm/quint/dist/src/apalache.js`, edit the line with `exports.DEFAULT_APALACHE_VERSION_TAG = '<apalache_version_tag>';` and replace the <apalache_version_tag> with `powsetfilter` in this example or the string after `apalache-dist-` of the dist specific folder.
3. Go to the following folder `apalache/bin` (`cd apalache/bin`). Make the file `apalache-mc` executable. (`chmod ugo+x apalache-mc`).

## Linux

1. Put the entire dist specific folder `apalache-dist-powsetfilter` in the folder `/home/<user_name>/.quint`. Replace <user_name> with the correct name.
2. Edit the npm quint package to use the updated apalache distribution. Open the file `/usr/local/lib/node_modules/@informalsystems/quint/dist/src/apalache.js`, edit the line with `exports.DEFAULT_APALACHE_VERSION_TAG = '<apalache_version_tag>';` and replace the <apalache_version_tag> with `powsetfilter` in this example or the string after `apalache-dist-` of the dist specific folder.
3. Go to the following folder `apalache/bin` (`cd apalache/bin`). Make the file `apalache-mc` executable. (`chmod ugo+x apalache-mc`).

> Note: apalache.jar
This file is too large for upload to githug. Therefore it can be downloaded from: https://drive.google.com/file/d/1YnzaAdV3i5PZwySWzIeRcVa0rHa__YA3/view?usp=sharing