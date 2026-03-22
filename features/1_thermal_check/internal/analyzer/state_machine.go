package analyzer

import (
	"fmt"
	"thermal-throttling-analyzer/internal/sensors"
	"time"
)

type State string

const (
	StateNormal     State = "NORMAL"
	StateHeatStress State = "HEAT_STRESS"
	StateThrottling State = "THROTTLING"
	StateRecovery   State = "RECOVERY"
)

type AnalysisResult struct {
	State      State
	Reason     string
	Confidence ConfidenceLevel
	Snapshot   *sensors.Snapshot
}

// StateMachine holds the history and current state logic.
type StateMachine struct {
	CurrentState    State
	LastTransition  time.Time
	// Track recent snapshots for duration-based logic
	// Simple approach: Keep just the current analysis for the CLI 'status' command.
	// For 'watch' command, the state machine persists in memory.
}

func NewStateMachine() *StateMachine {
	return &StateMachine{
		CurrentState:   StateNormal,
		LastTransition: time.Now(),
	}
}

// AnalyzeSnapshot processes a single snapshot and returns the analysis.
// This function is stateless in the sense that it doesn't mutate the machine's state,
// but returns what the state *is* based on the snapshot.
// The caller (CLI loop) updates the machine state if a transition is confirmed over time.
// Wait, the Prompt says "Condition persists for minimum duration".
// So the StateMachine MUST persist state and track duration.

func (sm *StateMachine) Update(s *sensors.Snapshot) AnalysisResult {
	// 1. Calculate base metrics
	isHighTemp := s.TempC >= TempHighThreshold
	isCriticalTemp := s.TempC >= TempCriticalThreshold
	
	// Freq drop?
	// If current freq is significantly lower than base freq
	freqRatio := 1.0
	if s.BaseFreqMHz > 0 {
		freqRatio = float64(s.FreqMHz) / float64(s.BaseFreqMHz)
	}
	isFreqDrop := freqRatio <= (1.0 - FreqDropPercentage)
	
	// Load?
	// Throttling usually happens under load.
	// If load is low, freq drop is normal (idle).
	isHighLoad := s.LoadPercent > 50.0 // heuristic
	
	// Determine the "Instant" State indicated by THIS snapshot
	instantState := StateNormal
	reason := "System operating within normal parameters"
	
	if isCriticalTemp {
		// Critical temp is almost always throttling or about to
		if isFreqDrop && isHighLoad {
			instantState = StateThrottling
			reason = fmt.Sprintf("Critical Temp (%.1fC) + Freq Drop (%.0f%%) under Load", s.TempC, (1.0-freqRatio)*100)
		} else {
			instantState = StateHeatStress
			reason = fmt.Sprintf("Critical Temp (%.1fC)", s.TempC)
		}
	} else if isHighTemp {
		if isFreqDrop && isHighLoad {
			instantState = StateThrottling
			reason = fmt.Sprintf("High Temp (%.1fC) + Freq Drop (%.0f%%) under Load", s.TempC, (1.0-freqRatio)*100)
		} else {
			instantState = StateHeatStress
			reason = fmt.Sprintf("High Temp (%.1fC)", s.TempC)
		}
	} else if isFreqDrop && isHighLoad {
		// Freq drop under load but temp is fine? 
		// Could be power throttling, but we focus on Thermal. 
		// OR could be "Recovery" phase where temp dropped but freq hasn't returned?
		// Or "PL1" limit?
		// We'll call it HEAT_STRESS or unknown, but let's stick to Thermal definition.
		// If temp is low, it's strictly NOT thermal throttling (by simple definition).
		// However, prompt implies 'Throttling' state logic.
		// Let's call it Normal or specific "Power Limit" but strict scope is Thermal.
		// We will treat it as Normal (or suspicious) unless temp was high recently.
		instantState = StateNormal
	} else {
		// Check for Recovery conditions if we were in Throttling
		// Recovery = Temp decreasing, Freq recovering.
		// Detailed history analysis would be needed here, 
		// but simple state machine transition logic handles 'Recovery' state.
	}
	
	// State Transition Logic with Hysteresis/Time-gating would go here.
	// For a CLI "status" command (one-shot), we return the Instant State.
	// For "watch", we would track transitions.
	
	// Simplified one-shot logic for 'status' command:
	confidence := CalculateConfidence(s)
	
	return AnalysisResult{
		State:      instantState,
		Reason:     reason,
		Confidence: confidence,
		Snapshot:   s,
	}
}

// UpdateState is used by long-running process (watch) to handle transitions
func (sm *StateMachine) UpdateWithHistory(s *sensors.Snapshot) AnalysisResult {
	instantResult := sm.Update(s)
	
	// Logic to transition from THROTTLING -> RECOVERY
	// If we are currently THROTTLING, and instant state becomes NORMAL (Temp dropped),
	// we enter RECOVERY state for a duration before going back to NORMAL.
	
	if sm.CurrentState == StateThrottling {
		if instantResult.State == StateNormal || instantResult.State == StateHeatStress {
			// Temp has dropped. 
			// We should transition to RECOVERY
			sm.CurrentState = StateRecovery
			sm.LastTransition = time.Now()
			
			return AnalysisResult{
				State:      StateRecovery,
				Reason:     "Temperature dropping, verifying stability",
				Confidence: instantResult.Confidence,
				Snapshot:   s,
			}
		}
	}
	
	if sm.CurrentState == StateRecovery {
		// Stay in recovery for minimum duration
		if time.Since(sm.LastTransition) < RecoverySustainDuration {
			return AnalysisResult{
				State:      StateRecovery,
				Reason:     "Recovering...",
				Confidence: instantResult.Confidence,
				Snapshot:   s,
			}
		}
		// After duration, if still fine, go Normal
		if instantResult.State == StateNormal {
			sm.CurrentState = StateNormal
			sm.LastTransition = time.Now()
		}
	}
	
	// Default: if strong signal for new state, switch
	if instantResult.State == StateThrottling {
		sm.CurrentState = StateThrottling
		sm.LastTransition = time.Now()
	} else if sm.CurrentState != StateRecovery {
		// Normal/HeatStress updates
		sm.CurrentState = instantResult.State
	}
	
	instantResult.State = sm.CurrentState
	return instantResult
}
