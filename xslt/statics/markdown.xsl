<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="xsl tei xs">
  <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes" />

  <xsl:import href="../partials/html_head.xsl" />
  <xsl:import href="../partials/html_navbar.xsl" />
  <xsl:import href="../partials/html_footer.xsl" />
  <xsl:import href="../partials/one_time_alert.xsl" />

  <xsl:variable name="md-base" select="'md/'" />

  <xsl:variable name="statics" as="element()*">
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'aktuelles.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Aktuelles</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>aktuelles.html</xsl:text>
      </xsl:attribute>
    </xsl:element>
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'editionsbeirat.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Editionsbeirat</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>editionsbeirat.html</xsl:text>
      </xsl:attribute>
    </xsl:element>
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'forschung.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Forschung</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>forschung.html</xsl:text>
      </xsl:attribute>
    </xsl:element>
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'mitarbeiter.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Mitarbeiter:Innen</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>mitarbeiter.html</xsl:text>
      </xsl:attribute>
    </xsl:element>
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'projekt.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Projekt</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>projekt.html</xsl:text>
      </xsl:attribute>
    </xsl:element>   
        <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'Datenmodell_Editionshinweise.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Editionshinweise</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>editionshinweise.html</xsl:text>
      </xsl:attribute>
    </xsl:element>
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'hilfe.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Hilfe</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>hilfe.html</xsl:text>
      </xsl:attribute>
    </xsl:element>
     <!--
    <xsl:element name="static">
      <xsl:attribute name="url">
        <xsl:value-of select="concat($md-base, 'einleitungen.md')" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>Einleitungen</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="filename">
        <xsl:text>einleitungen.html</xsl:text>
      </xsl:attribute>
    </xsl:element>-->
  </xsl:variable>

  <xsl:template match="/">
    <xsl:for-each select="$statics">
      <xsl:result-document href="{@filename}">
        <xsl:variable name="doc_title">
          <xsl:value-of select='@name' />
        </xsl:variable>
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
                  <h1><xsl:value-of select="@name" /></h1>
                </div>
                <article class="static-content" id="text">
                  <p>Lade Inhalt...</p>
                </article>
              </div>
            </main>

            <xsl:call-template name="html_footer" />

            <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
            <script src="https://unpkg.com/showdown/dist/showdown.min.js"></script>

            <script><![CDATA[
              var baseUrl = "]]><xsl:value-of select="@url" /><![CDATA[";
              var pageName = "]]><xsl:value-of select="@name" /><![CDATA[";

              function loadMarkdown(lang) {
                var mdUrl = baseUrl.replace('md/', 'md/' + lang + '/');
                var cacheKey = "md#" + lang + "#" + pageName;
                var localStorageAvailable = typeof(Storage) !== "undefined";

                var cacheTTL = 24 * 60 * 60 * 1000; // 1 day
                if (localStorageAvailable) {
                  var cached = localStorage.getItem(cacheKey);
                  var cachedTime = localStorage.getItem(cacheKey + "#ts");
                  if (cached && cachedTime && (Date.now() - Number(cachedTime)) < cacheTTL) {
                    $("#text").html(cached);
                    return;
                  }
                }

                $.ajax({
                  type: "GET",
                  url: mdUrl,
                  success: function (text) {
                    var converter = new showdown.Converter({
                      tables: true,
                      strikethrough: true,
                      tasklists: true,
                      ghCodeBlocks: true,
                      smoothLivePreview: true,
                      simpleLineBreaks: false,
                      openLinksInNewWindow: true,
                      emoji: true,
                      backslashEscapesHTMLTags: true
                    });
                    var html = converter.makeHtml(text);
                    $("#text").html(html);
                    if (localStorageAvailable) {
                      localStorage.setItem(cacheKey, html);
                      localStorage.setItem(cacheKey + "#ts", String(Date.now()));
                    }
                  },
                  error: function() {
                    $("#text").html('Fehler beim Laden der Markdown-Datei. Bitte versuchen Sie es später noch einmal.');
                  }
                });
              }

              // Initial load
              loadMarkdown(localStorage.getItem('i18nextLng') || 'de');

              // Reload on language change
              if (typeof i18next !== 'undefined') {
                i18next.on('languageChanged', function(lng) {
                  loadMarkdown(lng);
                });
              }
            ]]></script>
          </body>
        </html>
  </xsl:result-document>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
