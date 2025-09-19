# ==============================
#   Process Monitoring Script
#   Author: (Mubaraq Yusuf)
#   Date:   (8/03/2025)
# ==============================

Write-Host "=== Starting Process Monitoring Script ==="

# -----------------------------------------------------------
Write-Host "Configuring registry for script start time..."

$registryPath = "HKCU:\Software\PowershellScriptRunTime"
$registryKeyName = "RunTime"
$runTimeValue = (Get-Date).ToString("yyyy-MM-dd HH:mm")

# Ensure the registry path exists (creates if missing)
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath | Out-Null
}

# Create or update the 'RunTime' key with the current run time
New-ItemProperty -Path $registryPath -Name $registryKeyName -Value $runTimeValue -PropertyType String -Force | Out-Null
Write-Host "Registry updated with latest script start time:" $runTimeValue

# -----------------------------------------------------------
# Display all the running processes
# -----------------------------------------------------------
Write-Host "`n=== List of All Running Processes ==="
Get-Process | Format-Table -AutoSize

# -----------------------------------------------------------
# 2. Option menu for choosing how to search for the process
#    (ID, full name, partial name). Then prompt for input.
# -----------------------------------------------------------
Write-Host "`n=== Search for a Running Process ==="
Write-Host "How would you like to search?"
Write-Host "  1) By Process ID"
Write-Host "  2) By Exact Process Name"
Write-Host "  3) By Partial Process Name"
Write-Host ""

$searchChoice = Read-Host "Enter your choice (1,2,3)"

switch ($searchChoice) {
    '1' {
        Write-Host "Please enter the numeric Process ID:"
        $searchTerm = Read-Host

        # Validate numeric ID
        try {
            [int]$searchTerm | Out-Null
        } catch {
            Write-Host "Invalid numeric Process ID. Exiting."
            exit
        }

        Write-Host "`nRetrieving processes..."
        $foundProcesses = Get-Process | Where-Object { $_.Id -eq [int]$searchTerm }
    }
    '2' {
        Write-Host "Please enter the exact Process Name:"
        $searchTerm = Read-Host

        Write-Host "`nRetrieving processes..."
        $foundProcesses = Get-Process | Where-Object { $_.Name -eq $searchTerm }
    }
    '3' {
        Write-Host "Please enter partial name to match:"
        $searchTerm = Read-Host

        Write-Host "`nRetrieving processes..."
        $searchValue = $searchTerm.ToLower()
        $foundProcesses = Get-Process | Where-Object { $_.Name.ToLower() -like "*$searchValue*" }
    }
    default {
        Write-Host "Invalid selection. Exiting script."
        exit
    }
}

# If no processes found
if (-not $foundProcesses) {
    Write-Host "`nNo process found matching '$searchTerm'."
} else {
    Write-Host "`nFound the following process(es) matching '$searchTerm':"
    $foundProcesses | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Do you want to kill these process(es)? (Y/N):"
    $choice = Read-Host
    if ($choice -match '^[Yy]$') {
        foreach ($proc in $foundProcesses) {
            try {
                Write-Host "Attempting to kill process: $($proc.Name) (ID: $($proc.Id))"
                Stop-Process -Id $proc.Id -Force
                Write-Host "Process $($proc.Name) (ID: $($proc.Id)) has been terminated."
            } catch {
                Write-Host "Could not kill process $($proc.Name) (ID: $($proc.Id)): $($_.Exception.Message)"
            }
        }
    } else {
        Write-Host "Skipping process termination."
    }
}

Write-Host "`n=== Entering infinite loop to monitor processes ==="
Write-Host "Press Ctrl+C to stop this script at any time."

# -----------------------------------------------------------
# Function to handle housekeeping: keep only 5 CSV files
# -----------------------------------------------------------
function Cleanup-OldFiles {
    param (
        [string]$Path,
        [string]$Pattern,
        [int]$MaxFiles
    )
    $files = Get-ChildItem -Path $Path -Filter $Pattern -ErrorAction SilentlyContinue | 
             Sort-Object LastWriteTime -Descending
    if ($files.Count -gt $MaxFiles) {
        $filesToRemove = $files | Select-Object -Skip $MaxFiles
        foreach ($file in $filesToRemove) {
            Remove-Item $file.FullName -Force
            Write-Host "Housekeeping: Removed old file $($file.Name)"
        }
    }
}

# -----------------------------------------------------------
# 3. Infinite loop to monitor processes
#    - Write results to a CSV
#    - Keep no more than 5 CSVs in the directory
# -----------------------------------------------------------
while ($true) {
    try {
        Write-Host "`nGetting process list..."
        $timeStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $fileName = "ProcessList_$timeStamp.csv"

        $currentProcesses = Get-Process | 
            Select-Object Name, Id, @{Name='WS(KB)';Expression={[int]($_.WS / 1KB)}}  # Convert WS to KB

        # Write results to CSV
        $header = "Name,Id,WS(KB)"
        $header | Out-File $fileName
        foreach ($proc in $currentProcesses) {
            "$($proc.Name),$($proc.Id),$($proc.'WS(KB)')" | Out-File $fileName -Append
        }
        Write-Host "Process list has been written to $fileName"

        # Housekeeping: keep only 5 CSV files in the current directory
        Cleanup-OldFiles -Path "." -Pattern "ProcessList_*.csv" -MaxFiles 5

        Write-Host "Sleeping for 30 seconds..."
        Start-Sleep -Seconds 30
    } catch {
        Write-Host "Error occurred in monitoring loop: $($_.Exception.Message)"
        Start-Sleep -Seconds 30
    }
}

