import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/html_to_pdf_converter_web.dart';
import 'src/pdf_page_size.dart';

/// Web registration for flutter_native_html_to_pdf.
class FlutterNativeHtmlToPdfWeb {
  final _converter = HtmlToPdfConverter();

  static const String _unsupportedMessage =
      'HTML to PDF conversion is not supported on Flutter web because browsers '
      'do not expose generated PDF file paths to JavaScript.';

  /// Registers the web implementation with Flutter.
  static void registerWith(Registrar registrar) {
    final channel = MethodChannel(
      'flutter_native_html_to_pdf',
      const StandardMethodCodec(),
      registrar,
    );
    final plugin = FlutterNativeHtmlToPdfWeb();
    channel.setMethodCallHandler(plugin.handleMethodCall);
  }

  /// Handles method calls from apps that use the platform channel directly.
  Future<Object?> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'convertHtmlToPdf':
        throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: _unsupportedMessage,
        );
      case 'convertHtmlToPdfBytes':
        final arguments = call.arguments as Map<Object?, Object?>?;
        final html = arguments?['html'] as String?;
        if (html == null || html.isEmpty) {
          throw PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'The html argument is required.',
          );
        }

        final pageWidth = (arguments?['pageWidth'] as num?)?.toDouble();
        final pageHeight = (arguments?['pageHeight'] as num?)?.toDouble();
        final pageSize = pageWidth != null && pageHeight != null
            ? PdfPageSize.custom(width: pageWidth, height: pageHeight)
            : null;

        return _converter.convertHtmlToPdfBytes(html: html, pageSize: pageSize);
      default:
        throw MissingPluginException(
          'No implementation found for method ${call.method}',
        );
    }
  }
}
