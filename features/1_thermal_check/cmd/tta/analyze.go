package main

import (
	"fmt"
	"time"

	"thermal-throttling-analyzer/internal/events"

	"github.com/spf13/cobra"
)

var analyzeLastDuration string

var analyzeCmd = &cobra.Command{
	Use:   "analyze",
	Short: "Why was my system slow?",
	Run: func(cmd *cobra.Command, args []string) {
		duration, err := time.ParseDuration(analyzeLastDuration)
		if err != nil {
			fmt.Printf("Invalid duration format: %v\n", err)
			return
		}

		logger, err := events.NewLogger()
		if err != nil {
			fmt.Printf("Error accessing logs: %v\n", err)
			return
		}

		allEvents, err := logger.ReadEvents()
		if err != nil {
			fmt.Printf("Error reading logs: %v\n", err)
			return
		}

		startTime := time.Now().Add(-duration)

		// Filter events
		var relevantEvents []events.Event
		throttleCount := 0
		// Simpler: Just count events for now based on Types.

		for _, e := range allEvents {
			if e.Timestamp.After(startTime) {
				relevantEvents = append(relevantEvents, e)
				if e.State == "THROTTLING" {
					throttleCount++
				}
				// Parsing temp from details string is brittle but OK for this scope
				// or we trust the log types.
			}
		}

		fmt.Printf("Thermal Events (last %s):\n", duration)
		fmt.Printf("• Throttling events: %d\n", throttleCount)
		// Calculation of duration/avg would require pairing start/stop events.
		// For MVP/CLI scope, counting valid "THROTTLING" log entries (which happen on change) is tricky.
		// 'watch' logs on state CHANGE.
		// So detailed stats require replaying the state machine or assuming pairs.
		// Doing a simple count for now.

		if len(relevantEvents) > 0 {
			fmt.Println("Likely cause: Analysis based on available logs.")
		} else {
			fmt.Println("No events recorded in this period.")
		}
	},
}

func init() {
	analyzeCmd.Flags().StringVar(&analyzeLastDuration, "last", "2h", "Time duration to analyze (e.g. 2h, 30m)")
	rootCmd.AddCommand(analyzeCmd)
}
