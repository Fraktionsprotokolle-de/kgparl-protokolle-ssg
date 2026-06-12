<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:template match="/" name="one_time_alert">
        <div style="display:none" id="once-popup">
            <div class="kgparl-alert kgparl-alert-warning" role="alert">
                <h2 class="text-center">
                    Beta Version
                </h2>
                <button type="button" class="alert-close-btn" data-dismiss="alert" aria-label="Schließen">×</button>
            </div>
        </div>
        <script type="text/javascript" src="js/one_time_alert.js"></script>

    </xsl:template>
</xsl:stylesheet>