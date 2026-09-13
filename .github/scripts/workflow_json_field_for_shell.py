#!/usr/bin/env python3
"""Emit a JSON document field as a shell-comparable token.

Workflows must not use ``print(json.load(...)["field"])`` for booleans: Python
prints ``True``/``False``, which never matches ``[[ "$value" == "true" ]]``.
``json.dumps`` preserves JSON literals (``true``/``false``).
"""

from __future__ import annotations

import json
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: workflow_json_field_for_shell.py <json-path> <field-name>", file=sys.stderr)
        return 2
    path, field = sys.argv[1], sys.argv[2]
    document = json.load(open(path, encoding="utf-8"))
    if field not in document:
        print(f"missing field {field!r} in {path}", file=sys.stderr)
        return 1
    print(json.dumps(document[field]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
