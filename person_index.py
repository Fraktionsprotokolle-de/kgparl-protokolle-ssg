import glob
import os

from typesense.exceptions import ObjectNotFound
from acdh_cfts_pyutils import TYPESENSE_CLIENT as client
from acdh_tei_pyutils.tei import TeiReader
from acdh_tei_pyutils.utils import (
    extract_fulltext,
    make_entity_label,
)
from tqdm import tqdm


class Person:
    def __init__(self, id):
        self.id = id
        self.reg = ""
        self.found = False
        self.forename = ""
        self.surname = ""
        self.prefix = ""
        self.letter = ""
        self.gnd = ""
        self.birth = ""
        self.death = ""
        self.isMDB = False


def normalize_name_search(text):
    """Add conservative search variants for names without changing display values."""
    if not text:
        return ""
    replacements = [
        ('ö', 'oe'), ('ü', 'ue'), ('ä', 'ae'), ('ß', 'ss'),
        ('Ö', 'Oe'), ('Ü', 'Ue'), ('Ä', 'Ae'),
        ('š', 'sch'), ('Š', 'Sch'),
    ]
    result = text
    for old, new in replacements:
        result = result.replace(old, new)
    return result


def CreatePersonIndex(personregister, person_found, collection_name=None):
    # Allow collection name to be passed as parameter, default for backwards compatibility
    COLLECTION_NAME = collection_name if collection_name else "kgparl_persons"
    print(f"Creating person index in collection: {COLLECTION_NAME}")

    try:
        client.collections[COLLECTION_NAME].delete()
    except ObjectNotFound:
        pass

    current_schema = {
        "name": COLLECTION_NAME,
        "enable_nested_fields": False,
        "fields": [
            {"name": "id", "type": "string"},
            {"name": "rec_id", "type": "string", "facet": True,
                "optional": False, "sort": True},
            {"name": "birth", "type": "string", "optional": True},
            {"name": "death", "type": "string", "optional": True},
            {"name": "birth_place", "type": "string", "optional": True},
            {"name": "death_place", "type": "string", "optional": True},
            {"name": "birth_country", "type": "string", "optional": True},
            {"name": "death_country", "type": "string", "optional": True},
            {"name": "forename", "type": "string"},
            {"name": "surname", "type": "string", "sort": True},
            {"name": "letter", "type": "string", "facet": True,
                "optional": False, "sort": True, "index": True},
            {"name": "prefix", "type": "string", "sort": False,
                "optional": True, "index": True},
            {"name": "reg", "type": "string", "sort": True, "index": True},
            {"name": "name_combined", "type": "string", "sort": False,
                "optional": True, "index": True},
            {"name": "name_search", "type": "string", "sort": False,
                "optional": True, "index": True},
            {"name": "found", "type": "bool", "facet": True,
                "optional": False, "sort": True, "index": True},
            {"name": "gnd", "type": "string", "sort": True,
                "index": True, "optional": True},
            {"name": "isMDB", "type": "bool",
                "optional": True, "sort": True, "index": True},
        ],
        "default_sorting_field": "rec_id",
    }

    client.collections.create(current_schema)

    # Convert person_found to a set for fast lookup
    person_found_set = set(person_found)

    records = []
    for personid, person_data in personregister.items():
        record = {}
        record["id"] = personid
        record["rec_id"] = personid
        surname = person_data.get("surname", "") or ""
        forename = person_data.get("forename", "") or ""
        # Fallback: if no surname, use forename (for sorting and letter detection)
        if not surname and forename:
            surname = forename
            forename = ""
        record["surname"] = surname
        record["forename"] = forename
        record["reg"] = person_data.get("reg", "") or ""
        # Letter from DB; fallback to first letter of surname
        letter = person_data.get("letter", "") or ""
        if not letter and record["surname"]:
            record["letter"] = record["surname"][0].upper()
        elif letter:
            record["letter"] = letter
        else:
            record["letter"] = "#"
        record["gnd"] = person_data.get("gnd", "") or ""

        # Mark whether this person appears in the protocols
        record["found"] = personid in person_found_set

        record["birth"] = person_data.get("birth", "") or None
        record["death"] = person_data.get("death", "") or None
        record["birth_place"] = person_data.get("birth_place", "") or None
        record["death_place"] = person_data.get("death_place", "") or None
        record["birth_country"] = person_data.get("birth_country", "") or None
        record["death_country"] = person_data.get("death_country", "") or None
        record["isMDB"] = person_data.get("isMDB", False) == True
        record["prefix"] = person_data.get("prefix", "") or None

        # Combined name field for better multi-token matching
        # "Brandt, Willy" + "Willy Brandt" → high score for both input orders
        parts = [p for p in [surname, forename, person_data.get("prefix", "")] if p]
        if surname and forename:
            record["name_combined"] = surname + ", " + forename + " " + forename + " " + surname
            if person_data.get("prefix", ""):
                record["name_combined"] += " " + person_data["prefix"]
        elif parts:
            record["name_combined"] = " ".join(parts)

        # Conservative search aliases for person names (e.g. Müller→Mueller, Jušenkov→Juschenkov)
        name_parts = [record["surname"], record["forename"], record.get("reg", "")]
        normalized = normalize_name_search(" ".join(p for p in name_parts if p))
        # Only store if different from original (has searchable variants)
        if normalized != " ".join(p for p in name_parts if p):
            record["name_search"] = normalized

        records.append(record)

    make_index = client.collections[COLLECTION_NAME].documents.import_(records)
    print("indexed amount persons: ", len(records))
    print(make_index)
    print(f"done with indexing {COLLECTION_NAME}")
