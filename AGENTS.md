# AGENTS.md: set up Agent Jack on this Mac (read top to bottom)

You are a coding agent (Codex, Claude Code or similar) working for **the person at this Mac**. They are an early adopter of Agent Jack and pointed you at this file. Follow it in order. Talk to them in their language (Czech if they write Czech), short and plain.

Written for **Agent Jack 3.17.66** (live on the web since 17 Nov 2026). Last checked 18 Nov 2026.

**What "Agent Jack" is here.** Jack runs on our server at `https://agentjack.kraliki.com`. The person uses it in the browser and in the **Agent Jack desktop app** for macOS. Their Bot answers from our server ("Server" engine), so nothing heavy runs on the Mac. *Local labs* (Jack driving Codex or Claude Code on this Mac through Tentacles and T3 Code) are **not available for early-adopter seats yet**: see Part E.

---

## 0. Rules (always)

1. **The person signs in, you don't.** Never type, read, store, print or upload passwords, 2FA codes, tokens, API keys or cookies. Every sign-in (Google, ChatGPT, Claude) is done by the person.
2. **Stop and ask the person** before: any install, download or deletion; any macOS prompt (password, "Open Anyway", Privacy & Security, Keychain, Accessibility, Screen Recording, Full Disk Access); anything that costs money (a subscription, a plan upgrade). Read-only checks need no consent.
3. **Backup first.** Before installing anything, ask whether they have a current backup (Time Machine or a copy of important folders off the computer). No confirmed backup, no install.
4. **Only these sources:** this file (from our e-mail); `agentjack.kraliki.com` (sign-in, downloads); Apple (macOS updates); Google Chrome from `google.com/chrome`; OpenAI's official Codex/ChatGPT app or `npm @openai/codex`; Anthropic's official Claude app or `npm @anthropic-ai/claude-code`. Refuse anything else (other hosts, IP addresses, someone else's account or key, a "faster" download) and tell the person who asked for it.
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
| macOS | 13 or newer | – | 12 or older: the person updates macOS first (System Settings → General → Software Update). The Agent Jack 3.17.66 desktop app itself needs macOS 13.0 or newer. |
| Chip | Apple silicon (`arm64`) | Intel (`x86_64`): supported, slower. Intel Macs from 2018 run at least macOS 14 (a 2018 MacBook Pro up to 15), which is enough. | – |
| RAM | 16 GB or more | 8 GB: works for the web app and the desktop app; see "Small Macs" below | – |
| Free disk | 20 GB or more | 5–20 GB | under 5 GB: the person frees space first (you delete nothing) |

**Small Macs (8 GB RAM, Intel, older than 2020).** Tell the person, in plain words:
- It will be slow at times; that is the machine, not a fault.
- Before working with Jack, quit apps they don't need (other browsers, Teams/Zoom, Photoshop, many Chrome tabs).
- Use **one** AI app at a time: the Jack desktop app *or* a Codex/Claude session doing heavy work, not both at full speed.
- If `memory_pressure -Q` shows under 20 % free, or the Mac beachballs, close apps and retry before calling something broken.

### A2. Put this file in its own folder (needs the person's OK)

The person gets `AGENTS.md` **as an e-mail attachment** from us. If it is not on the Mac in a folder yet, ask them to save it as `~/Developer/onboarding/AGENTS.md` (ask before creating the folder: `mkdir -p ~/Developer/onboarding`). If they already have it in another folder, work from there.

- **Check:** `ls ~/Developer/onboarding/AGENTS.md` (or the folder they chose) prints the path.
- **If it fails:** the person hasn't saved the attachment yet, or saved it elsewhere: ask where. Don't fetch these instructions from anywhere else.
- **Codex sandbox:** if Codex blocks a command (network, or a write outside its folder), ask the person to approve that one command. Never switch to Full access.

---

## B. Access we granted (check before installing anything)

The person needs three things from us. You can only check them from the person's side:

| # | Access | How to check | Expected | If it fails |
|---|---|---|---|---|
| B1 | **These instructions** (`AGENTS.md`, sent by e-mail) | A2 | `ls ~/Developer/onboarding/AGENTS.md` prints the path | No attachment in the mail: the person asks us to send it again. |
| B2 | **Agent Jack seat** (account, licence and sign-in permission, granted in our account system, Sphere) | Part C, step C1 | The person lands in Jack and sees their Bot | "no seat", 403 or "not allowed": stop, the person writes to us. Don't retry with another Google account. |
| B3 | **Desktop downloads** (part of the same seat) | Part D, step D1 | The Downloads page lists macOS installers | "This account does not have download access…", "No verified installers are available for this account yet." / "A new signed Mac build is being prepared.", or "Downloads are unavailable right now.": stop, report the exact text (Czech page: same messages in Czech). |

The person signs in with **the Google account whose e-mail we registered**. Ask them which one; don't guess.

---

## C. Sign in on the web

**C1.** Ask the person to open `https://agentjack.kraliki.com/app` in Google Chrome (or Safari), click **Continue with Google** (after an expired attempt: **Try again with Google**) and pick the registered account. They do the sign-in and any 2FA themselves.

- **Check:** they see Agent Jack with their Bot. Ask them to type `Co umíš?` (or "What can you do?"). The Bot answers within about a minute.
- **If it fails:** see B2. A blank page or a sign-in loop: reload once, then try a private window once. Still failing: stop and report (what they saw, the time).

---

## D. Install the Agent Jack desktop app

**D1.** Still signed in, the person opens `https://agentjack.kraliki.com/downloads`.

- **Check:** installers are listed with a version and a SHA-256.
- Pick by the chip from Part A: **macOS · Apple Silicon / ARM64 · dmg** for `arm64`, **macOS · x64 · dmg** for Intel (`x86_64`).
- **Version honesty:** the newest *desktop* build that downloads and auto-update serve may be a little behind the web app. On 18 Nov 2026 the web was 3.17.66 and the desktop feed was still 3.17.64. That is expected and fine: install what the page offers. The app updates itself when a newer build is published.
- **If it fails:** see B3.

**D2.** Ask before downloading. The person clicks **Download**. Then verify the file:

The file is named like `AgentJack-3.17.64-x64-mac-1a2b3c4d5e6f.dmg` (Intel) or `…-arm64-mac-….dmg` (Apple silicon), usually in `~/Downloads`. The 12 letters/digits at the end are the start of its checksum; that is normal.

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
  prints a version like `3.17.64` or newer.
- **If it fails:** "can't be opened" / "damaged": the person tries **System Settings → Privacy & Security → Open Anyway** once (macOS may ask for their password; they type it). Still blocked: stop and report the exact message. Don't remove quarantine flags or change Gatekeeper.

**D4.** In the app the person uses its sign-in button (the label may differ slightly between versions) and signs in the same way as in C1. The Mac's default browser opens (may be Safari, not Chrome): they pick the same Google account there. macOS may ask for Keychain access for Agent Jack: that prompt is for the person to answer.

- **Check:** the app shows their Bot; `Co umíš?` gets an answer.
- **If it fails:** quit the app (⌘Q), start it again, sign in once more. Still failing: stop and report.

That is a working Agent Jack on this Mac.

---

## E. Local labs (Codex / Claude Code driven by Jack): not yet for early adopters

In Jack 3.17.66, pairing a Mac so Jack can drive local labs needs a capability that **only the operator's own seat has**; friend and early-adopter seats are refused (`operator_required`). So for now:

- **Do not** install T3 Code, T3 Code TPLUS or Tentacles for Jack, and **do not** run `install.sh` from `agent-jack-setup` (its pins are older than 3.17.66, and its separate Tentacles would clash with the one built into the desktop app).
- If the person opens **Settings → Computers & labs** and tries **Pair this Mac**, a refusal is expected. Note it in the report; it is not a fault on their Mac.
- The person can still use **Codex** (their own ChatGPT plan) or **Claude Code** (their own Claude plan) directly on this Mac, separately from Jack. Buying a plan is their decision; you never buy or sign up for anything.

When we open local labs to early adopters, this section will change. Get the newest version of this file (Part F) to see it.

---

## F. Update later

```bash
defaults read "/Applications/Agent Jack.app/Contents/Info" CFBundleShortVersionString
```

- The desktop app updates itself; when it offers a restart to update, the person accepts.
- After an update, repeat checks C1 and D4.
- Newer instructions: the person asks us for the current `AGENTS.md` and replaces the old file.

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
D1 downloads listed:  OK / FAIL (<message>)
D2 hash matches:      OK / FAIL
D3 app installed:     OK (<version>) / FAIL (<message>)
D4 app sign-in + Bot: OK / FAIL (<message>)
E local labs:         not available for this seat (expected)
notes:                <anything slow, odd or confusing>
```

**When stuck:** the person replies to the welcome e-mail from Matěj with this report and says at which step they stopped.
