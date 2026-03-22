package sensors

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// execPowerShell executes a PowerShell command and returns the output as a string.
// It enforces a timeout to prevent hanging.
func execPowerShell(command string) (string, error) {
	// 5 second timeout for any sensor read
	ctxTimeout := 5 * time.Second

	// Create command with timeout context would be ideal, but for simplicity/compatibility:
	// using time.AfterFunc or just simple exec for now to keep it dependency-free and simple.

	cmd := exec.Command("powershell", "-NoProfile", "-NonInteractive", "-Command", command)

	var out bytes.Buffer
	cmd.Stdout = &out

	// Simple timeout mechanism
	done := make(chan error, 1)
	go func() {
		done <- cmd.Run()
	}()

	select {
	case <-time.After(ctxTimeout):
		if cmd.Process != nil {
			cmd.Process.Kill()
		}
		return "", fmt.Errorf("timeout executing powershell command")
	case err := <-done:
		if err != nil {
			return "", err
		}
	}

	return strings.TrimSpace(out.String()), nil
}
