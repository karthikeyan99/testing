import 'dart:convert';
import 'dart:html' as html;

/// Web: trigger a browser download of the CSV.
Future<void> saveCsv(String filename, String csv) async {
  final bytes = utf8.encode(csv);
  final blob = html.Blob(<Object>[bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
