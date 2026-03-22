package events

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
)

// Logger handles writing events to the storage file.
type Logger struct {
	mu       sync.Mutex
	filePath string
}

// NewLogger creates a new logger instance.
// Ensure the storage directory exists.
func NewLogger() (*Logger, error) {
	cwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	// Assuming structure is maintained from root, or relative to executable
	// Strictly implementing "storage/events.jsonl" relative to CWD for this CLI tool usage.
	storageDir := filepath.Join(cwd, "storage")
	if err := os.MkdirAll(storageDir, 0755); err != nil {
		return nil, err
	}

	return &Logger{
		filePath: filepath.Join(storageDir, "events.jsonl"),
	}, nil
}

// LogEvent writes a single event to the file.
func (l *Logger) LogEvent(e Event) error {
	l.mu.Lock()
	defer l.mu.Unlock()

	f, err := os.OpenFile(l.filePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	data, err := json.Marshal(e)
	if err != nil {
		return err
	}

	if _, err := f.Write(append(data, '\n')); err != nil {
		return err
	}

	return nil
}

// ReadEvents reads all events from the log file.
// Used for analysis.
func (l *Logger) ReadEvents() ([]Event, error) {
	l.mu.Lock()
	defer l.mu.Unlock()

	// If file doesn't exist, return empty list
	if _, err := os.Stat(l.filePath); os.IsNotExist(err) {
		return []Event{}, nil
	}

	f, err := os.Open(l.filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var events []Event
	decoder := json.NewDecoder(f)
	for decoder.More() {
		var e Event
		if err := decoder.Decode(&e); err != nil {
			// Skip malformed lines or return error?
			// Diagnostic tool: best effort. Log error to stderr?
			// For now, continue
			continue
		}
		events = append(events, e)
	}

	return events, nil
}
