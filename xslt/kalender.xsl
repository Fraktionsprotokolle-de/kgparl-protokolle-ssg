<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="http://dse-static.foo.bar"
    version="2.0" exclude-result-prefixes="xsl tei xs local">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes"
        omit-xml-declaration="yes" />

    <xsl:import href="partials/html_navbar.xsl" />
    <xsl:import href="partials/html_head.xsl" />
    <xsl:import href="partials/html_footer.xsl" />

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Kalender'" />
        <html lang="de">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
                <script src="https://code.jquery.com/jquery-3.6.3.min.js"
                    integrity="sha256-pvPw+upLPUjgMXY0G+8O0xUf+/Im1MZjXxxgOcBQBXU="
                    crossorigin="anonymous"></script>
                <!-- Calendar CSS -->
                <link rel="stylesheet" type="text/css"
                    href="https://unpkg.com/js-year-calendar@latest/dist/js-year-calendar.min.css" />
                <script src="https://unpkg.com/js-year-calendar@latest/dist/js-year-calendar.min.js"></script>
                <script
                    src="https://unpkg.com/js-year-calendar@latest/locales/js-year-calendar.de.js"></script>
            </head>
            <body>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">
                        <div class="page-header text-center">
                            <h1 data-i18n="calendar.title">Kalender</h1>
                            <p data-i18n="calendar.description">Kalenderansicht der Sitzungsprotokolle</p>
                        </div>

                        <!-- Year Navigation Controls -->
                        <div class="calendar-navigation">
                            <button class="kgparl-btn-icon" id="decade-prev" data-i18n="[title]calendar.tenYearsBack;[aria-label]calendar.tenYearsBack" title="10 Jahre zurück" aria-label="10 Jahre zurück">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                    <path fill-rule="evenodd" d="M8.354 1.646a.5.5 0 0 1 0 .708L2.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/>
                                    <path fill-rule="evenodd" d="M12.354 1.646a.5.5 0 0 1 0 .708L6.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/>
                                </svg>
                            </button>

                            <button class="kgparl-btn-icon" id="year-prev" data-i18n="[title]calendar.oneYearBack;[aria-label]calendar.oneYearBack" title="1 Jahr zurück" aria-label="1 Jahr zurück">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                    <path fill-rule="evenodd" d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/>
                                </svg>
                            </button>

                            <button class="calendar-year-btn" id="year-display" type="button">
                                <span id="year-display-text">1949</span>
                            </button>

                            <button class="kgparl-btn-icon" id="year-next" data-i18n="[title]calendar.oneYearForward;[aria-label]calendar.oneYearForward" title="1 Jahr vor" aria-label="1 Jahr vor">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                    <path fill-rule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/>
                                </svg>
                            </button>

                            <button class="kgparl-btn-icon" id="decade-next" data-i18n="[title]calendar.tenYearsForward;[aria-label]calendar.tenYearsForward" title="10 Jahre vor" aria-label="10 Jahre vor">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                    <path fill-rule="evenodd" d="M3.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L9.293 8 3.646 2.354a.5.5 0 0 1 0-.708z"/>
                                    <path fill-rule="evenodd" d="M7.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L13.293 8 7.646 2.354a.5.5 0 0 1 0-.708z"/>
                                </svg>
                            </button>
                        </div>

                        <!-- Inline Legend (collapsible) -->
                        <details class="calendar-legend" id="calendar-legend">
                            <summary class="calendar-legend-toggle">
                                <span data-i18n="calendar.howToUse">Legende und Hinweise</span>
                            </summary>
                            <div class="calendar-legend-body">
                                <div class="calendar-legend-colors">
                                    <span class="calendar-legend-item">
                                        <span class="legend-swatch" style="background:#FF0000;"></span>
                                        <span data-i18n="calendar.spd">SPD</span>
                                    </span>
                                    <span class="calendar-legend-item">
                                        <span class="legend-swatch" style="background:#000000;"></span>
                                        <span data-i18n="calendar.cducsu">CDU/CSU</span>
                                    </span>
                                    <span class="calendar-legend-item">
                                        <span class="legend-swatch" style="background:#0080c8;"></span>
                                        <span data-i18n="calendar.csu">CSU-LG</span>
                                    </span>
                                    <span class="calendar-legend-item">
                                        <span class="legend-swatch" style="background:#FFFF00; border: 1px solid #ccc;"></span>
                                        <span data-i18n="calendar.fdp">FDP</span>
                                    </span>
                                    <span class="calendar-legend-item">
                                        <span class="legend-swatch" style="background:#00FF00;"></span>
                                        <span data-i18n="calendar.greens">Grüne</span>
                                    </span>
                                    <span class="calendar-legend-item">
                                        <span class="legend-swatch" style="background:#800080;"></span>
                                        <span data-i18n="calendar.linke">PDS/Linke</span>
                                    </span>
                                </div>
                                <p class="calendar-legend-hint" data-i18n="calendar.calendarExplanation">Farbig markierte Tage zeigen Fraktionssitzungen an. Bewegen Sie den Cursor über einen Tag, um die Sitzungen zu sehen, und klicken Sie auf einen Tagesordnungspunkt, um das Protokoll zu öffnen.</p>
                                <p class="calendar-legend-hint" data-i18n="calendar.yearInputHint">Klicken Sie auf die Jahreszahl, um direkt ein bestimmtes Jahr einzugeben.</p>
                            </div>
                        </details>

                        <!-- Calendar Container -->
                        <div id="calendar" class="calendar-container"></div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
            </body>
            <script src="js-data/calendarData.js"></script>
            <script src="js/searchUtils.js"></script>
            <script src="js/popover.js"></script>
            <script src="js/calendar.js"></script>
        </html>
    </xsl:template>
</xsl:stylesheet>
