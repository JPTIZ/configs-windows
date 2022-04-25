param(
    [string] $task="Show-Help"
)


# =============================================================================
# Utilities
# -----------------------------------------------------------------------------

function Show-Help() {
    Write-Host "Help: ?"
}


function Print-Log(
    [string] $msg,
    [string] $type,
    [string] $color
) {
    Write-Host ":: [" -NoNewline
    Write-Host "${type}" -NoNewline -ForegroundColor ${color}
    Write-Host "] $msg"
}


function Print-Info([string] $msg) {
    Print-Log $msg "INFO" DarkGray
}


function Print-Step([string] $msg) {
    Print-Log $msg "STEP" Yellow
}


function Print-Done([string] $msg) {
    Print-Log $msg "DONE" Green
}


function Run-And-Log {
    param(
        [string] $command,
        [parameter(ValueFromRemainingArguments = $true)]
        [string[]] $command_args
    )
    Write-Host ":: [" -NoNewline
    Write-Host "RUN" -NoNewline -ForegroundColor Blue
    Write-Host " ] " -NoNewline
    Write-Host "$ " -NoNewline -ForegroundColor Red
    Write-Host ${command} @command_args
    & ${command} @command_args
}


# =============================================================================
# Main functions
# -----------------------------------------------------------------------------

function First-Setup() {
    Print-Step "Executing first setup steps..."
    Setup-Profile
    Setup-Base-Tools
    Setup-Dev-Tools
}


function Setup-Profile() {
    Print-Info "  Setting up Profile..."
    # TODO: Copy Profile.ps1 to correct directory
    Print-Info "  Done."
}


function Setup-Base-Tools() {
    Print-Info "  Setting up base tools..."
    Install-Scoop
    Print-Info "  Cloning Linux configs..."
    Print-Done "  Done (Setup-Base-Tools)"
}


function Setup-Dev-Tools() {
    Install-Neovim
}


function Is-Installed([string] $program) {
    return Get-Command $program -ErrorAction SilentlyContinue
}


function Install-Scoop() {
    Print-Info "Installing Scoop..."
    Print-Info "  1. Checking if Scoop is already installed..."
    if (Is-Installed scoop) {
        Print-Info "     Scoop is already installed."
        return
    }

    # Snippet from: https://github.com/ScoopInstaller/Scoop#installation=
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    # End of snippet
}


function Install-Neovim() {
    Print-Info "Intalling Neovim..."
    Print-Info "  1. Checking if Neovim is already installed..."
    if (Is-Installed nvim) {
        Run-And-Log Write-Host "Nice"
        Print-Info "     Neovim is already installed."
        return
    }
    Run-And-Log "scoop install neovim"
    # TODO: Copy Neovim config files (+ vimrc) to Windows's Nvim config location
}

Write-Host "Executing task `"${task}`""
& ${task}
