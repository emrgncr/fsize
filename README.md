# fsize

A simple cli tool to get the folder sizes recursively.

## Usage

```sh
$fsize [-n] /path/to/file [maxrecs]
```
The order of the arguments is important.

By default, fsize uses cross-platform features of dart.
If `-n` is specified, it will attempt to use `/bin/du` instead.

`maxrecs` spesifies maximum recursion depth. By default this is 1. Use a negative value for no recursion depth.

## Compiling

You can compile the binary using:

```sh
$dart compile exe bin/fsize.dart
```
You can also get AOT, JIT, Kernel snapshots using `dart compile ...`.