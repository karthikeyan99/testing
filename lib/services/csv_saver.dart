// Platform-specific CSV persistence. Native builds write a temp file and open
// the share sheet; web builds trigger a browser download. Conditional import
// keeps dart:io off web and dart:html off native.
export 'csv_saver_io.dart' if (dart.library.html) 'csv_saver_web.dart';
