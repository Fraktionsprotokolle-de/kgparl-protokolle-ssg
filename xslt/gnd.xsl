<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    version="2.0" exclude-result-prefixes="xsl tei">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0"
        indent="yes" omit-xml-declaration="yes" />

    <xsl:template match="/">
        <html lang="de">
            <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>GND-Weiterleitung – KGParl Fraktionsprotokolle</title>
                <link rel="stylesheet" href="/css/variables.css" />
                <link rel="stylesheet" href="/css/kgparl.css" />
                <script src="/js/config.js"></script>
                <style>
                    body { display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; font-family: var(--font-family-base, sans-serif); background: var(--color-background, #faf9f7); color: var(--color-text, #2b2b2b); }
                    .gnd-message { text-align: center; max-width: 480px; padding: 2rem; }
                    .gnd-message h1 { font-size: 1.25rem; margin-bottom: 1rem; }
                    .gnd-message p { margin-bottom: 1rem; }
                    .gnd-message a { color: var(--color-primary, #6e9d1a); }
                    .spinner { display: inline-block; width: 24px; height: 24px; border: 3px solid #ccc; border-top-color: var(--color-primary, #6e9d1a); border-radius: 50%; animation: spin 0.8s linear infinite; margin-bottom: 1rem; }
                    @keyframes spin { to { transform: rotate(360deg); } }
                </style>
            </head>
            <body>
                <div class="gnd-message" id="message">
                    <div class="spinner"></div>
                    <p>GND-Weiterleitung&#8230;</p>
                </div>
                <script>
                <xsl:text disable-output-escaping="yes"><![CDATA[
(function() {
    function decodePathSegment(segment) {
        try {
            return decodeURIComponent(segment);
        } catch (e) {
            return segment;
        }
    }

    var params = new URLSearchParams(window.location.search);
    var gndId = params.get('id');
    if (!gndId) {
        var pathMatch = window.location.pathname.match(/\/gnd\/([^/?#]+)/);
        if (pathMatch) {
            gndId = decodePathSegment(pathMatch[1]);
        }
    }
    var messageEl = document.getElementById('message');

    if (!gndId) {
        messageEl.innerHTML = '<h1>Fehlende GND-ID</h1><p>Bitte eine GND-ID angeben, z.\u2009B. <code>gnd.html?id=118629972</code></p><p><a href="personenregister.html">Zum Personenregister</a></p>';
        return;
    }

    // Normalize: support both bare ID and full URL
    var gndUrl = gndId.startsWith('http') ? gndId : 'https://d-nb.info/gnd/' + gndId;
    var gndBare = gndId.replace(/^https?:\/\/d-nb\.info\/gnd\//, '');

    var baseUrl = TYPESENSE_CONFIG.protocol + '://' + TYPESENSE_CONFIG.host + ':' + TYPESENSE_CONFIG.port;
    var collection = TYPESENSE_COLLECTIONS.persons;
    var searchUrl = baseUrl + '/collections/' + collection + '/documents/search?q=' + encodeURIComponent(gndUrl) + '&query_by=gnd&per_page=5&num_typos=0';

    fetch(searchUrl, {
        headers: { 'X-TYPESENSE-API-KEY': TYPESENSE_CONFIG.apiKey }
    })
    .then(function(resp) { return resp.json(); })
    .then(function(data) {
        var match = null;
        if (data.hits) {
            for (var i = 0; i < data.hits.length; i++) {
                var docGnd = data.hits[i].document.gnd || '';
                if (docGnd === gndUrl || docGnd === gndBare || docGnd.endsWith('/' + gndBare)) {
                    match = data.hits[i].document;
                    break;
                }
            }
        }
        if (match) {
            window.location.replace('/' + match.id + '.html');
        } else {
            messageEl.innerHTML = '<h1>Person nicht gefunden</h1><p>Keine Person mit GND-ID <code>' + gndId + '</code> im Verzeichnis.</p><p><a href="personenregister.html">Zum Personenregister</a></p>';
        }
    })
    .catch(function() {
        messageEl.innerHTML = '<h1>Fehler</h1><p>Die Suche konnte nicht durchgeführt werden.</p><p><a href="personenregister.html">Zum Personenregister</a></p>';
    });
})();
                ]]></xsl:text>
                </script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
