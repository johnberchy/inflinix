#!/usr/bin/env bash
# Inflinix - from a clean clone to the load-bearing proof, in one command.
#   ./reproduce.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> 1/3  Environment"
[ -d .venv ] || python3 -m venv .venv
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt pytest

echo "==> 2/3  Tests"
.venv/bin/python -m pytest -q

echo "==> 3/3  Fresh-session recall + deletion test (real accred Memory)"
MEMORY_DRIVER=accred ACCRED_MEMORY_DB=./demo.db ACCRED_KEY_ID=meritor-demo \
  PY=.venv/bin/python ./demo/fresh_session_demo.sh

echo
echo "Done. Launch the web frontend with:  make web   (http://127.0.0.1:8848)"
