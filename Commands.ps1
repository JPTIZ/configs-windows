param(
    [parameter(
        Mandatory=$false,
        HelpMessage="Which task to execute."
    )] [string] $task="Show-Help"
)


# =============================================================================
# Utilities
# -----------------------------------------------------------------------------

function Show-Help() {
    Get-Help ./Commands.ps1
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
    Print-Done "Finished first setup."
}


function Setup-Profile() {
    Print-Info "  Setting up Profile..."
    # TODO: Copy Profile.ps1 to correct directory
    Print-Done "  :: Setup-Profile"
}


function Ensure-Installed(
    [parameter(Mandatory)][string] $app,
    [parameter(ValueFromRemainingArguments=$true)]
    [string[]] $custom_install_command
) {
    $app_name = (Get-Culture).TextInfo.ToTitleCase($app)
    Print-Info "Installing ${app_name}..."
    Print-Info "  1. Checking if ${app_name} is already installed..."
    if (Is-Installed $app) {
        Print-Info "     ${app_name} is already installed."
        return
    }

    Print-Info "     ${app_name} is not installed. Installing..."

    if (!${custom_install_command}) {
        Run-And-Log scoop install ${app}
    } else {
        & Run-And-Log @custom_install_command
    }
}


function Setup-Base-Tools() {
    Print-Info "  Setting up base tools..."
    Ensure-Installed scoop Install-Scoop
    Ensure-Installed git
    Print-Info "  Cloning Linux configs..."
    Print-Done ":: Setup-Base-Tools"
}


function Setup-Dev-Tools() {
    Setup-Neovim
}


function Is-Installed([string] $program) {
    return Get-Command $program -ErrorAction SilentlyContinue
}


function Install-Scoop() {
    # Snippet from: https://github.com/ScoopInstaller/Scoop#installation=
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    # End of snippet
}


function Setup-Neovim() {
    Ensure-Installed nvim scoop install neovim
    # TODO: Copy Neovim config files (+ vimrc) to Windows's Nvim config location
}

Run-And-Log ${task}
