package admin

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"time"

	_ "modernc.org/sqlite"
)

// Store handles SQLite persistence for build history.
type Store struct {
	db *sql.DB
}

// NewStore opens (or creates) the SQLite database and runs migrations.
func NewStore(dbPath string) (*Store, error) {
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	// WAL mode for better concurrent read performance
	if _, err := db.Exec("PRAGMA journal_mode=WAL"); err != nil {
		db.Close()
		return nil, fmt.Errorf("set WAL mode: %w", err)
	}

	if err := migrate(db); err != nil {
		db.Close()
		return nil, fmt.Errorf("migrate: %w", err)
	}

	return &Store{db: db}, nil
}

func migrate(db *sql.DB) error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS builds (
			id               INTEGER PRIMARY KEY AUTOINCREMENT,
			status           TEXT NOT NULL DEFAULT 'running',
			targets          TEXT NOT NULL,
			env              TEXT NOT NULL DEFAULT 'live',
			triggered_by     TEXT NOT NULL DEFAULT 'admin',
			started_at       DATETIME NOT NULL DEFAULT (datetime('now')),
			finished_at      DATETIME,
			duration_seconds INTEGER,
			exit_code        INTEGER,
			log_output       TEXT,
			error_message    TEXT
		)
	`)
	return err
}

// CreateBuild inserts a new build record and returns it with the generated ID.
func (s *Store) CreateBuild(targets []string, env, triggeredBy string) (*BuildRecord, error) {
	targetsJSON, err := json.Marshal(targets)
	if err != nil {
		return nil, fmt.Errorf("marshal targets: %w", err)
	}

	now := time.Now().UTC()
	res, err := s.db.Exec(
		`INSERT INTO builds (status, targets, env, triggered_by, started_at) VALUES (?, ?, ?, ?, ?)`,
		"running", string(targetsJSON), env, triggeredBy, now,
	)
	if err != nil {
		return nil, fmt.Errorf("insert build: %w", err)
	}

	id, err := res.LastInsertId()
	if err != nil {
		return nil, fmt.Errorf("last insert id: %w", err)
	}

	return &BuildRecord{
		ID:          id,
		Status:      "running",
		Targets:     string(targetsJSON),
		Env:         env,
		TriggeredBy: triggeredBy,
		StartedAt:   now,
	}, nil
}

// FinishBuild updates a build record with the final status, log, and exit code.
func (s *Store) FinishBuild(id int64, status string, exitCode int, logOutput, errorMessage string) error {
	now := time.Now().UTC()
	_, err := s.db.Exec(
		`UPDATE builds SET status = ?, finished_at = ?, duration_seconds = (strftime('%s', ?) - strftime('%s', started_at)), exit_code = ?, log_output = ?, error_message = ? WHERE id = ?`,
		status, now, now, exitCode, logOutput, errorMessage, id,
	)
	return err
}

// GetBuild returns a single build by ID.
func (s *Store) GetBuild(id int64) (*BuildRecord, error) {
	row := s.db.QueryRow(`SELECT id, status, targets, env, triggered_by, started_at, finished_at, duration_seconds, exit_code, log_output, error_message FROM builds WHERE id = ?`, id)
	return scanBuild(row)
}

// ListBuilds returns build records ordered by most recent first.
func (s *Store) ListBuilds(limit, offset int) ([]BuildRecord, error) {
	rows, err := s.db.Query(
		`SELECT id, status, targets, env, triggered_by, started_at, finished_at, duration_seconds, exit_code, COALESCE(SUBSTR(log_output, 1, 500), '') as log_output, error_message FROM builds ORDER BY id DESC LIMIT ? OFFSET ?`,
		limit, offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var builds []BuildRecord
	for rows.Next() {
		b, err := scanBuildRows(rows)
		if err != nil {
			log.Printf("scan build row: %v", err)
			continue
		}
		builds = append(builds, *b)
	}
	return builds, rows.Err()
}

// Close closes the underlying database connection.
func (s *Store) Close() error {
	return s.db.Close()
}

type scanner interface {
	Scan(dest ...interface{}) error
}

func scanBuild(row *sql.Row) (*BuildRecord, error) {
	var b BuildRecord
	var finishedAt sql.NullTime
	var duration sql.NullInt64
	var exitCode sql.NullInt64
	var logOutput sql.NullString
	var errorMessage sql.NullString

	err := row.Scan(&b.ID, &b.Status, &b.Targets, &b.Env, &b.TriggeredBy, &b.StartedAt, &finishedAt, &duration, &exitCode, &logOutput, &errorMessage)
	if err != nil {
		return nil, err
	}

	if finishedAt.Valid {
		b.FinishedAt = &finishedAt.Time
	}
	if duration.Valid {
		d := int(duration.Int64)
		b.DurationSeconds = &d
	}
	if exitCode.Valid {
		c := int(exitCode.Int64)
		b.ExitCode = &c
	}
	if logOutput.Valid {
		b.LogOutput = logOutput.String
	}
	if errorMessage.Valid {
		b.ErrorMessage = errorMessage.String
	}

	return &b, nil
}

func scanBuildRows(rows *sql.Rows) (*BuildRecord, error) {
	var b BuildRecord
	var finishedAt sql.NullTime
	var duration sql.NullInt64
	var exitCode sql.NullInt64
	var logOutput sql.NullString
	var errorMessage sql.NullString

	err := rows.Scan(&b.ID, &b.Status, &b.Targets, &b.Env, &b.TriggeredBy, &b.StartedAt, &finishedAt, &duration, &exitCode, &logOutput, &errorMessage)
	if err != nil {
		return nil, err
	}

	if finishedAt.Valid {
		b.FinishedAt = &finishedAt.Time
	}
	if duration.Valid {
		d := int(duration.Int64)
		b.DurationSeconds = &d
	}
	if exitCode.Valid {
		c := int(exitCode.Int64)
		b.ExitCode = &c
	}
	if logOutput.Valid {
		b.LogOutput = logOutput.String
	}
	if errorMessage.Valid {
		b.ErrorMessage = errorMessage.String
	}

	return &b, nil
}
