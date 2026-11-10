extends Node
## One ads API for every game. Today it is a STUB: in the editor and on desktop it pretends
## to show ads and always grants the reward, so you can build the flow before any SDK exists.
## Wiring the real AdMob plugin (Poing Studios) happens in Phase 4; only this file changes.
##
##   var ok: bool = await Ads.show_rewarded("continue")
##   if ok: give_reward()
##   Ads.show_interstitial()   # between levels only, never mid-play

signal rewarded_finished(placement: String, rewarded: bool)

## Google's public test IDs. Never put real IDs here until release.
const TEST_IDS: Dictionary = {
	"banner": "ca-app-pub-3940256099942544/6300978111",
	"interstitial": "ca-app-pub-3940256099942544/1033173712",
	"rewarded": "ca-app-pub-3940256099942544/5224354917",
}

## Set by Purchases when the player buys "remove_ads". Rewarded ads stay available
## because the player chooses to watch them.
var ads_removed: bool = false
var stub_delay: float = 0.5


func show_rewarded(placement: String) -> bool:
	Analytics.log_event("ad_rewarded_requested", {"placement": placement})
	print("Ads(stub): rewarded ad '%s'" % placement)
	await get_tree().create_timer(stub_delay, true).timeout
	EventBus.reward_granted.emit(placement)
	rewarded_finished.emit(placement, true)
	return true


func show_interstitial(placement: String = "between_levels") -> void:
	if ads_removed:
		return
	print("Ads(stub): interstitial '%s'" % placement)


func show_banner() -> void:
	if not ads_removed:
		print("Ads(stub): banner shown")


func hide_banner() -> void:
	pass
