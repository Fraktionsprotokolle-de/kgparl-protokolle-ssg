#!/bin/bash

# Read group ID from config file
GROUPID=$(grep -oP '(?<=<groupid>)[^<]+' zotero-config.xml)
FORMAT=$(grep -oP '(?<=<format>)[^<]+' zotero-config.xml)

if [ -z "$GROUPID" ]; then
    echo "Error: Could not find groupid in zotero-config.xml"
    exit 1
fi

echo "Group ID: $GROUPID"
echo "Format: $FORMAT"
echo ""

# Create output directory
OUTPUT_DIR="data/zotero"
mkdir -p "$OUTPUT_DIR"

# Download items in batches of 100
START=0
LIMIT=100
TOTAL=0

while true; do
    echo "Downloading items $START to $((START + LIMIT))..."

    OUTPUT_FILE="$OUTPUT_DIR/zotero_${START}.xml"

    # Download with curl
    HTTP_CODE=$(curl -w "%{http_code}" -s -o "$OUTPUT_FILE" \
        "https://api.zotero.org/groups/$GROUPID/items?format=tei&limit=$LIMIT&start=$START")

    if [ "$HTTP_CODE" != "200" ]; then
        echo "Error: HTTP $HTTP_CODE"
        if [ "$START" -eq 0 ]; then
            rm -f "$OUTPUT_FILE"
            exit 1
        else
            rm -f "$OUTPUT_FILE"
            break
        fi
    fi

    # Check if we got any items (count biblStruct elements in TEI)
    ITEM_COUNT=$(grep -o '<biblStruct' "$OUTPUT_FILE" | wc -l | tr -d ' ')

    if [ "$ITEM_COUNT" -eq 0 ]; then
        echo "No more items to download"
        rm -f "$OUTPUT_FILE"
        break
    fi

    echo "Downloaded $ITEM_COUNT items to $OUTPUT_FILE"
    TOTAL=$((TOTAL + ITEM_COUNT))

    # If we got fewer items than the limit, we're done
    if [ "$ITEM_COUNT" -lt "$LIMIT" ]; then
        echo "Reached last page"
        break
    fi

    START=$((START + LIMIT))

    # Be nice to the API
    sleep 1
done

echo ""
echo "Download complete! Total items: $TOTAL"
echo "Files saved in: $OUTPUT_DIR/"
