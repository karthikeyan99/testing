import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native: write to a temp file and open the OS share sheet.
Future<void> saveCsv(String filename, String csv) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsString(csv);
  await Share.shareXFiles([XFile(file.path)], text: 'Sales Tracker export');
}
