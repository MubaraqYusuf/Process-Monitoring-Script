# 🖥️ Process Monitoring Script

A PowerShell script for monitoring, searching, and managing running processes on Windows.  
It also logs process lists into CSV files at regular intervals and performs housekeeping to retain only the most recent files.

---

## 📌 Features

- **Registry Logging**  
  Stores the script start time in the registry (`HKCU:\Software\PowershellScriptRunTime`).

- **Process Display**  
  Shows all currently running processes in a table view.

- **Search Options**  
  Search running processes by:
  - Process ID  
  - Exact Process Name  
  - Partial Process Name  

- **Process Management**  
  Optionally terminate (kill) one or more processes found.

- **Continuous Monitoring**  
  Runs in an infinite loop, capturing process details every 30 seconds.

- **CSV Logging**  
  Saves process details (Name, ID, and Working Set in KB) to timestamped `.csv` files.

- **Automatic Housekeeping**  
  Keeps only the latest **5 process list CSV files**, removing older ones.

---

## ⚙️ Requirements

- Windows OS  
- PowerShell 5.1 or later (recommended)  
- User permission to write files in the current directory  
- Optional: Administrator rights (if terminating system-critical processes)  

---

## 🚀 Usage

1. **Save Script**  
   Save the script as `ProcessMonitor.ps1`.

2. **Run Script**  
   Open PowerShell and execute:

   ```powershell
   .\ProcessMonitor.ps1

