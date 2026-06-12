import argparse
import glob
import os
import datetime
import locale
import sqlite3
import time
import sys
import json

# Parse --env argument early before importing acdh_cfts_pyutils
parser = argparse.ArgumentParser(description="Index protocols to Typesense")
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
# from acdh_cfts_pyutils import CFTS_COLLECTION
from acdh_tei_pyutils.tei import TeiReader
from acdh_tei_pyutils.utils import (
    extract_fulltext,
    get_xmlid,
    make_entity_label,
    check_for_hash,
)
from tqdm import tqdm

from sentence_transformers import SentenceTransformer

from person_index import CreatePersonIndex, Person

from dotenv import load_dotenv

records = []


def load_keyword_register():
    """Load the keyword register (tei-fpv.xml) and return a dict mapping xml:id → pref label."""
    from lxml import etree
    keyword_file = os.path.join(os.path.dirname(__file__), "data", "indices", "tei-fpv.xml")
    if not os.path.exists(keyword_file):
        print(f"⚠ Keyword register not found at {keyword_file}")
        return {}
    tree = etree.parse(keyword_file)
    ns = {"tei": "http://www.tei-c.org/ns/1.0", "xml": "http://www.w3.org/XML/1998/namespace"}
    keyword_dict = {}
    for item in tree.xpath("//tei:standOff/tei:list[@type='fpv']/tei:item", namespaces=ns):
        xml_id = item.get("{http://www.w3.org/XML/1998/namespace}id")
        pref = item.xpath("tei:term[@type='pref']/text()", namespaces=ns)
        if xml_id and pref:
            keyword_dict[xml_id] = pref[0]
    return keyword_dict


def get_person_label(personid):
    global c
    personid = personid.replace("#", "")

    try:
        person = person_dict[personid]
        surname = person.get("surname", "")
        forename = person.get("forename", "")
        prefix = person.get("prefix", "")
        if surname and forename:
            label = surname + ", " + forename
            if prefix:
                label += " " + prefix
        else:
            label = person.get("reg", "")
        if label != "" and personid not in person_found:
            person_found.append(personid)
        return label
    except IndexError:
        return ""
    except KeyError:
        return ""
    except:
        sys.exit("Error with" + personid)


def get_persons_from_db():
    global c
    person_dict = {}
    query = "SELECT id, reg, forename, surname, letter, gnd, birth_date, death_date, isMDB, Found, birth_place, death_place, birth_country, death_country, prefix FROM persons;"
    c.execute(query)
    result = c.fetchall()

    for row in result:
        id = ""
        id = row[0]
        person_dict[id] = {}
        person_dict[id]["id"] = id
        person_dict[id]["forename"] = row[2]
        person_dict[id]["surname"] = row[3]
        person_dict[row[0]]["reg"] = row[1]
        person_dict[row[0]]["sex"] = row[4]
        person_dict[row[0]]["gnd"] = row[5]
        person_dict[row[0]]["birth"] = row[6]
        person_dict[row[0]]["death"] = row[7]
        person_dict[row[0]]["isMDB"] = row[8]
        person_dict[row[0]]["letter"] = row[4]
        person_dict[row[0]]["found"] = row[9]
        person_dict[row[0]]["birth_place"] = row[10]
        person_dict[row[0]]["death_place"] = row[11]
        person_dict[row[0]]["birth_country"] = row[12]
        person_dict[row[0]]["death_country"] = row[13]
        person_dict[row[0]]["prefix"] = row[14]
    return person_dict


def get_vectors(text):
    return model.encode(text)[0].tolist()


def load_synonyms(collection_name):
    """Server-seitige Typesense-Synonyme sind deaktiviert (seit 2026-02-26).

    Hintergrund:
      Typesense tokenisiert Multi-Wort-Synonyme in einzelne Tokens. Eine Suche
      nach "KGParl" wurde dadurch auf "Kommission", "für", "Geschichte", "des",
      "Parlamentarismus", "und", "der", "politischen", "Parteien" expandiert —
      jedes Wort einzeln als Match, was zu massenhaft irrelevanten Treffern führte.

    Neuer Ansatz:
      Synonym-Expansion läuft komplett im Frontend (search.js):
      1. SYNONYM_MAP (aus synonymData.js) liefert Alternativen pro Suchbegriff
      2. Für jede Alternative werden die passenden Dokument-IDs + Highlight-Snippets
         separat von Typesense geholt (fetchSynonymResults)
      3. Diese werden als `pinned_hits` in die Ergebnisse eingefügt (OR-Semantik)
      4. Highlight-Snippets werden nach dem Render client-seitig injiziert

    Siehe: html/js/search.js (Synonym-Expansion), generate_synonym_js() (Datengenerierung)
    """
    print(f"Skipping server-side synonyms for {collection_name} "
          "(handled by frontend synonym expansion)")


def generate_synonym_js(output_path="./html/js-data/synonymData.js"):
    """Generiert synonymData.js — ein JS-Lookup für die Frontend-Synonym-Expansion.

    Eingabe: data/synonyms/*.jsonl — jede Zeile ist ein JSON-Objekt mit:
      { "synonyms": ["KGParl", "Kommission für Geschichte des Parlamentarismus und der politischen Parteien e. V."] }

    Ausgabe: html/js-data/synonymData.js mit:
      const SYNONYM_MAP = {
        "kgparl": ["Kommission für Geschichte des Parlamentarismus und der politischen Parteien"],
        "kommission für geschichte des parlamentarismus und der politischen parteien": ["KGParl"],
        ...
      };

    Verarbeitungsregeln:
    - Jeder Wert in "synonyms" wird als Key angelegt, der auf alle ANDEREN Werte zeigt
    - Keys sind lowercase (case-insensitives Lookup im Frontend)
    - Rechtliche Suffixe (e. V., GmbH, AG, gGmbH) werden entfernt, da sie in den
      Protokolltexten nicht vorkommen
    - Ein Entry wird nur erstellt, wenn mindestens eine Alternative mehrere Wörter hat
      (Einwort↔Einwort-Synonyme werden nicht gebraucht, da Typesense Fuzzy-Matching hat)

    Wird aufgerufen am Ende des Indexierungslaufs (make_ts_index.py).
    Muss vor search.js geladen werden (via <script>-Tag in search.xsl).
    """
    import re
    _legal_suffix = re.compile(r'\s+(?:e\.\s*V\.?|GmbH|AG|gGmbH)\s*$')

    synonym_files = glob.glob("./data/synonyms/*.jsonl")
    synonyms = {}  # key (lowercase) → [alt1, alt2, …]
    for synonym_file in synonym_files:
        with open(synonym_file, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        data = json.loads(line)
                        syns = data['synonyms']
                        if len(syns) < 2:
                            continue
                        # Clean up values
                        cleaned = []
                        for s in syns:
                            cleaned.append(_legal_suffix.sub('', s).strip())
                        # For each value, map it to all other values
                        for i, key in enumerate(cleaned):
                            others = [cleaned[j] for j in range(len(cleaned)) if j != i]
                            # Only create an entry if at least one alternative is multi-word
                            if any(' ' in o for o in others):
                                synonyms[key.lower()] = others
                    except json.JSONDecodeError:
                        continue

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as out:
        out.write('// Auto-generated from data/synonyms/*.jsonl -- do not edit manually\n')
        out.write('const SYNONYM_MAP = ')
        out.write(json.dumps(synonyms, ensure_ascii=False, indent=2))
        out.write(';\n')
    print(f"Generated {output_path} with {len(synonyms)} synonym entries")


def make_index_introduction(introductions, COLLECTION_EINLEITUNG_NAME):
    records = []
    skipped_files = []
    for x in tqdm(introductions, total=len(introductions)):
        cfts_record = {
            "project": COLLECTION_EINLEITUNG_NAME,
        }
        record = {}
        try:
            doc = TeiReader(x)
        except Exception as e:
            print(f"\nSkipping {x} due to XML parsing error: {e}")
            skipped_files.append(x)
            continue
        try:
            body = doc.any_xpath(".//tei:body")[0]
            record["id"] = os.path.split(x)[-1].replace(".xml", "")
            # cfts_record["id"] = record["id"]
            print(record["id"])
        except IndexError:
            print("Index-Error on document " + x)


        record["rec_id"] = os.path.split(x)[-1]
        # cfts_record["rec_id"] = record["rec_id"]

        try:
            record["title"] = extract_fulltext(
                doc.any_xpath('.//tei:titleStmt/tei:title[@level="a"]')[0]
            )

        except Exception as e:
            print(f"title issues in {x}, due to: {e}")
            record["title"] = "Kein Titel"


        record["persons"] = set()
        try:
            for y in doc.any_xpath(".//tei:text//tei:name[@type='Person']"):
                id = y.xpath("@ref")[0]
                label = get_person_label(str(id))

                # check if id contains BrandtWilly_1949-09-07
        #        if not str(id) in person_found:
                if label != "":
                    record["persons"].add(label)

        # cfts_record["persons"] = [x["label"] for x in record["persons"]]
        except IndexError:
            print("Error found at " + record["id"])

        # Convert set back to list
        record["persons"] = list(record["persons"])

        record["orgs"] = []
        for y in doc.any_xpath(".//tei:text//tei:org[@xml:id]"):
            try:
                if y:
                    item = {"id": y.xpath(
                        "@ref")[0], "label": make_entity_label(y.xpath("./*[1]")[0])[0]}
                    record["orgs"].append(item)
            except IndexError:

                print("IndexError at " + record["id"])
                print(y)

        record["full_text"] = f"{extract_fulltext(body)} {record['title']}".replace("(", " ")

        record["items"] = []
        for y in doc.any_xpath('.//tei:text/tei:body//tei:div'):
            try:
                name = y.xpath("./@type")
                link = y.xpath("./@xml:id")
                if name and link:
                    item = {
                        "name": name[0].strip(),
                        "link": link[0]
                    }
                    record["items"].append(item)
            except IndexError:
                print("IndexError at " + record["id"])
                print(y)
        # cfts_record["full_text"] = record["full_text"]
        records.append(record)
        # cfts_records.append(cfts_record)

        # Create Vectors
        sentences = [record["full_text"]] + record["persons"] + record["orgs"]

        # check if sentences are not empty
        if len(sentences) == 0 or sentences == [""]:
            record["vectors"] = []
        else:
            # record["vectors"] = []
            record["vectors"] = get_vectors(sentences)
        # cfts_record["vectors"] = record["vectors"]
        records.append(record)

    if skipped_files:
        print(f"\n⚠ Skipped {len(skipped_files)} introduction files due to XML errors:")
        for filepath in skipped_files:
            print(f"  - {filepath}")

    return records


def make_index_protocol(files, COLLECTION_NAME):
    records = []
    print("Making index for protocol files")

    print(f"Total files to process: {len(files)}")
    skipped_files = []
    for x in tqdm(files, total=len(files)):
        cfts_record = {
            "project": COLLECTION_NAME,
        }
        record = {}
        try:
            doc = TeiReader(x)
        except Exception as e:
            print(f"\nSkipping {x} due to XML parsing error: {e}")
            skipped_files.append((x, str(e)))
            continue
        try:
            body = doc.any_xpath(".//tei:body")[0]
            record["id"] = os.path.split(x)[-1].replace(".xml", "")
            # cfts_record["id"] = record["id"]
            print(record["id"])
        except IndexError:
            print("Index-Error on document " + x)

        # cfts_record["resolver"] = (
        #    f"https://www.fraktionsprotokolle.de/{record['id']}.html"
        # )
        record["rec_id"] = os.path.split(x)[-1]
        # cfts_record["rec_id"] = record["rec_id"]

        # check if xml:id of category is not "EINL"
        try:
            if doc.any_xpath(
                '//tei:category[@xml:id="EINL"]'
            )[0] is not None:
                continue
        except IndexError:
            pass

        try:
            record["title"] = extract_fulltext(
                doc.any_xpath('.//tei:titleStmt/tei:title[@level="a"]')[0]
            )
        except Exception as e:
            print(f"title issues in {x}, due to: {e}")
            record["title"] = "Kein Titel"

        # cfts_record["title"] = record["title"]

        try:
            record["party"] = doc.any_xpath(
                '//tei:profileDesc//tei:idno[@type="Fraktion-Landesgruppe"]'
            )[0].text
            # cfts_record["party"] = record["party"]
        except IndexError:
            record["party"] = "Keine Fraktion"
            # cfts_record["party"] = record["party"]

        try:
            record["period"] = doc.any_xpath(
                '//tei:profileDesc//tei:idno[@type="wp"]'
            )[0].text
            cfts_record["period"] = record["period"]
        except IndexError:
            record["period"] = "Keine Wahlperiode"
            # cfts_record["period"] = record["period"]

        try:
            date_str = doc.any_xpath(
                '//tei:profileDesc//tei:creation/tei:date/@when'
            )[0]
        except IndexError:
            date_str = MIN_DATE

        # if date_str is MIN_DATE, try to get from date because of multiple dates
        if date_str == MIN_DATE:
            try:
                date_str = doc.any_xpath(
                    '//tei:profileDesc//tei:creation/tei:date[1]/@from'
                )[0]
            except IndexError:
                date_str = MIN_DATE

        try:
            record["date"] = date_str
            # cfts_record["date"] = date_str
        except ValueError:
            pass

        try:
            record["year"] = int(date_str[:4])
            # cfts_record["year"] = date_str[:4]
        except ValueError:
            pass

        try:
            record["sitzungsabfolge"] = int(doc.any_xpath(
                '//tei:profileDesc//tei:idno[@type="sitzungsabfolge"]'
            )[0].text)
        except (IndexError, TypeError, ValueError):
            record["sitzungsabfolge"] = 1

        record["persons"] = set()
        try:
            for y in doc.any_xpath(".//tei:text//tei:name[@type='Person']"):
                id = y.xpath("@ref")[0]
                label = get_person_label(str(id))

                # check if id contains BrandtWilly_1949-09-07
        #        if not str(id) in person_found:
                if label != "":
                    record["persons"].add(label)

        # cfts_record["persons"] = [x["label"] for x in record["persons"]]
        except IndexError:
            print("Error found at " + record["id"])

        # Convert set back to list
        record["persons"] = list(record["persons"])

        record["orgs"] = []
        for y in doc.any_xpath(".//tei:text//tei:org[@xml:id]"):
            try:
                if y:
                    item = {"id": y.xpath(
                        "@ref")[0], "label": make_entity_label(y.xpath("./*[1]")[0])[0]}
                    record["orgs"].append(item)
            except IndexError:

                print("IndexError at " + record["id"])
                print(y)

        # Extract keyword tags: <term ref="#keyword-id"> and <name ref="#keyword-id" type="Organisation">
        keyword_labels = set()
        for y in doc.any_xpath(".//tei:text//tei:term[@ref]"):
            ref = y.get("ref", "").lstrip("#")
            if ref and ref in keyword_register:
                keyword_labels.add(keyword_register[ref])
        for y in doc.any_xpath(".//tei:text//tei:name[@type='Organisation' and @ref]"):
            ref = y.get("ref", "").lstrip("#")
            if ref and ref in keyword_register:
                keyword_labels.add(keyword_register[ref])
        record["keywords"] = list(keyword_labels)

        record["full_text"] = f"{extract_fulltext(body)} {record['title']}".replace("(", " ")

        record["items"] = []
        for y in doc.any_xpath('.//tei:text/tei:front//tei:list[@type="SVP"]//tei:item'):
            try:
                name = y.xpath("./text()")
                link = y.xpath("./@corresp")
                if name and link:
                    item = {
                        "name": name[0].strip(),
                        "link": link[0]
                    }
                    record["items"].append(item)
            except IndexError:
                print("IndexError at " + record["id"])
                print(y)
        # cfts_record["full_text"] = record["full_text"]
        records.append(record)
        # cfts_records.append(cfts_record)

        # Create Vectors
        sentences = [record["full_text"]] + record["persons"] + record["orgs"]

        # check if sentences are not empty
        if len(sentences) == 0 or sentences == [""]:
            record["vectors"] = []
        else:
             record["vectors"] = []
            # record["vectors"] = get_vectors(sentences)
        # cfts_record["vectors"] = record["vectors"]
        records.append(record)

    if skipped_files:
        print(f"\n⚠ Skipped {len(skipped_files)} files due to XML errors:")
        for filepath, error in skipped_files:
            print(f"  - {filepath}")

    return records


locale.setlocale(category=locale.LC_ALL, locale="de_DE.UTF-8")

nsmap = {
    "tei": "http://www.tei-c.org/ns/1.0",
    "xml": "http://www.w3.org/XML/1998/namespace",
}

# Load the .env file
load_dotenv()

files = glob.glob("./data/editions/*.xml")
introductions = glob.glob("./data/einleitungen/*.xml")

# Collection names from environment config
COLLECTION_NAME = ts_config["collections"]["protocols"]
COLLECTION_EINLEITUNG_NAME = ts_config["collections"]["einleitung"]
MIN_DATE = "1949"

print(f"Using environment: {args.env}")
print(f"Protocol collection: {COLLECTION_NAME}")
print(f"Einleitung collection: {COLLECTION_EINLEITUNG_NAME}")


person_dict = {}
person_found = []
keyword_register = load_keyword_register()
print(f"keyword_register loaded with {len(keyword_register)} entries")
model = SentenceTransformer('sentence-transformers/all-MiniLM-L12-v2')
db_path = "./golang/persons.db"

try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    print("Database connected successfully.")
except sqlite3.Error as e:
    print(f"Error connecting to {db_path}: {e}")
    exit()


person_dict = get_persons_from_db()
print("person_dict loaded with " + str(len(person_dict)) + " entries")


try:
    client.collections[COLLECTION_NAME].delete()
    client.collections[COLLECTION_EINLEITUNG_NAME].delete()
    print("Collections deleted")
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
        {"name": "title", "type": "string"},
        {"name": "full_text", "type": "string"},
        {"name": "party", "type": "string", "facet": True,
            "optional": False, "sort": True, "index": True},
        {"name": "period", "type": "string", "facet": True,
            "optional": False, "sort": True, "index": True},
        {"name": "date", "type": "string", "sort": True},
        {
            "name": "year",
            "type": "int32",
            "optional": False,
            "facet": True,
            "sort": True,
        },
        {
            "name": "sitzungsabfolge",
            "type": "int32",
            "optional": True,
            "sort": True,
        },
        {
            "name": "persons",
            "type": "string[]",
            "facet": True,
            "optional": True,
            # "fields" : [
            #   {
            #       "name":"id",
            #       "type": "string"
            #   },
            #   {
            #       "name":"label",
            #       "type": "string"
            #   }
            # ]
        },
        {
            "name": "orgs",
            "type": "string[]",
            "facet": True,
            "optional": True,
        },
        {
            "name": "keywords",
            "type": "string[]",
            "facet": True,
            "optional": True,
        },
        {
            "name": "items",
            "type": "object[]",
            "optional": True,
            "fields": [
                {
                    "name": "name",
                    "type": "string"
                },
                {
                    "name": "link",
                    "type": "string"
                }
            ]
        }
    ],
    "default_sorting_field": "year",
}

current_schema_einleitung = {
    "name": COLLECTION_EINLEITUNG_NAME,
    "enable_nested_fields": True,
    "fields": [
        {"name": "id", "type": "string"},
        {"name": "rec_id", "type": "string", "facet": True, "optional": False},
        {"name": "title", "type": "string", "sort": True},
        {"name": "full_text", "type": "string"},
        {
            "name": "persons",
            "type": "string[]",
            "facet": True,
            "optional": True,
            # "fields" : [
            #   {
            #       "name":"id",
            #       "type": "string"
            #   },
            #   {
            #       "name":"label",
            #       "type": "string"
            #   }
            # ]
        },
    ],
    "default_sorting_field": "title",
}

# Create additional virtual Indices
try:
    client.collections[COLLECTION_NAME].delete()
except ObjectNotFound:
    pass


try:
    client.collections[COLLECTION_EINLEITUNG_NAME].delete()
except ObjectNotFound:
    pass

client.collections.create(current_schema)
client.collections.create(current_schema_einleitung)

# Load synonyms into the collection
load_synonyms(COLLECTION_NAME)
load_synonyms(COLLECTION_EINLEITUNG_NAME)

# Protokolle
print(f"Starting indexing {COLLECTION_NAME}")
records = make_index_protocol(files, COLLECTION_NAME)
make_index = client.collections[COLLECTION_NAME].documents.import_(records)
print(f"done with indexing {COLLECTION_NAME}")

# Einleitungen
records_einleitung = make_index_introduction(
    introductions, COLLECTION_EINLEITUNG_NAME)
print(f"Starting indexing {COLLECTION_EINLEITUNG_NAME}")
make_index_einleitung = client.collections[COLLECTION_EINLEITUNG_NAME].documents.import_(records_einleitung)
print(f"done with indexing {COLLECTION_EINLEITUNG_NAME}")

print(f"Starting PersonIndex")
# get all persons from db
print("current persons found: " + str(len(person_found)))
persons_collection = ts_config["collections"]["persons"]
CreatePersonIndex(person_dict, person_found, persons_collection)
print(f"done with PersonIndex")

# Generate frontend synonym lookup
generate_synonym_js()

# close connctions
c.close()
conn.close()
