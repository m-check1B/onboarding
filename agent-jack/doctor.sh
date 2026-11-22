#!/bin/bash
# Agent Jack doctor for macOS (KRA-10893). One run checks this Mac, installs what is missing, repairs what is
# broken and ends with one report. Safe to run again: on a Mac that is already right it changes nothing.
#   Terminal:  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)"
#   Options:   --yes (the person already agreed)  --check (change nothing)  --lang cs|en  --wait <seconds>
# Written for /bin/bash 3.2 and the tools macOS ships (curl, shasum, tar, hdiutil, ditto, plutil, defaults).
# No sudo, no Gatekeeper change, no secret is ever asked for, read or printed. Home is shown as ~.
# No `set -e` on purpose: a failed step is recorded and every step that does not need it still runs.
set -u
umask 022

DOCTOR_VERSION=2026.11.21.4       # bump with every change: a pasted script cannot know its commit (B3 P3-15)
JACK_HOST=agentjack.kraliki.com   # the one place the Agent Jack host is named (KRA-10094: moves before 25 Dec 2026)
DOCTOR_BASE=https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack   # the doctor, the lock and the pins copy
JACK_BUNDLE_ID=com.verduona.agentjack
JACK_TEAM_ID=QAF65J7554           # Developer ID Application: Verduona s.r.o.
# fixed, never read from a download: the pins may only agree with them (B3 P2-1)
T3_APP_NAME="T3 Code (Beta)"; T3_ID=com.t3tools.t3code
T3_LEGACY="T3 Code TPLUS|T3 Code (Alpha)"; T3_LEGACY_IDS=" com.t3tools.t3code com.verduona.t3code-tplus "   # only these move aside
APPS_SYS="${AJ_APPS:-/Applications}"   # AJ_APPS: tests only (a fake Applications folder)

YES=0; CHECK=0; UI=""; WAIT=600
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) YES=1 ;; --check) CHECK=1 ;;
    --lang) UI="${2:-}"; shift ;;
    --wait) WAIT="${2:-600}"; shift ;;
    -h|--help) echo "Agent Jack doctor $DOCTOR_VERSION. Options: --yes (the person already agreed)  --check (change nothing)  --lang cs|en  --wait <seconds>"; exit 0 ;;
    doctor) ;;   # $0 placeholder when started as: bash -c "$(curl …)" doctor --yes
    *) echo "unknown option: $1 (use --yes, --check, --lang cs|en, --wait <seconds>)" >&2; exit 2 ;;
  esac
  shift
done
case "$WAIT" in ''|*[!0-9]*) WAIT=600 ;; esac

# ---------- language ----------
if [ -z "$UI" ]; then UI="${AJ_LANG:-}"; fi
if [ -z "$UI" ]; then
  loc="$(defaults read -g AppleLocale 2>/dev/null || true)"; [ -n "$loc" ] || loc="${LANG:-}"
  case "$loc" in cs*|CS*) UI=cs ;; *) UI=en ;; esac
fi
[ "$UI" = cs ] || UI=en

# ---------- messages: code | sentence (en) | next (en) | sentence (cs) | next (cs) ----------
msgtab() {
cat <<'EOF'
AJ-OS-01|This doctor is for macOS only.|Run it on the Mac you want to set up.|Tento doctor je jen pro macOS.|Spusťte ho na Macu, který chcete nastavit.
AJ-ENV-02|HOME is unset or not a folder path in this window, so the doctor checked and changed nothing.|Open a new Terminal window from the Dock and run the doctor again.|V tomto okně není nastavená proměnná HOME nebo to není cesta ke složce, proto doctor nic nezkontroloval ani nezměnil.|Otevřete nové okno Terminálu z Docku a spusťte doctor znovu.
AJ-DOC-02|Another Agent Jack doctor is already running on this Mac, so this one changed nothing.|Wait a minute and run the doctor again; if this line comes back, restart the Mac.|Na tomto Macu už běží jiný Agent Jack doctor, proto tento nic nezměnil.|Počkejte minutu a spusťte doctor znovu; když se tento řádek vrátí, restartujte Mac.
AJ-SYS-01|macOS is older than 14; T3 Code (Beta) and the Agent Jack app need 14 or newer, so they were not installed.|Update macOS in System Settings → General → Software Update, then run the doctor again.|macOS je starší než 14; T3 Code (Beta) a aplikace Agent Jack potřebují 14 nebo novější, proto se nenainstalovaly.|Aktualizujte macOS v Nastavení systému → Obecné → Aktualizace softwaru a spusťte doctor znovu.
AJ-SYS-02|This is an Intel Mac: everything works, a little slower.|Nothing to do.|Tento Mac má procesor Intel: vše funguje, jen pomaleji.|Není potřeba nic dělat.
AJ-HW-01|This Mac has less than 16 GB of memory: it works, but keep few apps open.|Quit the apps you don't need while you work with Jack.|Tento Mac má méně než 16 GB paměti: funguje, ale nechte otevřených málo aplikací.|Při práci s Jackem zavřete aplikace, které nepotřebujete.
AJ-DISK-01|Less than 20 GB is free; the install fits, but space is tight.|When you can, empty the Trash or move large files off this Mac.|Volných je méně než 20 GB; instalace se vejde, ale místa je málo.|Až budete moct, vysypte Koš nebo přesuňte velké soubory mimo tento Mac.
AJ-DISK-02|Less than 5 GB is free, so nothing was downloaded or installed.|Free at least 5 GB yourself (empty the Trash, move large files), then run the doctor again.|Volných je méně než 5 GB, proto se nic nestahovalo ani neinstalovalo.|Uvolněte sami aspoň 5 GB (vysypte Koš, přesuňte velké soubory) a spusťte doctor znovu.
AJ-TMP-01|The doctor could not make its temporary folder (the line names where), so nothing was downloaded or installed.|Open a new Terminal window and run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Doctor nemohl vytvořit svou dočasnou složku (řádek uvádí kde), proto se nic nestáhlo ani nenainstalovalo.|Otevřete nové okno Terminálu a spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-DOC-01|The doctor runs inside a sandbox without network, so it cannot download anything.|Approve this one command to run outside the sandbox (Codex asks once); never switch to Full access.|Doctor běží v sandboxu bez sítě, a proto nemůže nic stáhnout.|Schvalte spuštění tohoto jednoho příkazu mimo sandbox (Codex se zeptá jednou); na Full access nepřepínejte.
AJ-NET-01|The doctor cannot reach github.com from here, so nothing was downloaded.|If an AI app runs this command in a sandbox, allow network for this one command; otherwise connect to the internet. Then run the doctor again.|Doctor se odsud nedostane na github.com, proto se nic nestáhlo.|Když tento příkaz spouští AI aplikace v sandboxu, povolte pro něj síť; jinak se připojte k internetu. Pak spusťte doctor znovu.
AJ-PIN-01|A tested-version value this step needs is missing, out of step or not safe to use, so this step installed nothing (the line names the value).|Run the doctor again in a few minutes; if this line comes back, reply to our welcome e-mail with this report.|Hodnota ověřené verze, kterou tento krok potřebuje, chybí, nesouhlasí nebo není bezpečná, proto tento krok nic neinstaloval (řádek ji jmenuje).|Spusťte doctor za pár minut znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-SRV-01|Our Agent Jack server reports a fault; that is on our side and did not stop the install.|Nothing for you to do; if your Bot does not answer later, reply to our welcome e-mail with this report.|Náš server Agent Jack hlásí poruchu; je na naší straně a instalaci nezastavila.|Nemusíte nic dělat; když vám Bot později neodpoví, pošlete tento report v odpovědi na uvítací e-mail.
AJ-NODE-01|Node.js (needed by Codex, Claude Code and Tentacles) could not be installed.|Run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Node.js (potřebují ho Codex, Claude Code a Tentacles) se nepodařilo nainstalovat.|Spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-PATH-01|Your login profile could not be changed, so apps started from the Dock may not find Codex, Claude Code or Tentacles.|Add this line to ~/.zprofile yourself: export PATH="$HOME/.agent-jack/node/bin:$PATH"|Váš přihlašovací profil nešel upravit, takže aplikace spuštěné z Docku nemusí najít Codex, Claude Code ani Tentacles.|Přidejte sami do ~/.zprofile tento řádek: export PATH="$HOME/.agent-jack/node/bin:$PATH"
AJ-CODEX-01|Codex CLI could not be installed.|Run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Codex CLI se nepodařilo nainstalovat.|Spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-CODEX-02|An older Codex CLI elsewhere on this Mac comes first (the line says which version).|Remove or update that older copy, then run the doctor again.|Jinde na Macu je starší Codex CLI a má přednost (řádek uvádí verzi).|Starší kopii odstraňte nebo aktualizujte a spusťte doctor znovu.
AJ-CLAUDE-01|Claude Code CLI could not be installed.|Run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Claude Code CLI se nepodařilo nainstalovat.|Spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-CLAUDE-02|An older Claude Code elsewhere on this Mac comes first (the line says which version).|Run: claude update, then run the doctor again.|Jinde na Macu je starší Claude Code a má přednost (řádek uvádí verzi).|Spusťte: claude update a pak znovu doctor.
AJ-CODEX-03|Neither Codex nor Claude Code is signed in, so no Bot can work on this Mac yet.|Sign in yourself in Terminal: codex login (ChatGPT plan) or claude auth login (Claude plan).|Nejste přihlášeni ani do Codexu, ani do Claude Code, takže na tomto Macu zatím žádný Bot pracovat nemůže.|Přihlaste se sami v Terminálu: codex login (předplatné ChatGPT) nebo claude auth login (předplatné Claude).
AJ-CODEX-04|Codex is not signed in (Claude Code is, which is enough).|Optional: run codex login in Terminal and sign in yourself.|Codex není přihlášený (Claude Code ano, a to stačí).|Volitelně: v Terminálu spusťte codex login a přihlaste se sami.
AJ-CLAUDE-04|Claude Code is not signed in (Codex is, which is enough).|Optional: run claude auth login in Terminal and sign in yourself.|Claude Code není přihlášený (Codex ano, a to stačí).|Volitelně: v Terminálu spusťte claude auth login a přihlaste se sami.
AJ-ENV-01|An ANTHROPIC_* variable replaces your Claude sign-in (the line says where it is set: a shell file, or (env) for this window only; never the value).|For a file: put a # in front of that line in that file yourself. For (env): open a new Terminal window from the Dock, not from the app that set it. Then run the doctor again.|Proměnná ANTHROPIC_* nahrazuje vaše přihlášení do Claude (řádek uvádí, kde je nastavená: soubor shellu, nebo (env) jen pro toto okno; nikdy hodnotu).|U souboru: dejte sami před ten řádek znak #. U (env): otevřete nové okno Terminálu z Docku, ne z aplikace, která ji nastavila. Pak spusťte doctor znovu.
AJ-T3-03|T3 Code (Beta) could not be downloaded or put in place; any copy you had is unchanged.|Run the doctor again.|T3 Code (Beta) se nepodařilo stáhnout nebo umístit; případná dosavadní kopie zůstala beze změny.|Spusťte doctor znovu.
AJ-T3-04|The T3 Code (Beta) download does not match its checksum or its makers' app id, so it was not installed.|Run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Stažené T3 Code (Beta) neodpovídá kontrolnímu součtu nebo identifikátoru aplikace od autorů, proto se neinstalovalo.|Spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-T3-07|An older T3 Code app could not be moved aside (the line names it).|Quit that app (⌘Q), then run the doctor again.|Starší aplikaci T3 Code nešlo odsunout stranou (řádek ji jmenuje).|Ukončete tu aplikaci (⌘Q) a spusťte doctor znovu.
AJ-T3-08|The T3 Code app on this Mac is not the official one, so the doctor left it alone.|Reply to our welcome e-mail with this report.|Aplikace T3 Code na tomto Macu není oficiální, proto ji doctor nechal být.|Pošlete tento report v odpovědi na uvítací e-mail.
AJ-T3-09|T3 Code (Beta) updated itself past the version we tested; that is expected.|Nothing to do.|T3 Code (Beta) se samo aktualizovalo nad verzi, kterou jsme ověřili; to je v pořádku.|Není potřeba nic dělat.
AJ-T3-11|An older T3 Code (Beta) in Applications belongs to another account and this account cannot replace it; it was left whole.|Ask the Mac's administrator to remove or update "T3 Code (Beta)" in Applications, then run the doctor again.|Starší T3 Code (Beta) v Aplikacích patří jinému účtu a tento účet ho nemůže nahradit; zůstalo celé.|Požádejte správce Macu, ať „T3 Code (Beta)“ v Aplikacích odstraní nebo aktualizuje, a spusťte doctor znovu.
AJ-T3-12|The new T3 Code (Beta) could not be put in place and the previous copy could not be moved back; it is kept, hidden, where the line says.|Run the doctor again: it puts the previous copy back first.|Nové T3 Code (Beta) nešlo umístit a předchozí kopii nešlo vrátit zpět; je uschovaná skrytě tam, kde uvádí řádek.|Spusťte doctor znovu: nejdřív vrátí předchozí kopii na místo.
AJ-TENT-01|Tentacles could not be installed.|Run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Tentacles se nepodařilo nainstalovat.|Spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-TENT-02|Another Tentacles comes first on this Mac (the line says which version).|Reply to our welcome e-mail with this report; do not remove it by hand.|Na tomto Macu má přednost jiné Tentacles (řádek uvádí verzi).|Pošlete tento report v odpovědi na uvítací e-mail; ručně ho neodstraňujte.
AJ-TENT-03|Tentacles is not signed in to T3 Code (Beta) yet.|Open T3 Code (Beta), wait until Settings → Providers shows Codex or Claude Code ready, then run the doctor again.|Tentacles ještě není přihlášené do T3 Code (Beta).|Otevřete T3 Code (Beta), počkejte, až Nastavení → Providers ukáže Codex nebo Claude Code připravené, a spusťte doctor znovu.
AJ-TENT-04|Tentacles runs but does not offer Local Talk with this T3 Code.|Reply to our welcome e-mail with this report.|Tentacles běží, ale s tímto T3 Code nenabízí Local Talk.|Pošlete tento report v odpovědi na uvítací e-mail.
AJ-TENT-05|T3 Code (Beta) did not start, so Tentacles could not sign in to it.|Open T3 Code (Beta) from Applications yourself (confirm Open if macOS asks), then run the doctor again.|T3 Code (Beta) se nespustilo, takže se do něj Tentacles nemohlo přihlásit.|Otevřete sami T3 Code (Beta) z Aplikací (když se macOS zeptá, potvrďte Otevřít) a spusťte doctor znovu.
AJ-PY-01|Python 3.11 or newer is missing, so the estate classifier was not installed.|Install Python 3.12 from https://www.python.org/downloads/macos/ yourself (you type your password), then run the doctor again.|Chybí Python 3.11 nebo novější, proto se klasifikátor nenainstaloval.|Nainstalujte sami Python 3.12 z https://www.python.org/downloads/macos/ (heslo zadáte vy) a spusťte doctor znovu.
AJ-EC-01|The estate classifier could not be installed.|Run the doctor again; if this line comes back, reply to our welcome e-mail with this report.|Klasifikátor se nepodařilo nainstalovat.|Spusťte doctor znovu; když se tento řádek vrátí, pošlete tento report v odpovědi na uvítací e-mail.
AJ-JACK-01|The Agent Jack app is not installed and its download is not in Downloads yet.|On the Agent Jack Downloads page (the doctor opens it in a repair run, with --yes), sign in and click Download for this Mac, then run the doctor again.|Aplikace Agent Jack není nainstalovaná a její stažený soubor zatím ve Stažených souborech není.|Na stránce Stažení Agent Jacka (doctor ji otevře při opravě, tedy s --yes) se přihlaste a klikněte na Stáhnout pro tento Mac; pak spusťte doctor znovu.
AJ-JACK-02|The Agent Jack app is older than this setup needs and no newer download is in Downloads.|On the Agent Jack Downloads page (the doctor opens it in a repair run, with --yes), sign in and click Download for this Mac, then run the doctor again.|Aplikace Agent Jack je starší, než toto nastavení potřebuje, a novější stažený soubor ve Stažených souborech není.|Na stránce Stažení Agent Jacka (doctor ji otevře při opravě, tedy s --yes) se přihlaste a klikněte na Stáhnout pro tento Mac; pak spusťte doctor znovu.
AJ-JACK-03|The Agent Jack download is damaged or failed the signature check (codesign and Gatekeeper), so it was not installed.|Delete that file from Downloads yourself, download it once more from the Agent Jack Downloads page, then run the doctor again.|Stažený Agent Jack je poškozený nebo neprošel kontrolou podpisu (codesign a Gatekeeper), proto se neinstaloval.|Smažte sami ten soubor ze Stažených souborů, stáhněte ho ještě jednou ze stránky Stažení Agent Jacka a spusťte doctor znovu.
AJ-JACK-05|The Agent Jack download is for the other kind of Mac chip.|On the Downloads page, pick the download for this chip (the line names it), then run the doctor again.|Stažený Agent Jack je pro jiný typ čipu Macu.|Na stránce Stažení vyberte verzi pro tento čip (řádek ho uvádí) a spusťte doctor znovu.
AJ-JACK-06|The Agent Jack app could not be put in place; any copy you had is unchanged.|Quit Agent Jack (⌘Q), then run the doctor again.|Aplikaci Agent Jack nešlo umístit; případná dosavadní kopie zůstala beze změny.|Ukončete Agent Jack (⌘Q) a spusťte doctor znovu.
AJ-JACK-07|The new Agent Jack app could not be put in place and the previous copy could not be moved back; it is kept, hidden, where the line says.|Quit Agent Jack (⌘Q), then run the doctor again: it puts the previous copy back first.|Novou aplikaci Agent Jack nešlo umístit a předchozí kopii nešlo vrátit zpět; je uschovaná skrytě tam, kde uvádí řádek.|Ukončete Agent Jack (⌘Q) a spusťte doctor znovu: nejdřív vrátí předchozí kopii na místo.
AJ-CHROME-01|Google Chrome is not installed; you only need it for the optional browser extensions.|If you want them, install Chrome from https://www.google.com/chrome yourself.|Google Chrome není nainstalovaný; potřebujete ho jen pro volitelná rozšíření prohlížeče.|Pokud je chcete, nainstalujte si Chrome sami z https://www.google.com/chrome.
AJ-SETUP-01|An older setup folder (~/Developer/agent-jack-setup) could not be updated; the doctor does not need it.|Nothing to do; you may delete that folder yourself.|Starší složku nastavení (~/Developer/agent-jack-setup) nešlo aktualizovat; doctor ji nepotřebuje.|Není potřeba nic dělat; složku můžete sami smazat.
AJ-PAIR-00|Pairing is checked in the Agent Jack app, not by the doctor.|In Agent Jack: Settings → Computers & labs → Pair this Mac, and confirm the prompt yourself.|Spárování se kontroluje v aplikaci Agent Jack, ne doctorem.|V Agent Jackovi: Nastavení → Computers & labs → Pair this Mac a výzvu potvrďte sami.
AJ-LOCAL-00|A Bot on this Mac is checked in the Agent Jack app, not by the doctor.|In Agent Jack: Bot → gear → Engine → Select (Advanced) → Lab Local · Codex or Local · Claude Code → Apply, then send one message.|Bot na tomto Macu se kontroluje v aplikaci Agent Jack, ne doctorem.|V Agent Jackovi: Bot → ozubené kolečko → Engine → Select (Advanced) → Lab Local · Codex nebo Local · Claude Code → Apply a pošlete jednu zprávu.
EOF
}
# field 2 = sentence, 3 = next action (English); 4 and 5 the same in Czech
msg() { local f=2; [ "$UI" = cs ] && f=4; [ "${2:-}" = next ] && f=$((f+1)); msgtab | awk -F'|' -v c="$1" -v f="$f" '$1==c{print $f; exit}'; }
# a stop before the report: one line with the code, the sentence and the one action (B3 round 3 P3-2)
stop_line() { printf 'FAIL %s %s → %s\n' "$1" "$(msg "$1")" "$(msg "$1" next)"; }
case "${HOME:-}" in /*) ;; *) stop_line AJ-ENV-02 >&2; exit 2 ;; esac   # before any path is built from it
APPS_HOME="$HOME/Applications"
AJ="$HOME/.agent-jack"
TILDE='~'

# ---------- report ----------
REPORT=""; FAILS=0; WARNS=0
say() { printf '%s\n' "$*"; }
step() { say "· $*"; }
nohome() { sed "s#$HOME#~#g"; }   # never print the home path (it holds the user name)
rec() { # status code component detail
  local d; d="$(printf '%s' "$4" | nohome)"
  [ "$1" = FAIL ] && FAILS=$((FAILS+1)); [ "$1" = WARN ] && WARNS=$((WARNS+1))
  REPORT="$REPORT$1|$2|$3|$d
"
  printf '  %-5s %-12s %s %s\n' "$1" "$2" "$3" "$d"
}
# needs: each flag is "" (ok) or the code that failed; prints the first failed code
OS_OK=""; DISK_OK=""; NET_OK=""; PINS_OK=""; NODE_OK="AJ-NODE-01"; T3_OK="AJ-T3-03"; TENT_OK="AJ-TENT-01"
needs() { local v; for v in "$@"; do [ -n "$v" ] && { echo "$v"; return 1; }; done; return 0; }
skip() { rec SKIP "$1" "$2" "$( [ "$UI" = cs ] && echo "čeká na $1" || echo "waits for $1")"; }

# ---------- small tools ----------
ver() { "$@" 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[-A-Za-z0-9.]*' | head -1; }
ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }   # $1 >= $2
plist_ver() { defaults read "$1/Contents/Info" CFBundleShortVersionString 2>/dev/null; }
plist_id() { defaults read "$1/Contents/Info" CFBundleIdentifier 2>/dev/null; }
json_get() { plutil -extract "$2" raw -o - "$1" 2>/dev/null; }   # file key (dotted); plutil ships with macOS
fetch() { curl -fsSL --proto '=https' --connect-timeout 20 --speed-limit 1024 --speed-time 60 -o "$2" "$1" 2>/dev/null; }
sha256() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; }
ts() { date +%Y%m%d%H%M%S; }
app_path() { local n d; for n in "$@"; do for d in "$APPS_SYS" "$APPS_HOME"; do [ -d "$d/$n.app" ] && { echo "$d/$n.app"; return; }; done; done; }
quit_app() { osascript -e 'on run a' -e 'quit app (item 1 of a)' -e 'end run' "$1" >/dev/null 2>&1 || true; }   # the name is an argument, never script text
# Every rm -rf goes through rmrf (B3 P1): only below ~/.agent-jack (never the parked apps in replaced-apps), the temp
# folder this run made, or a hidden staged copy (.<name>-aj-new-<pid>.app) this doctor names itself in an Applications
# folder. Refused too: "..", a trailing /, and a link in any part of the path below ~/.agent-jack (B3 P3-2).
nolink() { local q="$1"; while :; do case "$q" in "$AJ"/*) [ -L "$q" ] && return 1; q="${q%/*}" ;; *) return 0 ;; esac; done; }
rmrf() { local p ok; for p in "$@"; do ok=0
    case "$p" in *..*|*/|"$AJ"/replaced-apps|"$AJ"/replaced-apps/*) ;; "$AJ"/?*) ok=1 ;; "$APPS_SYS"/.*-aj-new-*.app|"$APPS_HOME"/.*-aj-new-*.app) ok=1 ;; esac
    [ -n "$TMPD" ] && case "$p" in *..*|*/) ;; "$TMPD"|"$TMPD"/*) ok=1 ;; esac
    [ $ok = 1 ] && ! nolink "$p" && ok=0
    if [ $ok = 1 ]; then rm -rf "$p"; else say "  note: refused to delete ${p/#"$HOME"/$TILDE}"; fi
  done; }
# a pin or lock value that becomes part of a path or URL: letters, digits, . + - only; no slash, no "..", no leading . or -
safe() { case "$1" in ""|*/*|*..*|.*|-*|*[!A-Za-z0-9.+-]*) return 1 ;; esac; }
safe_name() { case "$1" in ""|*/*|*..*|.*|-*|*[!A-Za-z0-9.+\ \(\)-]*) return 1 ;; esac; }   # app names: also a space and ( )
hex() { case "$1" in *[!0-9a-f]*) return 1 ;; esac; [ ${#1} = "$2" ]; }
ourgh() { case "$1" in https://github.com/m-check1B/*) safe "${1#https://github.com/m-check1B/}" ;; *) return 1 ;; esac; }   # our repos only
park() { # $1 = a bundle that was moved aside; keep it, never delete it
  mkdir -p "$AJ/replaced-apps" && mv "$1" "$AJ/replaced-apps/$2-$(ts).app" 2>/dev/null && return 0
  say "  note: the previous copy stays next to the new one as ${1/#"$HOME"/$TILDE}"
}
# KRA-10943: move aside, move in, move back on failure. $1 = staged new bundle in the same folder as $2.
# Returns 0 in place, 3 = the old copy cannot be moved (left whole), 4 = new copy failed (old copy restored),
# 5 = new copy failed and the old copy could not be moved back (SWAP_LEFT names where it is), 6 = new copy failed
# and there was no old copy (B3 P3-8).
SWAP_APP=""; SWAP_OLD=""; SWAP_NEW=""; SWAP_LEFT=""
swap_done() { SWAP_APP=""; SWAP_OLD=""; SWAP_NEW=""; }
swap_in() {
  local new="$1" app="$2" old=""
  if [ -e "$app" ]; then
    old="$(dirname "$app")/.$(basename "$app" .app)-aj-old-$$.app"; SWAP_APP="$app"; SWAP_OLD="$old"
    mv "$app" "$old" 2>/dev/null || { swap_done; rmrf "$new"; return 3; }
  fi
  if mv "$new" "$app" 2>/dev/null; then
    swap_done; [ -z "$old" ] || park "$old" "$(basename "$app" .app)"
    return 0
  fi
  [ -n "$old" ] || { swap_done; rmrf "$new"; return 6; }
  if mv "$old" "$app" 2>/dev/null; then swap_done; rmrf "$new"; return 4; fi
  swap_done; rmrf "$new"; SWAP_LEFT="${old/#"$HOME"/$TILDE}"; return 5
}
# the same for the doctor's own folders (Node, Tentacles; B3 P3-3): $1 new folder, $2 target. 0 = in place; then the
# caller ends with dir_done (keep) or dir_back (undo); until then a signal undoes it too
dir_in() { SWAP_APP="$2"; SWAP_OLD=""; SWAP_NEW="$1"
  if [ -e "$2" ]; then SWAP_OLD="$2.aj-old-$$"; mv "$2" "$SWAP_OLD" 2>/dev/null || { SWAP_OLD=""; dir_back; return 1; }; fi
  mv "$1" "$2" 2>/dev/null || { dir_back; return 1; }
  SWAP_NEW="$2"; }
dir_back() { [ -z "$SWAP_NEW" ] || rmrf "$SWAP_NEW"; [ -z "$SWAP_OLD" ] || [ -e "$SWAP_APP" ] || mv "$SWAP_OLD" "$SWAP_APP" 2>/dev/null; swap_done; }
dir_done() { local o="$SWAP_OLD"; swap_done; [ -z "$o" ] || rmrf "$o"; }
# Ctrl-C, a closed window or kill during a swap: the old copy goes back, a half-staged copy is removed
on_signal() { trap - INT TERM HUP; dir_back; say "stopped; nothing is half done. Run the doctor again to finish."; exit 130; }
trap on_signal INT TERM HUP
# copies of another doctor that is still running are never touched (B3 P3-4); $$ is this run
alive() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; [ "$1" != $$ ] && kill -0 "$1" 2>/dev/null; }
# what an interrupted earlier run left next to $1: an old copy goes back if the app is missing, else it is parked;
# a stale new copy is removed
leftovers() { local d n f p; d="$(dirname "$1")"; n="$(basename "$1" .app)"
  for f in "$d/.$n-aj-old-"*.app "$d/.$n-aj-new-"*.app; do [ -e "$f" ] || continue
    p="${f%.app}"; alive "${p##*-}" && continue
    case "$f" in *-aj-new-*) rmrf "$f" ;; *) if [ -e "$1" ]; then park "$f" "$n"; else mv "$f" "$1" 2>/dev/null; fi ;; esac; done; }
# the same for the folders: <x>.aj-old-<pid> goes back to <x> when <x> is missing, else it is removed (B3 P3-3)
dir_leftovers() { local f t; for f in "$AJ"/node.aj-*-* "$AJ"/tentacles/*.aj-*-*; do [ -e "$f" ] || continue
    alive "${f##*-}" && continue; t="${f%.aj-*}"
    case "$f" in *.aj-old-*) [ -e "$t" ] || { mv "$f" "$t" 2>/dev/null && continue; } ;; esac
    rmrf "$f"; done; }
# one doctor at a time (B3 P3-4): a lock folder with the pid; a lock of a dead doctor is taken over
DLOCK="$AJ/.doctor.lock"; LOCKED=""
# a live pid counts only when that process is a doctor: after a crash the pid may belong to any other process
held() { local p; p="$(cat "$DLOCK/pid" 2>/dev/null)"; [ -n "$p" ] && { alive "$p" && ps -p "$p" -o command= 2>/dev/null | grep -q doctor; return; }
  [ -z "$(find "$DLOCK" -maxdepth 0 -mmin +1 2>/dev/null)" ]; }   # no pid yet: being taken right now, unless a minute old
take_lock() { mkdir -p "$AJ" 2>/dev/null || return 0   # no ~/.agent-jack at all: the steps report that themselves
  mkdir "$DLOCK" 2>/dev/null || { [ -d "$DLOCK" ] && ! held && rmrf "$DLOCK" && mkdir "$DLOCK" 2>/dev/null; } || return 1
  echo $$ > "$DLOCK/pid"; LOCKED=1; }
MNT=""; TMPD=""
cleanup() { [ -z "$MNT" ] || hdiutil detach -quiet "$MNT" >/dev/null 2>&1; [ -z "$TMPD" ] || rmrf "$TMPD"; [ -z "$LOCKED" ] || rmrf "$DLOCK"; }
trap cleanup EXIT
attach() { hdiutil attach -nobrowse -readonly -noautoopen "$1" 2>/dev/null | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1; }
detach() { [ -z "$MNT" ] || hdiutil detach -quiet "$MNT" >/dev/null 2>&1; MNT=""; }
# copy a bundle out of a mounted image into a hidden staging name next to its final place; sets STAGED
# (no $(…): the signal trap must know the staged path in this shell)
stage_from() { # $1 source bundle, $2 final path
  STAGED="$(dirname "$2")/.$(basename "$2" .app)-aj-new-$$.app"; SWAP_NEW="$STAGED"
  rmrf "$STAGED"; mkdir -p "$(dirname "$2")" 2>/dev/null
  ditto "$1" "$STAGED" 2>/dev/null || { rmrf "$STAGED"; SWAP_NEW=""; return 1; }
}
# what the doctor installed (name|version|time|folder), read by agent-jack-setup bin/uninstall.sh; no user name or home path
record_app() { local f="$AJ/installed-apps" w="${3/#"$HOME"/$TILDE}"
  mkdir -p "$AJ" && { awk -F'|' -v n="$1" -v w="$w" '!($1==n && $4==w)' "$f" 2>/dev/null; printf '%s|%s|%s|%s\n' "$1" "$2" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$w"; } > "$f.new" && mv "$f.new" "$f"; }
# where an app goes: an existing copy's folder wins, then /Applications if writable, then ~/Applications
app_dest() { local cur; cur="$(app_path "$@")"; [ -n "$cur" ] && { dirname "$cur"; return; }
  if [ -w "$APPS_SYS" ]; then echo "$APPS_SYS"; else mkdir -p "$APPS_HOME"; echo "$APPS_HOME"; fi; }

# ---------- pins: the stack lock and its versions.env copy, both next to this doctor ----------
LOCK=""; PINS=""
lock_get() { json_get "$LOCK" "$1"; }   # the one reader of the lock (KRA-10868 shape: tentacles.repo/tag/version/commit/minimum)
pin() { [ -f "$PINS" ] && awk -F= -v k="$1" -v h="$HOME" '{sub(/#.*/,""); sub(/[ \t]+$/,"")} $1==k{v=substr($0,length(k)+2); gsub(/^"|"$/,"",v); gsub(/\$HOME/,h,v); print v; exit}' "$PINS"; }

# ---------- consent ----------
if [ "$(uname -s 2>/dev/null)" != Darwin ]; then stop_line AJ-OS-01; exit 1; fi
if [ $YES = 0 ] && [ $CHECK = 0 ]; then
  if [ -t 0 ]; then
    if [ "$UI" = cs ]; then
      say "Agent Jack doctor zkontroluje tento Mac a z oficiálních zdrojů nainstaluje nebo opraví: aplikaci Agent Jack, T3 Code (Beta), Tentacles, Codex CLI, Claude Code CLI, Node.js a klasifikátor (do ~/.agent-jack a Aplikací)."
      say "Maže jen své vlastní soubory (v ~/.agent-jack, dočasné soubory a své nedokončené kopie aplikací); starší kopie aplikací odloží do ~/.agent-jack/replaced-apps. Nikdy se neptá na hesla a všechna přihlášení děláte vy."
      printf 'Pokračovat? [a/N] '
    else
      say "The Agent Jack doctor checks this Mac and installs or repairs, from their official sources: the Agent Jack app, T3 Code (Beta), Tentacles, Codex CLI, Claude Code CLI, Node.js and the estate classifier (in ~/.agent-jack and Applications)."
      say "It deletes only its own files (in ~/.agent-jack, its temporary files and its own unfinished app copies); older app copies go to ~/.agent-jack/replaced-apps. It never asks for a password, and you do every sign-in."
      printf 'Continue? [y/N] '
    fi
    read -r ans
    case "$ans" in y|Y|yes|a|A|ano|ANO) YES=1 ;; *) CHECK=1 ;; esac
  else
    CHECK=1
  fi
fi
CAN=1; [ $CHECK = 1 ] && CAN=0
if [ $CAN = 1 ] && ! take_lock; then stop_line AJ-DOC-02; exit 1; fi
[ $CAN = 0 ] || dir_leftovers
say "AGENT JACK DOCTOR $DOCTOR_VERSION · macOS · $(date +%Y-%m-%d) · $([ $CAN = 1 ] && echo repair || echo check-only)"

# ---------- 1-2 this Mac ----------
step system
OSV="$(sw_vers -productVersion 2>/dev/null)"; ARCH="$(uname -m)"
[ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = 1 ] && ARCH=arm64   # Terminal under Rosetta still has an Apple chip
CHIP=Intel; [ "$ARCH" = arm64 ] && CHIP="Apple silicon"
MEM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))
FREE_KB="$(df -k "$HOME" 2>/dev/null | awk 'NR==2{print $4}')"; case "$FREE_KB" in ''|*[!0-9]*) FREE_KB=0 ;; esac
FREE_GB=$(( FREE_KB / 1048576 ))
if [ "${OSV%%.*}" -ge 14 ] 2>/dev/null; then rec PASS AJ-SYS-00 macos "$OSV $ARCH"; else OS_OK=AJ-SYS-01; rec FAIL AJ-SYS-01 macos "${OSV:-?} (need 14+)"; fi
[ "$ARCH" = arm64 ] || rec WARN AJ-SYS-02 chip "Intel ($ARCH)"
if [ "$MEM_GB" -lt 16 ]; then rec WARN AJ-HW-01 memory "$MEM_GB GB"; else rec PASS AJ-HW-00 memory "$MEM_GB GB"; fi
if [ "$FREE_GB" -lt 5 ]; then DISK_OK=AJ-DISK-02; rec FAIL AJ-DISK-02 disk "$FREE_GB GB free"
elif [ "$FREE_GB" -lt 20 ]; then rec WARN AJ-DISK-01 disk "$FREE_GB GB free"
else rec PASS AJ-DISK-00 disk "$FREE_GB GB free"; fi

# ---------- 3 sandbox and network ----------
step network
if [ -n "${CODEX_SANDBOX_NETWORK_DISABLED:-}" ]; then NET_OK=AJ-DOC-01; rec FAIL AJ-DOC-01 network "inside a sandbox without network"
elif curl -fsI --proto '=https' --connect-timeout 15 --max-time 30 -o /dev/null https://github.com 2>/dev/null; then rec PASS AJ-NET-00 network github.com
else NET_OK=AJ-NET-01; rec FAIL AJ-NET-01 network "github.com does not answer"; fi
TMP_OK=""; TMPD="$(mktemp -d "${TMPDIR:-/tmp}/aj-doctor.XXXXXX" 2>/dev/null)" || TMPD=""
[ -n "$TMPD" ] || { TMP_OK=AJ-TMP-01; rec FAIL AJ-TMP-01 temp-folder "cannot make a folder in ${TMPDIR:-/tmp}"; }

# ---------- 4 pins ----------
step versions
# Both files come from the doctor's own place; the pins copy is byte-identical to agent-jack-setup at the lock's
# setup tag (internal/bin/check_pins_copy.py). Each step checks only its own values (B3 P2-4).
SETUP_TAG=""
if bad="$(needs "$NET_OK" "$TMP_OK")"; then
  LOCK="$TMPD/stack.lock.json"; PINS="$TMPD/versions.env"
  if fetch "$DOCTOR_BASE/stack-lock/stack.lock.json" "$LOCK" && fetch "$DOCTOR_BASE/stack-lock/versions.env" "$PINS" && [ -n "$(lock_get revision)" ]; then
    SETUP_TAG="$(lock_get agentJackSetup.tag)"
    # one value per key: a shell that sources this file takes the last, pin the first (B3 round 3 P3-1)
    dup="$(awk -F= '/^[A-Za-z0-9_]+=/ && s[$1]++ {print $1; exit}' "$PINS")"
    if [ -n "$dup" ]; then PINS_OK=AJ-PIN-01; PINS=""; rec FAIL AJ-PIN-01 versions "versions.env has the key $dup twice"
    elif safe "$SETUP_TAG"; then rec PASS AJ-PIN-00 versions "lock rev $(lock_get revision), setup $SETUP_TAG"
    else SETUP_TAG=""; rec FAIL AJ-PIN-01 versions "lock rev $(lock_get revision): agentJackSetup.tag missing or not safe"; fi
  else PINS_OK=AJ-PIN-01; LOCK=""; PINS=""; rec FAIL AJ-PIN-01 versions "lock or versions.env could not be read"; fi
else PINS_OK="$bad"; skip "$bad" versions; fi

# ---------- 5 our server (never blocks anything) ----------
step server
if bad="$(needs "$NET_OK")"; then
  if curl -fsS --proto '=https' --connect-timeout 15 --max-time 30 -o /dev/null "https://$JACK_HOST/health/ready" 2>/dev/null; then rec PASS AJ-SRV-00 server "$JACK_HOST ready"
  else rec WARN AJ-SRV-01 server "$JACK_HOST not ready"; fi
else skip "$bad" server; fi

# ---------- 6 Node.js ----------
step node
NODE_VERSION="$(pin NODE_VERSION)"; NODE_MIN="$(pin NODE_MIN_MAJOR)"; [ -n "$NODE_MIN" ] || NODE_MIN=22
PROFILE="$HOME/.zprofile"; case "${SHELL:-}" in */bash) PROFILE="$HOME/.bash_profile" ;; esac
PATHLINE='export PATH="$HOME/.agent-jack/node/bin:$PATH"   # Agent Jack doctor'
node_ok() { local v; v="$(ver node --version)"; [ -n "$v" ] && [ "${v%%.*}" -ge "$NODE_MIN" ] 2>/dev/null && [ -w "$(npm prefix -g 2>/dev/null)/bin" ]; }
[ -x "$AJ/node/bin/node" ] && PATH="$AJ/node/bin:$PATH" && export PATH
if node_ok; then NODE_OK=""; rec PASS AJ-NODE-00 node "$(ver node --version)"
elif [ $CAN = 0 ]; then rec FAIL AJ-NODE-01 node "missing or not usable (check-only)"
elif bad="$(needs "$NET_OK" "$PINS_OK" "$DISK_OK")"; then
  na=x64; [ "$ARCH" = arm64 ] && na=arm64
  nsum="$(pin "NODE_SHA256_MAC_$(echo "$na" | tr a-z A-Z)")"; nf="$TMPD/node.tar.gz"; ns="$AJ/node.aj-new-$$"; SWAP_NEW="$ns"   # a signal while unpacking removes it
  # the Node pin is one unit: the version and both Mac checksums, or nothing is downloaded (B3 P2-2)
  if ! safe "$NODE_VERSION" || ! hex "$(pin NODE_SHA256_MAC_ARM64)" 64 || ! hex "$(pin NODE_SHA256_MAC_X64)" 64; then
    NODE_OK=AJ-PIN-01; rec FAIL AJ-PIN-01 node "NODE_VERSION, NODE_SHA256_MAC_ARM64 and NODE_SHA256_MAC_X64 not all set in versions.env ${SETUP_TAG:-?}"
  elif ! fetch "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-darwin-$na.tar.gz" "$nf"; then rec FAIL AJ-NODE-01 node "download failed"
  elif [ "$(sha256 "$nf")" != "$nsum" ]; then rec FAIL AJ-NODE-01 node "checksum mismatch, not installed"
  elif ! { rmrf "$ns" && mkdir -p "$ns" && tar -xzf "$nf" -C "$ns" --strip-components 1; }; then rmrf "$ns"; rec FAIL AJ-NODE-01 node "unpack failed"
  else
    dir_in "$ns" "$AJ/node" && dir_done
    PATH="$AJ/node/bin:$PATH"; export PATH
    if node_ok; then NODE_OK=""; rec FIXED AJ-NODE-00 node "$NODE_VERSION in ~/.agent-jack/node"; else rec FAIL AJ-NODE-01 node "installed but does not run"; fi
  fi
else rec FAIL AJ-NODE-01 node "missing"; skip "$bad" node-install; fi
# GUI apps (T3 Code, Agent Jack) read PATH from the login shell: one marked line, written once
if [ -z "$NODE_OK" ] && [ "$(command -v node)" = "$AJ/node/bin/node" ]; then
  if grep -qF '.agent-jack/node/bin' "$PROFILE" 2>/dev/null; then :
  elif [ $CAN = 1 ] && { printf '\n%s\n' "$PATHLINE" >> "$PROFILE"; } 2>/dev/null; then rec FIXED AJ-PATH-00 login-path "${PROFILE/#"$HOME"/$TILDE}"
  else rec WARN AJ-PATH-01 login-path "${PROFILE/#"$HOME"/$TILDE} not changed"; fi
fi

# ---------- 7-8 Codex CLI and Claude Code CLI (exact pins from versions.env, never latest) ----------
cli() { # name npm-package min code-prefix
  local cur; cur="$(ver "$1" --version)"
  [ -n "$PINS_OK" ] || safe "$3" || { rec FAIL AJ-PIN-01 "$1" "no ${4#AJ-}_CLI_MIN pin; never latest"; return; }
  if [ -n "$cur" ] && [ -n "$3" ] && ge "$cur" "$3"; then rec PASS "$4-00" "$1" "$cur"; return; fi
  if bad="$(needs "$NODE_OK" "$PINS_OK" "$NET_OK" "$DISK_OK")"; then :; else rec FAIL "$4-01" "$1" "${cur:-missing}"; skip "$bad" "$1-install"; return; fi
  [ $CAN = 1 ] || { rec FAIL "$4-01" "$1" "${cur:-missing} (check-only)"; return; }
  npm install -g --no-audit --no-fund --loglevel=error "$2@$3" >/dev/null 2>&1 || { rec FAIL "$4-01" "$1" "npm install $2@$3 failed"; return; }
  hash -r; cur="$(ver "$1" --version)"
  if [ -n "$cur" ] && ge "$cur" "$3"; then rec FIXED "$4-00" "$1" "$cur"; else rec FAIL "$4-02" "$1" "${cur:-missing} comes first on PATH, want >= $3"; fi
}
step codex; cli codex @openai/codex "$(pin CODEX_CLI_MIN)" AJ-CODEX
step claude; cli claude @anthropic-ai/claude-code "$(pin CLAUDE_CLI_MIN)" AJ-CLAUDE

# ---------- 9-10 T3 Code (Beta), official, from its makers ----------
step t3code
T3_MIN="$(lock_get t3.minimum 2>/dev/null)"; T3_TESTED="$(lock_get t3.testedThrough 2>/dev/null)"; T3_TAG="$(lock_get t3.tag 2>/dev/null)"
T3_REPO="$(lock_get t3.publisherRepo 2>/dev/null)"
# T3 needs only its own values to agree and be safe (B3 P1, P2-4); T3_PIN names the first one that is not
T3_PIN=""
for k in T3_ASSET_MAC_ARM64 T3_ASSET_MAC_X64; do safe "$(pin $k)" || T3_PIN=$k; done
for k in T3_SHA256_MAC_ARM64 T3_SHA256_MAC_X64; do hex "$(pin $k)" 64 || T3_PIN=$k; done
case "$T3_REPO" in https://github.com/*/*/*|*..*) T3_PIN=t3.publisherRepo ;; https://github.com/*/*) safe "${T3_REPO##*/}" || T3_PIN=t3.publisherRepo ;; *) T3_PIN=t3.publisherRepo ;; esac
safe "$T3_MIN" || T3_PIN=t3.minimum; safe "$T3_TESTED" || T3_PIN=t3.testedThrough
[ "$(pin T3_APP_NAME)" = "$T3_APP_NAME" ] || T3_PIN=T3_APP_NAME; [ "$(pin T3_BUNDLE_ID)" = "$T3_ID" ] || T3_PIN=T3_BUNDLE_ID
[ "$(pin T3_LEGACY_APP_NAMES)" = "$T3_LEGACY" ] || T3_PIN=T3_LEGACY_APP_NAMES; { safe "$T3_TAG" && [ "$(pin T3_TAG)" = "$T3_TAG" ]; } || T3_PIN=T3_TAG
t3_install() { # $1 final app path
  local asset sum f m s rc
  if [ "$ARCH" = arm64 ]; then asset="$(pin T3_ASSET_MAC_ARM64)"; sum="$(pin T3_SHA256_MAC_ARM64)"; else asset="$(pin T3_ASSET_MAC_X64)"; sum="$(pin T3_SHA256_MAC_X64)"; fi
  f="$TMPD/$asset"
  fetch "$T3_REPO/releases/download/$T3_TAG/$asset" "$f" || { rec FAIL AJ-T3-03 t3code "download failed"; return 1; }
  [ "$(sha256 "$f")" = "$sum" ] || { rec FAIL AJ-T3-04 t3code "checksum mismatch, not installed"; return 1; }
  MNT="$(attach "$f")"; m="$MNT/$T3_APP_NAME.app"
  [ -n "$MNT" ] && [ -d "$m" ] || { detach; rec FAIL AJ-T3-03 t3code "could not open the download"; return 1; }
  [ "$(plist_id "$m")" = "$T3_ID" ] || { detach; rec FAIL AJ-T3-04 t3code "download has bundle $(plist_id "$m")"; return 1; }
  stage_from "$m" "$1" || { detach
    if [ -e "$1" ] && [ ! -w "${1%/*}" ]; then rec FAIL AJ-T3-11 t3code "${1/#"$HOME"/$TILDE} cannot be replaced by this account (left whole)"
    else rec FAIL AJ-T3-03 t3code "could not copy into ${1%/*}"; fi; return 1; }
  s="$STAGED"; detach; quit_app "$T3_APP_NAME"
  swap_in "$s" "$1"; rc=$?
  [ $rc = 0 ] && return 0
  case $rc in 3) rec FAIL AJ-T3-11 t3code "${1/#"$HOME"/$TILDE} cannot be replaced by this account (left whole)" ;;
    5) rec FAIL AJ-T3-12 t3code "previous copy kept at $SWAP_LEFT" ;;
    6) rec FAIL AJ-T3-03 t3code "could not put the new app in place (there was no older copy)" ;;
    *) rec FAIL AJ-T3-03 t3code "could not put the new app in place (old copy restored)" ;; esac
  return 1
}
if ! bad="$(needs "$PINS_OK")"; then skip "$bad" t3code
elif [ -n "$T3_PIN" ]; then T3_OK=AJ-PIN-01; rec FAIL AJ-PIN-01 t3code "$T3_PIN missing, out of step with the lock, or not safe"
else
  [ $CAN = 0 ] || for d in "$APPS_SYS" "$APPS_HOME"; do leftovers "$d/$T3_APP_NAME.app"; done
  T3="$(app_path "$T3_APP_NAME")"; TV=""; [ -z "$T3" ] || TV="$(plist_ver "$T3")"
  if [ -n "$T3" ] && [ "$(plist_id "$T3")" != "$T3_ID" ]; then rec FAIL AJ-T3-08 t3code "bundle $(plist_id "$T3")"
  elif [ -n "$TV" ] && ge "$TV" "$T3_MIN"; then
    T3_OK=""
    if [ "$TV" != "$T3_TESTED" ] && ge "$TV" "$T3_TESTED"; then rec WARN AJ-T3-09 t3code "$TV (tested $T3_TESTED)"; else rec PASS AJ-T3-00 t3code "$TV"; fi
  elif [ $CAN = 0 ]; then rec FAIL AJ-T3-03 t3code "${TV:-missing} (check-only)"
  elif bad="$(needs "$OS_OK" "$NET_OK" "$DISK_OK")"; then
    dest="$(app_dest "$T3_APP_NAME")/$T3_APP_NAME.app"
    if t3_install "$dest"; then T3_OK=""; rec FIXED AJ-T3-00 t3code "$(plist_ver "$dest") in ${dest%/*}"; record_app "$T3_APP_NAME" "$(plist_ver "$dest")" "${dest%/*}"; fi
  else rec FAIL AJ-T3-03 t3code "${TV:-missing}"; skip "$bad" t3code-install; fi
fi
# older T3 apps share ~/.t3: once T3 Code (Beta) is in place they move aside, never deleted. The names are the fixed
# ones above, and an app moves only when its bundle id is a T3 one (B3 P2-1)
if [ -z "$T3_OK" ]; then
  IFS='|' read -r -a LEGACY <<< "$T3_LEGACY"
  for name in "${LEGACY[@]}"; do
    o="$(app_path "$name")"; [ -n "$o" ] || continue
    # a link is never quit or moved: quitting by name would reach the app it points to (B3 round 3 P3-3)
    [ -L "$o" ] && { rec WARN AJ-T3-08 t3code-older "$name.app is a link; left alone"; continue; }
    id="$(plist_id "$o")"
    case "$T3_LEGACY_IDS" in *" $id "*) ;; *) rec WARN AJ-T3-08 t3code-older "$name.app $([ -n "$id" ] && echo "has bundle $id" || echo "has no readable bundle id"); left alone"; continue ;; esac
    if [ $CAN = 1 ]; then quit_app "$name"
      if mkdir -p "$AJ/replaced-apps" && mv "$o" "$AJ/replaced-apps/$name-$(ts).app" 2>/dev/null; then rec FIXED AJ-T3-10 t3code-older "$name.app moved to ~/.agent-jack/replaced-apps"
      else rec WARN AJ-T3-07 t3code-older "$name.app"; fi
    else rec WARN AJ-T3-07 t3code-older "$name.app (check-only)"; fi
  done
fi

# ---------- 11 Tentacles at the lock's tested tag, from the public repo (commit archive, no git) ----------
step tentacles
TL_VER="$(lock_get tentacles.version 2>/dev/null)"; TL_COMMIT="$(lock_get tentacles.commit 2>/dev/null)"; TL_REPO="$(lock_get tentacles.repo 2>/dev/null)"
TENT_PIN=""; safe "$TL_VER" || TENT_PIN=tentacles.version; hex "$TL_COMMIT" 40 || TENT_PIN=tentacles.commit; ourgh "$TL_REPO" || TENT_PIN=tentacles.repo
if ! bad="$(needs "$PINS_OK")"; then skip "$bad" tentacles
elif [ -n "$TENT_PIN" ]; then TENT_OK=AJ-PIN-01; rec FAIL AJ-PIN-01 tentacles "lock $TENT_PIN missing or not safe"
else
  TD="$AJ/tentacles/$TL_VER"; cur="$(ver tentacles --version)"
  if [ "$cur" = "$TL_VER" ]; then TENT_OK=""; rec PASS AJ-TENT-00 tentacles "$cur"
  elif [ $CAN = 0 ]; then rec FAIL AJ-TENT-01 tentacles "${cur:-missing}, want $TL_VER (check-only)"
  elif bad="$(needs "$NODE_OK" "$NET_OK" "$DISK_OK")"; then
    f="$TMPD/tentacles.tar.gz"; s="$TD.aj-new-$$"; SWAP_NEW="$s"
    if ! fetch "$TL_REPO/archive/$TL_COMMIT.tar.gz" "$f"; then rec FAIL AJ-TENT-01 tentacles "download of $TL_COMMIT failed"
    elif ! { rmrf "$s" && mkdir -p "$s" && tar -xzf "$f" -C "$s" --strip-components 1; } || ! grep -q "\"version\": *\"$TL_VER\"" "$s/package.json" 2>/dev/null; then
      rmrf "$s"; rec FAIL AJ-TENT-01 tentacles "archive of $TL_COMMIT is not $TL_VER"
    else
      printf '%s\n' "$TL_COMMIT" > "$s/.aj-commit"
      if dir_in "$s" "$TD" && (cd "$TD" && npm ci --no-audit --no-fund --loglevel=error >/dev/null 2>&1 && npm link --loglevel=error >/dev/null 2>&1); then
        dir_done; hash -r; cur="$(ver tentacles --version)"
        if [ "$cur" = "$TL_VER" ]; then TENT_OK=""; rec FIXED AJ-TENT-00 tentacles "$cur @ ${TL_COMMIT:0:12}"
        else rec FAIL AJ-TENT-02 tentacles "${cur:-missing} comes first on PATH, want $TL_VER"; fi
      else
        dir_back; rmrf "$s"; rec FAIL AJ-TENT-01 tentacles "npm install/link failed"
      fi
    fi
  else rec FAIL AJ-TENT-01 tentacles "${cur:-missing}"; skip "$bad" tentacles-install; fi
fi

# ---------- 12 estate classifier at the pinned commit ----------
step classify
VENV="$AJ/venv"   # fixed: no downloaded value decides what is deleted (B3 P1); CLASSIFY_VENV is for Windows only
GC="$(pin GUARDIAN_COMMIT)"; CV="$(pin CLASSIFY_VERSION)"; PYMIN="$(pin PYTHON_MIN)"; GR="$(pin GUARDIAN_REPO)"
EC_PIN=""; hex "$GC" 40 || EC_PIN=GUARDIAN_COMMIT; safe "$CV" || EC_PIN=CLASSIFY_VERSION; ourgh "$GR" || EC_PIN=GUARDIAN_REPO
case "$PYMIN" in [0-9]*.[0-9]*) case "$PYMIN" in *[!0-9.]*) EC_PIN=PYTHON_MIN ;; esac ;; *) EC_PIN=PYTHON_MIN ;; esac
smoke() { "$VENV/bin/python" - >/dev/null 2>&1 <<'PY'
import json, tempfile, os, classify, worker_route
d = tempfile.mkdtemp()
p = os.path.join(d, "smoke.json")
json.dump({"name": "smoke", "taxonomy": {"classes": {}}, "question": "smoke?", "min_conf": 0.6,
           "paths": {"judge_queue": os.path.join(d, "q.jsonl"), "answers": os.path.join(d, "a.jsonl")},
           "key": {"source": "env", "env": "AJ_SMOKE_NO_KEY"}, "questions": {}}, open(p, "w"))
assert classify.Classifier(p).classify("smoke test", key="smoke")["class"] == "unclassified"
PY
}
ec_ok() { [ "$(cat "$VENV/.aj-commit" 2>/dev/null)" = "$GC" ] && [ "$("$VENV/bin/python" -c 'import importlib.metadata as m; print(m.version("estate-classify"))' 2>/dev/null)" = "$CV" ] && smoke; }
find_py() { local p; for p in python3.13 python3.12 python3.11 python3; do
    p="$(command -v "$p" 2>/dev/null)" || continue
    # /usr/bin/python3 without the command line tools only opens Apple's install dialog: treat it as missing
    [ "$p" = /usr/bin/python3 ] && ! xcode-select -p >/dev/null 2>&1 && continue
    "$p" -c "import sys; sys.exit(0 if sys.version_info >= tuple(map(int, '$PYMIN'.split('.'))) else 1)" 2>/dev/null && { echo "$p"; return 0; }
  done; return 1; }
if ! bad="$(needs "$PINS_OK")"; then skip "$bad" classify
elif [ -n "$EC_PIN" ]; then rec FAIL AJ-PIN-01 classify "$EC_PIN missing or not safe"
else
  if ec_ok; then rec PASS AJ-EC-00 classify "$CV @ ${GC:0:12}"
  elif ! PY="$(find_py)"; then rec FAIL AJ-PY-01 classify "no Python >= $PYMIN"
  elif [ $CAN = 0 ]; then rec FAIL AJ-EC-01 classify "not installed at ${GC:0:12} (check-only)"
  elif bad="$(needs "$NET_OK" "$DISK_OK")"; then
    f="$TMPD/estate-guardian.tar.gz"
    "$VENV/bin/python" -m pip --version >/dev/null 2>&1 || { rmrf "$VENV"; "$PY" -m venv "$VENV" >/dev/null 2>&1; }
    if ! fetch "$GR/archive/$GC.tar.gz" "$f"; then rec FAIL AJ-EC-01 classify "download of ${GC:0:12} failed"
    elif ! "$VENV/bin/python" -m pip install -q --upgrade --force-reinstall "$f" >/dev/null 2>&1; then rec FAIL AJ-EC-01 classify "pip install failed"
    else printf '%s\n' "$GC" > "$VENV/.aj-commit"
      if ec_ok; then rec FIXED AJ-EC-00 classify "$CV @ ${GC:0:12}"; else rec FAIL AJ-EC-01 classify "installed but the smoke test fails"; fi
    fi
  else rec FAIL AJ-EC-01 classify missing; skip "$bad" classify-install; fi
fi

# ---------- 13 Agent Jack desktop app ----------
step agent-jack
JMIN="$(lock_get agentJackSetup.desktopMin 2>/dev/null)"; [ -n "$JMIN" ] || JMIN="$(pin JACK_DESKTOP_MIN)"
JA=x64; [ "$ARCH" = arm64 ] && JA=arm64
dmg_ver() { basename "$1" | sed -nE 's/^AgentJack-[A-Za-z]+-([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/p'; }
# newest download that is at least the lock's minimum and not older than the installed app (never a downgrade)
newest_dmg() { local f v; ls -t "$HOME/Downloads"/AgentJack-*.dmg 2>/dev/null | while IFS= read -r f; do
    v="$(dmg_ver "$f")"; [ -n "$v" ] && ge "$v" "$JMIN" && { [ -z "$JV" ] || ge "$v" "$JV"; } && { echo "$f"; break; }; done; }
# The one place that gets the installer. Today: the signed-in Downloads page and a person's click; the doctor waits for
# the file. When a download link without sign-in exists (KRA-10893 A1), only this function changes, and it also
# fetches the pinned sha256 our server publishes for that file (shortcut: until then the signature is the only proof).
jack_get_dmg() {
  local d t=0; d="$(newest_dmg)"; [ -n "$d" ] && { echo "$d"; return 0; }
  [ $CAN = 1 ] && [ -z "$NET_OK" ] && [ "$WAIT" -gt 0 ] || return 1
  open "https://$JACK_HOST/downloads" >/dev/null 2>&1
  # stderr: this function's stdout is the file path
  if [ "$UI" = cs ]; then say "  PERSON: na stránce, která se otevřela, se přihlaste a klikněte na Stáhnout: macOS · $CHIP. Čekám až $WAIT s." >&2
  else say "  PERSON: on the page that opened, sign in and click Download: macOS · $CHIP. Waiting up to $WAIT s." >&2; fi
  while [ $t -lt "$WAIT" ]; do sleep 5; t=$((t+5)); d="$(newest_dmg)"
    [ -n "$d" ] && [ -z "$(ls "$HOME/Downloads"/*.crdownload "$HOME/Downloads"/*.download 2>/dev/null)" ] && { sleep 2; echo "$d"; return 0; }
  done; return 1
}
jack_install() { # $1 dmg; returns 0 when installed
  local base h12 got m s dest rc cur
  base="$(basename "$1")"; h12="$(printf '%s' "$base" | sed -nE 's/.*-([0-9a-f]{12})( \([0-9]+\))?\.dmg$/\1/p')"
  case "$base" in *-"$JA"-*) ;; *) rec FAIL AJ-JACK-05 agent-jack-app "$base is not for $CHIP ($JA)"; return 1 ;; esac
  got="$(sha256 "$1")"
  # the name's 12 hex only catch a damaged download; they prove nothing about who made it (codesign below does)
  [ -n "$h12" ] && [ "${got:0:12}" = "$h12" ] || { rec FAIL AJ-JACK-03 agent-jack-app "$base is damaged (checksum ${got:0:12} does not match its name)"; return 1; }
  MNT="$(attach "$1")"; m="$(ls -d "$MNT"/*.app 2>/dev/null | head -1)"
  [ -n "$MNT" ] && [ -d "$m" ] || { detach; rec FAIL AJ-JACK-03 agent-jack-app "$base does not open"; return 1; }
  # read-only checks: the signature is valid for every file and names our team, and Gatekeeper accepts the app (B3 P2-2)
  if [ "$(plist_id "$m")" != "$JACK_BUNDLE_ID" ] \
     || ! codesign --verify --deep --strict -R="anchor apple generic and certificate leaf[subject.OU] = \"$JACK_TEAM_ID\"" "$m" >/dev/null 2>&1 \
     || ! spctl -a -t exec "$m" >/dev/null 2>&1; then
    detach; rec FAIL AJ-JACK-03 agent-jack-app "$base failed the signature check for Verduona ($JACK_TEAM_ID)"; return 1; fi
  cur="$(app_path 'Agent Jack' AgentJack)"; dest="$(app_dest 'Agent Jack' AgentJack)/Agent Jack.app"
  stage_from "$m" "$dest" || { detach; rec FAIL AJ-JACK-06 agent-jack-app "could not copy into ${dest%/*}"; return 1; }
  s="$STAGED"; detach; quit_app "Agent Jack"
  swap_in "$s" "$dest"; rc=$?
  [ $rc = 5 ] && { rec FAIL AJ-JACK-07 agent-jack-app "previous copy kept at $SWAP_LEFT"; return 1; }
  [ $rc = 6 ] && { rec FAIL AJ-JACK-06 agent-jack-app "could not put the new app in place (there was no older copy)"; return 1; }
  [ $rc = 0 ] || { rec FAIL AJ-JACK-06 agent-jack-app "could not put the new app in place (old copy unchanged)"; return 1; }
  [ -n "$cur" ] && [ "$cur" != "$dest" ] && mkdir -p "$AJ/replaced-apps" && mv "$cur" "$AJ/replaced-apps/AgentJack-$(ts).app" 2>/dev/null   # the older name AgentJack.app
  return 0
}
if [ -z "$JMIN" ]; then skip "${PINS_OK:-AJ-PIN-01}" agent-jack-app
else
  [ $CAN = 0 ] || for d in "$APPS_SYS" "$APPS_HOME"; do leftovers "$d/Agent Jack.app"; done
  JAPP="$(app_path 'Agent Jack' AgentJack)"; JV=""; [ -z "$JAPP" ] || JV="$(plist_ver "$JAPP")"
  if [ -n "$JV" ] && ge "$JV" "$JMIN"; then rec PASS AJ-JACK-00 agent-jack-app "$JV"
  else code=AJ-JACK-01; [ -n "$JV" ] && code=AJ-JACK-02
    if bad="$(needs "$OS_OK" "$DISK_OK")"; then
      if [ $CAN = 0 ]; then rec FAIL "$code" agent-jack-app "${JV:-missing} (check-only)"
      elif ! DMG="$(jack_get_dmg)"; then rec FAIL "$code" agent-jack-app "${JV:-missing}, no AgentJack-*-$JA-*.dmg in ~/Downloads"
      elif jack_install "$DMG"; then rec FIXED AJ-JACK-00 agent-jack-app "$(plist_ver "$(app_path 'Agent Jack')"), signature verified (codesign, Gatekeeper)"; fi
    else rec FAIL "$code" agent-jack-app "${JV:-missing}"; skip "$bad" agent-jack-install; fi
  fi
fi

# ---------- 14 Google Chrome ----------
GCH="$(app_path 'Google Chrome')"
if [ -n "$GCH" ]; then rec PASS AJ-CHROME-00 google-chrome "$(plist_ver "$GCH")"; else rec WARN AJ-CHROME-01 google-chrome missing; fi

# ---------- 15 an older setup folder (KRA-10942): fetch tags, move to the lock's tag; never a second clone ----------
SD="$HOME/Developer/agent-jack-setup"
if [ -d "$SD/.git" ] && [ -n "$SETUP_TAG" ]; then
  step setup-folder
  # without the command line tools /usr/bin/git only opens Apple's install dialog: no git call at all then
  if ! xcode-select -p >/dev/null 2>&1; then rec WARN AJ-SETUP-01 setup-folder "not checked (no command line tools)"
  elif [ "$(git -C "$SD" describe --tags --exact-match 2>/dev/null)" = "$SETUP_TAG" ]; then rec PASS AJ-SETUP-00 setup-folder "$SETUP_TAG"
  elif [ $CAN = 1 ] && [ -z "$NET_OK" ] && [ -z "$(git -C "$SD" status --porcelain 2>/dev/null)" ] \
       && git -C "$SD" fetch -q --tags origin 2>/dev/null && git -C "$SD" -c advice.detachedHead=false checkout -q "refs/tags/$SETUP_TAG" 2>/dev/null; then
    rec FIXED AJ-SETUP-00 setup-folder "$SETUP_TAG (not needed by the doctor)"
  else rec WARN AJ-SETUP-01 setup-folder "$(git -C "$SD" describe --tags 2>/dev/null || echo unknown)"; fi
fi

# ---------- 16 T3 open, Tentacles signed in, Local Talk ----------
step local-talk
T3_CLI="$HOME/.t3/bin/t3"
t3_running() { ps -A -o comm= 2>/dev/null | grep -F -- "/$T3_APP_NAME.app/Contents/MacOS/$T3_APP_NAME" >/dev/null; }
TJ="$TMPD/tentacles-doctor.json"
tdoc() { tentacles doctor --json > "$TJ" 2>/dev/null; json_get "$TJ" t3.auth.status; }
if bad="$(needs "$T3_OK" "$TENT_OK")"; then
  if ! t3_running && [ $CAN = 1 ]; then open -a "$T3_APP_NAME" >/dev/null 2>&1; t=0
    while [ $t -lt 60 ] && ! { t3_running && [ -x "$T3_CLI" ]; }; do sleep 2; t=$((t+2)); done; fi
  if ! t3_running || [ ! -x "$T3_CLI" ]; then rec FAIL AJ-TENT-05 local-talk "T3 Code (Beta) not running"
  else
    st="$(tdoc)"
    if [ "$st" != valid ] && [ $CAN = 1 ]; then RA="$TMPD/reauth.json"   # the token stays in Tentacles' own file, never printed
      tentacles reauth --t3-bin "$T3_CLI" --t3-home "$HOME/.t3" > "$RA" 2>/dev/null; rmrf "$RA"; st="$(tdoc)"; fi
    talk="$(json_get "$TJ" capabilities.talkTurnResult)"
    if [ "$st" != valid ]; then rec FAIL AJ-TENT-03 local-talk "T3 auth ${st:-unknown}"
    elif [ "$talk" = v1 ]; then rec PASS AJ-TENT-00 local-talk "signed in, talkTurnResult v1"
    else rec FAIL AJ-TENT-04 local-talk "talkTurnResult ${talk:-none}"; fi
  fi
else skip "$bad" local-talk; fi

# ---------- 17 sign-ins (the person does them) and stray overrides ----------
step sign-in
CS=0; command -v claude >/dev/null 2>&1 && claude auth status >/dev/null 2>&1 && CS=1
XS=0; command -v codex >/dev/null 2>&1 && codex login status >/dev/null 2>&1 && XS=1
if [ $CS = 1 ] && [ $XS = 1 ]; then rec PASS AJ-SIGN-00 sign-in "codex, claude"
elif [ $CS = 1 ]; then rec WARN AJ-CODEX-04 sign-in "claude only"
elif [ $XS = 1 ]; then rec WARN AJ-CLAUDE-04 sign-in "codex only"
else rec FAIL AJ-CODEX-03 sign-in "neither"; fi
STRAY=""
for v in ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY; do
  if [ -z "${CLAUDECODE:-}" ] && [ -n "${!v:-}" ]; then STRAY="$STRAY $v(env)"; fi   # set or not; never the value
  for f in .zshenv .zshrc .zprofile .bash_profile .bashrc; do
    [ -f "$HOME/$f" ] && grep -Eq "^[[:space:]]*(export[[:space:]]+)?$v=" "$HOME/$f" && STRAY="$STRAY $v(~/$f)"
  done
done
[ -z "$STRAY" ] || rec WARN AJ-ENV-01 claude-env "${STRAY# }"

# ---------- 18 checked by hand in the app ----------
rec SKIP AJ-PAIR-00 pairing manual
rec SKIP AJ-LOCAL-00 local-bot manual

# ---------- the report ----------
P=0; X=0; S=0
while IFS='|' read -r s c n d; do case "$s" in PASS) P=$((P+1)) ;; FIXED) X=$((X+1)) ;; SKIP) S=$((S+1)) ;; esac; done <<EOF
$REPORT
EOF
say ""
say "----- AGENT JACK DOCTOR REPORT (copy from here) -----"
say "doctor: $DOCTOR_VERSION  date: $(date +%Y-%m-%d)  mode: $([ $CAN = 1 ] && echo repair || echo check-only)  setup: ${SETUP_TAG:-?}  lock: $( [ -n "$LOCK" ] && lock_get revision || echo ?)"
say "mac: $CHIP, macOS ${OSV:-?}, $MEM_GB GB RAM, $FREE_GB GB free"
printf '%s' "$REPORT" | while IFS='|' read -r s c n d; do [ -n "$s" ] && printf '%-5s %-12s %-15s %s\n' "$s" "$c" "$n" "$d"; done
say "summary: $P PASS, $X FIXED, $WARNS WARN, $FAILS FAIL, $S SKIP"
NEXT="$(printf '%s' "$REPORT" | awk -F'|' '($1=="FAIL"||$1=="WARN"||$1=="SKIP") && !seen[$2]++ {print $2}')"
if [ -n "$NEXT" ]; then
  [ "$UI" = cs ] && say "co dál (jedna věc na řádek):" || say "next (one thing per line):"
  for c in $NEXT; do
    case "$c" in AJ-PAIR-00|AJ-LOCAL-00) [ $FAILS = 0 ] || continue ;; esac   # the app steps come once the Mac is right
    t="$(msg "$c")"; [ -n "$t" ] || continue
    say "  $c: $t → $(msg "$c" next)"
  done
fi
[ $CAN = 1 ] || { [ "$UI" = cs ] && say "Nic se nezměnilo (jen kontrola). Pro opravu spusťte stejný příkaz s --yes." || say "Nothing was changed (check only). To repair, run the same command with --yes."; }
say "----- end of report (no passwords, keys, e-mails or names in it) -----"
[ $FAILS -eq 0 ]
