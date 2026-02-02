extends Node

const CARD_SMALLER_SCALE = 0.85
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 1
const BATTLE_FIELD_OFFSET = 100

var battle_timer
var empty_monster_card_slots = []

var opp_cards_on_battlefield = []
var player_cards_on_battlefield = []

var player_cards_that_attacked_this_turn = []

var player_health
var opp_health

var is_opp_turn = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_monster_card_slots.append($"../CardField/OppField/Front1")
	empty_monster_card_slots.append($"../CardField/OppField/Front2")
	empty_monster_card_slots.append($"../CardField/OppField/Front3")
	empty_monster_card_slots.append($"../CardField/OppField/Front4")
	empty_monster_card_slots.append($"../CardField/OppField/Front5")
	
	player_health = STARTING_HEALTH
	opp_health = STARTING_HEALTH
	
	$"../GameHUD/Health/PlayerHealth".text = str(player_health)
	$"../GameHUD/Health/OppHealth".text = str(opp_health)

func wait(time):
	battle_timer.wait_time =time
	battle_timer.start()
	await battle_timer.timeout

func _on_end_turn_pressed() -> void:
	is_opp_turn = true
	$"../CardManager".unselected_selected_monster()
	player_cards_that_attacked_this_turn = []
	opponent_turn()

func opponent_turn():
	$"../GameHUD/EndTurn".disabled = true
	$"../GameHUD/EndTurn".visible = false
	
	# if able to draw, draw then waot 1 sec
	if $"../OppDeck".opp_deck.size() != 0:
		$"../OppDeck".draw_card()
		battle_timer.start()
		await battle_timer.timeout
	
	
	# check free monster slot
	# play card
	if empty_monster_card_slots.size() != 0:
		await opp_play_card()
	# try attack
	if opp_cards_on_battlefield.size() != 0:
		var opp_cards_to_attack = opp_cards_on_battlefield.duplicate()
		for card in opp_cards_to_attack:
			if player_cards_on_battlefield.size() != 0:
				# attack
				var card_to_attack =player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "Opponent")
			else:
				# direct attack
				await direct_attack(card, "Opponent")

	# end turn
	end_opponent_turn()
	
func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		new_pos_y = 0
		player_cards_that_attacked_this_turn.append(attacking_card)
	#var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	var new_pos = Vector2(960, new_pos_y)
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		# deal dam to player
		player_health = max(0, player_health - attacking_card.attack)
		$"../GameHUD/Health/PlayerHealth".text = str(player_health)
		
	else:
		# deal dam to opponent
		opp_health = max(0, opp_health - attacking_card.attack)
		$"../GameHUD/Health/OppHealth".text = str(opp_health)
	
	# move back after attack
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.is_in_slot.position, CARD_MOVE_SPEED)
	attacking_card.z_index = 0
	
	await wait(1.0)

func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		player_cards_that_attacked_this_turn.append(attacking_card)
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.is_in_slot.position, CARD_MOVE_SPEED)
	
	# calc dam
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	var defending_card_stats = defending_card.get_node("Stats")
	defending_card_stats.get_node("Health").text = str(defending_card.health)
	
	# deal dam back to attacking card
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	var attacking_card_stats = attacking_card.get_node("Stats")
	attacking_card_stats.get_node("Health").text = str(attacking_card.health)
	
	await wait(1.0)
	
	attacking_card.z_index = 0
	var card_was_destroy = false
	if attacking_card.health == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroy = true
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		card_was_destroy = true
	if card_was_destroy:
		await wait(1.0)

func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerDiscard".position
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		card.is_in_slot.get_node("Area2D/CollisionShape2D").disabled = false

	else:
		new_pos = $"../OppDiscard".position
		if card in opp_cards_on_battlefield:
			opp_cards_on_battlefield.erase(card)
	
	card.is_in_slot.card_in_slot = false
	card.is_in_slot = null
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)

func opp_play_card():
	# get random empty card slot
	var opp_hand = $"../OppHand".opp_hand
	if opp_hand.size() == 0:
		end_opponent_turn()
		return
	var random_empty_monster_card_slot = empty_monster_card_slots.pick_random()
	empty_monster_card_slots.erase(random_empty_monster_card_slot)
	# play highest atkm card
	var card_with_highest_atk = opp_hand[0]
	for card in opp_hand:
		if card.attack > card_with_highest_atk.attack:
			card_with_highest_atk = card
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)

	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE), CARD_MOVE_SPEED)
	card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	# remove card from hand
	$"../OppHand".remove_card_from_hand(card_with_highest_atk)
	card_with_highest_atk.is_in_slot = random_empty_monster_card_slot
	opp_cards_on_battlefield.append(card_with_highest_atk)
	
	await wait(1.0)

func end_opponent_turn():
	$"../GameHUD/EndTurn".disabled = false
	$"../GameHUD/EndTurn".visible = true
	$"../PlayerDeck".reset_draw()
	$"../CardManager".reset_played_monster()
	is_opp_turn = false
