package admin

import (
	"path/filepath"
	"io/fs"
	"sort"
	"strings"
	"sync"
	"time"
)

// FileScanner scans the project's html/ directory and caches results.
type FileScanner struct {
	htmlDir  string
	cacheTTL time.Duration

	mu        sync.RWMutex
	files     []FileInfo
	stats     FileStats
	lastScan  time.Time
}

// NewFileScanner creates a scanner for the given html directory.
func NewFileScanner(projectRoot string) *FileScanner {
	return &FileScanner{
		htmlDir:  filepath.Join(projectRoot, "html"),
		cacheTTL: 5 * time.Minute,
	}
}

// GetStats returns aggregated file statistics, scanning if cache is stale.
func (s *FileScanner) GetStats() (FileStats, error) {
	if err := s.ensureFresh(); err != nil {
		return FileStats{}, err
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.stats, nil
}

// GetFiles returns a paginated, sorted, filtered list of files.
func (s *FileScanner) GetFiles(sortField, order, filter string, page, perPage int) ([]FileInfo, int, error) {
	if err := s.ensureFresh(); err != nil {
		return nil, 0, err
	}
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Filter
	filtered := s.files
	if filter != "" {
		filtered = make([]FileInfo, 0, len(s.files))
		for _, f := range s.files {
			matched, _ := filepath.Match(filter, filepath.Base(f.Path))
			if matched {
				filtered = append(filtered, f)
			}
		}
	}

	// Sort
	sort.Slice(filtered, func(i, j int) bool {
		switch sortField {
		case "size":
			if order == "desc" {
				return filtered[i].Size > filtered[j].Size
			}
			return filtered[i].Size < filtered[j].Size
		case "path", "name":
			if order == "desc" {
				return filtered[i].Path > filtered[j].Path
			}
			return filtered[i].Path < filtered[j].Path
		default: // modified
			if order == "asc" {
				return filtered[i].Modified.Before(filtered[j].Modified)
			}
			return filtered[i].Modified.After(filtered[j].Modified)
		}
	})

	// Paginate
	total := len(filtered)
	start := (page - 1) * perPage
	if start >= total {
		return []FileInfo{}, total, nil
	}
	end := start + perPage
	if end > total {
		end = total
	}

	return filtered[start:end], total, nil
}

func (s *FileScanner) ensureFresh() error {
	s.mu.RLock()
	fresh := !s.lastScan.IsZero() && time.Since(s.lastScan) < s.cacheTTL
	s.mu.RUnlock()
	if fresh {
		return nil
	}
	return s.scan()
}

func (s *FileScanner) scan() error {
	var files []FileInfo
	var totalSize int64
	var oldest, newest time.Time
	countByType := make(map[string]int)

	err := filepath.WalkDir(s.htmlDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil // skip inaccessible entries
		}
		if d.IsDir() {
			return nil
		}

		info, err := d.Info()
		if err != nil {
			return nil
		}

		// Store path relative to htmlDir
		relPath, _ := filepath.Rel(s.htmlDir, path)

		files = append(files, FileInfo{
			Path:     relPath,
			Size:     info.Size(),
			Modified: info.ModTime(),
		})

		totalSize += info.Size()

		ext := strings.ToLower(filepath.Ext(relPath))
		if ext == "" {
			ext = "(no ext)"
		}
		countByType[ext]++

		if oldest.IsZero() || info.ModTime().Before(oldest) {
			oldest = info.ModTime()
		}
		if newest.IsZero() || info.ModTime().After(newest) {
			newest = info.ModTime()
		}

		return nil
	})
	if err != nil {
		return err
	}

	now := time.Now()
	stats := FileStats{
		TotalFiles:   len(files),
		TotalSize:    totalSize,
		CountByType:  countByType,
		LastScanTime: &now,
	}
	if !oldest.IsZero() {
		stats.OldestFile = &oldest
	}
	if !newest.IsZero() {
		stats.NewestFile = &newest
	}

	s.mu.Lock()
	s.files = files
	s.stats = stats
	s.lastScan = now
	s.mu.Unlock()

	return nil
}
