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
        <xsl:variable name="doc_title" select="'Kontakt'" />
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
                            <h1>Kontakt</h1>
                        </div>
                        <article class="static-content">
                            <h2>Kommission für Geschichte des Parlamentarismus und der politischen Parteien e.V.</h2>

                            <h3>Anschrift</h3>
                            <p>
                                Schiffbauerdamm 40<br/>
                                10117 Berlin
                            </p>

                            <h3>Telefon</h3>
                            <p><a href="tel:+493020633940">+49 (0)30 206 33 94-0</a></p>

                            <h3>Fax</h3>
                            <p>+49 (0)30 206 33 94-50</p>

                            <h3>E-Mail</h3>
                            <p><a href="mailto:info@kgparl.de">info@kgparl.de</a></p>

                            <h3>Website</h3>
                            <p><a href="https://www.kgparl.de" target="_blank" rel="noopener">www.kgparl.de</a></p>

                            <h2>Anfahrt</h2>
                            <p>
                                Die KGParl befindet sich in unmittelbarer Nähe des Reichstagsgebäudes und des Berliner Hauptbahnhofs.
                            </p>
                            <p>
                                <strong>Öffentliche Verkehrsmittel:</strong><br/>
                                S-Bahn: Berlin Hauptbahnhof oder Friedrichstraße<br/>
                                U-Bahn: Bundestag (U55) oder Friedrichstraße (U6)
                            </p>

                            <h2>Projekt Fraktionsprotokolle</h2>
                            <p>
                                Bei Fragen zu den Editionen der Fraktionsprotokolle oder technischen Problemen
                                mit dieser Website können Sie uns gerne über die oben genannten Kontaktdaten erreichen.
                            </p>
                            <p>
                                Weitere Informationen zu den Editionsprojekten finden Sie auf der
                                <a href="https://www.kgparl.de" target="_blank" rel="noopener">Homepage der KGParl</a>.
                            </p>
                        </article>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
