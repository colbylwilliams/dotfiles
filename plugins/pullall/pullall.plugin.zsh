#!/usr/bin/env zsh
# pullall - Pull latest main for a list of repos
#
# Configure in .zshrc (after sourcing oh-my-zsh):
#
#   PULLALL_REPOS=(
#     "org/repo-one"
#     "org/repo-two"
#   )
#
# Repos are relative to PULLALL_ROOT. Default root:
#   ~/GitHub           on macOS / standard Linux
#   /workspaces        in GitHub Codespaces
#
# Optional overrides:
#   PULLALL_ROOT="$HOME/repos"     # base directory
#   PULLALL_TIMEOUT=60             # per-repo timeout in seconds (default: 30)

pullall() {
  if (( ! ${#PULLALL_REPOS[@]} )); then
    echo "pullall: no repos configured."
    echo ""
    echo "Add PULLALL_REPOS to your .zshrc (after sourcing oh-my-zsh):"
    echo ""
    echo '  PULLALL_REPOS=('
    echo '    "org/repo-one"'
    echo '    "org/repo-two"'
    echo '  )'
    echo ""
    echo "Repos are relative to \${PULLALL_ROOT:-\$HOME/GitHub}."
    return 1
  fi

  local default_root="$HOME/GitHub"
  if [[ -n "$CODESPACES" ]]; then
    default_root="/workspaces"
  fi

  local root="${PULLALL_ROOT:-$default_root}"
  local timeout_secs="${PULLALL_TIMEOUT:-30}"

  # Summary accumulators
  local -a pulled=()
  local -a skipped=()
  local -a failed=()
  local -a missing=()

  local total=${#PULLALL_REPOS[@]}
  local current=0

  for repo in "${PULLALL_REPOS[@]}"; do
    (( current++ ))
    local dir="$root/$repo"

    echo ""
    echo "━━━ [$current/$total] $repo ━━━"

    if [[ ! -d "$dir" ]]; then
      echo "⚠️  directory not found, skipping"
      missing+=("$repo")
      continue
    fi

    # Run in a subshell so cd never leaks to the parent or other iterations
    local result
    result=$(
      cd "$dir" || exit 1

      local branch
      branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

      if [[ "$branch" != "main" ]]; then
        echo "SKIPPED:on branch '$branch'"
        exit 0
      fi

      # GIT_TERMINAL_PROMPT=0 prevents credential popups from hanging the shell.
      # --ff-only refuses to create merge commits, so the pull never opens an
      # editor or pauses for conflict resolution.
      local output
      output=$(GIT_TERMINAL_PROMPT=0 git pull --ff-only 2>&1 &
        local pid=$!
        (
          sleep "$timeout_secs"
          kill "$pid" 2>/dev/null
        ) &
        local watchdog=$!
        wait "$pid" 2>/dev/null
        local rc=$?
        kill "$watchdog" 2>/dev/null
        wait "$watchdog" 2>/dev/null
        exit "$rc"
      )
      local rc=$?

      if [[ $rc -ne 0 ]]; then
        echo "FAILED:$output"
        exit 1
      fi

      echo "PULLED:$output"
      exit 0
    )
    local rc=$?

    # Parse the structured result
    local tag="${result%%:*}"
    local body="${result#*:}"

    case "$tag" in
      SKIPPED)
        echo "⏭️  $body"
        skipped+=("$repo ($body)")
        ;;
      PULLED)
        echo "✅  $body"
        pulled+=("$repo")
        ;;
      FAILED)
        echo "🚨  pull failed"
        echo "$body"
        failed+=("$repo")
        ;;
      *)
        echo "🚨  unexpected error"
        [[ -n "$result" ]] && echo "$result"
        failed+=("$repo")
        ;;
    esac
  done

  # ── Summary ──
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋  Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if (( ${#pulled} )); then
    echo "  ✅  Pulled:  ${#pulled}"
    for r in "${pulled[@]}"; do echo "        $r"; done
  fi
  if (( ${#skipped} )); then
    echo "  ⏭️   Skipped: ${#skipped}"
    for r in "${skipped[@]}"; do echo "        $r"; done
  fi
  if (( ${#missing} )); then
    echo "  ❓  Missing: ${#missing}"
    for r in "${missing[@]}"; do echo "        $r"; done
  fi
  if (( ${#failed} )); then
    echo "  🚨  Failed:  ${#failed}"
    for r in "${failed[@]}"; do echo "        $r"; done
  fi

  echo ""

  (( ${#failed} )) && return 1
  return 0
}
