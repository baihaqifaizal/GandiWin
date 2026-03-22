package events

import "time"

// Event represents a significant thermal event.
// This struct maps to the JSONL log format.
type Event struct {
	Timestamp time.Time `json:"timestamp"`
	Type      string    `json:"type"`              // e.g., TEMP_RISE, THROTTLING, RECOVERY
	State     string    `json:"state,omitempty"`   // e.g., NORMAL, HEAT_STRESS, THROTTLING
	Details   string    `json:"details,omitempty"` // Human-readable details
}
