<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0" exclude-result-prefixes="xsl tei xs">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes" />

    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Barrierefreiheit'" />
        <html lang="de">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
            </head>
            <body>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">
                        <div class="page-header">
                            <h1>Erklärung zur Barrierefreiheit</h1>
                        </div>
                        <article class="static-content">
                            <h2>Barrierefreie Gestaltung</h2>
                            <p>
                                Die Kommission für Geschichte des Parlamentarismus und der politischen
                                Parteien e.V. (KGParl) ist bemüht, ihre Website barrierefrei zu gestalten.
                                Diese Erklärung zur digitalen Barrierefreiheit gilt für die Website
                                der digitalen Edition der Fraktionsprotokolle.
                            </p>
                            <p>
                                Wir arbeiten kontinuierlich daran, die Zugänglichkeit und Benutzerfreundlichkeit
                                dieser Website zu verbessern und orientieren uns dabei an den Web Content
                                Accessibility Guidelines (WCAG) 2.1.
                            </p>

                            <h2>Schriftgröße anpassen</h2>
                            <p>
                                Sie können die Darstellung der Website in Ihrem Browser vergrößern oder
                                verkleinern:
                            </p>
                            <ul>
                                <li><strong>Vergrößern:</strong> Strg + Plus (Windows/Linux) oder Cmd + Plus (Mac)</li>
                                <li><strong>Verkleinern:</strong> Strg + Minus (Windows/Linux) oder Cmd + Minus (Mac)</li>
                                <li><strong>Zurücksetzen:</strong> Strg + 0 (Windows/Linux) oder Cmd + 0 (Mac)</li>
                            </ul>
                            <p>
                                Alternativ können Sie auch das Scrollrad Ihrer Maus bei gedrückter
                                Strg-Taste (bzw. Cmd-Taste auf Mac) verwenden.
                            </p>

                            <h2>Tastaturnavigation</h2>
                            <p>
                                Diese Website kann vollständig mit der Tastatur bedient werden:
                            </p>
                            <ul>
                                <li><strong>Tab:</strong> Zum nächsten interaktiven Element springen</li>
                                <li><strong>Shift + Tab:</strong> Zum vorherigen Element zurück</li>
                                <li><strong>Enter:</strong> Links aktivieren oder Schaltflächen betätigen</li>
                                <li><strong>Escape:</strong> Menüs oder Dialoge schließen</li>
                            </ul>

                            <h2>Dokumentformate</h2>
                            <p>
                                Die Protokolle werden als HTML-Seiten bereitgestellt und sind damit
                                in jedem modernen Browser lesbar. Zusätzlich stehen die Quelldateien
                                im XML-Format (TEI) zum Download zur Verfügung.
                            </p>
                            <p>
                                Für PDF-Dokumente empfehlen wir den
                                <a href="https://get.adobe.com/de/reader/" target="_blank" rel="noopener">Adobe Acrobat Reader</a>
                                oder einen anderen PDF-Reader Ihrer Wahl.
                            </p>

                            <h2>Bekannte Einschränkungen</h2>
                            <p>
                                Trotz unserer Bemühungen um Barrierefreiheit können einige Inhalte
                                Einschränkungen aufweisen:
                            </p>
                            <ul>
                                <li>Historische Dokumente und Faksimiles sind möglicherweise nicht
                                    vollständig barrierefrei zugänglich</li>
                                <li>Komplexe Tabellen in manchen Protokollen können für Screenreader
                                    schwer interpretierbar sein</li>
                                <li>Die Suchfunktion nutzt externe Dienste, deren Barrierefreiheit
                                    wir nicht vollständig kontrollieren können</li>
                            </ul>

                            <h2>Feedback und Kontakt</h2>
                            <p>
                                Wenn Sie auf Barrieren stoßen oder Verbesserungsvorschläge haben,
                                kontaktieren Sie uns bitte:
                            </p>
                            <p>
                                <strong>Kommission für Geschichte des Parlamentarismus und der politischen Parteien e.V.</strong><br/>
                                Schiffbauerdamm 40<br/>
                                10117 Berlin<br/><br/>
                                Telefon: <a href="tel:+493020633940">+49 (0)30 206 33 94-0</a><br/>
                                E-Mail: <a href="mailto:info@kgparl.de">info@kgparl.de</a>
                            </p>
                            <p>
                                Wir werden uns bemühen, Ihre Anfrage zeitnah zu beantworten und
                                gemeldete Probleme zu beheben.
                            </p>

                            <h2>Durchsetzungsverfahren</h2>
                            <p>
                                Sollten Sie der Meinung sein, dass unsere Antwort auf Ihre Anfrage
                                nicht zufriedenstellend war, können Sie sich an die zuständige
                                Durchsetzungsstelle wenden.
                            </p>
                        </article>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
