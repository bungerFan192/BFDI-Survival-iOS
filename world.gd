extends Node2D


@onready var player_number: Label = $CanvasLayer / PlayerNumber

var player_numbers: = {}
var next_player_number: int = 2
var my_player_number: int = 0
var _held_item_by_peer: Dictionary = {}

const CHUNK_SIZE: = 64
const BASE_SURFACE_Y: = 40


const BIOME_FREQ: = 0.0009
const PLAINS_AMP: = 4
const PLAINS_FREQ: = 0.015
const HILLS_AMP: = 10
const HILLS_FREQ: = 0.025
const MOUNTAINS_AMP: = 22
const MOUNTAINS_FREQ: = 0.045

const MAX_SLOPE_STEP: = 2
const FILL_DEPTH: = 96


const CAVE_FREQ: = 0.06
const CAVE_OCTAVES: = 3
const CAVE_THRESHOLD: = 0.58
const CAVE_SAFE_DEPTH: = 3


const SOIL_DEPTH: = 4
const MOUNTAIN_SOIL: = 1


const SRC: = 0
const ACTIVE_RADIUS_CHUNKS: = 1


var chunk_rects: = {}


const STONE_NOISE_FREQ: = 0.12
const STONE_THRESHOLD: = 0.42
const STONE_START_PLAINS: = 10
const STONE_START_MOUNTAIN: = 4


const CAVESTONE_FREQ: = 0.25
const CAVESTONE_THRESHOLD: = 0.53


const BREAK_REACH_CELLS: = 2
const BREAK_COOLDOWN: = 0.12


const BREAK_TIME_SURFACE: = 0.6
const BREAK_TIME_LOG: = 3
const BREAK_TIME_LEAVES: = 0.4
const BREAK_TIME_STONE: = 5
const BREAK_TIME_FALLBACK: = 0.55


const BREAK_TIME_MIN: = 0.05


const TOOL_BREAK_BONUS_SEC: = {
	ITEM_WOODEN_SHOVEL: {"grass": 0.15, "snow": 0.15, "sand": 0.15, "gravel": 0.15}, 
	ITEM_STONE_SHOVEL: {"grass": 0.3, "snow": 0.3, "sand": 0.3, "gravel": 0.3}, 
	ITEM_IRON_SHOVEL: {"grass": 0.4, "snow": 0.4, "sand": 0.4, "gravel": 0.4}, 
	ITEM_YOYLITE_SHOVEL: {"grass": 0.55, "snow": 0.55, "sand": 0.55, "gravel": 0.55}, 

	ITEM_WOODEN_PICKAXE: {"stone": 2}, 
	ITEM_STONE_PICKAXE: {"stone": 3}, 
	ITEM_IRON_PICKAXE: {"stone": 4}, 
	ITEM_YOYLITE_PICKAXE: {"stone": 4.8}, 

	ITEM_WOODEN_AXE: {"wood": 1.0}, 
	ITEM_STONE_AXE: {"wood": 1.5}, 
	ITEM_IRON_AXE: {"wood": 2.0}, 
	ITEM_YOYLITE_AXE: {"wood": 2.8}, 
}


var removed_cells: = {}
var cell_overrides: = {}


const BREAK_HOLD_TIME: = 0.55
const BREAK_DECAY_TIME: = 0.35


var _break_progress: = {}

var local_player: CharacterBody2D
var mining: AudioStreamPlayer2D
var mined: AudioStreamPlayer2D

var _world_inited: = false


const CLOUDS_PER_CHUNK_MIN: = 1
const CLOUDS_PER_CHUNK_MAX: = 3
const CLOUD_MIN_SEPARATION: = 500.0
const CLOUD_X_PADDING: = 64.0
const CLOUD_Y_MIN: = 2000.0
const CLOUD_Y_MAX: = 2800.0
const CLOUD_ALPHA: = 0.6
const CLOUD_SCALE_MIN: = 0.9
const CLOUD_SCALE_MAX: = 1.3


const CLOUD_TEXTURE_PATHS: = [
	"res://cloud1.png", 
	"res://cloud2.png", 
	"res://cloud3.png"
]

var chunk_clouds: = {}
var clouds_layer: Node2D


const ITEM_NONE: = 0
const ITEM_GRASS: = 1
const ITEM_DIRT: = 2
const ITEM_STONE: = 3
const ITEM_CAKE: = 4
const ITEM_LOG: = 5
const ITEM_LEAVES: = 6
const ITEM_CRAFT: = 7
const ITEM_STICK: = 8
const ITEM_STRING: = 9
const ITEM_WOODEN_PICKAXE: = 10
const ITEM_WOODEN_SWORD: = 11
const ITEM_WOODEN_AXE: = 12
const ITEM_WOODEN_SHOVEL: = 13
const ITEM_STONE_AXE: = 14
const ITEM_STONE_PICKAXE: = 15
const ITEM_STONE_SHOVEL: = 16
const ITEM_STONE_SWORD: = 17
const ITEM_IRON_STONE: = 18
const ITEM_COAL_STONE: = 19
const ITEM_COAL: = 20
const ITEM_RAW_IRON: = 21
const ITEM_IRON: = 22
const ITEM_OVEN: = 23
const ITEM_IRON_AXE: = 24
const ITEM_IRON_PICKAXE: = 25
const ITEM_IRON_SHOVEL: = 26
const ITEM_IRON_SWORD: = 27
const ITEM_SNOW: = 28
const ITEM_DARK_LEAVES: = 29
const ITEM_DARK_LOG: = 30
const ITEM_DARK_GRASS: = 31
const ITEM_SAND: = 32
const ITEM_CACTUS: = 33
const ITEM_WATER: = 34
const ITEM_AOU: = 35
const ITEM_DYNAMITE: = 36
const ITEM_LIGHTER: = 37
const ITEM_GOLDEN_CAKE: = 38
const ITEM_GOLD_STONE: = 39
const ITEM_RAW_GOLD: = 40
const ITEM_GOLD: = 41
const ITEM_YOYLE_GRASS: = 42
const ITEM_YOYLE_LOG: = 43
const ITEM_YOYLE_LEAVES: = 44
const ITEM_BUSH_LOG: = 45
const ITEM_BUSH_LEAVES: = 46
const ITEM_BUSH_LEAVES_BERRIES: = 47
const ITEM_YOYLEBERRY: = 48
const ITEM_BLUE_CONCRETE: = 49
const ITEM_YELLOW_CONCRETE: = 50
const ITEM_PURPLE_CONCRETE: = 51
const ITEM_RED_CONCRETE: = 52
const ITEM_GREEN_CONCRETE: = 53
const ITEM_BROWN_CONCRETE: = 54
const ITEM_WHITE_CONCRETE: = 55
const ITEM_WINDOW: = 56
const ITEM_POLE: = 57
const ITEM_SPHERE: = 58
const ITEM_STRIPE: = 59
const ITEM_PLATFORM: = 60
const ITEM_GOLDENBERRY: = 61
const ITEM_YOYLITE_STONE: = 62
const ITEM_YOYLITE: = 63
const ITEM_YOYLITE_AXE: = 64
const ITEM_YOYLITE_PICKAXE: = 65
const ITEM_YOYLITE_SHOVEL: = 66
const ITEM_YOYLITE_SWORD: = 67
const ITEM_YOYLE_CRYSTAL: = 68
const ITEM_VICTORY: = 69
const ITEM_LUCKY: = 70
const ITEM_YOYLITE_PEARL: = 71
const ITEM_YOYLITE_BOX: = 72
const ITEM_SPYGLASS: = 73
const ITEM_YOYLITE_ANCHOR_0: = 74
const ITEM_YOYLITE_ANCHOR_1: = 75
const ITEM_YOYLITE_ANCHOR_2: = 76
const ITEM_YOYLITE_ANCHOR_3: = 77
const ITEM_YOYLITE_ANCHOR_4: = 78
const ITEM_YOYLITE_WIRE: = 79
const ITEM_PISTON: = 80
const ITEM_STRINGY_PISTON: = 81
const ITEM_YOYLITE_EMITTER: = 82
const ITEM_LEVER: = 83
const ITEM_PISITON_EXTENDER: = 84
const ITEM_YOYLITE_DELAYER: = 85
const ITEM_STRING_BLOCK: = 86

func name_map_for_hotbar() -> Dictionary:
	return {
		1: "Grass", 
		2: "Dirt", 
		3: "Stone", 
		4: "Strawberry Cake Slice", 
		5: "Log", 
		6: "Leaves", 
		7: "Crafting Table", 
		8: "Stick", 
		9: "String", 
		10: "Wooden Pickaxe", 
		11: "Wooden Sword", 
		12: "Wooden Axe", 
		13: "Wooden Shovel", 
		14: "Stone Axe", 
		15: "Stone Pickaxe", 
		16: "Stone Shovel", 
		17: "Stone Sword", 
		18: "Iron Ore", 
		19: "Coal Ore", 
		20: "Coal", 
		21: "Raw Iron", 
		22: "Iron", 
		23: "Oven", 
		24: "Iron Axe", 
		25: "Iron Pickaxe", 
		26: "Iron Shovel", 
		27: "Iron Sword", 
		28: "Snow", 
		29: "Forest Leaves", 
		30: "Forest Log", 
		31: "Forest Grass", 
		32: "Sand", 
		33: "Cactus", 
		34: "Water", 
		35: "Announcer of Undying", 
		36: "Dynamite", 
		37: "Lighter", 
		38: "Golden Cake Slice", 
		39: "Gold Ore", 
		40: "Raw Gold", 
		41: "Gold", 
		42: "Yoyleland Grass", 
		43: "Yoyleland Log", 
		44: "Yoyleland Leaves", 
		45: "Bush Log", 
		46: "Bush Leaves", 
		47: "Bush Leaves with Yoyleberries", 
		48: "Yoyleberry", 
		49: "Blue Concrete", 
		50: "Yellow Concrete", 
		51: "Purple Concrete", 
		52: "Red Concrete", 
		53: "Green Concrete", 
		54: "Brown Concrete", 
		55: "White Concrete", 
		56: "Window", 
		57: "Pole", 
		58: "Sphere", 
		59: "Neon Green Stripe", 
		60: "Platform", 
		61: "Golden Berry", 
		62: "Yoylite Ore", 
		63: "Yoylite", 
		64: "Yoylite Axe", 
		65: "Yoylite Pickaxe", 
		66: "Yoylite Shovel", 
		67: "Yoylite Sword", 
		68: "Yoyle Crystal", 
		69: "Block of Victory", 
		70: "Lucky Block", 
		71: "Yoylite Pearl", 
		72: "Yoylite Box", 
		73: "Spyglass", 
		74: "Yoylite Anchor (No charge)", 
		75: "Yoylite Anchor (1 charge)", 
		76: "Yoylite Anchor (2 charges)", 
		77: "Yoylite Anchor (3 charges)", 
		78: "Yoylite Anchor (Fully charged)", 
		79: "Yoylite Wire", 
		80: "Piston", 
		81: "Stringy Piston", 
		82: "Yoylite Emitter", 
		83: "Lever", 
		84: "Piston Extender", 
		85: "Yoylite Delayer", 
		86: "String Block"
	}

const EXPLOSION_1 = preload("uid://ckrpyfy1fyxp2")
const EXPLOSION_2 = preload("uid://3i4w8kgnud05")
const EXPLOSION_3 = preload("uid://d2k3bvqknfdek")
const EXPLOSION_4 = preload("uid://cifsc24t2qcxe")
const FUSE = preload("uid://bq2x4s4oruycw")

const TELEPORT_1 = preload("uid://cdq0opuokx1vp")
const TELEPORT_2 = preload("uid://cy5va3sqwfnn6")
const THROW = preload("uid://cnpkj1dmvhtnp")

const SPYGLASS_STOP_OGG = preload("uid://cvvnxe44oiu0r")
const SPYGLASS_USE_OGG = preload("uid://c24in24fknfv1")
const RESPAWN_ANCHOR_CHARGE_1_OGG = preload("uid://buu5qgkqa8waj")
const RESPAWN_ANCHOR_CHARGE_2_OGG = preload("uid://beopsl3aeck1p")
const RESPAWN_ANCHOR_CHARGE_3_OGG = preload("uid://bsgsm4uo3fmvx")

const PEARL_THROW_SPEED: = 1020.0
const PEARL_UP_THROW: = 560.0
const PEARL_MAX_LIFETIME_S: = 10
const PEARL_RADIUS_PX: = 6.0
@onready var projectiles: Node2D = $Projectiles

var _last_pearl_at: = {}

@onready var ao_u: AnimatedSprite2D = $"CanvasLayer/Animation Anchor/AoU"


const EDIBLE_EFFECTS: = {
	ITEM_CAKE: {"hunger": 2, "heal": 0, "sat": 2, "absorb": 0, "regeneration": 0}, 
	ITEM_GOLDEN_CAKE: {"hunger": 4, "heal": 2, "sat": 3, "absorb": 2, "regeneration": 20}, 
	ITEM_YOYLEBERRY: {"hunger": 3, "heal": 0, "sat": 3, "absorb": 0, "regeneration": 0}, 
	ITEM_GOLDENBERRY: {"hunger": 5, "heal": 3, "sat": 4, "absorb": 3, "regeneration": 30}, 
}

var _pending_place: = {}

var _next_pickup_id: = 1
var _server_pickups: = {}
var pickups: = {}


const PATH_CAKE: = "res://food/Cake Slice Strawberry.png"
const PATH_STICK: = "res://items/stick.png"
const PATH_STRING: = "res://items/string.png"
const PATH_COAL: = "res://items/coal.png"
const PATH_RAW_IRON: = "res://items/raw_iron.png"
const PATH_IRON: = "res://items/iron.png"
const PATH_AOU: = "res://items/announcement of undying.png"
const PATH_LIGHTER: = "res://items/lighter.png"
const PATH_GOLDEN_CAKE: = "res://items/goldencake.png"
const PATH_RAW_GOLD: = "res://items/raw gold.png"
const PATH_GOLD: = "res://items/gold.png"
const PATH_YOYLEBERRY: = "res://food/Yoyle.png"
const PATH_GOLDENBERRY: = "res://food/GoldenYoyle.png"
const PATH_YOYLITE: = "res://items/yoylite.png"
const PATH_YOYLITE_PEARL: = "res://items/yoylite pearl.png"
const PATH_SPYGLASS: = "res://items/telescope.png"

const PATH_WOODEN_AXE: = "res://items/wooden_axe.png"
const PATH_WOODEN_PICKAXE: = "res://items/wooden_pickaxe.png"
const PATH_WOODEN_SHOVEL: = "res://items/wooden_shovel.png"
const PATH_STONE_AXE: = "res://items/stone_axe.png"
const PATH_STONE_PICKAXE: = "res://items/stone_pickaxe.png"
const PATH_STONE_SHOVEL: = "res://items/stone_shovel.png"
const PATH_IRON_AXE: = "res://items/iron_axe.png"
const PATH_IRON_PICKAXE: = "res://items/iron_pickaxe.png"
const PATH_IRON_SHOVEL: = "res://items/iron_shovel.png"
const PATH_YOYLITE_AXE: = "res://items/yoylite axe.png"
const PATH_YOYLITE_PICKAXE: = "res://items/yoylite pickaxe.png"
const PATH_YOYLITE_SHOVEL: = "res://items/yoylite shovel.png"

const PATH_WOODEN_SWORD: = "res://items/wooden_sword.png"
const PATH_STONE_SWORD: = "res://items/stone_sword.png"
const PATH_IRON_SWORD: = "res://items/iron_sword.png"
const PATH_YOYLITE_SWORD: = "res://items/yoylite sword.png"


const ITEM_SPRITES: = {
	ITEM_GRASS: null, 
	ITEM_DIRT: null, 
	ITEM_STONE: null, 
	ITEM_CAKE: PATH_CAKE, 
	ITEM_LOG: null, 
	ITEM_LEAVES: null, 
	ITEM_CRAFT: null, 
	ITEM_STICK: PATH_STICK, 
	ITEM_STRING: PATH_STRING, 
	ITEM_WOODEN_PICKAXE: PATH_WOODEN_PICKAXE, 
	ITEM_WOODEN_SWORD: PATH_WOODEN_SWORD, 
	ITEM_WOODEN_AXE: PATH_WOODEN_AXE, 
	ITEM_WOODEN_SHOVEL: PATH_WOODEN_SHOVEL, 
	ITEM_STONE_AXE: PATH_STONE_AXE, 
	ITEM_STONE_PICKAXE: PATH_STONE_PICKAXE, 
	ITEM_STONE_SHOVEL: PATH_STONE_SHOVEL, 
	ITEM_STONE_SWORD: PATH_STONE_SWORD, 
	ITEM_IRON_STONE: null, 
	ITEM_COAL_STONE: null, 
	ITEM_COAL: PATH_COAL, 
	ITEM_RAW_IRON: PATH_RAW_IRON, 
	ITEM_IRON: PATH_IRON, 
	ITEM_OVEN: null, 
	ITEM_IRON_AXE: PATH_IRON_AXE, 
	ITEM_IRON_PICKAXE: PATH_IRON_PICKAXE, 
	ITEM_IRON_SHOVEL: PATH_IRON_SHOVEL, 
	ITEM_IRON_SWORD: PATH_IRON_SWORD, 
	ITEM_AOU: PATH_AOU, 
	ITEM_LIGHTER: PATH_LIGHTER, 
	ITEM_GOLDEN_CAKE: PATH_GOLDEN_CAKE, 
	ITEM_RAW_GOLD: PATH_RAW_GOLD, 
	ITEM_GOLD: PATH_GOLD, 
	ITEM_YOYLEBERRY: PATH_YOYLEBERRY, 
	ITEM_GOLDENBERRY: PATH_GOLDENBERRY, 
	ITEM_YOYLITE: PATH_YOYLITE, 
	ITEM_YOYLITE_AXE: PATH_YOYLITE_AXE, 
	ITEM_YOYLITE_PICKAXE: PATH_YOYLITE_PICKAXE, 
	ITEM_YOYLITE_SHOVEL: PATH_YOYLITE_SHOVEL, 
	ITEM_YOYLITE_SWORD: PATH_YOYLITE_SWORD, 
	ITEM_YOYLITE_PEARL: PATH_YOYLITE_PEARL, 
	ITEM_SPYGLASS: PATH_SPYGLASS
}


const PATH_GRASS_DIG: = [
	"res://sounds/grass/Grass_dig1.ogg", 
	"res://sounds/grass/Grass_dig2.ogg", 
	"res://sounds/grass/Grass_dig3.ogg", 
	"res://sounds/grass/Grass_dig4.ogg"
]
const PATH_GRASS_MINING: = [
	"res://sounds/grass/Grass_mining1.ogg", 
	"res://sounds/grass/Grass_mining2.ogg", 
	"res://sounds/grass/Grass_mining3.ogg.mp3", 
	"res://sounds/grass/Grass_mining4.ogg", 
	"res://sounds/grass/Grass_mining5.ogg", 
	"res://sounds/grass/Grass_mining6.ogg"
]

const PATH_STONE_DIG: = [
	"res://sounds/stone/Stone_dig1.ogg", 
	"res://sounds/stone/Stone_dig2.ogg", 
	"res://sounds/stone/Stone_dig3.ogg", 
	"res://sounds/stone/Stone_dig4.ogg"
]
const PATH_STONE_MINING: = [
	"res://sounds/stone/Stone_mining1.ogg", 
	"res://sounds/stone/Stone_mining2.ogg.mp3", 
	"res://sounds/stone/Stone_mining3.ogg", 
	"res://sounds/stone/Stone_mining4.ogg.mp3", 
	"res://sounds/stone/Stone_mining5.ogg.mp3", 
	"res://sounds/stone/Stone_mining6.ogg.mp3"
]

const PATH_WOOD_DIG: = [
	"res://sounds/wood/Wood_dig1.ogg", 
	"res://sounds/wood/Wood_dig2.ogg", 
	"res://sounds/wood/Wood_dig3.ogg", 
	"res://sounds/wood/Wood_dig4.ogg"
]
const PATH_WOOD_MINING: = [
	"res://sounds/wood/Wood_mining1.ogg", 
	"res://sounds/wood/Wood_mining2.ogg", 
	"res://sounds/wood/Wood_mining3.ogg", 
	"res://sounds/wood/Wood_mining4.ogg", 
	"res://sounds/wood/Wood_mining5.ogg", 
	"res://sounds/wood/Wood_mining6.ogg"
]

const PATH_SNOW_DIG: = [
	"res://sounds/snow/Snow_dig1.ogg", 
	"res://sounds/snow/Snow_dig2.ogg", 
	"res://sounds/snow/Snow_dig3.ogg", 
	"res://sounds/snow/Snow_dig4.ogg"
]

const PATH_SAND_MINING: = [
	"res://sounds/sand/Sand_mining1.ogg.mp3", 
	"res://sounds/sand/Sand_mining2.ogg.mp3", 
	"res://sounds/sand/Sand_mining3.ogg.mp3", 
	"res://sounds/sand/Sand_mining4.ogg.mp3", 
	"res://sounds/sand/Sand_mining5.ogg.mp3"
]

const PATH_SAND_DIG: = [
	"res://sounds/sand/Sand_dig1.ogg.mp3", 
	"res://sounds/sand/Sand_dig2.ogg.mp3", 
	"res://sounds/sand/Sand_dig3.ogg.mp3", 
	"res://sounds/sand/Sand_dig4.ogg.mp3"
]

const PATH_GRAVEL_MINING: = [
	"res://sounds/gravel/Gravel_mining1.ogg.mp3", 
	"res://sounds/gravel/Gravel_mining2.ogg", 
	"res://sounds/gravel/Gravel_mining3.ogg.mp3", 
	"res://sounds/gravel/Gravel_mining4.ogg.mp3"
]

const PATH_GRAVEL_DIG: = [
	"res://sounds/gravel/Gravel_dig1.ogg.mp3", 
	"res://sounds/gravel/Gravel_dig2.ogg", 
	"res://sounds/gravel/Gravel_dig3.ogg", 
	"res://sounds/gravel/Gravel_dig4.ogg"
]



const MINE_GRASS: = PATH_GRASS_MINING
const MINE_STONE: = PATH_STONE_MINING
const MINE_WOOD: = PATH_WOOD_MINING
const MINE_SNOW: = PATH_SNOW_DIG
const MINE_SAND: = PATH_SAND_MINING
const MINE_GRAVEL: = PATH_GRAVEL_MINING

const DIG_GRASS: = PATH_GRASS_DIG
const DIG_STONE: = PATH_STONE_DIG
const DIG_WOOD: = PATH_WOOD_DIG
const DIG_SNOW: = PATH_SNOW_DIG
const DIG_SAND: = PATH_SAND_DIG
const DIG_GRAVEL: = PATH_GRAVEL_DIG

@onready var death_ui = $CanvasLayer / Death
var _ui_modal_open: = false

func show_death_screen() -> void :
	_ui_lock(true)
	if death_ui:
		death_ui.show_death()

func hide_death_screen() -> void :
	if death_ui:
		death_ui.hide_death()
	_ui_lock(false)

func _ui_lock(on: bool) -> void :
	_ui_modal_open = on
	_set_local_input_locked(on)

	if on:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


var _asset_cache: Dictionary = {}
var _atlas_cache: Dictionary = {}
const ASSET_CACHE_MAX: = 16
const ATLAS_CACHE_MAX: = 64
var _atlas_cache_order: Array = []

func _get_res(path: String) -> Resource:
	if path == "" or path == null:
		return null
	if _asset_cache.has(path):
		return _asset_cache[path]
	var r: = load(path)
	if r != null:
		_asset_cache[path] = r
		if _asset_cache.size() > ASSET_CACHE_MAX:

			var k = _asset_cache.keys()[0]
			_asset_cache.erase(k)
	return r

func _get_audio_list(paths: Array) -> Array:
	var out: Array = []
	for p in paths:
		var s: = _get_res(String(p))
		if s != null: out.append(s)
	return out

func _get_tex_from_path(path: String) -> Texture2D:
	return _get_res(path) as Texture2D


func unload_unused_assets() -> void :
	_asset_cache.clear()
	_atlas_cache.clear()

const NO_PREV: = -1000000000


const DYN_FUSE_SEC: = 2.6
const DYN_RADIUS_CELLS: = 3
var radius_px: = float(74 * DYN_RADIUS_CELLS)
const CRYSTAL_DAMAGE_RADIUS_PX: = 370.0
const CRYSTAL_BREAK_RADIUS_CELLS: = 3
const DYN_CHAIN_MIN: = 0.25
const DYN_CHAIN_MAX: = 0.75


var _boom_bucket: Array[Vector2] = []
const BOOM_BUCKET_SEC: = 0.08


func _queue_boom(pos: Vector2) -> void :
	_boom_bucket.append(pos)

	if _boom_bucket.size() == 1:
		await get_tree().create_timer(BOOM_BUCKET_SEC).timeout
		_flush_boom_bucket()

const EXPLOSION_BASE_GAIN_DB: = 8.0
const EXPLOSION_MIX_PER_DOUBLING_DB: = -2.0

func _flush_boom_bucket() -> void :
	var n: = _boom_bucket.size()
	if n <= 0: return
	var center: = Vector2.ZERO
	for p in _boom_bucket: center += p
	center /= float(n)
	_boom_bucket.clear()

	var vol_db: = EXPLOSION_BASE_GAIN_DB
	if n > 1:

		vol_db += clamp(EXPLOSION_MIX_PER_DOUBLING_DB * (log(float(n)) / log(2.0)), -8.0, 0.0)

	var streams: = [EXPLOSION_1, EXPLOSION_2, EXPLOSION_3, EXPLOSION_4]
	_play_sfx_at(streams[randi() % streams.size()], center, vol_db)


var _lit_dynamite: = {}
var _protected_cells: = {}

func _is_dynamite_cell(cell: Vector2i) -> bool:
	if ground.get_cell_source_id(cell) != SRC:
		return false
	return ground.get_cell_atlas_coords(cell) == T_DYNAMITE

func _play_sfx_at(stream: AudioStream, pos: Vector2, vol_db: float = 0.0) -> void :
	if stream == null: return
	var a: = AudioStreamPlayer2D.new()
	a.stream = stream
	a.volume_db = vol_db
	a.bus = "SFX"
	a.global_position = pos
	add_child(a)
	a.finished.connect(a.queue_free)
	a.play()

const N4: = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

func _ac(cell: Vector2i) -> Vector2i:
	if ground.get_cell_source_id(cell) != SRC:
		return Vector2i(-999, -999)
	return ground.get_cell_atlas_coords(cell)

func _is_wire(cell: Vector2i) -> bool:
	var a: = _ac(cell)
	return a == T_YOYLITE_WIRE_OFF or a == T_YOYLITE_WIRE_ON

func _is_wire_powered(cell: Vector2i) -> bool:
	return _ac(cell) == T_YOYLITE_WIRE_ON

func _is_emitter(cell: Vector2i) -> bool:
	var a: = _ac(cell)
	return a == T_YOYLITE_EMITTER_ON or a == T_YOYLITE_EMITTER_OFF

func _is_emitter_powered(cell: Vector2i) -> bool:
	return _ac(cell) == T_YOYLITE_EMITTER_ON


func _is_delayer(cell: Vector2i) -> bool:
	var a: = _ac(cell)
	return T_YOYLITE_DELAYER_TICK.has(a)

func _delayer_ticks_from_ac(a: Vector2i) -> int:

	if a == T_YOYLITE_DELAYER_1_OFF or a == T_YOYLITE_DELAYER_1_ON: return 1
	if a == T_YOYLITE_DELAYER_2_OFF or a == T_YOYLITE_DELAYER_2_ON: return 2
	if a == T_YOYLITE_DELAYER_3_OFF or a == T_YOYLITE_DELAYER_3_ON: return 3
	if a == T_YOYLITE_DELAYER_4_OFF or a == T_YOYLITE_DELAYER_4_ON: return 4
	return 1

func _delayer_is_on(cell: Vector2i) -> bool:
	var a: = _ac(cell)
	return a == T_YOYLITE_DELAYER_1_ON or a == T_YOYLITE_DELAYER_2_ON or a == T_YOYLITE_DELAYER_3_ON or a == T_YOYLITE_DELAYER_4_ON

func _delayer_set_on_off(cell: Vector2i, on: bool) -> void :
	var a: = _ac(cell)
	var t: = _delayer_ticks_from_ac(a)
	var new_ac: = Vector2i.ZERO
	match t:
		1: new_ac = (T_YOYLITE_DELAYER_1_ON if on else T_YOYLITE_DELAYER_1_OFF)
		2: new_ac = (T_YOYLITE_DELAYER_2_ON if on else T_YOYLITE_DELAYER_2_OFF)
		3: new_ac = (T_YOYLITE_DELAYER_3_ON if on else T_YOYLITE_DELAYER_3_OFF)
		4: new_ac = (T_YOYLITE_DELAYER_4_ON if on else T_YOYLITE_DELAYER_4_OFF)
	_yoylite_set_state(cell, new_ac)

func _is_yoylite_powered(cell: Vector2i) -> bool:
	return _is_wire_powered(cell)\
	or _delayer_is_on(cell)\
	or _is_emitter_powered(cell)\
	or _is_lever_powered(cell)

func _yoylite_set_state(cell: Vector2i, atlas: Vector2i) -> void :

	set_cell_override(cell, atlas, 0)

	rpc("cli_set_cell", cell, SRC, atlas)


	_mark_yoylite_dirty(cell)

func _is_conductor(cell: Vector2i) -> bool:
	return _is_wire(cell) or _is_delayer(cell)

func _conductor_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in N4:
		var n = cell + d
		if _is_conductor(n):
			out.append(n)
	return out


var _delayer_pending: = {}

func _schedule_delayer(cell: Vector2i, target_on: bool) -> void :
	var ticks: = _delayer_ticks_from_ac(_ac(cell))
	var existing = _delayer_pending.get(cell, null)
	if existing != null:

		if bool(existing["target_on"]) == target_on:
			existing["remain"] = mini(int(existing["remain"]), ticks)
			_delayer_pending[cell] = existing
			return

	_delayer_pending[cell] = {"target_on": target_on, "remain": ticks}
	_mark_yoylite_dirty(cell)

func _tick_delayer_timers() -> void :
	var to_apply: Array[Vector2i] = []
	for c in _delayer_pending.keys():
		var d: Dictionary = _delayer_pending[c]
		d["remain"] = int(d["remain"]) - 1
		_delayer_pending[c] = d
		if int(d["remain"]) <= 0:
			to_apply.append(c)

	for c in to_apply:
		var d: Dictionary = _delayer_pending[c]
		_delayer_pending.erase(c)

		var target_on: = bool(d["target_on"])
		if _delayer_is_on(c) != target_on:
			_delayer_set_on_off(c, target_on)
			_mark_yoylite_dirty(c)
		if not target_on:
			_delayer_inputs.erase(c)


func _is_source_powered_cell(cell: Vector2i, emitter_on: Dictionary, region_emitters: Dictionary, region_levers: Dictionary) -> bool:
	if region_emitters.has(cell) and bool(emitter_on.get(cell, false)):
		return true
	if region_levers.has(cell) and _is_lever_powered(cell):
		return true
	return false

var _yoylite_live_power: = {}
var _yoylite_live_sources: = {}

func _delayer_wants_on_now(cell: Vector2i) -> bool:

	for d in N4:
		var n = cell + d
		if _yoylite_live_power.has(n) or _yoylite_live_sources.has(n):
			return true
	return false

func _can_conduct_now(cell: Vector2i) -> bool:
	if _is_wire(cell): return true
	if _is_delayer(cell): return _delayer_is_on(cell)
	return false

func _emitter_next_on(cell: Vector2i) -> bool:



	for d in N4:
		if _is_lever_powered(cell + d):
			return false
		var barrier = cell + d
		if ground.get_cell_source_id(barrier) != SRC:
			continue


		if _is_conductor(barrier):
			continue


		for d2 in N4:
			var around = barrier + d2
			if _is_wire_powered(around) or _is_lever_powered(around) or _delayer_is_on(around):
				return false
	return true

@rpc("any_peer", "reliable")
func srv_request_delayer_click(cell: Vector2i) -> void :
	if not multiplayer.is_server(): return

	var actor: = multiplayer.get_remote_sender_id()
	if actor == 0: actor = SERVER_ID
	if not _server_can_reach_cell(actor, cell, BREAK_REACH_CELLS): return
	if not _is_delayer(cell): return

	var a: = _ac(cell)
	var on: = (a == T_YOYLITE_DELAYER_1_ON or a == T_YOYLITE_DELAYER_2_ON or a == T_YOYLITE_DELAYER_3_ON or a == T_YOYLITE_DELAYER_4_ON)
	var t: = _delayer_ticks_from_ac(a)
	var nt: = (t % 4) + 1

	var new_ac: = Vector2i.ZERO
	match nt:
		1: new_ac = (T_YOYLITE_DELAYER_1_ON if on else T_YOYLITE_DELAYER_1_OFF)
		2: new_ac = (T_YOYLITE_DELAYER_2_ON if on else T_YOYLITE_DELAYER_2_OFF)
		3: new_ac = (T_YOYLITE_DELAYER_3_ON if on else T_YOYLITE_DELAYER_3_OFF)
		4: new_ac = (T_YOYLITE_DELAYER_4_ON if on else T_YOYLITE_DELAYER_4_OFF)

	set_cell_override(cell, new_ac, 0)
	rpc("cli_set_cell", cell, SRC, new_ac)
	_mark_yoylite_dirty(cell)


	_delayer_pending.erase(cell)


var _delayer_inputs: = {}

func _delayer_update_inputs(cell: Vector2i, region_cond: Dictionary, emitter_on: Dictionary, region_emitters: Dictionary, region_levers: Dictionary) -> void :

	var reachable: = {}
	var q: Array[Vector2i] = []



	for e in region_emitters.keys():
		if bool(emitter_on.get(e, false)):
			for d in N4:
				var c = e + d
				if c == cell: continue
				if region_cond.has(c) and _can_conduct_now(c) and not reachable.has(c):
					reachable[c] = true
					q.append(c)

	for l in region_levers.keys():
		if _is_lever_powered(l):
			for d in N4:
				var c = l + d
				if c == cell: continue
				if region_cond.has(c) and _can_conduct_now(c) and not reachable.has(c):
					reachable[c] = true
					q.append(c)

	while q.size() > 0:
		var c = q.pop_back()
		for n in _conductor_neighbors(c):
			if n == cell: continue
			if not region_cond.has(n): continue
			if reachable.has(n): continue
			if not _can_conduct_now(n): continue
			reachable[n] = true
			q.append(n)


	var ins: = {}
	for d in N4:
		var n = cell + d
		if region_cond.has(n) and reachable.has(n):
			ins[n] = true

	_delayer_inputs[cell] = ins

func _delayer_is_input_neighbor(delayer_cell: Vector2i, neighbor: Vector2i) -> bool:
	var ins = _delayer_inputs.get(delayer_cell, null)
	return ins != null and (ins as Dictionary).has(neighbor)

func _server_tick_yoylite(cells_to_check: Array[Vector2i]) -> void :



	var region_wires: Dictionary = {}
	var region_emitters: Dictionary = {}
	var region_levers: Dictionary = {}
	var region_delayers: Dictionary = {}


	var seen: Dictionary = {}
	for seed in cells_to_check:
		if not _is_conductor(seed):
			continue
		if seen.has(seed):
			continue


		var q: Array[Vector2i] = [seed]
		seen[seed] = true
		while q.size() > 0:
			var c = q.pop_back()
			if _is_wire(c):
				region_wires[c] = true
			elif _is_delayer(c):
				region_delayers[c] = true


			for d in N4:
				var e = c + d
				if _is_emitter(e):
					region_emitters[e] = true
				if _is_lever(e):
					region_levers[e] = true

			for n in _conductor_neighbors(c):
				if not seen.has(n):
					seen[n] = true
					q.append(n)


	for seed in cells_to_check:
		if not _is_emitter(seed):
			continue
		region_emitters[seed] = true
		if _is_lever(seed):
			region_levers[seed] = true
		for d in N4:
			var w = seed + d
			if _is_conductor(w) and not seen.has(w):
				var q: Array[Vector2i] = [w]
				seen[w] = true
				while q.size() > 0:
					var c = q.pop_back()
					if _is_wire(c):
						region_wires[c] = true
					elif _is_delayer(c):
						region_delayers[c] = true
					for d2 in N4:
						var e2 = c + d2
						if _is_emitter(e2):
							region_emitters[e2] = true
					for n in _conductor_neighbors(c):
						if not seen.has(n):
							seen[n] = true
							q.append(n)


	var emitter_on: Dictionary = {}
	for e in region_emitters.keys():
		var want_on: = _emitter_next_on(e)
		emitter_on[e] = want_on



	var powered_from_sources: Dictionary = {}
	var q2: Array[Vector2i] = []

	var region_cond: Dictionary = {}
	for w in region_wires.keys():
		region_cond[w] = true
	for d in region_delayers.keys():
		region_cond[d] = true


	for e in region_emitters.keys():
		if emitter_on[e]:
			for d in N4:
				var c = e + d
				if region_cond.has(c) and _can_conduct_now(c) and not powered_from_sources.has(c):
					powered_from_sources[c] = true
					q2.append(c)


	for l in region_levers.keys():
		if _is_lever_powered(l):
			for d in N4:
				var c = l + d
				if region_cond.has(c) and _can_conduct_now(c) and not powered_from_sources.has(c):
					powered_from_sources[c] = true
					q2.append(c)

	while q2.size() > 0:
		var c = q2.pop_back()
		for n in _conductor_neighbors(c):
			if not region_cond.has(n): continue
			if powered_from_sources.has(n): continue
			if not _can_conduct_now(n): continue
			powered_from_sources[n] = true
			q2.append(n)


	var powered_held: Dictionary = {}
	var qh: Array[Vector2i] = []

	for dcell in region_delayers.keys():
		if not _delayer_is_on(dcell):
			continue


		for d in N4:
			var n = dcell + d
			if not region_cond.has(n): continue
			if not _can_conduct_now(n): continue


			if _delayer_is_input_neighbor(dcell, n):
				continue

			if not powered_held.has(n):
				powered_held[n] = true
				qh.append(n)


	while qh.size() > 0:
		var c = qh.pop_back()
		for n in _conductor_neighbors(c):
			if not region_cond.has(n): continue
			if powered_held.has(n): continue
			if not _can_conduct_now(n): continue


			if _is_delayer(c) and _delayer_is_input_neighbor(c, n):
				continue

			powered_held[n] = true
			qh.append(n)


	_yoylite_live_power.clear()
	_yoylite_live_sources.clear()



	for c in powered_from_sources.keys():
		if _is_wire(c):
			_yoylite_live_power[c] = true
		elif _is_delayer(c) and _delayer_is_on(c):
			_yoylite_live_power[c] = true


	for e in region_emitters.keys():
		if bool(emitter_on.get(e, false)):
			_yoylite_live_sources[e] = true
	for l in region_levers.keys():
		if _is_lever_powered(l):
			_yoylite_live_sources[l] = true

	for dcell in region_delayers.keys():
		var want_on: = _delayer_wants_on_now(dcell)
		if want_on:
			_delayer_update_inputs(dcell, region_cond, emitter_on, region_emitters, region_levers)


		var is_on: = _delayer_is_on(dcell)
		if want_on != is_on:
			_schedule_delayer(dcell, want_on)


	for e in region_emitters.keys():
		var new_e: = (T_YOYLITE_EMITTER_ON if emitter_on[e] else T_YOYLITE_EMITTER_OFF)
		if _ac(e) != new_e:
			_yoylite_set_state(e, new_e)

	for w in region_wires.keys():
		var on_now: = powered_from_sources.has(w) or powered_held.has(w)
		var new_w: = (T_YOYLITE_WIRE_ON if on_now else T_YOYLITE_WIRE_OFF)
		if _ac(w) != new_w:
			_yoylite_set_state(w, new_w)

var _yoylite_accum: = 0.0
const YOYLITE_TICK: = 0.1

var _yoylite_dirty: = {}

func _mark_yoylite_dirty(cell: Vector2i) -> void :
	_yoylite_dirty[cell] = true
	for o in N4:
		var n = cell + o
		_yoylite_dirty[n] = true
		for o2 in N4:
			_yoylite_dirty[n + o2] = true

func _seed_yoylite_dirty_for_chunk(cc: Vector2i) -> void :
	var x0: = cc.x * CHUNK_SIZE
	var x1: = x0 + CHUNK_SIZE - 1


	for c in cell_overrides.keys():
		if c.x >= x0 and c.x <= x1:
			_mark_yoylite_dirty(c)

	for c in removed_cells.keys():
		if c.x >= x0 and c.x <= x1:
			_mark_yoylite_dirty(c)

const DIR_FROM_INDEX: = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]

func _piston_face_index(ac: Vector2i) -> int:
	var i: = T_PISTON_FACES.find(ac)
	if i != -1: return i
	i = T_STRINGY_PISTON_FACES.find(ac)
	return i

func _piston_facing_dir(ac: Vector2i) -> Vector2i:
	return _piston_dir_from_ac(ac)

func _is_piston_cell(cell: Vector2i) -> bool:
	var ac: = _ac(cell)
	return T_PISTON_FACES.has(ac) or T_STRINGY_PISTON_FACES.has(ac)

func _is_stringy_piston(cell: Vector2i) -> bool:
	return T_STRINGY_PISTON_FACES.has(_ac(cell))

func _piston_is_powered(cell: Vector2i, facing: Vector2i) -> bool:
	for d in N4:
		if d == facing:
			continue
		var n = cell + d
		if _is_yoylite_powered(n):
			return true
	return false

func _extender_ac_for_dir(dir: Vector2i) -> Vector2i:
	if dir == Vector2i(1, 0): return T_PISTON_EXTENDER_RIGHT
	if dir == Vector2i(-1, 0): return T_PISTON_EXTENDER_LEFT
	if dir == Vector2i(0, -1): return T_PISTON_EXTENDER_UP
	return T_PISTON_EXTENDER_DOWN


func _extender_dir_from_ac(ac: Vector2i) -> Vector2i:
	if ac == T_PISTON_EXTENDER_RIGHT: return Vector2i(1, 0)
	if ac == T_PISTON_EXTENDER_LEFT: return Vector2i(-1, 0)
	if ac == T_PISTON_EXTENDER_UP: return Vector2i(0, -1)
	if ac == T_PISTON_EXTENDER_DOWN: return Vector2i(0, 1)
	return Vector2i.ZERO

func _piston_dir_from_ac(ac: Vector2i) -> Vector2i:
	if ac == T_PISTON_RIGHT or ac == T_STRINGY_PISTON_RIGHT: return Vector2i(1, 0)
	if ac == T_PISTON_LEFT or ac == T_STRINGY_PISTON_LEFT: return Vector2i(-1, 0)
	if ac == T_PISTON_UP or ac == T_STRINGY_PISTON_UP: return Vector2i(0, -1)
	if ac == T_PISTON_DOWN or ac == T_STRINGY_PISTON_DOWN: return Vector2i(0, 1)
	return Vector2i.ZERO

func _server_erase_cell_nodrop(cell: Vector2i) -> void :

	mark_cell_removed(cell)
	rpc("cli_erase_cell", cell)

func _erase_cell_persist(cell: Vector2i) -> void :
	mark_cell_removed(cell)
	rpc("cli_erase_cell", cell)
	_mark_yoylite_dirty(cell)

func _validate_extender_or_erase(ext_cell: Vector2i) -> void :
	if ground.get_cell_source_id(ext_cell) != SRC:
		return
	var ac: = _ac(ext_cell)
	if not T_PISTON_EXTENDER_FACES.has(ac):
		return


	var dir: = _extender_dir_from_ac(ac)
	if dir == Vector2i.ZERO:
		_erase_cell_persist(ext_cell)
		return

	var piston_cell: = ext_cell - dir


	if not _is_piston_cell(piston_cell):
		_erase_cell_persist(ext_cell)
		return


	if _piston_facing_dir(_ac(piston_cell)) != dir:
		_erase_cell_persist(ext_cell)
		return

func _is_extender(cell: Vector2i) -> bool:
	return T_PISTON_EXTENDER_FACES.has(_ac(cell))

const PISTON_MAX_PUSH: = 12

func _cell_is_empty(c: Vector2i) -> bool:
	return ground.get_cell_source_id(c) == -1

func _is_movable_override_cell(c: Vector2i) -> bool:

	return ground.get_cell_source_id(c) == SRC

func _move_bundle(cells: Array[Vector2i], delta: Vector2i) -> bool:
	var set: = {}
	for c in cells:
		set[c] = true


	var atlas_by_cell: = {}
	for c in cells:
		if not _is_movable_override_cell(c):
			return false
		var dst: = c + delta
		if not set.has(dst) and ground.get_cell_source_id(dst) != -1:
			return false
		atlas_by_cell[c] = ground.get_cell_atlas_coords(c)





	for c in cells:
		mark_cell_removed(c)
		rpc("cli_erase_cell", c)


	for c in cells:
		var ac: Vector2i = atlas_by_cell[c]
		set_cell_override(c + delta, ac, 0)
		rpc("cli_set_cell", c + delta, SRC, ac)

		_mark_yoylite_dirty(c)
		_mark_yoylite_dirty(c + delta)

	return true

func _maybe_include_matching_extender(cell: Vector2i, to_move: Dictionary) -> void :
	var ac: = _ac(cell)


	if not (ac in T_PISTON_FACES or ac in T_STRINGY_PISTON_FACES):
		return

	var facing: = _piston_facing_dir(ac)
	if facing == Vector2i.ZERO:
		return

	var head: = cell + facing
	if ground.get_cell_source_id(head) == SRC and _ac(head) == _extender_ac_for_dir(facing):
		to_move[head] = true

func _move_cell(from_c: Vector2i, to_c: Vector2i, _depth: = 0) -> bool:
	if _depth > 32:
		return false

	if not _is_movable_override_cell(from_c):
		return false
	if ground.get_cell_source_id(to_c) != -1:
		return false

	var delta: = to_c - from_c
	var from_ac: = ground.get_cell_atlas_coords(from_c)


	if from_ac in T_STRINGY_PISTON_FACES:
		var component: = _stringy_component_cells(from_c)


		var move_set: Dictionary = {}
		for c in component:
			move_set[c] = true


		var exclude: Dictionary = {}
		exclude[from_c] = true

		var facing0: = _piston_facing_dir(from_ac)
		if facing0 != Vector2i.ZERO:
			exclude[from_c + facing0] = true


		for c in component:
			if _is_string_block(c):
				var dragged: Dictionary = _string_build_move_set(c, delta, exclude)
				for k in dragged.keys():
					move_set[k] = true


		var arr: Array[Vector2i] = []
		for k in move_set.keys():
			arr.append(k)

		if not _move_bundle(arr, delta):
			return false


		_piston_last_power.erase(from_c)
		_piston_last_power.erase(to_c)
		return true



	if from_ac in T_PISTON_FACES:
		var facing: = _piston_facing_dir(from_ac)
		var head: = from_c + facing

		var has_ext: = (
			ground.get_cell_source_id(head) == SRC
			and ground.get_cell_atlas_coords(head) == _extender_ac_for_dir(facing)
		)

		if has_ext:

			if not _move_bundle([from_c, head], delta):
				return false

			_piston_last_power.erase(from_c)
			_piston_last_power.erase(to_c)
			_piston_last_power.erase(head)
			_piston_last_power.erase(head + delta)
			return true




	mark_cell_removed(from_c)
	rpc("cli_erase_cell", from_c)

	set_cell_override(to_c, from_ac, 0)
	rpc("cli_set_cell", to_c, SRC, from_ac)

	_mark_yoylite_dirty(from_c)
	_mark_yoylite_dirty(to_c)

	return true



func _piston_try_extend_and_push(piston_cell: Vector2i, facing: Vector2i) -> void :
	var pushed_already: Dictionary = {}
	var head: = piston_cell + facing


	if _is_extender(head):
		return



	var line: Array[Vector2i] = []
	var cur: = head



	for i in range(PISTON_MAX_PUSH + 1):
		if _cell_is_empty(cur):
			break
		line.append(cur)
		cur += facing


	if not _cell_is_empty(cur):
		return

	if line.size() > PISTON_MAX_PUSH:
		return


	for i in range(line.size() - 1, -1, -1):
		var c: = line[i]


		if pushed_already.has(c):
			continue


		if ground.get_cell_source_id(c) == -1:
			continue


		if not _is_movable_override_cell(c):
			return

		if _is_string_block(c):

			var exclude: Dictionary = {}
			exclude[piston_cell] = true

			var move_set: = _string_build_move_set(c, facing, exclude)


			if move_set.size() == 0:
				return


			for k in move_set.keys():
				pushed_already[k] = true


			var arr: Array[Vector2i] = []
			for k in move_set.keys():
				arr.append(k)

			if not _move_bundle(arr, facing):

				return

			continue


		if not _move_cell(c, c + facing):
			return



	if _ac(piston_cell) in T_STRINGY_PISTON_FACES:
		_stringy_has_capture.erase(piston_cell)


	if ground.get_cell_source_id(piston_cell) != SRC:
		return
	var piston_ac_now: = ground.get_cell_atlas_coords(piston_cell)
	if not (piston_ac_now in T_PISTON_FACES or piston_ac_now in T_STRINGY_PISTON_FACES):
		return


	facing = _piston_facing_dir(piston_ac_now)
	head = piston_cell + facing


	if ground.get_cell_source_id(head) != -1:
		return


	_play_piston_sfx(PISTON_EXTEND, piston_cell)
	_yoylite_set_state(head, _extender_ac_for_dir(facing))

var _stringy_has_capture: = {}

func _stringy_has_matching_extender(p: Vector2i, facing: Vector2i) -> bool:
	var head: = p + facing
	return _is_extender(head) and _ac(head) == _extender_ac_for_dir(facing)

func _stringy_ignore_attachment(p: Vector2i, a: Vector2i) -> bool:




	if not _is_piston_cell(a):
		return false

	var f: = _piston_facing_dir(_ac(a))
	if f == Vector2i.ZERO:
		return false


	if a + f != p:
		return false


	if _piston_is_powered(a, f):
		return true

	return false

func _stringy_attachment_cell(p: Vector2i) -> Vector2i:
	var facing: = _piston_facing_dir(_ac(p))
	var head: = p + facing
	return (head + facing) if _stringy_has_matching_extender(p, facing) else head

func _stringy_pistons_sticking_to_block(x: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	for dir in N4:

		var p1 = x - dir
		if _ac(p1) in T_STRINGY_PISTON_FACES:
			var facing1: = _piston_facing_dir(_ac(p1))
			if facing1 == dir and not _stringy_has_matching_extender(p1, facing1):
				out.append(p1)


		var p2 = x - (dir * 2)
		if _ac(p2) in T_STRINGY_PISTON_FACES:
			var facing2: = _piston_facing_dir(_ac(p2))
			if facing2 == dir and _stringy_has_matching_extender(p2, facing2):
				out.append(p2)

	return out

func _regular_piston_step_forward_if_stringy_in_front(piston_cell: Vector2i, facing: Vector2i) -> bool:

	var head: = piston_cell + facing
	if not _is_extender(head):
		return false
	if _ac(head) != _extender_ac_for_dir(facing):
		return false


	var front: = head + facing
	if not _is_stringy_piston(front):
		return false
	if _piston_facing_dir(_ac(front)) != - facing:
		return false



	var from_ac: = _ac(piston_cell)


	mark_cell_removed(piston_cell)
	rpc("cli_erase_cell", piston_cell)


	set_cell_override(head, from_ac, 0)
	rpc("cli_set_cell", head, SRC, from_ac)

	_mark_yoylite_dirty(piston_cell)
	_mark_yoylite_dirty(head)


	_play_piston_sfx(PISTON_CONTRACT, piston_cell)


	_piston_last_power.erase(piston_cell)
	_piston_last_power.erase(head)

	return true

func _stringy_component_cells(start_piston: Vector2i) -> Array[Vector2i]:
	var to_move: Dictionary = {}
	var q: Array[Vector2i] = []
	var seen_pistons: Dictionary = {}

	q.append(start_piston)
	seen_pistons[start_piston] = true

	while q.size() > 0:
		var p = q.pop_back()
		to_move[p] = true
		_maybe_include_matching_extender(p, to_move)

		var facing: = _piston_facing_dir(_ac(p))
		var head = p + facing


		if _stringy_has_matching_extender(p, facing):
			to_move[head] = true


		var a: = _stringy_attachment_cell(p)
		if ground.get_cell_source_id(a) != -1 and not _is_extender(a):

			if _stringy_ignore_attachment(p, a):
				pass
			else:
				to_move[a] = true
				_maybe_include_matching_extender(a, to_move)

				if _ac(a) in T_STRINGY_PISTON_FACES and not seen_pistons.has(a):
					seen_pistons[a] = true
					q.append(a)


				for p2 in _stringy_pistons_sticking_to_block(a):
					if not seen_pistons.has(p2):
						seen_pistons[p2] = true
						q.append(p2)


	for p3 in _stringy_pistons_sticking_to_block(start_piston):
		if not seen_pistons.has(p3):
			seen_pistons[p3] = true
			q.append(p3)


	var out: Array[Vector2i] = []
	for c in to_move.keys():
		out.append(c)
	return out

func _string_include_stringy_payload(p: Vector2i, group: Dictionary, q: Array[Vector2i], pusher_exclude: Dictionary) -> void :

	if not _is_stringy_piston(p):
		return


	var acp: = _ac(p)
	var f: = _piston_facing_dir(acp)
	if f != Vector2i.ZERO and _piston_is_powered(p, f):
		return


	_maybe_include_matching_extender(p, group)


	var a: = _stringy_attachment_cell(p)
	if pusher_exclude.has(a):
		return
	if _is_extender(a):
		return
	if ground.get_cell_source_id(a) != SRC:
		return

	if not group.has(a):
		group[a] = true
		q.append(a)
		_maybe_include_matching_extender(a, group)

func _string_group_add(cell: Vector2i, group: Dictionary, q: Array[Vector2i], pusher_exclude: Dictionary) -> void :
	if group.has(cell):
		return
	if pusher_exclude.has(cell):
		return
	if ground.get_cell_source_id(cell) != SRC:
		return
	if _is_extender(cell):
		return

	group[cell] = true
	q.append(cell)


	_maybe_include_matching_extender(cell, group)


	if _is_stringy_piston(cell):
		var comp: Array[Vector2i] = _stringy_component_cells(cell)
		for c in comp:
			if pusher_exclude.has(c):
				continue
			if ground.get_cell_source_id(c) != SRC:
				continue
			if _is_extender(c):
				continue

			if not group.has(c):
				group[c] = true

				if _is_string_block(c):
					q.append(c)

			_maybe_include_matching_extender(c, group)

func _string_group_cells(anchor: Vector2i, pusher_exclude: Dictionary) -> Dictionary:
	var group: Dictionary = {}
	var q: Array[Vector2i] = []

	if not _is_string_block(anchor):
		return group

	_string_group_add(anchor, group, q, pusher_exclude)

	while q.size() > 0:
		var c: Vector2i = q.pop_back()




		var c_is_string: = _is_string_block(c)
		if not c_is_string:

			for d in N4:
				var n = c + d
				if _is_string_block(n):
					_string_group_add(n, group, q, pusher_exclude)
			continue


		for d in N4:
			var n = c + d
			if group.has(n):
				continue
			if pusher_exclude.has(n):
				continue
			if ground.get_cell_source_id(n) != SRC:
				continue
			if _is_extender(n):
				continue


			if _is_string_block(n) or _string_can_drag(n, pusher_exclude):
				_string_group_add(n, group, q, pusher_exclude)

	return group



func _string_build_move_set(anchor: Vector2i, delta: Vector2i, pusher_exclude: Dictionary) -> Dictionary:

	var move_set: = _string_group_cells(anchor, pusher_exclude)


	var changed: = true
	while changed:
		changed = false
		var to_remove: Array[Vector2i] = []

		for c in move_set.keys():
			if _is_string_block(c):
				continue

			var dst = c + delta
			if move_set.has(dst):
				continue
			if ground.get_cell_source_id(dst) == -1:
				continue

			to_remove.append(c)

		if to_remove.size() > 0:
			for c in to_remove:
				move_set.erase(c)
			changed = true


	var reachable: Dictionary = {}
	var q: Array[Vector2i] = []

	if move_set.has(anchor):
		reachable[anchor] = true
		q.append(anchor)

	while q.size() > 0:
		var c: Vector2i = q.pop_back()

		for d in N4:
			var n = c + d
			if not move_set.has(n):
				continue
			if reachable.has(n):
				continue


			reachable[n] = true
			q.append(n)


	for c in move_set.keys():
		if _is_string_block(c) and not reachable.has(c):
			return {}


	for p in reachable.keys():
		if _is_stringy_piston(p):
			var a: = _stringy_attachment_cell(p)
			if ground.get_cell_source_id(a) == SRC and not _is_extender(a):
				if not reachable.has(a):
					return {}

	return reachable

func _stringy_try_retract(piston_cell: Vector2i, facing: Vector2i) -> void :
	var head: = piston_cell + facing
	if not _is_extender(head):
		return

	var pull_from: = head + facing


	_piston_remove_extender(piston_cell, facing)


	if ground.get_cell_source_id(pull_from) == -1:
		_stringy_has_capture.erase(piston_cell)
		return


	if _is_string_block(pull_from):
		var delta: = - facing


		var exclude: Dictionary = {}
		exclude[piston_cell] = true


		var move_set: Dictionary = _string_build_move_set(pull_from, delta, exclude)


		if move_set.size() == 0:
			return



		var arr: Array[Vector2i] = []
		for k in move_set.keys():
			arr.append(k)

		if not _move_bundle(arr, delta):
			return
	else:

		if not _move_cell(pull_from, head):
			return


	_stringy_has_capture[piston_cell] = true


func _is_string_block(cell: Vector2i) -> bool:
	return _ac(cell) == T_STRING_BLOCK

func _string_can_drag(cell: Vector2i, pusher_exclude: Dictionary) -> bool:
	if pusher_exclude.has(cell):
		return false
	if _is_extender(cell):
		return false



	return _is_movable_override_cell(cell)

var _piston_last_power: = {}

var _piston_busy: Dictionary = {}

func _mark_piston_busy(p: Vector2i, facing: Vector2i) -> void :
	_piston_busy[p] = true
	_piston_busy[p + facing] = true

func _server_tick_pistons(cells_to_check: Array[Vector2i]) -> void :
	_piston_busy.clear()
	var validate_cells: Dictionary = {}
	for c in cells_to_check:
		if not _is_piston_cell(c):
			continue

		var ac: = _ac(c)
		var facing: = _piston_facing_dir(ac)
		var powered: = _piston_is_powered(c, facing)
		var head: = c + facing


		if powered and not _is_extender(head):
			_mark_piston_busy(c, facing)
			_piston_try_extend_and_push(c, facing)

		if ( not powered) and _is_extender(head) and _ac(head) == _extender_ac_for_dir(facing):

			if _piston_busy.has(c) or _piston_busy.has(head):
				continue

			_mark_piston_busy(c, facing)

			if _is_stringy_piston(c):

				_stringy_try_retract(c, facing)
			else:

				if _regular_piston_step_forward_if_stringy_in_front(c, facing):
					continue
				_piston_try_retract(c, facing)




		var was: = bool(_piston_last_power.get(c, false))
		_piston_last_power[c] = powered


		if ( not powered) and was:
			if _is_stringy_piston(c):
				_stringy_try_retract(c, facing)
			else:
				if _regular_piston_step_forward_if_stringy_in_front(c, facing):
					continue
				_piston_try_retract(c, facing)



		validate_cells[c] = true
		validate_cells[head] = true
		for d in N4:
			validate_cells[c + d] = true
			validate_cells[head + d] = true


	for k in validate_cells.keys():
		_validate_extender_or_erase(k)

const PISTON_CONTRACT = preload("uid://ctjx675jss5fq")
const PISTON_EXTEND = preload("uid://81xxypa0gbxq")

func _play_piston_sfx(stream: AudioStream, piston_cell: Vector2i) -> void :
	if stream == null: return
	var pos: = ground.map_to_local(piston_cell)
	rpc("cli_play_world_sfx", stream.resource_path, pos, 10.0)

@rpc("any_peer", "reliable")
func srv_request_piston_click(cell: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var actor: = multiplayer.get_remote_sender_id()
	if actor == 0: actor = SERVER_ID
	if not _server_can_reach_cell(actor, cell, BREAK_REACH_CELLS): return
	if not _is_piston_cell(cell): return

	var ac: = _ac(cell)
	var facing: = _piston_facing_dir(ac)


	if _piston_is_powered(cell, facing): return
	if _is_extender(cell + facing): return


	var list: = (T_STRINGY_PISTON_FACES if T_STRINGY_PISTON_FACES.has(ac) else T_PISTON_FACES)
	var idx: = list.find(ac)
	if idx == -1: return
	var new_ac = list[(idx + 1) % list.size()]

	set_cell_override(cell, new_ac, 0)
	rpc("cli_set_cell", cell, SRC, new_ac)
	_mark_yoylite_dirty(cell)

func _piston_remove_extender(piston_cell: Vector2i, facing: Vector2i) -> void :
	var head: = piston_cell + facing
	if not _is_extender(head):
		return
	mark_cell_removed(head)
	rpc("cli_erase_cell", head)
	_mark_yoylite_dirty(head)
	_play_piston_sfx(PISTON_CONTRACT, piston_cell)

func _piston_try_retract(piston_cell: Vector2i, facing: Vector2i) -> void :
	_piston_remove_extender(piston_cell, facing)

const STONE_BUTTON_PRESS = preload("uid://ducrxtksvwm3q")
const STONE_BUTTON_UNPRESS = preload("uid://stt6lch2ad83")

func _is_lever(cell: Vector2i) -> bool:
	var a: = _ac(cell)
	return a == T_LEVER_OFF or a == T_LEVER_ON

func _is_lever_powered(cell: Vector2i) -> bool:
	return _ac(cell) == T_LEVER_ON

@rpc("any_peer", "reliable")
func srv_request_lever_click(cell: Vector2i) -> void :
	if not multiplayer.is_server(): return

	var actor: = multiplayer.get_remote_sender_id()
	if actor == 0: actor = SERVER_ID
	if not _server_can_reach_cell(actor, cell, BREAK_REACH_CELLS): return

	if not _is_lever(cell): return

	var was_on: = _is_lever_powered(cell)
	var next_ac: = (T_LEVER_OFF if was_on else T_LEVER_ON)

	set_cell_override(cell, next_ac, 0)
	rpc("cli_set_cell", cell, SRC, next_ac)


	_mark_yoylite_dirty(cell)


	_play_piston_sfx(STONE_BUTTON_UNPRESS if was_on else STONE_BUTTON_PRESS, cell)


const SFX_KIND_STEP: = 1
const SFX_KIND_JUMP: = 2
const SFX_KIND_HIT: = 3
const SFX_KIND_EAT: = 4
const SFX_KIND_AOU: = 5
const SFX_KIND_PICKUP: = 6

var _last_sfx_time: = {}

const STEP_MIN_INTERVAL: = 0.14
const JUMP_MIN_INTERVAL: = 0.2
const HIT_MIN_INTERVAL: = 0.08

func _ok_rate(pid: int, kind: int, now: float) -> bool:
	var key = Vector2i(pid, kind)

	var min_gap: = 0.0
	match kind:
		SFX_KIND_STEP:
			min_gap = STEP_MIN_INTERVAL
		SFX_KIND_JUMP:
			min_gap = JUMP_MIN_INTERVAL
		_:
			min_gap = HIT_MIN_INTERVAL

	var last: = float(_last_sfx_time.get(key, -1000000000.0))
	if (now - last) < min_gap:
		return false
	_last_sfx_time[key] = now
	return true


@rpc("any_peer", "reliable")
func srv_request_player_sfx(kind: int, stream_path: String, pos: Vector2, vol_db: float = 0.0) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()
	_server_broadcast_player_sfx(pid, kind, stream_path, pos, vol_db)


func _server_broadcast_player_sfx(pid: int, kind: int, stream_path: String, pos: Vector2, vol_db: float) -> void :
	rpc("cli_play_player_sfx", pid, kind, stream_path, pos, vol_db)


@rpc("call_local")
func cli_play_player_sfx(pid: int, kind: int, stream_path: String, pos: Vector2, vol_db: float = 0.0) -> void :

	if pid == multiplayer.get_unique_id():
		return

	var stream: = _get_res(stream_path) as AudioStream
	if stream == null: return

	var p: = AudioStreamPlayer2D.new()
	p.stream = stream
	p.volume_db = vol_db
	p.global_position = pos

	p.attenuation = 1.0
	p.max_distance = 900
	match kind:
		SFX_KIND_PICKUP:
			p.pitch_scale = randf_range(0.8, 2.8)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

@rpc("any_peer", "reliable")
func srv_request_explode_crystal(cell: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()
	var pc: = ground.local_to_map(ground.to_local(players[pid].global_position))
	if _chebyshev(cell, pc) > BREAK_REACH_CELLS: return
	if ground.get_cell_source_id(cell) != SRC: return
	if ground.get_cell_atlas_coords(cell) != T_YOYLE_CRYSTAL: return
	_server_detonate_crystal(cell)

@rpc("any_peer", "reliable")
func srv_request_ignite_dynamite(cell: Vector2i, selected_item_id: int) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()


	var pc: = ground.local_to_map(ground.to_local(players[pid].global_position))
	if _chebyshev(cell, pc) > BREAK_REACH_CELLS: return
	if selected_item_id != ITEM_LIGHTER: return
	if not _is_dynamite_cell(cell): return

	_server_ignite_dynamite(cell, DYN_FUSE_SEC)


	_consume_lighter_for(pid)

func _server_ignite_dynamite_from_yoylite(cells_to_check: Array[Vector2i]) -> void :


	var seen: Dictionary = {}

	for seed in cells_to_check:
		for off in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var c = seed + off
			if seen.has(c):
				continue
			seen[c] = true

			if not _is_dynamite_cell(c):
				continue


			for d in N4:
				var n = c + d
				if _is_wire_powered(n) or _is_emitter_powered(n):
					_server_ignite_dynamite(c, DYN_FUSE_SEC, false)
					break

func _consume_lighter_for(pid: int) -> void :

	if pid == multiplayer.get_unique_id():
		cli_consume_lighter_durability()
	else:
		rpc_id(pid, "cli_consume_lighter_durability")

@rpc("call_local")
func cli_consume_lighter_durability() -> void :
	var hb: = $CanvasLayer / itembar
	if hb == null: return
	var idx: = int(hb.selected)
	if idx < 0 or idx >= hb.slots.size(): return

	var s = hb.slots[idx]
	if int(s.get("id", 0)) != ITEM_LIGHTER:
		return


	s = ToolDurability.ensure_meta(s)
	hb.slots[idx] = s


	ToolDurability.damage_selected_tool(hb, 1)
	print("CONSUMED LIGHTER")
	hb._notify_held_item_changed()

func _server_ignite_dynamite(cell: Vector2i, fuse_sec: float, by_chain: bool = false) -> void :
	if _lit_dynamite.has(cell): return
	_lit_dynamite[cell] = fuse_sec
	var pos: = ground.to_global(ground.map_to_local(cell))
	rpc("cli_on_dynamite_lit", cell, fuse_sec, pos, by_chain)

@rpc("call_local")
func cli_on_dynamite_lit(_cell: Vector2i, _fuse_sec: float, pos: Vector2, by_chain: bool = false) -> void :
	if by_chain:
		return
	_play_sfx_at(FUSE, pos, 10.0)

func _tick_dynamite(dt: float) -> void :
	if _lit_dynamite.is_empty(): return
	var to_boom: Array[Vector2i] = []
	for c in _lit_dynamite.keys():
		var t: = float(_lit_dynamite[c]) - dt
		if t <= 0.0:
			to_boom.append(c)
		else:
			_lit_dynamite[c] = t
	for c in to_boom:
		_lit_dynamite.erase(c)
		_server_detonate_dynamite(c)

func _server_can_reach_cell(actor_pid: int, cell: Vector2i, max_cells: int) -> bool:
	if not players.has(actor_pid) or not is_instance_valid(players[actor_pid]):
		return false
	var pc: = ground.local_to_map(ground.to_local(players[actor_pid].global_position))
	return _chebyshev(cell, pc) <= max_cells

func _server_request_ignite(actor_pid: int, cell: Vector2i, selected_item_id: int) -> void :
	if selected_item_id != ITEM_LIGHTER: return
	if not _is_dynamite_cell(cell): return
	if not _server_can_reach_cell(actor_pid, cell, BREAK_REACH_CELLS): return
	_server_ignite_dynamite(cell, DYN_FUSE_SEC)
	_consume_lighter_for(actor_pid)

func _server_request_explode_crystal(actor_pid: int, cell: Vector2i) -> void :
	if ground.get_cell_source_id(cell) != SRC: return
	if ground.get_cell_atlas_coords(cell) != T_YOYLE_CRYSTAL: return
	if not _server_can_reach_cell(actor_pid, cell, BREAK_REACH_CELLS): return
	_server_detonate_crystal(cell)



func _server_detonate_crystal(cell: Vector2i) -> void :
	var support: = cell + Vector2i(0, 1)


	var support_was_stone: = (ground.get_cell_source_id(support) == SRC
		and ground.get_cell_atlas_coords(support) == T_STONE)

	_protected_cells[support] = true




	_server_detonate_blast(cell, [support], CRYSTAL_BREAK_RADIUS_CELLS)

	_protected_cells.erase(support)


	var center: = ground.to_global(ground.map_to_local(cell))
	_server_apply_explosion_damage(center, CRYSTAL_DAMAGE_RADIUS_PX, 6, 900.0)


	if support_was_stone:
		var cur_src: = ground.get_cell_source_id(support)
		var cur_ac: = ground.get_cell_atlas_coords(support)
		if not (cur_src == SRC and cur_ac == T_STONE):
			rpc("cli_set_cell", support, SRC, T_STONE)
			cell_overrides[support] = T_STONE
			removed_cells.erase(support)


func _server_detonate_dynamite(cell: Vector2i, exclude: Array[Vector2i] = []) -> void :
	var center: = ground.to_global(ground.map_to_local(cell))
	rpc("cli_on_explosion", center)


	_server_break_cell(cell, SERVER_ID, ITEM_NONE, true)

	var r: = DYN_RADIUS_CELLS
	for dx in range( - r, r + 1):
		for dy in range( - r, r + 1):
			var c2: = cell + Vector2i(dx, dy)

			if _chebyshev(cell, c2) > r: continue
			if exclude.has(c2):
				continue

			if _is_dynamite_cell(c2):
				_server_ignite_dynamite(c2, randf_range(DYN_CHAIN_MIN, DYN_CHAIN_MAX), true)
				continue

			if _cell_is_breakable(c2):
				_server_break_cell(c2, SERVER_ID, ITEM_NONE, false)

	_server_apply_explosion_damage(center, radius_px, 6, 900.0)

func _server_detonate_blast(cell: Vector2i, exclude: Array[Vector2i] = [], r_cells: int = DYN_RADIUS_CELLS) -> void :
	var center: = ground.to_global(ground.map_to_local(cell))
	rpc("cli_on_explosion", center)


	_server_break_cell(cell, SERVER_ID, ITEM_NONE, true)

	for dx in range( - r_cells, r_cells + 1):
		for dy in range( - r_cells, r_cells + 1):
			var c2: = cell + Vector2i(dx, dy)
			if _chebyshev(cell, c2) > r_cells:
				continue
			if exclude.has(c2):
				continue


			if _is_dynamite_cell(c2):
				_server_ignite_dynamite(c2, randf_range(DYN_CHAIN_MIN, DYN_CHAIN_MAX), true)
				continue

			if _cell_is_breakable(c2):
				_server_break_cell(c2, SERVER_ID, ITEM_NONE, false)

@rpc("call_local")
func cli_on_explosion(pos: Vector2) -> void :
	_queue_boom(pos)

func _request_throw_pearl(world_pos: Vector2) -> void :
	var pid: = multiplayer.get_unique_id()
	if multiplayer.is_server():
		srv_request_throw_pearl(world_pos, pid)
	else:
		rpc_id(1, "srv_request_throw_pearl", world_pos, pid)

var _pearl_seq: = 1
var _pearls: = {}

@rpc("any_peer", "reliable")
func srv_request_throw_pearl(target_world: Vector2, from_pid: int) -> void :
	if not multiplayer.is_server(): return
	if not players.has(from_pid): return




	var start = players[from_pid].global_position
	var dir = (target_world - start).normalized()
	var vel = dir * PEARL_THROW_SPEED + Vector2(0, - PEARL_UP_THROW)


	var pearl = preload("res://YoylitePearl.tscn").instantiate()
	pearl.owner_pid = from_pid
	pearl.pearl_id = _pearl_seq
	pearl.initial_velocity = vel
	pearl.max_lifetime = PEARL_MAX_LIFETIME_S
	pearl.visual_only = false
	pearl.global_position = start
	pearl.connect("landed", Callable(self, "_on_pearl_landed"))
	projectiles.add_child(pearl)
	_pearls[_pearl_seq] = pearl
	var this_id: = _pearl_seq
	_pearl_seq += 1


	rpc("cli_spawn_pearl_proxy", this_id, start, vel, PEARL_MAX_LIFETIME_S)


	rpc_id(from_pid, "cli_consume_selected_pearl_if_any")

func _on_pearl_landed(world_pos: Vector2, pearl_id: int) -> void :
	var pearl = _pearls.get(pearl_id)
	if pearl == null: return
	var pid = pearl.owner_pid
	_pearls.erase(pearl_id)

	var safe: = _find_safe_teleport_pos(world_pos)
	safe.y -= 6.0


	_force_server_warp(pid, safe)


	rpc_id(pid, "cli_force_warp_self", safe)


	rpc("cli_force_warp_proxy", pid, safe)


	rpc("cli_play_teleport_fx", safe)

func _force_server_warp(pid: int, pos: Vector2) -> void :
	var p = players.get(pid)
	if p and is_instance_valid(p):
		var from = p.global_position
		p.global_position = pos
		if "velocity" in p: p.velocity = Vector2.ZERO
		if p.has_method("reset_fall_state_after_teleport"):
			p.reset_fall_state_after_teleport(from)

@rpc("call_local")
func cli_force_warp_self(pos: Vector2) -> void :
	var me = players.get(multiplayer.get_unique_id())
	if me and is_instance_valid(me):
		var from = me.global_position
		me.global_position = pos
		if "velocity" in me: me.velocity = Vector2.ZERO
		if me.has_method("reset_fall_state_after_teleport"):
			me.reset_fall_state_after_teleport(from)
		var cam = me.get_node_or_null("Camera2D")
		if cam and cam.has_method("reset_smoothing"):
			cam.reset_smoothing()

func _find_safe_teleport_pos(world_guess: Vector2) -> Vector2:
	var tm: TileMapLayer = ground
	var cell: = tm.local_to_map(tm.to_local(world_guess))

	var up: = 0
	while up < 40 and _cell_is_solid(cell):
		cell.y -= 1;up += 1

	var down: = 0
	while down < 40 and not _cell_is_solid(cell + Vector2i(0, 1)):
		cell.y += 1;down += 1

	return tm.to_global(tm.map_to_local(cell))

func _cell_is_solid(c: Vector2i) -> bool:

	return ground.get_cell_source_id(c) != -1

func _server_tp_player_to(pid: int, world_pos: Vector2) -> void :
	if not players.has(pid): return
	var p = players[pid]
	if p and is_instance_valid(p):
		p.global_position = world_pos

@rpc("call_local")
func cli_play_teleport_fx(world_pos: Vector2) -> void :
	if randi_range(1, 2) == 1:
		_play_sfx_at(TELEPORT_1, world_pos, 10)
	else:
		_play_sfx_at(TELEPORT_2, world_pos, 10)

@rpc("call_local")
func cli_spawn_pearl_proxy(pearl_id: int, start: Vector2, vel: Vector2, life: float) -> void :

	if multiplayer.is_server(): return
	var pearl: = preload("res://YoylitePearl.tscn").instantiate()
	pearl.owner_pid = 0
	pearl.pearl_id = pearl_id
	pearl.initial_velocity = vel
	pearl.max_lifetime = life
	pearl.visual_only = true
	pearl.global_position = start
	projectiles.add_child(pearl)

@rpc("call_local")
func cli_end_pearl_proxy(pearl_id: int, land_pos: Vector2) -> void :

	for child in projectiles.get_children():
		if child is YoylitePearl and child.pearl_id == pearl_id:
			child.end_at(land_pos)

@rpc("call_local")
func cli_consume_selected_pearl_if_any() -> void :
	var hb: = $CanvasLayer / itembar
	if hb == null: return
	var idx: = int(hb.selected)
	if idx < 0 or idx >= hb.slots.size(): return
	var s = hb.slots[idx]
	if int(s.get("id", 0)) != ITEM_YOYLITE_PEARL: return


	var count: = int(s.get("count", 1))
	count -= 1
	if count <= 0:
		hb.slots[idx] = {"id": 0, "count": 0}
	else:
		s["count"] = count
		hb.slots[idx] = s

	hb.queue_redraw()
	hb._notify_held_item_changed()

	if hb.has_method("_touch_player_save"):
		hb._touch_player_save()

@rpc("call_local")
func cli_spawn_pearl_fx(start_pos: Vector2, end_pos: Vector2, travel_time: float) -> void :

	var spr: = Sprite2D.new()
	spr.texture = _get_tex_from_path(PATH_YOYLITE_PEARL)
	spr.scale = Vector2(0.6, 0.6)
	spr.centered = true
	spr.global_position = start_pos
	add_child(spr)

	var tween: = create_tween()
	tween.tween_property(spr, "global_position", end_pos, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(spr, "queue_free"))


var _server_boxes: = {}


func _cell_key(cell: Vector2i) -> String:
	return str(cell.x) + "," + str(cell.y)


func _server_nearest_player_pos(from: Vector2) -> Vector2:
	var best_pos: = from
	var best_d2: = INF
	for pid in players.keys():
		var p = players[pid]
		if p == null or not is_instance_valid(p):
			continue
		var d2: = from.distance_squared_to(p.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best_pos = p.global_position
	return best_pos

@rpc("call_local", "unreliable")
func cli_pickup_state(pid: int, pos: Vector2, vel: Vector2) -> void :

	if multiplayer.is_server():
		return

	var node = pickups.get(pid, null)
	if node != null and is_instance_valid(node) and node.has_method("net_apply_state"):
		node.net_apply_state(pos, vel)

func client_set_held_item(item_id: int) -> void :

	if multiplayer.is_server():
		var pid: = multiplayer.get_unique_id()
		_server_apply_held_item(pid, item_id)
	else:
		rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_set_held_item", item_id)

@rpc("any_peer", "reliable")
func srv_set_held_item(item_id: int) -> void :
	if not multiplayer.is_server():
		return
	var pid: = multiplayer.get_remote_sender_id()
	_server_apply_held_item(pid, item_id)

func _server_apply_held_item(pid: int, item_id: int) -> void :
	_held_item_by_peer[pid] = item_id


	if typeof(_equipped_item) == TYPE_DICTIONARY:
		_equipped_item[pid] = item_id


	rpc("cli_set_held_item_for_peer", pid, item_id)

@rpc("call_local")
func cli_set_held_item_for_peer(pid: int, item_id: int) -> void :
	var p = players.get(pid, null)
	if p and is_instance_valid(p) and p.has_method("set_held_item_visual"):
		p.call("set_held_item_visual", item_id)


func _place_box_at(cell: Vector2i, slot: Dictionary) -> void :

	var key: = _cell_key(cell)
	var meta: = (slot.get("meta", {}) as Dictionary)
	var box: = (meta.get("box", {}) as Dictionary)
	if box.size() == 0:
		box = BoxMeta.skeleton()
	_server_boxes[key] = {"box": box}

func _ensure_box_record(key: String) -> void :
	if not _server_boxes.has(key) or typeof(_server_boxes[key]) != TYPE_DICTIONARY:
		_server_boxes[key] = {"box": BoxMeta.skeleton(), "rev": 1}
		return

	var rec = _server_boxes[key]

	if not rec.has("box") or typeof(rec["box"]) != TYPE_DICTIONARY:
		rec["box"] = BoxMeta.skeleton()
	if not rec.has("rev") or typeof(rec["rev"]) != TYPE_INT:
		rec["rev"] = 1
	_server_boxes[key] = rec


@rpc("any_peer", "call_local")
func srv_request_open_box(cell: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var key: = _cell_key(cell)
	_ensure_box_record(key)

	var rec = _server_boxes.get(key, {})
	var box: = (rec.get("box", BoxMeta.skeleton()) as Dictionary).duplicate(true)
	var rev: = int(rec.get("rev", 1))

	box["_rev"] = rev
	var who: = multiplayer.get_remote_sender_id()
	if who == 0:
		cli_open_box(cell, box)
	else:
		rpc_id(who, "cli_open_box", cell, box)


@rpc("any_peer", "reliable")
func srv_box_set_slot(cell: Vector2i, slot_index: int, stack: Dictionary, client_rev: int) -> void :
	if not multiplayer.is_server(): return
	var key: = _cell_key(cell)
	_ensure_box_record(key)
	var rec = _server_boxes[key]
	var srv_rev: = int(rec.get("rev", 1))
	var box: = (rec.get("box", BoxMeta.skeleton()) as Dictionary)


	var slots: = (box.get("slots", []) as Array)
	if slot_index < 0 or slot_index >= slots.size():
		return


	if client_rev != srv_rev:

		var who: = multiplayer.get_remote_sender_id()
		var latest: = box.duplicate(true)
		latest["_rev"] = srv_rev
		if who == 0: cli_box_snapshot(cell, latest)
		else: rpc_id(who, "cli_box_snapshot", cell, latest)
		return


	var s: = stack.duplicate(true)
	var id: = int(s.get("id", 0))
	var cnt: = int(s.get("count", 0))
	if id == 0 or cnt <= 0:
		s = {"id": 0, "count": 0}
	else:

		if s.has("meta") and typeof(s["meta"]) == TYPE_DICTIONARY:
			s["meta"] = (s["meta"] as Dictionary).duplicate(true)

		s["count"] = clamp(cnt, 1, 64)


	slots[slot_index] = s
	box["slots"] = slots
	rec["box"] = box
	rec["rev"] = srv_rev + 1
	_server_boxes[key] = rec

	rpc("cli_box_slot", cell, slot_index, stack, rec["rev"])

@rpc("call_local")
func cli_box_snapshot(cell: Vector2i, snapshot: Dictionary) -> void :

	var ui: = _find_box_ui()
	if ui: ui.call_deferred("_on_box_snapshot", cell, snapshot)

@rpc("call_local")
func cli_box_slot(cell: Vector2i, idx: int, s: Dictionary, new_rev: int) -> void :
	var ui: = _find_box_ui()
	if ui: ui.call_deferred("_on_box_slot", cell, idx, s, new_rev)

func _find_box_ui() -> Node:
	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return null
	var ui: Node = world.get_node_or_null("CanvasLayer/YoyliteBoxMenu")
	if ui == null: ui = world.get_node_or_null("YoyliteBoxMenu")
	if ui == null: ui = world.get_tree().get_first_node_in_group("yoylite_box_menu")
	return ui

@rpc("call_local")
func cli_open_box(cell: Vector2i, snapshot: Dictionary) -> void :
	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	var ui: Node = world.get_node_or_null("CanvasLayer/YoyliteBoxMenu")
	if ui == null: ui = world.get_node_or_null("YoyliteBoxMenu")
	if ui == null: ui = world.get_tree().get_first_node_in_group("yoylite_box_menu")
	if ui == null: return
	if not ui.is_node_ready():
		ui.ready.connect( func(): ui.call_deferred("open_for_world", cell, snapshot), CONNECT_ONE_SHOT)
	else:
		ui.call_deferred("open_for_world", cell, snapshot)


@rpc("any_peer", "reliable")
func srv_container_commit(cell: Vector2i, box: Dictionary) -> void :
	if not multiplayer.is_server():
		return
	var key: = str(cell.x) + "," + str(cell.y)
	if not _server_boxes.has(key):
		_server_boxes[key] = {}
	_server_boxes[key]["box"] = box.duplicate(true)


	if GameSession.current_world_id != "":
		WorldSave.save_world(GameSession.current_world_id, self)

func place_yoylite_box(cell: Vector2i, source_slot: Dictionary) -> void :
	var key: = _cell_key(cell)
	var meta: = (source_slot.get("meta", {}) as Dictionary)
	var box: = (meta.get("box", {}) as Dictionary)
	if box.is_empty():
		box = BoxMeta.skeleton()


	var want: = int(box.get("cols", 8)) * int(box.get("rows", 4))
	var slots: = (box.get("slots", []) as Array).duplicate(true)
	while slots.size() < want: slots.append({"id": 0, "count": 0})
	if slots.size() > want: slots.resize(want)
	box["slots"] = slots

	var rec = _server_boxes.get(key, {})
	rec["box"] = box
	rec["rev"] = int(rec.get("rev", 1))
	_server_boxes[key] = rec

func _break_box_at(cell: Vector2i) -> void :
	var key: = _cell_key(cell)
	var data = _server_boxes.get(key, {})
	var box: = (data.get("box", {}) as Dictionary)
	_server_boxes.erase(key)

	var wp: = _cell_world_center(cell);wp.y -= 6.0
	if multiplayer.is_server():
		srv_request_drop(ITEM_YOYLITE_BOX, 1, wp, {"box": box})
	else:
		rpc_id(1, "srv_request_drop", ITEM_YOYLITE_BOX, 1, wp, {"box": box})

func _cell_world_center(cell: Vector2i) -> Vector2:
	var ground = get("ground")
	return ground.to_global(ground.map_to_local(cell))

var _spyglass_on: = false

@rpc("call_local")
func cli_toggle_spyglass(active: bool) -> void :
	var me = players.get(multiplayer.get_unique_id())
	if not me or not me.cam:
		return

	var cam = me.cam
	var target_zoom: = 0.5 if active else 1.0


	var zoom_diff = abs(cam.zoom.x - target_zoom) > 0.01

	var tween: = get_tree().create_tween()
	tween.tween_property(cam, "zoom", Vector2(target_zoom, target_zoom), 0.18)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if zoom_diff:
		var sound: = SPYGLASS_USE_OGG if active else SPYGLASS_STOP_OGG
		_play_sfx_at(sound, me.global_position, 10.0)


var _server_anchor_charge: = {}

func _is_anchor_cell(cell: Vector2i) -> bool:
	if ground.get_cell_source_id(cell) != SRC:
		return false
	var ac: = ground.get_cell_atlas_coords(cell)
	return ac == T_YOYLITE_ANCHOR_0 or ac == T_YOYLITE_ANCHOR_1\
	or ac == T_YOYLITE_ANCHOR_2 or ac == T_YOYLITE_ANCHOR_3\
	or ac == T_YOYLITE_ANCHOR_4

func _anchor_charge_from_tile(ac: Vector2i) -> int:
	if ac == T_YOYLITE_ANCHOR_0: return 0
	if ac == T_YOYLITE_ANCHOR_1: return 1
	if ac == T_YOYLITE_ANCHOR_2: return 2
	if ac == T_YOYLITE_ANCHOR_3: return 3
	if ac == T_YOYLITE_ANCHOR_4: return 4
	return 0

func _anchor_ac_for_charge(ch: int) -> Vector2i:
	match ch:
		0: return T_YOYLITE_ANCHOR_0
		1: return T_YOYLITE_ANCHOR_1
		2: return T_YOYLITE_ANCHOR_2
		3: return T_YOYLITE_ANCHOR_3
		4: return T_YOYLITE_ANCHOR_4
		_: return T_YOYLITE_ANCHOR_0

var _rng: = RandomNumberGenerator.new()

func _pick_random_anchor_charge_sfx() -> AudioStream:
	var picks: Array = [
		RESPAWN_ANCHOR_CHARGE_1_OGG, 
		RESPAWN_ANCHOR_CHARGE_2_OGG, 
		RESPAWN_ANCHOR_CHARGE_3_OGG, 
	]
	return picks[_rng.randi_range(0, picks.size() - 1)]

@rpc("any_peer", "reliable")
func srv_request_anchor_click(cell: Vector2i, selected_item_id: int, selected_count: int) -> void :
	if not multiplayer.is_server(): return


	var actor_pid: = multiplayer.get_remote_sender_id()
	if actor_pid == 0: actor_pid = SERVER_ID

	if not _server_can_reach_cell(actor_pid, cell, BREAK_REACH_CELLS): return
	if not _is_anchor_cell(cell): return

	var ac: = ground.get_cell_atlas_coords(cell)
	var charge = _server_anchor_charge.get(cell, _anchor_charge_from_tile(ac))
	var pos: = ground.to_global(ground.map_to_local(cell))



	if charge >= 4:
		_server_explode_anchor(cell, pos, 4)
		return


	var has_yoylite: = (selected_item_id == ITEM_YOYLITE)
	if charge > 0 and not has_yoylite:
		_server_explode_anchor(cell, pos, charge)
		return


	if charge == 0 and not has_yoylite:
		return


	rpc_id(actor_pid, "cli_consume_selected_yoylite_if_any")
	charge += 1
	_server_anchor_charge[cell] = charge

	var new_ac: = _anchor_ac_for_charge(charge)
	rpc("cli_set_cell", cell, SRC, new_ac)
	cell_overrides[cell] = new_ac
	removed_cells.erase(cell)

	var s: = _pick_random_anchor_charge_sfx()
	if s:
		rpc("cli_play_world_sfx", s.resource_path, pos, 10.0)

@rpc("call_local")
func cli_play_world_sfx(stream_path: String, pos: Vector2, vol_db: float = 0.0) -> void :
	var s: = _get_res(stream_path) as AudioStream
	_play_sfx_at(s, pos, vol_db)


const ANCHOR_BREAK_RADIUS_MUL: = {1: 1.0, 2: 1.25, 3: 1.6, 4: 2.0}
const ANCHOR_DAMAGE_RADIUS_MUL: = {1: 1.0, 2: 1.2, 3: 1.5, 4: 1.9}
const ANCHOR_DAMAGE_AMOUNT: = {1: 6, 2: 8, 3: 10, 4: 12}
const ANCHOR_KNOCKBACK: = {1: 900.0, 2: 1050.0, 3: 1200.0, 4: 1400.0}

func _server_explode_anchor(cell: Vector2i, world_pos: Vector2, phase: int) -> void :

	phase = clamp(phase, 1, 4)

	_server_anchor_charge.erase(cell)

	_server_break_cell(cell, SERVER_ID, ITEM_NONE, true)


	var break_r: = int(round(float(CRYSTAL_BREAK_RADIUS_CELLS) * ANCHOR_BREAK_RADIUS_MUL[phase]))
	_server_detonate_blast(cell, [], break_r)


	var dmg_r = float(CRYSTAL_DAMAGE_RADIUS_PX) * ANCHOR_DAMAGE_RADIUS_MUL[phase]
	var dmg: = int(ANCHOR_DAMAGE_AMOUNT[phase])
	var kb: = float(ANCHOR_KNOCKBACK[phase])
	_server_apply_explosion_damage(world_pos, dmg_r, dmg, kb)

func _client_try_anchor_click(target_cell: Vector2i) -> bool:
	if not _is_anchor_cell(target_cell):
		return false

	var selected_item_id: = 0
	var selected_count: = 1
	var hb: = $CanvasLayer / itembar
	if hb and hb.selected >= 0 and hb.selected < hb.slots.size():
		var s = hb.slots[hb.selected]
		selected_item_id = int(s.get("id", 0))
		selected_count = int(s.get("count", 1))

	if multiplayer.is_server():
		srv_request_anchor_click(target_cell, selected_item_id, selected_count)
	else:
		rpc_id(SERVER_ID, "srv_request_anchor_click", target_cell, selected_item_id, selected_count)
	return true

@rpc("call_local")
func cli_consume_selected_yoylite_if_any() -> void :
	var hb: = $CanvasLayer / itembar
	if hb == null: return
	var idx: = int(hb.selected)
	if idx < 0 or idx >= hb.slots.size(): return
	var s = hb.slots[idx]
	if int(s.get("id", 0)) != ITEM_YOYLITE: return

	var count: = int(s.get("count", 0))
	if count <= 0: return
	count -= 1
	if count <= 0:
		hb.slots[idx] = {"id": 0, "count": 0}
	else:
		s["count"] = count
		hb.slots[idx] = s

	hb.queue_redraw()
	hb._notify_held_item_changed()
	if hb.has_method("_touch_player_save"):
		hb._touch_player_save()

const HURTBOX_MASK: = 1 << 7




func _server_apply_explosion_damage(center: Vector2, radius_px: float, base_damage: int, impulse_strength: float) -> void :
	if not multiplayer.is_server(): return

	var targets: = get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("bug")
	targets += get_tree().get_nodes_in_group("fish")

	for n in targets:
		if not (n is Node2D): continue
		var pos: = (n as Node2D).global_position
		var dist: = center.distance_to(pos)
		if dist > radius_px: continue

		var dmg: = int(ceil(base_damage * (radius_px - dist) / radius_px))
		if dmg <= 0: dmg = 1

		var dir: = (pos - center).normalized()
		var impulse: = dir * impulse_strength * (radius_px - dist) / radius_px

		if n.is_in_group("player"):
			var auth: = n.get_multiplayer_authority()
			if auth != 0:
				n.rpc_id(auth, "cli_receive_damage", dmg, impulse)
			else:
				n.cli_receive_damage(dmg, impulse)
		elif n.is_in_group("bug"):
			var bid: = int(n.get("bug_id")) if n.has_method("get") else 0
			if bid != 0 and _server_bugs.has(bid):
				var info = _server_bugs[bid]
				var hp: = int(info.get("hp", 1))
				hp = max(0, hp - dmg)
				info["hp"] = hp
				_server_bugs[bid] = info


				if n.has_method("cli_bug_take_damage"): n.cli_bug_take_damage(dmg)
				if n.has_method("cli_bug_knockback"): n.cli_bug_knockback(impulse)


				if hp <= 0:
					_server_kill_bug_with_fade(bid)
		elif n.is_in_group("fish"):
			var fid: = int(n.get("fish_id")) if n.has_method("get") else 0
			if fid != 0 and _server_fishes.has(fid):
				var info = _server_fishes[fid]
				var hp: = int(info.get("hp", 3))

				hp = max(0, hp - dmg)
				info["hp"] = hp
				_server_fishes[fid] = info

				if n.has_method("cli_fish_take_damage"):
					n.cli_fish_take_damage(dmg)


				if hp <= 0:
					rpc("rpc_despawn_fish", fid)


const LUCKY_MIN_STACK: = 1
const LUCKY_MAX_STACK: = 20

func _random_item_id_like_wheel() -> int:

	var EXCLUDE: = {69: true}


	var ids: Array[int] = []
	if has_method("name_map_for_hotbar"):
		var m: Dictionary = name_map_for_hotbar()
		for k in m.keys():
			var id: = int(k)
			if not EXCLUDE.has(id):
				ids.append(id)
		if ids.size() > 0:
			return ids[randi() % ids.size()]


	var id: = 69
	while id == 69:
		id = 1 + (randi() % 20)
	return id


const MELEE_RANGE_PX: = 64.0
const MELEE_ARC_DEG: = 100.0
const MELEE_DAMAGE: = 1
const MELEE_COOLDOWN: = 0.45
const MELEE_HIT_IFRAME: = 0.35
const MELEE_KNOCKBACK: = Vector2(220.0, -140.0)

const WOODEN_SWORD_DAMAGE_BONUS: = 1
const STONE_SWORD_DAMAGE_BONUS: = 2
const IRON_SWORD_DAMAGE_BONUS: = 3
const YOYLITE_SWORD_DAMAGE_BONUS: = 4

var _last_attack_at: = {}
var _last_hit_at: = {}
var _equipped_item: = {}

func _now() -> float: return Time.get_ticks_msec() * 0.001

const DAYNIGHT_CYCLE_SEC: = 600.0
var _dn_epoch_server_sec: = 0.0

const SKY_WIND_DEFAULT: = Vector2(8.0, 0.0)
var _sky_wind: = SKY_WIND_DEFAULT
var _sky_epoch_sec: = 0.0


const BIOME_NORMAL: = 0
const BIOME_SNOWY_FOREST: = 1
const BIOME_EVIL_FOREST: = 2
const BIOME_DESERT: = 3
const BIOME_GOIKY_CANAL: = 4
const BIOME_YOYLELAND: = 5
const BIOME_YOYLECITY: = 6
const BIOME_YOYLEMOUNTAIN: = 7


const SNOWY_MIN_DIST_CHUNKS: = 6
const SNOWY_MAX_DIST_CHUNKS: = 12

const EVIL_AFTER_MIN_CHUNKS: = 6
const EVIL_AFTER_MAX_CHUNKS: = 12


const MID_SNOW_PROB: = 0.45
const MID_DARK_PROB: = 0.45


const SNOWY_TREE_TRUNK_MIN: = 5
const SNOWY_TREE_TRUNK_MAX: = 8
const SNOWY_TREE_BASE_PROB: = 0.24
const SNOWY_TREE_MIN_SPACING: = 16


const TREE_MIN_SPACING: = 20
const TREE_TRUNK_MIN: = 3
const TREE_TRUNK_MAX: = 4
const TREE_BASE_PROB: = 0.18
const TREE_STEEP_REJECT: = 2
const ALT_LOG_DECOR: = 1
const ALT_DECOR: = 1

const EVIL_TREE_TRUNK_MIN: = 5
const EVIL_TREE_TRUNK_MAX: = 9

const EVIL_TREE_BASE_PROB: = 0.44
const EVIL_TREE_MIN_SPACING: = 8


const EVIL_TREE_CLUSTER_CHANCE: = 0.33
const EVIL_TREE_CLUSTER_MAX_DX: = 5


const DESERT_AFTER_MIN_CHUNKS: = 6
const DESERT_AFTER_MAX_CHUNKS: = 12

const GOIKY_AFTER_MIN_CHUNKS: = 5
const GOIKY_AFTER_MAX_CHUNKS: = 10


const CACTUS_BASE_PROB: = 0.22
const CACTUS_MIN_SPACING: = 9
const CACTUS_TRUNK_MIN: = 2
const CACTUS_TRUNK_MAX: = 5

const BUSH_BASE_PROB: = 0.18
const BUSH_MIN_SPACING: = 7
const BUSH_TRUNK_MIN: = 1
const BUSH_TRUNK_MAX: = 2

const SLOPE_REJECT: = TREE_STEEP_REJECT


const YOYLE_AFTER_MIN_CHUNKS: = 6
const YOYLE_AFTER_MAX_CHUNKS: = 12


const YOYLECITY_AFTER_MIN_CHUNKS: = 4
const YOYLECITY_AFTER_MAX_CHUNKS: = 9


const YOYLECITY_BUILDING_BASE_PROB: = 0.42
const YOYLECITY_BUILDING_MIN_SPACING: = 4
const YOYLECITY_BUILDING_W_MIN: = 3
const YOYLECITY_BUILDING_W_MAX: = 9
const YOYLECITY_BUILDING_H_MIN: = 6
const YOYLECITY_BUILDING_H_MAX: = 22
const YOYLECITY_WINDOW_CHANCE: = 0.35
const YOYLECITY_WINDOW_MARGIN: = 1


const YOYLECITY_PLAIN_BUSH_BASE_PROB: = 0.1
const YOYLECITY_PLAIN_BUSH_MIN_SPACING: = 9
const YOYLECITY_YOYLE_BUSH_BASE_PROB: = 0.08
const YOYLECITY_YOYLE_BUSH_MIN_SPACING: = 9
const YOYLECITY_BUSH_SLOPE_REJECT: = 2



const YOYLE_MTN_AMP: = 52
const YOYLE_MTN_FREQ: = 0.022
const YOYLE_MTN_WIDTH_CHUNKS: = 8


const YOYLE_MTN_MICRO_JITTER: = 2.0


const YOYLE_MTN_SNOW_FRAC: = 0.22
const YOYLE_MTN_DARK_FRAC: = 0.45



const YOYLE_MTN_SNOW_THICK: = 5
const YOYLE_MTN_DARK_THICK: = 7
const YOYLE_MTN_YOYLE_THICK: = 4



const YOYLE_PLAIN_BUSH_BASE_PROB: = 0.18
const YOYLE_PLAIN_BUSH_MIN_SPACING: = 7
const YOYLE_PLAIN_BUSH_TRUNK_MIN: = 1
const YOYLE_PLAIN_BUSH_TRUNK_MAX: = 2
const BERRY_LEAF_CHANCE: = 0.45


const YOYLE_BUSH_BASE_PROB: = 0.14
const YOYLE_BUSH_MIN_SPACING: = 7
const YOYLE_BUSH_TRUNK_MIN: = 1
const YOYLE_BUSH_TRUNK_MAX: = 2


const FISH_SCENE: PackedScene = preload("res://fish.tscn")

const FISHES_PER_CHUNK_MIN: = 5
const FISHES_PER_CHUNK_MAX: = 10
const FISH_MIN_SEPARATION_PX: = 120.0
const FISH_PROBE_RADIUS_PX: = 10.0

var fishes_parent: Node = null
var _next_fish_id: = 1
var fishes: = {}
var _server_fishes: = {}
var _fishes_by_chunk: = {}
var fish_seeded_chunks: = {}


const BUGS_PER_CHUNK_MIN: = 20
const BUGS_PER_CHUNK_MAX: = 30
const BUG_MIN_SEPARATION: = 48.0
const BUG_SPAWN_RADIUS: = 12.0
var BUG_SPAWN_OFFSET_Y: = -8.0
const BUG_SCENE: PackedScene = preload("res://bug.tscn")
var bug_seeded_chunks: = {}

const BUG_STRING_DROP_CHANCE: = 0.35
const BUG_STRING_DROP_MIN: = 1
const BUG_STRING_DROP_MAX: = 2


const SURFACE_BUGS_PER_CHUNK_MIN: = 3
const SURFACE_BUGS_PER_CHUNK_MAX: = 6
const SURFACE_BUG_MIN_SEPARATION: = 140.0
const SURFACE_SPAWN_ATTEMPTS_FACTOR: = 24
var surface_seeded_chunks: = {}
const MELEE_RANGE_CELLS_BUG: = 3
var _last_is_night: bool = false

var _next_bug_id: = 1
var _server_bugs: = {}
var bugs: = {}
const SERVER_ID: = 1
var _pending_bug_spawns: Array = []

var _peer_loaded_chunks: = {}

@onready var bugs_parent: Node = get_node("Bugs") if has_node("Bugs") else null


var display_to_peer: Dictionary = {}
var peer_to_display: Dictionary = {}

@export var DEV_PASSWORD: String = "developercommandkeysurvival"

var _cmd_box: LineEdit = null
var _cmd_raw: String = ""
var _cmd_updating: = false
var _cmd_caret_pending: = -1

const CMD_FONT: FontFile = preload("res://Shag-Lounge.otf")
const CMD_FONT_SIZE: = 20

func _ensure_command_box() -> void :
	if _cmd_box and is_instance_valid(_cmd_box):
		return
	var ui_root: = $CanvasLayer if has_node("CanvasLayer") else null
	if ui_root == null:
		ui_root = CanvasLayer.new()
		ui_root.name = "CanvasLayer"
		add_child(ui_root)

	_cmd_box = LineEdit.new()
	_cmd_box.name = "CommandBox"
	_cmd_box.visible = false
	_cmd_box.placeholder_text = "Type a message..."
	_cmd_box.focus_mode = Control.FOCUS_ALL

	_cmd_box.anchor_left = 0.2
	_cmd_box.anchor_right = 0.8
	_cmd_box.anchor_top = 0.04
	_cmd_box.anchor_bottom = 0.1
	ui_root.add_child(_cmd_box)


	if CMD_FONT != null:
		_cmd_box.add_theme_font_override("font", CMD_FONT)
		_cmd_box.add_theme_font_size_override("font_size", CMD_FONT_SIZE)


	_cmd_box.add_theme_constant_override("caret_width", 2)


	if not _cmd_box.gui_input.is_connected(_on_cmd_gui_input):
		_cmd_box.gui_input.connect(_on_cmd_gui_input)
	if not _cmd_box.text_submitted.is_connected(_on_cmd_submit_masked):
		_cmd_box.text_submitted.connect(_on_cmd_submit_masked)

func _set_local_input_locked(locked: bool) -> void :

	var player: = get_tree().get_nodes_in_group("player")
	for p in player:
		if p.is_multiplayer_authority():
			p.call_deferred("set_input_locked", locked)
			return

func open_command_box(add_leading_slash: bool = false) -> void :
	_ensure_command_box()
	if not _cmd_box:
		return
	if _cmd_box.visible:
		_cmd_box.grab_focus()
		return

	_cmd_box.visible = true
	_cmd_box.editable = true


	if add_leading_slash:
		_cmd_raw = "/"
	else:
		_cmd_raw = ""

	_set_local_input_locked(true)
	_refresh_masked_view_and_focus(true)

func close_command_box() -> void :
	if not _cmd_box: return
	_cmd_box.visible = false
	_cmd_box.text = ""
	_cmd_raw = ""
	_set_local_input_locked(false)

func _masked_from_raw(s: String) -> String:
	if not s.begins_with("/"):
		return s
	var space_at: = s.find(" ", 1)
	var end_idx: = (space_at if space_at != -1 else s.length())

	var pw_len = max(0, end_idx - 1)
	var masked_pw: = ""
	for i in pw_len:
		masked_pw += "•"
	return "/" + masked_pw + s.substr(end_idx)

func _on_cmd_gui_input(e: InputEvent) -> void :
	if _cmd_updating or not (e is InputEventKey) or not e.pressed or e.echo:
		return


	if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
		_on_cmd_submit_masked(_cmd_box.text)
		_cmd_box.accept_event()
		return
	if e.keycode == KEY_ESCAPE:
		close_command_box()
		_cmd_box.accept_event()
		return


	if e.keycode == KEY_SHIFT or e.keycode == KEY_CTRL or e.keycode == KEY_ALT or e.keycode == KEY_META:
		return


	if e.keycode == KEY_V and e.ctrl_pressed:
		var clip: = DisplayServer.clipboard_get()
		_insert_text_into_raw(clip)
		_refresh_masked_view_and_focus()
		_cmd_box.accept_event()
		return



	if e.keycode == KEY_X and e.ctrl_pressed:
		_delete_selection_in_raw()
		_refresh_masked_view_and_focus()
		_cmd_box.accept_event()
		return
	if e.keycode == KEY_C and e.ctrl_pressed:
		return


	if e.keycode == KEY_BACKSPACE:
		if not _delete_selection_in_raw():
			_delete_left_in_raw()
		_refresh_masked_view_and_focus()
		_cmd_box.accept_event()
		return
	if e.keycode == KEY_DELETE:
		if not _delete_selection_in_raw():
			_delete_right_in_raw()
		_refresh_masked_view_and_focus()
		_cmd_box.accept_event()
		return


	if not (e.ctrl_pressed or e.alt_pressed or e.meta_pressed):
		var ch: = ""
		if e.unicode >= 32:
			ch = char(e.unicode)
		if ch != "":
			_insert_text_into_raw(ch)
			_refresh_masked_view_and_focus()
			_cmd_box.accept_event()
			return


func _current_sel() -> Dictionary:
	var has_sel: = _cmd_box.has_selection()
	var from: = (_cmd_box.get_selection_from_column() if has_sel else _cmd_box.caret_column)
	var to: = (_cmd_box.get_selection_to_column() if has_sel else _cmd_box.caret_column)
	return {"has": has_sel, "from": from, "to": to}

func _insert_text_into_raw(text: String) -> void :
	var sel: = _current_sel()
	var a = min(sel["from"], sel["to"])
	var b = max(sel["from"], sel["to"])
	_cmd_raw = _cmd_raw.substr(0, a) + text + _cmd_raw.substr(b)
	_cmd_caret_pending = a + text.length()

func _delete_selection_in_raw() -> bool:
	var sel: = _current_sel()
	if not sel["has"]:
		return false
	var a = min(sel["from"], sel["to"])
	var b = max(sel["from"], sel["to"])
	_cmd_raw = _cmd_raw.substr(0, a) + _cmd_raw.substr(b)
	_cmd_caret_pending = a
	return true

func _delete_left_in_raw() -> void :
	var caret: = _cmd_box.caret_column
	if caret <= 0: return
	_cmd_raw = _cmd_raw.substr(0, caret - 1) + _cmd_raw.substr(caret)
	_cmd_caret_pending = caret - 1

func _delete_right_in_raw() -> void :
	var caret: = _cmd_box.caret_column
	if caret >= _cmd_raw.length(): return
	_cmd_raw = _cmd_raw.substr(0, caret) + _cmd_raw.substr(caret + 1)
	_cmd_caret_pending = caret

func _on_cmd_submit_masked(_display_text: String) -> void :
	var raw: = _cmd_raw.strip_edges()
	close_command_box()


	if raw != "" and not raw.begins_with("/"):
		_send_chat(raw)
		return


	var ok: = _handle_dev_command(raw)
	if not ok:
		open_command_box()

func _refresh_masked_view_and_focus(place_caret_at_end: bool = false) -> void :
	if not _cmd_box: return
	_cmd_updating = true

	var had_sel: = _cmd_box.has_selection()
	var from: = (_cmd_box.get_selection_from_column() if had_sel else _cmd_box.caret_column)
	var to: = (_cmd_box.get_selection_to_column() if had_sel else _cmd_box.caret_column)
	var caret: = _cmd_box.caret_column

	_cmd_box.text = _masked_from_raw(_cmd_raw)

	if _cmd_caret_pending >= 0:
		_cmd_box.deselect()
		_cmd_box.caret_column = min(_cmd_caret_pending, _cmd_box.text.length())
		_cmd_caret_pending = -1
	elif place_caret_at_end:
		_cmd_box.deselect()
		_cmd_box.caret_column = _cmd_box.text.length()
	elif had_sel:
		_cmd_box.select(min(from, _cmd_box.text.length()), min(to, _cmd_box.text.length()))
	else:
		_cmd_box.caret_column = min(caret, _cmd_box.text.length())

	_cmd_box.grab_focus()
	_cmd_updating = false

func _connect_cmd_box_signals() -> void :
	if not _cmd_box: return
	if not _cmd_box.is_inside_tree(): return
	if not _cmd_box.text_submitted.is_connected(_on_cmd_submit):
		_cmd_box.text_submitted.connect(_on_cmd_submit)

func _on_cmd_submit(_text: String) -> void :
	var raw: = _cmd_raw.strip_edges()
	close_command_box()


	if raw != "" and not raw.begins_with("/"):
		_send_chat(raw)
		return


	var ok: = _handle_dev_command(raw)
	if not ok:
		open_command_box()

func _handle_dev_command(raw: String) -> bool:
	if raw == "":
		return false

	if raw.begins_with("/"):
		raw = raw.substr(1, raw.length() - 1)

	var parts: = raw.split(" ", false)
	if parts.size() < 2:
		_show_cmd_error("Usage: /<password> <command> ...")
		return false

	var pw: = parts[0]
	var cmd: = parts[1].to_lower()
	if pw != DEV_PASSWORD:
		_show_cmd_error("Invalid developer password.")
		return false

	match cmd:
		"give":
			if parts.size() != 5:
				_show_cmd_error("Usage: /<pw> give <player_id|me> <item_id> <count>")
				return false
			var pid_token: = parts[2]
			var item_id: = int(parts[3])
			var count = clamp(int(parts[4]), 1, 999)
			if multiplayer.is_server():
				var to_pid: = _resolve_target_pid(pid_token)
				if to_pid == -1:
					_show_cmd_error("Unknown player: %s" % pid_token)
					return false
				_server_dev_give(to_pid, item_id, count)
			else:
				rpc_id(1, "srv_dev_give_token", pw, pid_token, item_id, count)
			return true

		"teleport":



			if parts.size() < 5:
				_show_cmd_error("Usage: /<pw> teleport <player_id> <x> <y>  OR  /<pw> teleport <player_id> at <player_id>")
				return false

			var target_pid_token: = parts[2]



			if parts.size() == 5 and parts[3].to_lower() == "at":
				var dest_pid_token: = parts[4]
				if multiplayer.is_server():
					var target_pid: = _resolve_target_pid(target_pid_token)
					if target_pid == -1:
						_show_cmd_error("Unknown player (target): %s" % target_pid_token)
						return false
					var dest_pid: = _resolve_target_pid(dest_pid_token)
					if dest_pid == -1:
						_show_cmd_error("Unknown player (destination): %s" % dest_pid_token)
						return false
					_server_dev_tp_to_player(target_pid, dest_pid)
				else:
					rpc_id(1, "srv_dev_tp_to_player", pw, target_pid_token, dest_pid_token)
				return true


			if parts.size() == 5:
				var x_ok: = parts[3].is_valid_int()
				var y_ok: = parts[4].is_valid_int()
				if not (x_ok and y_ok):
					_show_cmd_error("Usage: /<pw> teleport <player_id> <x> <y>")
					return false
				var x: = int(parts[3])
				var y: = int(parts[4])
				if multiplayer.is_server():
					var target_pid: = _resolve_target_pid(target_pid_token)
					if target_pid == -1:
						_show_cmd_error("Unknown player (target): %s" % target_pid_token)
						return false
					_server_dev_tp_coords(target_pid, Vector2(x, y))
				else:
					rpc_id(1, "srv_dev_tp_coords", pw, target_pid_token, x, y)
				return true

			_show_cmd_error("Usage: /<pw> teleport <player_id> <x> <y>  OR  /<pw> teleport <player_id> at <player_id>")
			return false
		"infjump":

			if parts.size() != 4:
				_show_cmd_error("Usage: /<pw> infinitejumping <player_id> <bool>")
				return false

			var pid_token: = parts[2]
			var flag_token: = parts[3]
			if multiplayer.is_server():
				var to_pid: = _resolve_target_pid(pid_token)
				if to_pid == -1:
					_show_cmd_error("Unknown player: %s" % pid_token)
					return false
				var on: = _parse_bool_token(flag_token)
				_server_set_infinite_jumping(to_pid, on)
			else:
				rpc_id(1, "srv_dev_set_infinitejumping", pw, pid_token, flag_token)
			return true
		"maxfall":

			if parts.size() != 4:
				_show_cmd_error("Usage: /<pw> maxfall <player_id> <blocks>")
				return false

			var pid_token: = parts[2]
			var blocks_tok: = parts[3]

			if multiplayer.is_server():
				var to_pid: = _resolve_target_pid(pid_token)
				if to_pid == -1:
					_show_cmd_error("Unknown player: %s" % pid_token)
					return false
				var blocks: = _parse_int_clamped(blocks_tok, 0, 999)
				_server_set_max_fall(to_pid, blocks)
			else:
				rpc_id(1, "srv_dev_set_maxfall", pw, pid_token, blocks_tok)
			return true
		"cameramag":

			if parts.size() != 4:
				_show_cmd_error("Usage: /<pw> cameramag <player_id> <zoom>")
				return false

			var pid_token: = parts[2]
			var zoom_tok: = parts[3]

			if multiplayer.is_server():
				var to_pid: = _resolve_target_pid(pid_token)
				if to_pid == -1:
					_show_cmd_error("Unknown player: %s" % pid_token)
					return false
				var zoom: = _parse_float_clamped(zoom_tok, 0.1, 5.0)
				_server_set_camera_zoom(to_pid, zoom)
			else:
				rpc_id(1, "srv_dev_set_camerazoom", pw, pid_token, zoom_tok)
			return true
		"build":


			if parts.size() < 6:
				_show_cmd_error("Usage: /<pw> build <item_id> <w> <h> <x> <y>  OR  /<pw> build <item_id> <w> <h> at <player_id>")
				return false

			var item_id: = int(parts[2])
			var w: = int(parts[3])
			var h: = int(parts[4])


			if parts.size() == 7 and parts[5].to_lower() == "at":
				var pid_token: = parts[6]
				if multiplayer.is_server():
					var pid: = _resolve_target_pid(pid_token)
					if pid == -1:
						_show_cmd_error("Unknown player: %s" % pid_token)
						return false
					_server_dev_build_at(item_id, w, h, pid)
				else:
					rpc_id(1, "srv_dev_build_at", pw, item_id, w, h, pid_token)
				return true


			if parts.size() == 7:
				var x: = int(parts[5])
				var y: = int(parts[6])
				if multiplayer.is_server():
					_server_dev_build_rect(item_id, w, h, Vector2(x, y))
				else:
					rpc_id(1, "srv_dev_build_coords", pw, item_id, w, h, x, y)
				return true

			_show_cmd_error("Usage: /<pw> build <item_id> <w> <h> <x> <y>  OR  /<pw> build <item_id> <w> <h> at <player_id>")
			return false
		"cpos":

			if parts.size() != 3:
				_show_cmd_error("Usage: /<pw> cpos <player_id>")
				return false

			var pid_token: = parts[2]

			if multiplayer.is_server():
				var to_pid: = _resolve_target_pid(pid_token)
				if to_pid == -1 or not players.has(to_pid):
					_show_cmd_error("Unknown or missing player: %s" % pid_token)
					return false
				var pos: Vector2 = players[to_pid].global_position
				print("Player %s position: %s" % [pid_token, str(pos)])
				_show_cmd_info("Player %s is at (%.1f, %.1f)" % [str(to_pid), pos.x, pos.y])
			else:

				rpc_id(1, "srv_dev_get_cpos", pw, pid_token)
			return true
		"spectate":
			if parts.size() != 3:
				_show_cmd_error("Usage: /<pw> spectate <player_id>")
				return false

			var pid_token: = parts[2]
			var target_pid: = _resolve_target_pid(pid_token)
			if target_pid == -1:
				_show_cmd_error("Unknown player: %s" % pid_token)
				return false


			if not players.has(target_pid) or not is_instance_valid(players[target_pid]):
				_show_cmd_error("Player %s isn't spawned on this client." % str(target_pid))
				return false

			_start_spectate(target_pid)

			if multiplayer.is_server():
				_spectate_target_of[multiplayer.get_unique_id()] = target_pid
			else:
				rpc_id(1, "srv_set_spectate", target_pid)
			return true


		"unspectate":
			_stop_spectate()
			if multiplayer.is_server():
				_spectate_target_of.erase(multiplayer.get_unique_id())
			else:
				rpc_id(1, "srv_clear_spectate")
			return true
		_:
			_show_cmd_error("Unknown command: %s" % cmd)
			return false

func _show_cmd_error(msg: String) -> void :

	if _cmd_box:
		_cmd_box.placeholder_text = msg

func _show_cmd_info(msg: String) -> void :

	if _cmd_box:
		_cmd_box.placeholder_text = msg



const CHAT_MAX_LEN: = 180
var _chat_log: RichTextLabel = null
var _chat_lines: Array[Dictionary] = []
const CHAT_MAX_LINES: = 6
const CHAT_MAX_RENDER_LINES: = 6


const CHAT_FADE_DELAY: = 3.0
const CHAT_FADE_TIME: = 2.0



const CHAT_FILTER_BLOCK_URLS: = true
const CHAT_FILTER_SAFE_CHARS_ONLY: = false

const CHAT_SPAM_MIN_INTERVAL: = 0.8
const CHAT_SPAM_MAX_BURST: = 3
const CHAT_SPAM_BURST_WINDOW: = 4.0


const CHAT_BANNED_WORDS: = [
	"fuck", "shit", "bitch", "cunt", "nigger", "faggot", "asshole", "ass", "nigga", "dick", "cock", "pussy", "vagina", "vibrator", "sex", "rape", "cum", \
	"testicle", "tit", "boob", "breast", "retard", "arse", "arsehole", "slut", "wanker", "whore", "kike", "paki", "prick", "penis", "erection", "erectile", \
	"piss", "twat", "bastard", "blowjob", "handjob", "footjob", "feetjob", "fetish", "pedo", "pedophile", "zoophile", "cunt", "pajeet", "suicide", "epstein", \
	"groom", "kink", "sexual", "cumming", "jerk", "jerking", "goon", "gooning", "maturbate", "masturbating", "masturbation", "porn", "pornography", "onlyfan", \
	"ballsack", "sperm", "kneeger", "kneega", "orgasm", "orgy", "ejaculate", "ejaculation", "ejaculating", "foreskin", "bollock", "boner", "dildo", "dumbass", \
	"gay", "lesbian", "jackass", "jizz", "negro", "clit", "nutsack", "strip", "stripping", "stripper", "tranny", "upskirt", "vulva", "boobs", "breasts", 
]

const CHAT_PROFANITY_MAX_STRIKES: = 2
const CHAT_MUTE_SECONDS: = 300.0

var _chat_profanity_strikes: Dictionary = {}
var _chat_muted_until: Dictionary = {}


var _chat_rate: Dictionary = {}

func _on_chat_btn_pressed() -> void :
	if _cmd_box.visible == false or _cmd_box == null:
		open_command_box(false)
		get_viewport().set_input_as_handled()
	else:
		close_command_box()
		get_viewport().set_input_as_handled()

func _ensure_chat_log() -> void :
	if _chat_log and is_instance_valid(_chat_log):
		return

	var ui_root: = $CanvasLayer if has_node("CanvasLayer") else null
	if ui_root == null:
		ui_root = CanvasLayer.new()
		ui_root.name = "CanvasLayer"
		add_child(ui_root)

	_chat_log = RichTextLabel.new()
	_chat_log.name = "ChatLog"


	_chat_log.bbcode_enabled = true
	_chat_log.scroll_active = false
	_chat_log.fit_content = true
	_chat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE


	if CMD_FONT != null:
		_chat_log.add_theme_font_override("normal_font", CMD_FONT)
		_chat_log.add_theme_font_size_override("normal_font_size", CMD_FONT_SIZE)


	_chat_log.anchor_left = 0.65
	_chat_log.anchor_right = 0.98
	_chat_log.anchor_top = 0.35
	_chat_log.anchor_bottom = 0.65
	_chat_log.offset_left = 0
	_chat_log.offset_right = 0
	_chat_log.offset_top = 0
	_chat_log.offset_bottom = 0


	_chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chat_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	ui_root.add_child(_chat_log)

func _chat_name_for(pid: int) -> String:

	if player_numbers.has(pid):
		return "#%d" % int(player_numbers[pid])
	return str(pid)

func _append_chat_line(line: String) -> void :
	_ensure_chat_log()
	_chat_lines.append({"t": Time.get_ticks_msec() / 1000.0, "text": line})

	if _chat_lines.size() > CHAT_MAX_LINES:
		_chat_lines = _chat_lines.slice(_chat_lines.size() - CHAT_MAX_LINES, _chat_lines.size())

	_rebuild_chat_rich_text()

func _alpha_for_chat_line(age: float) -> float:

	if age <= CHAT_FADE_DELAY:
		return 1.0
	var x: = (age - CHAT_FADE_DELAY) / CHAT_FADE_TIME
	return clamp(1.0 - x, 0.0, 1.0)

func _rebuild_chat_rich_text() -> void :
	if _chat_log == null:
		return

	var now: = Time.get_ticks_msec() / 1000.0


	var visible_entries: Array[Dictionary] = []
	for e in _chat_lines:
		var age: = now - float(e["t"])
		var a: = _alpha_for_chat_line(age)
		if a > 0.0:
			visible_entries.append(e)

	_chat_lines = visible_entries


	while true:
		var bb: = ""
		for e in _chat_lines:
			var age: = now - float(e["t"])
			var a: = _alpha_for_chat_line(age)
			var aa: = int(round(a * 255.0))
			var color: = "#FFFFFF%02X" % aa
			bb += "[color=%s]%s[/color]\n" % [color, String(e["text"])]

		_chat_log.text = bb.strip_edges()


		if _chat_log.get_line_count() <= CHAT_MAX_RENDER_LINES:
			break


		if _chat_lines.size() > 0:
			_chat_lines.remove_at(0)
		else:
			break

func _send_chat(msg: String) -> void :
	if is_local_muted():
		var remaining = _local_mute_until - _chat_now_s()
		cli_chat_system("You are muted for %.0f more seconds." % max(0.0, remaining))
		return
	msg = msg.strip_edges()
	if msg == "":
		return


	if multiplayer.is_server():
		srv_chat_send(msg)
	else:
		rpc_id(1, "srv_chat_send", msg)

func _chat_now_s() -> float:
	return float(Time.get_unix_time_from_system())

func _strip_to_safe_chars(s: String) -> String:


	var out: = ""
	for i in s.length():
		var ch: = s[i]

		var code: = ch.unicode_at(0)
		if code >= 32 and code <= 126:
			out += ch

	out = out.strip_edges()
	while out.find("  ") != -1:
		out = out.replace("  ", " ")
	return out

func _collapse_repeated_chars(s: String, max_run: int = 1) -> String:

	if s.length() <= 1:
		return s

	var out: = ""
	var last: = ""
	var run: = 0

	for i in range(s.length()):
		var ch: = s.substr(i, 1)
		if ch == last:
			run += 1
			if run <= max_run:
				out += ch
		else:
			last = ch
			run = 1
			out += ch

	return out

func _contains_url_like(s: String) -> bool:
	var lower: = s.to_lower()
	return (
		lower.find("http://") != -1 or 
		lower.find("https://") != -1 or 
		lower.find("www.") != -1 or 
		lower.find(".com") != -1 or 
		lower.find(".net") != -1 or 
		lower.find(".gg") != -1 or 
		lower.find(".io") != -1
	)

func _censor_profanity(s: String) -> String:
	var out: = s
	for w in CHAT_BANNED_WORDS:
		var re: = RegEx.new()

		re.compile("(?i)\\b" + w + "\\b")
		out = re.sub(out, "", true)
	return out

func _is_pid_muted(pid: int) -> bool:
	if not _chat_muted_until.has(pid):
		return false
	var until: = float(_chat_muted_until[pid])
	var now: = _chat_now_s()
	if now < until:
		return true
	_chat_muted_until.erase(pid)
	save_local_mute()
	return false

const LOCAL_MUTE_SAVE: = "user://timer.json"
var _local_mute_until: = 0.0

func load_local_mute():
	if FileAccess.file_exists(LOCAL_MUTE_SAVE):
		var f = FileAccess.open(LOCAL_MUTE_SAVE, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(d) == TYPE_DICTIONARY:
			_local_mute_until = float(d.get("until", 0.0))

func save_local_mute():
	var f = FileAccess.open(LOCAL_MUTE_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"until": _local_mute_until}))
	f.close()

func is_local_muted() -> bool:
	return _chat_now_s() < _local_mute_until

func set_local_mute(seconds: float):
	_local_mute_until = _chat_now_s() + seconds
	save_local_mute()

func _mute_pid(pid: int, seconds: float) -> void :
	_chat_muted_until[pid] = _chat_now_s() + seconds
	save_local_mute()

func _increment_profanity_strike(pid: int) -> int:
	var s: = int(_chat_profanity_strikes.get(pid, 0)) + 1
	_chat_profanity_strikes[pid] = s
	return s


const CHAT_PROFANITY_SUFFIX_ALLOW: = 2

func _normalize_leetspeak(s: String) -> String:
	var t: = s.to_lower()



	t = t.replace("ph", "f")
	t = t.replace("vv", "w")
	t = t.replace("|<", "k")
	t = t.replace("()", "o")
	t = t.replace("[]", "o")
	t = t.replace("{}", "o")


	var map: = {
		"0": "o", 
		"1": "i", 
		"!": "i", 
		"|": "i", 
		"3": "e", 
		"4": "a", 
		"@": "a", 
		"5": "s", 
		"$": "s", 
		"7": "t", 
		"+": "t", 
		"8": "b", 
		"9": "g", 
		"2": "z"
	}

	var out: = ""
	for i in range(t.length()):
		var ch: = t.substr(i, 1)


		var code: = ch.unicode_at(0)
		var is_letter: = (code >= 97 and code <= 122)
		var is_digit: = (code >= 48 and code <= 57)

		if map.has(ch):
			out += String(map[ch])
		elif is_letter or is_digit:
			out += ch



	out = _collapse_repeated_chars(out, 2)

	return out

func _normalize_chat_token(tok: String) -> String:
	var n: = _normalize_leetspeak(tok)


	n = _collapse_repeated_chars(n, 1)

	return n

func _contains_profanity(msg: String) -> bool:
	var text: = msg.strip_edges()
	if text == "":
		return false


	var tokens: = text.split(" ", false)

	for raw_tok in tokens:
		var tok: = _normalize_chat_token(raw_tok)
		if tok == "":
			continue

		for w in CHAT_BANNED_WORDS:
			var banned: = String(w).strip_edges().to_lower()
			if banned == "":
				continue


			banned = _normalize_chat_token(banned)
			if banned == "":
				continue


			if banned.length() <= 3:
				if tok == banned:
					return true
				continue


			if tok == banned:
				return true
			if tok.begins_with(banned) and tok.length() <= banned.length() + CHAT_PROFANITY_SUFFIX_ALLOW:
				return true

	var whole: = _normalize_chat_token(text)
	for w in CHAT_BANNED_WORDS:
		var banned: = _normalize_chat_token(String(w))
		if banned == "" or banned.length() <= 3:
			continue
		if whole.find(banned) != -1:
			return true

	return false

func _rate_limit_allows(pid: int) -> bool:
	var now: = _chat_now_s()

	if not _chat_rate.has(pid):
		_chat_rate[pid] = {"last_t": 0.0, "burst": 0, "window_t": now}
	var st: Dictionary = _chat_rate[pid]


	if now - float(st["window_t"]) > CHAT_SPAM_BURST_WINDOW:
		st["window_t"] = now
		st["burst"] = 0


	if int(st["burst"]) >= CHAT_SPAM_MAX_BURST and (now - float(st["last_t"])) < CHAT_SPAM_MIN_INTERVAL:
		_chat_rate[pid] = st
		return false


	if (now - float(st["last_t"])) < CHAT_SPAM_MIN_INTERVAL:

		st["burst"] = int(st["burst"]) + 1
		st["last_t"] = now
		_chat_rate[pid] = st
		return true

	st["burst"] = 0
	st["last_t"] = now
	_chat_rate[pid] = st
	return true

func _filter_chat_message(msg: String) -> Dictionary:

	var m: = msg.strip_edges()
	if m == "":
		return {"ok": false, "msg": "", "reason": "empty"}


	if m.length() > CHAT_MAX_LEN:
		m = m.substr(0, CHAT_MAX_LEN)


	while m.find("  ") != -1:
		m = m.replace("  ", " ")


	m = _collapse_repeated_chars(m, 4)

	if CHAT_FILTER_SAFE_CHARS_ONLY:
		m = _strip_to_safe_chars(m)
		if m == "":
			return {"ok": false, "msg": "", "reason": "empty"}

	if CHAT_FILTER_BLOCK_URLS and _contains_url_like(m):
		return {"ok": false, "msg": "", "reason": "links_not_allowed"}




	return {"ok": true, "msg": m, "reason": ""}

@rpc("any_peer", "reliable")
func srv_chat_send(msg: String) -> void :
	if not multiplayer.is_server():
		return

	var from_pid: = multiplayer.get_remote_sender_id()
	if from_pid == 0:
		from_pid = multiplayer.get_unique_id()


	if _is_pid_muted(from_pid):
		var remaining: = float(_chat_muted_until[from_pid]) - _chat_now_s()
		rpc_id(from_pid, "cli_chat_system", "You are muted for %.0f more seconds." % max(0.0, remaining))
		return


	if not _rate_limit_allows(from_pid):
		rpc_id(from_pid, "cli_chat_system", "You're sending messages too fast.")
		return


	msg = msg.strip_edges()
	if msg == "":
		return
	if msg.length() > CHAT_MAX_LEN:
		msg = msg.substr(0, CHAT_MAX_LEN)


	if _contains_profanity(msg):
		var strikes: = _increment_profanity_strike(from_pid)

		if strikes >= CHAT_PROFANITY_MAX_STRIKES:

			rpc_id(from_pid, "cli_chat_system", "You have been muted for %.0f seconds." % CHAT_MUTE_SECONDS)
			set_local_mute(CHAT_MUTE_SECONDS)
		else:
			rpc_id(from_pid, "cli_chat_system", "Inappropriate messages are not allowed. Strike %d/%d." % [strikes, CHAT_PROFANITY_MAX_STRIKES])


		return


	var res: Dictionary = _filter_chat_message(msg)
	if not bool(res["ok"]):
		var reason: = String(res["reason"])
		if reason == "links_not_allowed":
			rpc_id(from_pid, "cli_chat_system", "Links are not allowed.")
		return

	var cleaned: = String(res["msg"])
	_server_broadcast_chat(from_pid, cleaned)

@rpc("any_peer", "call_local", "reliable")
func cli_chat_system(msg: String) -> void :
	_append_chat_line("[SYSTEM] " + msg)

func _server_broadcast_chat(from_pid: int, msg: String) -> void :

	var from_num: = -1
	if player_numbers.has(from_pid):
		from_num = int(player_numbers[from_pid])
	else:

		from_num = from_pid

	rpc("cli_chat_recv", from_pid, from_num, msg)

@rpc("any_peer", "call_local", "reliable")
func cli_chat_recv(from_pid: int, from_player_number: int, msg: String) -> void :
	var line: = "#%d: %s" % [from_player_number, msg]
	_append_chat_line(line)
	_spawn_chat_bubble(from_pid, msg)

const CHAT_BUBBLE_SCENE: = preload("res://ChatBubble.tscn")

func _spawn_chat_bubble(pid: int, msg: String) -> void :
	var p = players.get(pid, null)
	if p == null or not is_instance_valid(p):
		return


	var stack: = 0
	for c in p.get_children():
		if c.is_in_group("chat_bubble"):
			stack += 1

	var b: = CHAT_BUBBLE_SCENE.instantiate()
	p.add_child(b)
	b.play(msg, stack)



var _is_spectating: bool = false
var _spectate_target_pid: int = -1
var _spectate_cam: Camera2D = null


var _ui_vis_backup: Dictionary = {}

const SPECTATE_SMOOTH_PX_PER_SEC: = 1.0

var _spectate_target_of: = {}

@rpc("any_peer", "reliable")
func srv_set_spectate(target_pid: int) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()

	if not players.has(target_pid) or not is_instance_valid(players[target_pid]):
		return

	_spectate_target_of[pid] = target_pid


@rpc("any_peer", "reliable")
func srv_clear_spectate() -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()

	_spectate_target_of.erase(pid)

func _set_hud_visible(visible: bool) -> void :

	var ui_root: = $CanvasLayer if has_node("CanvasLayer") else null
	if ui_root == null:
		return

	for child in ui_root.get_children():
		if child == null: continue
		if child.name == "CommandBox":
			continue


		var key: = str(child.get_path())
		if not _ui_vis_backup.has(key):
			_ui_vis_backup[key] = child.visible

		child.visible = visible

func _restore_hud_visibility() -> void :
	if _ui_vis_backup.is_empty():
		return
	for key in _ui_vis_backup.keys():
		var np: = NodePath(String(key))
		var n: = get_node_or_null(np)
		if n:
			n.visible = bool(_ui_vis_backup[key])
	_ui_vis_backup.clear()

func _start_spectate(target_pid: int) -> void :
	if not players.has(target_pid) or not is_instance_valid(players[target_pid]):
		_show_cmd_error("Spectate failed: player_id %s not found." % str(target_pid))
		return

	_is_spectating = true
	_spectate_target_pid = target_pid


	_set_hud_visible(false)
	_set_local_input_locked(true)


	var me = players.get(multiplayer.get_unique_id(), null)
	if me and is_instance_valid(me):
		var me_cam = me.get_node_or_null("Camera2D")
		if me_cam:
			me_cam.enabled = false


	if _spectate_cam == null or not is_instance_valid(_spectate_cam):
		_spectate_cam = Camera2D.new()
		_spectate_cam.name = "SpectateCamera2D"
		add_child(_spectate_cam)


	_spectate_cam.enabled = true
	_spectate_cam.position_smoothing_enabled = true
	_spectate_cam.position_smoothing_speed = SPECTATE_SMOOTH_PX_PER_SEC


	_spectate_cam.global_position = (players[target_pid] as Node2D).global_position
	_spectate_cam.make_current()

func _stop_spectate() -> void :
	if not _is_spectating:
		return

	_is_spectating = false
	_spectate_target_pid = -1


	if _spectate_cam and is_instance_valid(_spectate_cam):
		_spectate_cam.queue_free()
	_spectate_cam = null


	var me = players.get(multiplayer.get_unique_id(), null)
	if me and is_instance_valid(me):
		var me_cam = me.get_node_or_null("Camera2D")
		if me_cam:
			me_cam.enabled = true
			me_cam.make_current()


	_restore_hud_visibility()
	_set_local_input_locked(false)

@rpc("authority")
func srv_dev_get_cpos(pw: String, pid_token: String) -> void :
	if pw != DEV_PASSWORD:
		return
	var to_pid: = _resolve_target_pid(pid_token)
	if to_pid == -1 or not players.has(to_pid):
		return
	var player_node = players[to_pid]
	var pos = player_node.global_position
	print("Player %s position: %s" % [pid_token, str(pos)])


func _parse_float_clamped(s: String, lo: float, hi: float) -> float:
	var v: = 1.0
	if s.is_valid_float():
		v = float(s)
	elif s.is_valid_int():
		v = float(int(s))
	return clamp(v, lo, hi)

func _parse_bool_token(t: String) -> bool:
	var s: = t.strip_edges().to_lower()
	return s == "1" or s == "true" or s == "on" or s == "yes" or s == "y"

func _parse_int_clamped(s: String, lo: int, hi: int) -> int:
	if s.is_valid_int():
		return clamp(int(s), lo, hi)
	return lo

@rpc("any_peer")
func srv_dev_build_coords(pw: String, item_id: int, w: int, h: int, x: int, y: int) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	_server_dev_build_rect(item_id, w, h, Vector2(x, y))

@rpc("any_peer")
func srv_dev_build_at(pw: String, item_id: int, w: int, h: int, pid_token: String) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	var pid: = _resolve_target_pid(pid_token)
	if pid == -1: return
	_server_dev_build_at(item_id, w, h, pid)

func _server_dev_build_at(item_id: int, w: int, h: int, target_pid: int) -> void :
	if not players.has(target_pid) or not is_instance_valid(players[target_pid]):
		return
	var tl: = ground
	if tl == null:
		return

	var p: Node2D = players[target_pid]
	var anchor: = tl.local_to_map(tl.to_local(p.global_position))


	anchor.y -= (h - 1)

	_server_dev_build_rect_from_cell(item_id, w, h, anchor)

func _server_dev_build_rect(item_id: int, w: int, h: int, origin_world: Vector2) -> void :
	var tl: = ground
	if tl == null: return

	var anchor: = tl.local_to_map(tl.to_local(origin_world))

	for dy in range(h):
		for dx in range(w):
			var cell: = anchor + Vector2i(dx, dy)
			var ac: = item_id_to_atlas(item_id, cell.x, cell.y)
			if ac == Vector2i(-1, -1):
				continue
			tl.set_cell(cell, SRC, ac)
			cell_overrides[cell] = ac
			removed_cells.erase(cell)
			rpc("cli_set_cell", cell, SRC, ac)


func _server_dev_build_rect_from_cell(item_id: int, w: int, h: int, anchor: Vector2i) -> void :
	var tl: = ground
	if tl == null: return

	for dy in range(h):
		for dx in range(w):
			var cell: = anchor + Vector2i(dx, dy)
			var ac: = item_id_to_atlas(item_id, cell.x, cell.y)
			if ac == Vector2i(-1, -1):
				continue
			tl.set_cell(cell, SRC, ac)
			if typeof(cell_overrides) != TYPE_NIL:
				cell_overrides[cell] = ac
			if typeof(removed_cells) != TYPE_NIL:
				removed_cells.erase(cell)
			if has_method("cli_set_cell"):
				rpc("cli_set_cell", cell, SRC, ac)

@rpc("any_peer")
func srv_dev_set_camerazoom(pw: String, pid_token: String, zoom_tok: String) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	var to_pid: = _resolve_target_pid(pid_token)
	if to_pid == -1: return
	var zoom: = _parse_float_clamped(zoom_tok, 0.1, 5.0)
	_server_set_camera_zoom(to_pid, zoom)

func _server_set_camera_zoom(target_pid: int, zoom: float) -> void :
	if not players.has(target_pid) or not is_instance_valid(players[target_pid]):
		return
	var p: Node = players[target_pid]


	if p.cam and is_instance_valid(p.cam):
		p.cam.zoom = Vector2(zoom, zoom)


	p.rpc_id(target_pid, "cli_set_camera_zoom", zoom)

@rpc("any_peer")
func srv_dev_set_maxfall(pw: String, pid_token: String, blocks_tok: String) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	var to_pid: = _resolve_target_pid(pid_token)
	if to_pid == -1: return
	var blocks: = _parse_int_clamped(blocks_tok, 0, 999)
	_server_set_max_fall(to_pid, blocks)

func _server_set_max_fall(target_pid: int, blocks: int) -> void :
	if not players.has(target_pid) or not is_instance_valid(players[target_pid]): return
	var p: Node = players[target_pid]


	p.MAXIMUM_BLOCK_FALL = blocks


	p.rpc_id(target_pid, "cli_set_max_fall", blocks)

@rpc("any_peer")
func srv_dev_set_infinitejumping(pw: String, pid_token: String, flag_token: String) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	var to_pid: = _resolve_target_pid(pid_token)
	if to_pid == -1: return
	_server_set_infinite_jumping(to_pid, _parse_bool_token(flag_token))

func _server_set_infinite_jumping(target_pid: int, on: bool) -> void :
	if not players.has(target_pid) or not is_instance_valid(players[target_pid]):
		return
	var p: Node = players[target_pid]


	p.allow_infinite_jump = on


	p.rpc_id(target_pid, "cli_set_infinite_jumping", on)


@rpc("any_peer")
func srv_dev_give(pw: String, to_pid: int, item_id: int, count: int) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	_server_dev_give(to_pid, item_id, count)

func _server_dev_give(to_pid: int, item_id: int, count: int) -> void :

	if not players.has(to_pid) or not is_instance_valid(players[to_pid]):
		return

	rpc_id(to_pid, "cli_give_item", item_id, count)

@rpc("any_peer")
func srv_dev_tp_coords(pw: String, target_pid_token: String, x: int, y: int) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	var target_pid: = _resolve_target_pid(target_pid_token)
	if target_pid == -1: return
	_server_dev_tp_coords(target_pid, Vector2(x, y))

@rpc("any_peer")
func srv_dev_tp_token(pw: String, keyword: String, pid_token: String) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	if keyword.to_lower() != "at": return
	var target_pid: = _resolve_target_pid(pid_token)
	if target_pid == -1: return
	_server_dev_tp(multiplayer.get_remote_sender_id(), target_pid)

@rpc("any_peer")
func srv_dev_tp_to_player(pw: String, target_pid_token: String, dest_pid_token: String) -> void :
	if not multiplayer.is_server(): return
	if pw != DEV_PASSWORD: return
	var target_pid: = _resolve_target_pid(target_pid_token)
	var dest_pid: = _resolve_target_pid(dest_pid_token)
	if target_pid == -1 or dest_pid == -1: return
	_server_dev_tp_to_player(target_pid, dest_pid)

func _server_dev_tp(source_pid: int, target_pid: int) -> void :
	if not players.has(source_pid) or not players.has(target_pid): return
	var target: Node2D = players[target_pid]
	if target and is_instance_valid(target):
		_server_dev_tp_coords(source_pid, target.global_position)

func _server_dev_tp_coords(target_pid: int, pos: Vector2) -> void :
	if not players.has(target_pid): return
	var p: Node2D = players[target_pid]
	if p and is_instance_valid(p):
		p.global_position = pos
		rpc("rpc_force_position", target_pid, pos)

func _server_dev_tp_to_player(target_pid: int, dest_pid: int) -> void :
	if not players.has(target_pid) or not players.has(dest_pid): return
	var dest: Node2D = players[dest_pid]
	if dest and is_instance_valid(dest):
		_server_dev_tp_coords(target_pid, dest.global_position)


@rpc("authority")
func rpc_force_position(pid: int, pos: Vector2) -> void :
	if players.has(pid):
		var p: Node2D = players[pid]
		if p: p.global_position = pos

const EVIL_LEAFY = preload("res://evil_leafy.tscn")

const EVIL_LEAFY_OFFSET_MIN: = 2
const EVIL_LEAFY_OFFSET_MAX: = 6

var _evil_leafy_id: = 0
var _evil_leafy_cc: Vector2i = Vector2i(999999, 0)
var _evil_leafy_loaded: = false
var _evil_leafy_home_cc_cached: = false

const EVIL_LEAFY_SCENE: PackedScene = EVIL_LEAFY

@export var EVIL_RESPAWN_COOLDOWN: = 1.0

var _evil_leafy_ref: Node = null
var _evil_leafy_defeated: = false
var _evil_leafy_respawn_at: = 0.0

@export var MAX_RIGHT_CHUNKS: int = 1
var _gate_spawned: = false


@export var EVIL_CHUNK_STEP_X: = 1024.0
@export var EVIL_SURFCAST_TOP: = -8000.0
@export var EVIL_SURFCAST_BOT: = 8000.0


const SAND_START_SPEED_CPS: = 0.1
const SAND_GRAVITY_CPS: = 0.3
const SAND_MAX_SPEED_CPS: = 3.0
const SAND_MAX_STEPS_PER_TICK: = 6

var _sand_vel: Dictionary = {}
var _sand_prog: Dictionary = {}

func _land_sand_at(c: Vector2i) -> void :

	_sand_vel.erase(c)
	_sand_prog.erase(c)

func _consume_one_from_selected() -> void :
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar and hotbar.has_method("consume_selected"):
		hotbar.call("consume_selected", 1)

var _aou_timer: Timer

@rpc("any_peer", "call_local")
func rpc_play_aou_animation_local(restart: = true, duration: = 1.71) -> void :
	if ao_u == null or not is_instance_valid(ao_u):
		return


	if restart and _aou_timer and is_instance_valid(_aou_timer):
		_aou_timer.stop()
		_aou_timer.queue_free()
		_aou_timer = null


	ao_u.visible = true
	if ao_u.has_method("stop"):
		ao_u.stop()
	ao_u.play()


	_aou_timer = Timer.new()
	_aou_timer.one_shot = true
	_aou_timer.wait_time = duration
	add_child(_aou_timer)
	_aou_timer.timeout.connect( func():
		if ao_u and is_instance_valid(ao_u):
			ao_u.visible = false
		if _aou_timer:
			_aou_timer.queue_free()
			_aou_timer = null
	)
	_aou_timer.start()

func is_aou_anim_active() -> bool:
	if ao_u == null or not is_instance_valid(ao_u):
		return false
	var playing: = false
	if ao_u.has_method("is_playing"):
		playing = ao_u.is_playing()

	return ao_u.visible and playing



func _server_now() -> float:
	return Time.get_ticks_msec() * 0.001

func _spawn_evil_leafy_at(feet_wp: Vector2) -> void :
	if not multiplayer.is_server(): return
	if _evil_leafy_ref and is_instance_valid(_evil_leafy_ref): return

	var e: = EVIL_LEAFY_SCENE.instantiate()
	e.name = "EvilLeafy"
	add_child(e)
	e.set_multiplayer_authority(multiplayer.get_unique_id(), true)
	e.call_deferred("spawn_at_feet", feet_wp)
	_evil_leafy_ref = e


	if not e.is_connected("tree_exiting", Callable(self, "_on_evil_leafy_despawned")):
		e.connect("tree_exiting", Callable(self, "_on_evil_leafy_despawned"))

func loaded_evil_chunk_count() -> int:

	var seen: = {}
	for p in get_tree().get_nodes_in_group("player"):
		if not p or not is_instance_valid(p):
			continue
		var base_cc: Vector2i = _chunk_of_world_pos(p.global_position)
		for dx in range(-4, 5):
			var cc: = Vector2i(base_cc.x + dx, 0)
			if _biome_for_chunk(cc) == BIOME_EVIL_FOREST and (_is_chunk_loaded(cc) or _loaded_count_peers(cc) > 0):
				seen[cc] = true
	return seen.size()


var _evil_mgr_timer: Timer

func _ensure_evil_mgr_timer() -> void :
	if _evil_mgr_timer and is_instance_valid(_evil_mgr_timer):
		return
	_evil_mgr_timer = Timer.new()
	_evil_mgr_timer.name = "EvilMgrTimer"
	_evil_mgr_timer.wait_time = 0.5
	_evil_mgr_timer.one_shot = false
	_evil_mgr_timer.autostart = true
	add_child(_evil_mgr_timer)
	_evil_mgr_timer.timeout.connect(_reconcile_evil_leafy)

func _reconcile_evil_leafy() -> void :
	if multiplayer and not multiplayer.is_server(): return
	if _evil_leafy_ref and is_instance_valid(_evil_leafy_ref): return
	if _evil_leafy_defeated: return
	if _server_now() < _evil_leafy_respawn_at: return
	if not any_evil_chunk_loaded(): return

	var spot = random_surface_spot_in_loaded_evil_near_x(0.0)
	if spot == null: return


	var e: = EVIL_LEAFY_SCENE.instantiate()
	e.name = "EvilLeafy"
	add_child(e)
	e.call_deferred("spawn_at_feet", spot)
	_evil_leafy_ref = e
	_evil_leafy_respawn_at = 0.0


	rpc("rpc_spawn_evil_leafy", spot)


	if not e.is_connected("tree_exiting", Callable(self, "_on_evil_leafy_despawned")):
		e.connect("tree_exiting", Callable(self, "_on_evil_leafy_despawned"))


var _srv_loaded_chunks: Dictionary = {}
var _srv_loaded_evil: Dictionary = {}

func _mark_chunk_loaded(cc: Vector2i) -> void :
	_srv_loaded_chunks[cc] = true
	if is_evil_chunk(cc):
		_srv_loaded_evil[cc] = true

func _mark_chunk_unloaded(cc: Vector2i) -> void :
	_srv_loaded_chunks.erase(cc)
	_srv_loaded_evil.erase(cc)

func any_evil_chunk_loaded() -> bool:
	if not has_method("_required_chunks_for_all_players"):
		return false
	for c in _required_chunks_for_all_players(ACTIVE_RADIUS_CHUNKS):
		if is_evil_chunk(c):
			return true
	return false


func random_surface_spot_in_loaded_evil_near_x(pref_x: float) -> Variant:
	var anchors: Array[float] = []


	for p in get_tree().get_nodes_in_group("player"):
		if p and is_instance_valid(p):
			var cc: = _chunk_of_world_pos(p.global_position)
			if _biome_for_chunk(cc) == BIOME_EVIL_FOREST and (_is_chunk_loaded(cc) or _loaded_count_peers(cc) > 0):
				anchors.append(p.global_position.x)

	if anchors.is_empty():
		anchors.append(pref_x)

	for ax in anchors:
		var base_cc: = _chunk_of_world_pos(Vector2(ax, 0.0))
		for step in range(0, 9):
			for dir in [-1, 1]:
				var cc: = Vector2i(base_cc.x + dir * step, 0)
				if _biome_for_chunk(cc) != BIOME_EVIL_FOREST:
					continue
				if not (_is_chunk_loaded(cc) or _loaded_count_peers(cc) > 0):
					continue


				var x0: = cc.x * CHUNK_SIZE
				var sx: = x0 + CHUNK_SIZE / 2
				var surf: Dictionary = _surface_y_map_for_chunk(cc)
				var y_surface: = int(surf.get(sx, BASE_SURFACE_Y))
				var stand_cell: = Vector2i(sx, y_surface - 1)
				return ground.to_global(ground.map_to_local(stand_cell))
	return null




func _world_x_center_of_chunk(cc: Vector2i) -> float:
	var x0: = cc.x * CHUNK_SIZE
	var center_cell: = Vector2i(x0 + CHUNK_SIZE / 2, 0)
	var wp: = ground.to_global(ground.map_to_local(center_cell))
	return wp.x


func nearest_loaded_evil_center_from_cx(cx: int) -> float:
	for radius in range(0, 64):
		var left_cc: = Vector2i(cx - radius, 0)
		if _biome_for_chunk(left_cc) == BIOME_EVIL_FOREST and (_is_chunk_loaded(left_cc) or _loaded_count_peers(left_cc) > 0):
			return _world_x_center_of_chunk(left_cc)
		var right_cc: = Vector2i(cx + radius, 0)
		if _biome_for_chunk(right_cc) == BIOME_EVIL_FOREST and (_is_chunk_loaded(right_cc) or _loaded_count_peers(right_cc) > 0):
			return _world_x_center_of_chunk(right_cc)
	return NAN


func _world_pos_at_surface_cell(x_cell: int, y_surface: int) -> Vector2:

	return ground.to_global(ground.map_to_local(Vector2i(x_cell, y_surface - 1)))



func _gate_chunk_cx() -> int:
	return MAX_RIGHT_CHUNKS
func _rightmost_allowed_cx() -> int:
	return MAX_RIGHT_CHUNKS - 1

const GATE = preload("res://gate.tscn")

func _spawn_gate_if_needed() -> void :
	if _gate_spawned:
		return
	_gate_spawned = true

	var gate_cx: = _gate_chunk_cx()
	var x0: = gate_cx * CHUNK_SIZE
	var y: = _get_surface_y_at(x0)
	var wp: = ground.to_global(ground.map_to_local(Vector2i(x0, y)))

	var gate: = GATE.instantiate()
	if gate is Node2D:
		(gate as Node2D).global_position = wp
		(gate as CanvasItem).z_as_relative = false
		(gate as CanvasItem).z_index = -10
	add_child(gate)

func _despawn_chunk_clouds(cc: Vector2i) -> void :
	if chunk_clouds.has(cc):
		for s in chunk_clouds[cc]:
			if s and is_instance_valid(s):
				s.queue_free()
		chunk_clouds.erase(cc)


const PICKAXE_IDS: = [ITEM_WOODEN_PICKAXE, ITEM_STONE_PICKAXE, ITEM_IRON_PICKAXE, ITEM_YOYLITE_PICKAXE]

func _is_pickaxe_item(id: int) -> bool:
	return id in PICKAXE_IDS

func _is_stone_like(ac: Vector2i) -> bool:
	return ac == T_STONE or ac == T_COALSTONE or ac == T_IRONSTONE or T_GOLDSTONE or T_YOYLITESTONE

func _selected_hotbar_item() -> int:
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	return int(hotbar.call("get_selected_item_id")) if hotbar else 0

func _tool_break_bonus_seconds(item_id: int, mat: StringName) -> float:
	if not TOOL_BREAK_BONUS_SEC.has(item_id):
		return 0.0
	var per_mat: Dictionary = TOOL_BREAK_BONUS_SEC[item_id]
	return float(per_mat.get(String(mat), 0.0))

func _selected_item_id() -> int:
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar and hotbar.has_method("get_selected_item_id"):
		return int(hotbar.call("get_selected_item_id"))
	return ITEM_NONE

func _attack_damage_for(pid: int) -> int:
	var dmg: = MELEE_DAMAGE
	var item_id: = int(_equipped_item.get(pid, ITEM_NONE))
	match item_id:
		ITEM_WOODEN_SWORD:
			dmg += WOODEN_SWORD_DAMAGE_BONUS
		ITEM_STONE_SWORD:
			dmg += STONE_SWORD_DAMAGE_BONUS
		ITEM_IRON_SWORD:
			dmg += IRON_SWORD_DAMAGE_BONUS
		ITEM_YOYLITE_SWORD:
			dmg += YOYLITE_SWORD_DAMAGE_BONUS
		_:
			pass
	return dmg

func _break_time_base_for_ac(ac: Vector2i) -> float:
	var mat: = _material_for_ac(ac)


	if mat == &"grass":
		if (ac == T_LEAVES) or (ac == T_DARK_LEAVES) or (ac == T_YOYLE_LEAVES)\
		or (ac == T_BUSH_LEAVES) or (ac == T_BUSH_LEAVES_BERRIES):
			return BREAK_TIME_LEAVES


	match mat:
		&"sand", &"snow", &"grass":
			return BREAK_TIME_SURFACE
		&"gravel":
			return BREAK_TIME_SURFACE
		&"wood":
			return BREAK_TIME_LOG
		&"stone":
			return BREAK_TIME_STONE
		_:
			return BREAK_TIME_FALLBACK

func _selected_hotbar_item_id() -> int:
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	return int(hotbar.call("get_selected_item_id")) if hotbar else ITEM_NONE

func _effective_break_time_for_ac(ac: Vector2i) -> float:
	var t: = _break_time_base_for_ac(ac)
	var mat: = _material_for_ac(ac)
	var tool_id: = _selected_hotbar_item_id()
	var bonus: = _tool_break_bonus_seconds(tool_id, mat)
	return max(BREAK_TIME_MIN, t - bonus)

func _maybe_drop_string_from_bug(bid: int, where: Vector2) -> void :

	if not multiplayer.is_server(): return


	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("bugdrop:", bid, ":", world_seed))

	if rng.randf() <= BUG_STRING_DROP_CHANCE:
		var count: = rng.randi_range(BUG_STRING_DROP_MIN, BUG_STRING_DROP_MAX)
		for i in count:
			var jitter: = Vector2(randf_range(-10, 10), -6)

			_server_spawn_pickup(ITEM_STRING, where + jitter, Vector2i(-1, -1), 0)

func _on_mining_finished() -> void :
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	var cell: = ground.local_to_map(ground.to_local(get_global_mouse_position()))
	if ground.get_cell_source_id(cell) == -1:
		return
	var ac: = ground.get_cell_atlas_coords(cell)
	var mat: = _material_for_ac(ac)
	_play_mining_material_local(mat)


func _play_mining_material_local(mat: StringName) -> void :
	if not is_instance_valid(local_player): return
	var a: AudioStreamPlayer2D = local_player.get_node_or_null("mining")
	if a == null: return
	var bank: = _mine_bank_for_material(mat)
	var s = _pick_rand(bank)
	if s == null: return
	a.stream = s
	a.pitch_scale = 1.0
	a.play()

func _material_for_ac(ac: Vector2i) -> StringName:

	if (ac in T_SURFACE_VARIANTS_SAND) or (ac == T_MID_SAND):
		return &"sand"

	if (ac in T_SURFACE_VARIANTS_SNOW) or (ac == T_MID_SNOW):
		return &"snow"


	if (ac == T_STONE) or (ac == T_CAVESTONE) or (ac == T_COALSTONE) or (ac == T_IRONSTONE) or (ac == T_GOLDSTONE) or (ac == T_YOYLITESTONE) or (ac == T_OVEN)\
	or (ac == T_BLUE_CONCRETE) or (ac == T_YELLOW_CONCRETE) or (ac == T_PURPLE_CONCRETE) or (ac == T_RED_CONCRETE) or (ac == T_GREEN_CONCRETE) or (ac == T_BROWN_CONCRETE)\
	or (ac == T_WHITE_CONCRETE) or (ac == T_WINDOW) or (ac == T_POLE) or (ac == T_SPHERE) or (ac == T_STRIPE) or (ac == T_PLATFORM) or (ac == T_YOYLE_CRYSTAL)\
	or (ac == T_VICTORY) or (ac == T_LUCKY) or (ac == T_YOYLITE_BOX) or (ac in T_YOYLITE_ANCHOR_PHASES) or (ac in T_YOYLITE_WIRE_STATE) or (ac in T_PISTON_FACES)\
	or (ac in T_STRINGY_PISTON_FACES) or (ac in T_YOYLITE_EMITTER_STATE) or (ac in T_LEVER_STATE) or (ac in T_YOYLITE_DELAYER_TICK):
		return &"stone"


	if (ac == T_LOG) or (ac == T_CRAFT) or (ac == T_DARK_LOG) or (ac == T_YOYLE_LOG) or (ac == T_BUSH_LOG) or (ac in T_PISTON_EXTENDER_FACES):
		return &"wood"


	if (ac in T_SURFACE_VARIANTS) or (ac in T_SURFACE_VARIANTS_DARK) or (ac in T_SURFACE_VARIANTS_YOYLE) or (ac == T_MID) or (ac == T_LEAVES) or (ac == T_DARK_LEAVES)\
	or (ac in T_SURFACE_VARIANTS_DARK) or (ac == T_MID_DARK) or (ac == T_CACTUS) or (ac == T_DYNAMITE) or (ac == T_YOYLE_LEAVES) or (ac == T_BUSH_LEAVES)\
	or (ac == T_BUSH_LEAVES_BERRIES) or (ac == T_STRING_BLOCK):
		return &"grass"

	if (ac == T_DEEP):
		return &"gravel"

	return &"grass"

func _mine_bank_for_material(mat: StringName) -> Array:
	match mat:
		&"stone": return _get_audio_list(MINE_STONE)
		&"wood": return _get_audio_list(MINE_WOOD)
		&"snow": return _get_audio_list(MINE_SNOW)
		&"sand": return _get_audio_list(MINE_SAND)
		&"gravel": return _get_audio_list(MINE_GRAVEL)
		_: return _get_audio_list(MINE_GRASS)

func _dig_bank_for_material(mat: StringName) -> Array:
	match mat:
		&"stone": return _get_audio_list(DIG_STONE)
		&"wood": return _get_audio_list(DIG_WOOD)
		&"snow": return _get_audio_list(DIG_SNOW)
		&"sand": return _get_audio_list(DIG_SAND)
		&"gravel": return _get_audio_list(DIG_GRAVEL)
		_: return _get_audio_list(DIG_GRASS)

func _pick_rand(arr: Array):
	if arr.is_empty(): return null
	randomize()
	return arr[randi() % arr.size()]

func _play_tool_break_local() -> void :
	if not is_instance_valid(local_player):
		return
	var a: AudioStreamPlayer2D = local_player.get_node_or_null("break")
	a.pitch_scale = randf_range(0.95, 1.05)
	a.play()

func _play_mined_material_local(mat: StringName) -> void :
	if not is_instance_valid(local_player): return
	var a: AudioStreamPlayer2D = local_player.get_node_or_null("mined")
	if a == null: return
	var bank: = _mine_bank_for_material(mat)
	var s = _pick_rand(bank)
	if s == null: return
	a.stream = s
	a.pitch_scale = 1.0
	a.play()

func _play_dig_material_local(mat: StringName) -> void :
	if not is_instance_valid(local_player): return
	var a: AudioStreamPlayer2D = local_player.get_node_or_null("mined")
	if a == null: return
	var bank: = _dig_bank_for_material(mat)
	var s = _pick_rand(bank)
	if s == null: return
	a.stream = s
	a.pitch_scale = 1.0
	a.play()

func _set_if_air_alt(c: Vector2i, atlas: Vector2i, alt: int) -> bool:
	if removed_cells.has(c) or cell_overrides.has(c):
		return false
	if _is_air(c):
		ground.set_cell(c, SRC, atlas, alt)
		return true
	return false

func _rng_for_chunk(ns: String, chunk_coord: Vector2i) -> RandomNumberGenerator:
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str(ns, ":", chunk_coord.x, ":", appearance_seed))
	return rng

func _set_if_air(c: Vector2i, atlas: Vector2i) -> bool:
	if removed_cells.has(c) or cell_overrides.has(c):
		return false
	if _is_air(c):
		ground.set_cell(c, SRC, atlas)
		return true
	return false


func _canopy_offsets_for_height(h: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var r: = 2 + int(h / 3)
	var out: Array[Vector2i] = []
	for dx in range( - r, r + 1):
		for dy in range( - r, r + 1):
			var md = abs(dx) + abs(dy)
			if md > r:
				continue

			var oy: = dy - 1

			if md == r and rng.randf() < 0.35:
				continue

			if dx == 0 and oy > 0:
				continue
			out.append(Vector2i(dx, oy))
	return out


func _place_tree_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0
	var h: = rng.randi_range(TREE_TRUNK_MIN, TREE_TRUNK_MAX)


	for i in range(1, h + 1):
		var c: = Vector2i(x, y0 - i)
		if _set_if_air_alt(c, T_LOG, ALT_LOG_DECOR):
			min_y = min(min_y, c.y)


	var top: = Vector2i(x, y0 - h)
	for off in _canopy_offsets_for_height(h, rng):
		var leaf_cell: = top + off
		if _set_if_air(leaf_cell, T_LEAVES):
			min_y = min(min_y, leaf_cell.y)

	return min_y


func _spawn_trees_for_chunk(cc: Vector2i) -> int:
	var biome: = _biome_for_chunk(cc)
	if biome == BIOME_SNOWY_FOREST:
		return _spawn_snowy_trees_for_chunk(cc)
	elif biome == BIOME_EVIL_FOREST:
		return _spawn_evil_trees_for_chunk(cc)
	elif biome == BIOME_DESERT:
		return _spawn_desert_plants_for_chunk(cc)
	elif biome == BIOME_GOIKY_CANAL:
		var rng: = _rng_for_chunk("goiky", cc)
		var rect: Rect2i = chunk_rects.get(cc, Rect2i(Vector2i(cc.x * CHUNK_SIZE, 0), Vector2i(CHUNK_SIZE, 1)))
		var bed_y: = rect.position.y + rect.size.y - 3
		_spawn_goiky_canal_lines_and_cactus_for_chunk(cc, bed_y, rng)
		_scatter_bed_stones_for_chunk(cc, bed_y, rng)
		return bed_y - 2
	elif biome == BIOME_YOYLELAND or biome == BIOME_YOYLEMOUNTAIN:
		return _spawn_yoyle_plants_for_chunk(cc)
	if biome == BIOME_YOYLECITY:
		return _spawn_yoylecity_for_chunk(cc)
	var rng: = _rng_for_chunk("trees", cc)
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE
	var last_tree_x: = -1000000
	var local_min_y: = 1000000
	for lx in range(1, CHUNK_SIZE - 1):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var l: = int(surf.get(x - 1, y0))
		var r: = int(surf.get(x + 1, y0))
		if abs(l - y0) > TREE_STEEP_REJECT or abs(r - y0) > TREE_STEEP_REJECT:
			continue
		if (x - last_tree_x) < TREE_MIN_SPACING: continue
		if rng.randf() >= TREE_BASE_PROB: continue
		var min_y: = _place_tree_at(x, y0, rng)
		local_min_y = min(local_min_y, min_y)
		last_tree_x = x
	return local_min_y


var _bug_viewers: = {}

func _bug_has_any_viewer(bid: int) -> bool:
	if not _bug_viewers.has(bid):
		return false
	return not (_bug_viewers[bid] as Dictionary).is_empty()

func _clear_bug_viewers_for_peer(pid: int) -> void :
	for bid in _bug_viewers.keys():
		var d: Dictionary = _bug_viewers[bid]
		d.erase(pid)
		if d.is_empty():
			_bug_viewers.erase(bid)

@rpc("any_peer")
func srv_report_bug_visible(bid: int, visible: bool) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()
	if pid == 0:
		pid = multiplayer.get_unique_id()
	var d: Dictionary = _bug_viewers.get(bid, {})
	if visible:
		d[pid] = true
	else:
		d.erase(pid)
	if d.is_empty():
		_bug_viewers.erase(bid)
	else:
		_bug_viewers[bid] = d


@rpc("any_peer", "call_local", "reliable")
func cli_reconcile_bugs(live_ids: Array) -> void :

	var set: = {}
	for id in live_ids:
		set[int(id)] = true


	var to_remove: Array[int] = []
	for k in bugs.keys():
		var bid: = int(k)
		if not set.has(bid):
			to_remove.append(bid)
	for bid in to_remove:
		_force_free_bug_node_local(bid)

func _broadcast_bug_reconcile() -> void :
	if not multiplayer.is_server():
		return
	var ids: Array[int] = []
	for k in _server_bugs.keys():
		ids.append(int(k))
	rpc("cli_reconcile_bugs", ids)

func _ensure_bugs_parent() -> void :
	if bugs_parent == null:
		var n: = Node2D.new()
		n.name = "Bugs"
		n.z_as_relative = false
		n.z_index = 2
		add_child(n, true)
		bugs_parent = n

func _ensure_fishes_parent() -> void :
	if fishes_parent == null:
		var n: = Node2D.new()
		n.name = "Fishes"
		n.z_as_relative = false
		n.z_index = 2
		add_child(n, true)
		fishes_parent = n

func _random_water_spot_in_chunk(cc: Vector2i) -> Variant:
	if not chunk_rects.has(cc):
		return null
	var rect: Rect2i = chunk_rects[cc]

	var tries: = 200
	while tries > 0:
		tries -= 1
		var cx: = randi_range(rect.position.x, rect.position.x + rect.size.x - 1)
		var cy: = randi_range(rect.position.y, rect.position.y + rect.size.y - 1)
		var c: = Vector2i(cx, cy)


		if not _is_water_cell_world(c):
			continue


		var wp: = ground.to_global(ground.map_to_local(c))


		var shape: = CircleShape2D.new()
		shape.radius = FISH_PROBE_RADIUS_PX
		var params: = PhysicsShapeQueryParameters2D.new()
		params.shape = shape
		params.transform = Transform2D(0.0, wp)
		params.collide_with_areas = true
		params.collide_with_bodies = true
		var hits: = get_world_2d().direct_space_state.intersect_shape(params, 8)
		var ok: = true
		for h in hits:
			if h.get("collider") != null:
				ok = false
				break
		if not ok:
			continue

		return wp

	return null

@rpc("any_peer")
func srv_client_chunk_loaded(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()
	var set = _peer_loaded_chunks.get(pid, {})
	set[chunk_coord] = true
	_peer_loaded_chunks[pid] = set


	for bid in _bugs_in_chunk_by_live_pos(chunk_coord):
		var b: Node2D = bugs.get(bid, null)
		if b and is_instance_valid(b):
			_set_peer_visibility(b, pid, true)
			var pos: = b.global_position
			var is_cave: = bool(_server_bugs[bid].get("is_cave", _server_bugs[bid].get("cave", false)))
			rpc_id(pid, "cli_spawn_bug", bid, pos, is_cave)


	for fid in _fishes_in_chunk_by_live_pos(chunk_coord):
		var f: Node2D = fishes.get(fid, null)
		if f and is_instance_valid(f):
			_set_peer_visibility(f, pid, true)
			var pos: = f.global_position
			rpc_id(pid, "cli_spawn_fish", fid, pos)

	_server_try_spawn_evil_leafy_if_ready(chunk_coord)
	_server_try_seed_fish_for_chunk(chunk_coord)
	_server_resend_fishes_for_chunk_to_peer(chunk_coord, multiplayer.get_remote_sender_id())

func _server_resend_fishes_for_chunk_to_peer(cc: Vector2i, peer_id: int) -> void :
	if not multiplayer.is_server(): return
	var list = _fishes_by_chunk.get(cc, [])
	for fid in list:
		if _server_fishes.has(fid):
			var pos: Vector2 = _server_fishes[fid]["pos"]
			rpc_id(peer_id, "rpc_spawn_fish", fid, pos)

func _server_despawn_pickups_in_chunk(cc: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var to_kill: Array[int] = []
	for pid in _server_pickups.keys():
		var info = _server_pickups[pid]
		var pos: Vector2 = info.get("pos", Vector2.ZERO)
		if _chunk_of_world_pos(pos) == cc:
			to_kill.append(int(pid))

	for pid in to_kill:
		_server_despawn_pickup(pid)

@rpc("any_peer")
func srv_client_chunk_unloaded(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var pid: = multiplayer.get_remote_sender_id()
	if _peer_loaded_chunks.has(pid):
		_peer_loaded_chunks[pid].erase(chunk_coord)


	for bid in _bugs_in_chunk_by_live_pos(chunk_coord):
		var b: Node2D = bugs.get(bid, null)
		if b and is_instance_valid(b):
			_set_peer_visibility(b, pid, false)


	for fid in _fishes_in_chunk_by_live_pos(chunk_coord):
		var f: Node2D = fishes.get(fid, null)
		if f and is_instance_valid(f):
			_set_peer_visibility(f, pid, false)

	var n: = get_node_or_null("EvilLeafy") as Node2D
	if n:
		_set_peer_visibility(n, pid, false)







	var need_any: = _required_chunks_for_any_player(ACTIVE_RADIUS_CHUNKS)
	if _loaded_count_peers(chunk_coord) == 0 and not _is_chunk_loaded(chunk_coord) and not need_any.has(chunk_coord):
		_server_despawn_bugs_in_chunk(chunk_coord)
		_server_despawn_fishes_in_chunk(chunk_coord)
		_server_despawn_pickups_in_chunk(chunk_coord)
		_despawn_chunk_and_cleanup(chunk_coord)
		call_deferred("_vacuum_dead_chunks_and_bugs")

@rpc("any_peer", "call_local", "reliable")
func cli_reconcile_fishes(live_ids: Array) -> void :
	var set: = {}
	for id in live_ids:
		set[int(id)] = true
	var to_remove: Array[int] = []
	for k in fishes.keys():
		var fid: = int(k)
		if not set.has(fid):
			to_remove.append(fid)
	for fid in to_remove:
		_force_free_fish_node_local(fid)

func _broadcast_fish_reconcile() -> void :
	if not multiplayer.is_server(): return
	var ids: Array[int] = []
	for k in _server_fishes.keys():
		ids.append(int(k))
	rpc("cli_reconcile_fishes", ids)

func _server_needs_chunk(cc: Vector2i) -> bool:


	return _is_chunk_loaded(cc)

func _chunks_in_radius(center_cc: Vector2i, r: int, vertical: int = 0) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range( - r, r + 1):
		for dy in range( - vertical, vertical + 1):
			out.append(Vector2i(center_cc.x + dx, center_cc.y + dy))
	return out

func _required_chunks_for_any_player(radius_chunks: int, vertical: int = 0) -> Dictionary:
	var need: = {}
	for p in get_tree().get_nodes_in_group("player"):
		if p == null or not is_instance_valid(p):
			continue
		if p.has_method("_dead") and p._dead:
			continue
		var center_cc: Vector2i = _chunk_of_world_pos(p.global_position)
		for cc in _chunks_in_radius(center_cc, radius_chunks, vertical):
			need[cc] = true
	return need

func world_chunk_loaded_for_pos(wp: Vector2) -> bool:
	var cc: = _chunk_of_world_pos(wp)
	return _is_chunk_loaded(cc) or _loaded_count_peers(cc) > 0

var DEBUG_BUGS: = false

func _force_free_bug_node_local(bid: int) -> void :

	if bugs.has(bid):
		var n = bugs[bid]
		if n and is_instance_valid(n):
			n.queue_free()
		bugs.erase(bid)

func _server_despawn_bugs_in_chunk(cc: Vector2i) -> void :
	if not multiplayer.is_server():
		return


	var ids: Array[int] = []


	if _bugs_by_chunk.has(cc):
		for v in _bugs_by_chunk[cc]:
			ids.append(int(v))


	for k in _server_bugs.keys():
		var bid: = int(k)
		var info = _server_bugs[bid]
		var cc_info = info.get("cc", null)
		var cc_of_info: Vector2i = cc_info if typeof(cc_info) == TYPE_VECTOR2I else _chunk_of_world_pos(info.get("pos", Vector2.ZERO))
		if cc_of_info == cc and not ids.has(bid):
			ids.append(bid)


	for k in bugs.keys():
		var bid: = int(k)
		var n = bugs[bid]
		if n and is_instance_valid(n):
			if _chunk_of_world_pos((n as Node2D).global_position) == cc and not ids.has(bid):
				ids.append(bid)

	if DEBUG_BUGS:
		print("[BUGS] Despawn chunk ", cc, " -> ids=", ids)


	for bid in ids:
		rpc("rpc_despawn_bug", bid)


	if _bugs_by_chunk.has(cc):
		_bugs_by_chunk.erase(cc)
	bug_seeded_chunks.erase(cc)
	surface_seeded_chunks.erase(cc)



	var leftovers: Array[int] = []
	for k in bugs.keys():
		var bid: = int(k)
		var n = bugs[bid]
		if n and is_instance_valid(n):
			if _chunk_of_world_pos((n as Node2D).global_position) == cc:
				leftovers.append(bid)
	for bid in leftovers:
		_force_free_bug_node_local(bid)


	for k in ids:
		_server_bugs.erase(int(k))


func _force_free_fish_node_local(fid: int) -> void :
	if fishes.has(fid):
		var n = fishes[fid]
		if n and is_instance_valid(n):
			n.queue_free()
		fishes.erase(fid)

func _server_despawn_fishes_in_chunk(cc: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var ids: Array[int] = []
	if _fishes_by_chunk.has(cc):
		for v in _fishes_by_chunk[cc]:
			ids.append(int(v))
	for fid in ids:
		rpc("rpc_despawn_fish", fid)

@rpc("any_peer", "call_local", "reliable")
func rpc_despawn_fish(fid: int) -> void :
	var n = fishes.get(fid, null)
	if n and is_instance_valid(n):
		n.queue_free()
	fishes.erase(fid)

	if multiplayer.is_server():
		var info = _server_fishes.get(fid, null)
		if info != null:
			var cc = info.get("cc", null)
			if typeof(cc) == TYPE_VECTOR2I and _fishes_by_chunk.has(cc):
				_fishes_by_chunk[cc].erase(fid)
				if _fishes_by_chunk[cc].is_empty():
					_fishes_by_chunk.erase(cc)
		_server_fishes.erase(fid)

func _is_night_now() -> bool:
	var dn: = get_tree().get_first_node_in_group("daynight")
	if dn:
		return bool(dn.get("is_night_now"))
	var sky: = get_tree().get_first_node_in_group("sky_cycle")
	if sky:
		return bool(sky.get("is_night_now"))
	var t: = Time.get_ticks_msec() * 0.001
	var phase: = fposmod(t - _dn_epoch_server_sec, DAYNIGHT_CYCLE_SEC) / DAYNIGHT_CYCLE_SEC
	return phase >= 0.5


func _find_sync_by_type(n: Node) -> MultiplayerSynchronizer:
	if n is MultiplayerSynchronizer:
		return n
	for c in n.get_children():
		var found: = _find_sync_by_type(c)
		if found:
			return found
	return null

var _bugs_by_chunk: = {}


func _chunk_of_world_pos(pos: Vector2) -> Vector2i:
	return Vector2i(_chunk_index_from_world_x(pos.x), 0)

@rpc("any_peer")
func srv_request_bugs_for_chunk(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	if not _is_chunk_loaded(chunk_coord): return
	var to_id: = multiplayer.get_remote_sender_id()

	for bid in _bugs_in_chunk_by_live_pos(chunk_coord):
		var live: Node2D = bugs.get(bid, null)
		var pos = (live.global_position if live and is_instance_valid(live) else _server_bugs.get(bid, {}).get("pos", Vector2.ZERO))
		var is_cave: bool = bool(_server_bugs[bid].get("is_cave", _server_bugs[bid].get("cave", false)))
		rpc_id(to_id, "cli_spawn_bug", bid, pos, is_cave)

@rpc("any_peer", "reliable")
func srv_request_fishes_for_chunk(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var sender_id: = multiplayer.get_remote_sender_id()
	if sender_id == 0: return


	if _fishes_by_chunk.has(chunk_coord):
		for fid in _fishes_by_chunk[chunk_coord]:
			if _server_fishes.has(fid):
				var info = _server_fishes[fid]
				var pos: Vector2 = info.get("pos", Vector2.ZERO)

				rpc_id(sender_id, "cli_spawn_fish", fid, pos)

func _bugs_in_chunk_by_live_pos(chunk_coord: Vector2i) -> Array[int]:
	var list: Array[int] = []
	for k in bugs.keys():
		var bid: = int(k)
		var obj = bugs.get(bid, null)
		if typeof(obj) == TYPE_OBJECT and not is_instance_valid(obj):
			bugs.erase(bid);continue
		var b: = obj as Node2D
		if b == null or not is_instance_valid(b):
			continue
		if _chunk_of_world_pos(b.global_position) == chunk_coord:
			list.append(bid)
	return list

func _fishes_in_chunk_by_live_pos(cc: Vector2i) -> Array[int]:
	var out: Array[int] = []

	for k in fishes.keys().duplicate():
		var obj = fishes.get(k, null)


		if typeof(obj) != TYPE_OBJECT or not is_instance_valid(obj):
			fishes.erase(k)
			continue


		var f: = obj as Node2D
		if f == null or not is_instance_valid(f):
			fishes.erase(k)
			continue

		if _chunk_of_world_pos(f.global_position) == cc:
			out.append(int(k))
	return out


func _solid_under_world_pos(wp: Vector2) -> bool:
	var cell: = ground.local_to_map(ground.to_local(wp))
	return _is_solid(cell) or _is_solid(cell + Vector2i(0, 1))


func _tick_bug_safety() -> void :
	if not multiplayer.is_server():
		return


	var ids: = _server_bugs.keys().duplicate()

	for bid in ids:
		var info: Dictionary = _server_bugs.get(bid, null)
		if info == null:
			_bug_last_safe_pos.erase(bid)
			continue

		var is_cave: = bool(info.get("is_cave", info.get("cave", false)))
		if not is_cave:
			continue

		var b = bugs.get(bid, null)

		if typeof(b) != TYPE_OBJECT or not is_instance_valid(b):
			bugs.erase(bid)
			_server_bugs.erase(bid)
			_bug_last_safe_pos.erase(bid)
			continue


		var pos: Vector2 = (b as Node2D).global_position


		if not is_instance_valid(b):
			continue

		if _solid_under_world_pos(pos):
			_bug_last_safe_pos[bid] = pos
		else:
			if _bug_last_safe_pos.has(bid):
				var safe: Vector2 = _bug_last_safe_pos[bid]

				if is_instance_valid(b):
					(b as Node2D).global_position = safe
			else:
				_bug_last_safe_pos[bid] = pos

func _ensure_surface_bugs_for_chunk(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	if _biome_for_chunk(chunk_coord) == BIOME_GOIKY_CANAL: return
	if not _is_night_now(): return
	if not _is_chunk_loaded(chunk_coord): return
	if surface_seeded_chunks.has(chunk_coord): return

	surface_seeded_chunks[chunk_coord] = true

	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("surface-bugs:", chunk_coord.x, ":", appearance_seed))

	var want: = rng.randi_range(SURFACE_BUGS_PER_CHUNK_MIN, SURFACE_BUGS_PER_CHUNK_MAX)
	if want <= 0: return

	var x0: = chunk_coord.x * CHUNK_SIZE
	var surf: = _surface_y_map_for_chunk(chunk_coord)

	var picked: Array[Vector2] = []
	var attempts = max(1, want * SURFACE_SPAWN_ATTEMPTS_FACTOR)

	for _i in attempts:
		if picked.size() >= want:
			break

		var lx: = rng.randi_range(0, CHUNK_SIZE - 1)
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))


		var stand_cell: = Vector2i(x, y0 - 1)
		if not _can_stand_here(stand_cell):
			continue

		var wp: = ground.to_global(ground.map_to_local(stand_cell))

		var ok: = true
		for p in picked:
			if p.distance_to(wp) < SURFACE_BUG_MIN_SEPARATION:
				ok = false;break
		if not ok: continue

		picked.append(wp)

	for pos in picked:
		_spawn_bug_at_world(pos + Vector2(0, BUG_SPAWN_OFFSET_Y), false)


func _world_free(wp: Vector2, radius: float = BUG_SPAWN_RADIUS) -> bool:
	var shape: = CircleShape2D.new()
	shape.radius = radius

	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, wp)
	params.collide_with_bodies = true
	params.collide_with_areas = true

	var hits: = get_world_2d().direct_space_state.intersect_shape(params, 8)
	return hits.is_empty()

func _ensure_bugs_for_chunk(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	if not _is_chunk_loaded(chunk_coord): return
	if bug_seeded_chunks.has(chunk_coord): return

	bug_seeded_chunks[chunk_coord] = true

	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("bugs:", chunk_coord.x, ":", appearance_seed))

	var want: = rng.randi_range(BUGS_PER_CHUNK_MIN, BUGS_PER_CHUNK_MAX)
	if want <= 0: return

	var x0: = chunk_coord.x * CHUNK_SIZE
	var surf: = _surface_y_map_for_chunk(chunk_coord)

	var picked: Array[Vector2] = []
	var attempts: = want * 32

	for _i in attempts:
		if picked.size() >= want:
			break

		var lx: = rng.randi_range(0, CHUNK_SIZE - 1)
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))


		var y: = rng.randi_range(y0 + CAVE_SAFE_DEPTH + 1, y0 + FILL_DEPTH - 2)
		var cell: = Vector2i(x, y)


		if not _is_cavestone_cell(cell):
			continue


		var wp: = ground.to_global(ground.map_to_local(cell)) + Vector2(0, BUG_SPAWN_OFFSET_Y)


		var ok: = true
		for p in picked:
			if p.distance_to(wp) < BUG_MIN_SEPARATION:
				ok = false
				break
		if not ok:
			continue

		picked.append(wp)

	for pos in picked:
		_spawn_bug_at_world(pos, true)

	if picked.size() > 0:
		print("BUGS in chunk ", chunk_coord, ": ", picked.size())

func _is_cavestone_cell(cell: Vector2i) -> bool:

	if ground.get_cell_source_id(cell) != SRC:
		return false
	return ground.get_cell_atlas_coords(cell) == T_CAVESTONE


var _sand_check: = {}

func _is_empty_cell(c: Vector2i) -> bool:
	return ground.get_cell_source_id(c) == -1

func _is_sand_cell(c: Vector2i) -> bool:
	if ground.get_cell_source_id(c) != SRC:
		return false
	var ac: = ground.get_cell_atlas_coords(c)
	if ac == T_MID_SAND:
		return true

	for v in T_SURFACE_VARIANTS_SAND:
		if ac == v:
			return true
	return false

const WATER_COORDS: = [Vector2i(4, 5)]
func _is_water_cell_world(c: Vector2i) -> bool:

	if ground.get_cell_source_id(c) == -1:
		return false
	return ground.get_cell_atlas_coords(c) in WATER_COORDS

func _schedule_sand_settle_from(c: Vector2i) -> void :
	_sand_check[c] = true
	if not _sand_vel.has(c):
		_sand_vel[c] = SAND_START_SPEED_CPS
	if not _sand_prog.has(c):
		_sand_prog[c] = 0.0

func _move_sand_down_at(c: Vector2i) -> bool:

	if not _is_sand_cell(c):
		_land_sand_at(c)
		return false

	var below: = c + Vector2i(0, 1)
	if not _is_empty_cell(below):
		_land_sand_at(c)
		return false

	var ac: = ground.get_cell_atlas_coords(c)


	rpc("cli_erase_cell", c)
	rpc("cli_set_cell", below, SRC, ac)


	var v: = float(_sand_vel.get(c, SAND_START_SPEED_CPS))
	var p: = float(_sand_prog.get(c, 0.0))
	_sand_vel.erase(c)
	_sand_prog.erase(c)
	_sand_vel[below] = v
	_sand_prog[below] = p


	_sand_check[below] = true

	_sand_check[c + Vector2i(0, -1)] = true
	return true


func _tick_falling_sand(max_cells: = 400) -> void :

	if multiplayer and not multiplayer.is_server():
		return
	if _sand_check.is_empty():
		return


	var batch: Array = []
	var i: = 0
	for key in _sand_check.keys():
		batch.append(key)
		i += 1
		if i >= max_cells:
			break
	for k in batch:
		_sand_check.erase(k)

	for start_c in batch:

		if not _is_sand_cell(start_c):
			_land_sand_at(start_c)
			continue


		var v: = float(_sand_vel.get(start_c, SAND_START_SPEED_CPS))
		v = min(SAND_MAX_SPEED_CPS, v + SAND_GRAVITY_CPS)

		var prog: = float(_sand_prog.get(start_c, 0.0)) + v
		var c = start_c
		var steps: = 0
		var moved_any: = false


		while prog >= 1.0 and steps < SAND_MAX_STEPS_PER_TICK:
			if not _move_sand_down_at(c):

				_land_sand_at(c)
				break

			c += Vector2i(0, 1)
			prog -= 1.0
			steps += 1
			moved_any = true


			if not _is_empty_cell(c + Vector2i(0, 1)):
				_land_sand_at(c)
				break


		if _is_sand_cell(c):
			var unsupported: = _is_empty_cell(c + Vector2i(0, 1))


			_sand_vel[c] = v
			_sand_prog[c] = prog

			if unsupported:

				_sand_check[c] = true
			else:

				_land_sand_at(c)
		else:

			_land_sand_at(c if moved_any else start_c)

func _is_air(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == -1

func _is_solid(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) != -1

func _can_stand_here(cell: Vector2i) -> bool:

	return _is_air(cell) and _is_solid(cell + Vector2i(0, 1))

func _server_reset_bugs_keep_positions() -> void :
	if not multiplayer.is_server():
		return


	const DESPAWN_BATCH: = 64
	const RESPAWN_BATCH: = 64


	var snapshot: Array = []
	for bid in _server_bugs.keys():
		var is_cave: = bool(_server_bugs[bid].get("is_cave", _server_bugs[bid].get("cave", false)))
		var live = bugs.get(bid, null)
		var pos = (live.global_position if live != null and is_instance_valid(live)
			else Vector2(_server_bugs[bid].get("pos", Vector2.ZERO)))
		snapshot.append({"pos": pos, "is_cave": is_cave})



	for bid in bugs.keys():
		var n = bugs[bid]
		if n != null and is_instance_valid(n):
			n.set_process(false)
			n.set_physics_process(false)


	var ids: = _server_bugs.keys()
	var i: = 0
	while i < ids.size():
		var end = min(i + DESPAWN_BATCH, ids.size())
		for j in range(i, end):
			_server_despawn_bug(int(ids[j]))
		i = end
		await get_tree().process_frame


	_bugs_by_chunk.clear()
	bug_seeded_chunks.clear()
	surface_seeded_chunks.clear()


	i = 0
	while i < snapshot.size():
		var end = min(i + RESPAWN_BATCH, snapshot.size())
		for j in range(i, end):
			var entry = snapshot[j]
			_spawn_bug_at_world(entry["pos"], bool(entry["is_cave"]))
		i = end
		await get_tree().process_frame



func _server_reset_fishes_keep_positions(reset_seed_flags: bool = false) -> void :
	if not multiplayer.is_server():
		return

	const DESPAWN_BATCH: = 64
	const RESPAWN_BATCH: = 64


	var snapshot: Array[Vector2] = []
	for fid in _server_fishes.keys():
		var live = fishes.get(fid, null)
		var pos = (live.global_position if live != null and is_instance_valid(live)
			else Vector2(_server_fishes[fid].get("pos", Vector2.ZERO)))
		snapshot.append(pos)


	for k in fishes.keys():
		var n = fishes[k]
		if n != null and is_instance_valid(n):
			n.set_process(false)
			n.set_physics_process(false)


	var ids: = _server_fishes.keys()
	var i: = 0
	while i < ids.size():
		var end = min(i + DESPAWN_BATCH, ids.size())
		for j in range(i, end):
			_server_despawn_fish(int(ids[j]))
		i = end
		await get_tree().process_frame


	_fishes_by_chunk.clear()
	if reset_seed_flags and not Engine.is_editor_hint():
		var has_prop: = false
		for p in get_property_list():

			if String(p.get("name", "")) == "fish_seeded_chunks":
				has_prop = true
				break
		if has_prop:
			var d = get("fish_seeded_chunks")
			if typeof(d) == TYPE_DICTIONARY:
				(d as Dictionary).clear()
				set("fish_seeded_chunks", d)


	i = 0
	while i < snapshot.size():
		var end = min(i + RESPAWN_BATCH, snapshot.size())
		for j in range(i, end):
			_spawn_fish_at_world(snapshot[j])
		i = end
		await get_tree().process_frame

func _set_peer_visibility(node: Node, peer_id: int, visible: bool) -> void :
	var mp: = get_tree().get_multiplayer()

	if mp.has_method("set_visibility_for"):
		mp.set_visibility_for(node, peer_id, visible)
		return

	if mp.has_method("set_visible_on_peer"):
		mp.set_visible_on_peer(node, peer_id, visible)


func _hp_range_for_biome(biome: int) -> Vector2i:
	match biome:
		BIOME_SNOWY_FOREST:
			return Vector2i(1, 3)
		BIOME_EVIL_FOREST:
			return Vector2i(2, 4)
		BIOME_DESERT:
			return Vector2i(2, 6)
		BIOME_GOIKY_CANAL:
			return Vector2i(3, 6)
		BIOME_YOYLELAND:
			return Vector2i(3, 9)
		BIOME_YOYLECITY:
			return Vector2i(3, 9)
		BIOME_YOYLEMOUNTAIN:
			return Vector2i(3, 9)
		_:
			return Vector2i(1, 2)


func _roll_bug_hp(bid: int, wp: Vector2) -> int:
	var cc: = _chunk_of_world_pos(wp)
	var biome: = _biome_for_chunk(cc)
	var range: = _hp_range_for_biome(biome)
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("bughp:", bid, ":", world_seed))
	return rng.randi_range(range.x, range.y)

func _spawn_bug_at_world(world_pos: Vector2, is_cave_bug: bool) -> void :
	if not multiplayer.is_server() or BUG_SCENE == null:
		return

	var bid: = _next_bug_id
	_next_bug_id += 1


	rpc("rpc_spawn_bug", bid, world_pos, is_cave_bug)


	_server_bugs[bid] = {"pos": world_pos, "is_cave": is_cave_bug}
	var cc: = _chunk_of_world_pos(world_pos)
	if not _bugs_by_chunk.has(cc):
		_bugs_by_chunk[cc] = []
	_bugs_by_chunk[cc].append(bid)
	var hp: = _roll_bug_hp(bid, world_pos)
	_server_bugs[bid]["hp"] = hp

	var biome: = _biome_for_chunk(_chunk_of_world_pos(world_pos))
	var r: = _hp_range_for_biome(biome)
	_server_bugs[bid]["hp_min"] = r.x
	_server_bugs[bid]["hp_max"] = r.y

var _pending_bugs_by_chunk: = {}
var _pending_fishes_by_chunk: = {}

@rpc("any_peer", "call_local", "reliable")
func rpc_spawn_bug(bid: int, world_pos: Vector2, is_cave: bool) -> void :
	_ensure_bugs_parent()


	if bugs.has(bid) and is_instance_valid(bugs[bid]):
		return

	var b: = BUG_SCENE.instantiate()


	var auth: = (SERVER_ID if not multiplayer.is_server() else multiplayer.get_unique_id())
	b.set_multiplayer_authority(auth, true)

	b.name = "Bug_%d" % bid
	b.global_position = world_pos
	b.is_cave_spawn = is_cave

	bugs_parent.add_child(b, true)
	bugs[bid] = b
	b.bug_id = bid

@rpc("any_peer", "call_local", "reliable")
func rpc_despawn_bug(bid: int) -> void :
	var n = bugs.get(bid, null)
	if n and is_instance_valid(n):
		n.queue_free()
	bugs.erase(bid)

	if multiplayer.is_server():
		var info = _server_bugs.get(bid, null)
		if info != null:
			var cc = info.get("cc", null)
			if typeof(cc) == TYPE_VECTOR2I and _bugs_by_chunk.has(cc):
				_bugs_by_chunk[cc].erase(bid)
				if _bugs_by_chunk[cc].is_empty():
					_bugs_by_chunk.erase(cc)
		_server_bugs.erase(bid)

func _spawn_fish_at_world(world_pos: Vector2) -> void :
	if not multiplayer.is_server() or FISH_SCENE == null:
		return
	var fid: = _next_fish_id
	_next_fish_id += 1


	var hp: = randi_range(3, 6)


	_server_fishes[fid] = {"pos": world_pos, "hp": hp, "max_hp": hp}

	var cc: = _chunk_of_world_pos(world_pos)
	if not _fishes_by_chunk.has(cc):
		_fishes_by_chunk[cc] = []
	_fishes_by_chunk[cc].append(fid)


	rpc("rpc_spawn_fish", fid, world_pos)

@rpc("any_peer", "call_local", "reliable")
func rpc_spawn_fish(fid: int, world_pos: Vector2) -> void :
	_ensure_fishes_parent()
	if fishes.has(fid) and is_instance_valid(fishes[fid]): return

	var f: = FISH_SCENE.instantiate()


	var auth: = (SERVER_ID if not multiplayer.is_server() else multiplayer.get_unique_id())
	f.set_multiplayer_authority(auth, true)

	f.name = "Fish_%d" % fid
	f.global_position = world_pos
	fishes_parent.add_child(f, true)
	fishes[fid] = f
	if f.has_method("set"): f.set("fish_id", fid)


	if not multiplayer.is_server():
		f.set_process(false)
		f.set_physics_process(false)

func _server_try_seed_fish_for_chunk(cc: Vector2i) -> void :
	if not multiplayer.is_server(): return
	if _biome_for_chunk(cc) != BIOME_GOIKY_CANAL: return
	if fish_seeded_chunks.has(cc): return

	var want: = randi_range(FISHES_PER_CHUNK_MIN, FISHES_PER_CHUNK_MAX)
	var placed_any: = false
	var attempts: = want * 25
	var placed: Array[Vector2] = []

	while want > 0 and attempts > 0:
		attempts -= 1
		var wp = _random_water_spot_in_chunk(cc)
		if wp == null:
			continue
		var ok: = true
		for p in placed:
			if p.distance_to(wp) < FISH_MIN_SEPARATION_PX:
				ok = false;break
		if not ok:
			continue
		_spawn_fish_at_world(wp)
		placed.append(wp)
		want -= 1
		placed_any = true

	if placed_any:
		fish_seeded_chunks[cc] = true

func _vacuum_dead_chunks_and_bugs() -> void :
	if not multiplayer.is_server():
		return

	var needed: = _required_chunks_for_all_players(ACTIVE_RADIUS_CHUNKS)


	var candidates: = {}

	for cc in _bugs_by_chunk.keys():
		candidates[cc] = true
	for k in _server_bugs.keys():
		var info = _server_bugs[k]
		var cc_info = info.get("cc", null)
		var cc_of_info: Vector2i = cc_info if typeof(cc_info) == TYPE_VECTOR2I else _chunk_of_world_pos(info.get("pos", Vector2.ZERO))
		candidates[cc_of_info] = true
	for cc in chunks.keys():
		candidates[cc] = true

	for cc in candidates.keys():
		if _loaded_count_peers(cc) == 0 and not needed.has(cc):
			_server_despawn_bugs_in_chunk(cc)
			if _is_chunk_loaded(cc):
				_despawn_chunk_and_cleanup(cc)


			_despawn_chunk_clouds(cc)


	_broadcast_bug_reconcile()
	unload_unused_assets()


func _chunk_index_from_world_x(world_x: float) -> int:
	var local_x: = ground.to_local(Vector2(world_x, 0.0)).x
	var w: = float(cell_size_px * CHUNK_SIZE)
	return int(floor(local_x / w))

func _chunk_index_from_local_x(local_x: float) -> int:
	var w: = float(cell_size_px * CHUNK_SIZE)
	return int(floor(local_x / w))

@rpc("any_peer", "call_local", "reliable")
func cli_spawn_bug(bid: int, world_pos: Vector2, is_cave: bool) -> void :
	_ensure_bugs_parent()
	if bugs.has(bid) and is_instance_valid(bugs[bid]): return

	var b: = BUG_SCENE.instantiate()
	b.set_multiplayer_authority(SERVER_ID, true)
	b.name = "Bug_%d" % bid
	b.global_position = world_pos
	b.is_cave_spawn = is_cave
	bugs_parent.add_child(b, true)

	if not multiplayer.is_server():
		_disable_bug_local(b)

	bugs[bid] = b


	if not multiplayer.is_server():
		b.process_mode = Node.PROCESS_MODE_DISABLED
		b.set_process(false)
		b.set_physics_process(false)

	bugs[bid] = b
	b.bug_id = bid

@rpc("any_peer", "call_local", "reliable")
func cli_spawn_fish(fid: int, world_pos: Vector2) -> void :
	_ensure_fishes_parent()
	if fishes.has(fid) and is_instance_valid(fishes[fid]): return

	var f: = FISH_SCENE.instantiate()
	f.set_multiplayer_authority(SERVER_ID, true)
	f.name = "Fish_%d" % fid
	f.global_position = world_pos
	fishes_parent.add_child(f, true)


	if not multiplayer.is_server():
		f.process_mode = Node.PROCESS_MODE_DISABLED
		f.set_process(false)
		f.set_physics_process(false)

	fishes[fid] = f
	if f.has_method("set"):
		f.set("fish_id", fid)
	if not f.is_in_group("fish"):
		f.add_to_group("fish")

@rpc("any_peer", "call_local", "reliable")
func cli_despawn_bug(bid: int) -> void :
	if bugs.has(bid):
		var n = bugs[bid]
		if is_instance_valid(n): n.queue_free()
		bugs.erase(bid)

func _server_despawn_bug(bid: int) -> void :
	if not multiplayer.is_server(): return
	rpc("rpc_despawn_bug", bid)
	_bug_viewers.erase(bid)

func _server_despawn_fish(fid: int) -> void :
	if not multiplayer.is_server(): return
	rpc("rpc_despawn_fish", fid)

func _item_texture_for(id: int, ac: Vector2i, alt: int) -> Texture2D:

	if ac.x >= 0 and ac.y >= 0:
		var t: = _texture_from_atlas_cached(SRC, ac, alt)
		if t != null:
			return t


	var entry = ITEM_SPRITES.get(id, null)
	if typeof(entry) == TYPE_STRING and entry != "":
		var tex: = _get_tex_from_path(String(entry))
		if tex != null:
			return tex


	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	return hotbar.icon_by_item.get(id, null) if hotbar else null

func _texture_from_atlas_cached(src_id: int, ac: Vector2i, alt: int) -> Texture2D:
	var key: = "%d:%d,%d:%d" % [src_id, ac.x, ac.y, alt]
	if _atlas_cache.has(key):

		_atlas_cache_order.erase(key)
		_atlas_cache_order.append(key)
		return _atlas_cache[key]
	var t: = _texture_from_atlas(src_id, ac, alt)
	if t != null:
		_atlas_cache[key] = t
		_atlas_cache_order.append(key)

		if _atlas_cache_order.size() > ATLAS_CACHE_MAX:
			var old_key = _atlas_cache_order.pop_front()
			_atlas_cache.erase(old_key)
	return t

func _purge_cell_state_for_chunk(cc: Vector2i) -> void :
	var x0: = cc.x * CHUNK_SIZE
	var x1: = x0 + CHUNK_SIZE - 1
	var y0: = cc.y * CHUNK_SIZE
	var y1: = y0 + CHUNK_SIZE - 1

	var kill_removed: Array[Vector2i] = []
	for c in removed_cells.keys():
		if c.x >= x0 and c.x <= x1 and c.y >= y0 and c.y <= y1:
			kill_removed.append(c)
	for c in kill_removed:
		removed_cells.erase(c)

	var kill_over: Array[Vector2i] = []
	for c in cell_overrides.keys():
		if c.x >= x0 and c.x <= x1 and c.y >= y0 and c.y <= y1:
			kill_over.append(c)
	for c in kill_over:
		cell_overrides.erase(c)

func _server_spawn_pickup(item_id: int, pos: Vector2, ac: Vector2i, alt: int, opts: = {}) -> int:
	var reason: = String(opts.get("reason", "seed"))
	var bypass: = bool(opts.get("bypass_cake_ban", false))

	var meta: Dictionary = {}
	if opts.has("meta") and typeof(opts["meta"]) == TYPE_DICTIONARY:
		meta = (opts["meta"] as Dictionary).duplicate(true)


	if item_id == ITEM_CAKE and not bypass:
		var cell: = ground.local_to_map(ground.to_local(pos))
		var x: = cell.x
		if collected_cake_columns.has(x):
			print("[CAKE] Blocked respawn at column ", x, " (reason=", reason, ")")
			return -1
	if item_id == ITEM_CAKE and _cake_nearby(pos):
		print("[CAKE] Skipped: nearby cake exists")
		return -1


	var pid: = _next_pickup_id
	_next_pickup_id += 1
	_server_pickups[pid] = {
		"item_id": item_id, 
		"pos": pos, 
		"ac": ac, 
		"alt": alt, 
		"meta": meta
	}


	rpc("cli_spawn_pickup", pid, item_id, pos, ac, alt, meta)
	return pid

@rpc("any_peer", "reliable")
func srv_world_ready() -> void :
	if not multiplayer.is_server(): return
	var id: = multiplayer.get_remote_sender_id()


	for pid in _server_pickups.keys():
		var info = _server_pickups[pid]
		var meta: = (info.get("meta", {}) as Dictionary)
		rpc_id(id, "cli_spawn_pickup", 
			pid, int(info["item_id"]), info["pos"], info["ac"], int(info["alt"]), meta)

	for bid in _server_bugs.keys():
		var info = _server_bugs[bid]
		rpc_id(id, "rpc_spawn_bug", int(bid), 
			info.get("pos", Vector2.ZERO), 
			bool(info.get("is_cave", info.get("cave", false))))


func _loaded_count_peers(cc: Vector2i) -> int:
	var c: = 0
	for pid in _peer_loaded_chunks.keys():
		var set: Dictionary = _peer_loaded_chunks[pid]
		if set.has(cc): c += 1
	return c



func _update_bug_indices_and_positions() -> void :
	if not multiplayer.is_server(): return

	for k in bugs.keys():
		var bid: = int(k)
		var b = bugs[bid]
		if b == null or not is_instance_valid(b):
			continue

		var pos: = (b as Node2D).global_position

		if _server_bugs.has(bid):
			_server_bugs[bid]["pos"] = pos

		var new_cc: = _chunk_of_world_pos(pos)
		var old_cc = _server_bugs.get(bid, {}).get("cc", null)


		if old_cc != null and old_cc != new_cc and _bugs_by_chunk.has(old_cc):
			_bugs_by_chunk[old_cc].erase(bid)
			if _bugs_by_chunk[old_cc].is_empty():
				_bugs_by_chunk.erase(old_cc)
		if not _bugs_by_chunk.has(new_cc):
			_bugs_by_chunk[new_cc] = []
		if not _bugs_by_chunk[new_cc].has(bid):
			_bugs_by_chunk[new_cc].append(bid)
		_server_bugs[bid]["cc"] = new_cc


		if not _is_chunk_loaded(new_cc) and _loaded_count_peers(new_cc) == 0:
			_server_despawn_bug(bid)

func _cake_was_collected_on_column(x: int) -> bool:
	return collected_cake_columns.has(x)

func _server_despawn_pickup(pid: int) -> void :
	if _server_pickups.has(pid):
		var info = _server_pickups[pid]
		if int(info.get("item_id", -1)) == ITEM_CAKE:
			var pos: Vector2 = info.get("pos", Vector2.ZERO)
			var cell: = ground.local_to_map(ground.to_local(pos))

			var x: = cell.x
			var y: = int(last_surface_y_for_x.get(x, cell.y))
			var anchor: = Vector2i(x, y)
			collected_cake_cells[anchor] = true
			collected_cake_columns[x] = true
		_server_pickups.erase(pid)
	rpc("cli_despawn_pickup", pid)

func _server_do_melee(attacker_id: int, facing_sign: int) -> void :
	if not multiplayer.is_server(): return

	var t: = _now()
	var last: = float(_last_attack_at.get(attacker_id, 0.0))
	if t - last < MELEE_COOLDOWN:
		return
	_last_attack_at[attacker_id] = t

	var attacker: Node2D = players.get(attacker_id, null)
	if attacker == null or not is_instance_valid(attacker):
		return

	var origin: = attacker.global_position
	var forward: = Vector2(facing_sign, 0.0).normalized()
	var cos_half_arc: = cos(deg_to_rad(MELEE_ARC_DEG * 0.5))

	for vid in players.keys():
		if vid == attacker_id:
			continue

		if t - float(_last_hit_at.get(vid, 0.0)) < MELEE_HIT_IFRAME:
			continue

		var vic: Node2D = players[vid]
		if vic == null or not is_instance_valid(vic):
			continue

		var to_v: = vic.global_position - origin
		var dist: = to_v.length()
		if dist > MELEE_RANGE_PX:
			continue
		if dist > 0.001 and forward.dot(to_v / dist) < cos_half_arc:
			continue

		_last_hit_at[vid] = t
		var kb: = Vector2(MELEE_KNOCKBACK.x * facing_sign, MELEE_KNOCKBACK.y)

		var dmg: = _attack_damage_for(attacker_id)
		(vic as Node).rpc_id(vid, "cli_receive_damage", dmg, kb)
		print("HIT: ", attacker_id, " -> ", vid)


@rpc("any_peer")
func srv_request_melee(facing_sign: int, selected_item_id: int = ITEM_NONE) -> void :
	if not multiplayer.is_server(): return
	var attacker_id: = multiplayer.get_remote_sender_id()
	_equipped_item[attacker_id] = selected_item_id
	_server_do_melee(attacker_id, facing_sign)


@rpc("any_peer")
func srv_request_chunk_diff(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server():
		return
	var to_id: = multiplayer.get_remote_sender_id()
	var x0: = chunk_coord.x * CHUNK_SIZE
	var x1: = x0 + CHUNK_SIZE - 1

	var override_cells: Array[Vector2i] = []
	var override_ac: Array[Vector2i] = []
	for c in cell_overrides.keys():
		var cx: = int(c.x)
		if cx >= x0 and cx <= x1:
			override_cells.append(c)
			override_ac.append(cell_overrides[c])

	var removed_list: Array[Vector2i] = []
	for c in removed_cells.keys():
		var cx: = int(c.x)
		if cx >= x0 and cx <= x1:
			removed_list.append(c)

	rpc_id(to_id, "cli_apply_chunk_diff", chunk_coord, override_cells, override_ac, removed_list)



@rpc("any_peer", "call_local", "reliable")
func cli_apply_chunk_diff(
	_chunk_coord: Vector2i, 
	override_cells: Array, 
	override_ac: Array, 
	removed_list: Array) -> void :

	var n = min(override_cells.size(), override_ac.size())
	for i in range(n):
		var cell: Vector2i = override_cells[i]
		var ac: Vector2i = override_ac[i]
		cell_overrides[cell] = ac
		removed_cells.erase(cell)
	for cell in removed_list:
		removed_cells[cell] = true
		cell_overrides.erase(cell)


	for i in range(n):
		var cell: Vector2i = override_cells[i]
		var ac: Vector2i = override_ac[i]
		ground.set_cell(cell, SRC, ac)

	for cell in removed_list:
		ground.erase_cell(cell)

@rpc("any_peer", "call_local", "reliable")
func cli_set_world_seeds(s: int, a: int) -> void :
	_apply_world_seeds_and_init(s, a)

@rpc("any_peer", "call_local", "reliable")
func cli_set_cell(cell: Vector2i, src_id: int, ac: Vector2i) -> void :
	ground.set_cell(cell, src_id, ac)

	cell_overrides[cell] = ac
	removed_cells.erase(cell)



	if _pending_place.has(cell):
		var item_id = _pending_place[cell]
		_pending_place.erase(cell)
		var hotbar: = get_tree().get_first_node_in_group("hotbar")
		if hotbar:
			hotbar.call("consume_selected", 1)

	if multiplayer.is_server():

		if _is_sand_cell(cell) and _is_empty_cell(cell + Vector2i(0, 1)):
			_schedule_sand_settle_from(cell)

		var above: = cell + Vector2i(0, -1)
		if _is_sand_cell(above):
			_schedule_sand_settle_from(above)

@rpc("any_peer", "call_local", "reliable")
func cli_erase_cell(cell: Vector2i) -> void :
	ground.erase_cell(cell)
	removed_cells[cell] = true
	cell_overrides.erase(cell)

	if multiplayer.is_server():
		var above: = cell + Vector2i(0, -1)
		if _is_sand_cell(above):
			_schedule_sand_settle_from(above)


@rpc("any_peer", "call_local", "reliable")
func cli_play_mined_material(mat: String, pos: Vector2) -> void :
	_play_mined_material_at(StringName(mat), pos)

@rpc("any_peer", "call_local", "reliable")
func cli_play_dig_material(mat: String, pos: Vector2) -> void :
	_play_dig_material_at(StringName(mat), pos)

func _play_mined_material_at(mat: StringName, pos: Vector2) -> void :
	var bank: = _mine_bank_for_material(mat)
	var s = _pick_rand(bank); if s == null: return
	_play_sfx_at(s, pos, 0.0)

func _play_dig_material_at(mat: StringName, pos: Vector2) -> void :
	var bank: = _dig_bank_for_material(mat)
	var s = _pick_rand(bank); if s == null: return
	_play_sfx_at(s, pos, 0.0)

@rpc("any_peer", "call_local", "reliable")
func cli_spawn_pickup(pid: int, item_id: int, world_pos: Vector2, ac: Vector2i, alt: int, meta: Dictionary = {}) -> void :
	if pickups.has(pid):

		var n = pickups[pid]
		if is_instance_valid(n):
			n.global_position = world_pos
		return
	var p: = pickup_scene.instantiate()
	p.item_id = item_id
	p.count = 1
	p.pickup_id = pid
	p.global_position = world_pos
	p.meta = (meta as Dictionary).duplicate(true)

	if p is Node2D:
		p.z_as_relative = false
		p.z_index = 4

	var tex: Texture2D = null
	if item_id == ITEM_CAKE:
		tex = _get_tex_from_path(PATH_CAKE)
	elif ac.x >= 0 and ac.y >= 0:
		tex = _texture_from_atlas(SRC, ac, alt)
	if tex == null:
		tex = _pickup_texture_for_item(item_id)
	if tex != null:
		p.texture = tex

	pickup_layer.add_child(p)
	pickups[pid] = p


func _pickup_texture_for_item(id: int) -> Texture2D:
	var path = ITEM_SPRITES.get(id, null)
	if typeof(path) == TYPE_STRING and path != "":
		return _get_tex_from_path(String(path))

	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar:
		var t: Texture2D = hotbar.icon_by_item.get(id, null)
		if t: return t
	return null

func icon_map_for_hotbar() -> Dictionary:
	var out: Dictionary = {}


	if typeof(ITEM_SPRITES) == TYPE_DICTIONARY:
		for id in ITEM_SPRITES.keys():
			var entry = ITEM_SPRITES[id]
			if typeof(entry) == TYPE_STRING and entry != "":
				var tex: = _get_tex_from_path(entry)
				if tex != null:
					out[int(id)] = tex


	var atlas_pairs: = {
		ITEM_GRASS: T_SURFACE_VARIANTS[0], 
		ITEM_DIRT: T_DEEP, 
		ITEM_STONE: T_STONE, 
		ITEM_LOG: T_LOG, 
		ITEM_LEAVES: T_LEAVES, 
		ITEM_CRAFT: T_CRAFT, 
		ITEM_COAL_STONE: T_COALSTONE, 
		ITEM_IRON_STONE: T_IRONSTONE, 
		ITEM_GOLD_STONE: T_GOLDSTONE, 
		ITEM_YOYLITE_STONE: T_YOYLITESTONE, 
		ITEM_OVEN: T_OVEN, 
		ITEM_SNOW: T_SURFACE_VARIANTS_SNOW[0], 
		ITEM_DARK_LOG: T_DARK_LOG, 
		ITEM_DARK_LEAVES: T_DARK_LEAVES, 
		ITEM_SAND: T_SURFACE_VARIANTS_SAND[0], 
		ITEM_DARK_GRASS: T_SURFACE_VARIANTS_DARK[0], 
		ITEM_CACTUS: T_CACTUS, 
		ITEM_DYNAMITE: T_DYNAMITE, 
		ITEM_YOYLE_GRASS: T_SURFACE_VARIANTS_YOYLE[0], 
		ITEM_YOYLE_LOG: T_YOYLE_LOG, 
		ITEM_YOYLE_LEAVES: T_YOYLE_LEAVES, 
		ITEM_BUSH_LOG: T_BUSH_LOG, 
		ITEM_BUSH_LEAVES: T_BUSH_LEAVES, 
		ITEM_BUSH_LEAVES_BERRIES: T_BUSH_LEAVES_BERRIES, 
		ITEM_BLUE_CONCRETE: T_BLUE_CONCRETE, 
		ITEM_YELLOW_CONCRETE: T_YELLOW_CONCRETE, 
		ITEM_PURPLE_CONCRETE: T_PURPLE_CONCRETE, 
		ITEM_RED_CONCRETE: T_RED_CONCRETE, 
		ITEM_GREEN_CONCRETE: T_GREEN_CONCRETE, 
		ITEM_BROWN_CONCRETE: T_BROWN_CONCRETE, 
		ITEM_WHITE_CONCRETE: T_WHITE_CONCRETE, 
		ITEM_WINDOW: T_WINDOW, 
		ITEM_POLE: T_POLE, 
		ITEM_SPHERE: T_SPHERE, 
		ITEM_STRIPE: T_STRIPE, 
		ITEM_PLATFORM: T_PLATFORM, 
		ITEM_YOYLE_CRYSTAL: T_YOYLE_CRYSTAL, 
		ITEM_WATER: T_WATER, 
		ITEM_VICTORY: T_VICTORY, 
		ITEM_LUCKY: T_LUCKY, 
		ITEM_YOYLITE_BOX: T_YOYLITE_BOX, 
		ITEM_YOYLITE_ANCHOR_0: T_YOYLITE_ANCHOR_0, 
		ITEM_YOYLITE_ANCHOR_1: T_YOYLITE_ANCHOR_1, 
		ITEM_YOYLITE_ANCHOR_2: T_YOYLITE_ANCHOR_2, 
		ITEM_YOYLITE_ANCHOR_3: T_YOYLITE_ANCHOR_3, 
		ITEM_YOYLITE_ANCHOR_4: T_YOYLITE_ANCHOR_4, 
		ITEM_YOYLITE_WIRE: T_YOYLITE_WIRE_OFF, 
		ITEM_PISTON: T_PISTON_RIGHT, 
		ITEM_STRINGY_PISTON: T_STRINGY_PISTON_RIGHT, 
		ITEM_YOYLITE_EMITTER: T_YOYLITE_EMITTER_ON, 
		ITEM_LEVER: T_LEVER_OFF, 
		ITEM_PISITON_EXTENDER: T_PISTON_EXTENDER_RIGHT, 
		ITEM_YOYLITE_DELAYER: T_YOYLITE_DELAYER_1_OFF, 
		ITEM_STRING_BLOCK: T_STRING_BLOCK
	}

	for id in atlas_pairs.keys():
		var ac: Vector2i = atlas_pairs[id]
		var tex: Texture2D = _texture_from_atlas_cached(SRC, ac, 0)
		if tex != null:
			out[int(id)] = tex

	return out



func _server_assign_number(peer_id: int, explicit: int = -1) -> void :
	if not multiplayer.is_server():
		return

	var num: = explicit
	if num <= 0:
		num = next_player_number
		next_player_number += 1

	player_numbers[peer_id] = num


	rpc_id(peer_id, "cli_set_local_player_number", num)

	rpc("cli_set_peer_number", peer_id, num)

func _server_has_player1() -> bool:
	for k in player_numbers.keys():
		if int(player_numbers[k]) == 1:
			return true
	return false

@rpc("any_peer", "call_local", "reliable")
func cli_set_local_player_number(n: int) -> void :
	my_player_number = n
	if player_number:
		player_number.text = "Player %d" % n

@rpc("any_peer", "call_local", "reliable")
func cli_set_peer_number(peer_id: int, n: int) -> void :


	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		var node = players[peer_id]
		if node.has_node("NumberLabel"):
			var L: Label = node.get_node("NumberLabel")
			L.text = str(n)

@rpc("any_peer", "call_local", "reliable")
func cli_despawn_pickup(pid: int) -> void :
	if pickups.has(pid):
		var node = pickups[pid]
		if is_instance_valid(node): node.queue_free()
		pickups.erase(pid)

func is_item_edible(id: int) -> bool:
	return EDIBLE_EFFECTS.has(id)

func edible_effects(id: int) -> Dictionary:
	return EDIBLE_EFFECTS.get(id, {"hunger": 0, "heal": 0})

const pickup_scene: PackedScene = preload("res://Pickup.tscn")
@onready var pickup_layer: Node = $Pickups if has_node("Pickups") else self

func _try_place_at_cell(cell: Vector2i, tile: Vector2i) -> bool:
	var source_slot: = {}
	var hb: = get_tree().get_first_node_in_group("hotbar")
	if hb and hb.slots.size() > hb.selected and typeof(hb.slots[hb.selected]) == TYPE_DICTIONARY:
		source_slot = (hb.slots[hb.selected] as Dictionary).duplicate(true)

	if multiplayer.is_server():

		return _server_place_cell(cell, tile, multiplayer.get_unique_id(), source_slot)
	else:
		rpc_id(SERVER_ID, "srv_request_place", cell, tile, source_slot)
		return true

@rpc("any_peer")
func srv_request_break(cell: Vector2i, selected_item_id: int) -> void :
	if not multiplayer.is_server(): return
	_server_break_cell(cell, multiplayer.get_remote_sender_id(), selected_item_id)

@rpc("any_peer")
func srv_request_place(cell: Vector2i, tile: Vector2i, source_slot: Dictionary = {}) -> void :
	if not multiplayer.is_server(): return
	_server_place_cell(cell, tile, multiplayer.get_remote_sender_id(), source_slot)


@rpc("any_peer")
func srv_request_pickup(pid: int, by_peer_id: int = -1) -> void :
	if not multiplayer.is_server(): return
	if not _server_pickups.has(pid): return

	var from_id: = multiplayer.get_remote_sender_id()
	if from_id == 0:
		from_id = (by_peer_id if by_peer_id != -1 else multiplayer.get_unique_id())

	var p = players.get(from_id, null)
	if p == null: return

	var info = _server_pickups[pid]
	var item_id: = int(info.get("item_id", 0))


	var live_node = pickups.get(pid, null)
	var live_pos = (live_node.global_position if live_node != null and is_instance_valid(live_node) else info.get("pos", Vector2.ZERO))
	var player_pos: = (p as Node2D).global_position
	if player_pos.distance_to(live_pos) > 160.0:
		return

	_server_despawn_pickup(pid)

	if item_id != 0:
		var meta: = (info.get("meta", {}) as Dictionary).duplicate(true)

		rpc_id(from_id, "cli_give_item_with_meta_hotbar_first", item_id, 1, meta)

	rpc_id(from_id, "cli_play_pickup")
	var stream_path: = ""
	var pop_node: = p.get_node_or_null("pop") as AudioStreamPlayer2D
	if pop_node and pop_node.stream and pop_node.stream.resource_path != "":
		stream_path = String(pop_node.stream.resource_path)
	else:
		stream_path = "res://sounds/Pop.ogg.mp3"

	_server_broadcast_player_sfx(from_id, SFX_KIND_PICKUP, stream_path, live_pos, -2.0)

@rpc("call_local")
func cli_give_item_with_meta_hotbar_first(item_id: int, amount: int, meta: Dictionary) -> void :
	var hb: = get_tree().get_first_node_in_group("hotbar")
	var inv: = get_tree().get_first_node_in_group("inventory")
	var left: = amount
	if hb and hb.has_method("add_with_meta"):
		left = hb.add_with_meta(item_id, left, meta)
	if left > 0 and inv and inv.has_method("add_with_meta"):
		left = inv.add_with_meta(item_id, left, meta)
	if left > 0 and hb and hb.has_method("try_add"):
		left = hb.try_add(item_id, left)
	if left > 0 and inv and inv.has_method("try_add"):
		left = inv.try_add(item_id, left)


func _get_local_player() -> Node2D:
	var my_id: = multiplayer.get_unique_id()
	for n in get_tree().get_nodes_in_group("player"):
		var p: = n as Node2D
		if p and p.get_multiplayer_authority() == my_id:
			return p
	var all: = get_tree().get_nodes_in_group("player")
	return all[0] as Node2D if all.size() == 1 else null


@rpc("any_peer", "call_local")
func cli_give_item(item_id: int, count: int) -> void :
	var left: = count


	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar and hotbar.has_method("try_add"):
		left = int(hotbar.call("try_add", item_id, left))


	if left > 0:
		var inv: = get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("try_add"):
			left = int(inv.call("try_add", item_id, left))


	if left > 0:
		var me: = _get_local_player()
		var drop_pos: = (me.global_position if me else Vector2.ZERO)

		if multiplayer.is_server():

			srv_request_drop(item_id, left, drop_pos)
		else:

			rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_request_drop", item_id, left, drop_pos)


@rpc("any_peer", "call_local")
func cli_play_pickup() -> void :

	var me_id: = multiplayer.get_unique_id()
	if players.has(me_id) and is_instance_valid(players[me_id]):
		var pop: = players[me_id].get_node_or_null("pop") as AudioStreamPlayer2D
		if pop:
			pop.pitch_scale = randf_range(0.8, 2.8)
			pop.play();return


	for n in get_tree().get_nodes_in_group("player"):
		if n.has_method("is_multiplayer_authority") and n.is_multiplayer_authority():
			var pop2: = n.get_node_or_null("pop") as AudioStreamPlayer2D
			if pop2:
				pop2.pitch_scale = randf_range(0.8, 2.8)
				pop2.play()
			return

@rpc("any_peer")
func srv_request_drop(item_id: int, count: int, world_pos: Vector2, meta_any: Variant = null) -> void :
	if not multiplayer.is_server(): return
	if count <= 0: return


	var meta_list: Array = []
	match typeof(meta_any):
		TYPE_DICTIONARY:
			meta_list = [(meta_any as Dictionary).duplicate(true)]
		TYPE_ARRAY:

			for m in (meta_any as Array):
				meta_list.append((m as Dictionary).duplicate(true))
		_:

			pass


	var ac: = item_id_to_atlas(item_id, 0, 0)
	var alt: = 0
	if ac.x < 0:
		ac = Vector2i(-1, -1)


	if ToolDurability.is_tool_id(item_id):
		count = min(count, 1)



	for i in count:
		var jitter: = Vector2(randf_range(-10, 10), -6)
		var wp: = world_pos + jitter
		wp.x += randf_range(-6, 6)


		if item_id == ITEM_CAKE and _cake_nearby(wp, 28.0):
			var tries: = 6
			while tries > 0 and _cake_nearby(wp, 28.0):
				wp.x += randf_range(-18, 18)
				wp.y += randf_range(-6, 6)
				tries -= 1


		var m: Dictionary = {}
		if i < meta_list.size():
			m = meta_list[i]


		_server_spawn_pickup(item_id, wp, ac, alt, {
			"reason": "player_drop", 
			"bypass_cake_ban": true, 
			"meta": m, 
		})

func _can_harvest_tile_with_tool(ac: Vector2i, tool_id: int) -> bool:

	if ac == T_IRONSTONE:
		return tool_id == ITEM_STONE_PICKAXE or tool_id == ITEM_IRON_PICKAXE or tool_id == ITEM_YOYLITE_PICKAXE

	if ac == T_GOLDSTONE:
		return tool_id == ITEM_IRON_PICKAXE or tool_id == ITEM_YOYLITE_PICKAXE
	if ac == T_YOYLITESTONE:
		return tool_id == ITEM_IRON_PICKAXE or tool_id == ITEM_YOYLITE_PICKAXE

	if ac == T_COALSTONE or ac == T_STONE:
		return _is_pickaxe_item(tool_id)

	return true

func _server_break_cell(cell: Vector2i, from_id: int, selected_item_id: int, suppress_drop: = false) -> bool:
	if not multiplayer.is_server(): return false
	if not _cell_is_breakable(cell): return false

	var ac: = ground.get_cell_atlas_coords(cell)
	if ac == T_CAVESTONE: return false
	if ac == T_WATER: return false
	if ac in T_PISTON_EXTENDER_FACES: return false
	var alt: = ground.get_cell_alternative_tile(cell)

	var drop_id: = ITEM_NONE
	var amount: = 1
	var pickup_ac: = ac
	var pickup_alt: = alt

	var can_harvest: = _can_harvest_tile_with_tool(ac, selected_item_id)


	if ac == T_DYNAMITE:
		drop_id = (atlas_to_item_id(ac) if not suppress_drop else ITEM_NONE)




	if ac in T_PISTON_FACES or ac in T_STRINGY_PISTON_FACES:
		var dir: = _piston_dir_from_ac(ac)
		if dir != Vector2i.ZERO:
			var front: = cell + dir
			if ground.get_cell_source_id(front) == SRC:
				var fac: = ground.get_cell_atlas_coords(front)
				if fac == _extender_ac_for_dir(dir):
					_server_erase_cell_nodrop(front)

	if ac == T_YOYLITE_BOX:
		_break_box_at(cell)

	elif ac == T_LUCKY:
		if suppress_drop:
			drop_id = ITEM_NONE
		else:
			drop_id = _random_item_id_like_wheel()
			amount = randi_range(LUCKY_MIN_STACK, LUCKY_MAX_STACK)
			pickup_ac = Vector2i(-1, -1)
			pickup_alt = 0
	else:
		if _is_stone_like(ac):
			if not can_harvest:
				drop_id = ITEM_NONE
			else:
				match ac:
					T_IRONSTONE: drop_id = ITEM_RAW_IRON
					T_COALSTONE: drop_id = ITEM_COAL
					T_GOLDSTONE: drop_id = ITEM_RAW_GOLD
					T_YOYLITESTONE: drop_id = ITEM_YOYLITE
					_: drop_id = atlas_to_item_id(ac)
				if drop_id == ITEM_RAW_IRON or drop_id == ITEM_COAL or drop_id == ITEM_RAW_GOLD or drop_id == ITEM_YOYLITE:
					amount = randi_range(1, 4)
					pickup_ac = Vector2i(-1, -1)
					pickup_alt = 0
		else:
			drop_id = atlas_to_item_id(ac)


		if ac == T_BUSH_LEAVES_BERRIES:
			drop_id = ITEM_YOYLEBERRY
			amount = randi_range(1, 4)
			pickup_ac = Vector2i(-1, -1)
			pickup_alt = 0



	if ac == T_DEEP or ac == T_STONE or ac == T_IRONSTONE or ac == T_COALSTONE or ac == T_GOLDSTONE or ac == T_YOYLITESTONE:

		set_cell_override(cell, T_CAVESTONE, 0)

		rpc("cli_set_cell", cell, SRC, T_CAVESTONE)
	else:


		mark_cell_removed(cell)

		rpc("cli_erase_cell", cell)


	var pos: = ground.to_global(ground.map_to_local(cell))
	rpc("cli_spawn_block_particles", pos, ac)
	var mat: = _material_for_ac(ac)
	_broadcast_dig_sound(cell, StringName(mat), pos)


	if ( not suppress_drop) and drop_id != ITEM_NONE and amount > 0:
		var base: = ground.to_global(ground.map_to_local(cell)) + Vector2(randf_range(-6, 6), -10)
		for i in amount:
			var jitter: = Vector2(randf_range(-10, 10), -6)
			_server_spawn_pickup(drop_id, base + jitter, pickup_ac, pickup_alt)


	if _is_mining_tool(selected_item_id):
		if from_id == SERVER_ID:
			cli_damage_selected_tool(1)
		else:
			rpc_id(from_id, "cli_damage_selected_tool", 1)

	_mark_yoylite_dirty(cell)

	return true

const MINING_TOOL_IDS: = {10: true, 12: true, 13: true, 14: true, 15: true, 16: true, 24: true, 25: true, 26: true, 64: true, 65: true, 66: true}
const SWORD_IDS: = {11: true, 17: true, 27: true, 67: true}

func _is_mining_tool(id: int) -> bool: return MINING_TOOL_IDS.has(id)
func _is_sword(id: int) -> bool: return SWORD_IDS.has(id)

@rpc("any_peer", "call_local")
func cli_damage_selected_tool(amount: int) -> void :
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if not hotbar: return

	var s = hotbar.slots[hotbar.selected]
	if s.get("id", 0) != 0 and ToolDurability.is_tool_id(int(s["id"])) and not s.has("meta"):
		s = ToolDurability.ensure_meta(s)
		hotbar.slots[hotbar.selected] = s

	ToolDurability.damage_selected_tool(hotbar, amount)
	hotbar._notify_held_item_changed()

@rpc("any_peer", "reliable")
func srv_spawn_white_gas(pos: Vector2) -> void :
	if not multiplayer.is_server():
		return
	rpc("cli_spawn_white_gas", pos)

@rpc("any_peer", "call_local", "reliable")
func cli_spawn_white_gas(pos: Vector2) -> void :
	spawn_white_gas(pos)

func spawn_white_gas(pos: Vector2) -> void :
	var p: = GPUParticles2D.new()
	p.one_shot = true
	p.lifetime = 1.2
	p.explosiveness = 1.0
	p.amount = 40
	p.fixed_fps = 0
	p.global_position = pos + Vector2(0, -8)

	var mat: = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 120.0
	mat.gravity = Vector3(0, -50, 0)
	mat.initial_velocity_min = 250.0
	mat.initial_velocity_max = 500.0
	mat.scale_min = 3.0
	mat.scale_max = 5.0
	mat.angular_velocity_min = -8.0
	mat.angular_velocity_max = 8.0

	var grad: = Gradient.new()
	grad.colors = [
		Color(1, 1, 1, 0.9), 
		Color(1, 1, 1, 0.6), 
		Color(1, 1, 1, 0.0)
	]
	var ramp: = GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	p.process_material = mat


	var img: = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex: = ImageTexture.create_from_image(img)
	p.texture = tex

	add_child(p)
	p.emitting = true

	await get_tree().create_timer(p.lifetime + 0.2).timeout
	if is_instance_valid(p):
		p.queue_free()

@rpc("call_local")
func cli_spawn_block_particles(pos: Vector2, ac: Vector2i) -> void :
	_spawn_block_particles(pos, ac)

func _spawn_block_particles(pos: Vector2, ac: Vector2i, maxscale: = 3, minscale: = 2, amount: = 32) -> void :
	var p: = GPUParticles2D.new()
	p.one_shot = true
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.amount = amount
	p.emitting = false
	p.fixed_fps = 0
	p.global_position = pos

	var mat: = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, 900.0, 0)
	mat.initial_velocity_min = 220.0
	mat.initial_velocity_max = 360.0
	mat.angular_velocity_min = -12.0
	mat.angular_velocity_max = 12.0
	mat.scale_min = minscale
	mat.scale_max = maxscale


	var c: = _dominant_color_for_ac(ac)
	var ramp: = Gradient.new()
	ramp.colors = [c.lightened(0.25), c, c.darkened(0.25)]
	var ramp_tex: = GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex

	p.process_material = mat


	var img: = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex: = ImageTexture.create_from_image(img)
	p.texture = tex

	add_child(p)
	p.emitting = true

	await get_tree().create_timer(p.lifetime + 0.1).timeout
	if is_instance_valid(p): p.queue_free()




@rpc("any_peer", "reliable")
func srv_spawn_aou_particles(pos: Vector2) -> void :
	if not multiplayer.is_server():
		return

	rpc("cli_spawn_aou_particles", pos)


@rpc("any_peer", "call_local", "reliable")
func cli_spawn_aou_particles(pos: Vector2) -> void :
	_spawn_aou_particles_at(pos)

func _spawn_aou_particles_at(pos: Vector2) -> void :
	var p: = GPUParticles2D.new()
	p.one_shot = true
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.amount = 55
	p.fixed_fps = 0
	p.global_position = pos
	p.z_index = 999

	var mat: = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 100.0
	mat.gravity = Vector3(0, 900, 0)
	mat.initial_velocity_min = 250.0
	mat.initial_velocity_max = 550.0
	mat.scale_min = 2.8
	mat.scale_max = 4.8
	mat.angular_velocity_min = -12.0
	mat.angular_velocity_max = 12.0
	mat.hue_variation_min = -0.03
	mat.hue_variation_max = 0.03
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 12.0


	var g: = Gradient.new()
	g.colors = [
		Color(0.3, 1.0, 0.4, 1.0), 
		Color(0.1, 0.9, 0.2, 1.0), 
		Color(0.8, 1.0, 0.6, 1.0)
	]
	var ramp_tex: = GradientTexture1D.new()
	ramp_tex.gradient = g
	mat.color_ramp = ramp_tex

	p.process_material = mat


	var img: = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex: = ImageTexture.create_from_image(img)
	p.texture = tex

	add_child(p)
	p.emitting = true

	await get_tree().create_timer(p.lifetime + 0.2).timeout
	if is_instance_valid(p):
		p.queue_free()

var _atlas_dominant_cache: = {}
var _atlas_image: Image = null

func _ensure_atlas_image() -> void :
	if _atlas_image != null: return
	var ts: TileSet = ground.tile_set
	var src: = ts.get_source(SRC)

	var tex = src.get_texture() if src.has_method("get_texture") else null
	if tex == null and src.has_method("get_atlas_texture"):
		tex = src.get_atlas_texture()
	if tex != null:
		_atlas_image = tex.get_image()
		_atlas_image.decompress()

func _dominant_color_for_ac(ac: Vector2i) -> Color:
	_ensure_atlas_image()
	if _atlas_image == null:
		return Color(0.8, 0.8, 0.8)

	var key: = "%d,%d" % [ac.x, ac.y]
	if _atlas_dominant_cache.has(key):
		return _atlas_dominant_cache[key]

	var ts: TileSet = ground.tile_set
	var src: = ts.get_source(SRC)

	var rect: Rect2i = src.get_tile_texture_region(ac)
	var step = max(1, rect.size.x / 8)
	var sum: = Vector3(0, 0, 0)
	var count: = 0

	for y in range(rect.position.y, rect.position.y + rect.size.y, step):
		for x in range(rect.position.x, rect.position.x + rect.size.x, step):
			var col: = _atlas_image.get_pixel(x, y)
			if col.a < 0.1: continue
			sum.x += col.r
			sum.y += col.g
			sum.z += col.b
			count += 1

	var c: = Color(sum.x / count, sum.y / count, sum.z / count, 1.0) if count > 0 else Color(0.8, 0.8, 0.8)
	_atlas_dominant_cache[key] = c
	return c

func _broadcast_dig_sound(cell: Vector2i, mat: StringName, pos: Vector2, hear_radius_px: float = 1200.0) -> void :
	for pid in players.keys():
		var listener_pos: Vector2


		if _spectate_target_of.has(pid):
			var tpid: = int(_spectate_target_of[pid])
			if players.has(tpid) and is_instance_valid(players[tpid]):
				listener_pos = (players[tpid] as Node2D).global_position
			else:

				_spectate_target_of.erase(pid)
				listener_pos = (players[pid] as Node2D).global_position
		else:
			listener_pos = (players[pid] as Node2D).global_position

		if pos.distance_to(listener_pos) <= hear_radius_px:
			rpc_id(pid, "cli_play_dig_material", String(mat), pos)

func _server_place_cell(cell: Vector2i, tile: Vector2i, from_id: int, source_slot: Dictionary = {}) -> bool:
	var p = players.get(from_id, null)
	if p == null: return false

	var player_cell: = ground.local_to_map(ground.to_local((p as Node2D).global_position))
	if _chebyshev(cell, player_cell) > BREAK_REACH_CELLS: return false

	var src: = ground.get_cell_source_id(cell)
	var ac: = ground.get_cell_atlas_coords(cell)

	if not (src == -1 or (src == SRC and (ac == T_CAVESTONE or ac == T_WATER or ac in T_PISTON_EXTENDER_FACES))):
		return false

	if tile == T_YOYLE_CRYSTAL:
		var below: = cell + Vector2i(0, 1)
		var ok: = (ground.get_cell_source_id(below) == SRC
			&& ground.get_cell_atlas_coords(below) == T_STONE)
		if not ok:
			return false


	set_cell_override(cell, tile, 0)

	rpc("cli_set_cell", cell, SRC, tile)


	var mat: = _material_for_ac(tile)
	var pos: = ground.to_global(ground.map_to_local(cell))
	_broadcast_dig_sound(cell, StringName(mat), pos)


	if tile == T_YOYLITE_BOX:
		place_yoylite_box(cell, source_slot)


	_mark_yoylite_dirty(cell)


	var placed_ac: = ground.get_cell_atlas_coords(cell)
	if placed_ac in T_PISTON_FACES or placed_ac in T_STRINGY_PISTON_FACES:
		_piston_last_power.erase(cell)


		var facing: = _piston_facing_dir(placed_ac)
		if _piston_is_powered(cell, facing) and not _is_extender(cell + facing):
			_piston_try_extend_and_push(cell, facing)


	return true

var build_mode: = false

func _input(e: InputEvent) -> void :
	if e is InputEventKey and e.pressed and not e.echo:

		if _cmd_box and _cmd_box.visible and _cmd_box.has_focus():
			if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
				_on_cmd_submit(_cmd_box.text)
				_cmd_box.accept_event()
				get_viewport().set_input_as_handled()
				return
			if e.keycode == KEY_ESCAPE:
				close_command_box()
				get_viewport().set_input_as_handled()
				return
			return


		if e.is_action_pressed("open_command"):
			open_command_box(true)
			get_viewport().set_input_as_handled()
			return
		if e.is_action_pressed("open_chat"):
			open_command_box(false)
			get_viewport().set_input_as_handled()
			return


	if _cmd_box and _cmd_box.visible:
		return


	if e.is_action_pressed("toggle_build"):
		build_mode = !build_mode
		if build_mode:
			_break_progress.clear()
			mining.playing = false


func _unhandled_input(e: InputEvent) -> void :
	if _ui_modal_open: return


	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		var cell: = ground.local_to_map(ground.to_local(get_global_mouse_position()))
		if _is_anchor_cell(cell):
			var selected_item_id: = 0
			var selected_count: = 0
			var hb: = $CanvasLayer / itembar
			if hb and hb.selected >= 0 and hb.selected < hb.slots.size():
				var s = hb.slots[hb.selected]
				selected_item_id = int(s.get("id", 0))
				selected_count = int(s.get("count", 0))

			if multiplayer.is_server():
				srv_request_anchor_click(cell, selected_item_id, selected_count)
			else:
				rpc_id(SERVER_ID, "srv_request_anchor_click", cell, selected_item_id, selected_count)

			get_viewport().set_input_as_handled()
			return

		if _is_piston_cell(cell) or _is_stringy_piston(cell):
			if multiplayer.is_server():
				srv_request_piston_click(cell)
			else:
				rpc_id(SERVER_ID, "srv_request_piston_click", cell, )

			get_viewport().set_input_as_handled()


		if _is_lever(cell):
			if multiplayer.is_server():
				srv_request_lever_click(cell)
			else:
				rpc_id(SERVER_ID, "srv_request_lever_click", cell)

			get_viewport().set_input_as_handled()
			return

		if _is_delayer(cell):
			if multiplayer.is_server():
				srv_request_delayer_click(cell)
			else:
				rpc_id(SERVER_ID, "srv_request_delayer_click", cell, )

			get_viewport().set_input_as_handled()


	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var hb: = $CanvasLayer / itembar
		if hb and hb.selected >= 0 and hb.selected < hb.slots.size():
			var s = hb.slots[hb.selected]
			if int(s.get("id", 0)) == ITEM_YOYLITE_PEARL:
				var click_world: = get_global_mouse_position()
				var pid: = multiplayer.get_unique_id()
				if players.has(pid):
					_play_sfx_at(THROW, players[pid].global_position, 10)
				_request_throw_pearl(click_world)
				get_viewport().set_input_as_handled()
				return


	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		if _selected_item_id() == ITEM_LIGHTER:
			var cell: = ground.local_to_map(ground.to_local(get_global_mouse_position()))
			if ground.get_cell_source_id(cell) == SRC and ground.get_cell_atlas_coords(cell) == T_DYNAMITE:
				if multiplayer.is_server():
					_server_request_ignite(SERVER_ID, cell, ITEM_LIGHTER)
				else:
					rpc_id(SERVER_ID, "srv_request_ignite_dynamite", cell, ITEM_LIGHTER)
				get_viewport().set_input_as_handled()
				return


	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		var cell: = ground.local_to_map(ground.to_local(get_global_mouse_position()))
		if ground.get_cell_source_id(cell) == SRC and ground.get_cell_atlas_coords(cell) == T_YOYLE_CRYSTAL:
			if multiplayer.is_server():
				_server_request_explode_crystal(SERVER_ID, cell)
			else:
				rpc_id(SERVER_ID, "srv_request_explode_crystal", cell)
			get_viewport().set_input_as_handled()
			return

func item_id_to_atlas(id: int, x: int, y: int) -> Vector2i:
	match id:
		ITEM_GRASS: return _variant_at(x, y, T_SURFACE_VARIANTS)
		ITEM_DIRT: return T_DEEP
		ITEM_STONE: return T_STONE
		ITEM_LOG: return T_LOG
		ITEM_LEAVES: return T_LEAVES
		ITEM_CRAFT: return T_CRAFT
		ITEM_IRON_STONE: return T_IRONSTONE
		ITEM_COAL_STONE: return T_COALSTONE
		ITEM_GOLD_STONE: return T_GOLDSTONE
		ITEM_YOYLITE_STONE: return T_YOYLITESTONE
		ITEM_OVEN: return T_OVEN
		ITEM_SNOW: return _variant_at(x, y, T_SURFACE_VARIANTS_SNOW)
		ITEM_DARK_LOG: return T_DARK_LOG
		ITEM_DARK_LEAVES: return T_DARK_LEAVES
		ITEM_DARK_GRASS: return _variant_at(x, y, T_SURFACE_VARIANTS_DARK)
		ITEM_SAND: return _variant_at(x, y, T_SURFACE_VARIANTS_SAND)
		ITEM_CACTUS: return T_CACTUS
		ITEM_DYNAMITE: return T_DYNAMITE
		ITEM_YOYLE_GRASS: return _variant_at(x, y, T_SURFACE_VARIANTS_YOYLE)
		ITEM_YOYLE_LOG: return T_YOYLE_LOG
		ITEM_YOYLE_LEAVES: return T_YOYLE_LEAVES
		ITEM_BUSH_LOG: return T_BUSH_LOG
		ITEM_BUSH_LEAVES: return T_BUSH_LEAVES
		ITEM_BUSH_LEAVES_BERRIES: return T_BUSH_LEAVES_BERRIES
		ITEM_BLUE_CONCRETE: return T_BLUE_CONCRETE
		ITEM_YELLOW_CONCRETE: return T_YELLOW_CONCRETE
		ITEM_PURPLE_CONCRETE: return T_PURPLE_CONCRETE
		ITEM_RED_CONCRETE: return T_RED_CONCRETE
		ITEM_GREEN_CONCRETE: return T_GREEN_CONCRETE
		ITEM_BROWN_CONCRETE: return T_BROWN_CONCRETE
		ITEM_WHITE_CONCRETE: return T_WHITE_CONCRETE
		ITEM_WINDOW: return T_WINDOW
		ITEM_POLE: return T_POLE
		ITEM_SPHERE: return T_SPHERE
		ITEM_STRIPE: return T_STRIPE
		ITEM_PLATFORM: return T_PLATFORM
		ITEM_YOYLE_CRYSTAL: return T_YOYLE_CRYSTAL
		ITEM_VICTORY: return T_VICTORY
		ITEM_LUCKY: return T_LUCKY
		ITEM_YOYLITE_BOX: return T_YOYLITE_BOX
		ITEM_YOYLITE_ANCHOR_0: return T_YOYLITE_ANCHOR_0
		ITEM_YOYLITE_ANCHOR_1: return T_YOYLITE_ANCHOR_1
		ITEM_YOYLITE_ANCHOR_2: return T_YOYLITE_ANCHOR_2
		ITEM_YOYLITE_ANCHOR_3: return T_YOYLITE_ANCHOR_3
		ITEM_YOYLITE_ANCHOR_4: return T_YOYLITE_ANCHOR_4
		ITEM_YOYLITE_WIRE: return T_YOYLITE_WIRE_OFF
		ITEM_PISTON: return T_PISTON_RIGHT
		ITEM_STRINGY_PISTON: return T_STRINGY_PISTON_RIGHT
		ITEM_YOYLITE_EMITTER: return T_YOYLITE_EMITTER_ON
		ITEM_LEVER: return T_LEVER_OFF
		ITEM_PISITON_EXTENDER: return T_PISTON_EXTENDER_RIGHT
		ITEM_YOYLITE_DELAYER: return T_YOYLITE_DELAYER_1_OFF
		ITEM_STRING_BLOCK: return T_STRING_BLOCK

		ITEM_CAKE: return Vector2i(-1, -1)
		_: return Vector2i(-1, -1)

func _within_reach(cell: Vector2i) -> bool:
	var pc: = ground.local_to_map(ground.to_local(local_player.global_position))
	return _chebyshev(cell, pc) <= BREAK_REACH_CELLS

func _can_place_at(cell: Vector2i) -> bool:
	if not _within_reach(cell):
		return false
	if not _cell_is_build_target(cell):
		return false


	var offsets: = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for o in offsets:
		if ground.get_cell_source_id(cell + o) != -1:
			return true
	return false


func _cell_is_build_target(cell: Vector2i) -> bool:

	var src_id: = ground.get_cell_source_id(cell)
	if src_id == -1:
		return true

	if src_id == SRC and ground.get_cell_atlas_coords(cell) == T_CAVESTONE:
		return true
	return false

func _place_block_at_cell(cell: Vector2i) -> bool:
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar == null: return false
	var item_id: = int(hotbar.call("get_selected_item_id"))
	if item_id == ITEM_NONE: return false
	if not _can_place_at(cell): return false

	if item_id == ITEM_YOYLE_CRYSTAL:
		var below: = cell + Vector2i(0, 1)
		var ok: = (ground.get_cell_source_id(below) == SRC
			&& ground.get_cell_atlas_coords(below) == T_STONE)
		if not ok:
			return false

	var ac: = item_id_to_atlas(item_id, cell.x, cell.y)
	if ac.x < 0: return false

	var took: = int(hotbar.call("consume_selected", 1))
	if took <= 0: return false

	if not _is_painted_locked(cell):
		ground.set_cell(cell, SRC, ac)
	cell_overrides[cell] = ac
	removed_cells.erase(cell)


	var pos: = ground.to_global(ground.map_to_local(cell))
	var mat: = _material_for_ac(ac)
	_broadcast_mined_sound(StringName(mat), pos)
	return true


func atlas_to_item_id(ac: Vector2i) -> int:

	for v in T_SURFACE_VARIANTS:
		if ac == v or ac == T_MID:
			return ITEM_GRASS

	if ac == T_DEEP:
		return ITEM_DIRT

	if ac == T_STONE:
		return ITEM_STONE

	if ac == T_LOG:
		return ITEM_LOG

	if ac == T_LEAVES:
		return ITEM_LEAVES

	if ac == T_CRAFT:
		return ITEM_CRAFT

	if ac == T_IRONSTONE:
		return ITEM_IRON_STONE

	if ac == T_COALSTONE:
		return ITEM_COAL_STONE

	if ac == T_GOLDSTONE:
		return ITEM_GOLD_STONE

	if ac == T_YOYLITESTONE:
		return ITEM_YOYLITE_STONE

	if ac == T_OVEN:
		return ITEM_OVEN

	for v in T_SURFACE_VARIANTS_SNOW:
		if ac == v or ac == T_MID_SNOW:
			return ITEM_SNOW

	if ac == T_DARK_LOG:
		return ITEM_DARK_LOG

	if ac == T_DARK_LEAVES:
		return ITEM_DARK_LEAVES

	for v in T_SURFACE_VARIANTS_DARK:
		if ac == v or ac == T_MID_DARK:
			return ITEM_DARK_GRASS

	for v in T_SURFACE_VARIANTS_SAND:
		if ac == v or ac == T_MID_DARK:
			return ITEM_SAND

	if ac == T_MID_SAND:
		return ITEM_SAND

	if ac == T_CACTUS:
		return ITEM_CACTUS

	if ac == T_DYNAMITE:
		return ITEM_DYNAMITE

	for v in T_SURFACE_VARIANTS_YOYLE:
		if ac == v or ac == T_MID_YOYLE:
			return ITEM_YOYLE_GRASS

	if ac == T_YOYLE_LOG:
		return ITEM_YOYLE_LOG

	if ac == T_YOYLE_LEAVES:
		return ITEM_YOYLE_LEAVES

	if ac == T_BUSH_LOG:
		return ITEM_BUSH_LOG

	if ac == T_BUSH_LEAVES:
		return ITEM_BUSH_LEAVES

	if ac == T_BUSH_LEAVES_BERRIES:
		return ITEM_BUSH_LEAVES_BERRIES

	if ac == T_BLUE_CONCRETE:
		return ITEM_BLUE_CONCRETE

	if ac == T_YELLOW_CONCRETE:
		return ITEM_YELLOW_CONCRETE

	if ac == T_PURPLE_CONCRETE:
		return ITEM_PURPLE_CONCRETE

	if ac == T_RED_CONCRETE:
		return ITEM_RED_CONCRETE

	if ac == T_GREEN_CONCRETE:
		return ITEM_GREEN_CONCRETE

	if ac == T_BROWN_CONCRETE:
		return ITEM_BROWN_CONCRETE

	if ac == T_WHITE_CONCRETE:
		return ITEM_WHITE_CONCRETE

	if ac == T_WINDOW:
		return ITEM_WINDOW

	if ac == T_POLE:
		return ITEM_POLE

	if ac == T_SPHERE:
		return ITEM_SPHERE

	if ac == T_STRIPE:
		return ITEM_STRIPE

	if ac == T_PLATFORM:
		return ITEM_PLATFORM

	if ac == T_YOYLE_CRYSTAL:
		return ITEM_YOYLE_CRYSTAL

	if ac == T_VICTORY:
		return ITEM_VICTORY

	if ac == T_LUCKY:
		return ITEM_LUCKY

	if ac == T_YOYLITE_BOX:
		return ITEM_YOYLITE_BOX

	if ac == T_YOYLITE_ANCHOR_0:
		return ITEM_YOYLITE_ANCHOR_0

	if ac == T_YOYLITE_ANCHOR_1:
		return ITEM_YOYLITE_ANCHOR_1

	if ac == T_YOYLITE_ANCHOR_2:
		return ITEM_YOYLITE_ANCHOR_2

	if ac == T_YOYLITE_ANCHOR_3:
		return ITEM_YOYLITE_ANCHOR_3

	if ac == T_YOYLITE_ANCHOR_4:
		return ITEM_YOYLITE_ANCHOR_4

	if ac in T_YOYLITE_WIRE_STATE:
		return ITEM_YOYLITE_WIRE

	if ac in T_PISTON_FACES:
		return ITEM_PISTON

	if ac in T_STRINGY_PISTON_FACES:
		return ITEM_STRINGY_PISTON

	if ac in T_YOYLITE_EMITTER_STATE:
		return ITEM_YOYLITE_EMITTER

	if ac in T_LEVER_STATE:
		return ITEM_LEVER

	if ac in T_PISTON_EXTENDER_FACES:
		return ITEM_PISITON_EXTENDER

	if ac in T_YOYLITE_DELAYER_TICK:
		return ITEM_YOYLITE_DELAYER

	if ac == T_STRING_BLOCK:
		return ITEM_STRING_BLOCK

	return ITEM_NONE


func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(world_pos))

func _cell_to_world_top_left(cell: Vector2i) -> Vector2:

	var in_ground: = ground.map_to_local(cell)
	var world: = ground.to_global(in_ground)
	return to_local(world)

func _texture_from_cell(cell: Vector2i) -> Texture2D:
	if ground.get_cell_source_id(cell) == -1:
		return null

	var td: TileData = ground.get_cell_tile_data(cell)
	if td == null:
		print_debug("[_texture_from_cell] No TileData at ", cell)
		return null


	var base_tex: Texture2D = td.get_texture(0)
	if base_tex == null:
		print_debug("[_texture_from_cell] Tile has no texture at layer 0: ", cell)
		return null


	var reg: Rect2i = td.get_region(0)
	if reg.size.x > 0 and reg.size.y > 0:
		var at: = AtlasTexture.new()
		at.atlas = base_tex
		at.region = Rect2(reg.position, reg.size)
		return at


	return base_tex


func _texture_from_atlas(src_id: int, ac: Vector2i, _alt: int) -> Texture2D:
	var src: = ground.tile_set.get_source(src_id)
	if !(src is TileSetAtlasSource):
		return null
	var atlas_src: = src as TileSetAtlasSource
	var base_tex: Texture2D = atlas_src.texture
	if base_tex == null:
		return null

	var region: Rect2i = atlas_src.get_tile_texture_region(ac, 0)


	var whole: = base_tex.get_size()
	if region.size.x <= 0 or region.size.y <= 0 or Vector2i(region.size) == Vector2i(whole):
		region = atlas_src.get_tile_texture_region(ac, 0)

	var at: = AtlasTexture.new()
	at.atlas = base_tex
	at.region = Rect2(region.position, region.size)

	at.filter_clip = true
	return at

func _cell_texture(cell: Vector2i) -> Texture2D:
	var src_id: = ground.get_cell_source_id(cell)
	if src_id == -1:
		return null

	var ac: = ground.get_cell_atlas_coords(cell)
	var alt: = ground.get_cell_alternative_tile(cell)

	var ts: TileSet = ground.tile_set
	if ts == null:
		return null

	var src: = ts.get_source(src_id)
	if !(src is TileSetAtlasSource):

		return null

	var atlas_src: = src as TileSetAtlasSource
	var base_tex: Texture2D = atlas_src.texture
	if base_tex == null:
		return null

	var region: Rect2i = atlas_src.get_tile_texture_region(ac, alt)
	if region.size.x <= 0 or region.size.y <= 0:

		return null

	var at: = AtlasTexture.new()
	at.atlas = base_tex
	at.region = Rect2(region.position, region.size)
	return at


func _break_cell(cell: Vector2i) -> bool:

	if ground.get_cell_source_id(cell) != SRC:
		return false
	var ac: = ground.get_cell_atlas_coords(cell)
	if ac == T_CAVESTONE or ac == T_WATER or ac in T_PISTON_EXTENDER_FACES:
		return false
	var src_id: = ground.get_cell_source_id(cell)
	var alt: = ground.get_cell_alternative_tile(cell)
	print_debug("[break] src=", src_id, " ac=", ac, " alt=", alt)


	var drop_id: = atlas_to_item_id(ac)
	var amount: = 1
	var tex_for_pickup: Texture2D = _cell_texture(cell)


	if ac == T_IRONSTONE:
		drop_id = ITEM_RAW_IRON
		amount = randi_range(1, 4)
		tex_for_pickup = null
	elif ac == T_GOLDSTONE:
		drop_id = ITEM_RAW_GOLD
		amount = randi_range(1, 4)
		tex_for_pickup = null
	elif ac == T_COALSTONE:
		drop_id = ITEM_COAL
		amount = randi_range(1, 4)
		tex_for_pickup = null
	elif ac == T_YOYLITESTONE:
		drop_id = ITEM_YOYLITE
		amount = randi_range(1, 4)
		tex_for_pickup = null
	elif ac == T_BUSH_LEAVES_BERRIES:
		drop_id = ITEM_YOYLEBERRY
		amount = randi_range(1, 4)
		tex_for_pickup = null


	if drop_id != ITEM_NONE:
		var wp: = ground.to_global(ground.map_to_local(cell)) + Vector2(randf_range(-6, 6), -10)
		spawn_pickup_for_item(drop_id, wp, amount, true, tex_for_pickup)



	if ac == T_DEEP or ac == T_STONE:
		ground.set_cell(cell, SRC, T_CAVESTONE)
		cell_overrides[cell] = T_CAVESTONE
		removed_cells.erase(cell)
	else:
		ground.erase_cell(cell)
		removed_cells[cell] = true
		cell_overrides.erase(cell)

	var mat: = _material_for_ac(ac)
	var pos: = ground.to_global(ground.map_to_local(cell))
	_broadcast_mined_sound(StringName(mat), pos)
	return true

func _broadcast_mined_sound(mat: StringName, pos: Vector2, hear_radius_px: float = 1200.0) -> void :
	for pid in players.keys():
		var p = players[pid]
		if not is_instance_valid(p): continue
		if pos.distance_to(p.global_position) <= hear_radius_px:
			rpc_id(pid, "cli_play_mined_material", String(mat), pos)


func spawn_pickup_for_item(id: int, world_pos: Vector2, amount: int = 1, kick: bool = false, tex: Texture2D = null) -> void :
	if id == 0 or amount <= 0:
		return
	var p: = pickup_scene.instantiate()
	p.item_id = id
	p.count = amount
	p.global_position = world_pos


	if tex == null:
		var hotbar: = get_tree().get_first_node_in_group("hotbar")
		if hotbar:
			var known_tex: Texture2D = hotbar.icon_by_item.get(id, null)
			if known_tex:
				tex = known_tex

	if tex != null:
		p.texture = tex

	pickup_layer.add_child(p)
	if kick and p.has_method("apply_kick"):
		p.apply_kick()

func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

func _cell_is_breakable(cell: Vector2i) -> bool:
	if _protected_cells.has(cell):
		return false
	if ground.get_cell_source_id(cell) == -1: return false
	if ground.get_cell_source_id(cell) != SRC: return false
	var ac: = ground.get_cell_atlas_coords(cell)
	return ac != T_CAVESTONE and ac != T_WATER and ac not in T_PISTON_EXTENDER_FACES


func _try_break_at_world(world_pos: Vector2) -> bool:
	var cell: = _world_to_cell(world_pos)
	var sel: = _selected_hotbar_item()
	if multiplayer.is_server():
		return _server_break_cell(cell, multiplayer.get_unique_id(), sel)
	else:
		rpc_id(1, "srv_request_break", cell, sel)
		return true

func _icon_from_cell(cell: Vector2i) -> Texture2D:
	var src_id: = ground.get_cell_source_id(cell)
	if src_id == -1:
		return null

	var ac: = ground.get_cell_atlas_coords(cell)
	var alt: = ground.get_cell_alternative_tile(cell)
	var src: = ground.tile_set.get_source(src_id)


	if src is TileSetAtlasSource:
		var atlas_src: = src as TileSetAtlasSource
		var base_tex: Texture2D = atlas_src.texture
		var region: Rect2i = atlas_src.get_tile_texture_region(ac, alt)

		var at: = AtlasTexture.new()
		at.atlas = base_tex
		at.region = Rect2(region.position, region.size)
		return at


	return null



const T_SURFACE_VARIANTS: Array[Vector2i] = [
	Vector2i(0, 0), 
	Vector2i(1, 0), 
	Vector2i(2, 0), 
	Vector2i(3, 0), 
	Vector2i(4, 0)
]
const T_MID: = Vector2i(4, 0)
const T_DEEP: = Vector2i(0, 1)
const T_STONE: = Vector2i(2, 1)
const T_CAVESTONE: = Vector2i(1, 1)
const T_LOG: = Vector2i(3, 1)
const T_LEAVES: = Vector2i(4, 1)
const T_CRAFT: = Vector2i(0, 2)
const T_IRONSTONE: = Vector2i(1, 2)
const T_COALSTONE: = Vector2i(2, 2)
const T_GOLDSTONE: = Vector2i(5, 0)
const T_YOYLITESTONE: = Vector2i(5, 7)
const T_OVEN: = Vector2i(3, 2)

const T_SURFACE_VARIANTS_SNOW: Array[Vector2i] = [
	Vector2i(4, 2), 
	Vector2i(0, 3), 
	Vector2i(1, 3), 
	Vector2i(2, 3)
]

const T_MID_SNOW: = Vector2i(2, 3)
const T_DARK_LOG: = Vector2i(3, 3)
const T_DARK_LEAVES: = Vector2i(4, 3)
const ALT_DARK_LOG: = 2

const T_SURFACE_VARIANTS_DARK: Array[Vector2i] = [
	Vector2i(0, 4), 
	Vector2i(1, 4), 
	Vector2i(2, 4), 
	Vector2i(3, 4)
]

const T_MID_DARK: = Vector2i(3, 4)

const T_SURFACE_VARIANTS_SAND: Array[Vector2i] = [
	Vector2i(4, 4), 
	Vector2i(0, 5), 
	Vector2i(1, 5), 
	Vector2i(2, 5)
]

const T_MID_SAND: = Vector2i(2, 5)
const T_CACTUS: = Vector2i(3, 5)
const ALT_CACTUS: = 3

const T_WATER: = Vector2i(4, 5)

const T_DYNAMITE: = Vector2i(0, 6)

const T_SURFACE_VARIANTS_YOYLE: Array[Vector2i] = [
	Vector2i(6, 0), 
	Vector2i(5, 1), 
	Vector2i(6, 1), 
	Vector2i(5, 2), 
	Vector2i(6, 2)
]

const T_MID_YOYLE: = Vector2i(6, 2)
const T_YOYLE_LOG: = Vector2i(5, 3)
const T_YOYLE_LEAVES: = Vector2i(6, 3)
const T_BUSH_LOG: = Vector2i(5, 4)
const T_BUSH_LEAVES: = Vector2i(6, 4)
const T_BUSH_LEAVES_BERRIES: = Vector2i(5, 5)
const T_YOYLE_CRYSTAL: = Vector2i(6, 7)

const T_BLUE_CONCRETE: = Vector2i(6, 5)
const T_YELLOW_CONCRETE: = Vector2i(1, 6)
const T_PURPLE_CONCRETE: = Vector2i(2, 6)
const T_RED_CONCRETE: = Vector2i(3, 6)
const T_GREEN_CONCRETE: = Vector2i(4, 6)
const T_BROWN_CONCRETE: = Vector2i(5, 6)
const T_WHITE_CONCRETE: = Vector2i(6, 6)
const T_WINDOW: = Vector2i(0, 7)

const T_POLE: = Vector2i(1, 7)
const T_SPHERE: = Vector2i(2, 7)
const T_STRIPE: = Vector2i(3, 7)
const T_PLATFORM: = Vector2i(4, 7)

const ALT_YOYLE_LOG: = 4
const ALT_BUSH_LOG: = 5
const ALT_BLUE_CONCRETE: = 6
const ALT_YELLOW_CONCRETE: = 7
const ALT_PURPLE_CONCRETE: = 8
const ALT_RED_CONCRETE: = 9
const ALT_GREEN_CONCRETE: = 10
const ALT_BROWN_CONCRETE: = 11
const ALT_WHITE_CONCRETE: = 12
const ALT_WINDOW: = 13
const ALT_POLE: = 14

const T_VICTORY: = Vector2i(7, 0)
const T_LUCKY: = Vector2i(7, 1)
const T_YOYLITE_BOX: = Vector2i(7, 2)

const T_YOYLITE_ANCHOR_PHASES: = [
	T_YOYLITE_ANCHOR_0, 
	T_YOYLITE_ANCHOR_1, 
	T_YOYLITE_ANCHOR_2, 
	T_YOYLITE_ANCHOR_3, 
	T_YOYLITE_ANCHOR_4
]

const T_YOYLITE_ANCHOR_0: = Vector2i(7, 3)
const T_YOYLITE_ANCHOR_1: = Vector2i(7, 4)
const T_YOYLITE_ANCHOR_2: = Vector2i(7, 5)
const T_YOYLITE_ANCHOR_3: = Vector2i(7, 6)
const T_YOYLITE_ANCHOR_4: = Vector2i(7, 7)

const T_PISTON_FACES: = [
	T_PISTON_RIGHT, 
	T_PISTON_UP, 
	T_PISTON_LEFT, 
	T_PISTON_DOWN
]

const T_PISTON_RIGHT: = Vector2i(8, 2)
const T_PISTON_LEFT: = Vector2i(0, 8)
const T_PISTON_UP: = Vector2i(1, 8)
const T_PISTON_DOWN: = Vector2i(2, 8)

const T_STRINGY_PISTON_FACES: = [
	T_STRINGY_PISTON_RIGHT, 
	T_STRINGY_PISTON_UP, 
	T_STRINGY_PISTON_LEFT, 
	T_STRINGY_PISTON_DOWN
]

const T_STRINGY_PISTON_RIGHT: = Vector2i(8, 3)
const T_STRINGY_PISTON_LEFT: = Vector2i(3, 8)
const T_STRINGY_PISTON_UP: = Vector2i(4, 8)
const T_STRINGY_PISTON_DOWN: = Vector2i(5, 8)

const T_PISTON_EXTENDER_FACES: = [
	T_PISTON_EXTENDER_RIGHT, 
	T_PISTON_EXTENDER_UP, 
	T_PISTON_EXTENDER_LEFT, 
	T_PISTON_EXTENDER_DOWN
]

const T_PISTON_EXTENDER_RIGHT: = Vector2i(8, 4)
const T_PISTON_EXTENDER_LEFT: = Vector2i(6, 8)
const T_PISTON_EXTENDER_UP: = Vector2i(7, 8)
const T_PISTON_EXTENDER_DOWN: = Vector2i(8, 8)

const T_YOYLITE_WIRE_STATE: = [
	T_YOYLITE_WIRE_OFF, 
	T_YOYLITE_WIRE_ON
]

const T_YOYLITE_EMITTER_STATE: = [
	T_YOYLITE_EMITTER_OFF, 
	T_YOYLITE_EMITTER_ON
]

const T_YOYLITE_WIRE_OFF: = Vector2i(8, 0)
const T_YOYLITE_WIRE_ON: = Vector2i(8, 1)
const T_YOYLITE_EMITTER_OFF: = Vector2i(9, 0)
const T_YOYLITE_EMITTER_ON: = Vector2i(8, 5)

const T_LEVER_STATE: = [
	T_LEVER_OFF, 
	T_LEVER_ON
]

const T_LEVER_OFF: = Vector2i(8, 6)
const T_LEVER_ON: = Vector2i(8, 7)

const T_YOYLITE_DELAYER_TICK: = [
	T_YOYLITE_DELAYER_1_OFF, 
	T_YOYLITE_DELAYER_2_OFF, 
	T_YOYLITE_DELAYER_3_OFF, 
	T_YOYLITE_DELAYER_4_OFF, 
	T_YOYLITE_DELAYER_1_ON, 
	T_YOYLITE_DELAYER_2_ON, 
	T_YOYLITE_DELAYER_3_ON, 
	T_YOYLITE_DELAYER_4_ON
]

const T_YOYLITE_DELAYER_1_OFF: = Vector2i(9, 5)
const T_YOYLITE_DELAYER_2_OFF: = Vector2i(9, 6)
const T_YOYLITE_DELAYER_3_OFF: = Vector2i(9, 7)
const T_YOYLITE_DELAYER_4_OFF: = Vector2i(9, 8)
const T_YOYLITE_DELAYER_1_ON: = Vector2i(9, 1)
const T_YOYLITE_DELAYER_2_ON: = Vector2i(9, 2)
const T_YOYLITE_DELAYER_3_ON: = Vector2i(9, 3)
const T_YOYLITE_DELAYER_4_ON: = Vector2i(9, 4)

const T_STRING_BLOCK: = Vector2i(0, 9)

func _apply_snowy_overlays_for_chunk(cc: Vector2i) -> void :
	var surf: = _surface_y_map_for_chunk(cc)
	var rng: = _rng_for_chunk("snowy", cc)
	var x0: = cc.x * CHUNK_SIZE
	const KEEP_MID_LAYERS: = 1

	for lx in range(0, CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var c_surface: = Vector2i(x, y0)


		var surface_edited: = removed_cells.has(c_surface) or cell_overrides.has(c_surface)


		if not surface_edited:
			var idx: = rng.randi_range(0, T_SURFACE_VARIANTS_SNOW.size() - 1)
			ground.set_cell(c_surface, SRC, T_SURFACE_VARIANTS_SNOW[idx])


		var mids: Array[int] = []
		var y: = y0 + 1
		while true:
			var c: = Vector2i(x, y)


			if removed_cells.has(c) or cell_overrides.has(c):
				y += 1
				continue


			if ground.get_cell_source_id(c) != SRC:
				break

			var ac: = ground.get_cell_atlas_coords(c)
			if ac != T_MID:
				break

			mids.append(y)
			y += 1

		var keep = min(KEEP_MID_LAYERS, mids.size())
		for i in range(0, mids.size() - keep):
			var cy: = Vector2i(x, mids[i])
			ground.set_cell(cy, SRC, T_MID_SNOW)

func _apply_evil_overlays_for_chunk(cc: Vector2i) -> void :
	var surf: = _surface_y_map_for_chunk(cc)
	var rng: = _rng_for_chunk("evil", cc)
	var x0: = cc.x * CHUNK_SIZE

	for lx in range(0, CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))


		var c_surface: = Vector2i(x, y0)
		var surface_edited: = removed_cells.has(c_surface) or cell_overrides.has(c_surface)
		if not surface_edited:
			var idx: = rng.randi_range(0, T_SURFACE_VARIANTS_DARK.size() - 1)
			ground.set_cell(c_surface, SRC, T_SURFACE_VARIANTS_DARK[idx])


		var y: = y0 + 1
		while true:
			var c: = Vector2i(x, y)


			if removed_cells.has(c) or cell_overrides.has(c):
				y += 1
				continue

			if ground.get_cell_source_id(c) != SRC:
				break

			var ac: = ground.get_cell_atlas_coords(c)
			if ac != T_MID:
				break

			ground.set_cell(c, SRC, T_MID_DARK)
			y += 1





func _apply_desert_overlays_for_chunk(cc: Vector2i) -> void :
	var surf: = _surface_y_map_for_chunk(cc)
	var rng: = _rng_for_chunk("desert", cc)
	var x0: = cc.x * CHUNK_SIZE

	for lx in range(0, CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))


		var c_surface: = Vector2i(x, y0)
		var surface_edited: = removed_cells.has(c_surface) or cell_overrides.has(c_surface)
		if not surface_edited:
			var idx: = rng.randi_range(0, T_SURFACE_VARIANTS_SAND.size() - 1)
			ground.set_cell(c_surface, SRC, T_SURFACE_VARIANTS_SAND[idx])


		var y: = y0 + 1
		while true:
			var c: = Vector2i(x, y)


			if removed_cells.has(c) or cell_overrides.has(c):
				y += 1
				continue

			if ground.get_cell_source_id(c) != SRC:
				break

			var ac: = ground.get_cell_atlas_coords(c)
			if ac != T_MID:
				break

			ground.set_cell(c, SRC, T_MID_SAND)
			y += 1


func _apply_yoyle_overlays_for_chunk(cc: Vector2i) -> void :
	var surf: = _surface_y_map_for_chunk(cc)
	var rng: = _rng_for_chunk("yoyle", cc)
	var x0: = cc.x * CHUNK_SIZE

	for lx in range(0, CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var c_surface: = Vector2i(x, y0)


		var surface_edited: = removed_cells.has(c_surface) or cell_overrides.has(c_surface)
		if not surface_edited:
			var idx: = rng.randi_range(0, T_SURFACE_VARIANTS_YOYLE.size() - 1)
			ground.set_cell(c_surface, SRC, T_SURFACE_VARIANTS_YOYLE[idx])


		var y: = y0 + 1
		while true:
			var c: = Vector2i(x, y)


			if removed_cells.has(c) or cell_overrides.has(c):
				y += 1
				continue

			if ground.get_cell_source_id(c) != SRC:
				break

			var ac: = ground.get_cell_atlas_coords(c)
			if ac != T_MID:
				break

			ground.set_cell(c, SRC, T_MID_YOYLE)
			y += 1

func _yoylemountain_profile_u(world_x: int) -> float:
	var mleft: = _yoylemountain_left_threshold()
	var total: = YOYLE_MTN_WIDTH_CHUNKS * CHUNK_SIZE
	var offset = clamp(world_x - mleft * CHUNK_SIZE, 0, total - 1)
	return float(offset) / float(total - 1)

func _tri(u: float) -> float:
	return 1.0 - abs(2.0 * u - 1.0)

func _yoylemountain_surface_y_triangle(world_x: int, prev_y0: int) -> int:
	var u: = _yoylemountain_profile_u(world_x)
	var tri: = _tri(u)
	var y0: = BASE_SURFACE_Y - int(round(YOYLE_MTN_AMP * tri))


	if prev_y0 != NO_PREV:
		var d: = y0 - prev_y0
		if d > MAX_SLOPE_STEP: y0 = prev_y0 + MAX_SLOPE_STEP
		if d < - MAX_SLOPE_STEP: y0 = prev_y0 - MAX_SLOPE_STEP
	return y0

func _yoylemountain_surface_y(world_x: int, prev_y0: int) -> int:
	var u: = _yoylemountain_profile_u(world_x)


	var hump: = 0.5 - 0.5 * cos(PI * u)
	hump = pow(hump, 1.12)


	var jitter: = int(round(YOYLE_MTN_MICRO_JITTER * noise_height.get_noise_1d(float(world_x) * 0.25)))


	var y0: = BASE_SURFACE_Y - int(round(YOYLE_MTN_AMP * hump)) + jitter


	if prev_y0 != NO_PREV:
		var d: = y0 - prev_y0
		if d > MAX_SLOPE_STEP: y0 = prev_y0 + MAX_SLOPE_STEP
		if d < - MAX_SLOPE_STEP: y0 = prev_y0 - MAX_SLOPE_STEP
	return y0



func _pull_up_column_for_mountain(x: int, old_y0: int, new_y0: int) -> void :
	var delta: = old_y0 - new_y0


	for y in range(new_y0 - 6, new_y0):
		var c: = Vector2i(x, y)
		if removed_cells.has(c) or cell_overrides.has(c): continue
		ground.erase_cell(c)



	for i in range(1, FILL_DEPTH + 1):
		var dst: = Vector2i(x, new_y0 + i)
		if removed_cells.has(dst) or cell_overrides.has(dst): continue

		var src: = Vector2i(x, new_y0 + i + delta)


		var sid: = ground.get_cell_source_id(src)
		if sid == SRC:
			var ac: = ground.get_cell_atlas_coords(src)
			var alt: = ground.get_cell_alternative_tile(src)
			ground.set_cell(dst, SRC, ac, alt)
		else:

			ground.set_cell(dst, SRC, T_STONE, 0)



	for y in range(old_y0 + 1, old_y0 + 1 + min(FILL_DEPTH, delta)):
		var c2: = Vector2i(x, y)
		if removed_cells.has(c2) or cell_overrides.has(c2): continue
		ground.erase_cell(c2)

func _apply_yoylemountain_make_real_surface_for_chunk(cc: Vector2i) -> void :
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	if cc.x < mleft or cc.x > mright:
		return

	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE

	for lx in range(CHUNK_SIZE):
		var x: = x0 + lx
		var new_y0: = int(surf.get(x, BASE_SURFACE_Y))
		var old_y0: = _get_surface_y_at(x)

		if new_y0 < old_y0:

			_pull_up_column_for_mountain(x, old_y0, new_y0)
			_seal_below_surface_column(x, new_y0)


		last_surface_y_for_x[x] = new_y0

const SEAL_DEPTH: = 8

func _seal_below_surface_column(x: int, y0: int, depth: int = SEAL_DEPTH) -> void :
	for i in range(1, depth + 1):
		var c: = Vector2i(x, y0 + i)
		if removed_cells.has(c) or cell_overrides.has(c):
			continue

		var sid: = ground.get_cell_source_id(c)
		if sid == -1:
			ground.set_cell(c, SRC, T_DEEP, 0)


func _yoylemountain_erase_above_dome_column(x: int, y0: int, rect: Rect2i) -> void :
	var top: = rect.position.y
	var stop = max(top, y0 - 1)
	for y in range(top, stop + 1):
		var c: = Vector2i(x, y)
		if removed_cells.has(c) or cell_overrides.has(c):
			continue
		if ground.get_cell_source_id(c) != -1:
			ground.erase_cell(c)

const MOUNTAIN_SEAM_LOCK: = 24
const MOUNTAIN_SEAM_MAX: = FILL_DEPTH

func _yoylemountain_enforce_surface_for_chunk(cc: Vector2i) -> void :
	var rect: Rect2i = chunk_rects.get(cc, Rect2i())
	if rect.size == Vector2i.ZERO:
		return
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE
	for lx in range(CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		_yoylemountain_erase_above_dome_column(x, y0, rect)
		_yoylemountain_rebuild_sleeve_column(x, y0, rect)
		last_surface_y_for_x[x] = y0

func _apply_yoylemountain_overlays_for_chunk(cc: Vector2i) -> void :
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	if cc.x < mleft or cc.x > mright:
		return

	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE

	for lx in range(CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var u: = _yoylemountain_profile_u(x)
		var h: = _tri(u)

		var item_id: = ITEM_YOYLE_GRASS
		var thick: = YOYLE_MTN_YOYLE_THICK
		if h >= (1.0 - YOYLE_MTN_SNOW_FRAC):
			item_id = ITEM_SNOW
			thick = YOYLE_MTN_SNOW_THICK
		elif h >= (1.0 - (YOYLE_MTN_SNOW_FRAC + YOYLE_MTN_DARK_FRAC)):
			item_id = ITEM_DARK_GRASS
			thick = YOYLE_MTN_DARK_THICK


		for dy in range(thick):
			var c: = Vector2i(x, y0 + dy)
			if removed_cells.has(c) or cell_overrides.has(c):
				continue
			var ac: = item_id_to_atlas(item_id, c.x, c.y)
			if ac != Vector2i(-1, -1):
				ground.set_cell(c, SRC, ac, 0)

func _yoylemountain_rebuild_sleeve_column(x: int, y0: int, rect: Rect2i) -> void :

	var top: = y0 + 1
	var bottom = min(y0 + MOUNTAIN_SEAM_MAX, rect.position.y + rect.size.y - 2)

	for y in range(top, bottom + 1):
		var c: = Vector2i(x, y)

		if removed_cells.has(c) or cell_overrides.has(c):
			continue


		var sid: = ground.get_cell_source_id(c)
		if sid == SRC:
			break

		var d: = y - y0


		if d <= MOUNTAIN_SEAM_LOCK:
			ground.set_cell(c, SRC, T_STONE)
			removed_cells.erase(c)
			continue



		var allow_cave: = (d > (CAVE_SAFE_DEPTH + 8))
		var is_cave: = allow_cave and _is_cave(x, y, y0)

		if is_cave:

			continue


		var ac: = T_STONE
		if has_method("_pick_stone_variant"):
			ac = _pick_stone_variant(x, y)
			if ac == Vector2i(-1, -1):
				ac = T_STONE
		ground.set_cell(c, SRC, ac)
		removed_cells.erase(c)

func _apply_yoylemountain_fix_gap_for_chunk(cc: Vector2i) -> void :
	var rect: Rect2i = chunk_rects.get(cc, Rect2i())
	if rect.size == Vector2i.ZERO:
		return

	var x0: = cc.x * CHUNK_SIZE
	var surf: = _surface_y_map_for_chunk(cc)
	for lx in range(CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		_yoylemountain_rebuild_sleeve_column(x, y0, rect)



const FILL_SPHERE_INTERIOR: = true
const STRIPE_EQU_SPACING: = 2
const STRIPE_VOL_HALF_THICK: = 0

func _in_sphere(dx: int, dy: int, r: int) -> bool:
	return dx * dx + dy * dy <= r * r

func _is_surface_cell(center: Vector2i, x: int, y: int, r: int) -> bool:
	var dx: = x - center.x
	var dy: = y - center.y
	if not _in_sphere(dx, dy, r):
		return false

	if not _in_sphere(dx + 1, dy, r): return true
	if not _in_sphere(dx - 1, dy, r): return true
	if not _in_sphere(dx, dy + 1, r): return true
	if not _in_sphere(dx, dy - 1, r): return true
	return false

func _is_in_stripe_volume(center_y: int, y: int) -> bool:

	var offsets: = [ - STRIPE_EQU_SPACING, 0, STRIPE_EQU_SPACING]
	for off in offsets:
		if abs(y - (center_y + off)) <= STRIPE_VOL_HALF_THICK:
			return true
	return false

func _fill_item_no_override(c: Vector2i, item_id: int, alt: int = 0) -> void :
	if removed_cells.has(c):
		return
	var ac: = item_id_to_atlas(item_id, c.x, c.y)
	if ac != Vector2i(-1, -1):
		ground.set_cell(c, SRC, ac, alt)

func _build_sphere_solid_with_3_volume_stripes(center: Vector2i, r: int) -> void :
	var y_min: = center.y - r
	var y_max: = center.y + r


	if FILL_SPHERE_INTERIOR:
		for y in range(y_min, y_max + 1):
			var dy: = y - center.y
			var rem: = r * r - dy * dy
			if rem < 0: continue
			var dx_max: = int(floor(sqrt(float(rem))))
			for dx in range( - dx_max, dx_max + 1):
				var x: = center.x + dx
				var c: = Vector2i(x, y)
				_fill_item_no_override(c, ITEM_SPHERE, 0)


	for y in range(y_min, y_max + 1):
		var dy: = y - center.y
		var rem: = r * r - dy * dy
		if rem < 0: continue
		var dx_max: = int(floor(sqrt(float(rem))))
		var in_stripe: = _is_in_stripe_volume(center.y, y)
		if not in_stripe:
			continue
		for dx in range( - dx_max, dx_max + 1):
			var x: = center.x + dx
			var c: = Vector2i(x, y)
			_fill_item_no_override(c, ITEM_STRIPE, 0)


	for y in range(y_min, y_max + 1):
		var dy: = y - center.y
		var rem: = r * r - dy * dy
		if rem < 0: continue
		var dx_max: = int(floor(sqrt(float(rem))))
		for dx in range( - dx_max, dx_max + 1):
			var x: = center.x + dx
			if not _is_surface_cell(center, x, y, r):
				continue
			var c: = Vector2i(x, y)
			if removed_cells.has(c):
				continue
			if _is_in_stripe_volume(center.y, y):
				_place_item_override(c, ITEM_STRIPE, 0)
			else:
				_place_item_override(c, ITEM_SPHERE, 0)

const SUMMIT_POLE_HEIGHT: = 160
const PLATFORM_STEP: = 6
const PLATFORM_RADIUS_X: = 3
const PLATFORM_RADIUS_Y: = 1

const SPHERE_RADIUS: = 7


var _summit_scan_done: bool = false
var _summit_setpiece_done: bool = false
var _summit_scanned: Dictionary = {}
var _summit_apex_x: int = 0
var _summit_apex_y: int = 0

func _ideal_apex_world_x() -> int:
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	var center_chunk: = int(floor((mleft + mright) / 2.0))
	return center_chunk * CHUNK_SIZE + int(CHUNK_SIZE / 2)

const APEX_REFINE_RADIUS: = 24

func _refine_apex_in_this_chunk(cc: Vector2i, guess_x: int) -> Vector2i:
	var surf: = _surface_y_map_for_chunk(cc)
	var rect: Rect2i = chunk_rects[cc]
	var x_lo = max(rect.position.x, guess_x - APEX_REFINE_RADIUS)
	var x_hi = min(rect.position.x + rect.size.x - 1, guess_x + APEX_REFINE_RADIUS)

	var best_x = x_lo
	var best_y: = 1000000
	for x in range(x_lo, x_hi + 1):
		var y: = int(surf.get(x, BASE_SURFACE_Y))
		if y < best_y:
			best_y = y
			best_x = x
	return Vector2i(best_x, best_y)

const META_SUMMIT_KEY: = "yoyle_summit_v1"

func _load_summit_from_meta() -> Dictionary:
	var world_name = GameSession.current_world_name
	var meta: = WorldSave.read_meta(world_name)
	return meta.get(META_SUMMIT_KEY, {})


func _save_summit_to_meta(apex_x: int, apex_y: int) -> void :
	var world_name = GameSession.current_world_name
	var meta: = WorldSave.read_meta(world_name)
	meta[META_SUMMIT_KEY] = {"x": apex_x, "y": apex_y, "placed": true}
	WorldSave.write_meta(world_name, meta)


func _place_item_override(c: Vector2i, item_id: int, alt: int = 0) -> void :
	if removed_cells.has(c):
		return
	var ac: = item_id_to_atlas(item_id, c.x, c.y)
	if ac != Vector2i(-1, -1):
		ground.set_cell(c, SRC, ac, alt)
		cell_overrides[c] = ac

func _place_item_override_if_air(c: Vector2i, item_id: int, alt: int = 0) -> void :
	if removed_cells.has(c):
		return
	if ground.get_cell_source_id(c) == -1:
		var ac: = item_id_to_atlas(item_id, c.x, c.y)
		if ac != Vector2i(-1, -1):
			ground.set_cell(c, SRC, ac, alt)
			cell_overrides[c] = ac



const STEP_GAP_BLOCKS: = 2
const LEDGE_RADIUS: = 2
const LEDGE_ALT_LIP: = 0

func _build_pole_with_alternating_ledges(summit: Vector2i) -> void :

	var sphere_ctr: = Vector2i(summit.x, summit.y - SUMMIT_POLE_HEIGHT)
	var sphere_bottom_y: = sphere_ctr.y + SPHERE_RADIUS

	var step_idx: = 0
	for i in range(1, SUMMIT_POLE_HEIGHT + 1):
		var cy: = summit.y - i


		if cy <= sphere_bottom_y:
			break


		_place_override(Vector2i(summit.x, cy), T_POLE, ALT_POLE)


		if (i % STEP_GAP_BLOCKS) == 0:
			var side_left: = (step_idx % 2) == 0

			var lx: = summit.x
			if side_left:
				lx -= LEDGE_RADIUS
			else:
				lx += LEDGE_RADIUS

			var ledge: = Vector2i(lx, cy)
			_place_override(ledge, T_PLATFORM, 0)


			if LEDGE_ALT_LIP == 1:
				var lip_x: = lx
				if side_left:
					lip_x -= 1
				else:
					lip_x += 1
				var lip: = Vector2i(lip_x, cy)
				_set_if_placeable(lip, T_PLATFORM, 0)


			var mid_x: = summit.x
			if side_left:
				mid_x -= 1
			else:
				mid_x += 1
			var mid: = Vector2i(mid_x, cy)
			if ground.get_cell_source_id(mid) != -1:
				if not removed_cells.has(mid) and not cell_overrides.has(mid):
					ground.erase_cell(mid)

			step_idx += 1


const JUMP_BLOCKS: = 2
const HELIX_RADIUS: = 2
const ANGLE_STEP: = PI / 6.0
const TREAD_LEN: = 2
const TREAD_WID: = 1

func _signi(v: int) -> int:
	if v > 0: return 1
	if v < 0: return -1
	return 0

func _place_tread(center_pole: Vector2i, cy: int, theta: float) -> void :
	var dx: = int(round(HELIX_RADIUS * cos(theta)))
	var dy: = int(round(HELIX_RADIUS * sin(theta)))
	var tread_center: = Vector2i(center_pole.x + dx, cy + dy)


	var tx: = - dy
	var ty: = dx


	if abs(tx) >= abs(ty):
		if tx > 0: tx = 1
		elif tx < 0: tx = -1
		else: tx = 0
		ty = 0
	else:
		if ty > 0: ty = 1
		elif ty < 0: ty = -1
		else: ty = 0
		tx = 0

	var half: = int(TREAD_LEN / 2)
	for k in range( - half, half + 1):
		var p: = Vector2i(tread_center.x + tx * k, tread_center.y + ty * k)
		_place_item_override(p, ITEM_PLATFORM, 0)


	var ip: = Vector2i(tread_center.x - _signi(dx), tread_center.y - _signi(dy))
	_place_item_override(ip, ITEM_PLATFORM, 0)


const SPHERE_SHELL_THICK: = 1
const STRIPE_COUNT: = 3
const STRIPE_HALF_THICK: = 0
const STRIPE_THICKNESS: = 1

func _is_shell_point(dx: int, dy: int, r: int) -> bool:
	var d2: = dx * dx + dy * dy
	var r2: = r * r
	var rm = max(0, r - SPHERE_SHELL_THICK)
	var rm2 = rm * rm
	return d2 <= r2 and d2 >= rm2

@rpc("any_peer", "call_local", "reliable")
func cli_set_summit_apex(ax: int, ay: int) -> void :
	_summit_apex_x = ax
	_summit_apex_y = ay

	print("Summit apex set: x=", ax, " y=", ay)

func _broadcast_summit_apex() -> void :
	rpc("cli_set_summit_apex", _summit_apex_x, _summit_apex_y)

func _maybe_init_summit_apex_and_broadcast() -> void :

	if _summit_apex_y != 0:
		_broadcast_summit_apex()
		return

	var rec: = _load_summit_from_meta()
	if rec.get("placed", false):
		_summit_apex_x = int(rec.get("x", 0))
		_summit_apex_y = int(rec.get("y", 0))
		_broadcast_summit_apex()

func get_yoyle_space_fade_profile() -> Dictionary:
	if _summit_apex_y == 0:
		var rec: = _load_summit_from_meta()
		if rec.get("placed", false):
			_summit_apex_x = int(rec.get("x", _summit_apex_x))
			_summit_apex_y = int(rec.get("y", _summit_apex_y))

	var base_tiles: = _summit_apex_y
	var full_tiles: = base_tiles - SUMMIT_POLE_HEIGHT

	var px: = ground.tile_set.tile_size.y
	return {
		"base_y": base_tiles * px, 
		"full_y": full_tiles * px
	}

func _apply_yoylemountain_summit_for_chunk(cc: Vector2i) -> void :
	if not _is_server(): return
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	if cc.x < mleft or cc.x > mright: return


	var rec: = _load_summit_from_meta()
	var already_placed = rec.get("placed", false)

	if already_placed:

		_summit_apex_x = int(rec.get("x", _summit_apex_x))
		_summit_apex_y = int(rec.get("y", _summit_apex_y))


		_broadcast_summit_apex()


		var sph_ctr: = Vector2i(_summit_apex_x, _summit_apex_y - SUMMIT_POLE_HEIGHT)
		_ensure_sphere_volume_for_chunk(cc, sph_ctr, SPHERE_RADIUS)
		return


	var ideal_x: = _ideal_apex_world_x()
	var x0: = cc.x * CHUNK_SIZE
	if ideal_x < x0 or ideal_x >= x0 + CHUNK_SIZE:
		return

	var summit: = _refine_apex_in_this_chunk(cc, ideal_x)
	if _pole_exists_near(summit):
		_save_summit_to_meta(summit.x, summit.y)
		return


	_build_pole_with_alternating_ledges(summit)


	var sph_ctr: = Vector2i(summit.x, summit.y - SUMMIT_POLE_HEIGHT)
	_build_sphere_solid_with_3_volume_stripes(sph_ctr, SPHERE_RADIUS)

	var vcell: = Vector2i(sph_ctr.x, sph_ctr.y - SPHERE_RADIUS)
	_place_item_override(vcell, ITEM_VICTORY, 0)


	_summit_apex_x = summit.x
	_summit_apex_y = summit.y
	_save_summit_to_meta(summit.x, summit.y)
	_broadcast_summit_apex()

func _sphere_center_for_summit(summit: Vector2i) -> Vector2i:

	return Vector2i(summit.x, summit.y - SUMMIT_POLE_HEIGHT)


func _chunk_apex_xy(cc: Vector2i) -> Vector2i:
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE
	var best_x: = x0
	var best_y: = 1000000
	for lx in range(CHUNK_SIZE):
		var wx: = x0 + lx
		var y: = int(surf.get(wx, BASE_SURFACE_Y))
		if y < best_y:
			best_y = y
			best_x = wx
	return Vector2i(best_x, best_y)


func _update_summit_scan_and_maybe_finalize() -> void :

	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	var needed: = YOYLE_MTN_WIDTH_CHUNKS


	if _summit_scanned.size() < needed:
		return


	var best_y: = 1000000
	var best_x: = 0
	for cx in _summit_scanned.keys():
		var rec = _summit_scanned[int(cx)]
		var x: = int(rec.x)
		var y: = int(rec.y)
		if y < best_y:
			best_y = y
			best_x = x

	_summit_apex_x = best_x
	_summit_apex_y = best_y
	_summit_scan_done = true


func _yoylemountain_band_world_range() -> Vector2i:
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	var start_x: = mleft * CHUNK_SIZE
	var end_x: = (mright + 1) * CHUNK_SIZE - 1
	return Vector2i(start_x, end_x)


func _yoylemountain_dome_y_at(world_x: int) -> int:
	var ccx: = int(floor(float(world_x) / float(CHUNK_SIZE)))
	var cc: = Vector2i(ccx, 0)
	if not chunk_rects.has(cc):
		return BASE_SURFACE_Y
	var surf: = _surface_y_map_for_chunk(cc)
	return int(surf.get(world_x, BASE_SURFACE_Y))

func _yoylemountain_find_apex_world_x() -> int:
	var rng: = _yoylemountain_band_world_range()
	var best_x: = rng.x
	var best_y: = 1000000


	var step: = 1
	for x in range(rng.x, rng.y + 1, step):
		var y: = _yoylemountain_dome_y_at(x)
		if y < best_y:
			best_y = y
			best_x = x


	if step > 1:
		var lo = max(rng.x, best_x - 3 * step)
		var hi = min(rng.y, best_x + 3 * step)
		for x in range(lo, hi + 1):
			var y: = _yoylemountain_dome_y_at(x)
			if y < best_y:
				best_y = y
				best_x = x

	return best_x

func _place_override(c: Vector2i, atlas: Vector2i, alt: int = 0) -> void :
	if removed_cells.has(c): return
	ground.set_cell(c, SRC, atlas, alt)
	cell_overrides[c] = atlas

func _place_override_if_air(c: Vector2i, atlas: Vector2i, alt: int = 0) -> void :
	if removed_cells.has(c): return
	if ground.get_cell_source_id(c) == -1:
		ground.set_cell(c, SRC, atlas, alt)
		cell_overrides[c] = atlas

func _build_pole_and_platforms_unbounded(summit: Vector2i) -> void :
	var x: = summit.x
	var y_surface: = summit.y
	for i in range(1, SUMMIT_POLE_HEIGHT + 1):
		var cy: = y_surface - i
		_place_override(Vector2i(x, cy), T_POLE, ALT_POLE)
		if (i % PLATFORM_STEP) == 0:
			for dx in range( - PLATFORM_RADIUS_X, PLATFORM_RADIUS_X + 1):
				_place_override_if_air(Vector2i(x + dx, cy), T_PLATFORM, 0)
			for dy in range( - PLATFORM_RADIUS_Y, PLATFORM_RADIUS_Y + 1):
				if dy != 0:
					_place_override_if_air(Vector2i(x, cy + dy), T_PLATFORM, 0)

func _yoylemountain_center_world_x() -> int:
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	var center_chunk: = int(floor((mleft + mright) / 2.0))
	return center_chunk * CHUNK_SIZE + int(floor(CHUNK_SIZE / 2.0))

func _is_server() -> bool:
	return multiplayer.is_server()

func _pole_exists_near(summit: Vector2i, check_height: int = 12) -> bool:
	for i in range(1, check_height + 1):
		var c: = Vector2i(summit.x, summit.y - i)
		var ac: Vector2i = ground.get_cell_atlas_coords(c)
		if ac == T_POLE:
			return true
	return false



func _set_if_placeable(c: Vector2i, atlas: Vector2i, alt: int = 0) -> bool:

	if removed_cells.has(c) or cell_overrides.has(c):
		return false

	return _set_if_air_alt(c, atlas, alt)

func _ensure_sphere_volume_for_chunk(cc: Vector2i, center: Vector2i, r: int) -> void :


	var x0: = cc.x * CHUNK_SIZE
	var x1: = x0 + CHUNK_SIZE - 1
	var y_min: = center.y - r
	var y_max: = center.y + r


	for y in range(y_min, y_max + 1):
		var dy: = y - center.y
		var rem: = r * r - dy * dy
		if rem < 0: continue
		var dx_max: = int(floor(sqrt(float(rem))))
		for dx in range( - dx_max, dx_max + 1):
			var x: = center.x + dx
			if x < x0 or x > x1: continue
			var c: = Vector2i(x, y)
			if removed_cells.has(c) or cell_overrides.has(c):
				continue
			_fill_item_no_override(c, ITEM_SPHERE, 0)


	for y in range(y_min, y_max + 1):
		if not _is_in_stripe_volume(center.y, y): continue
		var dy: = y - center.y
		var rem: = r * r - dy * dy
		if rem < 0: continue
		var dx_max: = int(floor(sqrt(float(rem))))
		for dx in range( - dx_max, dx_max + 1):
			var x: = center.x + dx
			if x < x0 or x > x1: continue
			var c: = Vector2i(x, y)
			if removed_cells.has(c) or cell_overrides.has(c):
				continue
			_fill_item_no_override(c, ITEM_STRIPE, 0)


const CANAL_DEPTH_MIN: = 8
const CANAL_DEPTH_MAX: = 14
const CANAL_SMOOTH_RADIUS: = 2
const CANAL_CLEAR_HEIGHT: = 6
const CANAL_CEILING_SHAVE: = 2

func _is_replaceable(c: Vector2i) -> bool:
	var sid: = ground.get_cell_source_id(c)
	if sid == -1: return true
	if sid != SRC: return false
	return ground.get_cell_atlas_coords(c) == T_WATER




func _is_player_edited(cell: Vector2i) -> bool:
	return removed_cells.has(cell) or cell_overrides.has(cell)

func _apply_goiky_canal_for_chunk(cc: Vector2i) -> void :
	if not chunk_rects.has(cc): return
	var rect: Rect2i = chunk_rects[cc]
	var x0: = cc.x * CHUNK_SIZE
	var rng: = _rng_for_chunk("goiky", cc)
	var surf: = _surface_y_map_for_chunk(cc)


	var bed_raw: Array[int] = []
	bed_raw.resize(CHUNK_SIZE)
	for lx in range(CHUNK_SIZE):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		bed_raw[lx] = clamp(
			y0 + rng.randi_range(CANAL_DEPTH_MIN, CANAL_DEPTH_MAX), 
			rect.position.y + 3, 
			rect.position.y + rect.size.y - 6
		)


	var bed: Array[int] = []
	bed.resize(CHUNK_SIZE)
	for lx in range(CHUNK_SIZE):
		var sum: = 0
		var n: = 0
		for dx in range( - CANAL_SMOOTH_RADIUS, CANAL_SMOOTH_RADIUS + 1):
			var ix = clamp(lx + dx, 0, CHUNK_SIZE - 1)
			sum += bed_raw[ix];n += 1
		bed[lx] = int(round(float(sum) / float(n)))


	for lx in range(CHUNK_SIZE):
		var x: = x0 + lx
		var bed_y: = bed[lx]
		var bed_cell: = Vector2i(x, bed_y)


		var clear_top = max(rect.position.y, bed_y - CANAL_CLEAR_HEIGHT)
		for y in range(clear_top, bed_y):
			var c: = Vector2i(x, y)

			if _is_player_edited(c):
				continue

			var sid: = ground.get_cell_source_id(c)
			if sid == -1 or sid == SRC:
				ground.set_cell(c, SRC, T_WATER)


		var shave_top = max(rect.position.y, clear_top - CANAL_CEILING_SHAVE)
		for y in range(shave_top, clear_top):
			var c: = Vector2i(x, y)
			if _is_player_edited(c):
				continue
			var sid: = ground.get_cell_source_id(c)
			if sid == -1 or sid == SRC:
				ground.set_cell(c, SRC, T_WATER)


		for y in range(rect.position.y, clear_top):
			var c: = Vector2i(x, y)
			if _is_player_edited(c):
				continue
			var sid: = ground.get_cell_source_id(c)
			if sid == -1:
				ground.set_cell(c, SRC, T_WATER)
				continue
			if sid != SRC:
				continue
			var ac2: = ground.get_cell_atlas_coords(c)
			var is_geo: = (ac2 == T_CAVESTONE) or (ac2 == T_STONE) or (ac2 == T_COALSTONE) or (ac2 == T_IRONSTONE)
			var is_soft: = (
				ac2 == T_MID or ac2 == T_MID_SAND or ac2 == T_MID_DARK or 
				ac2 in T_SURFACE_VARIANTS or 
				ac2 in T_SURFACE_VARIANTS_SNOW or 
				ac2 in T_SURFACE_VARIANTS_DARK or 
				ac2 in T_SURFACE_VARIANTS_SAND or 
				ac2 == T_DEEP or 
				ac2 == T_LEAVES or ac2 == T_DARK_LEAVES or 
				ac2 == T_LOG or ac2 == T_DARK_LOG or 
				ac2 == T_CACTUS
			)
			if not is_geo and is_soft:
				ground.set_cell(c, SRC, T_WATER)


		if not _is_player_edited(bed_cell):
			var sand_idx: = rng.randi_range(0, T_SURFACE_VARIANTS_SAND.size() - 1)
			ground.set_cell(bed_cell, SRC, T_SURFACE_VARIANTS_SAND[sand_idx])

		if rng.randf() < 0.65 and lx > 0:
			var left_cell: = Vector2i(x - 1, bed_y)
			if not _is_player_edited(left_cell) and ground.get_cell_source_id(left_cell) == SRC:
				ground.set_cell(left_cell, SRC, T_SURFACE_VARIANTS_SAND[rng.randi_range(0, T_SURFACE_VARIANTS_SAND.size() - 1)])

		if rng.randf() < 0.65 and lx < CHUNK_SIZE - 1:
			var right_cell: = Vector2i(x + 1, bed_y)
			if not _is_player_edited(right_cell) and ground.get_cell_source_id(right_cell) == SRC:
				ground.set_cell(right_cell, SRC, T_SURFACE_VARIANTS_SAND[rng.randi_range(0, T_SURFACE_VARIANTS_SAND.size() - 1)])


		var y: = bed_y + 1
		while true:
			var c2: = Vector2i(x, y)
			if _is_player_edited(c2):
				break
			if ground.get_cell_source_id(c2) != SRC:
				break
			var ac: = ground.get_cell_atlas_coords(c2)
			if ac != T_MID:
				break
			ground.set_cell(c2, SRC, T_MID_SAND)
			y += 1


	var bed_map: Dictionary = {}
	for i in range(CHUNK_SIZE):
		bed_map[x0 + i] = bed[i]

	_spawn_goiky_canal_lines_and_cactus_for_chunk_bedmap(cc, bed_map, rng)
	_scatter_bed_stones_for_chunk_bedmap(cc, bed_map, rng)
	if multiplayer.is_server():
		_server_try_seed_fish_for_chunk(cc)

func _spawn_goiky_canal_lines_and_cactus_for_chunk(cc: Vector2i, bed_y: int, rng: RandomNumberGenerator) -> void :
	var x0: = cc.x * CHUNK_SIZE



	var line_count: = rng.randi_range(1, 3)
	for li in line_count:
		var start_lx: = rng.randi_range(1, CHUNK_SIZE - 6)
		var length: = rng.randi_range(6, 14)
		for dx in range(0, length):
			var x = x0 + clamp(start_lx + dx, x0, x0 + CHUNK_SIZE - 1)
			var c: = Vector2i(x, bed_y - 1)
			if _is_air(c):
				ground.set_cell(c, SRC, T_DARK_LEAVES)



	var last_cx: = -1000000
	for lx in range(0, CHUNK_SIZE):
		var x: = x0 + lx
		if last_cx >= 0 and (x - last_cx) < CACTUS_MIN_SPACING:
			continue
		if rng.randf() < CACTUS_BASE_PROB * 0.75:

			var h: = rng.randi_range(max(2, CACTUS_TRUNK_MIN), CACTUS_TRUNK_MAX)
			var placed: = false
			for i in range(0, h):
				var c: = Vector2i(x, bed_y - i)
				if _set_if_air_simple(c, SRC, T_CACTUS):
					placed = true
			if placed:
				last_cx = x

func _scatter_bed_stones_for_chunk(cc: Vector2i, bed_y: int, rng: RandomNumberGenerator) -> void :

	var x0: = cc.x * CHUNK_SIZE
	for lx in range(0, CHUNK_SIZE):
		var x: = x0 + lx
		if rng.randf() < 0.12:
			var c: = Vector2i(x, bed_y)
			if not (removed_cells.has(c) or cell_overrides.has(c)) and ground.get_cell_source_id(c) == SRC:
				ground.set_cell(c, SRC, T_STONE)

func _spawn_goiky_canal_lines_and_cactus_for_chunk_bedmap(cc: Vector2i, bed_y_map: Dictionary, rng: RandomNumberGenerator) -> void :
	var x0: = cc.x * CHUNK_SIZE
	var x1: = x0 + CHUNK_SIZE - 1


	var line_count: = rng.randi_range(1, 3)
	for _i in line_count:
		var start_x: = rng.randi_range(x0 + 1, x1 - 5)
		var length: = rng.randi_range(6, 14)
		for k in range(length):
			var wx: = start_x + k
			if wx > x1: break
			if not bed_y_map.has(wx): break
			var by: = int(bed_y_map[wx])
			var c: = Vector2i(wx, by - 1)
			if _is_replaceable(c):
				ground.set_cell(c, SRC, T_DARK_LEAVES)


	var last_cx: = -1000000
	for lx in range(CHUNK_SIZE):
		var wx: = x0 + lx
		if not bed_y_map.has(wx): continue

		if last_cx >= 0 and (wx - last_cx) < CACTUS_MIN_SPACING: continue
		if rng.randf() < (CACTUS_BASE_PROB * 0.9):
			var by: = int(bed_y_map[wx])
			var h: = rng.randi_range(max(2, CACTUS_TRUNK_MIN), CACTUS_TRUNK_MAX)
			var placed: = false
			for i in range(h):
				var c: = Vector2i(wx, by - i)
				if _is_replaceable(c):
					ground.set_cell(c, SRC, T_CACTUS)
					placed = true
			if placed:
				last_cx = wx

func _scatter_bed_stones_for_chunk_bedmap(cc: Vector2i, bed_y_map: Dictionary, rng: RandomNumberGenerator) -> void :
	var x0: = cc.x * CHUNK_SIZE
	for lx in range(CHUNK_SIZE):
		var wx: = x0 + lx
		if not bed_y_map.has(wx): continue
		if rng.randf() < 0.22:
			var c: = Vector2i(wx, int(bed_y_map[wx]))

			if ground.get_cell_source_id(c) == SRC:
				ground.set_cell(c, SRC, T_STONE)

func _set_if_air_with_alt(c: Vector2i, src_id: int, atlas: Vector2i, alt: int) -> bool:
	if _is_air(c):
		ground.set_cell(c, src_id, atlas, alt)
		return true
	return false

func _set_if_air_simple(c: Vector2i, src_id: int, atlas: Vector2i) -> bool:
	if _is_air(c):
		ground.set_cell(c, src_id, atlas)
		return true
	return false

func _place_dark_tree_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0
	var h: = rng.randi_range(SNOWY_TREE_TRUNK_MIN, SNOWY_TREE_TRUNK_MAX)


	for i in range(1, h + 1):
		var c: = Vector2i(x, y0 - i)
		if _set_if_air_with_alt(c, SRC, T_DARK_LOG, ALT_DARK_LOG):
			min_y = min(min_y, c.y)


	var top: = Vector2i(x, y0 - h)
	for off in _canopy_offsets_for_height(h, rng):
		var leaf_cell: = top + off
		if _set_if_air_simple(leaf_cell, SRC, T_DARK_LEAVES):
			min_y = min(min_y, leaf_cell.y)

	return min_y

func _spawn_snowy_trees_for_chunk(cc: Vector2i) -> int:
	var rng: = _rng_for_chunk("trees-snowy", cc)
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE
	var last_tree_x: = -1000000
	var local_min_y: = 1000000

	for lx in range(1, CHUNK_SIZE - 1):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var l: = int(surf.get(x - 1, y0))
		var r: = int(surf.get(x + 1, y0))
		if abs(l - y0) > TREE_STEEP_REJECT or abs(r - y0) > TREE_STEEP_REJECT:
			continue
		if (x - last_tree_x) < SNOWY_TREE_MIN_SPACING:
			continue
		if rng.randf() >= SNOWY_TREE_BASE_PROB:
			continue

		var min_y: = _place_dark_tree_at(x, y0, rng)
		local_min_y = min(local_min_y, min_y)
		last_tree_x = x

	return local_min_y

func _spawn_evil_trees_for_chunk(cc: Vector2i) -> int:
	var rng: = _rng_for_chunk("eviltrees", cc)
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE
	var last_tree_x: = -1000000
	var local_min_y: = 1000000

	for lx in range(1, CHUNK_SIZE - 1):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var l: = int(surf.get(x - 1, y0))
		var r: = int(surf.get(x + 1, y0))


		if abs(l - y0) > TREE_STEEP_REJECT or abs(r - y0) > TREE_STEEP_REJECT:
			continue


		if (x - last_tree_x) < EVIL_TREE_MIN_SPACING:
			continue


		if rng.randf() >= EVIL_TREE_BASE_PROB:
			continue


		var min_y: = _place_evil_tree_at(x, y0, rng)
		local_min_y = min(local_min_y, min_y)
		last_tree_x = x


		if rng.randf() < EVIL_TREE_CLUSTER_CHANCE:
			var dx: = rng.randi_range(2, EVIL_TREE_CLUSTER_MAX_DX)
			var bx: = x + dx
			if bx < x0 + (CHUNK_SIZE - 1):
				var by0: = int(surf.get(bx, BASE_SURFACE_Y))
				var bl: = int(surf.get(bx - 1, by0))
				var br: = int(surf.get(bx + 1, by0))
				if abs(bl - by0) <= TREE_STEEP_REJECT and abs(br - by0) <= TREE_STEEP_REJECT:
					var bmin: = _place_evil_tree_at(bx, by0, rng)
					local_min_y = min(local_min_y, bmin)

					last_tree_x = bx

	return local_min_y

func _spawn_desert_plants_for_chunk(cc: Vector2i) -> int:
	var rng: = _rng_for_chunk("desertplants", cc)
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE
	var last_x: = -1000000
	var local_min_y: = 1000000

	for lx in range(1, CHUNK_SIZE - 1):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var l: = int(surf.get(x - 1, y0))
		var r: = int(surf.get(x + 1, y0))
		if abs(l - y0) > SLOPE_REJECT or abs(r - y0) > SLOPE_REJECT:
			continue


		var roll: = rng.randf()
		if roll < CACTUS_BASE_PROB:
			if (x - last_x) < CACTUS_MIN_SPACING: continue
			var miny: = _place_cactus_at(x, y0, rng)
			local_min_y = min(local_min_y, miny)
			last_x = x
		elif roll < (CACTUS_BASE_PROB + BUSH_BASE_PROB):
			if (x - last_x) < BUSH_MIN_SPACING: continue
			var miny: = _place_desert_bush_at(x, y0, rng)
			local_min_y = min(local_min_y, miny)
			last_x = x

	return local_min_y

func _spawn_yoyle_plants_for_chunk(cc: Vector2i) -> int:
	var rng: = _rng_for_chunk("yoyleplants", cc)
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE

	var last_x_plain: = -1000000
	var last_x_yoyle: = -1000000
	var local_min_y: = 1000000

	for lx in range(1, CHUNK_SIZE - 1):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var l: = int(surf.get(x - 1, y0))
		var r: = int(surf.get(x + 1, y0))
		if abs(l - y0) > TREE_STEEP_REJECT or abs(r - y0) > TREE_STEEP_REJECT:
			continue

		var roll: = rng.randf()


		if roll < YOYLE_PLAIN_BUSH_BASE_PROB:
			if (x - last_x_plain) < YOYLE_PLAIN_BUSH_MIN_SPACING:
				continue
			var miny: = _place_plain_bush_with_berries_at(x, y0, rng)
			local_min_y = min(local_min_y, miny)
			last_x_plain = x
			continue


		if roll < (YOYLE_PLAIN_BUSH_BASE_PROB + YOYLE_BUSH_BASE_PROB):
			if (x - last_x_yoyle) < YOYLE_BUSH_MIN_SPACING:
				continue
			var miny: = _place_yoyle_bush_at(x, y0, rng)
			local_min_y = min(local_min_y, miny)
			last_x_yoyle = x
			continue

	return local_min_y

func _spawn_yoylecity_for_chunk(cc: Vector2i) -> int:
	var rng: = _rng_for_chunk("yoylecity", cc)
	var surf: = _surface_y_map_for_chunk(cc)
	var x0: = cc.x * CHUNK_SIZE

	var last_bld_x: = -1000000
	var last_bush_x: = -1000000
	var last_yoyle_x: = -1000000
	var local_min_y: = 1000000

	for lx in range(2, CHUNK_SIZE - 2):
		var x: = x0 + lx
		var y0: = int(surf.get(x, BASE_SURFACE_Y))


		var l: = int(surf.get(x - 1, y0))
		var r: = int(surf.get(x + 1, y0))
		if abs(l - y0) > 1 or abs(r - y0) > 1:
			continue

		var roll: = rng.randf()


		if roll < YOYLECITY_BUILDING_BASE_PROB:
			if (x - last_bld_x) < YOYLECITY_BUILDING_MIN_SPACING:
				continue
			var w: = rng.randi_range(YOYLECITY_BUILDING_W_MIN, YOYLECITY_BUILDING_W_MAX)
			var h: = rng.randi_range(YOYLECITY_BUILDING_H_MIN, YOYLECITY_BUILDING_H_MAX)


			var ok: = true
			for dx in range(w):
				var sx: = x + dx
				var sy: = int(surf.get(sx, BASE_SURFACE_Y))
				if abs(sy - y0) > 1:
					ok = false;break
			if not ok:
				continue

			var miny: = _place_yoylecity_building_at(x, y0, w, h, rng)
			local_min_y = min(local_min_y, miny)
			last_bld_x = x + w
			continue


		var cutoff_plain: = YOYLECITY_BUILDING_BASE_PROB + YOYLECITY_PLAIN_BUSH_BASE_PROB
		if roll < cutoff_plain:
			if (x - last_bush_x) < YOYLECITY_PLAIN_BUSH_MIN_SPACING:
				continue
			var miny2: = _place_plain_bush_with_berries_at(x, y0, rng)
			local_min_y = min(local_min_y, miny2)
			last_bush_x = x
			continue


		var cutoff_yoyle: = cutoff_plain + YOYLECITY_YOYLE_BUSH_BASE_PROB
		if roll < cutoff_yoyle:
			if (x - last_yoyle_x) < YOYLECITY_YOYLE_BUSH_MIN_SPACING:
				continue
			var miny3: = _place_yoyle_bush_at(x, y0, rng)
			local_min_y = min(local_min_y, miny3)
			last_yoyle_x = x
			continue

	return local_min_y

func _rand_concrete_item(rng: RandomNumberGenerator) -> int:
	var choices: = [
		ITEM_BLUE_CONCRETE, ITEM_YELLOW_CONCRETE, ITEM_PURPLE_CONCRETE, 
		ITEM_RED_CONCRETE, ITEM_GREEN_CONCRETE, ITEM_BROWN_CONCRETE, ITEM_WHITE_CONCRETE
	]
	return choices[rng.randi_range(0, choices.size() - 1)]

func _alt_for_item(item_id: int) -> int:
	match item_id:
		ITEM_BLUE_CONCRETE: return ALT_BLUE_CONCRETE
		ITEM_YELLOW_CONCRETE: return ALT_YELLOW_CONCRETE
		ITEM_PURPLE_CONCRETE: return ALT_PURPLE_CONCRETE
		ITEM_RED_CONCRETE: return ALT_RED_CONCRETE
		ITEM_GREEN_CONCRETE: return ALT_GREEN_CONCRETE
		ITEM_BROWN_CONCRETE: return ALT_BROWN_CONCRETE
		ITEM_WHITE_CONCRETE: return ALT_WHITE_CONCRETE
		ITEM_WINDOW: return ALT_WINDOW
		_: return 0

func _place_yoylecity_building_at(x: int, y_surface: int, w: int, h: int, rng: RandomNumberGenerator) -> int:
	var tl: = ground
	if tl == null: return y_surface
	var miny: = y_surface
	var top_y: = y_surface - (h - 1)
	var concrete_item: = _rand_concrete_item(rng)
	var M: = YOYLECITY_WINDOW_MARGIN
	var GRID_STEP: = 2

	for dy in range(h):
		for dx in range(w):
			var cell: = Vector2i(x + dx, top_y + dy)


			if removed_cells.has(cell) or cell_overrides.has(cell):
				continue

			var on_border: = (dx < M) or (dx >= w - M) or (dy < M) or (dy >= h - M)
			var place_item: = concrete_item
			if not on_border:
				var gx: = dx - M
				var gy: = dy - M
				if gx >= 0 and gy >= 0 and gx % GRID_STEP == 0 and gy % GRID_STEP == 0:
					place_item = ITEM_WINDOW

			var alt: = _alt_for_item(place_item)
			var ac: = item_id_to_atlas(place_item, cell.x, cell.y)
			if ac != Vector2i(-1, -1):
				tl.set_cell(cell, SRC, ac, alt)



			miny = min(miny, cell.y)

	return miny

func _set_if_air_and_unedited(c: Vector2i, src_id: int, atlas: Vector2i, alt: int = -1) -> bool:
	if removed_cells.has(c) or cell_overrides.has(c):
		return false
	if _is_air(c):
		if alt >= 0:
			ground.set_cell(c, src_id, atlas, alt)
		else:
			ground.set_cell(c, src_id, atlas)
		return true
	return false

func _place_plain_bush_with_berries_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0
	var h: = rng.randi_range(YOYLE_PLAIN_BUSH_TRUNK_MIN, YOYLE_PLAIN_BUSH_TRUNK_MAX)


	for i in range(1, h + 1):
		var trunk_cell: = Vector2i(x, y0 - i)
		if _set_if_air_and_unedited(trunk_cell, SRC, T_BUSH_LOG, ALT_BUSH_LOG):
			min_y = min(min_y, trunk_cell.y)


	var ring: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0: continue
			ring.append(Vector2i(x, y0 - h) + Vector2i(dx, dy))

	var berry_index: = -1
	if rng.randf() < BERRY_LEAF_CHANCE and ring.size() > 0:
		berry_index = rng.randi_range(0, ring.size() - 1)

	for i in range(ring.size()):
		var leaf_cell: = ring[i]
		if i == berry_index:
			if _set_if_air_and_unedited(leaf_cell, SRC, T_BUSH_LEAVES_BERRIES):
				min_y = min(min_y, leaf_cell.y)
		else:
			if _set_if_air_and_unedited(leaf_cell, SRC, T_BUSH_LEAVES):
				min_y = min(min_y, leaf_cell.y)
	return min_y


func _place_yoyle_bush_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0
	var h: = rng.randi_range(YOYLE_BUSH_TRUNK_MIN, YOYLE_BUSH_TRUNK_MAX)


	for i in range(1, h + 1):
		var trunk_cell: = Vector2i(x, y0 - i)
		if _set_if_air_and_unedited(trunk_cell, SRC, T_YOYLE_LOG, ALT_YOYLE_LOG):
			min_y = min(min_y, trunk_cell.y)


	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0: continue
			var leaf_cell: = Vector2i(x, y0 - h) + Vector2i(dx, dy)
			if _set_if_air_and_unedited(leaf_cell, SRC, T_YOYLE_LEAVES):
				min_y = min(min_y, leaf_cell.y)
	return min_y

func _place_evil_tree_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0
	var h: = rng.randi_range(EVIL_TREE_TRUNK_MIN, EVIL_TREE_TRUNK_MAX)


	for i in range(1, h + 1):
		var c: = Vector2i(x, y0 - i)

		if _set_if_air_and_unedited(c, SRC, T_DARK_LOG, ALT_DARK_LOG):
			min_y = min(min_y, c.y)
		else:
			break


	var top: = Vector2i(x, y0 - h)
	for off in _canopy_offsets_for_height(h, rng):
		var leaf_cell: = top + off
		if _set_if_air_and_unedited(leaf_cell, SRC, T_DARK_LEAVES):
			min_y = min(min_y, leaf_cell.y)

	return min_y


func _place_cactus_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0
	var h: = rng.randi_range(CACTUS_TRUNK_MIN, CACTUS_TRUNK_MAX)
	for i in range(1, h + 1):
		var c: = Vector2i(x, y0 - i)

		if _set_if_air_and_unedited(c, SRC, T_CACTUS, ALT_CACTUS):
			min_y = min(min_y, c.y)
	return min_y


func _place_desert_bush_at(x: int, y0: int, rng: RandomNumberGenerator) -> int:
	var min_y: = y0


	var h: = rng.randi_range(BUSH_TRUNK_MIN, BUSH_TRUNK_MAX)
	for i in range(1, h + 1):
		var trunk_cell: = Vector2i(x, y0 - i)

		if _set_if_air_and_unedited(trunk_cell, SRC, T_DARK_LOG, ALT_DARK_LOG):
			min_y = min(min_y, trunk_cell.y)


		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var leaf_cell: = trunk_cell + Vector2i(dx, dy)

				if _set_if_air_and_unedited(leaf_cell, SRC, T_DARK_LEAVES):
					min_y = min(min_y, leaf_cell.y)

	return min_y


@export var cell_size_px: int = 74


@onready var ground: TileMapLayer = $TileMapLayer



var noise_biome: = FastNoiseLite.new()
var noise_height: = FastNoiseLite.new()
var noise_cave: = FastNoiseLite.new()
var noise_stone: = FastNoiseLite.new()
var noise_cavestone: = FastNoiseLite.new()
var noise_ore_choice: = FastNoiseLite.new()
var noise_coal_patch: = FastNoiseLite.new()
var noise_iron_patch: = FastNoiseLite.new()
var noise_gold_patch: = FastNoiseLite.new()
var noise_yoylite_patch: = FastNoiseLite.new()


var chunks: = {}
var last_surface_y_for_x: = {}
var world_seed: int
var appearance_seed: int

func _ensure_clouds_layer() -> void :
	if clouds_layer == null:
		clouds_layer = Node2D.new()
		clouds_layer.name = "Clouds"
		clouds_layer.z_as_relative = false
		clouds_layer.z_index = -1
		add_child(clouds_layer)

const PLAYER_SCENE: = preload("res://player.tscn")

enum CharacterKind{LEAFY, FIREY, COINY, PIN, TENNISBALL, GOLFBALL, PENCIL, MATCH, NEEDLE, PEN, ICECUBE, TEARDROP, ROCKY, FLOWER, BUBBLE, SNOWBALL, BLOCKY, WOODY, ERASER, SPONGY}

var players: = {}
var kinds: = {}
const DEFAULT_KIND: = CharacterKind.LEAFY
var host_kind: int = CharacterKind.LEAFY

const KINDS: = [CharacterKind.LEAFY, CharacterKind.FIREY, CharacterKind.COINY, CharacterKind.PIN, CharacterKind.TENNISBALL, CharacterKind.GOLFBALL, CharacterKind.PENCIL, CharacterKind.MATCH, CharacterKind.NEEDLE, CharacterKind.PEN, CharacterKind.ICECUBE, CharacterKind.TEARDROP, CharacterKind.ROCKY, CharacterKind.FLOWER, CharacterKind.BUBBLE, CharacterKind.SNOWBALL, CharacterKind.BLOCKY, CharacterKind.WOODY, CharacterKind.ERASER, CharacterKind.SPONGY]

var _available_kinds: Array = []

func _reset_available_kinds() -> void :
	_available_kinds = KINDS.duplicate()

func _pick_unique_character_kind() -> int:
	if _available_kinds.is_empty():
		_reset_available_kinds()
	var idx: = randi() % _available_kinds.size()
	var kind: int = _available_kinds[idx]
	_available_kinds.remove_at(idx)
	return kind

var _desired_spawn_by_peer: Dictionary = {}

@rpc("any_peer")
func srv_set_desired_spawn(pos: Vector2) -> void :
	var pid: = multiplayer.get_remote_sender_id()
	print("[SRV] desired spawn from pid=", pid, " pos=", pos)
	_desired_spawn_by_peer[pid] = pos
	_server_set_player_position_if_spawned(pid, pos)

func _saved_or_default_spawn_for(peer_id: int, default_index: int) -> Vector2:
	var v = _desired_spawn_by_peer.get(peer_id, null)
	return (v if v != null else _spawn_point_for_index(default_index))

func _server_set_player_position_if_spawned(peer_id: int, pos: Vector2) -> void :
	var pl = players.get(peer_id, null)
	if pl and is_instance_valid(pl):

		if pl.has_method("cli_snap_teleport_to"):
			pl.cli_snap_teleport_to(pos)
		else:
			pl.global_position = pos

		rpc("cli_force_player_pos", peer_id, pos)

@rpc("any_peer", "call_local", "reliable")
func cli_force_player_pos(peer_id: int, pos: Vector2) -> void :
	var pl = players.get(peer_id, null)
	if pl and is_instance_valid(pl):

		if pl.has_method("cli_snap_teleport_to"):
			pl.cli_snap_teleport_to(pos)
		else:
			pl.global_position = pos

var _desired_stats_by_peer: Dictionary = {}

@rpc("any_peer")
func srv_set_desired_stats(h: int, hu: int, sat: float, exh: float) -> void :
	var pid: = multiplayer.get_remote_sender_id()
	_desired_stats_by_peer[pid] = {
		"health": clamp(h, 0, 10), 
		"hunger": clamp(hu, 0, 10), 
		"saturation": max(0.0, sat), 
		"exhaustion": max(0.0, exh), 
	}
	_server_apply_stats_if_spawned(pid)

func _server_apply_stats_if_spawned(pid: int) -> void :
	var p: Node = players.get(pid, null)
	if p and is_instance_valid(p) and _desired_stats_by_peer.has(pid):
		var s: Dictionary = _desired_stats_by_peer[pid]

		if p.has_method("_health_hunger_sat_exh_apply"):
			p.call("_health_hunger_sat_exh_apply", s)

		rpc_id(pid, "cli_apply_stats", s)

@onready var virtual_stick: Control = $CanvasLayer / VirtualStick
@onready var buttonanchor: Control = $CanvasLayer / Buttonanchor
@onready var saving: Sprite2D = $CanvasLayer / SpriteAnchor / Saving
@onready var health: Control = $CanvasLayer / health
@onready var hunger: Control = $CanvasLayer / hunger

func set_character(chr):
	match chr:
		"LEAFY":
			return CharacterKind.LEAFY
		"FIREY":
			return CharacterKind.FIREY
		"COINY":
			return CharacterKind.COINY
		"PIN":
			return CharacterKind.PIN
		"TENNISBALL":
			return CharacterKind.TENNISBALL
		"GOLFBALL":
			return CharacterKind.GOLFBALL
		"PENCIL":
			return CharacterKind.PENCIL
		"MATCH":
			return CharacterKind.MATCH
		"NEEDLE":
			return CharacterKind.NEEDLE
		"PEN":
			return CharacterKind.PEN
		"ICECUBE":
			return CharacterKind.ICECUBE
		"TEARDROP":
			return CharacterKind.TEARDROP
		"ROCKY":
			return CharacterKind.ROCKY
		"FLOWER":
			return CharacterKind.FLOWER
		"BUBBLE":
			return CharacterKind.BUBBLE
		"SNOWBALL":
			return CharacterKind.SNOWBALL
		"BLOCKY":
			return CharacterKind.BLOCKY
		"WOODY":
			return CharacterKind.WOODY
		"ERASER":
			return CharacterKind.ERASER
		"SPONGY":
			return CharacterKind.SPONGY

var _target: Node2D = null

func _try_bind_target() -> void :

	var world: = get_tree().get_first_node_in_group("world")
	if world and world.has_method("get"):
		var lp = world.local_player
		if lp and is_instance_valid(lp):
			_target = lp
			return

	for n in get_tree().get_nodes_in_group("player"):
		if n.is_multiplayer_authority():
			_target = n
			return

@onready var prize_btn: Button = $CanvasLayer / PrizeBtn
@onready var chat_btn: Button = $CanvasLayer / ChatBtn
@onready var leave_btn: Button = $CanvasLayer / LeaveBtn

func _ready() -> void :
	add_to_group("world")
	_ensure_clouds_layer()

	_try_bind_target()

	var world: = get_tree().get_first_node_in_group("world")
	if world and world.has_signal("local_player_ready"):
		world.local_player_ready.connect( func(p): _target = p)

	var is_pc: = OS.has_feature("pc") or ( not OS.has_feature("mobile") and not DisplayServer.is_touchscreen_available())
	virtual_stick.visible = not is_pc
	buttonanchor.visible = not is_pc
	prize_btn.visible = not is_pc
	chat_btn.visible = not is_pc
	if is_pc:
		leave_btn.position = Vector2.ZERO

	if mining:
		mining.finished.connect(_on_mining_finished)


	z_as_relative = false
	z_index = 2
	ground.z_as_relative = false
	ground.z_index = 1

	_rng.randomize()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if multiplayer.is_server():
		_server_init_world_from_session()
		_server_load_dn_and_broadcast()
		_reset_available_kinds()
		var host_kind = set_character(GameSession.character)
		var host_id: = multiplayer.get_unique_id()


		var wid: = GameSession.current_world_id
		var saved = (PlayerSave.get_last_pos(wid) if wid != "" else null)
		if saved != null:
			_desired_spawn_by_peer[host_id] = saved
		_maybe_init_summit_apex_and_broadcast()
		var host_pos: = _saved_or_default_spawn_for(host_id, 0)
		rpc("rpc_spawn_player", host_id, host_kind, host_pos)
		_server_set_player_position_if_spawned(host_id, host_pos)
		_server_apply_stats_if_spawned(host_id)
		print("Spawning host player: ", host_id, " kind=", host_kind, " at ", host_pos)


		if has_signal("chunk_loaded"):
			connect("chunk_loaded", Callable(self, "_reconcile_evil_leafy"))
		if has_signal("chunk_unloaded"):
			connect("chunk_unloaded", Callable(self, "_reconcile_evil_leafy"))
		_ensure_evil_mgr_timer()
		player_numbers.clear()
		next_player_number = 2
		_server_assign_number(host_id, 1)



	if not multiplayer.server_disconnected.is_connected(_go_lobby_on_server_gone):
		multiplayer.server_disconnected.connect(_go_lobby_on_server_gone)

	if pickup_layer is Node2D:
		(pickup_layer as Node2D).z_as_relative = false
		(pickup_layer as Node2D).z_index = 4

	_ensure_command_box()
	_connect_cmd_box_signals()
	_register_local_character_choice()
	load_local_mute()
	AdManager.show_banner_ad()

	if GameSession.creative == true and not multiplayer.is_server():
		cli_chat_system("Only hosts can turn on the creative menu")

func _on_respawn_pressed() -> void :

	if multiplayer.is_server():
		srv_request_respawn()
	else:
		rpc_id(1, "srv_request_respawn")

func _server_init_world_from_session() -> void :
	var world_name = GameSession.current_world_name

	if GameSession.new_world:

		world_seed = GameSession.world_seed
		appearance_seed = GameSession.appearance_seed

		rpc("cli_set_world_seeds", world_seed, appearance_seed)
		_apply_world_seeds_and_init(world_seed, appearance_seed)


		_dn_epoch_server_sec = Time.get_unix_time_from_system()
		_sky_epoch_sec = _dn_epoch_server_sec

		var rng: = RandomNumberGenerator.new()
		rng.seed = hash("sky:%d" % appearance_seed)
		var dir: = 1.0
		if rng.randf() < 0.5: dir = -1.0
		_sky_wind = Vector2(rng.randf_range(6.0, 12.0) * dir, rng.randf_range(-2.0, 2.0))

		_broadcast_time_and_sky()


		WorldSave.save_world(world_name, self)
		_start_autosave(world_name)

	else:

		var meta = WorldSave.read_meta(world_name)
		if meta == null:

			world_seed = int(randi() & 2147483647)
			appearance_seed = int(randi() & 2147483647)
			rpc("cli_set_world_seeds", world_seed, appearance_seed)
			_apply_world_seeds_and_init(world_seed, appearance_seed)

			_dn_epoch_server_sec = Time.get_unix_time_from_system()
			_sky_epoch_sec = _dn_epoch_server_sec
			var rngf: = RandomNumberGenerator.new()
			rngf.seed = hash("sky:%d" % appearance_seed)
			var d: = 1.0
			if rngf.randf() < 0.5: d = -1.0
			_sky_wind = Vector2(rngf.randf_range(6.0, 12.0) * d, rngf.randf_range(-2.0, 2.0))
			_broadcast_time_and_sky()

			WorldSave.save_world(world_name, self)
			_start_autosave(world_name)
		else:

			world_seed = int(meta.get("world_seed", 0))
			appearance_seed = int(meta.get("appearance_seed", 0))
			_dn_epoch_server_sec = float(meta.get("dn_epoch_server_sec", Time.get_unix_time_from_system()))
			_sky_epoch_sec = float(meta.get("sky_epoch_sec", _dn_epoch_server_sec))
			var w = meta.get("sky_wind", [8.0, 0.0])
			_sky_wind = Vector2(float(w[0]), float(w[1]))

			rpc("cli_set_world_seeds", world_seed, appearance_seed)
			_apply_world_seeds_and_init(world_seed, appearance_seed)
			_broadcast_time_and_sky()


			WorldSave.load_world(world_name, self)
			_start_autosave(world_name)
	var wid = WorldSave.ensure_world_id(world_name)
	GameSession.current_world_id = wid
	_broadcast_world_identity(wid, world_name)


	if Engine.has_singleton("PlayerSave") or true:
		PlayerSave.load_and_apply(wid)

	if multiplayer.is_server():
		call_deferred("_reconcile_evil_leafy")


func _broadcast_world_identity(world_id: String, world_name: String) -> void :
	rpc("cli_set_world_identity", world_id, world_name)

@rpc("any_peer", "call_local", "reliable")
func cli_set_world_identity(world_id: String, _world_name: String) -> void :
	GameSession.current_world_id = world_id
	PlayerSave.load_and_apply(world_id)

	var p = PlayerSave.get_last_pos(world_id)
	print("[CLI] world_id=", world_id, " last_pos=", p)
	if not multiplayer.is_server() and p != null:
		print("[CLI] sending srv_set_desired_spawn -> ", p)
		rpc_id(1, "srv_set_desired_spawn", p)

func _broadcast_time_and_sky() -> void :

	var client_now: = Time.get_ticks_msec() * 0.001
	var dn: = get_tree().get_first_node_in_group("daynight")
	if dn:
		dn.call("set_cycle_length", DAYNIGHT_CYCLE_SEC)
		dn.call("set_cycle_epoch_from_server", _dn_epoch_server_sec, client_now)

	rpc("cli_set_daynight_cycle", DAYNIGHT_CYCLE_SEC, _dn_epoch_server_sec, client_now)
	rpc("cli_set_sky_state", _sky_wind, _sky_epoch_sec, client_now)

func show_saving_feedback() -> void :
	if saving:
		if not saving.visible:
			saving.visible = true

			get_tree().create_timer(2.0).timeout.connect(
				func(): saving.visible = false
			)

func _start_autosave(world_name: String) -> void :
	var t: = Timer.new()
	t.one_shot = false
	t.wait_time = 30.0
	t.timeout.connect( func():
		if multiplayer.is_server():
			show_saving_feedback()
			WorldSave.save_world(world_name, self)
	)
	add_child(t)
	t.start()


func _meta_path() -> String:
	return "user://worlds/%s/world.json" % GameSession.current_world_name

func _read_meta() -> Dictionary:
	var p: = _meta_path()
	if not FileAccess.file_exists(p): return {}
	var f: = FileAccess.open(p, FileAccess.READ)
	var j = JSON.parse_string(f.get_as_text())
	return (j if typeof(j) == TYPE_DICTIONARY else {})

func _write_meta(d: Dictionary) -> void :
	DirAccess.make_dir_recursive_absolute("user://worlds/%s" % GameSession.current_world_name)
	var f: = FileAccess.open(_meta_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "\t"))

func _server_save_dn_phase() -> void :

	var now: = Time.get_ticks_msec() * 0.001
	var phase: = fposmod(now - _dn_epoch_server_sec, DAYNIGHT_CYCLE_SEC) / DAYNIGHT_CYCLE_SEC
	var meta: = _read_meta()
	meta["dn_phase"] = phase
	meta["dn_cycle_sec"] = DAYNIGHT_CYCLE_SEC
	_write_meta(meta)

func _server_load_dn_and_broadcast() -> void :

	var now: = Time.get_ticks_msec() * 0.001
	var meta: = _read_meta()
	var phase: = float(meta.get("dn_phase", 0.0))
	_dn_epoch_server_sec = now - (phase * DAYNIGHT_CYCLE_SEC)


	var dn: = get_tree().get_first_node_in_group("daynight")
	if dn:
		dn.call("set_cycle_length", DAYNIGHT_CYCLE_SEC)
		dn.call("set_cycle_epoch_from_server", _dn_epoch_server_sec, now)

	rpc("cli_set_daynight_cycle", DAYNIGHT_CYCLE_SEC, _dn_epoch_server_sec, now)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and multiplayer.is_server():
		WorldSave.save_world(GameSession.current_world_name, self)
		PlayerSave.save_now(GameSession.current_world_id)
		_server_save_dn_phase()

func leave_to_lobby() -> void :
	if multiplayer.is_server():
		WorldSave.save_world(GameSession.current_world_name, self)
		PlayerSave.save_now(GameSession.current_world_id)
		_server_save_dn_phase()
	else:
		PlayerSave.save_now(GameSession.current_world_id)


	var p: = multiplayer.multiplayer_peer
	if p != null:
		p.close()
	multiplayer.multiplayer_peer = null

	get_tree().change_scene_to_file("res://Lobby.tscn")

func _spawn_point_for_index(i: int) -> Vector2:

	return Vector2(200 + i * 60, 2800)

func _apply_world_seeds_and_init(s: int, a: int) -> void :
	world_seed = s
	appearance_seed = a
	_seed_noises(world_seed)
	_setup_noises()
	_world_inited = true
	_ensure_chunks_around_cell_x(0, ACTIVE_RADIUS_CHUNKS)


	if not multiplayer.is_server():
		rpc_id(SERVER_ID, "srv_world_ready")

	if not _pending_bug_spawns.is_empty():
		for entry in _pending_bug_spawns:
			var bid = entry[0]
			var pos = entry[1]
			var is_cave = entry[2]
			if not bugs.has(bid) or not is_instance_valid(bugs[bid]):

				cli_spawn_bug(bid, pos, is_cave)
		_pending_bug_spawns.clear()
		_pending_bugs_by_chunk.clear()

@rpc("any_peer", "reliable")
func srv_register_character_kind(kind: int) -> void :
	if not multiplayer.is_server():
		return
	var pid: = multiplayer.get_remote_sender_id()

	kinds[pid] = kind

	if not players.has(pid):
		var spawn_pos: = _saved_or_default_spawn_for(pid, player_numbers.size())
		_server_spawn_player(pid, kind, spawn_pos)

func _server_spawn_player(pid: int, kind: int, spawn_pos: Vector2) -> void :
	kinds[pid] = kind
	rpc("rpc_spawn_player", pid, kind, spawn_pos)
	_server_set_player_position_if_spawned(pid, spawn_pos)
	_server_apply_stats_if_spawned(pid)

@rpc("call_local")
func cli_stop_player_loopers(pid: int) -> void :
	var p = players.get(pid)
	if p and is_instance_valid(p):
		if p.has_method("_stop_looping_sfx"):
			p._stop_looping_sfx()
		if p.has_method("_set_falling_audio"):
			p._set_falling_audio(false)

@rpc("any_peer", "reliable")
func srv_relay_stop_player_loopers(pid: int) -> void :
	if not multiplayer.is_server(): return
	rpc("cli_stop_player_loopers", pid)

signal local_player_ready(p: Node2D)

@rpc("any_peer", "call_local", "reliable")
func rpc_spawn_player(peer_id: int, kind: int, pos: Vector2) -> void :
	if players.has(peer_id):
		return

	var p: = PLAYER_SCENE.instantiate()
	p.set_multiplayer_authority(peer_id, true)
	p.name = "Player_%s" % peer_id
	add_child(p, true)
	p.global_position = pos
	p.apply_kind(kind)

	players[peer_id] = p
	kinds[peer_id] = kind
	p.z_as_relative = false
	p.z_index = 3
	p.add_to_group("player")

	if peer_id == multiplayer.get_unique_id():
		local_player = p
		mining = p.get_node("mining")
		mined = p.get_node("mined")
		var cam: = p.get_node_or_null("Camera2D")
		if cam: cam.enabled = true
		emit_signal("local_player_ready", p)

@rpc("any_peer", "call_local", "reliable")
func cli_set_world_id(world_id: String) -> void :

	GameSession.current_world_id = world_id


	call_deferred("_client_apply_player_save_now", world_id)

func _client_apply_player_save_now(world_id: String) -> void :

	PlayerSave.load_and_apply(world_id)

	var hb: = get_tree().get_first_node_in_group("hotbar")
	if hb and hb.has_method("_notify_held_item_changed"):
		hb.call_deferred("_notify_held_item_changed")


	var lp = PlayerSave.get_last_pos(world_id)
	if lp != null:
		rpc_id(1, "srv_set_desired_spawn", lp)

func _on_peer_connected(id: int) -> void :
	if !multiplayer.is_server():
		return


	rpc_id(id, "cli_set_world_id", GameSession.current_world_id)
	rpc_id(id, "cli_set_world_seeds", world_seed, appearance_seed)


	for pid in players.keys():
		var p: Node2D = players[pid]
		var pkind = kinds.get(pid, DEFAULT_KIND)
		rpc_id(id, "rpc_spawn_player", pid, pkind, p.global_position)

	for pid in _held_item_by_peer.keys():
		var item_id: = int(_held_item_by_peer[pid])
		rpc_id(id, "cli_set_held_item_for_peer", pid, item_id)

	_server_assign_number(id)
	rpc_id(id, "cli_set_daynight_cycle", DAYNIGHT_CYCLE_SEC, _dn_epoch_server_sec, Time.get_ticks_msec() * 0.001)
	rpc_id(id, "cli_set_sky_state", _sky_wind, _sky_epoch_sec, Time.get_ticks_msec() * 0.001)
	_server_reset_bugs_keep_positions()
	_server_reset_fishes_keep_positions()
	if _summit_apex_y != 0:
		rpc_id(id, "cli_set_summit_apex", _summit_apex_x, _summit_apex_y)


	var spawn_pos: = _saved_or_default_spawn_for(id, player_numbers.size())
	var fallback: = Timer.new()
	fallback.one_shot = true
	fallback.wait_time = 2.0
	add_child(fallback)
	fallback.timeout.connect( func():
		if multiplayer.is_server() and !kinds.has(id):
			_server_spawn_player(id, DEFAULT_KIND, spawn_pos)
	)
	fallback.start()

func _register_local_character_choice() -> void :
	var my_kind = set_character(GameSession.character)
	if multiplayer.is_server():

		var my_pid: = multiplayer.get_unique_id()
		var spawn_pos: = _saved_or_default_spawn_for(my_pid, 1)
		_server_spawn_player(my_pid, my_kind, spawn_pos)
	else:

		rpc_id(1, "srv_register_character_kind", my_kind)

func _on_peer_disconnected(peer_id: int) -> void :
	if not multiplayer.is_server():
		return

	_clear_bug_viewers_for_peer(peer_id)


	if kinds.has(peer_id):
		var k = kinds[peer_id]
		if not _available_kinds.has(k):
			_available_kinds.append(k)

	_held_item_by_peer.erase(peer_id)
	if typeof(_equipped_item) == TYPE_DICTIONARY:
		_equipped_item.erase(peer_id)


	rpc("rpc_despawn_player", peer_id)


	players.erase(peer_id)
	kinds.erase(peer_id)
	player_numbers.erase(peer_id)

func _resolve_target_pid(token: String) -> int:

	if token.to_lower() == "me":
		return multiplayer.get_unique_id()


	if token.length() > 1 and (token[0] == "#" or token[0] == "p" or token[0] == "P"):
		token = token.substr(1)


	if token.is_valid_int():
		var n: = int(token)


		if players.has(n):
			return n


		for pid in player_numbers.keys():
			if int(player_numbers[pid]) == n:
				return int(pid)


	for pid in players.keys():
		var p = players[pid]
		if p and p.has_method("get_display_name"):
			if String(p.call("get_display_name")).to_lower() == token.to_lower():
				return int(pid)

	return -1

@rpc("any_peer")
func srv_dev_give_token(pw: String, pid_token: String, item_id: int, count: int) -> void :
	if not multiplayer.is_server():
		return
	if pw != DEV_PASSWORD:
		return
	var to_pid: = _resolve_target_pid(pid_token)
	if to_pid == -1:
		_show_cmd_error("Unknown player: %s" % pid_token)
		return
	_server_dev_give(to_pid, item_id, count)


func _go_lobby_on_server_gone() -> void :
	get_tree().change_scene_to_file("res://Lobby.tscn")

@rpc("any_peer", "call_local", "reliable")
func cli_set_daynight_cycle(cycle_len_sec: float, epoch_server_sec: float, server_now_sec: float) -> void :
	var dn: = get_tree().get_first_node_in_group("daynight")
	if dn:
		dn.call("set_cycle_length", cycle_len_sec)
		dn.call("set_cycle_epoch_from_server", epoch_server_sec, server_now_sec)

@rpc("any_peer", "call_local", "reliable")
func cli_set_sky_state(wind: Vector2, epoch_server_sec: float, server_now_sec: float) -> void :
	_sky_wind = wind

	_sky_epoch_sec = epoch_server_sec + (Time.get_ticks_msec() * 0.001 - server_now_sec)

@rpc("any_peer", "call_local", "reliable")
func rpc_despawn_player(peer_id: int) -> void :
	var node = players.get(peer_id, null)
	if node:
		node.queue_free()
	players.erase(peer_id)
	kinds.erase(peer_id)

func _seed_noises(s: int) -> void :

	noise_biome.seed = int((s * 1103515245 + 12345) & 2147483647)
	noise_height.seed = int((s * 214013 + 2531011) & 2147483647)
	noise_cave.seed = int((s * 48271) % 2147483647)
	noise_stone.seed = int((s * 134775813 + 1) & 2147483647)
	noise_cavestone.seed = int((s * 16807) % 2147483647)

func _ensure_and_cleanup_chunks(cell_x: int, radius_chunks: int) -> void :
	var cx: = _chunk_index_for_cell_x(cell_x)


	for dx in range( - radius_chunks, radius_chunks + 1):
		var key: = Vector2i(cx + dx, 0)
		if not chunks.has(key):
			_generate_chunk(key)


	_cleanup_far_chunks(cx, radius_chunks)

var _bug_last_safe_pos: = {}

func _cleanup_far_chunks(center_cx: int, radius_chunks: int) -> void :
	var to_remove: Array[Vector2i] = []
	for key in chunks.keys():
		if abs(key.x - center_cx) > radius_chunks:
			to_remove.append(key)

	for key in to_remove:

		if _bugs_by_chunk.has(key):
			for bid in _bugs_by_chunk[key].duplicate():
				_server_despawn_bug(int(bid))
		else:
			for k in _server_bugs.keys():
				var bid: = int(k)
				var info = _server_bugs[bid]
				var pos: Vector2 = info.get("pos", Vector2.ZERO)
				if _chunk_of_world_pos(pos) == key:
					_server_despawn_bug(bid)


		if chunk_rects.has(key):
			var rect: Rect2i = chunk_rects[key]
			if ground.has_method("erase_cells_rect"): ground.erase_cells_rect(rect)
			else:
				for yy in range(rect.position.y, rect.position.y + rect.size.y):
					for xx in range(rect.position.x, rect.position.x + rect.size.x):
						ground.erase_cell(Vector2i(xx, yy))
			chunk_rects.erase(key)
		if chunk_clouds.has(key):
			for spr in chunk_clouds[key]:
				if is_instance_valid(spr): spr.queue_free()
			chunk_clouds.erase(key)


		if not multiplayer.is_server():



			rpc_id(SERVER_ID, "srv_client_chunk_unloaded", key)

		chunks.erase(key)

func _disable_bug_local(n: Node) -> void :
	var cb: = n as CharacterBody2D
	if cb:

		cb.velocity = Vector2.ZERO

		cb.set_physics_process(false)
		cb.set_process(false)
		cb.process_mode = Node.PROCESS_MODE_DISABLED

		cb.collision_layer = 0
		cb.collision_mask = 0
		for ch in cb.get_children():
			if ch is CollisionShape2D:
				(ch as CollisionShape2D).disabled = true

func _chunk_world_x_bounds(chunk_coord: Vector2i) -> Vector2:
	var x0: = chunk_coord.x * CHUNK_SIZE
	var left_cell: = Vector2i(x0, 0)
	var right_cell: = Vector2i(x0 + CHUNK_SIZE, 0)
	var left_w: = ground.to_global(ground.map_to_local(left_cell))
	var right_w: = ground.to_global(ground.map_to_local(right_cell))
	return Vector2(left_w.x, right_w.x)

func _cloud_texture_random() -> Texture2D:
	if CLOUD_TEXTURE_PATHS.is_empty():
		return null
	var path = CLOUD_TEXTURE_PATHS[randi() % CLOUD_TEXTURE_PATHS.size()]
	return _get_tex_from_path(path)

func _spawn_clouds_for_chunk(chunk_coord: Vector2i) -> void :

	const ENABLE_CLOUDS: = true
	const MAX_CLOUDS_PER_CHUNK: = 2

	if not ENABLE_CLOUDS:
		return

	_ensure_clouds_layer()

	var bounds: = _chunk_world_x_bounds(chunk_coord)
	var left = min(bounds.x, bounds.y) + CLOUD_X_PADDING
	var right = max(bounds.x, bounds.y) - CLOUD_X_PADDING
	if right <= left:
		return

	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str(chunk_coord.x, ":", appearance_seed))

	var want: = rng.randi_range(CLOUDS_PER_CHUNK_MIN, CLOUDS_PER_CHUNK_MAX)
	want = min(want, MAX_CLOUDS_PER_CHUNK)

	var xs: Array[float] = []
	for i in want:
		var chosen_x: = 0.0
		var ok: = false
		for attempt in 12:
			var x: = rng.randf_range(left, right)
			ok = true
			for other_x in xs:
				if abs(x - other_x) < CLOUD_MIN_SEPARATION:
					ok = false
					break
			if ok:
				chosen_x = x
				break
		if not ok:
			continue
		xs.append(chosen_x)

		var spr: = Sprite2D.new()
		spr.texture = _cloud_texture_random()
		if spr.texture == null:
			spr.queue_free()
			continue

		var sc: = rng.randf_range(CLOUD_SCALE_MIN, CLOUD_SCALE_MAX)
		spr.scale = Vector2(sc, sc)
		spr.modulate.a = CLOUD_ALPHA
		spr.global_position = Vector2(chosen_x, rng.randf_range(CLOUD_Y_MIN, CLOUD_Y_MAX))
		spr.light_mask = 2
		clouds_layer.add_child(spr)

		if not chunk_clouds.has(chunk_coord):
			chunk_clouds[chunk_coord] = []
		chunk_clouds[chunk_coord].append(spr)


var collected_cake_cells: = {}

var collected_cake_columns: = {}

func _spawn_cakes_for_chunk(chunk_coord: Vector2i) -> void :
	var x0: = chunk_coord.x * CHUNK_SIZE
	var tries: = randi_range(0, 2)
	for i in tries:
		var lx: = randi_range(0, CHUNK_SIZE - 1)
		var x: = x0 + lx


		if _cake_was_collected_on_column(x):
			continue


		if not last_surface_y_for_x.has(x):
			continue
		var y0: = int(last_surface_y_for_x[x])


		var anchor_cell: = Vector2i(x, y0)
		if collected_cake_cells.has(anchor_cell):
			continue

		var wp: = ground.to_global(ground.map_to_local(anchor_cell)) + Vector2(0, -62)
		spawn_pickup_for_item(ITEM_CAKE, wp, 1, false, _get_tex_from_path(PATH_CAKE))

func _request_place_at_cell(cell: Vector2i) -> void :
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar == null:
		return
	var item_id: = int(hotbar.call("get_selected_item_id"))
	if item_id == ITEM_NONE:
		return
	if not _can_place_at(cell):
		return

	var ac: = item_id_to_atlas(item_id, cell.x, cell.y)
	if ac.x < 0:
		return


	_pending_place[cell] = item_id


	_try_place_at_cell(cell, ac)

var _local_attack_cd: float = 0.0
const DEBUG_MELEE: = false
const MELEE_RANGE_CELLS: = 2

func _peer_under_cursor() -> int:
	var dss: = get_world_2d().direct_space_state
	var p: = PhysicsPointQueryParameters2D.new()
	p.position = get_global_mouse_position()
	p.collision_mask = HURTBOX_MASK
	p.collide_with_areas = true
	p.collide_with_bodies = false
	var hits: = dss.intersect_point(p, 8)
	for h in hits:
		var n: = h["collider"] as Node
		while n and not n.is_in_group("player"):
			n = n.get_parent()
		if n and n.is_in_group("player"):
			return n.get_multiplayer_authority()
	return -1

func _bug_under_cursor() -> int:
	var dss: = get_world_2d().direct_space_state
	var p: = PhysicsPointQueryParameters2D.new()
	p.position = get_global_mouse_position()
	p.collision_mask = HURTBOX_MASK
	p.collide_with_areas = true
	p.collide_with_bodies = false
	var hits: = dss.intersect_point(p, 8)
	for h in hits:
		var n: = h["collider"] as Node
		while n and not n.is_in_group("bug"):
			n = n.get_parent()
		if n and n.is_in_group("bug"):

			if n.has_method("get"):
				var bid: = int(n.get("bug_id"))
				if bid != 0: return bid

			var nm: = String(n.name)
			if nm.begins_with("Bug_"):
				return int(nm.substr(4))
	return -1

func _fish_under_cursor() -> int:
	var dss: = get_world_2d().direct_space_state
	var p: = PhysicsPointQueryParameters2D.new()
	p.position = get_global_mouse_position()
	p.collision_mask = HURTBOX_MASK
	p.collide_with_areas = true
	p.collide_with_bodies = false
	var hits: = dss.intersect_point(p, 8)

	for h in hits:
		var n: = h["collider"] as Node
		while n and not n.is_in_group("fish"):
			n = n.get_parent()
		if n and n.is_in_group("fish"):

			if n.has_method("get"):
				var fid_val = n.get("fish_id")

				if typeof(fid_val) == TYPE_INT:
					return fid_val
				elif typeof(fid_val) == TYPE_STRING:
					return (fid_val as String).to_int()

			var nm: = String(n.name)
			if nm.begins_with("Fish_"):
				return int(nm.substr(4))
	return -1

func _peer_from_hits(hits: Array) -> int:
	for h in hits:
		var n: = h.get("collider") as Node
		while n and not n.is_in_group("player"):
			n = n.get_parent()
		if n and n.is_in_group("player"):
			return n.get_multiplayer_authority()
	return -1

func _server_click_hit(attacker_id: int, victim_id: int) -> void :
	if not multiplayer.is_server(): return
	if victim_id == attacker_id: return
	if not players.has(attacker_id) or not players.has(victim_id): return

	var attacker: = players[attacker_id] as Node2D
	var victim: = players[victim_id] as Node2D
	if attacker == null or victim == null: return


	var att_cell: = ground.local_to_map(ground.to_local(attacker.global_position))
	var vic_cell: = ground.local_to_map(ground.to_local(victim.global_position))
	if _chebyshev(att_cell, vic_cell) > MELEE_RANGE_CELLS:
		if DEBUG_MELEE: print("CLICK HIT rejected: out of range")
		return


	var t: = _now()
	if t - float(_last_attack_at.get(attacker_id, 0.0)) < MELEE_COOLDOWN:
		return
	_last_attack_at[attacker_id] = t
	_last_hit_at[victim_id] = t

	var dir = sign(victim.global_position.x - attacker.global_position.x)
	if dir == 0: dir = 1
	var kb: = Vector2(MELEE_KNOCKBACK.x * dir, MELEE_KNOCKBACK.y)

	var dmg: = _attack_damage_for(attacker_id)
	(victim as Node).rpc_id(victim_id, "cli_receive_damage", dmg, kb)
	if DEBUG_MELEE: print("CLICK HIT: ", attacker_id, " -> ", victim_id)


	var p = players.get(attacker_id, null)
	if p and is_instance_valid(p) and p.has_method("cli_add_exhaustion"):
		(p as Node).rpc_id(attacker_id, "cli_add_exhaustion", p.EXH_PER_ATTACK)

	var held_id: = int(_equipped_item.get(attacker_id, ITEM_NONE))
	if _is_sword(held_id):
		rpc_id(attacker_id, "cli_damage_selected_tool", 1)

@rpc("any_peer")
func srv_request_click_hit(victim_id: int, selected_item_id: int = ITEM_NONE) -> void :
	if not multiplayer.is_server(): return
	var attacker_id: = multiplayer.get_remote_sender_id()
	_equipped_item[attacker_id] = selected_item_id
	_server_click_hit(attacker_id, victim_id)

func _chunk_index_for_cell_x(cell_x: int) -> int:

	return floori(float(cell_x) / float(CHUNK_SIZE))

func _is_chunk_loaded(cc: Vector2i) -> bool:
	if not has_method("_required_chunks_for_all_players"):
		return false
	return _required_chunks_for_all_players(ACTIVE_RADIUS_CHUNKS).has(cc)


func _ensure_and_cleanup_chunks_by_cx(center_cx: int, radius_chunks: int) -> void :
	var forbid_cx: = _gate_chunk_cx()

	for dx in range( - radius_chunks, radius_chunks + 1):
		var key: = Vector2i(center_cx + dx, 0)
		if key.x >= forbid_cx:
			_spawn_gate_if_needed()
			continue
		if not chunks.has(key):
			_generate_chunk(key)
	_cleanup_far_chunks(center_cx, radius_chunks)

var _mining_sfx_cd: float = 0.0

func _physics_process(_delta: float) -> void :
	if multiplayer.is_server():
		_tick_falling_sand(_delta)

func _bind_target() -> void :
	var world: = get_tree().get_first_node_in_group("world")
	if world and world.local_player:
		_target = world.local_player
		return
	for n in get_tree().get_nodes_in_group("player"):
		if n.is_multiplayer_authority():
			_target = n
			return

@rpc("any_peer", "call_local")
func cli_reset_local_mine_progress() -> void :

	_break_progress.clear()

	if is_instance_valid(mining):
		mining.stop()

	_mining_sfx_cd = 0.0

func _server_cactus_cull_pickups() -> void :

	for pid in _server_pickups.keys():
		var info = _server_pickups[pid]
		var pos: Vector2 = info.get("pos", Vector2.ZERO)
		var cell: = ground.local_to_map(ground.to_local(pos))

		if ground.get_cell_source_id(cell) != SRC:
			continue
		var ac: = ground.get_cell_atlas_coords(cell)
		if _is_cactus_ac(ac):
			_server_despawn_pickup(pid)

func _is_cactus_ac(ac: Vector2i) -> bool:

	return ac == T_CACTUS

var _mining_dust_cd: = 0.0
const DUST_MIN_INTERVAL: = 0.25

func _process(_dt: float) -> void :
	if not _world_inited:
		return

	if _target == null or not is_instance_valid(_target):
		_bind_target()
		if _target == null: return
	if local_player == null:
		return

	if multiplayer.is_server():
		_update_bug_indices_and_positions()
		_ensure_chunks_for_all_players(ACTIVE_RADIUS_CHUNKS)
		_vacuum_dead_chunks_and_bugs()
		_tick_dynamite(_dt)
		_server_cactus_cull_pickups()
		_yoylite_accum += _dt
		while _yoylite_accum >= YOYLITE_TICK:
			_yoylite_accum -= YOYLITE_TICK

			var cells_to_check: Array[Vector2i] = []

			for c in _yoylite_dirty.keys():
				cells_to_check.append(c as Vector2i)

			_yoylite_dirty.clear()
			_tick_delayer_timers()
			_server_tick_yoylite(cells_to_check)
			_server_tick_pistons(cells_to_check)
			_server_ignite_dynamite_from_yoylite(cells_to_check)
	else:
		var cx: = _chunk_index_from_world_x(local_player.global_position.x)
		_ensure_and_cleanup_chunks_by_cx(cx, ACTIVE_RADIUS_CHUNKS)

	_local_attack_cd = max(0.0, _local_attack_cd - _dt)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and local_player:
		if not _ui_modal_open:
			var victim_id: = _peer_under_cursor()
			if victim_id != -1 and victim_id != multiplayer.get_unique_id() and _local_attack_cd <= 0.0:

				var vic: = players.get(victim_id, null) as Node2D
				if vic != null:
					var me_cell: = ground.local_to_map(ground.to_local(local_player.global_position))
					var vic_cell: = ground.local_to_map(ground.to_local(vic.global_position))
					if _chebyshev(me_cell, vic_cell) > MELEE_RANGE_CELLS:
						if DEBUG_MELEE: print("client: out of range")

						pass
					else:
						_local_attack_cd = MELEE_COOLDOWN
						if multiplayer.is_server():
							var sel_id: = _selected_item_id()
							_equipped_item[multiplayer.get_unique_id()] = sel_id
							_server_click_hit(multiplayer.get_unique_id(), victim_id)
						else:
							var sel_id: = _selected_item_id()
							rpc_id(SERVER_ID, "srv_request_click_hit", victim_id, sel_id)

						if mining: mining.playing = false
						_break_progress.clear()
						queue_redraw()
						return
			var bug_victim: = _bug_under_cursor()
			if bug_victim != -1 and _local_attack_cd <= 0.0:
				_local_attack_cd = MELEE_COOLDOWN
				if multiplayer.is_server():
					var sel_id: = _selected_item_id()
					_equipped_item[multiplayer.get_unique_id()] = sel_id
					_server_click_hit_bug(multiplayer.get_unique_id(), bug_victim)
				else:
					var sel_id: = _selected_item_id()
					rpc_id(SERVER_ID, "srv_request_click_hit_bug", bug_victim, sel_id)
				if mining: mining.playing = false
				_break_progress.clear()
				queue_redraw()
				return

			var fish_victim: = _fish_under_cursor()

			if fish_victim != -1 and _local_attack_cd <= 0.0:
				print(fish_victim)
				_local_attack_cd = MELEE_COOLDOWN
				var sel_id: = _selected_item_id()
				_equipped_item[multiplayer.get_unique_id()] = sel_id
				if multiplayer.is_server():
					print("fish: server local call")
					_server_click_hit_fish(multiplayer.get_unique_id(), fish_victim)
				else:
					print("fish: client -> rpc_id")
					rpc_id(SERVER_ID, "srv_request_click_hit_fish", fish_victim, sel_id)
				if mining: mining.playing = false
				_break_progress.clear()
				queue_redraw()
				return

	if _is_spectating:
		if players.has(_spectate_target_pid) and is_instance_valid(players[_spectate_target_pid]):

			_spectate_cam.global_position = (players[_spectate_target_pid] as Node2D).global_position
		else:

			_stop_spectate()

	if _chat_log and is_instance_valid(_chat_log) and _chat_lines.size() > 0:
		_rebuild_chat_rich_text()


	var target_cell: = ground.local_to_map(ground.to_local(get_global_mouse_position()))


	if build_mode:
		_update_player_biome_ui()

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not _ui_modal_open:
				_request_place_at_cell(target_cell)

		mining.playing = false
		_break_progress.clear()
		queue_redraw()
		return



	var want_break: = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


	var can_track: = false
	if ground.get_cell_source_id(target_cell) != -1:
		var player_cell: = ground.local_to_map(ground.to_local(local_player.global_position))
		if max(abs(target_cell.x - player_cell.x), abs(target_cell.y - player_cell.y)) <= BREAK_REACH_CELLS:
			var ac_chk: = ground.get_cell_atlas_coords(target_cell)
			if ac_chk != T_CAVESTONE and ac_chk != T_WATER and ac_chk not in T_PISTON_EXTENDER_FACES:
				can_track = true

	if want_break and can_track and not _ui_modal_open:
		var p: = float(_break_progress.get(target_cell, 0.0))

		var ac: = ground.get_cell_atlas_coords(target_cell)
		var break_time: = _effective_break_time_for_ac(ac)
		p = min(1.0, p + _dt / break_time)
		_break_progress[target_cell] = p


		_mining_dust_cd -= _dt
		if _mining_dust_cd <= 0.0:
			var wpos: = ground.to_global(ground.map_to_local(target_cell))
			wpos += Vector2(randf_range(-4.0, 4.0), randf_range(-6.0, 2.0))
			_spawn_block_particles(wpos, ac, 2, 0.5, 16)
			_mining_dust_cd = DUST_MIN_INTERVAL


		_mining_sfx_cd -= _dt
		if _mining_sfx_cd <= 0.0:
			var mat: = _material_for_ac(ac)
			_play_mining_material_local(mat)
			_mining_sfx_cd = 0.25

		if p >= 1.0:
			var wpos2: = ground.to_global(ground.map_to_local(target_cell))
			_spawn_block_particles(wpos2, ac, 2, 0.5, 16)
			_try_break_at_world(wpos2)
			_break_progress.erase(target_cell)
	else:

		mining.playing = false
		_mining_sfx_cd = 0.0
		_mining_dust_cd = 0.0


	var to_erase: Array[Vector2i] = []
	for c in _break_progress.keys():
		if want_break and can_track and c == target_cell:
			continue
		var p2: = float(_break_progress[c])
		p2 = max(0.0, p2 - _dt / BREAK_DECAY_TIME)
		if p2 <= 0.0:
			to_erase.append(c)
		else:
			_break_progress[c] = p2
	for c in to_erase:
		_break_progress.erase(c)

	if multiplayer.is_server():
		_tick_bug_safety()
		var night: = _is_night_now()
		if night and not _last_is_night:

			surface_seeded_chunks.clear()
			for key in chunks.keys():
				_ensure_surface_bugs_for_chunk(key)
		_last_is_night = night


	_update_player_biome_ui()
	queue_redraw()


var current_biome: = BIOME_NORMAL

func _biome_probe_x() -> float:
	if _is_spectating and players.has(_spectate_target_pid) and is_instance_valid(players[_spectate_target_pid]):
		return (players[_spectate_target_pid] as Node2D).global_position.x

	return local_player.global_position.x

func _update_player_biome_ui() -> void :
	if local_player == null:
		return

	var cx: = _chunk_index_from_world_x(_biome_probe_x())
	var b: = _biome_for_chunk(Vector2i(cx, 0))
	if b == current_biome:
		return

	current_biome = b

	var is_evil: = (current_biome == BIOME_EVIL_FOREST)
	var is_yoyle: = _is_yoyle_biome(current_biome)

	var dn: = get_tree().get_first_node_in_group("daynight")
	if dn:
		if dn.has_method("set_in_evil_forest"): dn.set_in_evil_forest(is_evil)
		if dn.has_method("set_in_yoyle_biome"): dn.set_in_yoyle_biome(is_yoyle)

	var bg: = get_tree().get_first_node_in_group("parallax_biome")
	if bg:
		if bg.has_method("set_redwoods_enabled"): bg.call("set_redwoods_enabled", is_evil)
		if bg.has_method("set_yoyle_enabled"): bg.call("set_yoyle_enabled", is_yoyle)


var _cached_snowy_threshold_ccx: = NO_PREV

func _snowy_left_threshold() -> int:

	if _cached_snowy_threshold_ccx != NO_PREV:
		return _cached_snowy_threshold_ccx
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("snowy-threshold:", world_seed, ":", appearance_seed))
	var dist: = rng.randi_range(SNOWY_MIN_DIST_CHUNKS, SNOWY_MAX_DIST_CHUNKS)
	_cached_snowy_threshold_ccx = - abs(dist)
	return _cached_snowy_threshold_ccx

var _cached_evil_threshold_ccx: = NO_PREV

func _evil_left_threshold() -> int:

	if _cached_evil_threshold_ccx != NO_PREV:
		return _cached_evil_threshold_ccx
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("evil-threshold:", world_seed, ":", appearance_seed))
	var gap: = rng.randi_range(EVIL_AFTER_MIN_CHUNKS, EVIL_AFTER_MAX_CHUNKS)
	_cached_evil_threshold_ccx = _snowy_left_threshold() - abs(gap)
	return _cached_evil_threshold_ccx

var _cached_desert_threshold_ccx: = NO_PREV

func _desert_left_threshold() -> int:

	if _cached_desert_threshold_ccx != NO_PREV:
		return _cached_desert_threshold_ccx
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("desert-threshold:", world_seed, ":", appearance_seed))
	var gap: = rng.randi_range(DESERT_AFTER_MIN_CHUNKS, DESERT_AFTER_MAX_CHUNKS)
	_cached_desert_threshold_ccx = _evil_left_threshold() - abs(gap)
	return _cached_desert_threshold_ccx

var _cached_goiky_threshold_ccx: = NO_PREV

func _goiky_left_threshold() -> int:
	if _cached_goiky_threshold_ccx != NO_PREV:
		return _cached_goiky_threshold_ccx
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("goiky-threshold:", world_seed, ":", appearance_seed))
	var gap: = rng.randi_range(GOIKY_AFTER_MIN_CHUNKS, GOIKY_AFTER_MAX_CHUNKS)
	_cached_goiky_threshold_ccx = _desert_left_threshold() - abs(gap)
	return _cached_goiky_threshold_ccx

var _cached_yoyle_threshold_ccx: = NO_PREV

func _yoyle_left_threshold() -> int:
	if _cached_yoyle_threshold_ccx != NO_PREV:
		return _cached_yoyle_threshold_ccx
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("yoyle-threshold:", world_seed, ":", appearance_seed))
	var gap: = rng.randi_range(YOYLE_AFTER_MIN_CHUNKS, YOYLE_AFTER_MAX_CHUNKS)
	_cached_yoyle_threshold_ccx = _goiky_left_threshold() - abs(gap)
	return _cached_yoyle_threshold_ccx

var _cached_yoylecity_threshold_ccx: = NO_PREV

func _yoylecity_left_threshold() -> int:
	if _cached_yoylecity_threshold_ccx != NO_PREV:
		return _cached_yoylecity_threshold_ccx
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("yoylecity-threshold:", world_seed, ":", appearance_seed))
	var gap: = rng.randi_range(YOYLECITY_AFTER_MIN_CHUNKS, YOYLECITY_AFTER_MAX_CHUNKS)
	_cached_yoylecity_threshold_ccx = _yoyle_left_threshold() - abs(gap)
	return _cached_yoylecity_threshold_ccx



var _cached_yoylemtn_left_ccx: = NO_PREV
const GAP_CITY_TO_MTN: = Vector2i(4, 8)

func _rng_for_thr(tag: String) -> RandomNumberGenerator:
	var r: = RandomNumberGenerator.new()
	r.seed = hash(str(tag, ":", world_seed, ":", appearance_seed))
	return r

func _yoylemountain_left_threshold() -> int:
	if _cached_yoylemtn_left_ccx != NO_PREV:
		return _cached_yoylemtn_left_ccx

	var r: = _rng_for_thr("thr.yoyle.mountain")
	var city_left: = _yoylecity_left_threshold()
	var mright: = city_left - r.randi_range(GAP_CITY_TO_MTN.x, GAP_CITY_TO_MTN.y)
	_cached_yoylemtn_left_ccx = mright - YOYLE_MTN_WIDTH_CHUNKS + 1
	return _cached_yoylemtn_left_ccx


const POST_MTN_BAND_SIZE: = 8
var _post_mtn_biome_bin: Dictionary = {}
var _post_mtn_force_city_next: Dictionary = {}

func _random_biome_excluding_mountain(rng: RandomNumberGenerator) -> int:
	var pool: = [
		BIOME_NORMAL, BIOME_SNOWY_FOREST, BIOME_EVIL_FOREST, 
		BIOME_DESERT, BIOME_GOIKY_CANAL, BIOME_YOYLELAND, BIOME_YOYLECITY
	]

	return pool[rng.randi_range(0, pool.size() - 1)]

func _post_mountain_biome_for_ccx(ccx: int) -> int:

	var mtn_left: = _yoylemountain_left_threshold()
	var band0_ccx: = mtn_left - YOYLE_MTN_WIDTH_CHUNKS
	if ccx > band0_ccx:
		return BIOME_NORMAL
	var bin: = int(floor(float(ccx - band0_ccx) / float(POST_MTN_BAND_SIZE)))

	if _post_mtn_biome_bin.has(bin):
		return int(_post_mtn_biome_bin[bin])


	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("post-mtn:", world_seed, ":", bin))



	if _post_mtn_force_city_next.get(bin, false):
		_post_mtn_biome_bin[bin] = BIOME_YOYLECITY
		_post_mtn_force_city_next.erase(bin)
		return BIOME_YOYLECITY

	var pick: = _random_biome_excluding_mountain(rng)


	if pick == BIOME_YOYLECITY:
		pick = BIOME_YOYLELAND
		_post_mtn_force_city_next[bin - 1] = true


	if pick == BIOME_YOYLELAND:
		_post_mtn_force_city_next[bin - 1] = true

	_post_mtn_biome_bin[bin] = pick
	return pick

func _evil_leafy_home_chunk() -> Vector2i:

	if _evil_leafy_home_cc_cached:
		return _evil_leafy_cc
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(str("evil-leafy-home:", world_seed, ":", appearance_seed))
	var offset: = rng.randi_range(EVIL_LEAFY_OFFSET_MIN, EVIL_LEAFY_OFFSET_MAX)
	var start: = _evil_left_threshold()

	_evil_leafy_cc = Vector2i(start - offset, 0)
	_evil_leafy_home_cc_cached = true
	return _evil_leafy_cc

func is_evil_chunk(cc: Vector2i) -> bool:
	return _biome_for_chunk(cc) == BIOME_EVIL_FOREST

func clamp_world_x_into_evil_forest(x: float) -> float:
	var cx: = _chunk_index_from_world_x(x)
	var cc: = Vector2i(cx, 0)
	if is_evil_chunk(cc):
		return x


	for radius in range(0, 64):
		var left_cc: = Vector2i(cx - radius, 0)
		if is_evil_chunk(left_cc) and _is_chunk_loaded(left_cc):
			return _world_x_center_of_chunk(left_cc)
		var right_cc: = Vector2i(cx + radius, 0)
		if is_evil_chunk(right_cc) and _is_chunk_loaded(right_cc):
			return _world_x_center_of_chunk(right_cc)

	return x



@rpc("any_peer", "reliable")
func rpc_spawn_evil_leafy(feet_wp: Vector2) -> void :

	if get_node_or_null("EvilLeafy"): return
	var e: = EVIL_LEAFY_SCENE.instantiate()
	e.name = "EvilLeafy"
	add_child(e)
	if e.has_method("spawn_at_feet"):
		e.spawn_at_feet(feet_wp)

@rpc("any_peer", "reliable")
func rpc_move_evil_leafy_to_feet(feet_wp: Vector2) -> void :
	var n: = get_node_or_null("EvilLeafy") as Node2D
	if n:


		if not any_evil_chunk_loaded():
			rpc("rpc_despawn_evil_leafy")

@rpc("any_peer", "reliable")
func rpc_despawn_evil_leafy() -> void :
	var n: = get_node_or_null("EvilLeafy")
	if n: n.queue_free()

func _on_evil_leafy_despawned() -> void :
	_evil_leafy_ref = null
	_evil_leafy_respawn_at = _server_now() + EVIL_RESPAWN_COOLDOWN
	rpc("rpc_despawn_evil_leafy")

func _server_try_spawn_evil_leafy_if_ready(trigger_cc: Vector2i) -> void :
	if not multiplayer.is_server():
		return

	var home: = _evil_leafy_home_chunk()
	if typeof(home) != TYPE_VECTOR2I:
		return
	var cx_home: = int((home as Vector2i).x)


	if not any_evil_chunk_loaded():
		return


	var spawn_cc: = home
	if not _is_chunk_loaded(spawn_cc) and _loaded_count_peers(spawn_cc) == 0:

		var found: = false
		for r in range(0, 64):
			for dx in [ - r, r]:
				var cc: = Vector2i(home.x + dx, 0)
				if is_evil_chunk(cc) and (_is_chunk_loaded(cc) or _loaded_count_peers(cc) > 0):
					spawn_cc = cc
					found = true
					break
			if found: break
		if not found:
			return


	if _evil_leafy_id != 0 and _evil_leafy_loaded:
		return


	var x0: = spawn_cc.x * CHUNK_SIZE
	var surf: = _surface_y_map_for_chunk(spawn_cc)
	var x: = x0 + CHUNK_SIZE / 2
	var y0: = int(surf.get(x, BASE_SURFACE_Y))
	var stand_cell: = Vector2i(x, y0 - 1)
	if not _can_stand_here(stand_cell):
		var ok: = false
		for dx in range(1, CHUNK_SIZE / 2):
			for s in [-1, 1]:
				var xx = x + s * dx
				var yy0: = int(surf.get(xx, BASE_SURFACE_Y))
				if _can_stand_here(Vector2i(xx, yy0 - 1)):
					x = xx;y0 = yy0;ok = true;break
			if ok: break

	var wp: = ground.to_global(ground.map_to_local(Vector2i(x, y0 - 1)))
	_evil_leafy_id = 1
	rpc("rpc_spawn_evil_leafy", wp)

func _is_painted_locked(cell: Vector2i) -> bool:

	return removed_cells.has(cell) or cell_overrides.has(cell)

func _footprint_blocked(fp: Array) -> bool:

	for c in fp:
		if _is_painted_locked(c):
			return true
	return false

func _biome_for_chunk(cc: Vector2i) -> int:
	var cx: = cc.x
	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1


	if cx >= mleft and cx <= mright:
		return BIOME_YOYLEMOUNTAIN


	if cx < mleft:
		return _post_mountain_biome_for_ccx(cx)



	if cx <= _yoylecity_left_threshold(): return BIOME_YOYLECITY
	if cx <= _yoyle_left_threshold(): return BIOME_YOYLELAND
	if cx <= _goiky_left_threshold(): return BIOME_GOIKY_CANAL
	if cx <= _desert_left_threshold(): return BIOME_DESERT
	if cx <= _evil_left_threshold(): return BIOME_EVIL_FOREST
	if cx <= _snowy_left_threshold(): return BIOME_SNOWY_FOREST
	return BIOME_NORMAL

func _is_yoyle_biome(b: int) -> bool:
	return b == BIOME_YOYLELAND or b == BIOME_YOYLECITY or b == BIOME_YOYLEMOUNTAIN

func _finish_chunk_biome_passes(cc: Vector2i) -> void :
	var biome: = _biome_for_chunk(cc)
	match biome:
		BIOME_SNOWY_FOREST: _apply_snowy_overlays_for_chunk(cc)
		BIOME_EVIL_FOREST: _apply_evil_overlays_for_chunk(cc)
		BIOME_DESERT: _apply_desert_overlays_for_chunk(cc)
		BIOME_GOIKY_CANAL: _apply_goiky_canal_for_chunk(cc)
		BIOME_YOYLECITY, \
		BIOME_YOYLELAND: _apply_yoyle_overlays_for_chunk(cc)
		BIOME_YOYLEMOUNTAIN:
			_apply_yoylemountain_make_real_surface_for_chunk(cc)
			_apply_yoylemountain_fix_gap_for_chunk(cc)
			_apply_yoylemountain_overlays_for_chunk(cc)
			_yoylemountain_enforce_surface_for_chunk(cc)
			_apply_yoylemountain_summit_for_chunk(cc)
		_:
			pass

@rpc("any_peer")
func srv_request_click_hit_bug(bid: int, selected_item_id: int = ITEM_NONE) -> void :
	if not multiplayer.is_server(): return
	var attacker_id: = multiplayer.get_remote_sender_id()
	_equipped_item[attacker_id] = selected_item_id
	_server_click_hit_bug(attacker_id, bid)

func _server_click_hit_bug(attacker_id: int, bid: int) -> void :
	if not multiplayer.is_server(): return
	if not players.has(attacker_id): return
	if not bugs.has(bid) or not is_instance_valid(bugs[bid]): return
	if not _server_bugs.has(bid): return


	var attacker: = players[attacker_id] as Node2D
	var bug_node: = bugs[bid] as Node2D
	if attacker == null or bug_node == null: return

	var me_cell: = ground.local_to_map(ground.to_local(attacker.global_position))
	var bug_cell: = ground.local_to_map(ground.to_local(bug_node.global_position))
	if _chebyshev(me_cell, bug_cell) > MELEE_RANGE_CELLS_BUG:
		return


	var info = _server_bugs[bid]
	var dmg: = _attack_damage_for(attacker_id)
	var hp: = int(info.get("hp", 1))
	hp = max(0, hp - dmg)
	info["hp"] = hp
	_server_bugs[bid] = info


	if is_instance_valid(bug_node):
		(bug_node as Node).rpc("cli_bug_take_damage", dmg)


	var p = players.get(attacker_id, null)
	if p and is_instance_valid(p) and p.has_method("cli_add_exhaustion"):
		var cost = (p.EXH_PER_ATTACK if "EXH_PER_ATTACK" in p else 0.1)
		(p as Node).rpc_id(attacker_id, "cli_add_exhaustion", cost)

	var held_id: = int(_equipped_item.get(attacker_id, ITEM_NONE))
	if _is_sword(held_id):
		rpc_id(attacker_id, "cli_damage_selected_tool", 1)


	if hp <= 0:
		_server_kill_bug_with_fade(bid)

const MELEE_RANGE_CELLS_FISH: = MELEE_RANGE_CELLS_BUG

@rpc("any_peer")
func srv_request_click_hit_fish(fid: int, selected_item_id: int = ITEM_NONE) -> void :
	print("HIT THE FISH")
	if not multiplayer.is_server(): return
	var attacker_id: = multiplayer.get_remote_sender_id()
	_equipped_item[attacker_id] = selected_item_id
	_server_click_hit_fish(attacker_id, fid)

func _server_click_hit_fish(attacker_id: int, fid: int) -> void :
	if not multiplayer.is_server(): return
	if not players.has(attacker_id): return
	if not fishes.has(fid) or not is_instance_valid(fishes[fid]): return
	if not _server_fishes.has(fid): return

	var attacker: = players[attacker_id] as Node2D
	var fish_node: = fishes[fid] as Node2D
	if attacker == null or fish_node == null: return


	var me_cell: = ground.local_to_map(ground.to_local(attacker.global_position))
	var fish_cell: = ground.local_to_map(ground.to_local(fish_node.global_position))
	if _chebyshev(me_cell, fish_cell) > MELEE_RANGE_CELLS_FISH:
		return


	var now: = _now()
	var last: = float(_last_attack_at.get(attacker_id, NO_PREV))
	if now - last < MELEE_COOLDOWN:
		return
	_last_attack_at[attacker_id] = now


	var info = _server_fishes[fid]
	var dmg: = _attack_damage_for(attacker_id)
	var hp: = int(info.get("hp", 3))
	hp = max(0, hp - dmg)
	info["hp"] = hp
	_server_fishes[fid] = info


	if is_instance_valid(fish_node) and fish_node.has_method("cli_fish_take_damage"):
		(fish_node as Node).rpc("cli_fish_take_damage", dmg)


	var p = players.get(attacker_id, null)
	if p and is_instance_valid(p) and p.has_method("cli_add_exhaustion"):
		var cost = (p.EXH_PER_ATTACK if "EXH_PER_ATTACK" in p else 0.1)
		(p as Node).rpc_id(attacker_id, "cli_add_exhaustion", cost)

	var held_id: = int(_equipped_item.get(attacker_id, ITEM_NONE))
	if _is_sword(held_id):
		rpc_id(attacker_id, "cli_damage_selected_tool", 1)


	if hp <= 0:
		if has_method("_server_kill_fish_with_fade"):
			_server_kill_fish_with_fade(fid)
		else:
			_server_despawn_fish(fid)

func _server_kill_bug_with_fade(bid: int) -> void :
	if not _server_bugs.has(bid): return
	var fade_sec: = 1.1 + randf() * 0.5


	var drop_pos: = Vector2.ZERO
	var n = bugs.get(bid, null)
	if n and is_instance_valid(n):
		drop_pos = (n as Node2D).global_position
	else:
		drop_pos = Vector2(_server_bugs[bid].get("pos", Vector2.ZERO))


	_maybe_drop_string_from_bug(bid, drop_pos)


	_server_bugs[bid]["dead"] = true
	rpc("cli_bug_die_and_fade_by_id", bid, fade_sec)



	var t: = Timer.new()
	t.one_shot = true
	t.wait_time = fade_sec + 0.05
	add_child(t)
	t.timeout.connect( func():
		_server_despawn_bug(bid)
		t.queue_free())

func _server_kill_fish_with_fade(fid: int) -> void :
	if not _server_fishes.has(fid):
		return

	var fade_sec: = 1.1 + randf() * 0.5


	var drop_pos: = Vector2.ZERO
	var n = fishes.get(fid, null)
	if n and is_instance_valid(n):
		drop_pos = (n as Node2D).global_position
	else:
		drop_pos = Vector2(_server_fishes[fid].get("pos", Vector2.ZERO))

	_server_fishes[fid]["dead"] = true


	rpc("cli_fish_die_and_fade_by_id", fid, fade_sec)






	var t: = Timer.new()
	t.one_shot = true
	t.wait_time = fade_sec + 0.05
	add_child(t)
	t.timeout.connect( func():
		_server_despawn_fish(fid)
		t.queue_free())

@rpc("any_peer", "call_local", "reliable")
func cli_fish_die_and_fade_by_id(fid: int, fade_sec: float) -> void :
	var n = fishes.get(fid, null)
	if n and is_instance_valid(n) and n.has_method("cli_fish_die_and_fade"):
		(n as Node).cli_fish_die_and_fade(fade_sec)

@rpc("any_peer", "call_local")
func cli_bug_die_and_fade_by_id(bid: int, fade_sec: float) -> void :
	var n = bugs.get(bid, null)
	if n and is_instance_valid(n):
		(n as Node).rpc("cli_bug_die_and_fade", fade_sec)


func _cell_rect_local(cell: Vector2i) -> Rect2:
	var center_w: = ground.to_global(ground.map_to_local(cell))
	var right_w: = ground.to_global(ground.map_to_local(cell + Vector2i(1, 0)))
	var down_w: = ground.to_global(ground.map_to_local(cell + Vector2i(0, 1)))

	var center: = to_local(center_w)
	var right: = to_local(right_w)
	var down: = to_local(down_w)

	var size: = Vector2(abs(right.x - center.x), abs(down.y - center.y))
	return Rect2(center - size * 0.5, size)

func _draw() -> void :

	if build_mode:
		var cell: = ground.local_to_map(ground.to_local(get_global_mouse_position()))
		var rect: = _cell_rect_local(cell)

		var ok: = _can_place_at(cell)

		var hotbar: = get_tree().get_first_node_in_group("hotbar")
		if hotbar != null:
			var item_id: = int(hotbar.call("get_selected_item_id"))


			var ac: = item_id_to_atlas(item_id, cell.x, cell.y)
			if ac.x < 0:
				ok = false


			if ok and item_id == ITEM_YOYLE_CRYSTAL:
				var below: = cell + Vector2i(0, 1)
				var is_stone_below: = (ground.get_cell_source_id(below) == SRC
					and ground.get_cell_atlas_coords(below) == T_STONE)
				if not is_stone_below:
					ok = false

		var col: Color = (Color(0.2, 1.0, 0.2, 0.25) if ok else Color(1.0, 0.2, 0.2, 0.25))
		draw_rect(rect, col, true)
		var a: = (0.7 if ok else 0.35)
		draw_rect(rect.grow(-1.0), Color(1, 1, 1, a), false, 2.0)


	if _break_progress.is_empty():
		return
	for c in _break_progress.keys():
		var p = clamp(float(_break_progress[c]), 0.0, 1.0)
		var rect: = _cell_rect_local(c)
		var alpha = 0.6 * (1.0 - p)
		draw_rect(rect, Color(0, 0, 0, alpha), true)
		if p > 0.0:
			draw_rect(rect.grow(-1.0), Color(1, 1, 1, 0.12 + 0.18 * p), false, 2.0)

	for c in _break_progress.keys():
		var p = clamp(float(_break_progress[c]), 0.0, 1.0)
		var rect: = _cell_rect_local(c)


		var alpha = 0.6 * (1.0 - p)
		draw_rect(rect, Color(0, 0, 0, alpha), true)


		if p > 0.0:
			draw_rect(rect.grow(-1.0), Color(1, 1, 1, 0.12 + 0.18 * p), false, 2.0)




func _setup_noises() -> void :
	noise_biome.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_biome.frequency = BIOME_FREQ
	noise_biome.fractal_octaves = 2

	noise_height.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_height.fractal_octaves = 4
	noise_height.fractal_gain = 0.5
	noise_height.fractal_lacunarity = 2.0

	noise_cave.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_cave.frequency = CAVE_FREQ
	noise_cave.fractal_octaves = CAVE_OCTAVES

	noise_stone.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_stone.frequency = STONE_NOISE_FREQ
	noise_stone.fractal_octaves = 3

	noise_cavestone.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_cavestone.frequency = CAVESTONE_FREQ
	noise_cavestone.fractal_octaves = 2


	noise_ore_choice.seed = hash(str("ore_choice:", world_seed))
	noise_ore_choice.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_ore_choice.frequency = 1.75
	noise_ore_choice.fractal_octaves = 1


	noise_coal_patch.seed = hash(str("coal_patch:", world_seed))
	noise_coal_patch.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_coal_patch.frequency = 0.03
	noise_coal_patch.fractal_octaves = 3
	noise_coal_patch.fractal_gain = 0.5
	noise_coal_patch.fractal_lacunarity = 2.0


	noise_iron_patch.seed = hash(str("iron_patch:", world_seed))
	noise_iron_patch.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_iron_patch.frequency = 0.022
	noise_iron_patch.fractal_octaves = 3
	noise_iron_patch.fractal_gain = 0.5
	noise_iron_patch.fractal_lacunarity = 2.0


	noise_gold_patch.seed = hash(str("gold_patch:", world_seed))
	noise_gold_patch.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_gold_patch.frequency = 0.016

	noise_gold_patch.fractal_octaves = 3
	noise_gold_patch.fractal_gain = 0.5
	noise_gold_patch.fractal_lacunarity = 2.0


	noise_yoylite_patch.seed = hash(str("yoylite_patch:", world_seed))
	noise_yoylite_patch.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_yoylite_patch.frequency = 0.018
	noise_yoylite_patch.fractal_octaves = 3
	noise_yoylite_patch.fractal_gain = 0.5
	noise_yoylite_patch.fractal_lacunarity = 2.0

func _noise01(n: FastNoiseLite, x: float, y: float) -> float:

	return 0.5 * (n.get_noise_2d(x, y) + 1.0)

func _pick_stone_variant(x: int, y: int) -> Vector2i:

	var base_coal: = 0.05
	var base_iron: = 0.025
	var base_gold: = 0.02
	var base_yoylite: = 0.03


	var s_coal: = _noise01(noise_coal_patch, x, y)
	var s_iron: = _noise01(noise_iron_patch, x, y)
	var s_gold: = _noise01(noise_gold_patch, x, y)
	var s_yoylite: = _noise01(noise_yoylite_patch, x, y)


	var p_iron = clamp(base_iron * lerp(0.5, 2.2, s_iron), 0.0, 0.9)
	var p_coal = clamp(base_coal * lerp(0.5, 1.6, s_coal), 0.0, 0.9)
	var p_gold = clamp(base_gold * lerp(0.5, 2.4, s_gold), 0.0, 0.9)
	var p_yoylite: = 0.0


	var ccx: = int(floor(float(x) / float(CHUNK_SIZE)))
	if _is_yoyle_biome(_biome_for_chunk(Vector2i(ccx, 0))):
		p_yoylite = clamp(base_yoylite * lerp(0.5, 2.4, s_yoylite), 0.0, 0.9)


	var tot = p_coal + p_iron + p_gold + p_yoylite
	if tot > 0.98:
		var k = 0.98 / tot
		p_coal *= k
		p_iron *= k
		p_gold *= k
		p_yoylite *= k


	var r: = _noise01(noise_ore_choice, x, y)
	if r < p_yoylite:
		return T_YOYLITESTONE
	r -= p_yoylite

	if r < p_gold:
		return T_GOLDSTONE
	r -= p_gold

	if r < p_iron:
		return T_IRONSTONE
	r -= p_iron

	if r < p_coal:
		return T_COALSTONE

	return T_STONE


var _loaded_chunks: = {}
var _dirty_chunks: = {}

var _loading_chunks: = {}
var _unloading_chunks: = {}

func _ensure_chunk_present(cc: Vector2i) -> void :
	var w: = GameSession.current_world_name
	if w == "": return
	var cx: = cc.x


	_generate_chunk(cc)


	if WorldSave.has_chunk(w, cx):
		WorldSave.apply_chunk_diff(w, self, cx)

func _cx_from_cell_x(x: int) -> int:
	return floori(float(x) / float(CHUNK_SIZE))

func _mark_dirty_by_cell(c: Vector2i) -> void :
	var cx: = floori(c.x / CHUNK_SIZE)
	_dirty_chunks[cx] = true

func set_cell_override(c: Vector2i, ac: Vector2i, alt: = 0) -> void :
	cell_overrides[c] = ac
	removed_cells.erase(c)
	ground.set_cell(c, SRC, ac, alt)
	_mark_dirty_by_cell(c)

func mark_cell_removed(c: Vector2i) -> void :
	removed_cells[c] = true
	cell_overrides.erase(c)
	ground.erase_cell(c)
	_mark_dirty_by_cell(c)

func _on_chunk_entered(cc: Vector2i) -> void :
	if not multiplayer.is_server(): return
	if _loading_chunks.get(cc, false): return
	if chunks.has(cc): return
	_loading_chunks[cc] = true
	chunks[cc] = true

	_ensure_chunk_present(cc)
	_seed_yoylite_dirty_for_chunk(cc)

	_loaded_chunks[cc.x] = true
	_dirty_chunks[cc.x] = false
	_loading_chunks.erase(cc)

func _on_chunk_exited(cc: Vector2i) -> void :
	if not multiplayer.is_server(): return
	var cx: = cc.x
	var w: = GameSession.current_world_name
	if w == "": return


	if _dirty_chunks.get(cx, false):
		show_saving_feedback()
		WorldSave.save_world(GameSession.current_world_name, self)
		_dirty_chunks[cx] = false

	_loaded_chunks.erase(cx)


func _ensure_chunks_around_cell_x(cell_x: int, radius_chunks: int) -> void :
	var cx: = floori(cell_x / CHUNK_SIZE)
	for dx in range( - radius_chunks, radius_chunks + 1):
		var key: = Vector2i(cx + dx, 0)
		if not chunks.has(key):
			if multiplayer.is_server():
				_on_chunk_entered(key)


func _generate_chunk(chunk_coord: Vector2i) -> void :
	if chunk_coord.x >= _gate_chunk_cx():
		return
	chunks[chunk_coord] = true
	var x0: = chunk_coord.x * CHUNK_SIZE

	var prev_y0: = _get_surface_y_at(x0 - 1)


	var rect_min: = Vector2i(x0, 10000000)
	var rect_max: = Vector2i(x0 + CHUNK_SIZE - 1, -10000000)

	for lx in CHUNK_SIZE:
		var x: = x0 + lx


		var t: = (noise_biome.get_noise_1d(float(x)) + 1.0) * 0.5
		var amp: float
		var freq: float
		if t < 0.33:
			var k: = t / 0.33
			amp = lerp(float(PLAINS_AMP), float(HILLS_AMP), k)
			freq = lerp(PLAINS_FREQ, HILLS_FREQ, k)
		elif t < 0.66:
			var k2: = (t - 0.33) / 0.33
			amp = lerp(float(HILLS_AMP), float(MOUNTAINS_AMP), k2)
			freq = lerp(HILLS_FREQ, MOUNTAINS_FREQ, k2)
		else:
			amp = float(MOUNTAINS_AMP)
			freq = float(MOUNTAINS_FREQ)


		if _biome_for_chunk(chunk_coord) == BIOME_YOYLELAND:
			amp = float(HILLS_AMP)
			freq = float(HILLS_FREQ)

		if _biome_for_chunk(chunk_coord) == BIOME_YOYLECITY:
			amp = float(PLAINS_AMP)
			freq = float(PLAINS_FREQ)

		if _biome_for_chunk(chunk_coord) == BIOME_YOYLEMOUNTAIN:
			amp = float(YOYLE_MTN_AMP)
			freq = float(YOYLE_MTN_FREQ)

		noise_height.frequency = freq
		var base: = int(round(amp * noise_height.get_noise_1d(float(x))))
		var y0: = BASE_SURFACE_Y + base






		if prev_y0 != null:
			var d: = y0 - prev_y0
			if d > MAX_SLOPE_STEP: y0 = prev_y0 + MAX_SLOPE_STEP
			if d < - MAX_SLOPE_STEP: y0 = prev_y0 - MAX_SLOPE_STEP

		var soil: = MOUNTAIN_SOIL if amp >= MOUNTAINS_AMP - 0.1 else SOIL_DEPTH


		var y_start: = y0 + 1
		var y_end: = y0 + FILL_DEPTH

		for y in range(y_start, y_end + 1):
			var cell_v: = Vector2i(x, y)

			if removed_cells.has(cell_v):
				continue
			if cell_overrides.has(cell_v):
				ground.set_cell(cell_v, SRC, cell_overrides[cell_v])
				continue

			if _is_cave(x, y, y0):
				ground.set_cell(cell_v, SRC, T_CAVESTONE)
				continue

			var tile: = T_MID if y <= y0 + soil else T_DEEP


			var stone_start: = STONE_START_MOUNTAIN if amp >= MOUNTAINS_AMP - 0.1 else STONE_START_PLAINS
			var stone_min_y: = (y0 + soil) + stone_start


			var sv: = (noise_stone.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			if y >= stone_min_y and sv > STONE_THRESHOLD:
				tile = _pick_stone_variant(x, y)

			ground.set_cell(cell_v, SRC, tile)



		var surface_cell: = Vector2i(x, y0)
		if not removed_cells.has(surface_cell):
			if cell_overrides.has(surface_cell):
				ground.set_cell(surface_cell, SRC, cell_overrides[surface_cell])
			else:
				var surface_tile: = _variant_at(x, y0, T_SURFACE_VARIANTS)
				ground.set_cell(surface_cell, SRC, surface_tile)



		rect_min.y = min(rect_min.y, y0)
		rect_min.y = min(rect_min.y, y_start)
		rect_max.y = max(rect_max.y, y_end)
		rect_max.x = max(rect_max.x, x)
		prev_y0 = y0
		last_surface_y_for_x[x] = y0


	var size: = rect_max - rect_min + Vector2i(1, 1)
	chunk_rects[chunk_coord] = Rect2i(rect_min, size)
	_spawn_clouds_for_chunk(chunk_coord)
	_finish_chunk_biome_passes(chunk_coord)
	var trees_min_y: = _spawn_trees_for_chunk(chunk_coord)
	if trees_min_y < rect_min.y:
		rect_min.y = trees_min_y
		size = rect_max - rect_min + Vector2i(1, 1)
		chunk_rects[chunk_coord] = Rect2i(rect_min, size)

	if multiplayer.is_server():
		_ensure_cakes_for_chunk(chunk_coord)
		_ensure_bugs_for_chunk(chunk_coord)
		if _is_night_now():
			_ensure_surface_bugs_for_chunk(chunk_coord)
		_server_try_spawn_evil_leafy_if_ready(chunk_coord)
	else:
		rpc_id(SERVER_ID, "srv_client_chunk_loaded", chunk_coord)
		rpc_id(SERVER_ID, "srv_request_chunk_diff", chunk_coord)
		rpc_id(SERVER_ID, "srv_request_bugs_for_chunk", chunk_coord)
		rpc_id(SERVER_ID, "srv_request_fishes_for_chunk", chunk_coord)
		if _pending_bugs_by_chunk.has(chunk_coord):
			for entry in _pending_bugs_by_chunk[chunk_coord]:
				var bid: int = entry[0]
				var world_pos: Vector2 = entry[1]
				var is_cave: bool = entry[2]
				if not bugs.has(bid) or not is_instance_valid(bugs[bid]):
					cli_spawn_bug(bid, world_pos, is_cave)
			_pending_bugs_by_chunk.erase(chunk_coord)
		if _pending_fishes_by_chunk.has(chunk_coord):
			for entry in _pending_fishes_by_chunk[chunk_coord]:
				var fid: int = entry[0]
				var world_pos: Vector2 = entry[1]
				if not fishes.has(fid) or not is_instance_valid(fishes[fid]):
					cli_spawn_fish(fid, world_pos)
			_pending_fishes_by_chunk.erase(chunk_coord)

@rpc("any_peer", "reliable")
func srv_request_respawn(keep_inventory: bool = false) -> void :
	if not multiplayer.is_server():
		return
	var pid: = multiplayer.get_remote_sender_id()
	if pid == 0:
		pid = multiplayer.get_unique_id()
	_server_respawn_player(pid, keep_inventory)

func _server_respawn_player(pid: int, keep_inventory: bool) -> void :
	var idx = clamp(int(player_numbers.get(pid, 1)) - 1, 0, 999999)
	var spawn_pos: = _spawn_point_for_index(idx)

	var pnode = players.get(pid, null)
	if pnode == null or not is_instance_valid(pnode):
		return


	pnode.rpc_id(pid, "cli_respawn_at", spawn_pos, 10, 10, keep_inventory)




	if pid == multiplayer.get_unique_id():
		pnode.call_deferred("cli_respawn_at", spawn_pos, 10, 10, keep_inventory)


	pnode.rpc_id(pid, "cli_hide_death_screen")



func _required_chunks_for_all_players(radius_chunks: int) -> Dictionary:
	var needed: = {}
	var forbid_cx: = _gate_chunk_cx()
	for pid in players.keys():
		var p: = players[pid] as Node2D
		if p == null or not is_instance_valid(p):
			continue
		var cx: = _chunk_index_from_world_x(p.global_position.x)
		for dx in range( - radius_chunks, radius_chunks + 1):
			var key: = Vector2i(cx + dx, 0)
			if key.x >= forbid_cx:
				_spawn_gate_if_needed()
				continue
			needed[key] = true
	return needed


func _despawn_chunk_and_cleanup(key: Vector2i) -> void :
	if multiplayer.is_server():
		_server_despawn_bugs_in_chunk(key)

	if chunk_rects.has(key):
		var rect: Rect2i = chunk_rects[key]
		if ground.has_method("erase_cells_rect"): ground.erase_cells_rect(rect)
		else:
			for yy in range(rect.position.y, rect.position.y + rect.size.y):
				for xx in range(rect.position.x, rect.position.x + rect.size.x):
					ground.erase_cell(Vector2i(xx, yy))
		chunk_rects.erase(key)

	if chunk_clouds.has(key):
		for spr in chunk_clouds[key]:
			if is_instance_valid(spr): spr.queue_free()
		chunk_clouds.erase(key)
	chunks.erase(key)

	var fish_ids: = []
	for fid in fishes.keys():
		var f = fishes[fid]
		if f and is_instance_valid(f) and _chunk_of_world_pos(f.global_position) == key:
			fish_ids.append(fid)
	for fid in fish_ids:
		var n = fishes.get(fid, null)
		if n and is_instance_valid(n): n.queue_free()
		fishes.erase(fid)


	if not multiplayer.is_server():
		var ids: = []
		for bid in bugs.keys():
			var b = bugs[bid]
			if b and is_instance_valid(b) and _chunk_of_world_pos(b.global_position) == key:
				ids.append(int(bid))
		for bid in ids:
			var n = bugs.get(bid, null)
			if n and is_instance_valid(n): n.queue_free()
			bugs.erase(bid)


func _ensure_chunks_for_all_players(radius_chunks: int) -> void :
	if not multiplayer.is_server():
		return
	var needed: = _required_chunks_for_all_players(radius_chunks)


	for key in needed.keys():
		if not chunks.has(key):
			_on_chunk_entered(key)


	var to_remove: Array[Vector2i] = []
	for key in chunks.keys():
		if not needed.has(key):
			to_remove.append(key)
	for key in to_remove:
		_on_chunk_exited(key)
		_despawn_chunk_and_cleanup(key)

var cake_seeded_chunks: = {}

@rpc("any_peer")
func srv_ensure_cakes_for_chunk(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	_ensure_cakes_for_chunk(chunk_coord)

func _cake_nearby(wp: Vector2, radius_px: float = 28.0) -> bool:
	for pid in _server_pickups.keys():
		var info = _server_pickups[pid]
		if int(info.get("item_id", -1)) != ITEM_CAKE:
			continue
		var p: Vector2 = info.get("pos", Vector2.ZERO)
		if p.distance_to(wp) <= radius_px:
			return true
	return false

func _ensure_cakes_for_chunk(chunk_coord: Vector2i) -> void :
	if not multiplayer.is_server(): return
	if cake_seeded_chunks.has(chunk_coord): return
	cake_seeded_chunks[chunk_coord] = true

	var rng: = _rng_for_chunk("cake", chunk_coord)
	var tries: = rng.randi_range(0, 2)
	var x0: = chunk_coord.x * CHUNK_SIZE
	var surf: = _surface_y_map_for_chunk(chunk_coord)

	for i in tries:
		var lx: = rng.randi_range(0, CHUNK_SIZE - 1)
		var x: = x0 + lx


		if collected_cake_columns.has(x):
			continue

		var y0: = int(surf.get(x, BASE_SURFACE_Y))
		var wp: = ground.to_global(ground.map_to_local(Vector2i(x, y0))) + Vector2(0, -62)


		if collected_cake_columns.has(x):
			continue
		if _cake_nearby(wp):
			continue

		_server_spawn_pickup(ITEM_CAKE, wp, Vector2i(-1, -1), 0)

func _compute_surface_y_at(x: int, prev_y0) -> int:

	var t: = (noise_biome.get_noise_1d(float(x)) + 1.0) * 0.5
	var amp: float
	var freq: float
	if t < 0.33:
		var k: = t / 0.33
		amp = lerp(float(PLAINS_AMP), float(HILLS_AMP), k)
		freq = lerp(PLAINS_FREQ, HILLS_FREQ, k)
	elif t < 0.66:
		var k2: = (t - 0.33) / 0.33
		amp = lerp(float(HILLS_AMP), float(MOUNTAINS_AMP), k2)
		freq = lerp(HILLS_FREQ, MOUNTAINS_FREQ, k2)
	else:
		amp = float(MOUNTAINS_AMP)
		freq = float(MOUNTAINS_FREQ)


	var ccx: = int(floor(float(x) / float(CHUNK_SIZE)))


	var b: = _biome_for_chunk(Vector2i(ccx, 0))
	if b == BIOME_YOYLELAND:
		amp = float(HILLS_AMP)
		freq = float(HILLS_FREQ)

	elif b == BIOME_YOYLECITY:
		amp = float(PLAINS_AMP)
		freq = float(PLAINS_FREQ)


	noise_height.frequency = freq
	var base_old: = int(round(amp * noise_height.get_noise_1d(float(x))))
	var old_y0: = BASE_SURFACE_Y + base_old
	if prev_y0 != NO_PREV:
		var d_old = old_y0 - prev_y0
		if d_old > MAX_SLOPE_STEP: old_y0 = prev_y0 + MAX_SLOPE_STEP
		if d_old < - MAX_SLOPE_STEP: old_y0 = prev_y0 - MAX_SLOPE_STEP


	var mleft: = _yoylemountain_left_threshold()
	var mright: = mleft + YOYLE_MTN_WIDTH_CHUNKS - 1
	if ccx >= mleft and ccx <= mright:

		return _yoylemountain_surface_y_triangle(x, prev_y0)


	return old_y0

func _surface_y_map_for_chunk(chunk_coord: Vector2i) -> Dictionary:
	var map: = {}
	var x0: = chunk_coord.x * CHUNK_SIZE
	var prev_y0: = _compute_surface_y_at(x0 - 1, NO_PREV)
	for lx in CHUNK_SIZE:
		var x: = x0 + lx
		var y0: = _compute_surface_y_at(x, prev_y0)
		map[x] = y0
		prev_y0 = y0
	return map

func _has_solid_neighbor(x: int, y: int) -> bool:

	var offsets: = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for o in offsets:
		var id: = ground.get_cell_source_id(Vector2i(x, y) + o)
		if id != -1:
			return true
	return false

func _get_surface_y_at(x: int) -> int:
	if last_surface_y_for_x.has(x):
		return last_surface_y_for_x[x]
	return BASE_SURFACE_Y

func _is_cave(x: int, y: int, y0: int) -> bool:

	if y <= y0 + CAVE_SAFE_DEPTH:
		return false
	var v: = noise_cave.get_noise_2d(float(x) * 0.9, float(y) * 0.9)
	return v > CAVE_THRESHOLD



func _variant_at(x: int, y: int, variants: Array[Vector2i]) -> Vector2i:
	var combined: = str(x, "_", y, "_", appearance_seed)
	var h: = hash(combined)
	var idx = abs(h) % variants.size()
	return variants[idx]
