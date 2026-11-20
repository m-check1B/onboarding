# Onboarding

Public setup guides for our products, one folder per product. Each folder has a `README.md` for people and an `AGENTS.md` that your coding agent (Codex, Claude Code, …) follows step by step. Your agent asks before every install; you always sign in yourself and it never sees your passwords.

| Product | Guide | What it sets up |
| --- | --- | --- |
| Agent Jack | [agent-jack/](agent-jack/README.md) | Web sign-in, the Agent Jack desktop app for macOS, the Server engine (starter, then your own OpenRouter key), and Local labs on your Mac (Codex / Claude Code, T3 Code (Beta), Tentacles) |

Related public repos: [agent-jack-setup](https://github.com/m-check1B/agent-jack-setup) (Agent Jack Local labs: install, doctor, repair; agent-jack/AGENTS.md Part E runs it) and [t3-code-tentacles](https://github.com/m-check1B/t3-code-tentacles) (how Agent Jack drives coding agents through T3 Code).

Česky: návody k našim produktům, jedna složka na produkt. Svému agentovi dejte `AGENTS.md` z příslušné složky, například pro Agent Jacka: „Přečti si https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md a nastav mi krok za krokem Agent Jacka na Macu. Před každou instalací se mě zeptej.“

New product? Add `<product>/README.md` + `<product>/AGENTS.md` and a row above; its private runbooks and templates go in the private twin under `internal/<product>/`.
