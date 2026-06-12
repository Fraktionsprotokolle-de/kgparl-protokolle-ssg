#!/bin/bash

# Environment parameter (default: live)
ENV="${1:-live}"

echo "============================================"
echo "Fetching data for environment: $ENV"
echo "============================================"

# Load environment config
ENV_FILE="./config/${ENV}.env"
ENV_JSON="./config/environments.json"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

if [ ! -f "$ENV_JSON" ]; then
    echo "Error: Environment JSON not found: $ENV_JSON"
    exit 1
fi

# Get Token from environment-specific .env file
TOKEN=$(grep GITHUB_TOKEN "$ENV_FILE" | cut -d '=' -f2)

# Get Repo from environments.json using Python (jq alternative)
REPO=$(python3 -c "import json; data=json.load(open('$ENV_JSON')); print(data['$ENV']['github']['repo'])")
BRANCH=$(python3 -c "import json; data=json.load(open('$ENV_JSON')); print(data['$ENV']['github']['branch'])")

# Echo ENV Variables
echo "Environment: $ENV"
echo "REPO: $REPO"
echo "BRANCH: $BRANCH"
echo "TOKEN: ${TOKEN:0:10}... (truncated)"

echo "fetching transkriptions from data_repo"
rm -rf data/editions && mkdir data/editions
rm -rf data/indices && mkdir data/indices
rm -rf data/einleitungen && mkdir data/einleitungen

# Download repository archive
HTTP_CODE=$(curl -w "%{http_code}" -H "Authorization: token $TOKEN" \
     -L "https://api.github.com/repos/$REPO/zipball/$BRANCH" \
     -o main.zip -s)

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Error: Failed to download repository archive (HTTP $HTTP_CODE)"
    if [ "$HTTP_CODE" = "401" ]; then
        echo "   Authentication failed. Please check your TOKEN in .env file."
        echo "   The token may be expired or invalid."
        echo "   Generate a new token at: https://github.com/settings/tokens"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "   Repository not found or access denied."
        echo "   Please check REPO setting in .env: $REPO"
    fi
    cat main.zip 2>/dev/null
    rm -f main.zip
    exit 1
fi

echo "✅ Successfully downloaded repository archive"
topdir=$(unzip -Z1 main.zip | head -n1 | cut -d/ -f1)
unzip main.zip -d .

if [ "$ENV" != "live" ]; then
    # Find all XML files and copy them to the destination directory
    find "$topdir/Fraktionen" -type f -name "*.xml" \
        -not -path "*/Einleitung/*" \
        -not -path "*/Normdaten/*" \
        -not -path "*/__contents__.xml" \
        -exec sh -c 'cp "$1" ./data/editions/' _ {} \;
    # Iterate over Subfolder Fraktionen and copy all directories to data/editions without the subfolder Einleitung and Normdaten
    #for dir in "$topdir"/Fraktionen/*; do
    #    base=$(basename "$dir")
    #    if [ "$base" != "Einleitung" ] \
    #       && [ "$base" != "Normdaten" ] \
    #       && [ "$base" != "__contents__.xml" ]; then
    #        mv "$dir" ./data/editions/
    #    fi
    #done

    find "$topdir" -type f -name "*.xml" \
        -path "$topdir/Einleitung/*" \
        -not -path "*Normdaten*" \
        -exec cp {} ./data/einleitungen \;
    find "$topdir" -type f -name "*.xml" -path "./Normdaten/*" -not -path "./Einleitung/*" -exec cp {} ./data/indices/ \;
    for dir in $topdir/Fraktionen/Normdaten/*; do
            #Just copy the Files Organisationen.xml, Personen.xml, and tei-fpv.xml to data/indices
            if [ "$(basename "$dir")" = "Organisationen.xml" ] || [ "$(basename "$dir")" = "Personen.xml" ] || [ "$(basename "$dir")" = "tei-fpv.xml" ]; then
                        mv "$dir" ./data/indices
            fi
    done

    for dir in $topdir/Fraktionen/Einleitung/*; do
            mv "$dir" ./data/einleitungen
    done

    # Move PDFs from einleitungen to downloads
    mkdir -p ./html/downloads
    find ./data/einleitungen -type f -name "*.pdf" -exec mv {} ./html/downloads/ \;
    PDF_COUNT=$(find ./html/downloads -name "*.pdf" -newer main.zip 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ Moved $PDF_COUNT Einleitungen-PDFs to html/downloads/"

fi


if [ "$ENV" == "live" ]; then
    # Find all XML files and copy them to the destination directory
    find "$topdir/xml_quellen" -type f -name "*.xml" \
        -not -path "*/Einleitung/*" \
        -not -path "*/Normdaten/*" \
        -not -path "*/__contents__.xml" \
        -exec sh -c 'cp "$1" ./data/editions/' _ {} \;
    # Iterate over Subfolder Fraktionen and copy all directories to data/editions without the subfolder Einleitung and Normdaten
    #for dir in "$topdir"/Fraktionen/*; do
    #    base=$(basename "$dir")
    #    if [ "$base" != "Einleitung" ] \
    #       && [ "$base" != "Normdaten" ] \
    #       && [ "$base" != "__contents__.xml" ]; then
    #        mv "$dir" ./data/editions/
    #    fi
    #done

    find "$topdir" -type f -name "*.xml" \
        -path "$topdir/xml_einleitungen/*" \
        -not -path "*Normdaten*" \
        -exec cp {} ./data/einleitungen \;
    find "$topdir" -type f -name "*.xml" -path "./xml_quellen/*" -not -path "./xml_einleitungen/*" -exec cp {} ./data/indices/ \;
    for dir in $topdir/xml_quellen/Normdaten/*; do
            #Just copy the Files Organisationen.xml, Personen.xml, and tei-fpv.xml to data/indices
            if [ "$(basename "$dir")" = "Organisationen.xml" ] || [ "$(basename "$dir")" = "Personen.xml" ] || [ "$(basename "$dir")" = "tei-fpv.xml" ]; then
                        mv "$dir" ./data/indices
            fi
    done

    for dir in $topdir/xml_einleitungen/*; do
                        mv "$dir" ./data/einleitungen
    done

    # Move PDFs from einleitungen to downloads
    mkdir -p ./html/downloads
    find ./data/einleitungen -type f -name "*.pdf" -exec mv {} ./html/downloads/ \;
    PDF_COUNT=$(find ./html/downloads -name "*.pdf" -newer main.zip 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ Moved $PDF_COUNT Einleitungen-PDFs to html/downloads/"
fi
# Extract markdown content pages (md-seitentexte)
echo "Extracting markdown content pages..."
rm -rf html/md
mkdir -p html/md
if [ -d "$topdir/md-seitentexte" ]; then
    cp -r "$topdir/md-seitentexte/"* html/md/
    echo "✅ Markdown content pages copied to html/md/"
else
    echo "⚠️  No md-seitentexte directory found in repository"
fi

# Write data source version info for footer display
DATA_SHA=$(echo "$topdir" | rev | cut -d'-' -f1 | rev)
DATA_SHORT_SHA=$(echo "$DATA_SHA" | cut -c1-7)
DATA_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mkdir -p ./html/js-data
cat > ./html/js-data/dataVersion.js <<JSEOF
// Auto-generated by fetch_data.sh — do not edit manually
var DATA_VERSION = {
  repo: "$REPO",
  sha: "$DATA_SHORT_SHA",
  fetchedAt: "$DATA_TIMESTAMP"
};
JSEOF
echo "✅ Data version written: $REPO@$DATA_SHORT_SHA"

rm main.zip
rm -rf "$topdir"
