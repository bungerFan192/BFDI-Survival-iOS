
extends Node2D

@onready var admob: Admob = $Admob

signal rewarded_ready
signal rewarded_failed
signal rewarded_closed
signal rewarded_granted

signal interstitial_ready
signal interstitial_failed
signal interstitial_closed

var is_initialized: = false
var rewarded_loaded: = false
var banner_loaded: = false
var loading: = false
var loading_banner: = false
var fail_count: = 0
const FAIL_THRESHOLD: = 3

var banner_retry_attempts: = 0
const BANNER_MAX_RETRIES: = 3
var banner_show_requested: = false


var inter_loaded: = false
var inter_loading: = false
var inter_fail_count: = 0
const INTER_FAIL_THRESHOLD: = 3


var _seen_first_lobby: = false



func _ensure_inter_loaded() -> void :
	if not is_initialized: return
	if inter_loaded or inter_loading: return
	inter_loading = true
	admob.load_interstitial_ad()


func maybe_show_lobby_interstitial() -> void :

	if not _seen_first_lobby:
		_seen_first_lobby = true
		_ensure_inter_loaded()
		return


	if is_initialized and inter_loaded:
		admob.show_interstitial_ad()
	else:
		_ensure_inter_loaded()



func _on_admob_interstitial_ad_loaded(ad_info: AdInfo, response_info: ResponseInfo) -> void :
	inter_loaded = true
	inter_loading = false
	emit_signal("interstitial_ready")

func _on_admob_interstitial_ad_failed_to_load(ad_info: AdInfo, error_data: LoadAdError) -> void :
	inter_loaded = false
	inter_loading = false
	inter_fail_count += 1
	emit_signal("interstitial_failed")

	if inter_fail_count < INTER_FAIL_THRESHOLD:
		_ensure_inter_loaded()

func _on_admob_interstitial_ad_failed_to_show_full_screen_content(ad_info: AdInfo, error_data: AdError) -> void :

	inter_loaded = false
	inter_loading = false
	inter_fail_count += 1
	emit_signal("interstitial_closed")
	if inter_fail_count < INTER_FAIL_THRESHOLD:
		_ensure_inter_loaded()

func _on_admob_interstitial_ad_dismissed_full_screen_content(ad_info: AdInfo) -> void :

	inter_loaded = false
	inter_loading = false
	inter_fail_count = 0
	emit_signal("interstitial_closed")
	_ensure_inter_loaded()

func _ready() -> void :
	admob.initialize()

func _on_admob_initialization_completed(status_data: InitializationStatus) -> void :
	is_initialized = true
	_ensure_reward_loaded()
	_ensure_banner_loaded()

func _ensure_reward_loaded() -> void :
	if not is_initialized: return
	if rewarded_loaded or loading: return
	loading = true
	admob.load_rewarded_ad()

func _ensure_banner_loaded() -> void :
	if not is_initialized: return
	if banner_loaded or loading_banner: return
	loading_banner = true
	admob.load_banner_ad()

func show_banner_ad():

	if banner_loaded and is_initialized:
		admob.show_banner_ad()
		return


	banner_show_requested = true
	banner_retry_attempts = 0
	_try_load_banner_again()

func _try_load_banner_again():
	if not is_initialized:
		return
	if banner_retry_attempts >= BANNER_MAX_RETRIES:

		banner_show_requested = false
		return
	banner_retry_attempts += 1

	banner_loaded = false
	loading_banner = false
	_ensure_banner_loaded()

func _on_admob_banner_ad_loaded(ad_info: AdInfo, response_info: ResponseInfo) -> void :
	banner_loaded = true
	loading_banner = false

	if banner_show_requested and is_initialized:
		admob.show_banner_ad()
	banner_show_requested = false
	banner_retry_attempts = 0

func _on_admob_banner_ad_failed_to_load(ad_info: AdInfo, error_data: LoadAdError) -> void :
	banner_loaded = false
	loading_banner = false
	if banner_show_requested:

		_try_load_banner_again()


func is_reward_ready() -> bool:
	return rewarded_loaded

func show_reward_ad():
	if rewarded_loaded and is_initialized:
		admob.show_rewarded_ad()

func manual_load():

	fail_count = 0
	rewarded_loaded = false
	_ensure_reward_loaded()



func _on_admob_rewarded_ad_loaded(ad_info: AdInfo, response_info: ResponseInfo) -> void :
	rewarded_loaded = true
	loading = false
	emit_signal("rewarded_ready")

func _on_admob_rewarded_ad_failed_to_load(ad_info: AdInfo, error_data: LoadAdError):
	rewarded_loaded = false
	loading = false
	fail_count += 1
	emit_signal("rewarded_failed")

	if fail_count < FAIL_THRESHOLD:
		_ensure_reward_loaded()

func _on_admob_rewarded_ad_failed_to_show_full_screen_content(ad_info: AdInfo, error_data: AdError):

	rewarded_loaded = false
	loading = false
	fail_count += 1
	emit_signal("rewarded_closed")
	if fail_count < FAIL_THRESHOLD:
		_ensure_reward_loaded()

func _on_admob_rewarded_ad_dismissed_full_screen_content(ad_info: AdInfo):

	rewarded_loaded = false
	loading = false
	emit_signal("rewarded_closed")

	fail_count = 0
	_ensure_reward_loaded()

func _on_admob_rewarded_ad_user_earned_reward(ad_info: AdInfo, reward_data: RewardItem):
	emit_signal("rewarded_granted")
