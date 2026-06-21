// Selects the right sqflite database factory for the current platform.
//
// Conditional import: the IO implementation is used on Android/iOS/desktop,
// and the web implementation on Chrome/Edge. Only one is ever compiled in,
// which keeps `dart:io` out of the web build and `dart:html` out of native.
export 'db_init_io.dart' if (dart.library.html) 'db_init_web.dart';
