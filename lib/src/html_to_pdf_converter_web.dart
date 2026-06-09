import 'package:flutter/services.dart';

import 'pdf_page_size.dart';

/// Converts HTML content to PDF on Flutter web.
///
/// Browser runtimes do not expose a WebView/print API that can synchronously
/// export arbitrary HTML as a PDF file path or PDF bytes. Calls therefore fail
/// with [PlatformException] using the `UNSUPPORTED_PLATFORM` code.
class HtmlToPdfConverter {
  static const String _unsupportedMessage =
      'HTML to PDF conversion is not supported on Flutter web because browsers '
      'do not expose generated PDF files or bytes to JavaScript.';

  /// File-path PDF output is unavailable on web.
  Future<Never> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    throw PlatformException(
      code: 'UNSUPPORTED_PLATFORM',
      message: _unsupportedMessage,
    );
  }

  /// PDF byte output is unavailable on web.
  Future<Uint8List> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    throw PlatformException(
      code: 'UNSUPPORTED_PLATFORM',
      message: _unsupportedMessage,
    );
  }
}
