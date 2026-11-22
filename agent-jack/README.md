# Agent Jack onboarding

**Early adopter?** This is the public setup guide for Agent Jack. On your Mac, paste this one line into Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)"
```

The **Agent Jack doctor** checks your Mac, installs what is missing (the Agent Jack app, the official T3 Code (Beta), our Tentacles, Codex CLI, Claude Code CLI), repairs what is broken and ends with one report. It asks you once at the start, never asks for a password, deletes only its own files (older app copies are kept in ~/.agent-jack/replaced-apps), and is safe to run again. You sign in yourself; nobody sees your passwords.

Prefer your coding agent (Codex, Claude Code, …)? Tell it:

> Read https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md and set up Agent Jack on my Mac with its doctor.

What a finished Mac looks like, piece by piece with the exact versions we tested, is in [CHECKLIST.md](CHECKLIST.md). When something stays red, reply to the welcome e-mail with the report the doctor prints at the end.

Related public repos: [agent-jack-setup](https://github.com/m-check1B/agent-jack-setup) (the tested versions in `versions.env`; Windows setup) and [t3-code-tentacles](https://github.com/m-check1B/t3-code-tentacles) (how Jack drives coding agents through T3 Code).

Česky: Na Macu vložte do Terminálu řádek výše. Agent Jack doctor zkontroluje Mac, nainstaluje, co chybí, opraví, co nefunguje, a na konci vypíše jeden report; zeptá se jednou na začátku a nikdy nechce heslo. Raději se svým agentem? Řekněte mu: „Přečti si https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md a nastav mi Agent Jacka na Macu jeho doctorem.“ Přihlašujete se vždy sami. Cílový stav Macu je v [CHECKLIST.md](CHECKLIST.md).
