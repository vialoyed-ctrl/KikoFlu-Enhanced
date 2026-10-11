param(
    [Parameter(Mandatory = $true)]
    [string]$FlutterSdk,
    [string]$JavaHome = $env:JAVA_HOME,
    [switch]$TestPackage,
    [switch]$Smoke,
    [switch]$Offline
)
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path $PSScriptRoot -Parent
$taskFlutter = Join-Path $FlutterSdk 'bin/flutter.bat'
$taskPubspec = Join-Path $taskProject 'pubspec.yaml'
$taskOriginal = [IO.File]::ReadAllText($taskPubspec)
Push-Location $taskProject
try {
    # Global desktop flags override environment flags in this SDK. Disable
    # desktop generation only for this pub invocation, then restore the file.
    $taskTemporary = [regex]::Replace($taskOriginal, '(?m)^flutter:\r?\n', "flutter:`n  config:`n    enable-windows-desktop: false`n    enable-linux-desktop: false`n")
    try {
        [IO.File]::WriteAllText($taskPubspec, $taskTemporary)
        if ($Offline) { & $taskFlutter pub get --offline } else { & $taskFlutter pub get }
        if ($LASTEXITCODE -ne 0) { throw 'pub get failed; APK build cancelled.' }
    } finally { [IO.File]::WriteAllText($taskPubspec, $taskOriginal) }
    if (!(Test-Path 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java')) {
        throw 'Missing Android plugin registrant; APK build cancelled.'
    }
    if (!$JavaHome -or !(Test-Path (Join-Path $JavaHome 'bin/java.exe'))) { throw 'Specify an installed Java 17 or 21 directory with -JavaHome.' }
    $env:JAVA_HOME = $JavaHome
    if ($taskOriginal -notmatch '(?m)^version:\s*([^\s+]+)\+([0-9]+)') { throw 'pubspec version must include a build number.' }
    $taskVersion = $Matches[1]; $taskBuildNumber = $Matches[2]
    $taskPropsPath = Join-Path $taskProject 'android/local.properties'
    if (!(Test-Path $taskPropsPath)) { throw 'Create android/local.properties with sdk.dir and flutter.sdk first.' }
    $taskProps = [IO.File]::ReadAllText($taskPropsPath)
    $taskProps = [regex]::Replace($taskProps, '(?m)^flutter\.(versionName|versionCode|buildMode)=.*\r?\n?', '')
    [IO.File]::WriteAllText($taskPropsPath, $taskProps.TrimEnd()+"`nflutter.buildMode=release`nflutter.versionName=$taskVersion`nflutter.versionCode=$taskBuildNumber`n")
    Push-Location android
    try {
        $taskArgs = @('-PskipDependencyChecks=true', '-Ptarget-platform=android-arm64', '-Ptarget=lib/main.dart')
        if ($Smoke) { $taskArgs[2]='-Ptarget=tool/dsp_device_smoke.dart'; $taskArgs+='-PkikoApplicationId=com.meteor.kikoeruflutter.dspsmoke' }
        elseif ($TestPackage) { $taskArgs+='-PkikoApplicationId=com.meteor.kikoeruflutter.dspcheck' }
        & ./gradlew.bat @taskArgs assembleRelease
        if ($LASTEXITCODE -ne 0) { throw 'Gradle build failed.' }
    } finally { Pop-Location }
} finally { Pop-Location }
