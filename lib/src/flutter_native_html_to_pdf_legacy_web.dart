import 'dart:typed_data';

import 'html_to_pdf_converter_web.dart';
import 'pdf_page_size.dart';

/// Legacy class for backward compatibility.
///
/// Consider using [HtmlToPdfConverter] directly for new code.
@Deprecated('Use HtmlToPdfConverter instead')
class FlutterNativeHtmlToPdf {
  final _converter = HtmlToPdfConverter();

  /// File-path PDF output is unavailable on web.
  Future<Never> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) {
    return _converter.convertHtmlToPdf(
      html: html,
      targetDirectory: targetDirectory,
      targetName: targetName,
      pageSize: pageSize,
    );
  }

  /// PDF byte output is unavailable on web.
  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) {
    return _converter.convertHtmlToPdfBytes(html: html, pageSize: pageSize);
  }
}
