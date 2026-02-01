extends Node

const CARD_SMALLER_SCALE = 0.85
const CARD_MOVE_SPEED = 0.2

var battle_timer
var empty_monster_card_slots = []

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

func _on_end_turn_pressed() -> void:
	opponent_turn()

func opponent_turn():
	$"../EndTurn".disabled = true
	$"../EndTurn".visible = false
	
	# if able to draw, draw then waot 1 sec
	if $"../OppDeck".opp_deck.size() != 0:
		$"../OppDeck".draw_card()
		battle_timer.start()
		await battle_timer.timeout
	
	
	# check free monster slot
	if empty_monster_card_slots.size() == 0:
		end_opponent_turn()
		return
	# play card
	await opp_play_card()
	
	# end turn
	
	# reset draw count
	end_opponent_turn()

func opp_play_card():
	# get random empty card slot
	var opp_hand = $"../OppHand".opp_hand
	if opp_hand.size() == 0:
		end_opponent_turn()
		return
	var random_empty_monster_card_slot = empty_monster_card_slots[randi_range(0, empty_monster_card_slots.size() - 1)]
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
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	$"../EndTurn".disabled = false
	$"../EndTurn".visible = true
	$"../PlayerDeck".reset_draw()
	$"../CardManager".reset_played_monster()
