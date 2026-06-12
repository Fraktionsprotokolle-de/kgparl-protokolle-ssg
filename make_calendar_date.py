import glob
import os
import json
from acdh_tei_pyutils.tei import TeiReader
from acdh_tei_pyutils.utils import make_entity_label, extract_fulltext
from tqdm import tqdm


out_path = os.path.join("html", "js-data")
os.makedirs(out_path, exist_ok=True)

files = sorted(glob.glob("./data/editions/*.xml"))

# check if file exists, if so, delete it 
out_file = os.path.join(out_path, "calendarData.js")

if os.path.exists(out_file):
    os.remove(out_file)

data = []
skipped_files = []
for x in tqdm(files, total=len(files)):
    item = {}
    head, tail = os.path.split(x)
    try:
        doc = TeiReader(x)
    except Exception as e:
        print(f"\nSkipping {x} due to XML parsing error: {e}")
        skipped_files.append(x)
        continue
    try:
        item["name"] = doc.any_xpath('//tei:title[@level="a"]/text()')[0]
    except IndexError:
        print(f"\nSkipping {x}: no title found")
        skipped_files.append(x)
        continue
    try:
        item["startDate"] = doc.any_xpath('//tei:profileDesc//tei:creation/tei:date/@when')[0]
    except IndexError:
        continue

    try:
        if item["startDate"] is None:
            item["startDate"] = doc.any_xpath('//tei:profileDesc//tei:creation/tei:date/@from')[0].text
    except IndexError:
        continue

    try:
        item["fraktion"] = doc.any_xpath('//tei:profileDesc//tei:idno[@type="Fraktion-Landesgruppe"]')[0].text
    except IndexError:
        print(f"no fraktion for {x}")
        continue


    try:
        item["wp"] =  doc.any_xpath('//tei:profileDesc//tei:idno[@type="wp"]')[0].text
    except IndexError:
        print(f"no wp for {x}")
        continue
    
    try:
        item["id"] = tail.replace(".xml", ".html")
        data.append(item)
    except IndexError:
        print(f"no id for {x}")
        continue

    try:
        topics = []
        for y in doc.any_xpath('//tei:text//tei:list[@type="SVP"]//tei:item'):
            title = make_entity_label(y)[0]
            corresp = y.xpath("@corresp")[0]
            topics.append({"title": title, "corresp": corresp})
        item["topics"] = topics
    except IndexError:
        print(f"no topics for {x}")

with open(out_file, "w", encoding="utf8") as f:
    output = f"var KGParlData = {json.dumps(data, ensure_ascii=False)}"
    f.write(output)

if skipped_files:
    print(f"\n⚠ Skipped {len(skipped_files)} files due to errors:")
    for filepath in skipped_files:
        print(f"  - {filepath}")

print(f"\nProcessed {len(data)} files successfully.")
