// ignore_for_file: deprecated_member_use

import 'dart:html' as html;
import 'dart:js_interop';

import 'package:flutter/services.dart';

import 'pdf_page_size.dart';

@JS('flutterNativeHtmlToPdfBytes')
external JSPromise<JSUint8Array> _convertHtmlToPdfBytes(
  JSString html,
  JSBoolean isRtl,
);

/// Converts HTML content to PDF on Flutter web.
///
/// The web implementation renders the HTML in an offscreen iframe and uses
/// html2pdf.js to produce PDF bytes. File-path output is unavailable on web.
class HtmlToPdfConverter {
  static var _helperInjected = false;

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
    _ensureHelperInjected();

    try {
      final bytes = await _convertHtmlToPdfBytes(
        html.toJS,
        _isRtlHtml(html).toJS,
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

  static void _ensureHelperInjected() {
    if (_helperInjected) return;

    final script = html.ScriptElement()
      ..id = 'flutter-native-html-to-pdf-helper'
      ..text = _helperScript;
    html.document.head!.append(script);
    _helperInjected = true;
  }
}

const _helperScript = r'''
(function () {
  if (window.flutterNativeHtmlToPdfBytes) {
    return;
  }

  window.flutterNativeHtmlToPdfBytes = async function (htmlContent, isRtl) {
    await ensureHtml2PdfLoaded();

    const frame = document.createElement('iframe');
    frame.setAttribute('aria-hidden', 'true');
    frame.style.position = 'fixed';
    frame.style.left = '0';
    frame.style.top = '0';
    frame.style.width = '794px';
    frame.style.height = '1123px';
    frame.style.border = '0';
    frame.style.background = '#ffffff';
    frame.style.zIndex = '2147483647';
    frame.style.pointerEvents = 'none';
    frame.style.opacity = '1';

    const frameReady = waitForReportFrame(frame);
    frame.srcdoc = htmlContent;
    document.body.appendChild(frame);

    try {
      const frameDocument = await frameReady;
      const reportElement = frameDocument.body || frameDocument.documentElement;

      if (!reportElement || !reportElement.innerHTML.trim()) {
        throw new Error('Report HTML has no body content to convert');
      }

      frameDocument.documentElement.dir = isRtl ? 'rtl' : 'ltr';
      frameDocument.documentElement.style.width = '794px';
      frameDocument.documentElement.style.minHeight = '1123px';
      frameDocument.documentElement.style.overflow = 'visible';
      frameDocument.body.style.background = '#ffffff';
      frameDocument.body.style.color = '#000000';
      frameDocument.body.style.direction = isRtl ? 'rtl' : 'ltr';
      frameDocument.body.style.width = '794px';
      frameDocument.body.style.minHeight = '1123px';
      frameDocument.body.style.overflow = 'visible';
      frameDocument.body.style.margin = frameDocument.body.style.margin || '0';

      injectReportPdfPageStyles(frameDocument);
      await waitForReportLayout(frameDocument);

      const frameHeight = Math.max(
        frameDocument.documentElement.scrollHeight,
        frameDocument.body.scrollHeight,
        1123
      );
      frame.style.height = `${frameHeight}px`;
      reportElement.style.width = '794px';
      reportElement.style.minHeight = `${frameHeight}px`;
      reportElement.style.overflow = 'visible';

      await waitForNextPaint();

      const arrayBuffer = await window.html2pdf()
        .set({
          margin: [12, 12, 12, 12],
          image: { type: 'jpeg', quality: 0.98 },
          html2canvas: {
            scale: 2,
            useCORS: true,
            allowTaint: true,
            logging: false,
            backgroundColor: '#ffffff',
            windowWidth: 794,
            windowHeight: frameHeight
          },
          jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
          pagebreak: {
            mode: ['css', 'legacy'],
            before: '.html2pdf__page-break, .page-break, [data-pdf-page-break="before"]',
            after: '[data-pdf-page-break="after"]',
            avoid: 'tr, thead, tfoot, img, svg, canvas'
          }
        })
        .from(reportElement)
        .outputPdf('arraybuffer');

      return new Uint8Array(arrayBuffer);
    } finally {
      frame.remove();
    }
  };

  function ensureHtml2PdfLoaded() {
    if (window.html2pdf) {
      return Promise.resolve();
    }

    if (window.__flutterNativeHtml2PdfLoader) {
      return window.__flutterNativeHtml2PdfLoader;
    }

    window.__flutterNativeHtml2PdfLoader = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js';
      script.crossOrigin = 'anonymous';
      script.referrerPolicy = 'no-referrer';
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Failed to load html2pdf.js'));
      document.head.appendChild(script);
    });

    return window.__flutterNativeHtml2PdfLoader;
  }

  function injectReportPdfPageStyles(frameDocument) {
    const style = frameDocument.createElement('style');
    style.id = 'flutter-native-html-to-pdf-page-style';
    style.textContent = `
      @page { size: A4; margin: 12mm; }
      html, body {
        width: 794px !important;
        min-height: 1123px !important;
        height: auto !important;
        overflow: visible !important;
        background: #ffffff !important;
      }
      body { box-sizing: border-box; }
      table { width: 100%; border-collapse: collapse; }
      thead { display: table-header-group; }
      tfoot { display: table-footer-group; }
      tr, thead, tfoot, img, svg, canvas {
        break-inside: avoid;
        page-break-inside: avoid;
      }
      .html2pdf__page-break,
      .page-break,
      [data-pdf-page-break="before"] {
        break-before: page;
        page-break-before: always;
      }
      [data-pdf-page-break="after"] {
        break-after: page;
        page-break-after: always;
      }
    `;
    frameDocument.head.appendChild(style);
  }

  function waitForReportFrame(frame) {
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        reject(new Error('Timed out while loading report HTML'));
      }, 15000);

      frame.addEventListener('load', () => {
        clearTimeout(timeoutId);
        resolve(frame.contentDocument || frame.contentWindow.document);
      }, { once: true });
    });
  }

  async function waitForReportLayout(frameDocument) {
    if (frameDocument.fonts && frameDocument.fonts.ready) {
      await frameDocument.fonts.ready.catch(() => undefined);
    }

    const images = Array.from(frameDocument.images || []);
    await Promise.all(images.map((image) => {
      if (image.complete) {
        return Promise.resolve();
      }

      return new Promise((resolve) => {
        image.addEventListener('load', resolve, { once: true });
        image.addEventListener('error', resolve, { once: true });
      });
    }));

    await waitForNextPaint();
    await new Promise((resolve) => setTimeout(resolve, 500));
    await waitForNextPaint();
  }

  function waitForNextPaint() {
    return new Promise((resolve) => requestAnimationFrame(() => {
      requestAnimationFrame(resolve);
    }));
  }
})();
''';
