#!/usr/bin/env python3
"""
PDF Generator for Fraktionsprotokolle
Generates PDFs from HTML protocol pages using WeasyPrint.
"""

import os
import sys
import argparse
from pathlib import Path
from urllib.parse import urlparse
from datetime import datetime
import logging
import re

try:
    from weasyprint import HTML, CSS
    from weasyprint.text.fonts import FontConfiguration
except ImportError:
    print("WeasyPrint not installed. Run: pip install weasyprint")
    sys.exit(1)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# Get current date for footer
CURRENT_DATE = datetime.now().strftime("%d.%m.%Y")

# Custom CSS for PDF generation
ENV_BASE_URLS = {
    "test": "www.edition-bundestagsfraktionen.de",
    "live": "www.fraktionsprotokolle.de",
}


def get_pdf_css(document_id: str = "", env: str = "live") -> str:
    """Generate PDF CSS with document-specific footer URL."""
    base_domain = ENV_BASE_URLS.get(env, ENV_BASE_URLS["live"])
    if document_id:
        footer_url = f"{base_domain}/{document_id}.html"
    else:
        footer_url = base_domain

    return f"""
/* ==========================================================================
   PAGE SETUP
   ========================================================================== */
@page {{
    size: A4;
    margin: 2cm 2cm 2.5cm 2cm;

    @top-center {{
        content: "{footer_url}";
        font-size: 8pt;
        color: #048263;
    }}

    @bottom-center {{
        content: "Seite " counter(page) " von " counter(pages);
        font-size: 9pt;
        color: #666;
    }}

    @bottom-right {{
        content: "PDF erstellt am {CURRENT_DATE}";
        font-size: 8pt;
        color: #999;
    }}
}}

@page :first {{
    margin-top: 1.5cm;

    @top-center {{
        content: none;
    }}
}}

/* ==========================================================================
   GLOBAL WHITESPACE NORMALIZATION
   Prevents WeasyPrint errors from external stylesheets with white-space: pre
   ========================================================================== */
* {{
    white-space: normal !important;
}}

/* ==========================================================================
   HIDE NON-PRINT ELEMENTS
   ========================================================================== */
.kgparl-header,
.main-nav,
.kgparl-footer,
.sidebar-menu,
#hamburger-menu,
.breadcrumbs,
.menu-toggle,
.menu-overlay,
.skip-link,
.kgparl-btn-download,
button,
.back-to-top,
.edition-sidebar,
.facets-panel,
aside,
nav:not(#sitzungsverlauf),
[class*="facet"],
custom-checkbox {{
    display: none !important;
}}

/* ==========================================================================
   LAYOUT RESET
   ========================================================================== */
body {{
    font-family: "Georgia", "Times New Roman", serif;
    font-size: 11pt;
    line-height: 1.6;
    color: #000;
    background: #fff;
}}

.kgparl-container,
.edition-layout,
.edition-content,
#main-content,
#content-container {{
    width: 100% !important;
    max-width: none !important;
    margin: 0 !important;
    padding: 0 !important;
    display: block !important;
}}

.edition-layout {{
    display: block !important;
    flex-direction: unset !important;
}}

article.edition-content {{
    width: 100% !important;
}}

/* ==========================================================================
   TYPOGRAPHY
   ========================================================================== */
h1 {{
    font-size: 16pt;
    page-break-after: avoid;
    margin-top: 1cm;
    margin-bottom: 0.5cm;
}}

h2 {{
    font-size: 14pt;
    page-break-after: avoid;
    color: #048263;
}}

h3 {{
    font-size: 12pt;
    page-break-after: avoid;
}}

p {{
    orphans: 3;
    widows: 3;
    text-align: justify;
    hyphens: auto;
    margin-bottom: 0.4cm;
}}

/* ==========================================================================
   DETAILS/SUMMARY - Force open for PDF
   ========================================================================== */
details {{
    display: block !important;
}}

details[open] > summary ~ * {{
    display: block !important;
}}

summary {{
    display: block;
    font-weight: bold;
    margin-bottom: 0.3cm;
    color: #000;
}}

summary::marker,
summary::-webkit-details-marker {{
    display: none;
}}

/* ==========================================================================
   SITZUNGSINFO
   ========================================================================== */
#sitzungs-info {{
    margin-bottom: 1cm;
    padding-bottom: 0.5cm;
    border-bottom: 1pt solid #ccc;
}}

#sitzungs-info h2 {{
    color: #000;
    font-size: 16pt;
    margin-bottom: 0.3cm;
}}

#sitzungs-info .info-block {{
    background: #f5f5f5;
    padding: 0.4cm;
    font-size: 9pt;
    line-height: 1.4;
    margin-top: 0.3cm;
}}

/* Sitzungsverlauf */
#svplist,
#sitzungsverlauf ul {{
    list-style-type: none;
    padding-left: 0;
    margin: 0.3cm 0;
}}

#svplist li,
#sitzungsverlauf li {{
    margin-bottom: 0.15cm;
    font-size: 10pt;
    padding-left: 0.5cm;
    text-indent: -0.5cm;
    text-align: left;
}}

#svplist li::before,
#sitzungsverlauf li::before {{
    content: "• ";
    color: #000;
}}

/* Frontmatter (Sitzungsinfo, Sitzungsverlauf) komplett in Schwarz —
   spart Tonerfarbe, sieht im SW-Druck sauberer aus. Akzentfarben bleiben
   nur im eigentlichen Protokolltext (Fußnoten-Marker, kgparl-Links etc.). */
#sitzungs-info,
#sitzungs-info *,
#sitzungsverlauf,
#sitzungsverlauf *,
#svplist,
#svplist * {{
    color: #000 !important;
}}

/* ==========================================================================
   PERSON NAMES - Fix double display
   ========================================================================== */
/* popup-info: Basis-Styling */
popup-info {{
    display: inline;
}}

/* Slot content Element ausblenden */
[slot="content"],
span[slot="content"] {{
    display: none !important;
}}

/* PERSONEN: Kein ::before mit data-title - verhindert Dopplung (Konrad Adenauer + Adenauer) */
.person-mention popup-info::before,
.fw-bold popup-info::before,
[aria-haspopup] popup-info::before {{
    content: none !important;
    display: none !important;
}}

/* Personen-Erwähnung: kursiv */
.person-mention {{
    font-style: italic;
}}

.person-mention popup-info {{
    font-style: italic;
}}

/* Sprecher: fett */
.fw-bold {{
    font-weight: bold;
}}

.fw-bold popup-info {{
    font-weight: bold;
    font-style: normal;
}}

/* ==========================================================================
   FOOTER / KOOPERATIONSPARTNER AUSBLENDEN
   ========================================================================== */
.partner-section,
.kgparl-footer,
footer,
[class*="partner"],
[class*="logo-grid"],
contentinfo {{
    display: none !important;
}}

/* ==========================================================================
   FOOTNOTES - Inline references in text
   ========================================================================== */
/* Der eigentliche Fußnoten-Container */
.seg-note {{
    display: inline !important;
}}

/* Fußnoten-Marker — analog kgparl.css:1248ff: die Superscript-Transformation
   sitzt auf popup-info (nicht auf .seg-note-link!). Anders als im Web lassen
   wir line-height NICHT auf 0 fallen — das würde die Bounding-Box des inneren
   <a> kollabieren und WeasyPrint könnte keine klickbare Link-Annotation mehr
   erzeugen. */
.seg-note popup-info {{
    display: inline !important;
    font-size: 0.75em;
    vertical-align: super;
    font-weight: 500;
}}

.seg-note-link {{
    color: #006699;
    text-decoration: none !important;
    display: inline !important;
}}

/* Notenbereich: im PDF KEINE Unterstreichung — der Anker zur Fußnote ist
   ohnehin nur per Hochzahl klar, eine Linie verkomplext den Lauftext nur. */
.note-segment {{
    display: inline !important;
    text-decoration: none !important;
}}

/* ==========================================================================
   FOOTNOTES - List at end of document
   ========================================================================== */
#footnotes-container {{
    margin-top: 1cm;
    padding-top: 0.5cm;
    border-top: 1pt solid #ccc;
}}

/* Einzelne Fußnote */
.footnotes {{
    display: block !important;
    margin-bottom: 0.3cm;
    font-size: 9pt;
    line-height: 1.4;
}}

/* Fußnoten-Nummer am Anfang */
.footnotes .fn {{
    font-weight: bold;
    color: #048263;
    margin-right: 0.2cm;
}}

/* Fußnoten-Text */
.footnotes p {{
    display: inline !important;
    margin: 0;
}}

/* Rücklink-Pfeil: im PDF ohne Funktion, daher komplett ausblenden */
.fn-back {{
    display: none !important;
}}

/* ==========================================================================
   DESCRIPTIONS (Zwischenrufe)
   ========================================================================== */
.tei-desc,
incident desc {{
    display: block;
    font-style: italic;
    color: #555;
    margin: 0.3cm 0;
    text-align: center;
}}

/* ==========================================================================
   QUOTES
   Zitate werden im PDF NICHT als separat eingerückte Blöcke behandelt, damit
   (a) verschachtelte tei:quote keine kumulierte Einrückung erzeugen und
   (b) die Randglossen der enthaltenen <p> am einheitlichen rechten Satzrand
       ausgerichtet bleiben (der sonst durch den linken Versatz der
       Blockquotes relativ verschoben wirkt).
   ========================================================================== */
blockquote,
.tei-quote {{
    display: block;
    margin: 0;
    padding: 0;
    border: none;
    font-style: normal;
}}

/* Inline-Zitat innerhalb eines Absatzes bleibt als Lauftext — kein Block */
.tei-quote-compact {{
    display: inline;
    font-style: normal;
}}

/* ==========================================================================
   SECTION BREAKS
   Frontmatter (Sitzungsinfo + Sitzungsverlauf) bekommt einen expliziten
   Seitenumbruch danach, damit der eigentliche Protokolltext immer auf
   einer frischen Seite beginnt — und Seite 1 nicht halbleer wirkt, nur
   weil SVP-1 vorher nicht ganz auf die Seite gepasst hat.
   ========================================================================== */
#sitzungsverlauf {{
    page-break-after: always;
    break-after: page;
}}

h1[id*="SVP"],
.text-start.fw-bold[id*="SVP"] {{
    page-break-before: always;
    padding-top: 0.5cm;
    border-top: 0.5pt solid #ccc;
    margin-top: 0;
}}

/* SVP-1 darf direkt am Seitenanfang sitzen (kein zusätzlicher Top-Padding,
   kein Trennstrich — der Seitenumbruch davor reicht als Trennung). */
h1[id$="SVP-1"],
.text-start.fw-bold[id$="SVP-1"] {{
    padding-top: 0;
    border-top: none;
}}

/* ==========================================================================
   LINKS
   ========================================================================== */
a {{
    color: #000;
    text-decoration: none;
}}

a.kgparl-link {{
    color: #048263;
}}

/* ==========================================================================
   TABLES
   ========================================================================== */
table {{
    page-break-inside: avoid;
    border-collapse: collapse;
    width: 100%;
    margin: 0.5cm 0;
}}

th, td {{
    padding: 0.2cm;
    border: 0.5pt solid #ccc;
    text-align: left;
}}

th {{
    background: #f5f5f5;
    font-weight: bold;
}}

/* ==========================================================================
   MARGINALNUMMERN / RANDGLOSSEN
   Pro SVP-Abschnitt durchgezählt (Absätze + Zwischenrufe).
   Badge am rechten Textrand, innerhalb des Satzspiegels (nicht in der Seitenmarge),
   damit sie in WeasyPrint zuverlässig gerendert werden.
   ========================================================================== */
.svp-section {{
    counter-reset: rn;
}}

.svp-section p,
.svp-section > .tei-desc,
.svp-section .content > .tei-desc {{
    counter-increment: rn;
    position: relative;
    padding-right: 2cm;
}}

.svp-section p::before,
.svp-section > .tei-desc::before,
.svp-section .content > .tei-desc::before {{
    content: "[" counter(rn) "]";
    position: absolute;
    right: 0;
    /* auf Höhe der ersten Textzeile ausrichten — die absolute line-height
       entspricht dem Fließtext (11pt × 1.6 ≈ 17.6pt), damit die Grundlinie
       der Randziffer mit der Grundlinie der ersten Zeile übereinstimmt.
       ::before (statt ::after), damit das Pseudo-Element bei Seitenumbruch
       mit dem ERSTEN Fragment des Absatzes mitwandert — sonst rutscht die
       Randziffer auf die nächste Seite, wenn der Absatz umbrochen wird. */
    top: 0;
    line-height: 17.6pt;
    font-size: 7.5pt;
    color: #888;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
    font-style: normal;
    font-weight: normal;
}}

/* ==========================================================================
   ORGANIZATION NAMES
   ========================================================================== */
.org-mention {{
    color: #666;
}}

/* ==========================================================================
   SMALL CAPS
   ========================================================================== */
.small-caps {{
    font-variant: small-caps;
}}
"""


def preprocess_html(html_content: str) -> str:
    """
    Preprocess HTML to fix issues before PDF generation.
    - Opens all details elements
    - Extracts footnote text from popup-info data-title and adds it visibly
    - Normalizes whitespace to prevent WeasyPrint layout errors
    """
    import re

    # Force all details elements to be open
    html_content = html_content.replace('<details>', '<details open>')
    html_content = html_content.replace('<details ', '<details open ')

    # Remove duplicate 'open' attributes
    html_content = html_content.replace('open open', 'open')

    # Remove external stylesheet links - we use our own custom CSS
    # This prevents external CSS from causing WeasyPrint layout errors
    html_content = re.sub(
        r'<link[^>]*rel=["\']stylesheet["\'][^>]*>', '', html_content)
    html_content = re.sub(
        r'<link[^>]*href=["\'][^"\']*\.css["\'][^>]*>', '', html_content)

    # Aggressive whitespace normalization to prevent WeasyPrint errors
    # The error "Got ' \n' between two lines" occurs when there's a space followed by newline
    # Convert all sequences containing newlines to single spaces
    html_content = re.sub(r'[ \t]*\n[ \t]*', ' ', html_content)

    # Clean up any resulting multiple spaces
    html_content = re.sub(r'  +', ' ', html_content)

    # Strip whitespace am inneren Rand von .note-segment, damit die
    # text-decoration: underline nicht auf Leerraum rechts/links der
    # hochgestellten Fußnotenzahl liegen bleibt.
    html_content = re.sub(
        r'(<span class="note-segment"[^>]*>)\s+(<span[^>]*seg-note)',
        r'\1\2', html_content)
    html_content = re.sub(
        r'(</popup-info>\s*</span>)\s+(</span>)',
        r'\1\2', html_content)

    return html_content


def generate_pdf(source: str, output_path: str, base_url: str = None, env: str = "live") -> bool:
    """
    Generate PDF from HTML source (file path or URL).

    Args:
        source: Path to HTML file or URL
        output_path: Output PDF file path
        base_url: Base URL for resolving relative links (optional)

    Returns:
        True if successful, False otherwise
    """
    try:
        font_config = FontConfiguration()
        import urllib.request

        # Extract document ID from source for footer URL
        if source.startswith(('http://', 'https://')):
            document_id = urlparse(source).path.split('/')[-1].replace('.html', '')
        else:
            document_id = Path(source).stem

        # Determine if source is URL or file
        if source.startswith(('http://', 'https://')):
            logger.info(f"Fetching: {source}")
            if not base_url:
                parsed = urlparse(source)
                base_url = f"{parsed.scheme}://{parsed.netloc}"

            # Fetch HTML content for preprocessing
            with urllib.request.urlopen(source) as response:
                html_content = response.read().decode('utf-8')

            html_content = preprocess_html(html_content)
            html = HTML(string=html_content, base_url=base_url)
        else:
            source_path = Path(source)
            if not source_path.exists():
                logger.error(f"File not found: {source}")
                return False
            logger.info(f"Reading: {source}")

            # Read and preprocess HTML
            with open(source_path, 'r', encoding='utf-8') as f:
                html_content = f.read()

            html_content = preprocess_html(html_content)
            html = HTML(string=html_content,
                        base_url=base_url or str(source_path.parent))

        # Create output directory if needed
        output_dir = Path(output_path).parent
        output_dir.mkdir(parents=True, exist_ok=True)

        # Generate PDF with custom CSS
        pdf_css = get_pdf_css(document_id, env=env)
        logger.info(f"Generating PDF: {output_path}")
        html.write_pdf(
            output_path,
            stylesheets=[CSS(string=pdf_css, font_config=font_config)],
            font_config=font_config
        )

        # Check file size
        size = os.path.getsize(output_path)
        logger.info(f"Created: {output_path} ({size / 1024:.1f} KB)")
        return True

    except Exception as e:
        logger.error(f"Error generating PDF: {e}")
        import traceback
        traceback.print_exc()
        return False


def batch_generate(html_dir: str, output_dir: str, pattern: str = "*.html", env: str = "live") -> int:
    """
    Generate PDFs for all matching HTML files in a directory.

    Args:
        html_dir: Directory containing HTML files
        output_dir: Output directory for PDFs
        pattern: Glob pattern for HTML files

    Returns:
        Number of successfully generated PDFs
    """
    html_path = Path(html_dir)
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    # Find protocol HTML files (exclude index, liste, etc.)
    exclude_names = {
        'index', 'liste', 'suche', 'kalender', 'hilfe',
        'impressum', 'datenschutz', 'kontakt', 'barrierefreiheit'
    }

    html_files = [
        f for f in html_path.glob(pattern)
        if f.stem not in exclude_names
        and not f.stem.startswith('_')
        and 'Einleitung' not in f.stem
        and any(party in f.stem for party in ['cdu-csu', 'spd', 'fdp', 'gruene', 'csu-lg', 'linke', 'pds'])
    ]

    logger.info(f"Found {len(html_files)} protocol files")

    success_count = 0
    skipped_count = 0
    for i, html_file in enumerate(sorted(html_files), 1):
        pdf_name = html_file.stem + '.pdf'
        pdf_path = out_path / pdf_name

        # Skip if PDF exists and is newer than the HTML source
        if pdf_path.exists() and pdf_path.stat().st_mtime >= html_file.stat().st_mtime:
            skipped_count += 1
            logger.debug(f"[{i}/{len(html_files)}] Skipped (unchanged): {html_file.name}")
            continue

        logger.info(f"[{i}/{len(html_files)}] Processing: {html_file.name}")

        if generate_pdf(str(html_file), str(pdf_path), base_url=str(html_path), env=env):
            success_count += 1

    logger.info(f"Generated {success_count}/{len(html_files)} PDFs, skipped {skipped_count} unchanged")
    return success_count


def main():
    parser = argparse.ArgumentParser(
        description='Generate PDFs from Fraktionsprotokolle HTML files'
    )
    parser.add_argument(
        'source',
        help='HTML file path, URL, or directory for batch processing'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output PDF path or directory',
        default=None
    )
    parser.add_argument(
        '-b', '--batch',
        action='store_true',
        help='Batch process all HTML files in directory'
    )
    parser.add_argument(
        '--base-url',
        help='Base URL for resolving relative links',
        default=None
    )
    parser.add_argument(
        '--env',
        choices=['test', 'live'],
        default=os.environ.get('ENV', 'live'),
        help='Environment (test/live) for URL generation (default: ENV variable or live)'
    )

    args = parser.parse_args()

    if args.batch:
        output_dir = args.output or './html/downloads'
        batch_generate(args.source, output_dir, env=args.env)
    else:
        # Single file/URL
        if args.output:
            output_path = args.output
        else:
            # Generate output name from source
            if args.source.startswith(('http://', 'https://')):
                name = urlparse(args.source).path.split('/')[-1]
                name = name.replace('.html', '.pdf')
            else:
                name = Path(args.source).stem + '.pdf'
            output_path = f'./html/downloads/{name}'

        success = generate_pdf(args.source, output_path, args.base_url, env=args.env)
        sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
