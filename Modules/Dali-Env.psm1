# $env:DALIHUB_DIR = "${env:USERPROFILE}/source/dali-hub"

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
function RequireSuccess {
    if ($LastExitCode -ne 0) {
        throw "Stopping as last command failed."
    }
}


function EnterDirectory {
    # Saves current directory location
    pushd

    $dir = $args[0]
    echo "Entering ${dir}"
    cd "${dir}"
}


function LeaveDirectory {
    echo "Leaving $(Get-Location)"
    popd
}


function GetCMakeArgs {
    $cmake_args = @()

    if ($debug) {
        $cmake_args += "-DENABLE_DEBUG=ON"
        $cmake_args += "-DCMAKE_BUILD_TYPE=Debug"
    }

    if ($m32) {
        $cmake_args += "-A"
        $cmake_args += "Win32"
    }

    return $cmake_args
}

# -----------------------------------------------------------------------------
# Main functions
# -----------------------------------------------------------------------------
function CreateDaliHub {
    <#
        .SYNOPSIS
            Creates an isolated development environment for DALi and all of its
            dependencies.

        .DESCRIPTION
            This should be a summary of the instructions from this document:
            https://gist.github.com/Coquinho/b8a88d0f23dacdfb78eab301775e6871.

            NOTE: Do not confuse it with dali-env. DALiHub *contains* dali-env.

            It'll create a DaliHub directory (or however you want it to be
            called), install vcpkg and some dependencies, and then some DALi
            modules. It will also create a directory called "dali-env", which
            is the environment itself.
     #>
    param(
        # Where DALi the entire DALi environment and dependencies will be
        # located.
        [Parameter(Mandatory=$true)]
        [string]$dalihub_dir
    )

    echo "Creating DaliHub at ${dalihub_dir}"
    $env:DALIHUB_DIR = "$(Get-Location)/${dalihub_dir}"
    [System.Environment]::SetEnvironmentVariable('DALIHUB_DIR', `
                                                 "${env:dalihub_dir}", `
                                                 [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable('DALI_ENV_FOLDER', `
                                                 "${env:dalihub_dir}/dali-env", `
                                                 [System.EnvironmentVariableTarget]::User)
    mkdir "${env:DALIHUB_DIR}"
    EnterDirectory "${env:DALIHUB_DIR}"

    # Before anything...
    CloneDependencies

    # Now run the .md document steps
    foreach ($step in "vcvars64",
                      "vcpkg",
                      "dali-env",
                      "windows-dependencies",
                      "dali-core",
                      "dali-adaptor",
                      "dali-toolkit",
                      "dali-demo",
                      "tizenfx-stub",
                      "dali-csharp-binder",
                      "tizenfx")
    {
        Setup "${step}"
    }

    LeaveDirectory
}


function CloneDependencies {
    $repos = (
        @{ Url = "microsoft/vcpkg";                 Branch = "2020.11-1" },
        @{ Url = "dalihub/windows-dependencies";    Branch = "expertise/vsix" },
        @{ Url = "dalihub/dali-core";               Branch = "expertise/vsix" },
        @{ Url = "dalihub/dali-adaptor";            Branch = "expertise/vsix" },
        @{ Url = "dalihub/dali-toolkit";            Branch = "expertise/vsix" },
        @{ Url = "dalihub/dali-demo";               Branch = "expertise/vsix" },
        @{ Url = "expertisesolutions/tizenfx-stub"; Branch = "expertise/vsix" },
        @{ Url = "dalihub/dali-csharp-binder";      Branch = "expertise/vsix" },
        @{ Url = "Samsung/TizenFX";                 Branch = "expertise/vsix" }
    )

    EnterDirectory "${env:DALIHUB_DIR}"
    foreach ($repo in $repos)
    {
        $url = $repo.Url
        $branch = $repo.Branch
        git clone "https://github.com/${url}" --branch "${branch}"
    }
    LeaveDirectory
}


function CheckoutToVsix {
    foreach ($dalidir in "dali-adaptor",
                         "dali-core",
                         "dali-csharp-binder",
                         "dali-demo",
                         "dali-toolkit",
                         "tizenfx-stub",
                         "TizenFX")
    {
        EnterDirectory "${env:DALIHUB_DIR}/${dalidir}"
        echo ":::: Adding expertise/vsix remote"
        git remote add expertise "https://github.com/expertisesolutions/${dalidir}"
        echo ":::: Fetching expertise/vsix"
        git fetch expertise vsix
        echo ":::: Checking out expertise/vsix"
        git checkout expertise/vsix
        LeaveDirectory # dalidir
        echo ":: [CheckoutToVsix -- ${dalidir}] Done."
    }
}


function Setup {
    param(
        [string]$step
    )

    echo ":: Running step: ${step}"

    switch ($step)
    {
        "vcvars64" {
            PSvcvars64
        }
        "vcpkg" {
            EnterDirectory "${env:DALIHUB_DIR}/vcpkg"

            ./bootstrap-vcpkg.bat
            ./vcpkg integrate install
            AddVcpkgToPath
            InstallVcpkgDependencies

            LeaveDirectory # vcpkg
        }
        "dali-env" {
            $env:DALI_ENV_FOLDER = "${env:DALIHUB_DIR}/dali-env"
            mkdir "${env:DALI_ENV_FOLDER}"

            EnterDirectory "${env:DALI_ENV_FOLDER}"

            ../windows-dependencies/prebuild.bat
            ../windows-dependencies/setenv.bat
            # VCPKG related
            AddVcpkgDllsToPath

            # Dali again
            SetupDaliEnv

            LeaveDirectory # dali-env
        }
        # Simple "build-me" tasks
        "windows-dependencies" { BuildWindowsDependencies }
        "dali-core" { BuildDaliCore }
        "dali-adaptor" { BuildDaliAdaptor }
        "dali-toolkit" { BuildDaliToolkit }
        "dali-demo" {
            BuildDaliDemo
            # dali-demo
            # RequireSuccess
        }
        "tizenfx-stub" { BuildTizenFxStub }
        "dali-csharp-binder" { BuildDaliCSharpBinder }
        "tizenfx" { BuildTizenFx }
    }
}


function AddVcpkgToPath {
    if (${env:DALIHUB_DIR} -eq $null) {
        Write-Host "       I think you didn't create DaliHub yet."
        return
    }

    $env:VCPKG_DIR = "${env:DALIHUB_DIR}/vcpkg"
    $env:VCPKG_TOOLCHAIN_FILE = "${env:VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake"


    Write-Host ":::: Adding ${env:vcpkg_dir} to PATH"
    $env:PATH += ";${env:vcpkg_dir};"

    $env:VCPKG_FOLDER = $env:VCPKG_DIR
}

function AddVcpkgDllsToPath {
    if (${env:DALIHUB_DIR} -eq $null) {
        Write-Host "       I think you didn't create DaliHub yet."
        return
    }

    Write-Host ":::: Addinv vcpkg DLLs to PATH"

    $env:PATH += ";${env:vcpkg_dir}/installed/${env:vcpkg_default_triplet}/bin"
    $env:PATH += ";${env:vcpkg_dir}/installed/${env:vcpkg_default_triplet}/debug/bin"
    $env:FONTCONFIG_PATH = "${env:vcpkg_dir}/installed/${env:vcpkg_default_triplet}/tools/fontconfig/"
}

function SetupDaliEnv {
    Write-Host ":::: Setting-up DALi environment..."

    if (${env:DALIHUB_DIR} -eq $null) {
        Write-Host "       I think you didn't create DaliHub yet."
        return
    }

    if (${env:DALI_ENV_FOLDER} -eq $null) {
        throw "Something is wrong: DALI_ENV_FOLDER is not set."
    }

    $env:PATH += ";${env:DALI_ENV_FOLDER}/bin/"
    $env:PATH += ";${env:DALI_ENV_FOLDER}/bin/debug"
    $env:DALIAPPLICATION_PACKAGE = "${env:DALI_ENV_FOLDER}/share/com.samsung.dali-demo/res/"
    $env:DALIWINDOW_WIDTH = "480"
    $env:DALIWINDOW_HEIGHT = "800"
 
    $env:DALIIMAGE_DIR="${env:DALI_ENV_FOLDER}/share/dali/toolkit/images/"
    $env:DALISOUND_DIR="${env:DALI_ENV_FOLDER}/share/dali/toolkit/sounds/"
    $env:DALISTYLE_DIR="${env:DALI_ENV_FOLDER}/share/dali/toolkit/styles/"
    $env:DALISTYLE_IMAGE_DIR="${env:DALI_ENV_FOLDER}/share/dali/toolkit/styles/images/"
    $env:DALIDATA_READ_ONLY_DIR="${env:DALI_ENV_FOLDER}/share/dali/"
}

# Remember: we do not run this in main!
function InstallVcpkgDependencies {
    vcpkg install `
                  angle[core] `
                  bzip2[core] `
                  cairo `
                  curl[core,ssl,winssl] `
                  dirent[core] `
                  egl-registry[core] `
                  expat[core] `
                  freetype[core] `
                  fribidi[core] `
                  fontconfig `
                  getopt-win32[core] `
                  gettext[core] `
                  giflib[core] `
                  glib[core] `
                  harfbuzz[core] `
                  libexif[core] `
                  libffi[core] `
                  libiconv[core] `
                  libjpeg-turbo[core] `
                  libpng[core] `
                  libwebp[core] `
                  opengl[core] `
                  pcre[core] `
                  pixman[core] `
                  pthreads[core] `
                  ragel[core] `
                  tool-meson[core] `
                  winsock2[core] `
                  zlib[core]
}

function UninstallVcpkgDependencies {
    vcpkg remove --recurse `
                 angle[core] `
                 bzip2[core] `
                 cairo `
                 curl[core,ssl,winssl] `
                 dirent[core] `
                 egl-registry[core] `
                 expat[core] `
                 freetype[core] `
                 fribidi[core] `
                 fontconfig `
                 getopt-win32[core] `
                 gettext[core] `
                 giflib[core] `
                 glib[core] `
                 harfbuzz[core] `
                 libexif[core] `
                 libffi[core] `
                 libiconv[core] `
                 libjpeg-turbo[core] `
                 libpng[core] `
                 libwebp[core] `
                 opengl[core] `
                 pcre[core] `
                 pixman[core] `
                 pthreads[core] `
                 ragel[core] `
                 tool-meson[core] `
                 winsock2[core] `
                 zlib[core]
}

function BuildWindowsDependencies {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building windows-dependencies..."
    $dir = "${env:DALIHUB_DIR}/windows-dependencies/build"
    EnterDirectory "${dir}"

    echo "Hello? ${cmake_args}"

    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          @cmake_args
    RequireSuccess

    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # $dir
    echo ":::: [windows-dependencies] Done."
}

function BuildDaliCore {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building Dali-Core..."
    EnterDirectory "${env:DALIHUB_DIR}/dali-core/build/tizen"

    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          -DENABLE_PKG_CONFIGURE=OFF `
          -DENABLE_LINK_TEST=OFF `
          -DINSTALL_CMAKE_MODULES=ON `
          @cmake_args
    RequireSuccess

    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # dali-core/build/tizen
    echo ":::: [Dali-Core] Done."
}

function BuildDaliAdaptor {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building Dali-Adaptor..."
    EnterDirectory "${env:DALIHUB_DIR}/dali-adaptor/build/tizen"

    echo ":::::: Generating build..."
    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          -DENABLE_PKG_CONFIGURE=OFF `
          -DENABLE_LINK_TEST=OFF `
          -DINSTALL_CMAKE_MODULES=ON `
          -DPROFILE_LCASE=windows `
          @cmake_args
    RequireSuccess

    echo ":::::: Building..."
    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # dali-adaptor/build/tizen
    echo ":::: [Dali-Adaptor] Done."
}

function BuildDaliToolkit {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building Dali-Toolkit..."
    EnterDirectory "${env:DALIHUB_DIR}/dali-toolkit/build/tizen"

    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          -DENABLE_PKG_CONFIGURE=OFF `
          -DENABLE_LINK_TEST=OFF `
          -DINSTALL_CMAKE_MODULES=ON `
          -DUSE_DEFAULT_RESOURCE_DIR=ON `
          -DDALI_IMAGE_DIR="${env:DALI_IMAGE_DIR}" `
          -DDALI_STYLE_DIR="${env:DALI_STYLE_DIR}" `
          -DDALI_STYLE_IMAGE_DIR="${env:DALI_STYLE_IMAGE_DIR}" `
          -DDALI_SOUND_DIR="${env:DALI_SOUND_DIR}" `
          -DDALI_DATA_READ_ONLY_DIR="${env:DALI_DATA_READ_ONLY_DIR}" `
          @cmake_args
    RequireSuccess

    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # dali-toolkit/build/tizen
    echo ":::: [Dali-Toolkit] Done."
}

function BuildDaliDemo {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building Dali-Demo..."
    EnterDirectory "${env:DALIHUB_DIR}/dali-demo/build/tizen"

    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          -DENABLE_PKG_CONFIGURE=OFF `
          -DINTERNATIONALIZATION=OFF `
          @cmake_args
    RequireSuccess

    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # dali-demo/build/tizen
    echo ":::: [Dali-Demo] Done."
}

function BuildTizenFxStub {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building TizenFX-Stub..."
    EnterDirectory "${env:DALIHUB_DIR}/tizenfx-stub"

    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          @cmake_args
    RequireSuccess

    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # tizenfx-stub
    echo ":::: [TizenFX-Stub] Done."
}


function BuildDaliCSharpBinder {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true
    )

    $cmake_args = GetCMakeArgs $debug $m32

    echo ":::: Building Dali-CSharp-Binder..."
    EnterDirectory "${env:DALIHUB_DIR}/dali-csharp-binder/build/tizen"

    cmake . `
          -B build `
          -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_TOOLCHAIN_FILE}" `
          -DCMAKE_INSTALL_PREFIX="${env:DALI_ENV_FOLDER}" `
          @cmake_args
    RequireSuccess

    cmake --build build --target install --parallel
    RequireSuccess

    LeaveDirectory # tizenfx-stub
    echo ":::: [Dali-CSharp-Binder] Done."
}


function BuildTizenFx {
    echo ":::: Building TizenFX..."
    EnterDirectory "${env:DALIHUB_DIR}/TizenFX"

    ./build.sh full -p:DefineConstants=NOTIZEN
    RequireSuccess

    dotnet build test/Tizen.NUI.Samples/Tizen.NUI.Samples/Tizen.NUI.Samples.csproj /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary
    RequireSuccess

    dotnet run test/Tizen.NUI.Samples/Tizen.NUI.Samples/bin/Debug/netcoreapp3.1/Tizen.NUI.Samples.dll --project test/Tizen.NUI.Samples/Tizen.NUI.Samples/Tizen.NUI.Samples.csproj /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary
    RequireSuccess

    dotnet run test/Tizen.NUI.Samples/Tizen.NUI.Samples/bin/Debug/netcoreapp3.1/Tizen.NUI.Samples.dll --project test/Tizen.NUI.Samples/Tizen.NUI.Samples/Tizen.NUI.Samples.csproj /property:GenerateFullPaths=true /consoleloggerparameters:NoSummary
    RequireSuccess

    LeaveDirectory # tizenfx
    echo ":::: [TizenFX] Done."
}


function BuildAll {
    param (
        [switch]$debug = $true,
        [switch]$m32 = $true,
        $projects = ("WindowsDependencies",
                     "DaliCore",
                     "DaliAdaptor",
                     "DaliToolkit",
                     "DaliDemo",
                     "TizenFxStub",
                     "DaliCSharpBinder",
                     "TizenFx")
    )

    foreach ($project in $projects) {
        & "Build${project}" "${debug}" "${m32}"
        RequireSuccess
    }
}

function _Main {
    $env:vcpkg_default_triplet = "x86-windows"
    PSvcvars64
    AddVcpkgToPath
    AddVcpkgDllsToPath
    SetupDaliEnv
}

_Main
