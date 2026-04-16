# =============================================================================
# Morning Briefing — Windows Task Scheduler Wrapper
# Schedule: 7:10 AM ET, Monday–Friday
# =============================================================================
#
# SETUP (one-time):
#   1. Open Task Scheduler (taskschd.msc)
#   2. Create Basic Task > Name: "PACO Morning Briefing"
#   3. Trigger: Daily at 7:10 AM
#      - Advanced: repeat Monday through Friday only
#   4. Action: Start a Program
#      - Program: powershell.exe
#      - Arguments: -ExecutionPolicy Bypass -File "C:\Users\user8\iCloudDrive\Documents\Work AI Hub\ai-experiments\routines\morning-briefing\schedule-briefing.ps1"
#   5. Conditions: Start only if logged on (or check "Run whether user is logged on or not")
#
# =============================================================================

# --- Configuration ---
$RepoDir    = "C:\Users\user8\iCloudDrive\Documents\Work AI Hub\ai-experiments"
$RoutineFile = "$RepoDir\routines\morning-briefing\morning-briefing.md"
$LogDir     = "$RepoDir\routines\morning-briefing\logs"
$Timestamp  = Get-Date -Format "yyyy-MM-dd-HHmmss"
$LogFile    = "$LogDir\briefing-$Timestamp.log"

# --- Ensure log directory exists ---
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# --- Check if routine file exists ---
if (-not (Test-Path $RoutineFile)) {
    $msg = "ERROR: Routine file not found at $RoutineFile"
    $msg | Out-File -FilePath $LogFile -Encoding utf8
    Write-Error $msg
    exit 1
}

# --- Read routine prompt ---
$RoutinePrompt = Get-Content $RoutineFile -Raw

# --- Run Claude Code with the routine ---
Write-Host "Starting Morning Briefing at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Log: $LogFile"

try {
    $RoutinePrompt | claude -p `
        --add-dir $RepoDir `
        2>&1 | Tee-Object -FilePath $LogFile -Encoding utf8

    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        "EXIT CODE: $exitCode" | Out-File -FilePath $LogFile -Append -Encoding utf8
        Write-Warning "Claude Code exited with code $exitCode. Check log: $LogFile"
    } else {
        Write-Host "Morning Briefing completed successfully."
    }
} catch {
    $errorMsg = "EXCEPTION: $($_.Exception.Message)"
    $errorMsg | Out-File -FilePath $LogFile -Append -Encoding utf8
    Write-Error $errorMsg
    exit 1
}
