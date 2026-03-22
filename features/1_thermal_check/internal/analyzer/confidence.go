package analyzer

import "thermal-throttling-analyzer/internal/sensors"

type ConfidenceLevel string

const (
	ConfidenceLow    ConfidenceLevel = "Low"
	ConfidenceMedium ConfidenceLevel = "Medium"
	ConfidenceHigh   ConfidenceLevel = "High"
)

// CalculateConfidence determines the confidence of the analysis based on snapshot quality.
func CalculateConfidence(s *sensors.Snapshot) ConfidenceLevel {
	// 1. Count valid signals
	validCount := len(s.ValidSignals)
	
	// 2. Logic
	if validCount >= 3 {
		// All sensors (Temp, Freq, Load) available
		return ConfidenceHigh
	}
	if validCount == 2 {
		return ConfidenceMedium
	}
	
	return ConfidenceLow
}
