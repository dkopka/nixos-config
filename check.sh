#!/usr/bin/env bash
# check.sh — local verification for the ThinkPad NixOS config (see TESTING.md).
#
# Runs the tiers that work on ANY platform, including this aarch64 MacBook:
# Nix *evaluation* is platform-independent, so the full module system —
# option names, types, merges, assertions — is verified here even though the
# target is x86_64-linux. Building/booting (tiers 3-4) happens in CI.
#
# Usage:
#   ./check.sh            tiers 1+2: syntax + full evaluation (default, pre-commit gate)
#   ./check.sh eval       tier 2 only
#   ./check.sh lint       statix + deadnix (downloads the linters on first run)
#   ./check.sh all        everything above
#   ./check.sh ci-eval    what CI runs: eval thinkpad-ci only (no private layer needed)
#
# Any extra args go to nix, e.g.:  ./check.sh eval --show-trace
set -euo pipefail
cd "$(dirname "$0")"

MODE="${1:-default}"; shift 2>/dev/null || true
NIXOPTS=(--extra-experimental-features "nix-command flakes" "$@")

# `path:.` is deliberate: it copies the tree UNFILTERED, so the gitignored
# private/ layer stays visible to the flake. A bare `.` would hide it.
FLAKE="path:$PWD"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\033[31mFAIL\033[0m %s\n' "$*"; exit 1; }
ok()   { printf '\033[32m ok \033[0m %s\n' "$*"; }

##############################################################################
# Step 0 — is Nix installed?
##############################################################################
if ! command -v nix >/dev/null 2>&1; then
  cat <<'EOF'
Nix is not installed on this machine. Recommended installer for macOS
(survives OS updates, includes flakes out of the box):

    curl -fsSL https://install.determinate.systems/nix | sh -s -- install

Official alternative:  sh <(curl -L https://nixos.org/nix/install)
Then open a new shell and re-run ./check.sh
EOF
  exit 1
fi

##############################################################################
# Tier 1 — syntax: parse every .nix file (fast, no downloads)
##############################################################################
tier_syntax() {
  bold "tier 1: parse all .nix files"
  local f rc=0
  while IFS= read -r f; do
    if ! nix-instantiate --parse "$f" >/dev/null 2>/tmp/nix-parse-err; then
      printf '\033[31mparse error\033[0m %s\n' "$f"; cat /tmp/nix-parse-err; rc=1
    fi
  done < <(find . -name '*.nix' -not -path './.git/*')
  [ "$rc" -eq 0 ] || fail "syntax"
  ok "all .nix files parse"
}

##############################################################################
# Tier 2 — full evaluation of the system derivation(s).
# Forces the toplevel drvPath: every module is imported, every option value
# type-checked, every NixOS assertion executed. Catches ~most config bugs.
##############################################################################
eval_one() {
  local attr="$1"
  bold "tier 2: evaluate nixosConfigurations.${attr}"
  nix eval "${NIXOPTS[@]}" --raw \
    "$FLAKE#nixosConfigurations.${attr}.config.system.build.toplevel.drvPath" \
    >/dev/null || fail "evaluation of ${attr}"
  ok "${attr} evaluates to a system derivation"
}

tier_eval() {
  if [ -f private/hardware-configuration.nix ]; then
    eval_one thinkpad          # the real config, private layer included
  else
    echo "note: private/ not present — skipping the real 'thinkpad' (CI-style checkout)"
  fi
  eval_one thinkpad-ci         # what CI builds/boots — keep it evaluating too
}

##############################################################################
# Lint — statix (anti-patterns) + deadnix (dead code)
##############################################################################
tier_lint() {
  bold "lint: statix"
  nix run "${NIXOPTS[@]}" nixpkgs#statix -- check . || fail "statix"
  ok "statix"
  bold "lint: deadnix"
  # --no-lambda-pattern-names: module headers keep the conventional
  # { config, lib, pkgs, ... }: signature even when an arg is unused —
  # that's NixOS module style, not dead code.
  nix run "${NIXOPTS[@]}" nixpkgs#deadnix -- --fail --no-lambda-pattern-names . \
    || fail "deadnix"
  ok "deadnix"
}

case "$MODE" in
  default) tier_syntax; tier_eval ;;
  eval)    tier_eval ;;
  lint)    tier_lint ;;
  all)     tier_syntax; tier_lint; tier_eval ;;
  ci-eval) eval_one thinkpad-ci ;;
  *)       fail "unknown mode '$MODE' (default|eval|lint|all|ci-eval)" ;;
esac

bold "local checks passed — tiers 3-4 (x86_64 build + VM boot) run in GitHub Actions"
