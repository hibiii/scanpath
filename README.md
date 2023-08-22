# scanpath

an utility to scan your PATH variable for stuff like, folders that don't exist,
or for commands being shadowed by commands in other directories.

```console
$ scanpath
warning: relative directory found in path: "."
warning: relative directory found in path: "."
warning: could not open "/home/hibi/.dotnet/tools": error.FileNotFound
info: "gitui" of "/usr/bin" shadowed by the one in "/home/hibi/.cargo/bin"
warning: could not open "/home/hibi/Applications": error.FileNotFound
```
