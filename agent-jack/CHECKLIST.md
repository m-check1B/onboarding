# Target setup on a Mac: what is installed, at which version

This is the one combination we have tested. A Mac that matches every row is set up correctly. Anything else is not proven, even when it seems to work. The Agent Jack doctor ([AGENTS.md](AGENTS.md) step 1) gets a Mac there in one run, and this page is the picture of done.

Last checked 21 Nov 2026, against setup tag **v1.1.4**. The doctor reads the versions from our stack lock (`stack-lock/stack.lock.json` next to it) and from the copy of `versions.env` beside the lock, which is byte-identical to the one in [agent-jack-setup](https://github.com/m-check1B/agent-jack-setup) at that tag. If this page and those files disagree, the files win and this page has a bug: tell us.

Agent Jack, Tentacles and T3 Code are **three separate pieces**. Each is installed from its own source and none of them replaces another.

## One command checks all of it

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)" doctor --check
```

`--check` changes nothing. Expected: no line that starts with `FAIL`. Two lines always say `SKIP … manual`: `AJ-PAIR-00` and `AJ-LOCAL-00` (rows 11 and 12, checked in the app). Every other line that is not `PASS` names its own next step.

## 1. Every Mac (Agent Jack in the browser and the desktop app)

| # | What | Aim at | Where it comes from | How to check |
|---|---|---|---|---|
| 1 | macOS | 14 or newer, Intel or Apple silicon | Apple (System Settings → General → Software Update) | `sw_vers -productVersion` |
| 2 | Agent Jack desktop app | **3.17.68** or newer | the Agent Jack Downloads page, signed in. Never from GitHub or anywhere else. | `defaults read "/Applications/Agent Jack.app/Contents/Info" CFBundleShortVersionString`. The doctor installs a download only when its SHA-256 starts with the 12 characters at the end of its file name and it is signed by `Verduona s.r.o. (QAF65J7554)`. |

With rows 1 and 2 the person can sign in and their Bot answers from our server. That is a complete setup for someone who does not run Bots on their own Mac.

## 2. A Mac that runs Local labs (Bots working on this Mac)

| # | What | Aim at | Where it comes from | How to check |
|---|---|---|---|---|
| 3 | Node.js | 22 or newer | the one on the Mac if usable, otherwise the doctor puts the pinned build from `nodejs.org` (SHA-256 checked) in `~/.agent-jack/node` | `node --version` |
| 4 | Codex CLI | 0.164.0 or newer, signed in by the person with their ChatGPT plan | installed by the doctor with npm at exactly that version | `codex --version` |
| 5 | Claude Code CLI | 2.1.310 or newer, signed in by the person with their Claude plan | installed by the doctor with npm at exactly that version | `claude --version` |
| 6 | T3 Code (Beta) | **0.1.11**. Supported range 0.1.8 to 0.1.11; the app updates itself. | The official, unmodified app from its makers: `github.com/pingdotgg/t3code`, release `v0.1.11` (SHA-256 and bundle id checked) | `defaults read "/Applications/T3 Code (Beta).app/Contents/Info" CFBundleShortVersionString` prints `0.1.11`, and the same command with `CFBundleIdentifier` prints `com.t3tools.t3code` |
| 7 | Tentacles | **0.5.0-jack.19**: tag `v0.5.0-jack.19`, commit `a80ca96b91abbf427648371392a968a32f17bf73` | Our public repo `github.com/m-check1B/t3-code-tentacles`, the archive of exactly that commit, in `~/.agent-jack/tentacles/` and linked with npm | `tentacles --version` prints `0.5.0-jack.19`. `tentacles doctor` shows `T3: reachable`, `T3 authentication: valid` and `T3 Code support: supported` (or `untested` after T3 Code has updated itself past the tested version). |
| 8 | Python | 3.11 or newer | `python.org` (the person installs it) | `python3 --version` |
| 9 | estate-guardian (classify) | tag `v1.0.0`, estate-classify 0.3.0 | Our public repo `github.com/m-check1B/estate-guardian`, the archive of the tag's commit, in `~/.agent-jack/venv` | the doctor line `AJ-EC-00` |
| 10 | Google Chrome | the current release (optional: only for the browser extensions) | `google.com/chrome` | `ls "/Applications/Google Chrome.app"` |

One signed-in plan (row 4 or row 5) is enough to start; the doctor shows `WARN` for the other. Homebrew and git are not needed.

**Must not be on the Mac:** `T3 Code TPLUS`, `T3 Code (Alpha)` or any other modified T3 build. We ship no T3 fork. The doctor moves those two to `~/.agent-jack/replaced-apps` when they carry a T3 bundle id, and deletes nothing. It leaves any other app of that name, and any other T3 build, alone and reports it (`AJ-T3-08`).

**Apps in the home folder.** When `/Applications` is not writable, the apps in rows 2 and 6 live in `~/Applications` instead (row 2 also under the older name `AgentJack.app`). An older copy in `/Applications` that this account cannot replace is left whole and reported (`AJ-T3-11`); the doctor never installs a second copy next to it.

## 3. Checked by hand in the Agent Jack app

| # | What | Aim at |
|---|---|---|
| 11 | Pairing | **Settings → Computers & labs** shows this Mac as **Paired · ready** or **Connected** |
| 12 | A Bot on Local | A Bot set to **Local · Codex** or **Local · Claude Code** answers, and the line under the answer reads **Ran on Local · …** |

## 4. Easy to get wrong today

- **Newer is not better here.** A newer Tentacles tag than row 7 can exist in the public repo. Until our lock names it as tested, it is not proven with the rest, and the doctor installs row 7. T3 Code is different: it updates itself, and a version above the tested one shows as `WARN AJ-T3-09`, not `FAIL`.
- **Plugins on a Local lab do not work with this combination.** A Bot that has a plugin switched on (Marketplace › Plugins) must run on Server; on Local it answers that the lab can't use plugins. That is the current state, not a fault on the Mac.
- **Proven Local labs are Codex and Claude Code.** The app also lists Grok, Cursor, DeepSeek, OpenCode and Antigravity when it finds them. They are not part of the tested setup yet.
- **Hardware.** Recommended: Apple M3 or newer, 16 GB RAM, 512 GB disk. Less works; the doctor shows `WARN AJ-HW-01` or `WARN AJ-SYS-02` (Intel).
- **This page is for macOS.** Windows 11 has its own guide in agent-jack-setup and is not proven with the official T3 Code (Beta) yet.

## 5. How this page stays correct

The versions in rows 2, 6 and 7 and the setup tag change only together, in one step across Agent Jack, Tentacles, agent-jack-setup and this guide. Our version lock records that step, and the doctor reads it. Before any change to this page is merged, we run a check that compares this page with the lock. The minimums in rows 3 to 5, 8 and 9 come from `versions.env` at the setup tag and are re-read by hand at each step.
