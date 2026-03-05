extends Node

const ZEPHYR_DAMAGE = 10

var card_to_destroy = []

func trigger_ability(battle_manager_ref, card_with_ability, input_manager):
	input_manager.input_disabled = true
	battle_manager_ref.enable_end_turn_button(false)
	await battle_manager_ref.wait(1.0)
	
	for card in battle_manager_ref.opp_cards_on_battlefield:
		# dam calc
		card.health = max(0, card.health - ZEPHYR_DAMAGE)
		var card_stats = card.get_node("Stats")
		card_stats.get_node("Health").text = str(card.health)
		
		if card.health == 0:
			card_to_destroy.append(card)
		
	await battle_manager_ref.wait(1.0)
	
	if card_to_destroy.size() > 0:
		for card in card_to_destroy:
			battle_manager_ref.destroy_card(card, "Opponent")
	
	battle_manager_ref.destroy_card(card_with_ability, "Player")
	await battle_manager_ref.wait(1.0)
	
	battle_manager_ref.enable_end_turn_button(true)
	input_manager.input_disabled = false
	
	
	
