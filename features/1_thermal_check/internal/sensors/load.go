package sensors

import (
	"fmt"
	"strconv"
)

// GetCPULoad fetches the current CPU load percentage (0-100).
func GetCPULoad() (float64, error) {
	// Win32_Processor LoadPercentage is an instant snapshot.
	// For better accuracy, we might want typeperf "\Processor(_Total)\% Processor Time"
	// But Win32_Processor is faster/easier for this scope.
	
	cmd := "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage | Measure-Object -Average | Select-Object -ExpandProperty Average"
	
	output, err := execPowerShell(cmd)
	if err != nil {
		return 0, err
	}
	
	load, err := strconv.ParseFloat(output, 64)
	if err != nil {
		return 0, fmt.Errorf("failed to parse load: %v", err)
	}
	
	return load, nil
}
