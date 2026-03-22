package analyzer

import "time"

// Thresholds for thermal analysis.
// All magic numbers must live here.

const (
	// Temperature Thresholds (Celsius)
	TempHighThreshold     = 90.0
	TempCriticalThreshold = 95.0
	TempRecoveryThreshold = 85.0

	// Frequency Thresholds
	FreqDropPercentage = 0.20 // 20% drop from base frequency suggests throttling

	// Duration Thresholds
	ThrottlingSustainDuration = 10 * time.Second
	RecoverySustainDuration   = 30 * time.Second

	// Sampling
	SampleInterval = 2 * time.Second
)
