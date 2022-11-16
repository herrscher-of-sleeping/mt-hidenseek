local HideNSeek

local matchmaking_queue = {
  _awaiting_players = {},
  _awaiting_players_set = {},
}

function matchmaking_queue.add_player(player)
  if not matchmaking_queue._awaiting_players_set[player] then
    table.insert(matchmaking_queue._awaiting_players, player)
    matchmaking_queue._awaiting_players_set[player] = true
  end
end

HideNSeek.matchmaking_queue = matchmaking_queue
