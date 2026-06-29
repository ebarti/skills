#!/usr/bin/env bash
#
# install.sh — install the book-derived agent skills into one or more agents.
#
# How it works:
#   1. Clones (or updates) this repo into a single managed location.
#   2. Symlinks each skill folder from that clone into the directory each target
#      agent reads from.
#
# Because every install is a symlink back to one clone, updating is just:
#       cd <clone> && git pull        # every agent picks up the changes instantly
#
# Skills are plain "Agent Skills" folders (a SKILL.md plus reference files).
# Supported targets and where they look (user/global scope):
#
#   Claude       ~/.claude/skills/<skill>            -> clone/<skill>
#   Codex        ~/.agents/skills/<skill>            -> clone/<skill>
#   Gemini       ~/.gemini/extensions/skills-from-books/skills/<skill>  (+ manifest)
#   Antigravity  ~/.gemini/antigravity/skills/<skill>
#
# Usage:
#   ./install.sh                      # interactive picker
#   ./install.sh --all                # install to every supported agent
#   ./install.sh --targets claude,codex
#   ./install.sh --project            # symlink into the current repo (project scope)
#   ./install.sh --clone-dir <path>   # where to keep the managed clone
#   ./install.sh --list               # list the skills that would be installed
#   ./install.sh --dry-run --all      # show what would happen, change nothing
#   ./install.sh --help
#
# Env:
#   SKILLS_HOME   default managed-clone location (default: ~/.skills-from-books)
#   SKILLS_REPO   git URL to clone (default: https://github.com/ebarti/skills.git)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEMINI_EXT_NAME="skills-from-books"
DEFAULT_REPO="https://github.com/ebarti/skills.git"
SKILLS_REPO="${SKILLS_REPO:-$DEFAULT_REPO}"
CLONE_DIR="${SKILLS_HOME:-$HOME/.skills-from-books}"

# ---- pretty output -----------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; RESET="$(printf '\033[0m')"
  BLUE="$(printf '\033[34m')"; GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"; RED="$(printf '\033[31m')"
else
  BOLD=""; DIM=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""; RED=""
fi
info()  { printf '%s\n' "$*"; }
ok()    { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
err()   { printf '%s✗%s %s\n' "$RED" "$RESET" "$*" >&2; }

# Read from the terminal even when the script is piped (curl ... | bash).
read_tty() {
  if [ -r /dev/tty ]; then read "$@" </dev/tty; else read "$@"; fi
}

# ---- supported targets -------------------------------------------------------
ALL_TARGETS="claude codex gemini antigravity"

target_label() {
  case "$1" in
    claude)      echo "Claude (Claude Code / Claude apps)";;
    codex)       echo "Codex (OpenAI Codex CLI / IDE / app)";;
    gemini)      echo "Gemini CLI (bundled as an extension)";;
    antigravity) echo "Antigravity (Google agentic IDE)";;
    *)           echo "$1";;
  esac
}

# Destination skills directory for a target at a given scope (user|project).
dest_dir() {
  local target="$1" scope="$2" base
  if [ "$scope" = "project" ]; then base="$(pwd)"; else base="$HOME"; fi
  case "$target" in
    claude)      echo "$base/.claude/skills";;
    codex)       echo "$base/.agents/skills";;
    gemini)      echo "$base/.gemini/extensions/$GEMINI_EXT_NAME/skills";;
    antigravity) if [ "$scope" = "project" ]; then echo "$base/.agent/skills"; else echo "$base/.gemini/antigravity/skills"; fi;;
    *)           return 1;;
  esac
}

# ---- discover skills (in the managed clone) ----------------------------------
discover_skills() {
  local d
  for d in "$CLONE_DIR"/*/; do
    [ -f "${d}SKILL.md" ] && basename "$d"
  done
}

# ---- args --------------------------------------------------------------------
SCOPE="user"
DRY_RUN=0
SELECTED=""
NONINTERACTIVE=0
NO_CLONE=0

usage() {
  cat <<EOF
${BOLD}Install book-derived agent skills (clone + symlink)${RESET}

${BOLD}Usage:${RESET}
  ./install.sh [options]

${BOLD}Options:${RESET}
  --all                 Install to every supported agent (Claude, Codex, Gemini, Antigravity)
  --targets <list>      Comma-separated subset, e.g. --targets claude,codex
  --project             Symlink into the current directory (project scope) instead of user/global
  --user                Symlink into the user/global config (default)
  --clone-dir <path>    Where to keep the managed clone (default: \$SKILLS_HOME or ~/.skills-from-books)
  --source <path>       Use an existing skills dir as-is (no git clone/pull); used by the Homebrew wrapper
  --list                List the skills that would be installed, then exit
  --dry-run             Print actions without writing anything
  -h, --help            Show this help

Updating later:  cd "$CLONE_DIR" && git pull   (all symlinked installs update at once)

With no target flags, an interactive picker is shown.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)         SELECTED="$ALL_TARGETS"; NONINTERACTIVE=1;;
    --targets)     shift; SELECTED="$(echo "${1:-}" | tr ',' ' ')"; NONINTERACTIVE=1;;
    --targets=*)   SELECTED="$(echo "${1#*=}" | tr ',' ' ')"; NONINTERACTIVE=1;;
    --project)     SCOPE="project";;
    --user)        SCOPE="user";;
    --clone-dir)   shift; CLONE_DIR="${1:?--clone-dir needs a path}";;
    --clone-dir=*) CLONE_DIR="${1#*=}";;
    --source)      shift; CLONE_DIR="${1:?--source needs a path}"; NO_CLONE=1;;
    --source=*)    CLONE_DIR="${1#*=}"; NO_CLONE=1;;
    --dry-run)     DRY_RUN=1;;
    --list)        LIST_ONLY=1;;
    -h|--help)     usage; exit 0;;
    *)             err "Unknown option: $1"; usage; exit 1;;
  esac
  shift
done

run() {  # echo + execute, respecting --dry-run
  if [ "$DRY_RUN" -eq 1 ]; then info "    ${DIM}\$ $*${RESET}"; else "$@"; fi
}

# ---- obtain / update the managed clone ---------------------------------------
ensure_clone() {
  # --source: use a pre-existing skills directory as-is (e.g. a Homebrew Cellar
  # path). No git involved; updates happen via whatever manages that dir.
  if [ "$NO_CLONE" -eq 1 ]; then
    [ -d "$CLONE_DIR" ] || { err "--source path not found: $CLONE_DIR"; exit 1; }
    info "${DIM}Using skills source:${RESET} $CLONE_DIR"
    return
  fi

  # If the script lives inside a git checkout of this repo, treat that as the
  # managed clone (the user already cloned it; let them manage it in place)
  # unless they explicitly asked for a different --clone-dir / $SKILLS_HOME.
  if [ -z "${SKILLS_HOME:-}" ] && [ "$CLONE_DIR" = "$HOME/.skills-from-books" ] \
     && [ -d "$SCRIPT_DIR/.git" ] && ls "$SCRIPT_DIR"/*/SKILL.md >/dev/null 2>&1; then
    CLONE_DIR="$SCRIPT_DIR"
    info "${DIM}Using existing checkout as the managed clone:${RESET} $CLONE_DIR"
    return
  fi

  if [ -d "$CLONE_DIR/.git" ]; then
    info "${DIM}Updating managed clone:${RESET} $CLONE_DIR"
    run git -C "$CLONE_DIR" pull --ff-only
  else
    command -v git >/dev/null 2>&1 || { err "git is required to clone $SKILLS_REPO"; exit 1; }
    info "${DIM}Cloning${RESET} $SKILLS_REPO ${DIM}→${RESET} $CLONE_DIR"
    run git clone --depth 1 "$SKILLS_REPO" "$CLONE_DIR"
  fi
}

# ---- install -----------------------------------------------------------------
link_skill() {
  local src="$1" dst_dir="$2" name; name="$(basename "$src")"
  local target="$dst_dir/$name"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "    ${DIM}link${RESET} $target → $src"
    return
  fi
  rm -rf "$target"                 # replace a previous copy or stale link
  ln -s "$src" "$target"
}

write_gemini_manifest() {
  local ext_root="$1" manifest="$1/gemini-extension.json"
  if [ "$DRY_RUN" -eq 1 ]; then info "    ${DIM}write${RESET} $manifest"; return; fi
  cat > "$manifest" <<'JSON'
{
  "name": "skills-from-books",
  "version": "1.0.0",
  "description": "Agent skills distilled from technical books (AI Engineering, DDIA, Context Engineering, and more)."
}
JSON
}

install_target() {
  local target="$1" dst skill count=0
  dst="$(dest_dir "$target" "$SCOPE")" || { err "Unknown target: $target"; return 1; }

  info ""
  info "${BLUE}${BOLD}→ ${target} ${RESET}${DIM}(${SCOPE})${RESET}"
  info "  ${DIM}$dst${RESET}"

  run mkdir -p "$dst"

  for skill in $SKILLS; do
    link_skill "$CLONE_DIR/$skill" "$dst"
    count=$((count+1))
  done

  [ "$target" = "gemini" ] && write_gemini_manifest "$(dirname "$dst")"

  ok "$count skill(s) linked for ${target}"
}

# ---- interactive picker ------------------------------------------------------
pick_targets() {
  local i=1 t names=() choice out=""
  info "${BOLD}Where should the skills be installed?${RESET}"
  for t in $ALL_TARGETS; do
    printf "  %s%d%s) %s\n" "$BOLD" "$i" "$RESET" "$(target_label "$t")"
    names[$i]="$t"; i=$((i+1))
  done
  printf "  %sa%s) All of the above\n" "$BOLD" "$RESET"
  printf "\n%sSelect (e.g. 1,3 or a):%s " "$DIM" "$RESET"
  read_tty -r choice || choice=""
  choice="$(echo "$choice" | tr 'A-Z' 'a-z' | tr ',' ' ')"
  case " $choice " in
    *" a "*|*" all "*) out="$ALL_TARGETS";;
    *)
      for c in $choice; do
        case "$c" in
          ''|*[!0-9]*) [ -n "$c" ] && warn "Ignoring invalid choice: $c";;
          *) if [ -n "${names[$c]:-}" ]; then out="$out ${names[$c]}"; else warn "No such option: $c"; fi;;
        esac
      done;;
  esac
  SELECTED="$(echo $out | tr ' ' '\n' | awk 'NF&&!seen[$0]++' | tr '\n' ' ')"
}

# ---- main --------------------------------------------------------------------
info "${BOLD}📚 Skills from Books — installer${RESET}"

ensure_clone

SKILLS="$(discover_skills | tr '\n' ' ')"
if [ -z "${SKILLS// }" ]; then
  err "No skills found in $CLONE_DIR (looked for */SKILL.md)."
  exit 1
fi
SKILL_COUNT="$(echo $SKILLS | wc -w | tr -d ' ')"

if [ "${LIST_ONLY:-0}" -eq 1 ]; then
  info "${BOLD}Skills ($SKILL_COUNT):${RESET}"
  for s in $SKILLS; do info "  • $s"; done
  exit 0
fi

info "${DIM}$SKILL_COUNT skill(s) available in $CLONE_DIR${RESET}"

if [ -z "${SELECTED// }" ] && [ "$NONINTERACTIVE" -eq 0 ]; then
  info ""
  pick_targets
fi

if [ -z "${SELECTED// }" ]; then
  warn "No targets selected. Nothing to do."
  exit 0
fi

for t in $SELECTED; do
  case " $ALL_TARGETS " in
    *" $t "*) ;;
    *) err "Unsupported target: '$t' (supported: $ALL_TARGETS)"; exit 1;;
  esac
done

[ "$DRY_RUN" -eq 1 ] && warn "Dry run — no changes will be made."

for t in $SELECTED; do
  install_target "$t"
done

info ""
ok "Done."
if [ "$NO_CLONE" -eq 1 ]; then
  info "${DIM}Skills update in place when you run:${RESET} brew upgrade skills"
else
  info "${DIM}Update everything later with:${RESET} cd \"$CLONE_DIR\" && git pull"
fi
