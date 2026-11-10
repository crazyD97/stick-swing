extends Node
## One in-app purchase API. Today it is a STUB that "buys" instantly and remembers the
## purchase in the save file. Phase 4 swaps in GodotGooglePlayBilling behind the same calls.
## The real version must acknowledge purchases right away (Play refunds after 3 days otherwise).
##
##   if await Purchases.buy("remove_ads"): ...
##   Purchases.is_owned("remove_ads")

const PRODUCTS: Dictionary = {
	"remove_ads": {"title": "Remove ads", "price": "$1.99"},
}


func _ready() -> void:
	Ads.ads_removed = is_owned("remove_ads")


func buy(product_id: String) -> bool:
	if not PRODUCTS.has(product_id):
		push_warning("Purchases: unknown product %s" % product_id)
		return false
	print("Purchases(stub): bought %s" % product_id)
	await get_tree().process_frame
	SaveManager.set_value("purchases", product_id, true)
	if product_id == "remove_ads":
		Ads.ads_removed = true
	Analytics.log_event("purchase", {"product": product_id})
	EventBus.purchase_completed.emit(product_id)
	return true


func is_owned(product_id: String) -> bool:
	return bool(SaveManager.get_value("purchases", product_id, false))
