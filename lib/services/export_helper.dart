import 'dart:typed_data';

import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Web has no filesystem and no native "open in app" or share sheet, so
/// every PDF/image export on web instead triggers a browser download.
/// Native platforms keep their own dart:io + OS share-sheet flow at the
/// call site; this helper only covers the web-safe path.
class ExportHelper {
  static Future<void> downloadPdf(Uint8List bytes, String filename) {
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> downloadImages(List<Uint8List> pages, String baseName) {
    final files = <XFile>[
      for (var i = 0; i < pages.length; i++)
        XFile.fromData(
          pages[i],
          mimeType: 'image/png',
          name: i == 0 ? '$baseName.png' : '${baseName}_p${i + 1}.png',
        ),
    ];
    return SharePlus.instance.share(ShareParams(files: files));
  }
}
