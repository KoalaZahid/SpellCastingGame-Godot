extends Node3D
class_name SpellHolder

signal spell_used(SpellIndex : String, cooldownTime : float)
signal spell_selected(SpellIndex : String)

@export var Spell1 : Spell
@export var Spell2 : Spell
@export var Spell3 : Spell
@export var Spell4 : Spell
var active_spell : Spell = null

@export var active : bool = true;

@export var spell_charge_bar : ProgressBar
var _spell_idx = ""

func _input(event: InputEvent) -> void:
	if not active: return
	if event.is_action_pressed("spell_1"):
		_spell_idx = "1"
		_set_active_spell(Spell1)
	elif event.is_action_pressed("spell_2"):
		_spell_idx = "2"
		_set_active_spell(Spell2)
	elif event.is_action_pressed("spell_3"):
		_spell_idx = "3"
		_set_active_spell(Spell3)
	elif event.is_action_pressed("spell_4"):
		_spell_idx = "4"
		_set_active_spell(Spell4)


func _set_active_spell(chosen_spell : Spell):
	active_spell = chosen_spell if active_spell!=chosen_spell else null
	if active_spell != null:
		spell_selected.emit(_spell_idx)
	else:
		spell_selected.emit("0")
	spell_charge_bar.visible = active_spell!=null


func reset_selected_spell():
	if active_spell == null: return
	_set_active_spell(active_spell)

func _ready() -> void:
	spell_charge_bar.visible = false


var _mouse_holding = false
func _process(delta: float) -> void:
	if not active_spell or not active: return
	spell_charge_bar.value = active_spell.charge_time/active_spell.max_charge_time*100
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not _mouse_holding:
			_mouse_holding = true
			active_spell.initialize()
		active_spell.charge(delta)
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _mouse_holding:
		_mouse_holding = false
		active_spell.release()
		await active_spell.spell_used
		spell_used.emit(_spell_idx, active_spell.cooldown)
