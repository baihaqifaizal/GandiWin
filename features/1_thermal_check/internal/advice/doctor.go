package advice

import (
	"fmt"
	"thermal-throttling-analyzer/internal/events"
	"strings"
	"time"
)

// GenerateDoctorReport analyzes events and produces a conservative advice report.
func GenerateDoctorReport(eventsList []events.Event) string {
	var sb strings.Builder
	
	// 1. Analyze frequency of throttling
	throttleCount := 0
	recentThrottleCount := 0
	last24h := time.Now().Add(-24 * time.Hour)
	
	for _, e := range eventsList {
		if e.State == "THROTTLING" {
			throttleCount++
			if e.Timestamp.After(last24h) {
				recentThrottleCount++
			}
		}
	}
	
	sb.WriteString("System Health Report:\n")
	
	if throttleCount == 0 {
		sb.WriteString("• No throttling events detected in logs. System appears healthy.\n")
		return sb.String()
	}
	
	sb.WriteString(fmt.Sprintf("• %d throttling events detected (%d in last 24h).\n\n", throttleCount, recentThrottleCount))
	
	sb.WriteString("Suggestions (Risk Reduction):\n")
	
	// Conservative advice only
	sb.WriteString("• Ensure air vents are not obstructed.\n")
	sb.WriteString("• Avoid soft surfaces (blankets, laps) which block airflow.\n")
	
	if recentThrottleCount > 5 {
		sb.WriteString("• Consider using 'Balanced' power profile instead of 'High Performance'.\n")
		sb.WriteString("• High ambient temperatures may be contributing.\n")
	}
	
	return sb.String()
}
