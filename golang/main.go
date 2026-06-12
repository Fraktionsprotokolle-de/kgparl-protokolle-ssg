package main

import (
	"database/sql"
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"unicode"

	_ "github.com/mattn/go-sqlite3"
	"golang.org/x/text/unicode/norm"
)

type TEI struct {
	XMLName xml.Name `xml:"TEI"`
	Text    Text     `xml:"text"`
}

type Text struct {
	Body Body `xml:"body"`
}

type Body struct {
	ListPerson []ListPerson `xml:"listPerson"`
}

type ListPerson struct {
	Type    string   `xml:"type,attr"`
	Persons []Person `xml:"person"`
}

type Person struct {
	ID          string        `xml:"id,attr"`
	PersName    []PersName    `xml:"persName"`
	Sex         Sex           `xml:"sex"`
	Birth       Event         `xml:"birth"`
	Death       Event         `xml:"death"`
	Affiliation []Affiliation `xml:"affiliation"`
	Idno        []Idno        `xml:"idno"`
	isMDB       bool
	Letter      string
	GND         string
	Found       bool
}

type PersName struct {
	N        string    `xml:"n,attr,omitempty"`
	Type     string    `xml:"type,attr,omitempty"`
	Text     string    `xml:",chardata"`
	Reg      string    `xml:"reg"`
	Forename string    `xml:"forename"`
	Surname  string    `xml:"surname"`
	AddName  []AddName `xml:"addName"`
	RoleName RoleName  `xml:"roleName"`
}

// NamedPersName returns the first persName with an n attribute (the structured name).
func (p Person) NamedPersName() PersName {
	for _, pn := range p.PersName {
		if pn.N != "" {
			return pn
		}
	}
	// Fallback: return first entry
	if len(p.PersName) > 0 {
		return p.PersName[0]
	}
	return PersName{}
}

// DisplayName returns the display name from persName[@type='display'], or reg, or forename+surname.
func (p Person) DisplayName() string {
	for _, pn := range p.PersName {
		if pn.Type == "display" {
			text := strings.TrimSpace(pn.Text)
			if text != "" {
				return text
			}
		}
	}
	named := p.NamedPersName()
	if named.Reg != "" {
		return named.Reg
	}
	return strings.TrimSpace(named.Forename + " " + named.Surname)
}

type AddName struct {
	Text string `xml:",chardata"`
	Type string `xml:"type,attr"`
}

type RoleName struct{}

type Sex struct {
	Value string `xml:"value,attr"`
}

type Event struct {
	Date      Date   `xml:"date"`
	PlaceName string `xml:"placeName"`
	Country   string `xml:"country"`
}

type Date struct {
	When string `xml:"when,attr"`
}

type Affiliation struct {
	Type       string        `xml:"type,attr"`
	Role       string        `xml:"role,attr,omitempty"`
	Period     string        `xml:"period,attr,omitempty"`
	From       string        `xml:"from,attr,omitempty"`
	To         string        `xml:"to,attr,omitempty"`
	Content    string        `xml:",chardata"`
	SubEntries []Affiliation `xml:"affiliation"`
}

type Idno struct {
	Type    string `xml:"type,attr"`
	Content string `xml:",chardata"`
}

// normalizeLetter strips diacritics and returns the uppercase base letter.
// Ö→O, Č→C, İ→I, Ō→O, Ş→S, Ž→Z, etc.
func normalizeLetter(s string) string {
	if s == "" {
		return ""
	}
	// NFD decomposes: Ö → O + combining-diaeresis, Č → C + combining-caron, etc.
	decomposed := norm.NFD.String(s)
	// Take first non-combining rune (the base letter)
	for _, r := range decomposed {
		if !unicode.Is(unicode.Mn, r) { // Mn = Mark, Nonspacing (combining diacritics)
			return strings.ToUpper(string(r))
		}
	}
	return strings.ToUpper(s[:1])
}

func loadAndDumpToSQLite() error {
	// Load XML
	pwd, _ := os.Getwd()
	fp := filepath.Join(pwd, "..", "data", "indices", "Personen.xml")

	var tei TEI
	content, err := ioutil.ReadFile(fp)
	if err != nil {
		return fmt.Errorf("error reading file: %w", err)
	}
	err = xml.Unmarshal(content, &tei)
	if err != nil {
		return fmt.Errorf("error unmarshaling XML: %w", err)
	}

	// Create SQLite database
	db, err := sql.Open("sqlite3", "persons.db")
	if err != nil {
		return fmt.Errorf("error opening database: %w", err)
	}
	defer db.Close()

	// Drop and recreate tables to ensure clean state
	db.Exec(`DROP TABLE IF EXISTS personNames`)
	db.Exec(`DROP TABLE IF EXISTS affiliations`)
	db.Exec(`DROP TABLE IF EXISTS persons`)

	// Create table
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS persons (
		id TEXT PRIMARY KEY,
		forename TEXT,
		surname TEXT,
		reg TEXT,
		sex TEXT,
		prefix TEXT,
		birth_date TEXT,
		birth_place TEXT,
		birth_country TEXT,
		death_date TEXT,
		death_place TEXT,
		death_country TEXT,
		isMDB BOOLEAN,
		letter TEXT,
		gnd TEXT,
		found BOOLEAN
	)`)

	// Create table if it doesn't exist for Person Names
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS personNames (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		person_id TEXT,
		n INTEGER,
		forename TEXT,
		surname TEXT,
		reg TEXT,
		addName TEXT,
		roleName TEXT
	)`)

	if err != nil {
		log.Fatal(err)
	}

	// Create table if it doesn't exist
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS affiliations (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		person_id TEXT,
		type TEXT,
		role TEXT,
		period TEXT,
		"from" TEXT,
		"to" TEXT,
		content TEXT
	)`)
	if err != nil {
		return fmt.Errorf("error creating table: %w", err)
	}

	// Prepare insert statement
	stmt, err := db.Prepare(`INSERT OR REPLACE INTO persons
		(id, forename, surname, reg, prefix, sex, birth_date, birth_place, birth_country, death_date, death_place, death_country, isMDB, letter, gnd, found)
		VALUES (?, ?, ?, ?, ?,?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("error preparing statement: %w", err)
	}
	defer stmt.Close()

	// Prepare insert statement for affiliations
	stmt2, err := db.Prepare(`INSERT OR REPLACE INTO affiliations 
		( person_id, type, role, period, "from", "to", content) 
		VALUES ( ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("error preparing statement: %w", err)
	}
	defer stmt2.Close()

	// Preare insert statement for personNames
	stmt3, err := db.Prepare(`INSERT OR REPLACE INTO personNames 
		( person_id, n, forename, surname, reg, addName, roleName) 
		VALUES ( ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("error preparing statement: %w", err)
	}
	defer stmt3.Close()

	// Insert data
	for _, lp := range tei.Text.Body.ListPerson {
		// Skip KGParl staff — not part of the edition
		if lp.Type == "Mitarbeiter-KGParl" {
			fmt.Printf("Skipping listPerson type=%s (%d persons)\n", lp.Type, len(lp.Persons))
			continue
		}
		fmt.Printf("Persons in list: %d\n", len(lp.Persons))
		for _, p := range lp.Persons {

			//fmt.Printf("Person: %s\n", p.PersName[0].Surname)

			p.isMDB = false
			if lp.Type == "MdB" {
				p.isMDB = true
			}

			gnd := ""
			for _, idno := range p.Idno {
				if idno.Type == "GND" {
					gnd = idno.Content
				}
			}
			p.GND = gnd
			p.Found = false

			addname := ""
			for _, n := range p.PersName {
				for _, add := range n.AddName {
					if add.Type == "prefix" {
						addname = string(add.Text)
					}
				}
			}

			// Ensure Birth.Country and Death.Country are never null
			if p.Birth.Country == "" {
				p.Birth.Country = ""
			}
			if p.Death.Country == "" {
				p.Death.Country = ""
			}

			named := p.NamedPersName()
			if named.Surname != "" {
				p.Letter = normalizeLetter(named.Surname)
			} else if named.Forename != "" {
				p.Letter = normalizeLetter(named.Forename)
			} else {
				displayName := p.DisplayName()
				if displayName != "" {
					p.Letter = normalizeLetter(displayName)
				}
			}

			_, err := stmt.Exec(
				p.ID,
				named.Forename,
				named.Surname,
				p.DisplayName(),
				addname,
				p.Sex.Value,
				p.Birth.Date.When,
				p.Birth.PlaceName,
				p.Birth.Country,
				p.Death.Date.When,
				p.Death.PlaceName,
				p.Death.Country,
				p.isMDB,
				p.Letter,
				p.GND,
				p.Found,
			)
			if err != nil {
				return fmt.Errorf("error inserting data: %w", err)
			}

			for _, a := range p.Affiliation {
				_, err := stmt2.Exec(
					p.ID,
					a.Type,
					a.Role,
					a.Period,
					a.From,
					a.To,
					a.Content,
				)
				if err != nil {
					return fmt.Errorf("error inserting data: %w", err)
				}
			}

			for _, name := range p.PersName {
				// Skip display-only persName entries (no structured data)
				if name.Type == "display" {
					continue
				}
				reg := name.Reg
				if reg == "" {
					reg = p.DisplayName()
				}
				_, err := stmt3.Exec(
					p.ID,
					name.N,
					name.Forename,
					name.Surname,
					reg,
					strings.Join(func() []string {
						addNames := []string{}
						for _, an := range name.AddName {
							addNames = append(addNames, an.Type)
						}
						return addNames
					}(), ", "),
					"", // RoleName is empty for now
				)
				if err != nil {
					return fmt.Errorf("error inserting data: %w", err)
				}
			}
		}
	}

	fmt.Println("Data successfully dumped to persons.db")
	return nil
}

func main() {
	if err := loadAndDumpToSQLite(); err != nil {
		fmt.Printf("Error: %v\n", err)
	}
}
