# Thermal Throttling Analyzer (TTA) - Command Reference

This file contains a list of all available commands for the `tta` CLI tool, including their descriptions and usage.

## Global Usage

### Option 1: Run from Source (Dev/No Install)
Use the full `go run` command from the project root:
`go run ./cmd/tta [command] [flags]`

### Option 2: Run Installed Binary
If you have built and installed the binary (see `walkthrough.md` or README):
`tta [command] [flags]`

> **Note:** The examples below use `tta` for brevity, but you can replace it with `go run ./cmd/tta` if running from source.

## Commands

### 1. `watch`
**Description:** Monitors the system's thermal state in real-time. It detects throttling events and logs them.
**Usage:** `tta watch [flags]` or `go run ./cmd/tta watch [flags]`
**Flags:**
- `--demo`: Simulate thermal throttling state (useful for testing animations and logic without actual throttling).

**Example:**
```bash
# Installed
tta watch
tta watch --demo

# From Source
go run ./cmd/tta watch
go run ./cmd/tta watch --demo
```

### 2. `status`
**Description:** Displays a snapshot of the current thermal state. It tells you if you are currently throttling, the reason, and the confidence level of the diagnosis.
**Usage:** `tta status`

**Example:**
```bash
# Installed
tta status

# From Source
go run ./cmd/tta status
```

### 3. `analyze`
**Description:** Analyzes past thermal events to explain why the system might have been slow.
**Usage:** `tta analyze [flags]`
**Flags:**
- `--last [duration]`: Specify the time duration to analyze (default "2h"). Examples: "30m", "1h30m", "24h".

**Example:**
```bash
# Installed
tta analyze --last 4h

# From Source
go run ./cmd/tta analyze --last 4h
```

### 4. `doctor`
**Description:** Generates a report with advice based on historical thermal data. It suggests actions to improve thermal performance.
**Usage:** `tta doctor`

**Example:**
```bash
# Installed
tta doctor

# From Source
go run ./cmd/tta doctor
```

### 5. `log`
**Description:** Displays the raw log of thermal events.
**Usage:** `tta log [flags]`
**Flags:**
- `--today`: Show only today's events.

**Example:**
```bash
# Installed
tta log
tta log --today

# From Source
go run ./cmd/tta log
```

### 6. `help`
**Description:** Help about any command.
**Usage:** `tta help [command]`
