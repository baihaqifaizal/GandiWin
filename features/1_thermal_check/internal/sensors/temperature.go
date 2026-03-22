package sensors

import (
	"fmt"
	"strconv"
)

// GetCPUTemperature fetches the current CPU temperature in Celsius.
// It attempts to read from MSAcpi_ThermalZoneTemperature.
// Returns 0 and an error if unavailable.
func GetCPUTemperature() (float64, error) {
	// Command to get temperature in Kelvin * 10
	// MSAcpi_ThermalZoneTemperature is a common WMI class for ACPI thermal zones.
	// CurrentTemperature is in 0.1 Kelvin.
	cmd := "Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature | Select-Object -ExpandProperty CurrentTemperature | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum"

	output, err := execPowerShell(cmd)
	if err != nil {
		// Fallback or specific error handling can go here.
		// For now, return error to let caller decide (e.g., fallback to mock).
		return 0, err
	}

	if output == "" {
		return 0, fmt.Errorf("no temperature data returned")
	}

	// Parse output
	rawTemp, err := strconv.ParseFloat(output, 64)
	if err != nil {
		return 0, err
	}

	// Convert Decikelvin to Celsius: (K * 10 - 2732) / 10 = C
	// formula: (Raw - 2732) / 10.0
	celsius := (rawTemp - 2732) / 10.0

	return celsius, nil
}
