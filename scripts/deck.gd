extends Node2D

const CARD_DRAW_SPEED = 0.2
const CARD_SCENE_PATH = "res://scenes/card.tscn"
const STARTING_HAND_SIZE = 5

var player_deck = ["Golshi", "Tachyon", "Tachyon", "Stego", "Teio", "Tachyon", "Tachyon", "Tachyon"]
var card_db_ref
var drawn_card_this_turn = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_db_ref = preload("res://scripts/CardDB.gd")
	for i in range (STARTING_HAND_SIZE):
		draw_card()
		drawn_card_this_turn = false
	drawn_card_this_turn = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func draw_card():
	if drawn_card_this_turn: 
		return
	drawn_card_this_turn = true
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$SleeveImg.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(player_deck.size())
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	# set card img
	var card_img_path = str("res://assets/CardsImg/" + card_drawn_name + ".png")
	new_card.get_node("CardImg").texture = load(card_img_path)
	# set card stats
	new_card.attack = card_db_ref.CARDS[card_drawn_name][0]
	new_card.health = card_db_ref.CARDS[card_drawn_name][1]
	var card_stats = new_card.get_node("Stats")
	card_stats.get_node("Attack").text = str(new_card.attack)
	card_stats.get_node("Health").text = str(new_card.health)
	# get card type
	new_card.card_type = card_db_ref.CARDS[card_drawn_name][2]
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	drawn_card_this_turn = false
