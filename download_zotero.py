#!/usr/bin/env python3
"""
Simple script to download Zotero items using curl and the configuration from zotero-config.xml
"""

import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
import sys
import time
import re
import json
import shutil


def read_config(config_path='zotero-config.xml'):
    """Read the Zotero configuration from XML file."""
    try:
        tree = ET.parse(config_path)
        root = tree.getroot()

        groupid = root.find('groupid').text.strip()
        format_type = root.find('format').text.strip()

        return groupid, format_type
    except Exception as e:
        print(f"Error reading config file: {e}")
        sys.exit(1)


def download_batch(groupid, start, limit=100, download_type='data', retry_count=0, max_retries=5):
    """Download a batch of items in JSON format.

    Args:
        download_type: 'data' for structured bibliographic data, 'bib' for formatted citations
    """
    # The Zotero API doesn't support include=bib,data together, so we download separately:
    # - format=json (default) gives full structured data in 'data' field
    # - format=json&include=bib gives formatted citations in 'bib' field
    if download_type == 'bib':
        url = f"https://api.zotero.org/groups/{groupid}/items?format=json&include=bib,data,coins,citation&style=universitat-freiburg-geschichte&limit={limit}&start={start}"
    else:  # download_type == 'data'
        url = f"https://api.zotero.org/groups/{groupid}/items?format=json&limit={limit}&start={start}"

    try:
        result = subprocess.run(
            ['curl', '-s', url],
            capture_output=True,
            text=True,
            check=True
        )

        if result.returncode == 0 and result.stdout:
            # Check if we got a 504 Gateway Timeout HTML page
            if result.stdout.startswith('<html>') or 'Gateway Time-out' in result.stdout or 'Error' in result.stdout[:100]:
                if retry_count < max_retries:
                    wait_time = (retry_count + 1) * 5  # Exponential backoff: 5, 10, 15, 20, 25 seconds
                    print(f"Server timeout or error. Retrying in {wait_time} seconds... (attempt {retry_count + 1}/{max_retries})")
                    time.sleep(wait_time)
                    return download_batch(groupid, start, limit, download_type, retry_count + 1, max_retries)
                else:
                    print(f"Max retries ({max_retries}) reached. Giving up on this batch.")
                    return None

            return result.stdout
        return None
    except subprocess.CalledProcessError as e:
        print(f"Error downloading: {e}")
        return None


def get_chicago_citation(groupid, item_key):
    """Fetch Chicago-style citation for an item."""
    url = f"https://api.zotero.org/groups/{groupid}/items/{item_key}?format=bib&style=chicago-notes-bibliography-subsequent-author-title-17th-edition"

    try:
        result = subprocess.run(
            ['curl', '-s', url],
            capture_output=True,
            text=True,
            check=True
        )

        if result.returncode == 0 and result.stdout:
            # The API returns HTML, we need to strip the tags
            citation = result.stdout.strip()
            # Remove HTML tags
            citation = re.sub(r'<[^>]+>', '', citation)
            return citation.strip()
        return None
    except subprocess.CalledProcessError as e:
        print(f"Error fetching citation for {item_key}: {e}")
        return None


def json_to_tei_biblstruct(item_json, groupid):
    """Convert a Zotero JSON item to a TEI biblStruct element.

    This conversion handles all major Zotero item types and fields.
    """
    # Get the item key
    item_key = item_json.get('key', '')

    # The structured data is directly in the item for merged JSON files
    # (For backward compatibility, also check 'data' field)
    if 'data' in item_json:
        data = item_json['data']
    else:
        data = item_json

    # Try to generate a citation key (author-year format)
    creators = data.get('creators', [])
    year = data.get('date', '')[:4] if data.get('date') else ''

    # Get first author's last name
    first_author = ''
    if creators and len(creators) > 0:
        first_author = creators[0].get('lastName', creators[0].get('name', ''))

    # Generate xml:id (citation key)
    citation_key =  item_key

    # Create biblStruct element
    item_type = data.get('itemType', 'book')
    bibl_struct = ET.Element('biblStruct')
    bibl_struct.set('{http://www.w3.org/XML/1998/namespace}id', citation_key)
    bibl_struct.set('type', item_type)
    bibl_struct.set('corresp', f"http://zotero.org/groups/{groupid}/items/{item_key}")

    # Create analytic element for article/chapter titles
    if item_type in ['journalArticle', 'magazineArticle', 'newspaperArticle', 'bookSection']:
        analytic = ET.SubElement(bibl_struct, 'analytic')

        # Add title
        if data.get('title'):
            title = ET.SubElement(analytic, 'title')
            title.set('level', 'a')
            title.text = data['title']

        # Add authors
        for creator in creators:
            if creator.get('creatorType') in ['author', None]:
                author = ET.SubElement(analytic, 'author')
                if creator.get('firstName'):
                    forename = ET.SubElement(author, 'forename')
                    forename.text = creator['firstName']
                if creator.get('lastName'):
                    surname = ET.SubElement(author, 'surname')
                    surname.text = creator['lastName']
                elif creator.get('name'):
                    surname = ET.SubElement(author, 'surname')
                    surname.text = creator['name']

    # Create monogr element
    monogr = ET.SubElement(bibl_struct, 'monogr')

    # Add publication title (journal, book, etc.)
    pub_title = data.get('publicationTitle') or data.get('bookTitle') or ''
    if pub_title:
        title = ET.SubElement(monogr, 'title')
        title.set('level', 'j' if item_type.endswith('Article') else 'm')
        title.text = pub_title
    elif item_type in ['book', 'thesis', 'report'] and data.get('title'):
        # For books, the main title goes in monogr
        title = ET.SubElement(monogr, 'title')
        title.set('level', 'm')
        title.text = data['title']

        # Add book authors/editors
        for creator in creators:
            if creator.get('creatorType') in ['author', 'editor', None]:
                elem_name = 'editor' if creator.get('creatorType') == 'editor' else 'author'
                author_elem = ET.SubElement(monogr, elem_name)
                if creator.get('firstName'):
                    forename = ET.SubElement(author_elem, 'forename')
                    forename.text = creator['firstName']
                if creator.get('lastName'):
                    surname = ET.SubElement(author_elem, 'surname')
                    surname.text = creator['lastName']
                elif creator.get('name'):
                    surname = ET.SubElement(author_elem, 'surname')
                    surname.text = creator['name']

    # Add imprint
    imprint = ET.SubElement(monogr, 'imprint')

    # Add publisher
    if data.get('publisher'):
        publisher = ET.SubElement(imprint, 'publisher')
        publisher.text = data['publisher']

    # Add place
    if data.get('place'):
        pub_place = ET.SubElement(imprint, 'pubPlace')
        pub_place.text = data['place']

    # Add date
    if data.get('date'):
        date = ET.SubElement(imprint, 'date')
        date.text = data['date']

    # Add volume
    if data.get('volume'):
        bibl_scope = ET.SubElement(imprint, 'biblScope')
        bibl_scope.set('unit', 'volume')
        bibl_scope.text = data['volume']

    # Add pages
    if data.get('pages'):
        bibl_scope = ET.SubElement(imprint, 'biblScope')
        bibl_scope.set('unit', 'page')
        bibl_scope.text = data['pages']

    return bibl_struct, item_key


def generate_citation_from_data(data):
    """Generate a formatted citation string from Zotero structured data."""
    parts = []

    # Authors/Creators
    creators = data.get('creators', [])
    if creators:
        author_names = []
        for creator in creators[:3]:  # First 3 authors
            if creator.get('lastName'):
                if creator.get('firstName'):
                    author_names.append(f"{creator['lastName']}, {creator['firstName']}")
                else:
                    author_names.append(creator['lastName'])
            elif creator.get('name'):
                author_names.append(creator['name'])

        if author_names:
            if len(creators) > 3:
                parts.append(' / '.join(author_names) + ' u. a.')
            elif len(author_names) > 1:
                parts.append(' / '.join(author_names))
            else:
                parts.append(author_names[0])

    # Title
    title = data.get('title', '')
    if title:
        # Add quotes for articles, italics markers for books
        item_type = data.get('itemType', '')
        if item_type in ['journalArticle', 'magazineArticle', 'newspaperArticle']:
            parts.append(f'"{title}"')
        else:
            parts.append(title)

    # Publication title
    pub_title = data.get('publicationTitle', '')
    if pub_title:
        parts.append(pub_title)

    # Volume and issue
    volume = data.get('volume', '')
    issue = data.get('issue', '')
    if volume:
        vol_str = f"Bd. {volume}"
        if issue:
            vol_str += f", Nr. {issue}"
        parts.append(vol_str)

    # Pages
    pages = data.get('pages', '')
    if pages:
        parts.append(f"S. {pages}")

    # Publisher and place
    publisher = data.get('publisher', '')
    place = data.get('place', '')
    if publisher or place:
        pub_parts = []
        if place:
            pub_parts.append(place)
        if publisher:
            pub_parts.append(publisher)
        parts.append(': '.join(pub_parts))

    # Date
    date = data.get('date', '')
    if date:
        parts.append(date)

    return '. '.join(parts) + '.' if parts else ''


def extract_and_save_items(groupid, input_dir, output_dir):
    """Extract individual items from JSON files and save them as TEI XML with Chicago citations."""
    import html

    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Find all JSON files (looking for zotero_data_*.json pattern)
    json_files = sorted(input_path.glob('zotero_data_*.json'))

    if not json_files:
        # Fallback to old naming pattern
        json_files = sorted(input_path.glob('zotero_*.json'))

    if not json_files:
        print(f"No JSON files found in {input_dir}")
        return 0

    total_items = 0
    generated_citations = 0

    for json_file in json_files:
        print(f"Processing {json_file.name}...")

        try:
            # Read and parse the JSON file
            with open(json_file, 'r', encoding='utf-8') as f:
                items = json.load(f)

            for item_data in items:
                # Convert JSON to TEI biblStruct
                bibl_struct, citation_key = json_to_tei_biblstruct(item_data, groupid)

                # Get the formatted citation from the JSON (already included via include=bib)
                citation_html = item_data.get('bib', '')

                if citation_html:
                    # Strip HTML tags to get plain text citation
                    citation_text = re.sub(r'<[^>]+>', '', citation_html).strip()
                    # Decode HTML entities to get proper characters
                    citation_text = html.unescape(citation_text)
                else:
                    # Generate citation from structured data
                    data = item_data.get('data', item_data)
                    citation_text = generate_citation_from_data(data)
                    generated_citations += 1

                if citation_text:
                    # Create bibl element with citation
                    bibl = ET.Element('bibl')
                    bibl.text = citation_text

                    # Insert bibl as first child of biblStruct
                    bibl_struct.insert(0, bibl)

                # Create new TEI document for this item
                item_root = ET.Element('TEI', {'xmlns': 'http://www.tei-c.org/ns/1.0'})
                text_elem = ET.SubElement(item_root, 'text')
                body_elem = ET.SubElement(text_elem, 'body')
                list_bibl = ET.SubElement(body_elem, 'listBibl')
                list_bibl.append(bibl_struct)

                # Create ElementTree and save
                item_tree = ET.ElementTree(item_root)
                output_file = output_path / f"{citation_key}.xml"

                # Write with XML declaration and proper encoding
                ET.register_namespace('', 'http://www.tei-c.org/ns/1.0')
                item_tree.write(output_file, encoding='utf-8', xml_declaration=True)

                print(f"  Saved {citation_key}.xml")
                total_items += 1

        except Exception as e:
            print(f"Error processing {json_file}: {e}")
            import traceback
            traceback.print_exc()
            continue

    print(f"\nExtraction summary:")
    print(f"  Total items: {total_items}")
    print(f"  Citations from API: {total_items - generated_citations}")
    print(f"  Citations generated: {generated_citations}")

    return total_items


def main():
    """Main function to download all Zotero items."""
    import argparse

    parser = argparse.ArgumentParser(
        description='Download Zotero items and optionally extract them individually'
    )
    parser.add_argument(
        '--extract-only',
        action='store_true',
        help='Only extract items from existing downloads (skip downloading)'
    )
    parser.add_argument(
        '--no-extract',
        action='store_true',
        help='Only download items (skip extraction)'
    )

    args = parser.parse_args()

    # Read configuration
    print("Reading configuration from zotero-config.xml...")
    groupid, format_type = read_config()

    print(f"Group ID: {groupid}")
    print(f"Format: {format_type}")
    print("")

    # Create output directory
    output_dir = Path("data/zotero")
    items_dir = Path("data/zotero/items")

    # Delete existing output directory
    if output_dir.exists():
        shutil.rmtree(output_dir)

    if not args.extract_only:
        output_dir.mkdir(parents=True, exist_ok=True)

        # Download items in batches - we need TWO downloads:
        # 1. Data files with full structured bibliographic info
        # 2. Bib files with formatted citations
        # Check if we have existing downloads and resume from there
        existing_data_files = list(output_dir.glob('zotero_data_*.json'))
        if existing_data_files:
            # Find the highest start number
            start_numbers = [int(f.stem.split('_')[2]) for f in existing_data_files]
            start = max(start_numbers) + 100
            total = sum(len(json.load(open(f))) for f in existing_data_files)
            print(f"Resuming from item {start} ({total} items already downloaded)...")
        else:
            start = 0
            total = 0

        limit = 100

        while True:
            print(f"Downloading items {start} to {start + limit}...")

            # Download structured data
            data_content = download_batch(groupid, start, limit, download_type='data')
            if data_content is None:
                print("Error downloading data batch")
                if start == 0:
                    sys.exit(1)
                break

            # Parse JSON to count items
            try:
                data_items = json.loads(data_content)
                item_count = len(data_items)
            except json.JSONDecodeError as e:
                print(f"Error parsing data JSON: {e}")
                if data_content:
                    print(f"Content received (first 500 chars): {data_content[:500]}")
                break

            if item_count == 0:
                print("No more items to download")
                break

            # Download formatted citations (same batch)
            print(f"  Downloading citations for items {start} to {start + limit}...")
            bib_content = download_batch(groupid, start, limit, download_type='bib')
            if bib_content is None:
                print("  Warning: Error downloading bib batch, continuing without citations")
                bib_items = []
            else:
                try:
                    bib_items = json.loads(bib_content)
                except json.JSONDecodeError:
                    print("  Warning: Error parsing bib JSON, continuing without citations")
                    bib_items = []

            # Merge data and bib by key
            bib_by_key = {item['key']: item.get('bib', '') for item in bib_items}
            for item in data_items:
                item['bib'] = bib_by_key.get(item['key'], '')

            # Save merged JSON to file
            output_file = output_dir / f"zotero_data_{start}.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(data_items, f, indent=2, ensure_ascii=False)

            print(f"Downloaded {item_count} items (with citations) to {output_file}")
            total += item_count

            # If we got fewer items than the limit, we're done
            if item_count < limit:
                print("Reached last page")
                break

            start += limit

            # Be nice to the API - wait 3 seconds between requests (we made 2 requests)
            time.sleep(3)

        print("")
        print(f"Download complete! Total items: {total}")
        print(f"Files saved in: {output_dir}/")
        print("")

    if not args.no_extract:
        print("Extracting individual items with Chicago citations...")
        print("")
        extracted = extract_and_save_items(groupid, output_dir, items_dir)
        print("")
        print(f"Extraction complete! Total items: {extracted}")
        print(f"Individual items saved in: {items_dir}/")


if __name__ == '__main__':
    main()
