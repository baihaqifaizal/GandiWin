package main

import (
	"fmt"
	"time"

	"thermal-throttling-analyzer/internal/events"
	"github.com/spf13/cobra"
)

var logOnlyToday bool

var logCmd = &cobra.Command{
	Use:   "log",
	Short: "Show me raw truth",
	Run: func(cmd *cobra.Command, args []string) {
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

		now := time.Now()
		for _, e := range allEvents {
			if logOnlyToday {
				// Check if same day
				if e.Timestamp.Year() != now.Year() || e.Timestamp.YearDay() != now.YearDay() {
					continue
				}
			}
			
			// Format: 14:31 TEMP_RISE 89°C
			// Simplified format as per req
			timeStr := e.Timestamp.Format("15:04")
			fmt.Printf("%s %s %s\n", timeStr, e.Type, e.Details)
		}
	},
}

func init() {
	logCmd.Flags().BoolVar(&logOnlyToday, "today", false, "Show only today's events")
	rootCmd.AddCommand(logCmd)
}
