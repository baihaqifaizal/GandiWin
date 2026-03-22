package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

const (
	LightBlue = "\033[34m"
	Red       = "\033[31m"
	Reset     = "\033[0m"
)

var rootCmd = &cobra.Command{
	Use:   "tta",
	Short: "Thermal Throttling Analyzer",
	Long:  `A Windows-only CLI diagnostic tool in Go that detects, analyzes, and explains CPU thermal throttling.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(LightBlue + "\n  [ THERMAL THROTTLING ANALYZER - v1.2.0 ]" + Reset)
		fmt.Println("-------------------------------------------")
		cmd.Help()
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func matchRun() {
	Execute()
}
