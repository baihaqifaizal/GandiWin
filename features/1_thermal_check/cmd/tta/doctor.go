package main

import (
	"fmt"

	"thermal-throttling-analyzer/internal/advice"
	"thermal-throttling-analyzer/internal/events"
	"github.com/spf13/cobra"
)

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "What should I do?",
	Run: func(cmd *cobra.Command, args []string) {
		logger, err := events.NewLogger()
		if err != nil {
			fmt.Printf("Error accessing logs for analysis: %v\n", err)
			// Proceed without logs? Doctor relies on history.
			fmt.Println("No history available yet. Run 'tta watch' to gather data.")
			return
		}

		allEvents, err := logger.ReadEvents()
		if err != nil {
			fmt.Printf("Error reading logs: %v\n", err)
			return
		}

		report := advice.GenerateDoctorReport(allEvents)
		fmt.Println(report)
	},
}

func init() {
	rootCmd.AddCommand(doctorCmd)
}
