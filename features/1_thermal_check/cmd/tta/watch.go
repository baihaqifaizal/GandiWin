package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	"thermal-throttling-analyzer/internal/analyzer"
	"thermal-throttling-analyzer/internal/events"
	"thermal-throttling-analyzer/internal/sensors"

	"github.com/spf13/cobra"
)

var watchCmd = &cobra.Command{
	Use:   "watch",
	Short: "Tell me when things go bad",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Monitoring thermal state... (Press Ctrl+C to stop)")

		demoMode, _ := cmd.Flags().GetBool("demo")
		if demoMode {
			fmt.Println("DEMO MODE ACTIVE: Simulating thermal throttling")
		}

		sm := analyzer.NewStateMachine()
		logger, err := events.NewLogger()
		if err != nil {
			fmt.Printf("Error initializing logger: %v\n", err)
			return
		}

		// Channel for clean exit
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

		ticker := time.NewTicker(analyzer.SampleInterval) // 2s
		defer ticker.Stop()

		var lastState analyzer.State
		demoCounter := 0

		// External process for animation
		var fireCmd *exec.Cmd

		for {
			select {
			case <-sigChan:
				fmt.Println("\nStopping monitor.")
				if fireCmd != nil && fireCmd.Process != nil {
					_ = fireCmd.Process.Kill()
				}
				return
			case <-ticker.C:
				snap := sensors.CollectSnapshot()
				res := sm.UpdateWithHistory(snap)

				if demoMode {
					demoCounter++
					// Toggle state every 10 seconds (5 samples)
					cycle := (demoCounter / 5) % 2
					if cycle == 1 {
						res.State = analyzer.StateThrottling
						res.Reason = "Simulated Demo Throttling"
						snap.TempC = 98.5
					} else {
						res.State = analyzer.StateNormal
						res.Reason = "Simulated Normal"
						snap.TempC = 45.0
					}
				}

				if res.State == analyzer.StateThrottling {
					if fireCmd == nil {
						// Start fire animation
						// Assume gh-yule-log is in PATH or GOPATH/bin
						// We'll try to run it directly
						fireCmd = exec.Command("gh-yule-log")
						fireCmd.Stdout = os.Stdout
						fireCmd.Stdin = os.Stdin
						fireCmd.Stderr = os.Stderr

						if err := fireCmd.Start(); err != nil {
							fmt.Printf("\nError starting fire animation: %v\n", err)
							fireCmd = nil
						}
					}
				} else {
					if fireCmd != nil {
						if fireCmd.Process != nil {
							_ = fireCmd.Process.Signal(os.Interrupt)
							// Allow brief time to cleanup, otherwise kill
							go func(p *os.Process) {
								time.Sleep(200 * time.Millisecond)
								_ = p.Kill()
							}(fireCmd.Process)
						}
						_ = fireCmd.Wait()
						fireCmd = nil
						// Clear screen/reset cursor
						fmt.Print("\033[2J\033[H")
						// Reprint monitoring status as clearing screen wipes it
						fmt.Println("Monitoring thermal state... (Press Ctrl+C to stop)")
					}
				}

				// Print only on state change or significant event
				if res.State != lastState {
					timestamp := time.Now().Format("15:04")
					// If fire is running, this might get messy, but standard output is shared
					if fireCmd == nil {
						fmt.Printf("[%s] %s detected (temp %.0f°C)\n", timestamp, res.State, snap.TempC)
					}

					// Log event
					_ = logger.LogEvent(events.Event{
						Timestamp: time.Now(),
						Type:      string(res.State),
						State:     string(res.State),
						Details:   res.Reason,
					})

					lastState = res.State
				}
			}
		}
	},
}

func init() {
	watchCmd.Flags().Bool("demo", false, "Simulate thermal throttling state")
	rootCmd.AddCommand(watchCmd)
}
