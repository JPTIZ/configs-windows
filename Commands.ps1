param(
    [parameter(
        Mandatory=$false,
        HelpMessage="Which task to execute."
    )] [string] $task="Show-Help"
)


${GIT_CONFIGS_PATH} = "${env:HOMEPATH}/.git-configs"
${CONFIGS_PATH} = "${env:HOMEPATH}/.config"


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


function Is-Installed([string] $program) {
    return Get-Command $program -ErrorAction SilentlyContinue
}


function Link-File([string] $link_path, [string] $links_to) {
    if (!(Test-Path -Path "${link_path}")) {
        New-Item -ItemType HardLink -Path "${link_path}" -Target "${links_to}"
    }
}


function Link-Dir([string] $link_path, [string] $links_to) {
    if (!(Test-Path -Path "${link_path}")) {
        New-Item -ItemType Junction -Path "${link_path}" -Target "${links_to}"
    }
}


# =============================================================================
# Custom install functions
# -----------------------------------------------------------------------------


function Install-Scoop() {
    # Install instructions from: https://github.com/ScoopInstaller/Scoop#installation=
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    iwr -useb get.scoop.sh -outfile 'ScoopInstall.ps1'
    if (${env:CI}) {
        ./ScoopInstall.ps1 -RunAsAdmin
    } else {
        ./ScoopInstall.ps1
    }
}


# =============================================================================
# Main functions
# -----------------------------------------------------------------------------

function First-Setup() {
    Print-Step "Executing first setup steps..."
    Setup-Base-Tools
    Setup-Dev-Tools
    Setup-Config-Files
    Setup-Profile
    Print-Done "Finished first setup."
}


function Setup-Profile() {
    Print-Info "  Setting up Profile..."
    Run-And-Log Link-File "${PROFILE}" "${PWD}/Microsoft.PowerShell_profile.ps1"
    Print-Done "  :: Setup-Profile"
}


function Setup-Base-Tools() {
    Print-Info "  Setting up base tools..."
    Ensure-Installed scoop Install-Scoop
    Ensure-Installed git
    Print-Done ":: Setup-Base-Tools"
}


function Setup-Dev-Tools() {
    Run-And-Log scoop bucket add extras
    Ensure-Installed wezterm scoop install extras/wezterm
    Ensure-Installed nvim scoop install neovim
    Ensure-Installed mosh scoop install mosh-client
}


function Setup-Config-Files() {
    if (Test-Path -Path "${GIT_CONFIGS_PATH}") {
        Print-Info "  ${GIT_CONFIGS_PATH} already exists. Skip repository cloning..."
    } else {
        Print-Info "  Cloning Linux configs..."
        git clone https://gitlab.com/jptiz/configs ${GIT_CONFIGS_PATH}
    }

    Print-Info "  Creating config directory (${CONFIGS_PATH})..."
    [void](New-Item -Path "${CONFIGS_PATH}" -ItemType "directory" -Force)

    Print-Info "  Creating links to config files from applications to their Windows directory:"
    Print-Info "      - Wezterm"
    Link-Dir "${CONFIGS_PATH}/wezterm" "${GIT_CONFIGS_PATH}/files/wezterm"
    Print-Info "      - Neovim"
    Link-Dir "${env:HOMEPATH}/AppData/Local/nvim" "${GIT_CONFIGS_PATH}/files/vim"
    Print-Info "      - Git (config, ignore)"
    cp -Force "${GIT_CONFIGS_PATH}/files/gitconfig" "${env:HOMEPATH}/.gitconfig"
    cp -Force "${GIT_CONFIGS_PATH}/files/gitignore" "${env:HOMEPATH}/.gitignore"
    Print-Done ":: Setup-Config-Files"
}


function Setup-Extra-Tools() {
    Ensure-Installed btm scoop install bottom
}

Run-And-Log ${task}
