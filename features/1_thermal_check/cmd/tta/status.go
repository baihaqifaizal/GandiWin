package main

import (
	"fmt"
	"os"
	"thermal-throttling-analyzer/internal/analyzer"
	"thermal-throttling-analyzer/internal/sensors"
	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "What's happening right now?",
	Run: func(cmd *cobra.Command, args []string) {
		snapshot := sensors.CollectSnapshot()
		sm := analyzer.NewStateMachine()
		result := sm.Update(snapshot)

		fmt.Printf("Thermal State: %s\n", result.State)
		fmt.Printf("Reason: %s\n", result.Reason)
		fmt.Printf("Confidence: %s\n", result.Confidence)
		
		if len(snapshot.ValidSignals) == 0 {
			fmt.Println("\nWarning: No sensors could be read. Ensure you are running as Administrator or on a supported Windows device.")
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
