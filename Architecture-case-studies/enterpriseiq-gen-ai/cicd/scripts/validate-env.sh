#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  dev|prod) echo "Selected environment: $1" ;;
  *) echo "ENV must be dev or prod" >&2; exit 1 ;;
esac
