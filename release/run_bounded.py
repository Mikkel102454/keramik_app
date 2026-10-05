"""Run local validation with a hard wall-clock bound, killing its owned process tree."""
import argparse
import os
import subprocess
import sys

p = argparse.ArgumentParser()
p.add_argument("--seconds", type=int, required=True)
p.add_argument("--cwd", required=True)
p.add_argument("command", nargs=argparse.REMAINDER)
a = p.parse_args()
command = a.command[1:] if a.command[:1] == ["--"] else a.command
if not command or a.seconds <= 0:
    p.error("a positive timeout and command are required")
if os.name == "nt" and command[0].endswith((".bat", ".cmd")):
    command[0] = command[0].replace("/", "\\")
    command = ["cmd.exe", "/d", "/c", *command]
child = subprocess.Popen(command, cwd=a.cwd)
try:
    sys.exit(child.wait(timeout=a.seconds))
except subprocess.TimeoutExpired:
    print(f"TIMEOUT after {a.seconds}s; stopping owned validation process tree", flush=True)
    if os.name == "nt":
        subprocess.run(["taskkill", "/PID", str(child.pid), "/T", "/F"], check=False)
    else:
        child.kill()
    child.wait(timeout=15)
    sys.exit(124)
