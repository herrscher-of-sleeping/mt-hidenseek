#!/usr/bin/env bash

server_ip="${MINETEST_SERVER_IP:=127.0.0.1}"
n_clients=$1
server_pid=
client_pids=

MINETEST:=minetest

run_server()
{
	$MINETEST --server --gameid mineclone5_novillagers --world hs2 --port 30000 hs2 > logs/server.log 2>&1 &
	server_pid=$!
}

hide_window()
{
	if command -v wmctrl; then
		current_desktop=$(wmctrl -d | awk '{ if ($2 == "*") print $0}' | cut -d " " -f1)
		next_desktop=$(expr $current_desktop + 1)
		window_pid=$1
		window_id=$(wmctrl -lp | grep $window_pid | head -1 | cut -d " " -f1)
		wmctrl -ir $window_id -t $next_desktop
	fi
}

run_client()
{
	username=player_$1
	# first user is the one we control
	if [ $1 -eq 1 ]; then
		custom_flags=""
	else
		custom_flags="--random-input"
	fi
	$MINETEST --go $custom_flags --address $server_ip --port 30000 \
		--name $username --password totally_random_password > logs/client_$1.log 2>&1 &
	client_pids[$1]=$!
	if [ $1 -eq 1 ]; then
		echo ""
	else
		sleep 0.2
		hide_window $!
	fi
}

run_server_and_clients()
{
	run_server
	echo "server pid: $server_pid"

	for i in `seq 1 $n_clients`
	do
		run_client $i
		echo "client #$i pid ${client_pids[$i]}"
	done
}

try_kill()
{
	if ps --pid $1 > /dev/null ; then
		kill -9 $1
	fi
}

on_exit()
{
	echo "Exit, killing server and all clients..."
	try_kill $server_pid
	for i in `seq 1 $n_clients`
	do
		try_kill ${client_pids[$i]}
	done
	echo "Done"
	exit 0
}

rm -rf logs/*
mkdir -p logs/
run_server_and_clients

trap on_exit SIGINT

wait $server_pid
on_exit

