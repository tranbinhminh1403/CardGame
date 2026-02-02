extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1

const DEFAULT_CARD_SCALE = 0.85
const CARD_LARGE_SCALE = 1
const CARD_SMALL_SCALE = 0.85


var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_ref

var played_monster_this_turn = false
var selected_monster

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_ref = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_position = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_position.x, 0, screen_size.x),clamp(mouse_position.y, 0, screen_size.y))

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#var selected_card = raycast_check()
			#if selected_card:
				#start_drag(selected_card)
		#else:
			#if card_being_dragged:
				#finish_drag()

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)

func finish_drag():
	card_being_dragged.scale = Vector2(CARD_LARGE_SCALE, CARD_LARGE_SCALE)
	var card_slot_found = raycast_check_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			if !played_monster_this_turn:
				played_monster_this_turn = true
				card_being_dragged.scale = Vector2(CARD_SMALL_SCALE, CARD_SMALL_SCALE)
				card_being_dragged.z_index = 0
				card_slot_found.z_index = -1
				is_hovering_on_card = false
				card_being_dragged.is_in_slot = card_slot_found
				# remove card from hand
				player_hand_ref.remove_card_from_hand(card_being_dragged)
				# stay in EMPTY slot
				card_being_dragged.position = card_slot_found.position
				#### in case not want to change card slot 
				#card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
				####
				# switch to state if there is already card in slot, have o be change in case allowing move card between slot
				card_slot_found.card_in_slot = true
				card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
				$"../BattleManager".player_cards_on_battlefield.append(card_being_dragged)
				card_being_dragged = null
				return
	player_hand_ref.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null

func get_highest_z_index_card(cards):
	var highest_card = cards[0].collider.get_parent()
	var highest_z_index = highest_card.z_index
	for i in range (1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if (current_card.z_index > highest_z_index):
			highest_card = current_card
			highest_z_index = current_card.z_index
	return highest_card
# raycast check click on something
func raycast_check():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_highest_z_index_card(result)
	return null

func raycast_check_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
		#return get_highest_z_index_card(result)
	return null

func highlight_card(card: Node2D, hovered: bool):
	if hovered:
		card.scale = Vector2(CARD_LARGE_SCALE, CARD_LARGE_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1

func connect_card_signals(card: Node2D):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card: Node2D):
	if card.is_in_slot:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)
	
func on_hovered_off_card(card: Node2D):
	if !card.is_in_slot && !card_being_dragged:
		highlight_card(card, false)
		# check new card stack on hover
		var new_card_hover = raycast_check()
		if new_card_hover:
			highlight_card(new_card_hover, true)
		else:
			is_hovering_on_card = false

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func _on_end_turn_pressed() -> void:
	pass # Replace with function body.

func reset_played_monster():
	played_monster_this_turn = false

func card_clicked(card):
	if card.is_in_slot:
		# on field
		if $"../BattleManager".is_opp_turn:
			if card not in $"../BattleManager".player_cards_that_attacked_this_turn:
				if $"../BattleManager".opp_cards_on_battlefield.size() == 0:
					$"../BattleManager".direct_attack(card, "Player")
					return
				else:
					select_card_for_battle(card)
	else:
		start_drag(card)

func select_card_for_battle(card):
	# toggle select monster
	if selected_monster:
		if selected_monster == card:
			card.position.y += 20
			selected_monster = null
		else:
			selected_monster.position.y += 20
			selected_monster = card
			card.position.y -= 20
	else:
		selected_monster = card
		card.position.y -= 20

func unselected_selected_monster():
	if selected_monster:
		selected_monster.position.y -= 20
		selected_monster = null
