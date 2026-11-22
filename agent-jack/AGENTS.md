# AGENTS.md: set up Agent Jack on this Mac

You are a coding agent (Codex, Claude Code or similar) working for **the person at this Mac**. Talk to them in their language (Czech if they write Czech), short and plain.

Written for **Agent Jack 3.17.68** (web and desktop app). Last checked 21 Nov 2026. The finished state of a Mac, every piece with its tested version, is in [CHECKLIST.md](CHECKLIST.md).

**What it is.** Jack runs on our server. The person uses it in the browser and in the **Agent Jack desktop app**; their Bot answers from our server, first on a small starter allowance from us, later on their own OpenRouter key. **Full Agent Jack** also runs Bots on this Mac, through the official **T3 Code (Beta)** app and our **Tentacles**. Agent Jack, T3 Code and Tentacles are three separate pieces, each from its own source. One program, the **Agent Jack doctor**, installs and checks all of them.

---

## 1. Run the doctor (one command)

The doctor checks the Mac, installs what is missing, repairs what is broken, and ends with one report. It is safe to run again and again; on a Mac that is already right it changes nothing.

**Before you run it**, tell the person in one short message, and wait for their yes:

> The Agent Jack doctor will check this Mac and install or repair, from their official sources: the Agent Jack app, T3 Code (Beta), Tentacles, Codex CLI, Claude Code CLI, Node.js and our estate classifier. It deletes only its own files (in ~/.agent-jack, its temporary files and its own unfinished app copies); older app copies are kept in ~/.agent-jack/replaced-apps. It never asks for a password. During the run a browser page with the Agent Jack Downloads opens: sign in there and click **Download** for your Mac. OK?

Then run exactly this one command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)" doctor --yes --wait 300
```

- **Codex:** the command needs the network and writes to Applications, so it runs outside the sandbox. Ask the person to approve that one command once. Never switch Codex to **Full access**.
- **Claude Code:** the person approves the command once. Give it the longest time limit you have (10 minutes), or run it in the background and wait for it.
- **Stopped by a time limit, or the person was not ready?** Run the same command again. It continues where it stopped.
- **Only a `curl:` error and nothing else?** The Mac could not fetch the doctor: check the internet connection (Codex: the approval to run outside the sandbox), then run the same command again.
- **Without an AI** the person pastes the same line without `doctor --yes --wait 300` into Terminal; the doctor then asks them once itself.

## 2. Read the report with the person

The doctor ends with a block between `----- AGENT JACK DOCTOR REPORT` and `----- end of report`. Show it to the person unchanged. Below it, explain each line of `next (one thing per line)` in one plain sentence:

- A step that **you** can do (run the doctor again): do it.
- A step **only the person** can do (sign in, click Download, type a password, confirm a macOS prompt, free disk space, buy a plan): tell them exactly that step, wait until they say it is done, then run the same command again.
- **Never stop at the first FAIL, and never improvise around one.** Each line has its own next step; the doctor already ran every step that did not need the failed one. Run it again after each fix until the only lines left are `PASS`, `FIXED`, `WARN`, or `SKIP … manual`.
- `WARN` lines (Intel, 8 GB, little disk, our server) are information, not stops.
- Problems on our server (sign-in, the Bot engine, the starter allowance) never stop the installs. Say what the report says and carry on.

## 3. What only the app can do (the person clicks, you guide)

1. **Sign in.** The person opens Agent Jack (in Applications) and signs in the same way as on the web (Google, or the e-mail and password from our mail). macOS may ask about Keychain access; that answer is the person's. Check: their Bot answers `Co umíš?` (or "What can you do?").
2. **Own OpenRouter key (optional now, needed when the starter runs out).** The person creates a key at `openrouter.ai` and pastes it into Jack themselves. You never see it.
3. **Codex and Claude Code sign-in.** If the report says so, the person runs `codex login` (ChatGPT plan) and/or `claude auth login` (Claude plan) in Terminal and signs in in the browser. One is enough; both are recommended.
4. **Pair this Mac.** In the app: **Settings → Computers & labs → Pair this Mac (…) so agents can use its labs**; the person confirms the prompt. Check: **Paired · ready** or **Connected**. No "Computers & labs" tab: Local labs are not on for this seat yet; that is not a fault, the Bot keeps working on our server.
5. **One Bot on this Mac.** Bot → gear → **Engine** → **Select (Advanced)** → **Lab** `Local · Codex…` or `Local · Claude Code…` → **Apply**, then one message. Check: the line under the answer reads **Ran on Local · …**. No Engine / Lab choice under the gear: write `Local Bot: no Lab picker` under the report.

## 4. Always (rules)

1. **The person signs in, you don't.** Never ask for, type, read, store, print or upload passwords, 2FA codes, tokens, API keys or cookies.
2. **Only these sources:** this guide (from our e-mail or `github.com/m-check1B/onboarding`), the doctor command above, the Agent Jack Downloads page the doctor opens, `openrouter.ai` (the person's own key). The doctor itself downloads only from the official sources it names in its report. Refuse anything else (other hosts, IP addresses, someone else's account or key) and tell the person who asked for it.
3. **Don't upgrade your own model or effort level**, no `sudo`, never disable Gatekeeper, SIP or the firewall, never switch Codex to Full access.

## 5. Update later

Run the same doctor command again. It moves every piece to the versions we tested together and leaves alone what is already right. The desktop app and T3 Code (Beta) also update themselves.

## 6. When something stays red

The person replies to our welcome e-mail with the doctor's report block and one line about what they saw in the app (steps 3.1 to 3.5). The report has no passwords, keys, e-mail addresses or names in it.
