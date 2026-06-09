import 'dart:io';
import 'dart:typed_data';

import 'html_to_pdf_converter_io.dart';
import 'pdf_page_size.dart';

/// Legacy class for backward compatibility.
///
/// Consider using [HtmlToPdfConverter] directly for new code.
@Deprecated('Use HtmlToPdfConverter instead')
class FlutterNativeHtmlToPdf {
  final _converter = HtmlToPdfConverter();

  /// Converts HTML content to a PDF file.
  Future<File?> convertHtmlToPdf({
    required String html,
    required String targetDirectory,
    required String targetName,
    PdfPageSize? pageSize,
  }) async {
    return _converter.convertHtmlToPdf(
      html: html,
      targetDirectory: targetDirectory,
      targetName: targetName,
      pageSize: pageSize,
    );
  }

  /// Converts HTML content to PDF bytes.
  Future<Uint8List?> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    return _converter.convertHtmlToPdfBytes(html: html, pageSize: pageSize);
  }
}
