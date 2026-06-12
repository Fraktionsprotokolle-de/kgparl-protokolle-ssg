package admin

import "time"

// BuildRecord represents a single build execution stored in the database.
type BuildRecord struct {
	ID              int64      `json:"id"`
	Status          string     `json:"status"` // running, success, error
	Targets         string     `json:"targets"`
	Env             string     `json:"env"`
	TriggeredBy     string     `json:"triggered_by"`
	StartedAt       time.Time  `json:"started_at"`
	FinishedAt      *time.Time `json:"finished_at,omitempty"`
	DurationSeconds *int       `json:"duration_seconds,omitempty"`
	ExitCode        *int       `json:"exit_code,omitempty"`
	LogOutput       string     `json:"log_output,omitempty"`
	ErrorMessage    string     `json:"error_message,omitempty"`
}

// FileInfo represents a single file in the project directory.
type FileInfo struct {
	Path     string    `json:"path"`
	Size     int64     `json:"size"`
	Modified time.Time `json:"modified"`
	IsDir    bool      `json:"is_dir"`
}

// FileStats contains aggregated statistics about the scanned files.
type FileStats struct {
	TotalFiles   int            `json:"total_files"`
	TotalSize    int64          `json:"total_size"`
	OldestFile   *time.Time     `json:"oldest_file,omitempty"`
	NewestFile   *time.Time     `json:"newest_file,omitempty"`
	CountByType  map[string]int `json:"count_by_type"`
	LastScanTime *time.Time     `json:"last_scan_time,omitempty"`
}

// BuildRequest is the payload for triggering a new build.
type BuildRequest struct {
	Targets []string `json:"targets" binding:"required,min=1"`
	Env     string   `json:"env" binding:"required,oneof=live test"`
}

// BuildStatus reports whether a build is currently running.
type BuildStatus struct {
	State   string `json:"state"` // idle, running
	BuildID *int64 `json:"build_id,omitempty"`
	LogTail string `json:"log_tail,omitempty"`
}

// AdminConfig holds the configuration for the admin dashboard.
type AdminConfig struct {
	User        string
	Password    string
	ProjectRoot string
	DBPath      string
}
