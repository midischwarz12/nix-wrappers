#! @bash@

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

set -euo pipefail

MAKE_WRAPPER="@out@/bin/makeWrapper"
MAKE_WRAPPER_NATIVE="@out@/bin/makeWrapperNative"
WRAP_PROGRAM="@out@/bin/wrapProgram"

usage() {
  cat <<'EOF'
nix-wrappers <make|wrap|help> [options]

Commands:
  make  --exec <path> --out <path> [wrapper options...]   Create a new wrapper at OUT.
  wrap  --exec <path> [wrapper options...]                Replace EXEC in-place with a wrapper.
  help                                                    Show this help text.

Common options (forwarded to underlying makeWrapper/wrapProgram):
  --argv0 NAME
  --inherit-argv0
  --resolve-argv0
  --chdir DIR
  --run CMD
  --add-flag ARG | --append-flag ARG
  --add-flags ARGS | --append-flags ARGS
  --set VAR VAL | --set-default VAR VAL | --unset VAR
  --prefix ENV SEP VAL | --suffix ENV SEP VAL
  --prefix-each ENV SEP VALS | --suffix-each ENV SEP VALS
  --prefix-contents ENV SEP FILES | --suffix-contents ENV SEP FILES

make-specific:
  --native            Use the compiled native wrapper generator (makeWrapperNative).

Notes:
- This CLI only reshuffles arguments for convenience; it forwards everything else unchanged.
- Unknown flags are passed through verbatim.
EOF
}

cmd=${1:-help}
shift || true

case "$cmd" in
  help|-h|--help)
    usage
    ;;

  make)
    exec_path=""
    out_path=""
    forward=()
    use_native=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --exec|-e)
          exec_path=${2-}
          shift 2 || true
          ;;
        --out|-o)
          out_path=${2-}
          shift 2 || true
          ;;
        --native)
          use_native=true
          shift
          ;;
        -h|--help|help)
          usage; exit 0;
          ;;
        *)
          forward+=("$1")
          shift
          ;;
      esac
    done

    if [[ -z "$exec_path" || -z "$out_path" ]]; then
      echo "error: make requires --exec <path> and --out <path>" >&2
      usage
      exit 1
    fi

    if $use_native; then
      exec "$MAKE_WRAPPER_NATIVE" "$exec_path" "$out_path" "${forward[@]}"
    else
      exec "$MAKE_WRAPPER" "$exec_path" "$out_path" "${forward[@]}"
    fi
    ;;

  wrap)
    exec_path=""
    forward=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --exec|-e)
          exec_path=${2-}
          shift 2 || true
          ;;
        -h|--help|help)
          usage; exit 0;
          ;;
        *)
          forward+=("$1")
          shift
          ;;
      esac
    done

    if [[ -z "$exec_path" ]]; then
      echo "error: wrap requires --exec <path>" >&2
      usage
      exit 1
    fi

    exec "$WRAP_PROGRAM" "$exec_path" "${forward[@]}"
    ;;

  *)
    echo "error: unknown command '$cmd'" >&2
    usage
    exit 1
    ;;
esac
