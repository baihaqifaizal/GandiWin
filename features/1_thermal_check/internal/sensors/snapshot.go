package sensors

import "time"

// Snapshot represents a point-in-time capture of system thermal state.
// All sensors feed into this struct.
type Snapshot struct {
	TempC        float64
	FreqMHz      int
	BaseFreqMHz  int
	LoadPercent  float64
	Timestamp    time.Time
	ValidSignals []string // List of signals that were successfully collected
}
