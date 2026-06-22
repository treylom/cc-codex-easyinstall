# 패스트캠퍼스 강의 — 윈도우 종합 설치 부트스트랩
# 설치.bat 가 관리자 권한으로 이 파일을 호출한다. 직접 실행도 가능:
#   powershell -ExecutionPolicy Bypass -File bootstrap.ps1
#
# 흐름:
#   [Phase 1] WSL2 + 우분투 설치 (없을 때만) → 재부팅 후 자동재개 등록 → 재부팅
#   [Phase 2] (재부팅 후 자동) 우분투 준비 대기 → WSL 안에서 setup-wsl-lecture.sh 자동 실행
#
# (A) WSL 통일 환경. 재경님 2026-06-22 승인 설계(60-windows-installer-comprehensive-spec.md).

param(
    [int]$Phase = 1,
    [string]$Distro = "Ubuntu"
)

# 콘솔 한글(UTF-8) 출력 — PowerShell 5.1 한국어 Windows mojibake 방지
try { chcp 65001 > $null; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName  = "FastCampus-Lecture-Install-Resume"

function Say($msg)  { Write-Host "  $msg" }
function Head($msg) { Write-Host ""; Write-Host "=== $msg ===" }

function Test-WslReady {
    # 우분투에 일반 사용자가 만들어졌는지(첫 실행 완료) 확인
    try {
        $u = (wsl -d $Distro -- whoami) 2>$null
        return ($LASTEXITCODE -eq 0 -and $u -and $u.Trim() -ne "root")
    } catch { return $false }
}

function Get-WslDistros {
    # wsl.exe는 배포 목록을 UTF-16LE로 출력 → 인코딩 맞춰 읽고 정리
    # (스크립트 상단 chcp 65001 상태에서 그냥 읽으면 mojibake → 빈 목록 오판)
    $old = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        return @(wsl.exe -l -q 2>$null | ForEach-Object { ($_ -replace "[^\x20-\x7E]", "").Trim() } | Where-Object { $_ -ne "" })
    } catch { return @() }
    finally { [Console]::OutputEncoding = $old }
}

function Register-Resume {
    # 재부팅 후 로그인 시 Phase 2 자동 실행 (RunOnce)
    $cmd = "powershell -ExecutionPolicy Bypass -NoProfile -File `"$ScriptDir\bootstrap.ps1`" -Phase 2"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
        -Name $TaskName -Value $cmd
    Say "재부팅 후 자동 재개 등록 완료."
}

function Run-WslSetup {
    Head "WSL 안에서 강의 셋업 실행"
    # 우분투 준비될 때까지 대기 (사용자가 첫 실행에서 이름·비번 만들 시간)
    if (-not (Test-WslReady)) {
        Say "우분투 첫 실행 창에서 [사용자 이름]과 [비밀번호]를 설정해 주세요."
        Say "(설정이 끝나면 자동으로 이어집니다. 우분투 창이 안 보이면 시작메뉴에서 'Ubuntu' 실행)"
        try { Start-Process $Distro } catch {}
        $tries = 0
        while (-not (Test-WslReady) -and $tries -lt 120) { Start-Sleep -Seconds 5; $tries++ }
    }
    if (-not (Test-WslReady)) {
        Say "우분투 사용자 설정이 확인되지 않습니다. 우분투 창에서 설정을 끝낸 뒤 설치.bat 를 다시 실행해 주세요."
        return $false
    }
    # 윈도우 경로 → WSL 경로 변환 후, /mnt 에서 바로 실행 (복사 불필요)
    $winWslDir = (Resolve-Path (Join-Path $ScriptDir "..\wsl")).Path   # '..' 해소된 절대경로
    $wslScriptDir = (wsl -d $Distro -- wslpath -a "$winWslDir") 2>$null
    $wslScriptDir = ($wslScriptDir | Select-Object -First 1).Trim()
    Say "WSL 셋업 스크립트: $wslScriptDir/setup-wsl-lecture.sh"
    Say ""
    Say ">> 설치 중 [sudo] 비밀번호를 물어보면, 방금 만든 '우분투 비밀번호'를 입력하세요. <<"
    Say ""
    # 이 콘솔 안에서 실행 → sudo 비밀번호 입력 프롬프트가 보입니다.
    wsl -d $Distro -- bash "$wslScriptDir/setup-wsl-lecture.sh"
    return ($LASTEXITCODE -eq 0)
}

# ── Phase 2 (재부팅 후 자동) ────────────────────────────────
if ($Phase -eq 2) {
    Head "Phase 2 — 재부팅 후 자동 이어서 설치"
    if (Run-WslSetup) {
        Head "설치 완료!"
        Say "WSL(우분투) 터미널을 열고:  claude   → 브라우저 안내로 로그인하세요."
    }
    Read-Host "`n계속하려면 Enter를 누르세요"
    exit 0
}

# ── Phase 1 ─────────────────────────────────────────────────
Head "패스트캠퍼스 강의 — 설치 시작 (Phase 1)"

# 1) WSL 설치 상태 점검 (기존 배포 견고 감지 — UTF-16 + 이름변형 대응)
$distros = Get-WslDistros
if ($distros -notcontains $Distro) {
    $alt = $distros | Where-Object { $_ -like "Ubuntu*" } | Select-Object -First 1
    if ($alt) { Say "기존 배포 '$alt' 사용(요청 '$Distro' 미발견)."; $Distro = $alt }
}
$hasDistro = ($distros -contains $Distro)

if ($hasDistro -and (Test-WslReady)) {
    Say "WSL + $Distro 이미 준비됨 → 재부팅 없이 바로 셋업합니다."
    if (Run-WslSetup) { Head "설치 완료!"; Say "WSL 터미널에서:  claude" }
    Read-Host "`n계속하려면 Enter"
    exit 0
}

# 2) Windows Terminal (선택, winget 있으면)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Say "Windows Terminal 설치(있으면 건너뜀)..."
    try { winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements 2>$null } catch {}
}

# 3) WSL2 + 우분투 설치 → 재부팅 재개 등록 → 재부팅
Head "WSL2 + $Distro 설치"
Say "이 단계는 윈도우 기능을 켜고 우분투를 받습니다. 끝나면 재부팅이 필요합니다."
Register-Resume
wsl --install -d $Distro
$installExit = $LASTEXITCODE
if ($installExit -ne 0) {
    # ERROR_ALREADY_EXISTS 등 — 기존 배포가 있으면 재부팅 없이 셋업 시도
    Say "wsl --install 종료코드 $installExit — 기존 배포 확인 후 진행을 시도합니다."
    if (((Get-WslDistros) -contains $Distro) -and (Test-WslReady)) {
        Say "기존 $Distro 사용 가능 → 재부팅 없이 바로 셋업합니다."
        if (Run-WslSetup) { Head "설치 완료!"; Say "WSL 터미널에서:  claude" }
        Read-Host "`n계속하려면 Enter"
        exit 0
    }
}
Head "재부팅이 필요합니다"
Say "재부팅하면 자동으로 이어서 설치합니다(우분투 이름·비번만 직접 설정)."
$ans = Read-Host "지금 재부팅할까요? (Y/N)"
if ($ans -match '^[Yy]') { Restart-Computer -Force }
else { Say "나중에 재부팅하세요. 재부팅 후 자동으로 이어집니다(또는 설치.bat 다시 실행)." }
