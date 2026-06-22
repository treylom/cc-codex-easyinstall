# 패스트캠퍼스 강의 — 윈도우 설치파일

윈도우(Windows)에서 강의 환경을 **한 번에** 설치합니다.
WSL(윈도우 속 리눅스) + Claude Code + Codex + tmux + 강의 도구.

---

## ⚡ 빠른 시작 (3단계)

1. 이 페이지 오른쪽 위 **초록색 `< > Code` 버튼 → `Download ZIP`** 으로 파일을 받습니다.
2. 받은 ZIP을 **마우스 오른쪽 클릭 → 압축 풀기**.
3. 풀린 폴더 안의 **`설치.bat` 더블클릭**.

그 다음은 화면 안내(+ 재부팅 1회)를 따라가면 자동으로 끝납니다.

> 처음 쓰시는 분은 👉 **[설치가이드.md](설치가이드.md)** 를 그대로 따라오세요 (그림·단계별, 막히는 부분 해결까지).

---

## 무엇이 설치되나요?

| 항목 | 설명 |
|---|---|
| WSL2 + 우분투 | 윈도우 안에서 리눅스 환경 (강의 기준 환경) |
| Claude Code | 이 강의의 메인 AI 코딩 도구 |
| Codex | 형제 도구 (1.2.4 / 1.2.5에서 사용) |
| tmux + Oh My Tmux | 터미널 분할 (봇·세션 여러 개 다루기) |
| lesson-cc-codex 스킬 | 강의 실습 스킬 (`~/.claude/skills`, 설치 시 최신본 자동 받음) |
| 샘플 vault | 실습용 샘플 노트 모음 (`~/lecture-sample-vault`) |

모든 단계는 **'이미 깔렸으면 건너뛰기'** 라서, 중간에 멈춰도 `설치.bat`를 다시 실행하면 이어서 됩니다.

---

## 폴더 구성

```
설치.bat                  ← 더블클릭 진입 (관리자 권한 자동)
설치가이드.md             ← 처음 쓰는 분용 단계별 안내
windows/bootstrap.ps1     ← WSL 설치 + 재부팅 자동재개
wsl/setup-wsl-lecture.sh  ← WSL 안 도구 설치 (tmux·Claude·Codex·번들)
wsl/setup-bashrc.sh       ← ai 런처 (tmux + Claude 한 번에)
bundle/sample-vault/      ← 실습용 샘플 vault (→ ~/lecture-sample-vault)
```
> lesson-cc-codex 스킬은 설치 시 최신본을 자동으로 받아옵니다(GitHub `treylom/lesson-cc-codex`).

---

## 도움이 필요하면

[설치가이드.md](설치가이드.md) 의 "자주 묻는 것"을 먼저 확인하고, 그래도 안 되면 강의 Q&A에 **어느 단계 / 어떤 화면**인지 스크린샷과 함께 남겨주세요.
