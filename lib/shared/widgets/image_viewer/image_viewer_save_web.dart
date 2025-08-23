// Only compiled on web via conditional import.
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> saveBytesToDownloadsWeb(Uint8List bytes, String filename) async {
  // Create a Blob from the raw bytes.
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS);

  // Create an object URL and a temporary <a download> to trigger the save.
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
