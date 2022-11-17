import 'dart:io';

const ansiSt = '\x1B[';
const ansiColors = {
  'red': 31,
  'green': 32,
  'blue': 34,
  'gray': 90,
  'bred': 91,
  'bgreen': 92,
};
const ansiRed = '${ansiSt}31m';
const ansiEnd = '${ansiSt}0m';

String ansiColor(String color) => '$ansiSt${ansiColors[color]}m';

ProcessResult getSizeNative(String filepath, {int? maxDepth}) {
  String arg2 = '--max-depth=$maxDepth';
  var args = [filepath];
  if (maxDepth != null) args.add(arg2);
  return Process.runSync('/bin/du', args);
}

Future<List<fpair>> getAllSize(String filepath, {int? maxDepth}) async {
  Directory root = Directory(filepath);
  maxDepth ??= -2;
  return getRecursiveSize(root, maxDepth);
}

Future<int> getDirSize(Directory dir, {bool onlyFile = true}) async {
  int r = 0;
  await for (var i in dir.list(recursive: !onlyFile, followLinks: false)) {
    if (i is File) {
      r += await i.length();
    }
  }
  return r ~/ 1024; //to KB
}

int getDirSizeSync(Directory dir, {bool onlyFile = true}) {
  int r = 0;
  for (var i in dir.listSync(followLinks: false, recursive: !onlyFile)) {
    if (i is File) {
      r += i.lengthSync();
    }
  }
  return r ~/ 1024; //to KB
}

Future<List<fpair>> getRecursiveSize(Directory parent, int maxDepth) async {
  if (maxDepth == -1) {
    return [
      fastFpair(
          parent.path.toString(), await getDirSize(parent, onlyFile: false))
    ];
  }
  Stream<FileSystemEntity> children = parent.list(followLinks: false);
  List<fpair> ret = [];
  List<Directory> toRec = [];
  await children.forEach((element) {
    if (element is Directory) toRec.add(element);
  });
  var ts = fastFpair(parent.path.toString(), await getDirSize(parent));
  if (toRec.isEmpty) {
    ret.add(ts);
    return ret;
  }

  for (var i in toRec) {
    var childs = await getRecursiveSize(i, maxDepth - 1);
    ret.addAll(childs);
    for (var j in childs) {
      if (j.len - 1 == ts.len) ts.size += j.size;
    }
  }
  ret.add(ts);
  return ret;
}

String visualizeSize(int s) {
  double pow = 1;
  int mult = 2;
  while (s > pow * 1024) {
    pow *= 1024;
    mult++;
  }
  var typ = [
    '-1',
    'B',
    '${ansiColor('green')}KB$ansiEnd',
    '${ansiColor('bgreen')}MB$ansiEnd',
    '${ansiColor('red')}GB$ansiEnd',
    '${ansiColor('bred')}TB$ansiEnd',
    'PB'
  ];
  String typetest = mult > typ.length ? '??' : typ[mult];
  String t = (s / (pow)).toStringAsFixed(1);
  return "$t $typetest";
}

// ignore: camel_case_types
class fpair {
  int size;
  List<String> path;
  get getSize => size;
  get getPath => path;
  get len => path.length;
  fpair(this.size, this.path);
  @override
  String toString() {
    return visualize(0);
  }

  String visualize(int baseLen) {
    return "${"\t" * (path.length - baseLen)}${path.last}: ${visualizeSize(size)}";
  }
}

fpair mapSize(String ls) {
  final sp = ls.split('\t');
  int sz = int.tryParse(sp[0]) ?? (-1);
  List<String> path = sp[1].split(Platform.pathSeparator);
  bool i = true;
  while (i) {
    i = path.remove('');
  }
  return fpair(sz, path);
}

fpair fastFpair(String paths, int sz) {
  List<String> path = paths.split(Platform.pathSeparator);
  bool i = true;
  while (i) {
    i = path.remove('');
  }
  return fpair(sz, path);
}
