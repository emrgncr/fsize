import 'package:fsize/fsize.dart';

String rebuildPath(Iterable<String> i) {
  String ret = "";
  for (var j in i) {
    ret += '$j/';
  }
  ret = ret.substring(0, ret.length - 1);
  return ret;
}

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments[0] == "--help") {
    print('usage: [-n] fsize path/to/folder [maxrecs]');
    print('\t-n: calculates filesizes using /bin/du if it can.');
    // ignore: prefer_adjacent_string_concatenation
    print('\tmaxrecs: maximum recursion depth, by default is 0.' +
        ' Use negative values for no limit');
    return;
  }
  int? maxrecs = 0;
  if (arguments.length > 1) {
    maxrecs = int.tryParse(arguments.last);
  }

  bool native = false;
  if (arguments.length > 2) {
    String a1 = arguments[0];
    if (a1 == "-n") {
      native = true;
    }
  }

  if (maxrecs != null && !native) maxrecs--;

  var mpath = arguments[native ? 1 : 0];

  List<fpair> paths = [];

  if (native) {
    final endp = maxrecs != null && maxrecs >= 0
        ? getSizeNative(mpath, maxDepth: maxrecs)
        : getSizeNative(mpath);
    final dynamic stder = endp.stderr;
    if (stder.length != 0) {
      print('Error, file $mpath does not exists or arguments are wrong');
      return;
    }
    if (endp.stdout is! String) {
      print("Faced an error");
      return;
    }
    final String output = endp.stdout;
    var lines = output.split('\n');
    lines.removeLast();
    paths.addAll(lines.reversed.map(mapSize));
  } else {
    paths.addAll((await getAllSize(mpath, maxDepth: maxrecs)).reversed);
  }
  int baseLen = paths[0].len;
  int prevLen = baseLen;
  for (final dir in paths) {
    if (dir.len < prevLen) {
      print(
          '${ansiColor('gray')}${"\t" * (dir.len - baseLen - 1)}${dir.path[dir.len - 2]}:$ansiEnd');
    }
    print(dir.visualize(baseLen));
    prevLen = dir.len;
  }
}
