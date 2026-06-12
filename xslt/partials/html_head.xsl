<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:include href="./params.xsl" />

    <xsl:template match="/" name="html_head">
        <xsl:param name="html_title" select="$project_short_title"></xsl:param>

        <!-- Character encoding and compatibility -->
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />

        <!-- Mobile app capabilities -->
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-title" content="{$html_title}" />
        <meta name="msapplication-TileColor" content="#6e9d1a" />
        <meta name="msapplication-TileImage" content="{$project_logo}" />
        <meta name="theme-color" content="#6e9d1a" />

        <!-- Open Graph Meta Tags -->
        <meta property="og:title" content="Fraktionsprotokolle"/>
        <meta property="og:type" content="website"/>
        <meta property="og:url" content="{$base_url}/"/>
        <meta property="og:image" content="images/KGParl_titel.png"/>
        <meta property="og:description" content="Online-Edition der Protokolle der Fraktionen des Deutschen Bundestags"/>
        <meta property="og:site_name" content="Fraktionsprotokolle - KGParl"/>

        <!-- Favicon -->
        <link rel="icon" type="image/svg+xml" href="{$project_logo}" sizes="any" />
        <link rel="profile" href="http://gmpg.org/xfn/11"></link>

        <!-- Title -->
        <title><xsl:value-of select="$html_title" /></title>

        <!-- Fonts: Source Sans 3 -->
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&amp;display=swap" rel="stylesheet" />

        <!-- KGParl Design System CSS -->
        <link rel="stylesheet" href="css/tailwind.css" type="text/css" />
        <link rel="stylesheet" href="css/kgparl.css" type="text/css" />

        <!-- jQuery (needed for jqueryI18next and other scripts) -->
        <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>

        <!-- i18next for translations -->
        <script src="https://cdn.jsdelivr.net/npm/i18next@21.6.10/i18next.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/i18next-browser-languagedetector@6.1.3/i18nextBrowserLanguageDetector.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/i18next-http-backend@1.3.2/i18nextHttpBackend.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/jquery-i18next@1.2.1/jquery-i18next.min.js"></script>

        <!-- Configuration -->
        <script src="js/config.js"></script>

        <!-- Components -->
        <script type="module" src="js/popupinfo.js"></script>
        <script type="module" src="js/customcheckbox.js"></script>
        <script src="js/print-helper.js"></script>
    </xsl:template>

    <!-- Styleless variant for PDF/Print generation -->
    <xsl:template name="html_head_styleless">
        <xsl:param name="html_title" select="$project_short_title"></xsl:param>

        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-title" content="{$html_title}" />
        <meta name="msapplication-TileColor" content="#6e9d1a" />
        <meta name="msapplication-TileImage" content="{$project_logo}" />

        <link rel="icon" type="image/svg+xml" href="{$project_logo}" sizes="any" />
        <link rel="profile" href="http://gmpg.org/xfn/11"></link>

        <title><xsl:value-of select="$html_title" /></title>

        <!-- Minimal fonts for print -->
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600&amp;display=swap" rel="stylesheet" />

        <!-- Minimal CSS variables -->
        <link rel="stylesheet" href="css/variables.css" type="text/css" />

        <!-- i18next for translations -->
        <script src="https://cdn.jsdelivr.net/npm/i18next@21.6.10/i18next.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/i18next-browser-languagedetector@6.1.3/i18nextBrowserLanguageDetector.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/i18next-http-backend@1.3.2/i18nextHttpBackend.min.js"></script>
    </xsl:template>
</xsl:stylesheet>
