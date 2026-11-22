# Onboarding

Public setup guides for our products, one folder per product. Each folder has a `README.md` for people and an `AGENTS.md` for your coding agent (Codex, Claude Code, …). You always sign in yourself and nobody sees your passwords.

| Product | Guide | What it sets up |
| --- | --- | --- |
| Agent Jack | [agent-jack/](agent-jack/README.md) | One command, the Agent Jack doctor: the desktop app for macOS and Local labs on your Mac (Codex / Claude Code, T3 Code (Beta), Tentacles); then web sign-in and the Server engine (starter, then your own OpenRouter key) |

For Agent Jack, [agent-jack/CHECKLIST.md](agent-jack/CHECKLIST.md) lists what a finished Mac has installed, at which tested version, and how to check each piece.

Related public repos: [agent-jack-setup](https://github.com/m-check1B/agent-jack-setup) (the tested versions the doctor reads; Windows setup) and [t3-code-tentacles](https://github.com/m-check1B/t3-code-tentacles) (how Agent Jack drives coding agents through T3 Code).

Česky: návody k našim produktům, jedna složka na produkt. Pro Agent Jacka na Macu stačí do Terminálu vložit jeden řádek z [agent-jack/README.md](agent-jack/README.md) (Agent Jack doctor), nebo agentovi říct: „Přečti si https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md a nastav mi Agent Jacka na Macu jeho doctorem.“

New product? Add `<product>/README.md` + `<product>/AGENTS.md` and a row above; its private runbooks and templates go in the private twin under `internal/<product>/`.
