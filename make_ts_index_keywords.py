import argparse
import locale
import os
import sys
import unicodedata
import xml.etree.ElementTree as ET

# Parse --env argument early before importing acdh_cfts_pyutils
parser = argparse.ArgumentParser(description="Index keywords (FPV) to Typesense")
parser.add_argument("--env", choices=["live", "test"], default="live",
                    help="Environment to use (default: live)")
args = parser.parse_args()

# Set up environment variables before importing Typesense client
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'scripts'))
from env_config import get_typesense_config, setup_typesense_env_vars

# Set up Typesense env vars for acdh_cfts_pyutils
setup_typesense_env_vars(args.env)
ts_config = get_typesense_config(args.env)

from typesense.exceptions import ObjectNotFound
from acdh_cfts_pyutils import TYPESENSE_CLIENT as client
from tqdm import tqdm

from dotenv import load_dotenv

locale.setlocale(category=locale.LC_ALL, locale="de_DE.UTF-8")

# Load the .env file
load_dotenv()

# Collection name from environment config
COLLECTION_NAME = ts_config["collections"]["keywords"]

print(f"Using environment: {args.env}")
print(f"Keywords collection: {COLLECTION_NAME}")

# Define XML namespace
namespaces = {'tei': 'http://www.tei-c.org/ns/1.0'}

# Parse the FPV XML file
FPV_FILE = "./data/indices/tei-fpv.xml"
tree = ET.parse(FPV_FILE)
root = tree.getroot()

# Find all items in the FPV list
items = root.findall('.//tei:standOff/tei:list[@type="fpv"]/tei:item', namespaces)

print(f"Found {len(items)} keyword items")

try:
    client.collections[COLLECTION_NAME].delete()
    print("Collection deleted")
except ObjectNotFound:
    pass

current_schema = {
    "name": COLLECTION_NAME,
    "fields": [
        {"name": "id", "type": "string"},
        {"name": "prefLabel", "type": "string", "sort": True},
        {"name": "altLabels", "type": "string[]", "optional": True},
        {"name": "letter", "type": "string", "facet": True},
        {"name": "entityType", "type": "string", "facet": True},
        {"name": "definition", "type": "string", "optional": True},
    ],
}

client.collections.create(current_schema)

# Helper: normalize first letter (Ö→O, Ä→A, Ü→U, etc.)
def normalize_letter(char):
    if not char:
        return "#"
    # NFD decomposition strips diacritics
    nfkd = unicodedata.normalize('NFKD', char.upper())
    base = ''.join(c for c in nfkd if not unicodedata.combining(c))
    if base and base[0].isalpha():
        return base[0]
    return "#"

records = []

for item in tqdm(items, total=len(items)):
    xml_id = item.get('{http://www.w3.org/XML/1998/namespace}id')
    if not xml_id:
        print(f"Skipping item without xml:id")
        continue

    record = {"id": xml_id}

    # prefLabel: term[@type='pref']
    pref_term = item.find('tei:term[@type="pref"]', namespaces)
    if pref_term is not None and pref_term.text:
        record["prefLabel"] = pref_term.text.strip()
    else:
        record["prefLabel"] = xml_id
        print(f"No prefLabel for {xml_id}")

    # altLabels: term[@type='alt']
    alt_terms = item.findall('tei:term[@type="alt"]', namespaces)
    alt_labels = []
    for alt in alt_terms:
        if alt.text and alt.text.strip():
            alt_labels.append(alt.text.strip())
    if alt_labels:
        record["altLabels"] = alt_labels

    # letter: first letter of prefLabel (normalized)
    record["letter"] = normalize_letter(record["prefLabel"][0] if record["prefLabel"] else "")

    # entityType: note[@type='entityType']
    entity_note = item.find('tei:note[@type="entityType"]', namespaces)
    if entity_note is not None and entity_note.text:
        record["entityType"] = entity_note.text.strip()
    else:
        record["entityType"] = "topic"

    # definition: note[@type='definition']
    def_note = item.find('tei:note[@type="definition"]', namespaces)
    if def_note is not None and def_note.text:
        record["definition"] = def_note.text.strip()

    records.append(record)

# Import data to Typesense
make_index = client.collections[COLLECTION_NAME].documents.import_(records)
print(make_index)
print(f"done with indexing {COLLECTION_NAME}")
print(f"indexed amount keywords: {len(records)}")
