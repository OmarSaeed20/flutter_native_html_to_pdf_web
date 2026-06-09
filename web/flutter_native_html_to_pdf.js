(function () {
  const namespace = window.flutterNativeHtmlToPdf || {};
  window.flutterNativeHtmlToPdf = namespace;

  namespace.convertHtmlToPdfBytes = async function (
    htmlContent,
    isRtl,
    pageWidth,
    pageHeight
  ) {
    await ensureHtml2PdfLoaded();

    const widthPt = Number(pageWidth) || 595.2;
    const heightPt = Number(pageHeight) || 841.8;
    const widthPx = Math.round(pointsToCssPixels(widthPt));
    const minHeightPx = Math.round(pointsToCssPixels(heightPt));
    const marginPt = millimetersToPoints(12);

    const frame = document.createElement('iframe');
    frame.setAttribute('aria-hidden', 'true');
    frame.style.position = 'fixed';
    frame.style.left = '0';
    frame.style.top = '0';
    frame.style.width = `${widthPx}px`;
    frame.style.height = `${minHeightPx}px`;
    frame.style.border = '0';
    frame.style.background = '#ffffff';
    frame.style.zIndex = '2147483647';
    frame.style.pointerEvents = 'none';
    frame.style.opacity = '1';

    const frameReady = waitForReportFrame(frame);
    frame.srcdoc = String(htmlContent || '');
    document.body.appendChild(frame);

    try {
      const frameDocument = await frameReady;
      const reportElement = frameDocument.body || frameDocument.documentElement;

      if (!reportElement || !reportElement.innerHTML.trim()) {
        throw new Error('Report HTML has no body content to convert');
      }

      normalizeReportDocument(
        frameDocument,
        Boolean(isRtl),
        widthPx,
        minHeightPx
      );
      injectReportPdfPageStyles(
        frameDocument,
        widthPx,
        minHeightPx,
        widthPt,
        heightPt,
        marginPt
      );

      await waitForReportLayout(frameDocument);

      const frameHeight = Math.max(
        frameDocument.documentElement.scrollHeight,
        frameDocument.body.scrollHeight,
        minHeightPx
      );
      frame.style.height = `${frameHeight}px`;
      reportElement.style.width = `${widthPx}px`;
      reportElement.style.minHeight = `${frameHeight}px`;
      reportElement.style.overflow = 'visible';

      await waitForNextPaint();

      const arrayBuffer = await window.html2pdf()
        .set({
          margin: [marginPt, marginPt, marginPt, marginPt],
          image: { type: 'jpeg', quality: 0.98 },
          html2canvas: {
            scale: 2,
            useCORS: true,
            allowTaint: true,
            logging: false,
            backgroundColor: '#ffffff',
            windowWidth: widthPx,
            windowHeight: frameHeight
          },
          jsPDF: {
            unit: 'pt',
            format: [widthPt, heightPt],
            orientation: widthPt > heightPt ? 'landscape' : 'portrait'
          },
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

  function normalizeReportDocument(frameDocument, isRtl, widthPx, minHeightPx) {
    const direction = isRtl ? 'rtl' : 'ltr';
    frameDocument.documentElement.dir = direction;
    frameDocument.documentElement.lang = isRtl ? 'ar' : 'en';
    frameDocument.documentElement.style.width = `${widthPx}px`;
    frameDocument.documentElement.style.minHeight = `${minHeightPx}px`;
    frameDocument.documentElement.style.overflow = 'visible';

    frameDocument.body.style.background = '#ffffff';
    frameDocument.body.style.color = '#000000';
    frameDocument.body.style.direction = direction;
    frameDocument.body.style.width = `${widthPx}px`;
    frameDocument.body.style.minHeight = `${minHeightPx}px`;
    frameDocument.body.style.overflow = 'visible';
    frameDocument.body.style.margin = frameDocument.body.style.margin || '0';
  }

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

  function injectReportPdfPageStyles(
    frameDocument,
    widthPx,
    minHeightPx,
    widthPt,
    heightPt,
    marginPt
  ) {
    const style = frameDocument.createElement('style');
    style.id = 'flutter-native-html-to-pdf-page-style';
    style.textContent = `
      @page { size: ${widthPt}pt ${heightPt}pt; margin: ${marginPt}pt; }
      html, body {
        width: ${widthPx}px !important;
        min-height: ${minHeightPx}px !important;
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
      img, svg, canvas {
        max-width: 100%;
        height: auto;
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

  function pointsToCssPixels(points) {
    return points * 96 / 72;
  }

  function millimetersToPoints(millimeters) {
    return millimeters * 72 / 25.4;
  }
})();
