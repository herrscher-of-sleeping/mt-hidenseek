import os
import subprocess

MINETEST_BINARY = "../../bin/minetest"

server_cmd = [MINETEST_BINARY, "--server", "--go", "--gameid", "minetest_game", "--worldname", "hs"]
server_pid = subprocess.Popen(server_cmd).pid
subprocess.Popen(["sleep", "1"]).wait()

hiders = [
    "hider1",
    "hider2",
    "hider3",
]

hiders_pids = []

for hider in hiders:
    print("hider: " + hider)
    cmd = [MINETEST_BINARY, "--go", "--address", "127.0.0.1", "--port", "30000", "--name", hider]
    pid = subprocess.Popen(cmd).pid
    hiders_pids.append(pid)

subprocess.Popen(["sleep", "0.1"]).wait()
cmd = [MINETEST_BINARY, "--go", "--address", "127.0.0.1", "--port", "30000", "--name", "seeker1"]
subprocess.Popen(cmd).wait()

for pid in hiders_pids:
    os.kill(pid, 9)

os.kill(server_pid, 9)
