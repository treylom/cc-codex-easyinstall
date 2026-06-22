#!/bin/bash
# 패스트캠퍼스 강의 — WSL(우분투) 자동 셋업 (수강생용)
# 윈도우 부트스트랩(bootstrap.ps1)이 재부팅 후 자동 호출한다. 직접 실행도 가능:
#   bash setup-wsl-lecture.sh [번들경로]
#
# 설치 항목 (전부 '이미 있으면 건너뛰기' = 환경점검 실시간):
#   - tmux · git · curl
#   - Claude Code (네이티브 — Node 불필요)
#   - Oh My Tmux (테마 + 마우스)
#   - Node.js (Codex 의존 → 강의에선 필수)
#   - Codex CLI (@openai/codex)
#   - 강의 번들 (~/.claude/{commands,skills})
#   - ai 런처 (tmux + Claude 한 번에) — setup-bashrc.sh 있으면
#
# 근거: claude-agent-teams-setup/scripts/setup-wsl.sh (루돌프 라이브 검증본)을 강의용으로 확장.
# 봇팀 오케스트레이션(agent-teams)은 Discord로 하므로 여기선 제외(재경님 2026-06-22).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 번들 위치: 인자 > 스크립트 옆 ../bundle > 스크립트 옆 .claude
BUNDLE_DIR="${1:-}"
if [ -z "$BUNDLE_DIR" ]; then
    for c in "$SCRIPT_DIR/../bundle" "$SCRIPT_DIR/bundle" "$SCRIPT_DIR/.claude" "$SCRIPT_DIR/../.claude"; do
        [ -d "$c" ] && { BUNDLE_DIR="$c"; break; }
    done
fi

echo "========================================="
echo " 패스트캠퍼스 강의 — WSL 자동 셋업"
echo "========================================="
echo ""

# ── 1. 시스템 패키지 업데이트 ───────────────────────────────
echo "[1/7] 시스템 패키지 업데이트..."
sudo apt update
sudo apt upgrade -y

# ── 2. 기본 패키지 (tmux, git, curl) ────────────────────────
echo "[2/7] tmux · git · curl 설치..."
if command -v tmux >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    echo "  → 이미 설치됨. 건너뜀."
else
    sudo apt install -y tmux git curl
fi
echo "  → tmux $(tmux -V 2>/dev/null || echo '미설치')"

# ── 3. Claude Code (네이티브, Node 불필요) ──────────────────
echo "[3/7] Claude Code (네이티브) 설치..."
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -qsF "$PATH_LINE" "$HOME/.bashrc"; then
    { echo ""; echo "# Claude Code (네이티브) — ~/.local/bin (setup-wsl-lecture.sh)"; echo "$PATH_LINE"; } >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
    echo "  → 이미 설치됨. 건너뜀. ($(claude --version 2>/dev/null))"
else
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        echo "  ❌ Claude Code 설치 실패(다운로드/권한). 네트워크 확인 후 재실행." >&2; exit 1
    fi
    export PATH="$HOME/.local/bin:$PATH"
    command -v claude >/dev/null 2>&1 || { echo "  ❌ 설치는 끝났으나 'claude' 미발견. 새 터미널서 'claude --version' 확인." >&2; exit 1; }
    echo "  → 설치 완료 ($(claude --version 2>/dev/null || echo '버전은 새 터미널서'))"
fi

# ── 4. Node.js (Codex 의존 → 강의 필수) ─────────────────────
# Claude Code 자체는 Node 불필요하나, Codex(@openai/codex)가 npm 으로 깔리므로 Node 필요.
echo "[4/7] Node.js 설치 (Codex 의존)..."
ensure_node() {
    if command -v node >/dev/null 2>&1; then
        echo "  → Node 이미 설치됨. ($(node --version 2>/dev/null))"; return 0
    fi
    echo "  → nvm + Node LTS 설치..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash || return 1
    fi
    ( set +u; export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts ) || return 1
    # 현재 셸에 즉시 반영(아래 Codex 설치가 npm 을 보도록)
    ( set +u; export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" ) || true
    export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && { set +u; . "$NVM_DIR/nvm.sh"; set -u; }
}
if ! ensure_node; then
    echo "  ❌ Node 설치 실패 — Codex 설치 불가. 새 터미널서 'nvm install --lts' 후 재실행." >&2; exit 1
fi

# ── 5. Codex CLI (@openai/codex) ────────────────────────────
echo "[5/7] Codex CLI 설치..."
if command -v codex >/dev/null 2>&1; then
    echo "  → 이미 설치됨. 건너뜀. ($(codex --version 2>/dev/null))"
else
    # npm 이 nvm 셸에서 잡히도록 한 번 더 로드
    ( set +u; export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; npm install -g @openai/codex ) \
        || { echo "  ⚠️ Codex 설치 실패 — 1.2.4/1.2.5에서 'npm install -g @openai/codex'로 재시도 안내." >&2; }
    command -v codex >/dev/null 2>&1 && echo "  → Codex 설치 완료 ($(codex --version 2>/dev/null))" || true
fi

# ── 6. Oh My Tmux (테마 + 마우스) ───────────────────────────
echo "[6/7] Oh My Tmux 설치..."
if [ -d "$HOME/.tmux" ]; then
    echo "  → ~/.tmux 존재. clone 건너뜀(설정만 점검)."
else
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
fi
ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
[ -f "$HOME/.tmux.conf.local" ] || cp "$HOME/.tmux/.tmux.conf.local" "$HOME/"
if [ -f "$HOME/.tmux.conf.local" ]; then
    grep -q '^set -g mouse on' "$HOME/.tmux.conf.local" 2>/dev/null || \
        sed -i 's/#set -g mouse on/set -g mouse on/' "$HOME/.tmux.conf.local" 2>/dev/null || true
fi
echo "  → Oh My Tmux 점검 완료."

# ── 7. 강의 스킬(lesson-cc-codex) + 샘플 vault + 편의 설정 ──
echo "[7/7] 강의 스킬 + 샘플 vault + 편의 설정..."
mkdir -p "$HOME/.claude/skills"
# (a) lesson-cc-codex = 공개레포 install-time clone (최신 유지, 유지보수 중)
LESSON_DIR="$HOME/.claude/skills/lesson-cc-codex"
if [ -d "$LESSON_DIR/.git" ]; then
    echo "  → lesson-cc-codex 이미 있음 → 업데이트(pull)"
    git -C "$LESSON_DIR" pull --ff-only 2>/dev/null || echo "  ⚠ pull 실패(무시, 기존 유지)"
elif [ -d "$LESSON_DIR" ]; then
    echo "  → lesson-cc-codex 폴더 존재(비-git) → 건너뜀"
else
    git clone --depth 1 https://github.com/treylom/lesson-cc-codex.git "$LESSON_DIR" \
        && echo "  → lesson-cc-codex 설치 완료" \
        || echo "  ⚠ lesson-cc-codex clone 실패 — 수동: git clone https://github.com/treylom/lesson-cc-codex.git ~/.claude/skills/lesson-cc-codex"
fi
# (b) 샘플 vault → ~/lecture-sample-vault (실습용 — 강사 vault ❌, 샘플에서 실습)
SAMPLE_DEST="$HOME/lecture-sample-vault"
if [ -d "$SAMPLE_DEST" ]; then
    echo "  → 샘플 vault 이미 있음(보존). 건너뜀."
elif [ -n "$BUNDLE_DIR" ] && [ -d "$BUNDLE_DIR/sample-vault" ]; then
    cp -R "$BUNDLE_DIR/sample-vault" "$SAMPLE_DEST" && echo "  → 샘플 vault → $SAMPLE_DEST"
else
    echo "  → 샘플 vault 번들 못 찾음(건너뜀)."
fi
# (c) settings.local.json (강의 = MCP 자동 허용, agent-teams 미사용)
SETTINGS_LOCAL="$HOME/.claude/settings.local.json"
[ -f "$SETTINGS_LOCAL" ] || printf '{\n  "enableAllProjectMcpServers": true\n}\n' > "$SETTINGS_LOCAL"
# ai 런처 (있으면)
if [ -f "$SCRIPT_DIR/setup-bashrc.sh" ]; then
    bash "$SCRIPT_DIR/setup-bashrc.sh" "$HOME" 2>/dev/null || echo "  → ai 런처 설정 건너뜀(선택)."
fi

echo ""
echo "========================================="
echo " ✅ 설치 완료!"
echo ""
echo " 다음 단계:"
echo "   1. 새 터미널 열기 (또는 'source ~/.bashrc')"
echo "   2. claude        → 브라우저 안내로 로그인 (Pro Max 5x)"
echo "   3. codex         → (1.2.4/1.2.5에서) Codex 로그인"
echo ""
echo " 강의 도구: 스킬 lesson-cc-codex (claude=/lesson-cc-codex · codex=\$lesson-cc-codex)"
echo " 실습 폴더: ~/lecture-sample-vault (샘플 vault에서 실습)"
echo "========================================="
