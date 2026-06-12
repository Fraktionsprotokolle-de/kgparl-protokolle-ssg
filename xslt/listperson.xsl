<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY copy "&#169;">
    <!ENTITY nbsp "&#160;">
    <!ENTITY ndash "&#8211;">
]>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0" exclude-result-prefixes="xsl tei xs">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes"
        omit-xml-declaration="yes" />

    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />
    <xsl:import href="./fraktionsprotokolle.xslt" />
    <xsl:import href="./partials/person.xsl" />

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select=".//tei:titleStmt/tei:title[1]/text()" />
        </xsl:variable>
        <xsl:variable
            name="col" select="collection('../build/valid-editions/?select=*.xml;recurse=no')" />
        <xsl:variable
            name="heute" select="current-date()" />
        <xsl:variable name="countPersonenAll"
            select="count(.//tei:person)" />
        <xsl:variable name="standDatum"
            select=".//tei:publicationStmt/tei:date/@when" />
        <html lang="de">

            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
                <script
                    src="https://cdn.jsdelivr.net/npm/typesense-instantsearch-adapter@2/dist/typesense-instantsearch-adapter.min.js" />
                <script
                    src="https://cdn.jsdelivr.net/npm/algoliasearch@4.5.1/dist/algoliasearch-lite.umd.js"
                    integrity="sha256-EXPXz4W6pQgfYY3yTpnDa3OH8/EPn16ciVsPQ/ypsjk="
                    crossorigin="anonymous" />
                <script
                    src="https://cdn.jsdelivr.net/npm/instantsearch.js@4.74.1/dist/instantsearch.production.min.js"
                    crossorigin="anonymous" />
            </head>


            <body>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">
                        <div class="page-header">
                            <h1 data-i18n="personRegister.title">Personenregister</h1>
                            <p class="register-count" id="register-total-count">
                                <xsl:value-of select="$countPersonenAll" />
                                <xsl:text> </xsl:text>
                                <span data-i18n="personRegister.description">Personen im Personenregister</span>
                            </p>
                        </div>

                        <div class="list-page-layout">
                            <div class="list-main-content">
                                <div class="list-searchbox" id="searchbox"></div>
                                <details class="search-syntax-help">
                                    <summary data-i18n="search.syntaxHelpTitle">Suchsyntax</summary>
                                    <div class="details-content">
                                        <table class="search-syntax-table">
                                            <thead>
                                                <tr>
                                                    <th scope="col" data-i18n="search.syntaxOperator">Operator</th>
                                                    <th scope="col" data-i18n="search.syntaxExample">Beispiel</th>
                                                    <th scope="col" data-i18n="search.syntaxDescription">Beschreibung</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td><code>NOT</code></td>
                                                    <td><code>Müller NOT Schmidt</code></td>
                                                    <td data-i18n="search.syntaxNotDesc">Schließt Treffer aus, die den zweiten Begriff enthalten</td>
                                                </tr>
                                                <tr>
                                                    <td><code>-</code></td>
                                                    <td><code>Müller -Schmidt</code></td>
                                                    <td data-i18n="search.syntaxMinusDesc">Kurzform für NOT (ohne Leerzeichen vor dem Begriff)</td>
                                                </tr>
                                                <tr>
                                                    <td><code>"..."</code></td>
                                                    <td><code>"von Braun"</code></td>
                                                    <td data-i18n="search.syntaxPhraseDesc">Sucht nach der exakten Wortfolge</td>
                                                </tr>
                                                <tr>
                                                    <td><code>NOT</code> + <code>"..."</code></td>
                                                    <td><code>"von Braun" NOT Wernher</code></td>
                                                    <td data-i18n="search.syntaxCombinedDesc">Kombinierte Suche: Phrase ohne bestimmte Begriffe</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                        <p class="search-syntax-note">
                                            <strong data-i18n="search.letterHintLabel">Hinweis:</strong>&#160;<span data-i18n="search.letterHintText">Die Buchstabennavigation und die Texteingabe schließen sich gegenseitig aus. Bei Eingabe eines Suchbegriffs wird ein aktiver Buchstabenfilter zurückgesetzt und umgekehrt.</span>
                                        </p>
                                    </div>
                                </details>
                                <div class="register-separator">
                                    <span data-i18n="personRegister.or">oder</span>
                                </div>
                                <p class="register-letter-hint" data-i18n="personRegister.letterHint">Alle Personen anzeigen, deren Nachname mit dem gewählten Buchstaben beginnt:</p>
                                <div id="letters" class="person-letters"></div>
                                <div id="allFound" class="search-stats" data-stand="{$standDatum}"></div>
                                <div class="list-hits" id="hits"></div>
                                <div class="list-pagination" id="pagination"></div>
                            </div>

                            <aside class="list-sidebar" aria-label="Optionen">
                                <h2 data-i18n="protocols.hitsPerPage">Treffer pro Seite</h2>
                                <div id="hits-per-page"></div>
                            </aside>
                        </div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
                <script src="js/searchUtils.js"></script>
                <script src="js/personenregister.js"></script>
            </body>
        </html>


        <xsl:for-each
            select=".//tei:listPerson[not(@type='Mitarbeiter-KGParl')]/tei:person">
            <xsl:variable name="person_id" select="data(@xml:id)" />
            <xsl:variable name="filename"
                select="concat(./@xml:id, '.html')" />
            <xsl:variable name="anzeigename">
                <xsl:if test="./tei:addName[@type='preaefix']">
                    <xsl:value-of select="./tei:addName[@type='preaefix']" />
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="string-length(./tei:persName[@n='1']/tei:surname) > 0 and string-length(./tei:persName[@n='1']/tei:forename) > 0">
                        <xsl:value-of select="./tei:persName[@n='1']/tei:surname/text()" />
                        <xsl:text>, </xsl:text>
                        <xsl:value-of select="./tei:persName[@n='1']/tei:forename/text()" />
                    </xsl:when>
                    <xsl:when test="string-length(./tei:persName[@n='1']/tei:surname) > 0">
                        <xsl:value-of select="./tei:persName[@n='1']/tei:surname/text()" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="./tei:persName[@n='1']/tei:forename/text()" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable
                name="name"
                select="normalize-space(string-join(./tei:persName[@type='display']/text()))"></xsl:variable>
            <xsl:variable name="facet_name">
                <xsl:choose>
                    <xsl:when test="string-length(./tei:persName[@n='1']/tei:surname) > 0 and string-length(./tei:persName[@n='1']/tei:forename) > 0">
                        <xsl:value-of select="./tei:persName[@n='1']/tei:surname/text()" />
                        <xsl:text>, </xsl:text>
                        <xsl:value-of select="./tei:persName[@n='1']/tei:forename/text()" />
                    </xsl:when>
                    <xsl:when test="string-length(./tei:persName[@n='1']/tei:surname) > 0">
                        <xsl:value-of select="./tei:persName[@n='1']/tei:surname/text()" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="./tei:persName[@n='1']/tei:forename/text()" />
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="./tei:addName[@type='preaefix']">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="./tei:addName[@type='preaefix']" />
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="hashedid" select="concat('#', $person_id)" />
            <xsl:variable name="hits"
                select="$col//tei:name[@type='Person' and @ref=$hashedid]" />
            <xsl:variable
                name="distinct" select="distinct-values($hits/base-uri(.))" />
            <xsl:variable
                name="birth">
                <xsl:if test=".//tei:birth/tei:date/@when">
                    <xsl:variable name="bw" select=".//tei:birth/tei:date/@when" />
                    <xsl:choose>
                        <xsl:when test="starts-with($bw, '-')">
                            <xsl:value-of select="number(substring($bw, 2))" />
                            <xsl:text> v.&#160;Chr.</xsl:text>
                        </xsl:when>
                        <xsl:when test="string-length($bw) = 10">
                            <xsl:value-of
                                select="format-date(xs:date($bw), '[D]. [MNn] [Y]', 'de', (), ())" />
                        </xsl:when>
                        <xsl:when test="string-length($bw) = 7">
                            <xsl:value-of
                                select="format-date(xs:date(concat($bw, '-01')), '[MNn] [Y]', 'de', (), ())" />
                        </xsl:when>
                        <xsl:when test="string-length($bw) = 4">
                            <xsl:value-of select="number($bw)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$bw" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="death">
                <xsl:if test=".//tei:death/tei:date/@when">
                    <xsl:variable name="dw" select=".//tei:death/tei:date/@when" />
                    <xsl:choose>
                        <xsl:when test="starts-with($dw, '-')">
                            <xsl:value-of select="number(substring($dw, 2))" />
                            <xsl:text> v.&#160;Chr.</xsl:text>
                        </xsl:when>
                        <xsl:when test="string-length($dw) = 10">
                            <xsl:value-of
                                select="format-date(xs:date($dw), '[D]. [MNn] [Y]', 'de', (), ())" />
                        </xsl:when>
                        <xsl:when test="string-length($dw) = 7">
                            <xsl:value-of
                                select="format-date(xs:date(concat($dw, '-01')), '[MNn] [Y]', 'de', (), ())" />
                        </xsl:when>
                        <xsl:when test="string-length($dw) = 4">
                            <xsl:value-of select="number($dw)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$dw" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="birthplace">
                <xsl:if test=".//tei:birth/tei:placeName">
                    <xsl:value-of select="./tei:birth/tei:placeName" />
                </xsl:if>
                <xsl:if
                    test="string-length(.//tei:birth/tei:country[1]) > 0">
                    <xsl:value-of select="concat(' (', .//tei:birth/tei:country[1], ')')" />
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="deathplace">
                <xsl:if test=".//tei:death/tei:placeName">
                    <xsl:value-of select=".//tei:death/tei:placeName" />
                </xsl:if>
                <xsl:if
                    test="string-length(.//tei:death/tei:country[1]) > 0">
                    <xsl:value-of select="concat(' (', .//tei:death/tei:country[1], ')')" />
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="birthstring">
                <xsl:if test="$birth">
                    <xsl:value-of select="$birth" />
                </xsl:if>
                <xsl:if
                    test="string-length($birthplace) != 0">
                    <xsl:text> in </xsl:text>
                    <xsl:value-of select="$birthplace" />
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="deathstring">
                <xsl:if test="$death">
                    <xsl:value-of select="$death" />
                </xsl:if>
                <xsl:if
                    test="string-length($deathplace) != 0">
                    <xsl:text> in </xsl:text>
                    <xsl:value-of select="$deathplace" />
                </xsl:if>
            </xsl:variable>

            <xsl:variable
                name="occupation">
                <xsl:if test=".//tei:affiliation[@type='Erwerbsarbeit']">
                    <xsl:value-of select=".//tei:affiliation[@type='Erwerbsarbeit']" />
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="sonstiges">
                <xsl:if test=".//tei:affiliation[@type='Sonstiges']">
                    <xsl:value-of select=".//tei:affiliation[@type='Sonstiges']" />
                </xsl:if>
            </xsl:variable>
            <xsl:variable
                name="periods">
                <xsl:if test=".//tei:affiliation[@type='Wahlperioden']">
                    <xsl:copy-of select=".//tei:affiliation[@type='Wahlperioden']" />
                </xsl:if>
            </xsl:variable>

            <xsl:variable
                name="idnos">
                <xsl:if test=".//tei:idno[not(@type='dip_personen_id')]">
                    <xsl:copy-of select=".//tei:idno[not(@type='dip_personen_id')]" />
                </xsl:if>
            </xsl:variable>

            <xsl:variable
                name="mdb" select="./ancestor-or-self::tei:listPerson[@type='MdB']" />

            <xsl:variable
                name="count">
                <xsl:value-of
                    select="count($distinct)"
                />
            </xsl:variable>
            <xsl:result-document
                href="{$filename}">
                <html lang="de">
                    <head>

                        <xsl:call-template name="html_head">
                            <xsl:with-param name="html_title" select="$name"></xsl:with-param>
                        </xsl:call-template>
                        <link
                            rel="stylesheet"
                            href="https://cdn.datatables.net/1.12.1/css/jquery.dataTables.css"
                        />
                        <link rel="stylesheet" href="css/kgparl.css" />
                        <script src="https://cdn.datatables.net/1.12.1/js/jquery.dataTables.js"></script>
                        <script
                            src="//cdn.datatables.net/plug-ins/1.12.1/pagination/ellipses.js"></script>
                        <!--<script
                    src="https://cdn.datatables.net/plug-ins/2.1.8/sorting/datetime-moment.js"></script>-->
                    </head>

                    <body>
                        <xsl:call-template name="nav_bar" />

                        <main class="main-content" id="main-content">
                            <div class="kgparl-container">
                                <div class="page-header">
                                    <h1>
                                        <xsl:value-of select="$name" />
                                        <xsl:if test="$mdb">
                                            <xsl:text> </xsl:text>
                                            <span class="person-result-badge">MdB</span>
                                        </xsl:if>
                                    </h1>
                                    <xsl:choose>
                                        <xsl:when test="count($distinct) > 0">
                                            <a class="kgparl-btn-outline person-facet-link"
                                                id="person-facet-link"
                                                data-person-name="{$facet_name}"
                                                href="liste.html"
                                                data-i18n="personRegister.addToFacet">
                                                In Personenfacette übernehmen
                                            </a>
                                            <script>
                                                <xsl:text disable-output-escaping="yes"><![CDATA[
                                                (function() {
                                                    var col = typeof TYPESENSE_COLLECTIONS !== 'undefined' ? TYPESENSE_COLLECTIONS.protocols : 'kgparl';
                                                    var link = document.getElementById('person-facet-link');
                                                    var name = link.getAttribute('data-person-name');
                                                    link.href = 'liste.html?' + encodeURIComponent(col + '[refinementList][persons][0]') + '=' + encodeURIComponent(name);
                                                })();
                                            ]]></xsl:text>
                                            </script>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <button type="button"
                                                class="kgparl-btn-outline person-facet-link"
                                                disabled="disabled"
                                                aria-disabled="true"
                                                data-i18n="personRegister.addToFacet">
                                                In Personenfacette übernehmen
                                            </button>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </div>

                                <div>
                                    <xsl:attribute name="class">
                                        <xsl:text>person-detail-grid</xsl:text>
                                        <xsl:if test="not(count($periods/*) > 0)"> no-membership</xsl:if>
                                    </xsl:attribute>
                                    <div class="person-info-section">
                                        <h2 data-i18n="personRegister.personalInfo">Persönliche
        Informationen</h2>
                                        <div class="person-card">
                                            <div class="person-card-body">
                                                <ul class="list-plain">
                                                    <li class="person-name-header">
                                                        <b><xsl:value-of select="$anzeigename" /></b>
                                                        <xsl:if
                                                            test="string-length(.//tei:persName[@n = '1']/tei:addName[@type='Ort']) > 0">
                                                            <xsl:text> </xsl:text>
                                                            <xsl:value-of
                                                                select=".//tei:persName[@n = '1']/tei:addName[@type='Ort']" />
                                                        </xsl:if>
                                                        <br />
                                                        [<span data-i18n="personRegister.displayName">Anzeigename
                                                        in der Edition:</span><xsl:text> </xsl:text><xsl:value-of
                                                        select="$name" />]
                                                    </li>
                                                    <xsl:if
                                                        test=".//tei:persName[@n = '2']">
                                                        <br />
                                                        <i
                                                            data-i18n="personRegister.nameVariants">
        Namensvarianten:</i>
                                                        <ul>
                                                            <xsl:for-each
                                                                select=".//tei:persName[@n != '1']">

                                                                <li>
                                                                    <xsl:if
                                                                        test="./tei:addName[@type='preaefix']">
                                                                        <xsl:value-of
                                                                            select="./tei:addName[@type='preaefix']" />
                                                                        <xsl:text> </xsl:text>
                                                                    </xsl:if>
                                                                    <xsl:value-of
                                                                        select=".//tei:surname/text()" />
                                                                    <xsl:text>, </xsl:text>
                                                                    <xsl:value-of
                                                                        select=".//tei:forename/text()" />
                                                                    <xsl:if
                                                                        test="string-length(./tei:addName[@type='Ort']) > 0">
                                                                        <xsl:text> </xsl:text>
                                                                        <xsl:value-of
                                                                            select="./tei:addName[@type='Ort']" />
                                                                    </xsl:if>
                                                                </li>
                                                            </xsl:for-each>
                                                        </ul>
                                                        <br />
                                                    </xsl:if>

                                                    <xsl:if
                                                        test="string-length(normalize-space($birthstring)) > 0">
                                                        <li>
                                                            <span data-i18n="personRegister.born">
        Geboren:</span><xsl:text> </xsl:text>
                                                            <xsl:value-of
                                                                select="$birthstring" />
                                                        </li>
                                                    </xsl:if>
                                                    <xsl:if
                                                        test="string-length(normalize-space($deathstring)) > 0">
                                                        <li>
                                                            <span data-i18n="personRegister.died">
        Gestorben:</span><xsl:text> </xsl:text>
                                                            <xsl:value-of
                                                                select="$deathstring" />
                                                        </li>
                                                    </xsl:if>
                                                    <xsl:if
                                                        test="string-length(normalize-space($occupation)) > 0">
                                                        <li>
                                                            <span
                                                                data-i18n="personRegister.occupation">
        Tätigkeit(en):</span><xsl:text> </xsl:text>
                                                            <xsl:value-of
                                                                select="$occupation" />
                                                        </li>
                                                    </xsl:if>
                                                    <xsl:if
                                                        test="string-length($sonstiges) > 0">
                                                        <li>
                                                            <span>Sonstiges:</span><xsl:text> </xsl:text>
                                                            <xsl:value-of
                                                                select="$sonstiges" />
                                                        </li>
                                                    </xsl:if>
                                                </ul>
                                            </div>
                                        </div>
                                        <xsl:if test="$idnos//*[text() != '']">
                                        <br />
                                        <h3 class="section-heading"
                                            data-i18n="personRegister.linkedOffers">Vernetzte
        Angebote</h3>
                                        <div class="person-card">
                                            <div class="person-card-body">
                                                <ul class="linked-offers-list">
                                                        <xsl:for-each
                                                            select="$idnos//*[text() != '']">
                                                            <xsl:if test="@type='MDB_Stammdaten'">
                                                                <li>
                                                                    <span
                                                                        data-i18n="personRegister.mdbNumber">
        MdB-Stammdatennummer</span>
                                                                    <xsl:text>: </xsl:text>
                                                                    <xsl:value-of select=".//text()" />
                                                                </li>
                                                            </xsl:if>
                                                            <xsl:if
                                                                test="not(@type='MDB_Stammdaten')">
                                                                <li>
                                                                    <xsl:value-of select="@type" />
                                                                    <xsl:text>:</xsl:text>
                                                                    <br />
                                                                    <a href="{.//text()}" target="_blank" rel="noopener">
                                                                        <xsl:value-of select=".//text()" />
                                                                    </a>
                                                                </li>
                                                                <!-- NDB link derived from GND -->
                                                                <xsl:if test="@type='Wikipedia'">
                                                                    <xsl:variable name="gnd_url" select="../tei:idno[@type='GND']/text()" />
                                                                    <xsl:if test="$gnd_url and $gnd_url != ''">
                                                                        <xsl:variable name="gnd_id" select="substring-after($gnd_url, '/gnd/')" />
                                                                        <xsl:if test="$gnd_id != ''">
                                                                            <xsl:variable name="ndb_url" select="concat('https://www.deutsche-biographie.de/gnd', $gnd_id, '.html')" />
                                                                            <li>
                                                                                <xsl:text>NDB/ADB:</xsl:text>
                                                                                <br />
                                                                                <a href="{$ndb_url}" target="_blank" rel="noopener">
                                                                                    <xsl:value-of select="$ndb_url" />
                                                                                </a>
                                                                            </li>
                                                                        </xsl:if>
                                                                    </xsl:if>
                                                                </xsl:if>
                                                            </xsl:if>
                                                        </xsl:for-each>
                                                </ul>
                                            </div>
                                        </div>
                                        </xsl:if>
                                    </div>

                                    <xsl:if test="count($periods/*) > 0">
                                        <div class="person-membership-section">
                                            <h2 data-i18n="personRegister.bundestagMembership">Mitgliedschaft
        im Bundestag</h2>
                                            <div class="membership-grouped">

                                                <xsl:for-each-group
                                                    select="$periods//tei:affiliation[@type='Wahlperiode']"
                                                    group-by=".//tei:affiliation[@type='Fraktionszugehoerigkeiten']/tei:affiliation[@type='Fraktionszugehoerigkeit']">
                                                    <div class="membership-party-group">
                                                        <h3 class="membership-party-name">
                                                            <xsl:value-of
                                                                select="current-grouping-key()" />
                                                        </h3>
                                                        <ul class="membership-periods-list">
                                                            <xsl:for-each select="current-group()">
                                                                <xsl:sort
                                                                    select="replace(@period, '#wp', '')"
                                                                    data-type="number" />
                                                                <xsl:variable
                                                                    name="wp"
                                                                    select="replace(@period, '#wp', '')" />

                                                                <!-- Passende
                                                                Fraktionszugehoerigkeit anhand des
                                                                Grouping-Keys filtern -->
                                                                <xsl:variable
                                                                    name="matching-affiliation"
                                                                    select=".//tei:affiliation[@type='Fraktionszugehoerigkeiten']
                              /tei:affiliation[@type='Fraktionszugehoerigkeit']
                                [. = current-grouping-key()][1]" />

                                                                <!-- Anzahl aller
                                                                Fraktionszugehoerigkeiten in dieser
                                                                Wahlperiode -->
                                                                <xsl:variable
                                                                    name="total-affiliations"
                                                                    select="count(.//tei:affiliation[@type='Fraktionszugehoerigkeiten']
                              /tei:affiliation[@type='Fraktionszugehoerigkeit'])" />

                                                                <li
                                                                    class="membership-period-item">
                                                                    <span class="membership-wp">
                                                                        <xsl:value-of select="$wp" />
                                                                        <span
                                                                            data-i18n="personRegister.wpSuffix">
        WP</span>
                                                                    </span>
                                                                    <span class="membership-dates">
                                                                        <xsl:choose>
                                                                            <!-- Mehrere Fraktionen
                                                                            in dieser WP: nur "seit
                                                                            [Datum]" -->
                                                                            <xsl:when
                                                                                test="$total-affiliations &gt; 1">
                                                                                <xsl:variable
                                                                                    name="next-sibling"
                                                                                    select="$matching-affiliation/following-sibling::tei:affiliation[@type='Fraktionszugehoerigkeit'][1]" />
                                                                                <xsl:choose>
                                                                                    <xsl:when
                                                                                        test="$next-sibling">
                                                                                        <xsl:value-of
                                                                                            select="format-date(xs:date($matching-affiliation/@from), '[D01].[M01].[Y]')" />
                                                                                        <xsl:text> – </xsl:text>
                                                                                        <xsl:value-of
                                                                                            select="format-date(xs:date($next-sibling/@from), '[D01].[M01].[Y]')" />
                                                                                    </xsl:when>
                                                                                    <xsl:otherwise>
                                                                                        <xsl:value-of
                                                                                            select="format-date(xs:date($matching-affiliation/@from), '[D01].[M01].[Y]')" />
                                                                                        <xsl:text> – </xsl:text>
                                                                                        <xsl:value-of
                                                                                            select="format-date(xs:date($matching-affiliation/parent::tei:affiliation[@type='Fraktionszugehoerigkeiten']/@to), '[D01].[M01].[Y]')" />
                                                                                    </xsl:otherwise>
                                                                                </xsl:choose>
                                                                            </xsl:when>
                                                                            <!-- Nur eine Fraktion
                                                                            in dieser WP: Zeitraum -->
                                                                            <xsl:otherwise>
                                                                                <xsl:value-of
                                                                                    select="format-date(xs:date(.//tei:affiliation[@type='Fraktionszugehoerigkeiten']/@from), '[D01].[M01].[Y]')" />
                                                                                <xsl:text> – </xsl:text>
                                                                                <xsl:value-of
                                                                                    select="format-date(xs:date(.//tei:affiliation[@type='Fraktionszugehoerigkeiten']/@to), '[D01].[M01].[Y]')" />
                                                                            </xsl:otherwise>
                                                                        </xsl:choose>
                                                                    </span>
                                                                </li>
                                                            </xsl:for-each>
                                                        </ul>
                                                    </div>
                                                </xsl:for-each-group>
                                            </div>
                                        </div>
                                    </xsl:if>


                                    <xsl:if test="count(distinct-values($hits/base-uri(.))) > 0">
                                        <div class="person-protocols-section">
                                            <h2 data-i18n="personRegister.occurrences">
                                                Erwähnung in Fraktionsprotokollen</h2>
                                            <ul class="protocol-list">
                                                <!-- Group all hits by actual protocol WP -->
                                                <xsl:for-each-group select="$hits" group-by="root(.)//tei:creation//tei:idno[@type='wp']">
                                                    <xsl:sort select="current-grouping-key()" data-type="number" />
                                                    <xsl:variable name="wp" select="current-grouping-key()" />
                                                    <xsl:variable name="wpHits" select="current-group()" />
                                                    <xsl:variable name="wpDistinct" select="distinct-values($wpHits/base-uri(.))" />

                                                    <xsl:if test="count($wpDistinct) > 0">
                                                        <li class="protocol-list-item">
                                                            <details class="protocol-details">
                                                                <summary class="protocol-summary">
                                                                    <span class="wp-label"><xsl:value-of select="$wp" />. <span data-i18n="personRegister.electoralPeriods">Wahlperiode</span></span>
                                                                    <span class="wp-count">
                                                                        <xsl:value-of select="count($wpDistinct)" />
                                                                    </span>
                                                                </summary>
                                                                <table id="protocol-table-{$wp}"
                                                                    class="kgparl-table display">
                                                                    <thead>
                                                                        <tr>
                                                                            <th scope="col" data-i18n="personRegister.faction">Fraktion</th>
                                                                            <th scope="col" data-i18n="personRegister.date">Datum</th>
                                                                            <th scope="col" data-i18n="personRegister.titleColumn">Titel</th>
                                                                        </tr>
                                                                    </thead>
                                                                    <tbody>
                                                                        <xsl:for-each-group select="$wpHits" group-by="base-uri(.)">
                                                                            <xsl:sort select="root(.)//tei:creation//tei:date[1]" order="descending" />
                                                                            <xsl:variable name="url" select="replace(tokenize(base-uri(.), '/')[last()], 'xml', 'html')" />
                                                                            <xsl:variable name="date">
                                                                                <xsl:call-template name="PureDate">
                                                                                    <xsl:with-param name="protocol" select="root(.)" />
                                                                                </xsl:call-template>
                                                                            </xsl:variable>

                                                                            <tr data-href="{concat($url, '?person=', $person_id)}">
                                                                                <td>
                                                                                    <xsl:call-template name="GetParty">
                                                                                        <xsl:with-param name="protocol" select="root(.)" />
                                                                                    </xsl:call-template>
                                                                                </td>
                                                                                <td data-sort="{$date}">
                                                                                    <xsl:call-template name="GetDate">
                                                                                        <xsl:with-param name="protocol" select="root(.)" />
                                                                                    </xsl:call-template>
                                                                                </td>
                                                                                <td>
                                                                                    <a href="{concat($url, '?person=', $person_id)}" class="kgparl-link">
                                                                                        <xsl:value-of select="root(.)//tei:titleStmt/tei:title[@level='a']" />
                                                                                    </a>
                                                                                </td>
                                                                            </tr>
                                                                        </xsl:for-each-group>
                                                                    </tbody>
                                                                </table>
                                                            </details>
                                                        </li>
                                                    </xsl:if>
                                                </xsl:for-each-group>
                                            </ul>
                                        </div>
                                    </xsl:if>
                                </div>

                            </div>
                        </main>
                        <script>
                            $(document).ready(function () {
                            // Initialize DataTables
                            $("table.kgparl-table").each(function () {
                            $(this).DataTable({
                            pageLength: 25,
                            responsive: true,
                            order: [[1, "asc"]],
                            language: {
                            url: "js/de-DE.json",
                            },
                            });
                            });

                            // Add click event listeners to table rows
                            $("table.kgparl-table tbody").on("click", "tr", function (e) {
                            // Don't navigate if clicking on a link or other interactive element
                            if (e.target.tagName === "A" || $(e.target).closest("a").length) {
        return;
                            }
                            var href = $(this).attr("data-href");
                            if (href) {
                              if (e.ctrlKey || e.metaKey || e.button === 1) {
                                window.open(href, '_blank');
                              } else {
                                window.location.href = href;
                              }
                            }
                            });
                            });
                        </script>
                        <xsl:call-template name="html_footer" />

                    </body>
                </html>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
