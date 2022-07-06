Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit

Set-Alias -Name vim -Value nvim -Force

function Prompt
{
    $OriginalLastExitCode = $LastExitCode
    $host.ui.RawUI.WindowTitle = $(get-location)

    if ($OriginalLastExitCode) {
      $ShowErrorCode = "(${OriginalLastExitCode}) "
    } else {
      $ShowErrorCode = ""
    }

    # Directory and prefix
    Write-Host -NoNewline "${ShowErrorCode}$(get-location)"

    # Writes branch name
    $status = git status --porcelain
    if ($?) {
        Write-Host -NoNewline " ["
        if ($status | Where {$_ -match '^\?\?'}) {
            # untracked files exist
            $BranchColor = "DarkRed"
        }
        elseif ($status | Where {$_ -match '^ M'}) {
            # uncommitted changes
            $BranchColor = "Red"
        }
        elseif ($status | Where {$_ -match '^M '}) {
            # uncommitted changes
            $BranchColor = "DarkYellow"
        }
        else {
            # tree is clean
            $BranchColor = "DarkGreen"
        }
        $BranchName = "$(git symbolic-ref HEAD | ForEach-Object { $_.split("/")[2] })"
        Write-Host -NoNewline ${BranchName} -Foreground ${BranchColor}
        Write-Host -NoNewline "]"
    }

    # Suffix
    Write-Host -NoNewline " $ "

    " "
    $global:LastExitCode = $OriginalLastExitCode
}

function PSvcvars64 {
    if (${env:devenvdir}) {
        echo "= Devenvdir already set. Nothing to be done."
        return
    }

    cmd.exe /c "call vcvars64 && set > %temp%\vcvars.txt"

    Get-Content "$env:temp\vcvars.txt" | Foreach-Object {
      if ($_ -match "^(.*?)=(.*)$") {
        Set-Content "env:\$($matches[1])" $matches[2]
      }
    }
}

function ActivateEFLEnv {
    $env:Path += ";"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_audio;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_avahi;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_buffer;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_cocoa;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_con;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_drm;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_drm2;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_evas;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_fb;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_file;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_imf;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_imf_evas;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_input;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_input_evas;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_ipc;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_sdl;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_wayland;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_win32;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_wl2;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ecore_x;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ector;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/edje;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eet;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eeze;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/efl;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/efl_canvas_wl;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/efl_mono;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/efreet;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eina;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eio;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eldbus;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/elementary;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/elput;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/elua;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/embryo;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/emile;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/emotion;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eo;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eolian;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/eolian_cxx;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ephysics;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ethumb;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/ethumb_client;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/evas;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/src/lib/evil;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/subprojects/lua;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/subprojects/getopt;"
    $env:Path += "${env:USERPROFILE}/source/repos/efl/build/subprojects/pcre-8.37;"
    $env:Path += "${env:USERPROFILE}/source/pkg/vcpkg/installed/x64-windows/bin;"
    $env:Path += "${env:USERPROFILE}/source/pkg/vcpkg/installed/x64-windows/debug/bin;"
    $vcpkg_dir = "${env:USERPROFILE}/source/pkg/vcpkg/;"
}

function Activate {
    $environment = $args[0]
    echo "= Activating ${environment}"
    Import-Module "${env:USERPROFILE}/Documents/WindowsPowerShell/Modules/${environment}.psm1"
    echo "= [${environment}] Done."
}

function Mosh-Tmux {
    param(
        [parameter(ValueFromRemainingArguments=$true)]
        [string[]] $mosh_args
    )
    & mosh --no-init @mosh_args # -- tmux new-session -ADs default
}
