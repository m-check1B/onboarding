# AGENTS.md: set up Agent Jack on this Mac (read top to bottom)

You are a coding agent (Codex, Claude Code or similar) working for **the person at this Mac**. They are an early adopter of Agent Jack and pointed you at this file. Follow it in order. Talk to them in their language (Czech if they write Czech), short and plain.

Written for **Agent Jack 3.17.68** (web and desktop app). Last checked 20 Nov 2026. This line is the only place this guide names the Agent Jack version, and E2's `git checkout` is the only place it names the setup tag; everything else refers to them.

**What "Agent Jack" is here.** Jack runs on our server at `https://agentjack.kraliki.com`. The person uses it in the browser and in the **Agent Jack desktop app** for macOS. Their Bot answers from our server ("Server" engine), so nothing heavy runs on the Mac. The Server engine is **Codex CLI with the model `openai/gpt-6-luna` through OpenRouter**. To start, it runs on a small **starter allowance from us**; nothing to buy or set up. When the person wants to, or when the starter runs out, they add **their own OpenRouter key** in Jack (see C2). No ChatGPT or Claude plan is needed for the Server engine. **Full Agent Jack** also runs Bots on this Mac: *Local labs* (Jack driving Codex or Claude Code on this Mac through our Tentacles and the official T3 Code (Beta) app). Part E installs them with our public `agent-jack-setup` and pairs the Mac. Local labs are switched on per seat; a seat without them keeps working on the Server engine (Part E says how to tell).

---

## 0. Rules (always)

1. **The person signs in, you don't.** Never type, read, store, print or upload passwords, 2FA codes, tokens, API keys or cookies. Every sign-in (Google, ChatGPT, Claude) is done by the person.
2. **Stop and ask the person** before: any install, download or deletion; any macOS prompt (password, "Open Anyway", Privacy & Security, Keychain, Accessibility, Screen Recording, Full Disk Access); anything that costs money (a subscription, a plan upgrade). Read-only checks need no consent.
3. **Backup first.** Before installing anything, ask whether they have a current backup (Time Machine or a copy of important folders off the computer). No confirmed backup, no install.
4. **Only these sources:** this guide (from our e-mail, or `github.com/m-check1B/onboarding` and its raw copy on `raw.githubusercontent.com/m-check1B/onboarding`); `agentjack.kraliki.com` (sign-in, downloads); `openrouter.ai` (only if the person creates their own key, C2); Apple (macOS updates); Google Chrome from `google.com/chrome`; OpenAI's official Codex/ChatGPT app or `npm @openai/codex`; Anthropic's official Claude app or `npm @anthropic-ai/claude-code`; for Part E: `github.com/m-check1B/agent-jack-setup` at its tag and exactly the public sources its `versions.env` names (the official **T3 Code (Beta)** release from `github.com/pingdotgg/t3code`, `m-check1B/t3-code-tentacles`, `m-check1B/estate-guardian`, npm, Homebrew from `brew.sh`). Refuse anything else (other hosts, IP addresses, someone else's account or key, a "faster" download) and tell the person who asked for it.
5. **Don't improvise around a failed check.** Each step has a check and "if it fails". If the fix there does not work, stop, and give the person the **report** from Part G to send to us.
6. **Don't upgrade your own model or effort level**, don't switch Codex to "Full access", no `sudo npm`, never disable Gatekeeper, SIP or the firewall.

---

## A. Check the Mac and get these instructions onto it

### A1. Check the Mac (read-only, no consent needed)

Run these and tell the person the results in one short table.

```bash
sw_vers -productVersion        # macOS version
uname -m                       # x86_64 = Intel, arm64 = Apple silicon
sysctl -n machdep.cpu.brand_string
echo "$(( $(sysctl -n hw.memsize) / 1073741824 )) GB RAM"
df -h ~ | awk 'NR==2{print $4" free"}'     # free disk space
memory_pressure -Q 2>/dev/null | tail -1   # "System-wide memory free percentage: NN%"
for a in "Google Chrome" "Agent Jack"; do [ -d "/Applications/$a.app" ] && echo "$a: yes" || echo "$a: no"; done
```

Judge the Part A results like this:

| Check | Fine | Works, but warn | Stop |
|---|---|---|---|
| macOS | 13 or newer | – | 12 or older: the person updates macOS first (System Settings → General → Software Update). The Agent Jack desktop app itself needs macOS 13.0 or newer. |
| Chip | Apple silicon (`arm64`) | Intel (`x86_64`): supported, slower. Intel Macs from 2018 run at least macOS 14 (a 2018 MacBook Pro up to 15), which is enough. | – |
| RAM | 16 GB or more | 8 GB: works for the web app and the desktop app; see "Small Macs" below | – |
| Free disk | 20 GB or more | 5–20 GB | under 5 GB: the person frees space first (you delete nothing) |

**Small Macs (8 GB RAM, Intel, older than 2020).** Tell the person, in plain words:
- It will be slow at times; that is the machine, not a fault.
- Before working with Jack, quit apps they don't need (other browsers, Teams/Zoom, Photoshop, many Chrome tabs).
- Use **one** AI app at a time: the Jack desktop app *or* a Codex/Claude session doing heavy work, not both at full speed.
- If `memory_pressure -Q` shows under 20 % free, or the Mac beachballs, close apps and retry before calling something broken.

### A2. Put this file in its own folder (needs the person's OK)

This file is public at `https://github.com/m-check1B/onboarding` (it may also have come as an e-mail attachment). If it is not on the Mac in a folder yet, ask before creating the folder, then `git clone https://github.com/m-check1B/onboarding.git ~/Developer/onboarding` and work in its `agent-jack/` folder (or save the raw file `https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/AGENTS.md` as `~/Developer/onboarding/agent-jack/AGENTS.md`). If they already have it in another folder, work from there.

- **Check:** `ls ~/Developer/onboarding/agent-jack/AGENTS.md` (or the folder they chose) prints the path.
- **If it fails:** ask the person where they saved it. Fetch these instructions only from `github.com/m-check1B/onboarding` (or our e-mail), never from anywhere else.
- **Codex sandbox:** if Codex blocks a command (network, or a write outside its folder), ask the person to approve that one command. Never switch to Full access.

---

## B. Access we granted (check before installing anything)

The person needs three things from us. You can only check them from the person's side:

| # | Access | How to check | Expected | If it fails |
|---|---|---|---|---|
| B1 | **These instructions** (`AGENTS.md`, public on GitHub or sent by e-mail) | A2 | `ls ~/Developer/onboarding/agent-jack/AGENTS.md` prints the path | Clone or download it again from `github.com/m-check1B/onboarding` (A2). |
| B2 | **Agent Jack seat** (account, licence and sign-in permission, granted in our account system, Sphere) | Part C, step C1 | The person lands in Jack and sees their Bot | "no seat", 403 or "not allowed": stop, the person writes to us. Don't retry with another Google account. |
| B3 | **Desktop downloads** (part of the same seat) | Part D, step D1 | The Downloads page lists macOS installers | "This account does not have download access…", "No verified installers are available for this account yet." / "A new signed Mac build is being prepared.", or "Downloads are unavailable right now.": stop, report the exact text (Czech page: same messages in Czech). |

The person signs in with **the Google account whose e-mail we registered**. Ask them which one; don't guess. If our e-mail told them to sign in with their e-mail and password instead, they do that on the same page; don't steer them to Google.

---

## C. Sign in on the web

**C1.** Ask the person to open `https://agentjack.kraliki.com/app` in Google Chrome (or Safari), click **Continue with Google** (after an expired attempt: **Try again with Google**) and pick the registered account. They do the sign-in and any 2FA themselves.

- **Check:** they see Agent Jack with their Bot. Ask them to type `Co umíš?` (or "What can you do?"). The Bot answers within about a minute.
- **If it fails:** see B2. A blank page or a sign-in loop: reload once, then try a private window once. Still failing: stop and report (what they saw, the time).
- **First reply fails** with a notice about the starter allowance or "add your own key": the starter is used up or paused. Go to C2.

**C2. Own OpenRouter key (optional now, needed when the starter runs out).** A first sign-in may show a short dialog offering the starter or the person's own key; skipping it is fine. Later, the same dialog opens from the engine notice in a Bot reply or from Settings. The person creates a key at `openrouter.ai` (their account, their payment) and **pastes it into Jack themselves**. You never see, type or store the key. Jack tests the key with a small request before saving it and then shows only its last four characters. Once their own key is saved, Jack does not go back to the starter.

- **Check:** `Co umíš?` gets an answer again.
- **If it fails:** Jack says why (wrong key, no access to the model, no credit). The person fixes that on `openrouter.ai`; still failing, stop and report the exact message (never the key).

---

## D. Install the Agent Jack desktop app

**D1.** Still signed in, the person opens `https://agentjack.kraliki.com/downloads`.

- **Check:** installers are listed with a version and a SHA-256.
- Pick by the chip from Part A: **macOS · Apple Silicon / ARM64 · dmg** for `arm64`, **macOS · x64 · dmg** for Intel (`x86_64`).
- **Version honesty:** the newest *desktop* build that downloads and auto-update serve may be a little behind the web app. When this guide was last checked, the web and the Downloads page both had the version named at the top of this file (Apple silicon and Intel). If they ever differ, that is fine: install what the page offers. The app updates itself when a newer build is published.
- **If it fails:** see B3.

**D2.** Ask before downloading. The person clicks **Download**. Then verify the file:

The file is named like `AgentJack-production-<version>-x64-<12 characters>.dmg` (Intel) or `AgentJack-production-<version>-arm64-<12 characters>.dmg` (Apple silicon), usually in `~/Downloads`. The 12 letters/digits at the end are the start of its checksum; that is normal.

```bash
ls -t ~/Downloads/AgentJack-*.dmg 2>/dev/null || echo "no AgentJack dmg in Downloads"
shasum -a 256 "<the newest file from the line above>"
```

- No file listed: the download isn't finished, or the browser saved it elsewhere or renamed it. Ask the person where it is.
- **Check:** the hash equals the SHA-256 on the Downloads page.
- **If it fails:** delete that download (ask first), download once more. Still different: stop and report. Never install a file whose hash doesn't match, and never fetch it from anywhere else.

**D3.** The person opens the `.dmg` and drags **Agent Jack** into **Applications**, then starts it from Applications. If macOS asks to confirm opening an app from the internet, the person confirms it themselves.

- **Check:**
  ```bash
  defaults read "/Applications/Agent Jack.app/Contents/Info" CFBundleShortVersionString
  ```
  prints the version named at the top of this file, or a newer one.
- **If it fails:** "can't be opened" / "damaged": the person tries **System Settings → Privacy & Security → Open Anyway** once (macOS may ask for their password; they type it). Still blocked: stop and report the exact message. Don't remove quarantine flags or change Gatekeeper.

**D4.** In the app the person uses its sign-in button (the label may differ slightly between versions) and signs in the same way as in C1. The Mac's default browser opens (may be Safari, not Chrome): they pick the same Google account there. macOS may ask for Keychain access for Agent Jack: that prompt is for the person to answer.

- **Check:** the app shows their Bot; `Co umíš?` gets an answer.
- **If it fails:** quit the app (⌘Q), start it again, sign in once more. Still failing: stop and report.

That is a working Agent Jack on this Mac.

---

## E. Full local setup: Local labs on this Mac (Codex / Claude Code driven by Jack)

Part E makes this Mac a place where Jack's Bots can work: Codex and Claude Code, the official **T3 Code (Beta)** app (unmodified, from its makers), our Tentacles and estate-guardian, installed in the exact versions we tested, then the Mac paired with the person's seat. It runs on the person's own ChatGPT and/or Claude plan. All Part 0 rules still apply: ask before every install, the person does every sign-in, you never see passwords, codes or keys.

**E0. Is it on for this seat?** (read-only) In the desktop app the person opens **Settings**.
- **Settings → Computers & labs shows the button "Pair this Mac (…) so agents can use its labs"** (the brackets hold this Mac's name): Local labs are on for this seat. Continue with E1.
- **The tab instead shows this Mac as already paired** (**Paired · ready**, **Connected**, or a button **Pair this Mac (…) again**): Local labs are on, and this Mac was paired before. Continue with E1; in E3 only check the state.
- **No "Computers & labs" tab, or the tab shows none of the above**: Local labs are not on for this seat yet. That is not a fault. Tell the person plainly: "Your Bot works on our server; running Bots on this Mac is switched on per seat, and Matěj will tell you when yours is on." Skip to Part G (write `E local labs: not on for this seat`). Install nothing from Part E.

**E1. Plans and sign-ins (the person's decision).** Local labs need the person's own plan: **ChatGPT Plus** (for Codex) and/or **Claude Pro** (for Claude Code), about USD 20/month each. Both are recommended; one is enough to start. If they have neither, stop Part E here and say so in the report; buying a plan is their decision, never yours.

**E2. Run our setup guide at its pinned version.** Ask before cloning, then:

```bash
mkdir -p ~/Developer && cd ~/Developer
git clone https://github.com/m-check1B/agent-jack-setup.git
cd agent-jack-setup && git checkout v1.1.1
```

Read its `AGENTS.md`, then follow its **`SETUP-PROMPT.md`** (macOS) from step 0 **up to and including the doctor at the end of its step 4, then stop and come back here**. E3 and E4 below replace its steps 6 and 7. Skip its steps 6b and 8 (browser extensions, phone app): they are not part of this guide. Notes for the steps you do run:
- Its step 0 (backup) counts as done if the person already confirmed a backup in Part 0; still run its disk check.
- Its step 5 (the Agent Jack app) is already done in Part D; just confirm D3 and D4 still pass.
- Its step 4 installs Codex CLI, Claude Code CLI, T3 Code (Beta), Tentacles and estate-guardian with `bin/install.sh all`. Ask first. The person signs in themselves (`codex login`, `claude auth login`) and opens T3 Code (Beta) once; if macOS asks to confirm opening an app from the internet, the person confirms it.
- Each FAIL has its fix in that repo's `REPAIR.md`. If the fix there does not work, stop and go to Part G.

- **Check:** `bin/doctor.sh` ends with **0 FAIL**. A WARN for the plan they don't have is fine.

**E3. Pair this Mac.** In the desktop app: **Settings → Computers & labs → Pair this Mac (…) so agents can use its labs** (the brackets hold this Mac's name). The person confirms the prompt themselves. If the Mac is already **Paired · ready** or **Connected**, skip the button and go to the check.
- **Check:** the Mac shows **Paired · ready** or **Connected**.
- **If it fails:** use the repair button the app shows (for example **Pair this Mac (…) again**) once. Still failing: stop and go to Part G with the state the app shows.

**E4. One Bot on Local.** In the app the person opens a Bot → gear → **Engine** → **Select (Advanced)** → **Lab**: the option starting with **Local · Codex** (with ChatGPT Plus) or **Local · Claude Code** (with Claude Pro) → **Model**: leave the one it offers → **Apply**. Then they type `Co umíš?` (or "What can you do?") in that Bot.
- **Check:** the Bot answers, and the line under the answer reads **Ran on Local · …** (Codex or Claude Code), so it ran on this Mac.
- **No Engine / Lab choice under the gear:** this seat cannot pick a lab yet. Write `E4 Local Bot: no Lab picker` in the report; it is not a fault on the Mac.
- **If it fails:** run `bin/doctor.sh` once more and fix any FAIL with `REPAIR.md`; still no answer: switch the Bot back to **Server** so the person can keep working, and go to Part G.

That is the full Agent Jack on this Mac.

---

## F. Update later

```bash
defaults read "/Applications/Agent Jack.app/Contents/Info" CFBundleShortVersionString
```

- The desktop app updates itself; when it offers a restart to update, the person accepts.
- After an update, repeat checks C1 and D4 (with Local labs also E3 and E4).
- Local labs: never update them yourself. When this file names a newer `agent-jack-setup` tag, check it out and run its `bin/doctor.sh`; it says what to update.
- Newer instructions: the current version of this file is always public at `https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md` (raw: `https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/AGENTS.md`). Fetch it and follow it instead of an older copy.

---

## G. The report (always end with it)

Print this block, filled in (C1 also covers the seat B2; D1 covers downloads B3), for the person to paste into a reply to our welcome e-mail. No passwords, codes, e-mail addresses, or paths with their name (write the home folder as `~`).

```
AGENT JACK SETUP REPORT
date:                 <date>
mac:                  <chip>, <RAM> GB RAM, macOS <version>, <free disk> free
A checks:             OK / WARN (<which>) / STOP (<which>)
B1 AGENTS.md saved:   OK / FAIL
C1 web sign-in:       OK / FAIL (<what they saw>)
C2 engine:            starter / own key / FAIL (<message, never the key>)
D1 downloads listed:  OK / FAIL (<message>)
D2 hash matches:      OK / FAIL
D3 app installed:     OK (<version>) / FAIL (<message>)
D4 app sign-in + Bot: OK / FAIL (<message>)
E local labs:         not on for this seat / on
E2 DOCTOR:            <setup tag>, <n> PASS / <n> WARN (<which>) / <n> FAIL (<which>) / not run
E3 pair:              Paired · ready / FAIL (<state the app shows>) / not tried
E4 Local Bot:         Ran on Local · Codex / Ran on Local · Claude Code / no Lab picker / FAIL / not tried
notes:                <anything slow, odd or confusing>
```

**When stuck:** the person replies to the welcome e-mail from Matěj with this report and says at which step they stopped.
