#!/usr/bin/env python3
# Source of truth: SCRIPTS/githubactions. Generated copies are overwritten.

import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("usage: patch-vikunja-mcp.py PATH")

path = Path(sys.argv[1])
old = "this.request('/tasks/all', 'GET'"
new = "this.request('/tasks', 'GET'"
source = path.read_text()
if source.count(old) != 1:
    raise SystemExit(f"unexpected node-vikunja source: {path}")
path.write_text(source.replace(old, new))
