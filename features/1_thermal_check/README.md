<h1 align="center"> Thermal Throttling Analyzer </h1>

<p align="center">
  <img src="assets/banner.svg" alt="Project Banner" />
</p>


<p align="center">
  <img src="https://img.shields.io/badge/CLI-Cobra-green" />
  <img src="https://img.shields.io/badge/platform-Windows-blue" />
  <img src="https://img.shields.io/badge/license-MIT-green" />
  <img src="https://img.shields.io/badge/go-1.21-blue?logo=go" />
</p>

<p align="center">
<b>Thermal Throttling Analyzer (TTA)</b> is a powerful, lightweight, and Windows-only CLI diagnostic tool built in Go. It empowers developers, gamers, and power users to detect, analyze, and explain CPU thermal throttling events in real-time.
</p>

---

![Dashboard Preview](assets/preview.png)

![Demo Animation](https://raw.githubusercontent.com/Akarshjha03/ThermalThrottlingAnalyzer/main/assets/Throttle.gif)


---

## 🚀 Project Idea & Use Cases

Modern CPUs invoke thermal throttling to protect themselves from overheating, but this often results in unexplained performance drops (FPS lag, compile time slowdowns). **TTA** bridges the gap between raw sensor data and actionable insights.

### Common Use Cases:
- **Gamers**: Diagnose why your frame rate suddenly drops after 30 minutes of gameplay.
- **Developers**: Understand if thermal limits are affecting your compile times or render jobs.
- **Overclockers**: Verify system stability and cooling efficiency under load.
- **SysAdmins**: Quick health checks on Windows servers without heavy GUI tools.

---

## ✨ Key Features

- **🔥 Real-time Monitoring**: Watch CPU state, temperature, and frequency live.
- **📊 Historical Analysis**: Analyze past logs to correlate slowdowns with thermal events.
- **🏥 Doctor Mode**: One-command system health check.
- **📉 Throttling Detection**: Smart state machine detects when and why throttling occurs.
- **🎈 Lightweight**: Zero dependencies, single binary executable.

---

## 📦 Installation

### Option 1: Download Binary (Recommended)
Download the latest pre-built `.exe` from the [Releases Page](https://github.com/Akarshjha03/ThermalThrottlingAnalyzer/releases).

1.  Download `tta.exe`.
2.  Open your terminal in the download folder.
3.  Run `.\tta.exe`.

### Option 2: Build from Source
Requirements: Go 1.21+

```bash
git clone https://github.com/Akarshjha03/ThermalThrottlingAnalyzer.git
cd ThermalThrottlingAnalyzer
go mod tidy
go build -o tta.exe ./cmd/tta
```

### Option 3: Go Install
```bash
go install github.com/Akarshjha03/ThermalThrottlingAnalyzer/cmd/tta@latest
```

---

## 🛠️ Commands

### 1. View Available Commands
Run the root command to see the ASCII banner and list of all supported commands.
```bash
tta
```
*Output: Displays a custom ASCII banner followed by the help menu.*

### 2. Check System Status
Quickly verify if your system is currently throttling or healthy.
```bash
tta status
```
*Output: "Thermal State: NORMAL" or "Thermal State: THROTTLING"*

### 3. Live Monitoring
Watch your CPU metrics update in real-time with a fire animation when throttling occurs.
```bash
tta watch
```

### 4. Analyze History
Investigate what happened in the last few hours.
```bash
tta analyze --last 2h
```

### 5. Health Check (Doctor)
Run a comprehensive diagnostic of your thermal sensors and configuration.
```bash
tta doctor
```

### 6. View Logs
Dump raw event logs for external processing.
```bash
tta log --today
```

### 7. Other Commands
*   `tta completion`: Generate the autocompletion script for the specified shell.
*   `tta help`: Help about any command.

## 🤝 Contributions

Contributions are always welcome! We'd love to have your help to make TTA better.

1.  **Fork** the repository.
2.  **Create** a feature branch (`git checkout -b feature/NewSensor`).
3.  **Commit** your changes (`git commit -m 'Add new sensor support'`).
4.  **Push** to the branch (`git push origin feature/NewSensor`).
5.  **Open** a Pull Request.

Please ensure you run `go fmt ./...` before submitting!

---

## 🙏 Acknowledgments

-   **ANSI Fire Animation**: Inspired by and adapted from [gh-yule-log](https://github.com/leereilly/gh-yule-log) by Lee Reilly.
