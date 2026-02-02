extends Node2D

#const HAND_COUNT = 4
const CARD_WIDTH = 120
const HAND_Y_POSITION = 20
const DEFAULT_CARD_MOVE_SPEED = 0.1
 
var center_screen_x
var opp_hand = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2


func add_card_to_hand(card, speed):
	if card not in opp_hand:
		opp_hand.insert(0, card)
		update_hand_position(speed)
	else:
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)


func remove_card_from_hand(card):
	if card in opp_hand:
		opp_hand.erase(card)
		update_hand_position(DEFAULT_CARD_MOVE_SPEED)

func update_hand_position(speed):
	for i in range(opp_hand.size()):
		# get new card position base on index
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = opp_hand[i]
		# set card to start position at hand
		card.starting_position = new_position
		animate_card_to_position(card, new_position, speed)

func calculate_card_position(index):
	var total_width = (opp_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
