extends ColorRect

@onready var frame = $"."

@export var spell_holder : SpellHolder
@export var inventory : Node3D

@onready var spell_container = $ScrollContainer/VBoxContainer
@onready var fire_spell_button = $FireSpellButton
@onready var create_new_spell_button = $CreateNewSpellButton
@onready var description = $Description
@onready var edit_spell_button = $EditSpell
@onready var title_label = $TitleLabel

@onready var spell_preview = $SubViewportContainer/SubViewport/Spell_Preview
@onready var fake_player = spell_preview.get_node("Player")

@onready var spell_editor = $"../Spell_Editor"

var title_template = "Current Spells (%.0f)"

var description_template = "Spell Name: %s
Element: [color=orange]%s[/color]
Cast Time: %.2f second(s)
MP Cost: %.0f MP
Components: %s"

var selected_spell : Spell = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame.visible = false
	edit_spell_button.visible = false
	fire_spell_button.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Inventory"):
		frame.visible = not frame.visible
		spell_holder.active = not frame.visible
		if frame.visible:
			spell_holder.reset_selected_spell()
			update_current_spells()
		else:
			spell_editor.close()
		load_spell_info(null)

func update_current_spells():
	# clears the children
	for n in spell_container.get_children():
		spell_container.remove_child(n)
		n.queue_free()

	for spell : Spell in spell_holder.get_children():
		var button = Button.new()
		button.name = spell.name
		button.text = spell.spell_name
		#button.set_meta("Spell", spell)
		spell_container.add_child(button)
		button.connect("pressed", _spell_button_pressed.bind(spell))
	
	title_label.text = title_template % spell_holder.get_child_count()

func _spell_button_pressed(spell : Spell):
	load_spell_info(spell)

var stored_spell_info = {}

func load_spell_info(spell : Spell):
	if not spell:
		if selected_spell != null:
			selected_spell.caster = stored_spell_info.caster
			selected_spell.spell_container = stored_spell_info.container
			selected_spell.holder = stored_spell_info.holder
			selected_spell.affect_caster = stored_spell_info.affect_caster
			selected_spell.lifetime = stored_spell_info.lifetime
		selected_spell = null
		description.text = ""
		edit_spell_button.visible = false
		fire_spell_button.visible = false
		return
	var components_string = ""
	
	if spell.modifiers.size() == 0:
		components_string = "None"
	else:
		for i in spell.modifiers.size():
			var component = spell.modifiers[i]
			var additional_info = " ("+str(component.amount)+") " if ("amount" in component) else ""
			components_string += component.modifier_name+additional_info
			if i < spell.modifiers.size() - 1:
				components_string += ", "
	
	description.text = description_template % [spell.spell_name, spell.element_toString(), spell.max_charge_time, spell.mp_cost, components_string]
	edit_spell_button.visible = true
	fire_spell_button.visible = true
	if selected_spell != null:
		selected_spell.caster = stored_spell_info.caster
		selected_spell.spell_container = stored_spell_info.container
		selected_spell.holder = stored_spell_info.holder
		selected_spell.affect_caster = stored_spell_info.affect_caster
		selected_spell.lifetime = stored_spell_info.lifetime
		#selected_spell.free()
		
	selected_spell = spell
	stored_spell_info = {
		caster = spell.caster,
		container = spell.spell_container,
		holder = spell.holder,
		affect_caster = spell.affect_caster,
		lifetime = spell.lifetime
	}
	#fake_player.add_child(selected_spell)
	selected_spell.caster = fake_player
	selected_spell.spell_container = spell_preview.get_node("SpellContainer")
	selected_spell.holder = spell_preview.get_node("Player/SpellHolder")
	selected_spell.affect_caster = false
	selected_spell.lifetime = 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
#var start_loop = false
#func _process(delta: float) -> void:
	#if start_loop and selected_spell != null:
		#selected_spell.charge(delta)
		#pass


func _on_fire_spell_button_pressed() -> void:
	selected_spell.initialize()
	#selected_spell.spell_available = true
	var max_charge = selected_spell.max_charge_time
	var timer : float = 0
	var delta = 1./60.
	while timer < max_charge:
		selected_spell.charge(delta)
		await get_tree().create_timer(delta).timeout
		timer += delta
	selected_spell.release()
	pass # Replace with function body.


func _on_edit_spell_pressed() -> void:
	spell_editor.visible = true
	#spell_editor.set_meta("SpellObject",selected_spell)
	spell_editor.update(selected_spell)
