extends Node

var current_world_name: String = ""
var current_world_id: String = ""
var new_world: bool = false
var world_seed: int = 0
var appearance_seed: int = 0

var character: = "LEAFY"
var music: = true
var creative: = false

static func safe_name(raw: String) -> String:
	var s: = raw.strip_edges()
	if s.is_empty():
		s = "World_%d" % int(Time.get_unix_time_from_system())
	var re: = RegEx.new();re.compile("[^A-Za-z0-9_-]+")
	return re.sub(s, "_", true)
