extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4
const COLLISION_MASK_OPP_CARD = 8

var card_manager_ref
var deck_ref

var input_disabled = false

signal left_mouse_button_clicked
signal left_mouse_button_released

func _ready() -> void:
	card_manager_ref = $"../CardManager"
	deck_ref = $"../PlayerDeck"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("left_mouse_button_clicked")
			raycast_at_cursor()
		else:
			emit_signal("left_mouse_button_released")

func raycast_at_cursor():
	if input_disabled:
		return
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	#parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_CARD:
			# card click
			var card_found = result[0].collider.get_parent()
			if card_found:
				card_manager_ref.card_clicked(card_found)
		elif result_collision_mask == COLLISION_MASK_DECK:
			# deck click
			deck_ref.draw_card()
		elif result_collision_mask == COLLISION_MASK_OPP_CARD:
			$"../BattleManager".opp_card_selected(result[0].collider.get_parent())
