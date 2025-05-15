extends ColorRect

@export var spell_holder : SpellHolder
@export var container : HBoxContainer

var spell_bar_item_template = load("res://assets/instances/UI/spell_bar_item.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_bar()
	_on_spell_holder_spell_selected("0")


func _update_bar():
	for button in container.get_children():
		button.free()
	for i in range(4):
		var spell_num = str(i+1)
		var item = spell_bar_item_template.instantiate()
		var spell : Spell = spell_holder.get("Spell"+spell_num)
		if not spell: continue
		item.name = "Spell"+spell_num
		item.get_node("ProgressBar").value = 0
		item.get_node("SpellName").text = spell.spell_name
		item.get_node("Input").text = spell_num
		_set_item_color(item, Color.from_string("2b2b2b",Color.WHITE))
		container.add_child(item)


func _set_item_color(item : Button, col : Color):
	item.get_theme_stylebox("disabled").bg_color = col


func _on_spell_holder_spell_used(SpellIndex: String, cooldownTime: float) -> void:
	var node = container.get_node("Spell"+SpellIndex)
	if node:
		node.get_node("ProgressBar").value = 100
		var tween = create_tween()
		tween.tween_property(node.get_node("ProgressBar"),"value",0,cooldownTime)


func _on_spell_holder_spell_selected(SpellIndex : String) -> void:
	for spell in container.get_children():
		_set_item_color(spell, Color.from_string("2b2b2b",Color.WHITE))
	var node = container.get_node("Spell"+SpellIndex)
	if node:
		_set_item_color(node, Color.from_string("804242",Color.CRIMSON))
