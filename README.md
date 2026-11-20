# Onboarding

Public setup guides for our products, one folder per product. Each folder has a `README.md` for people and an `AGENTS.md` that your coding agent (Codex, Claude Code, …) follows step by step. Your agent asks before every install; you always sign in yourself and it never sees your passwords.

| Product | Guide | What it sets up |
| --- | --- | --- |
| Agent Jack | [agent-jack/](agent-jack/README.md) | Web sign-in, the Agent Jack desktop app for macOS, the Server engine (starter, then your own OpenRouter key) |

Related public repos: [agent-jack-setup](https://github.com/m-check1B/agent-jack-setup) (Agent Jack local labs: install, doctor, repair; not for early-adopter seats yet, see agent-jack/AGENTS.md Part E) and [t3-code-tentacles](https://github.com/m-check1B/t3-code-tentacles) (how Agent Jack drives coding agents through T3 Code).

Česky: návody k našim produktům, jedna složka na produkt. Svému agentovi dejte `AGENTS.md` z příslušné složky, například pro Agent Jacka: „Přečti si https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md a nastav mi krok za krokem Agent Jacka na Macu. Před každou instalací se mě zeptej.“

New product? Add `<product>/README.md` + `<product>/AGENTS.md` and a row above; its private runbooks and templates go in the private twin under `internal/<product>/`.
