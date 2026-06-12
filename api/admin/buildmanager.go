package admin

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
)

// allowedTargets is the whitelist of valid make targets.
var allowedTargets = map[string]bool{
	"config":   true,
	"css":      true,
	"fetch":    true,
	"indices":  true,
	"makeHTML": true,
	"makePDF":  true,
	"build":    true,
	"upload":   true,
	"all":      true,
}

// BuildManager executes builds one at a time with mutex protection.
type BuildManager struct {
	projectRoot string
	store       *Store

	mu         sync.Mutex
	running    bool
	currentID  int64
	logBuffer  *bytes.Buffer
}

// NewBuildManager creates a new build manager.
func NewBuildManager(projectRoot string, store *Store) *BuildManager {
	return &BuildManager{
		projectRoot: projectRoot,
		store:       store,
	}
}

// ValidateTargets checks that all targets are in the allowlist.
func ValidateTargets(targets []string) error {
	for _, t := range targets {
		if !allowedTargets[t] {
			return fmt.Errorf("invalid target: %q", t)
		}
	}
	return nil
}

// Status returns the current build state.
func (bm *BuildManager) Status() BuildStatus {
	bm.mu.Lock()
	defer bm.mu.Unlock()

	if !bm.running {
		return BuildStatus{State: "idle"}
	}

	status := BuildStatus{
		State:   "running",
		BuildID: &bm.currentID,
	}

	if bm.logBuffer != nil {
		logBytes := bm.logBuffer.Bytes()
		// Return last 2000 bytes as tail
		if len(logBytes) > 2000 {
			logBytes = logBytes[len(logBytes)-2000:]
		}
		status.LogTail = string(logBytes)
	}

	return status
}

// StartBuild launches a build in the background. Returns 409-style error if already running.
func (bm *BuildManager) StartBuild(targets []string, env, triggeredBy string) (*BuildRecord, error) {
	if err := ValidateTargets(targets); err != nil {
		return nil, fmt.Errorf("validation: %w", err)
	}

	bm.mu.Lock()
	if bm.running {
		bm.mu.Unlock()
		return nil, fmt.Errorf("build already running")
	}
	bm.running = true
	bm.logBuffer = &bytes.Buffer{}
	bm.mu.Unlock()

	record, err := bm.store.CreateBuild(targets, env, triggeredBy)
	if err != nil {
		bm.mu.Lock()
		bm.running = false
		bm.mu.Unlock()
		return nil, fmt.Errorf("create build record: %w", err)
	}

	bm.mu.Lock()
	bm.currentID = record.ID
	bm.mu.Unlock()

	go bm.executeBuild(record.ID, targets, env)

	return record, nil
}

func (bm *BuildManager) executeBuild(buildID int64, targets []string, env string) {
	defer func() {
		bm.mu.Lock()
		bm.running = false
		bm.currentID = 0
		bm.mu.Unlock()
	}()

	args := append([]string{"-j4", "-C", bm.projectRoot}, targets...)
	cmd := exec.Command("make", args...)

	// Prepend venv bin/ to PATH so all python3 calls use the venv
	venvBin := filepath.Join(bm.projectRoot, "bin")
	currentPath := os.Getenv("PATH")
	cmd.Env = append(cmd.Environ(),
		fmt.Sprintf("ENV=%s", env),
		fmt.Sprintf("PATH=%s:%s", venvBin, currentPath),
		fmt.Sprintf("VIRTUAL_ENV=%s", bm.projectRoot),
	)

	bm.mu.Lock()
	logBuf := bm.logBuffer
	bm.mu.Unlock()

	// Capture stdout and stderr into the shared buffer
	cmd.Stdout = io.MultiWriter(logBuf)
	cmd.Stderr = io.MultiWriter(logBuf)

	log.Printf("[admin] Build #%d started: make %s (env=%s)", buildID, strings.Join(targets, " "), env)

	err := cmd.Run()

	exitCode := 0
	status := "success"
	errorMsg := ""

	if err != nil {
		status = "error"
		errorMsg = err.Error()
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = -1
		}
	}

	logOutput := logBuf.String()

	if dbErr := bm.store.FinishBuild(buildID, status, exitCode, logOutput, errorMsg); dbErr != nil {
		log.Printf("[admin] Failed to update build #%d: %v", buildID, dbErr)
	}

	log.Printf("[admin] Build #%d finished: status=%s exit_code=%d", buildID, status, exitCode)
}
