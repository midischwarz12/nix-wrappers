#! @bash@

# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

set -euo pipefail

PYTHON=@python@
RUNNER=@runner@

WRAPPER_RUNNER=$RUNNER exec "$PYTHON" - <<'PY'
import argparse
import os
import pathlib
import shutil
import struct
import sys

MARKER = b"WRAPCFG1"


def main():
    parser = argparse.ArgumentParser(
        description="Generate a native wrapper binary without a shell dependency."
    )

    parser.add_argument("exec", help="Executable to wrap")
    parser.add_argument("out", help="Output path for the wrapper")

    parser.add_argument("--argv0", dest="argv0", default=None)
    parser.add_argument("--chdir", dest="chdir", default=None)
    parser.add_argument("--run", dest="runs", action="append", default=[])
    parser.add_argument("--add-flag", dest="prefix_args", action="append", default=[])
    parser.add_argument("--append-flag", dest="suffix_args", action="append", default=[])
    parser.add_argument("--set", dest="sets", action="append", nargs=2, metavar=("VAR", "VAL"), default=[])
    parser.add_argument("--set-default", dest="set_defaults", action="append", nargs=2, metavar=("VAR", "VAL"), default=[])
    parser.add_argument("--unset", dest="unsets", action="append", metavar="VAR", default=[])
    parser.add_argument("--prefix", dest="prefixes", action="append", nargs=3, metavar=("ENV", "SEP", "VAL"), default=[])
    parser.add_argument("--suffix", dest="suffixes", action="append", nargs=3, metavar=("ENV", "SEP", "VAL"), default=[])

    args = parser.parse_args()

    cfg_lines = [f"exec={args.exec}"]
    if args.argv0:
        cfg_lines.append(f"argv0={args.argv0}")
    if args.chdir:
        cfg_lines.append(f"chdir={args.chdir}")

    for cmd in args.runs:
        cfg_lines.append(f"preRun={cmd}")

    for val in args.prefix_args:
        cfg_lines.append(f"prefixArg={val}")
    for val in args.suffix_args:
        cfg_lines.append(f"suffixArg={val}")

    for var, val in args.sets:
        cfg_lines.append(f"set={var}={val}")
    for var, val in args.set_defaults:
        cfg_lines.append(f"setDefault={var}={val}")
    for var in args.unsets:
        cfg_lines.append(f"unset={var}")

    for env, sep, val in args.prefixes:
        cfg_lines.append(f"prefix={env}|{sep}|{val}")
    for env, sep, val in args.suffixes:
        cfg_lines.append(f"suffix={env}|{sep}|{val}")

    payload = "\n".join(cfg_lines) + "\n"
    payload_bytes = payload.encode()

    out_path = pathlib.Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    runner = os.environ["WRAPPER_RUNNER"]

    with open(runner, "rb") as src, open(out_path, "wb") as dst:
        shutil.copyfileobj(src, dst)
        dst.write(MARKER)
        dst.write(payload_bytes)
        dst.write(struct.pack("<I", len(payload_bytes)))

    os.chmod(out_path, 0o755)


if __name__ == "__main__":
    main()
PY
