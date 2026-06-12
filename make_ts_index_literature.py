import argparse
import glob
import locale
import os
import sys
import xml.etree.ElementTree as ET

# Parse --env argument early before importing acdh_cfts_pyutils
parser = argparse.ArgumentParser(description="Index literature to Typesense")
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

from sentence_transformers import SentenceTransformer


from dotenv import load_dotenv


def get_vectors(text):
    return model.encode(text)[0].tolist()


locale.setlocale(category=locale.LC_ALL, locale="de_DE.UTF-8")

# Load the .env file
load_dotenv()

files = glob.glob("./data/zotero/items/*.xml")

# Collection name from environment config
COLLECTION_NAME = ts_config["collections"]["literature"]
MIN_DATE = "1949"

print(f"Using environment: {args.env}")
print(f"Literature collection: {COLLECTION_NAME}")

model = SentenceTransformer('sentence-transformers/all-MiniLM-L12-v2')


try:
    client.collections[COLLECTION_NAME].delete()
    print("Collection deleted")
except ObjectNotFound:
    pass

# Initialize PersonDict
# person_dict = createPersonDict()

current_schema = {
    "name": COLLECTION_NAME,
    "enable_nested_fields": True,
    "fields": [
        {"name": "id", "type": "string"},
        {"name": "rec_id", "type": "string", "facet": True, "optional": False},
        {"name": "title", "type": "string", "optional": False, "sort": True},
        {"name": "date", "type": "string", "sort": True},
        {"name": "year", "type": "int32", "facet": True,
            "optional": True, "sortable": True},
        {"name": "letter", "type": "string[]", "facet": True,
         "optional": False,  "index": True},
        {"name": "href", "type": "string", "optional": False},
        {
            "name": "authors",
            "type": "string[]",
            "facet": True,
            "optional": True,
            "sortable": True
        },
    ],
}

# Create additional virtual Indices

client.collections.create(current_schema)

records = []
# cfts_records = []

# Define XML namespace
namespaces = {'tei': 'http://www.tei-c.org/ns/1.0'}

for x in tqdm(files, total=len(files)):
    cfts_record = {
        "project": COLLECTION_NAME,
    }

    # Parse the XML file
    tree = ET.parse(x)
    root = tree.getroot()

    # Find the biblStruct element
    bibl_struct = root.find('.//tei:biblStruct', namespaces)

    if bibl_struct is None:
        print(f"No biblStruct found in {x}")
        continue

    record = {}

    # Extract xml:id as the record ID
    xml_id = bibl_struct.get('{http://www.w3.org/XML/1998/namespace}id')
    if xml_id:
        record["id"] = xml_id
        record["rec_id"] = xml_id
    else:
        print(f"No xml:id found in {x}")
        continue

    # Extract title from bibl element (this is the citation text)
    bibl_elem = bibl_struct.find('.//tei:bibl', namespaces)
    if bibl_elem is not None and bibl_elem.text:
        record["title"] = bibl_elem.text.strip()
    else:
        record["title"] = "Kein Titel"
        print(f"title issues in {x}")

    # Extract date
    date_elem = bibl_struct.find('.//tei:date', namespaces)
    if date_elem is not None and date_elem.text:
        date_str = date_elem.text.strip()
        record["date"] = date_str
        try:
            record["year"] = int(date_str[:4])
        except (ValueError, IndexError):
            pass
    else:
        record["date"] = "ohne Datum"
        print(f"date issues in {record['id']}")

    # Extract authors
    record["authors"] = []
    record["letter"] = []

    authors = bibl_struct.findall('.//tei:author', namespaces)
    for author in authors:
        forename = author.find('tei:forename', namespaces)
        surname = author.find('tei:surname', namespaces)

        if forename is not None and surname is not None:
            label = f"{surname.text}, {forename.text}"
        elif surname is not None:
            label = surname.text
        else:
            continue

        if label and label != "":
            record["authors"].append(label)
            print("adding letter: " + label[:1])

            if label[:1] not in record["letter"]:
                record["letter"].append(label[:1])

    # Extract href from corresp attribute
    corresp = bibl_struct.get('corresp')
    if corresp:
        record["href"] = corresp
    else:
        record["href"] = "keine URL"
        print(f"No href found in {record['id']}")

    # Create Vectors
    sentences = [record["title"]]

    # check if sentences are not empty
    if len(sentences) == 0 or sentences == [""]:
        record["vectors"] = []
    else:
        record["vectors"] = get_vectors(sentences)

    records.append(record)

# Import data to Typesense
make_index = client.collections[COLLECTION_NAME].documents.import_(records)
print(make_index)
print(f"done with indexing {COLLECTION_NAME}")
print(f"indexed amount literature: ", len(records))
