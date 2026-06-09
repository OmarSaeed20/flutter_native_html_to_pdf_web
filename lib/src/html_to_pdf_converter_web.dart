// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';

import 'pdf_page_size.dart';

@JS('flutterNativeHtmlToPdf.convertHtmlToPdfBytes')
external JSPromise<JSUint8Array> _convertHtmlToPdfBytes(
  JSString html,
  JSBoolean isRtl,
  JSNumber pageWidth,
  JSNumber pageHeight,
);

/// Converts HTML content to PDF on Flutter web.
///
/// The web implementation renders the HTML in an offscreen iframe and uses
/// html2pdf.js to produce PDF bytes. File-path output is unavailable on web.
class HtmlToPdfConverter {
  static Future<void>? _helperLoad;

  static const String _unsupportedMessage =
      'HTML to PDF conversion is not supported on Flutter web because browsers '
      'do not expose generated PDF file paths to JavaScript.';

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

  /// Converts [html] to PDF bytes held in memory.
  Future<Uint8List> convertHtmlToPdfBytes({
    required String html,
    PdfPageSize? pageSize,
  }) async {
    await _ensureHelperLoaded();

    try {
      final resolvedPageSize = pageSize ?? PdfPageSize.a4;
      final bytes = await _convertHtmlToPdfBytes(
        html.toJS,
        _isRtlHtml(html).toJS,
        resolvedPageSize.width.toJS,
        resolvedPageSize.height.toJS,
      ).toDart;
      return bytes.toDart;
    } catch (e) {
      throw PlatformException(
        code: 'CONVERSION_FAILED',
        message: 'Failed to convert HTML to PDF on web.',
        details: e.toString(),
      );
    }
  }

  static bool _isRtlHtml(String html) {
    return RegExp(
      r'''<html\b[^>]*\bdir=(["'])rtl\1''',
      caseSensitive: false,
    ).hasMatch(html);
  }

  static Future<void> _ensureHelperLoaded() {
    return _helperLoad ??= _loadHelperScript();
  }

  static Future<void> _loadHelperScript() async {
    if (_isHelperAvailable()) return;

    const scriptId = 'flutter-native-html-to-pdf-helper';
    if (html.document.getElementById(scriptId) case final existingScript?) {
      await _waitForExistingScript(existingScript);
      if (_isHelperAvailable()) return;
    }

    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..id = scriptId
      ..src =
          'assets/packages/flutter_native_html_to_pdf/web/flutter_native_html_to_pdf.js'
      ..async = true;

    script.onLoad.first.then((_) {
      if (_isHelperAvailable()) {
        completer.complete();
      } else {
        completer.completeError(
          StateError('flutterNativeHtmlToPdf web helper did not initialize.'),
        );
      }
    });
    script.onError.first.then((_) {
      completer.completeError(
        StateError('Failed to load flutter_native_html_to_pdf web helper.'),
      );
    });

    html.document.head!.append(script);
    await completer.future;
  }

  static Future<void> _waitForExistingScript(html.Element script) async {
    if (_isHelperAvailable()) return;

    final completer = Completer<void>();
    script.onLoad.first.then((_) => completer.complete());
    script.onError.first.then((_) {
      completer.completeError(
        StateError('Failed to load flutter_native_html_to_pdf web helper.'),
      );
    });
    await completer.future;
  }

  static bool _isHelperAvailable() {
    final nativeHtmlToPdf = globalContext.getProperty<JSObject?>(
      'flutterNativeHtmlToPdf'.toJS,
    );
    if (nativeHtmlToPdf == null) return false;
    return nativeHtmlToPdf.getProperty<JSAny?>('convertHtmlToPdfBytes'.toJS) !=
        null;
  }
}
