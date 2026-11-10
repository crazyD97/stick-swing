extends Node
## Global signals so scenes never need direct references to each other.
## Emit: EventBus.score_changed.emit(10)   Listen: EventBus.score_changed.connect(_on_score)

@warning_ignore_start("unused_signal")

## Gameplay
signal level_started(level_id: String)
signal level_won(level_id: String, score: int, stars: int)
signal level_lost(level_id: String, score: int)
signal score_changed(score: int)
signal coins_changed(coins: int)
signal player_hit
signal player_died

## App / flow
signal game_paused(paused: bool)
signal scene_changed(scene_path: String)
signal settings_changed(key: String, value: Variant)

## Monetization
signal reward_granted(placement: String)
signal purchase_completed(product_id: String)

@warning_ignore_restore("unused_signal")
