import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web registration for flutter_native_html_to_pdf.
class FlutterNativeHtmlToPdfWeb {
  static const String _unsupportedMessage =
      'HTML to PDF conversion is not supported on Flutter web because browsers '
      'do not expose generated PDF files or bytes to JavaScript.';

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
      case 'convertHtmlToPdfBytes':
        throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: _unsupportedMessage,
        );
      default:
        throw MissingPluginException(
          'No implementation found for method ${call.method}',
        );
    }
  }
}
