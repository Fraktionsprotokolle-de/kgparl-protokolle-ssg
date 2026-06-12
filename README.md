# Fraktionsprotokolle – Statische Webseite

Erzeugung einer statischen Webseite für die digitale Edition »Fraktionen im Deutschen Bundestag 1949–2005«der Kommission für Geschichte des Parlamentarismus und der politischen Parteien, Berlin.

## Übersicht

Dieses Projekt generiert eine statische HTML-Webseite aus TEI-XML-Quellen der parlamentarischen Fraktionsprotokolle. 

## Datenquelle

Die XML-Quellen werden aus dem öffentlichen GitHub-Repository bezogen:
- **Repository**: [Fraktionsprotokolle-de/fraktionsprotokolle_web](https://github.com/Fraktionsprotokolle-de/fraktionsprotokolle_web)
- Die XML-Dateien befinden sich im Verzeichnis `xml_quellen/`

## Projektstruktur

### Hauptverzeichnisse

```
.
├── config/                  # Umgebungskonfiguration
│   ├── environments.json   # Zentrale Konfiguration (live/test)
│   ├── live.env           # API-Keys für Live-Umgebung (nicht im Repo)
│   ├── test.env           # API-Keys für Test-Umgebung (nicht im Repo)
│   └── *.env.example      # Vorlagen für .env-Dateien
├── scripts/                 # Build-Skripte
│   ├── generate_js_config.py  # Generiert html/js/config.js
│   └── env_config.py      # Python-Hilfsmodul für Umgebungskonfiguration
├── data/                    # XML-Quelldaten (generiert)
│   ├── editions/           # Fraktionsprotokolle (TEI-XML)
│   ├── indices/            # Normdaten (Personen, Organisationen)
│   └── einleitungen/       # Einleitungstexte
├── html/                   # Generierte HTML-Ausgabe
│   ├── css/               # Stylesheets
│   ├── js/                # JavaScript-Dateien
│   └── js-data/           # Generierte JSON-Daten
├── xslt/                   # XSLT-Transformationen
│   ├── partials/          # XSLT-Teilvorlagen
│   └── statics/           # Statische Seiten-Templates
├── golang/                 # Go-basierte Tools
├── saxon/                  # Saxon XSLT-Prozessor
├── bin/                    # Build-Skripte
├── fetch_data.sh           # Daten-Download-Skript

```

**Wichtige Dateien:**
- **[`fetch_data.sh`](fetch_data.sh)** - Skript zum Herunterladen der XML-Quelldaten
- **[`config/environments.json`](config/environments.json)** - Zentrale Konfiguration für Live- und Test-Umgebung
- **`config/*.env`** - Umgebungsspezifische API-Keys (nicht im Repository)

### CSS-Dateien

Die Stylesheets befinden sich im Verzeichnis **[`html/css/`](html/css/)**:

- **[`kgparl.css`](html/css/kgparl.css)** - Haupt-Stylesheet mit allen Projektstilen
- **[`variables.css`](html/css/variables.css)** - CSS-Variablen und Theming

Das Haupt-Stylesheet [`kgparl.css`](html/css/kgparl.css) enthält:
- Layout-Definitionen für Protokollseiten
- Tabellen-Stile (sortierbare Spalten, Hover-Effekte)
- Navigationsleisten und Menüs
- Typografie und Farbschema
- Responsive Breakpoints
- Such- und Filter-Komponenten (InstantSearch)
- Personenregister und Kalenderansichten

### JavaScript-Dateien

Die JavaScript-Dateien befinden sich im Verzeichnis **[`html/js/`](html/js/)**.

#### Hauptskripte

- **[`toc.js`](html/js/toc.js)** - Inhaltsverzeichnis und Protokollliste mit InstantSearch
- **[`einleitungen.js`](html/js/einleitungen.js)** - Einleitungsseiten-Funktionalität
- **[`editions.js`](html/js/editions.js)** - Protokoll-Einzelansicht
- **[`person.js`](html/js/person.js)** - Personendetailseiten
- **[`personenregister.js`](html/js/personenregister.js)** - Personenregister mit Suche
- **[`literaturregister.js`](html/js/literaturregister.js)** - Literaturverzeichnis
- **[`search.js`](html/js/search.js)** - Volltextsuche mit Typesense
- **[`calendar.js`](html/js/calendar.js)** - Kalenderansicht
- **[`index.js`](html/js/index.js)** - Startseite

#### Konfiguration und Hilfsskripte

- **[`config.js`](html/js/config.js)** - **Automatisch generiert** aus `config/environments.json`. Enthält `TYPESENSE_CONFIG` und `TYPESENSE_COLLECTIONS`. Nicht manuell bearbeiten!
- **[`i18n.js`](html/js/i18n.js)** - Internationalisierung
- **[`ts_update_url.js`](html/js/ts_update_url.js)** - URL-Verwaltung für Suche

#### UI-Komponenten

- **[`popover.js`](html/js/popover.js)** - Popover-Komponenten für Annotationen
- **[`popupinfo.js`](html/js/popupinfo.js)** - Info-Dialoge
- **[`customcheckbox.js`](html/js/customcheckbox.js)** - Custom Checkbox-Komponenten
- **[`one_time_alert.js`](html/js/one_time_alert.js)** - Einmalige Benachrichtigungen

#### Viewer und Visualisierungen

- **[`osd.js`](html/js/osd.js)** - OpenSeadragon-Integration (Bildviewer)
- **[`osd_scroll.js`](html/js/osd_scroll.js)** - Scroll-Synchronisation für Bilder
- **[`osd_single.js`](html/js/osd_single.js)** - Einzelbild-Ansicht
- **[`make_map_and_table.js`](html/js/make_map_and_table.js)** - Karten und Tabellen
- **[`map_table_cfg.js`](html/js/map_table_cfg.js)** - Konfiguration für Karten/Tabellen

#### Sonstige

- **[`run.js`](html/js/run.js)** - Initialisierungsskript
- **[`listStopProp.js`](html/js/listStopProp.js)** - Event-Propagation-Management

#### Generierte Daten

**[`html/js-data/`](html/js-data/)** enthält:
- **[`calendarData.js`](html/js-data/calendarData.js)** - Kalenderdaten für die Kalenderansicht

### XSLT-Transformationen

Die XSLT-Templates befinden sich im Verzeichnis **[`xslt/`](xslt/)**:

#### Haupt-Transformationen

- **[`fraktionsprotokolle.xslt`](xslt/fraktionsprotokolle.xslt)** - Haupttransformationsdatei
- **[`editions.xsl`](xslt/editions.xsl)** - Protokoll-Einzelseiten
- **[`liste.xsl`](xslt/liste.xsl)** - Protokollliste/Inhaltsverzeichnis
- **[`einleitungen.xsl`](xslt/einleitungen.xsl)** - Einleitungsseiten
- **[`index.xsl`](xslt/index.xsl)** - Startseite
- **[`search.xsl`](xslt/search.xsl)** - Suchseite
- **[`kalender.xsl`](xslt/kalender.xsl)** - Kalenderansicht

#### Register und Verzeichnisse

- **[`listperson.xsl`](xslt/listperson.xsl)** - Personenregister
- **[`listliterature.xsl`](xslt/listliterature.xsl)** - Literaturverzeichnis
- **[`listplace.xsl`](xslt/listplace.xsl)** - Ortsregister
- **[`listorg.xsl`](xslt/listorg.xsl)** - Organisationsverzeichnis

#### Metadaten und statische Seiten

- **[`meta.xsl`](xslt/meta.xsl)** - Metadaten-Seiten
- Rechtliche Seiten werden direkt auf `kgparl.de` verlinkt und nicht im SSG erzeugt.
- **[`beacon.xsl`](xslt/beacon.xsl)** - BEACON-Dateien für Normdaten
- **[`404.xsl`](xslt/404.xsl)** - Fehlerseite
- **[`statics/markdown.xsl`](xslt/statics/markdown.xsl)** - Markdown-zu-HTML-Konverter

#### Teilvorlagen ([`xslt/partials/`](xslt/partials/))

- **[`html_head.xsl`](xslt/partials/html_head.xsl)** - HTML-Head-Bereich
- **[`html_navbar.xsl`](xslt/partials/html_navbar.xsl)** - Navigationsleiste
- **[`html_navbar_no_translations.xsl`](xslt/partials/html_navbar_no_translations.xsl)** - Navbar ohne Sprachauswahl
- **[`html_footer.xsl`](xslt/partials/html_footer.xsl)** - Footer-Bereich
- **[`shared.xsl`](xslt/partials/shared.xsl)** - Gemeinsame Templates und Funktionen
- **[`params.xsl`](xslt/partials/params.xsl)** - Globale Parameter

##### Entity-Templates

- **[`person.xsl`](xslt/partials/person.xsl)** - Personen-Markup
- **[`org.xsl`](xslt/partials/org.xsl)** - Organisations-Markup
- **[`place.xsl`](xslt/partials/place.xsl)** - Orts-Markup
- **[`bibl.xsl`](xslt/partials/bibl.xsl)** - Bibliografische Referenzen

##### UI-Komponenten

- **[`osd-container.xsl`](xslt/partials/osd-container.xsl)** - OpenSeadragon-Container
- **[`aot-options.xsl`](xslt/partials/aot-options.xsl)** - Annotierungs-Optionen
- **[`one_time_alert.xsl`](xslt/partials/one_time_alert.xsl)** - Alert-Komponenten
- **[`tabulator_js.xsl`](xslt/partials/tabulator_js.xsl)** - Tabulator-Integration
- **[`tabulator_dl_buttons.xsl`](xslt/partials/tabulator_dl_buttons.xsl)** - Download-Buttons für Tabellen

## Build-System

Das Projekt verwendet [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter) als Build-Framework mit Apache Ant als Build-Tool.

### Voraussetzungen

- **Java** (für Saxon XSLT-Prozessor und Apache Ant)
- **Python 3.12+** (für Indexierung und Datenverarbeitung)
- **Go** (für zusätzliche Build-Tools)
- **Node.js** (für JavaScript-Dependencies)

### Installation

1. **Repository klonen**
   ```bash
   git clone https://github.com/Fraktionsprotokolle-de/fraktionsprotokolle_web.git
   cd fraktionsprotokolle_web
   ```

2. **Umgebungskonfiguration einrichten**

   Das Projekt unterstützt mehrere Umgebungen (live/test). Die Konfiguration erfolgt über zwei Dateitypen:

   **a) Zentrale Konfiguration (`config/environments.json`)**

   Diese Datei enthält die nicht-sensiblen Einstellungen für alle Umgebungen (bereits im Repository):
   ```json
   {
     "live": {
       "typesense": {
         "host": "typesense.example.com",
         "port": 8108,
         "protocol": "https",
         "timeout": 120,
         "collections": {
           "protocols": "kgparl",
           "persons": "kgparl_persons",
           "literature": "kgparl_literature",
           "einleitung": "kgparl_einleitung"
         }
       },
       "github": {
         "repo": "Fraktionsprotokolle-de/fraktionsprotokolle_web",
         "branch": "main"
       }
     },
     "test": {
       "typesense": { ... },
       "github": {
         "repo": "Fraktionsprotokolle-de/Protokolle",
         "branch": "main"
       }
     }
   }
   ```

   **b) API-Keys und Tokens (`config/live.env` und `config/test.env`)**

   Erstellen Sie diese Dateien aus den Vorlagen:
   ```bash
   cp config/live.env.example config/live.env
   cp config/test.env.example config/test.env
   ```

   Inhalt der `.env`-Dateien:
   ```env
   # Typesense API Key (search-only key für Browser)
   TYPESENSE_API_KEY=ihr_search_api_key

   # Typesense Admin Key (für Indexierung)
   TYPESENSE_ADMIN_KEY=ihr_admin_api_key

   # GitHub Token für Daten-Download
   GITHUB_TOKEN=ihr_github_token
   ```

   **Hinweis:** Die `config/*.env`-Dateien sind in `.gitignore` und werden nicht committed.

3. **Dependencies installieren**
   ```bash
   npm install
   pip install -r requirements.txt
   ```

## Build-Prozess

Das Projekt verwendet ein **Makefile** mit Unterstützung für mehrere Umgebungen.

### Kompletter Build (empfohlen)

```bash
# Live-Umgebung (Standard)
make all

# Test-Umgebung
make all ENV=test
```

Dies führt automatisch alle Schritte aus: `config` → `fetch` → `indices` → `makeHTML` → `upload`

### Einzelne Build-Schritte

#### 1. JavaScript-Konfiguration generieren

```bash
make config ENV=live
# oder
python3 scripts/generate_js_config.py --env live
```

Generiert `html/js/config.js` aus `config/environments.json` mit den Typesense-Einstellungen für die gewählte Umgebung.

#### 2. Daten herunterladen

```bash
make fetch ENV=live
# oder
./fetch_data.sh live
```

Das Skript [`fetch_data.sh`](fetch_data.sh):
- Liest Repository und Branch aus `config/environments.json`
- Lädt die XML-Quelldaten aus dem konfigurierten GitHub-Repository
- Extrahiert Fraktionsprotokolle nach [`data/editions/`](data/editions/)
- Extrahiert Normdaten nach [`data/indices/`](data/indices/)
- Extrahiert Einleitungen nach [`data/einleitungen/`](data/einleitungen/)

**Hinweis:** Falls ein Authentifizierungsfehler (HTTP 401) auftritt, prüfen Sie den `GITHUB_TOKEN` in `config/live.env` oder `config/test.env`.

#### 3. HTML generieren

```bash
make makeHTML
# oder
ant
```

Das Ant-Build-Skript führt folgende Schritte aus:
- XSLT-Transformationen der XML-Dateien nach HTML
- Generierung von Registern und Verzeichnissen
- Erstellung der statischen Seiten
- Kopieren von Assets (CSS, JS, Bilder)

#### 4. Suchindex erstellen

```bash
make indices ENV=live
```

Oder manuell:

```bash
# Go-Tool ausführen
cd golang && go mod tidy && go run ./main.go && cd ..

# Hauptindex erstellen
python3 ./make_ts_index.py --env live

# Literaturindex erstellen
python3 ./make_ts_index_literature.py --env live

# Kalenderdaten generieren
python3 ./make_calendar_date.py
```

**Verwendete Skripte:**
- **[`golang/main.go`](golang/main.go)** - Go-basierte Datenverarbeitung
- **[`make_ts_index.py`](make_ts_index.py)** - Hauptindex für Protokolle (unterstützt `--env`)
- **[`make_ts_index_literature.py`](make_ts_index_literature.py)** - Literaturindex (unterstützt `--env`)
- **[`make_calendar_date.py`](make_calendar_date.py)** - Kalenderdaten-Generator
- **[`person_index.py`](person_index.py)** - Personenindex (wird von make_ts_index.py aufgerufen)

### Makefile-Übersicht

| Target | Beschreibung |
|--------|-------------|
| `make all` | Kompletter Build (config → fetch → indices → makeHTML → upload) |
| `make config` | Generiert `html/js/config.js` |
| `make fetch` | Lädt Daten von GitHub |
| `make indices` | Erstellt Typesense-Indices |
| `make makeHTML` | Generiert HTML via Ant |
| `make upload` | Deployed nach Remote-Server |
| `make help` | Zeigt Hilfe an |

Alle Targets unterstützen den Parameter `ENV=live` (Standard) oder `ENV=test`.

### 5. Zotero-Daten herunterladen (optional)

```bash
python3 ./download_zotero.py
```

Das Skript **[`download_zotero.py`](download_zotero.py)** lädt bibliografische Daten aus Zotero für das Literaturverzeichnis.

## Umgebungskonfiguration

Das Projekt unterstützt mehrere Umgebungen (z.B. `live` und `test`) mit unterschiedlichen:
- **Typesense-Collections**: Separate Indices für Live und Test
- **GitHub-Repositories**: Verschiedene Datenquellen für Live und Test

### Konfigurationsdateien

| Datei | Zweck | Im Repository |
|-------|-------|---------------|
| `config/environments.json` | Hosts, Ports, Collection-Namen, GitHub-Repos | Ja |
| `config/live.env` | API-Keys für Live | Nein |
| `config/test.env` | API-Keys für Test | Nein |
| `config/*.env.example` | Vorlagen für .env-Dateien | Ja |

### Neue Umgebung hinzufügen

1. Fügen Sie einen neuen Eintrag in `config/environments.json` hinzu
2. Erstellen Sie eine entsprechende `config/neuename.env` Datei
3. Nutzen Sie `make all ENV=neuename`

## Entwicklung

### CSS-Entwicklung

Das Haupt-Stylesheet [`html/css/kgparl.css`](html/css/kgparl.css) kann direkt bearbeitet werden. Für Produktionsbuilds kann die bereinigte Version mit [`purge-css.js`](purge-css.js) erstellt werden:

```bash
node purge-css.js
```

Dies erstellt [`kgparl.purged.css`](html/css/kgparl.purged.css) mit entfernten ungenutzten CSS-Regeln.

### XSLT-Entwicklung

XSLT-Templates befinden sich in [`xslt/`](xslt/). Nach Änderungen muss `ant` erneut ausgeführt werden, um die HTML-Dateien neu zu generieren.

### JavaScript-Entwicklung

JavaScript-Dateien in [`html/js/`](html/js/) werden direkt in die HTML-Seiten eingebunden. Änderungen sind nach Reload der Seite sichtbar.

## Deployment

Die generierten HTML-Dateien befinden sich im Verzeichnis [`html/`](html/) und können auf einen Webserver deployed werden.

### Automatisches Deployment

```bash
make upload
```

Die Deployment-Konfiguration erfolgt über Variablen im Makefile:
- `REMOTE_USER` - SSH-Benutzername (Standard: `stephan`)
- `REMOTE_HOST` - Server-Adresse
- `REMOTE_DIR` - Zielverzeichnis auf dem Server

Diese können beim Aufruf überschrieben werden:
```bash
make upload REMOTE_HOST=example.com REMOTE_USER=deploy REMOTE_DIR=/var/www/html
```

## Technischer Stack

- **Build-System**: Apache Ant, DSE-Static-Cookiecutter
- **XSLT-Prozessor**: Saxon
- **Suchengine**: Typesense mit InstantSearch.js
- **Frontend-Frameworks**:
  - Tailwind v4
  - InstantSearch.js
  - OpenSeadragon (Bildviewer)
  - Tabulator (Tabellen)
- **Backend-Sprachen**:
  - Python (Indexierung, Datenverarbeitung)
  - Go (Build-Tools)
  - Shell (Build-Skripte)

## Lizenz

Dieses Projekt steht unter der MIT License.

Dieses Projekt basiert teilweise auf [dse-static-cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter) des Austrian Centre for Digital Humanities and Cultural Heritage (ACDH-CH). 

Der daraus übernommene Code steht unter der MIT License. Details finden sich in der Datei `LICENSE`.

Bitte beachten Sie, dass diese Lizenz **nicht** für für im Projekt enthaltene Drittsoftware gilt, insbesondere für Saxon sowie CSS- und JavaScript-Bibliotheken. Für diese Komponenten gelten die jeweiligen Lizenzbedingungen der ursprünglichen Anbieter.

## Kontakt

- **E-Mail**: info@fraktionsprotokolle.de
