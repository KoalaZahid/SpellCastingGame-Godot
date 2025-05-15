extends ColorRect

var component_item_template = load("res://assets/instances/UI/component_item.tscn")

@export var inventory : Node3D

@onready var spell_bar_ui = $"../SpellBar"
@onready var spell_inventory_ui = $"../SpellInventory"

@onready var component_container = $ScrollContainer/VBoxContainer
@onready var spell_components_container = $ComponentList/HFlowContainer

@onready var spell_name_editor = $SpellName
@onready var component_description = $Description
@onready var save_button = $SaveButton
@onready var close_button = $CloseButton

@onready var info_label = $InfoSection/RichTextLabel

var current_spell : Spell = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	component_description.text = "Component Description"
	visible = false

var component_text_template = "%s  [color=cyan]+%.2f s[/color]  [color=coral]+%.0f MP[/color]"
var info_template = "CAST TIME: [color=cyan]%.2f s[/color]																	MP COST: [color=coral]%.0f[/color]"

func _input(event):
	if spell_name_editor.has_focus():
		if event is InputEventKey and event.is_pressed():
			if event.key_label == KEY_ENTER:
				spell_name_editor.text.replace("\n","")
				get_viewport().set_input_as_handled()
				current_spell.spell_name = spell_name_editor.text
				spell_bar_ui._update_bar()

func _instance_component_item(component : SpellComponentClass, remove : bool):
	var instance = component_item_template.instantiate()
	var component_item = instance.get_node("ComponentItem")
	var name_string = component.modifier_name
	var additional_info = " ("+str(component.amount)+") " if ("amount" in component) else ""
	var description : RichTextLabel = component_item.get_node("Description")
	description.text = component_text_template % [name_string+additional_info,
	component.cast_cost,
	component.mp_cost]
	
	var instance_button : Button = component_item.get_node("Button")
	instance_button.text = "-" if remove else "+"
	var new_color = Color("ff2a00") if remove else Color("00ff02")
	instance_button.add_theme_color_override("font_color", new_color)
	return instance

func update(spell : Spell):
	current_spell = spell
	update_component_label(null)
	spell_name_editor.text = spell.spell_name
	spell_name_editor.release_focus()
	spell_bar_ui._update_bar()
	for n in component_container.get_children():
		component_container.remove_child(n)
		n.queue_free()
	
	for n in spell_components_container.get_children():
		spell_components_container.remove_child(n)
		n.queue_free()
	
	for component in inventory.get_children():
		if component is not ShapeModifier:
			if (spell.spell_shape.spell_shape == ShapeModifier.Shapes.Shield and component.shield_restriction): continue
			var label = _instance_component_item(component, false)
			component_container.add_child(label)
			var label_button = label.get_node("ComponentItem")
			label_button.connect("pressed",update_component_label.bind(component))
			var add_button = label_button.get_node("Button")
			add_button.connect("pressed", add_modifier_to_spell.bind(component))
	
	for component in spell.get_children():
		if component is not SpellComponentClass: continue
		var label = _instance_component_item(component, true)
		spell_components_container.add_child(label)
		var label_button = label.get_node("ComponentItem")
		label_button.connect("pressed",update_component_label.bind(component))
		var remove_button = label_button.get_node("Button")
		remove_button.connect("pressed", remove_modifier_from_spell.bind(component))
		
	spell_inventory_ui.load_spell_info(spell)

var component_description_template = "Name: %s\nDescription: %s"
func update_component_label(component : SpellComponentClass):
	if not current_spell: return
	info_label.text = info_template % [current_spell.max_charge_time, current_spell.mp_cost]
	if not component : return
	var name_string = component.modifier_name
	var additional_info = " ("+str(component.amount)+") " if ("amount" in component) else ""
	name_string+=additional_info
	var shield_info = "\n[color=blanchedalmond]+ This Component does not apply to shields.[/color]" if component.shield_restriction else ""
	component_description.text = (component_description_template+shield_info) % [name_string,component.description]
	update(current_spell)

func add_modifier_to_spell(component : SpellComponentClass):
	for modifier in current_spell.modifiers:
		if modifier.modifier_name == component.modifier_name:
			remove_modifier_from_spell(modifier)
	component.reparent(current_spell, false)
	current_spell.modifiers.append(component)
	current_spell._modifier_change()
	update_component_label(component)
	update(current_spell)

func remove_modifier_from_spell(component : SpellComponentClass):
	var component_idx = current_spell.modifiers.find(component)
	current_spell.modifiers.remove_at(component_idx)
	component.reparent(inventory, false)
	current_spell._modifier_change()
	update_component_label(component)
	update(current_spell)

func close():
	visible = false
	if current_spell != null:
		current_spell.spell_name = spell_name_editor.text
		spell_inventory_ui.load_spell_info(current_spell)
	
	for n in component_container.get_children():
		component_container.remove_child(n)
		n.queue_free()
	
	for n in spell_components_container.get_children():
		spell_components_container.remove_child(n)
		n.queue_free()
	spell_inventory_ui.update_current_spells()

func _on_close_button_pressed() -> void:
	close()
