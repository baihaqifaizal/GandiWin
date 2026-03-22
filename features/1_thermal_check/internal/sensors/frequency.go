package sensors

import (
	"fmt"
	"strconv"
)

// FrequencyData holds current and base frequency in MHz.
type FrequencyData struct {
	CurrentMHz int
	BaseMHz    int
}

// GetCPUFrequency fetches the current and max clock speed.
func GetCPUFrequency() (FrequencyData, error) {

	// We need to parse JSON output efficiently without deep structs if possible,
	// or just simple string manipulation if we want to avoid complex JSON parsing for a simple output.
	// However, PowerShell JSON output can be a list or single object.
	// Let's use a more direct specific query to avoid JSON parsing issues for multi-socket systems.
	// We'll take the average or first processor found.

	// Simplified approach: Get Max (Base) and Current separately to ensure stability.

	// Get Current
	cmdCurr := "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty CurrentClockSpeed | Measure-Object -Average | Select-Object -ExpandProperty Average"
	outCurr, err := execPowerShell(cmdCurr)
	if err != nil {
		return FrequencyData{}, err
	}

	// Get Base (Max)
	cmdBase := "Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty MaxClockSpeed | Measure-Object -Average | Select-Object -ExpandProperty Average"
	outBase, err := execPowerShell(cmdBase)
	if err != nil {
		return FrequencyData{}, err
	}

	currMHz, err := strconv.ParseFloat(outCurr, 64)
	if err != nil {
		return FrequencyData{}, fmt.Errorf("failed to parse current freq: %v", err)
	}

	baseMHz, err := strconv.ParseFloat(outBase, 64)
	if err != nil {
		return FrequencyData{}, fmt.Errorf("failed to parse base freq: %v", err)
	}

	return FrequencyData{
		CurrentMHz: int(currMHz),
		BaseMHz:    int(baseMHz),
	}, nil
}
