extends Control

const AXIS_SIZE_MIN := 1
const AXIS_SIZE_MAX := 16384

var current_path := ""
var opensprite_file_selected := false

export var _path_tools_container := @""
export var _path_new_image_dialog := @""
export var _path_scale_image_dialog := @""

onready var pencil_tool = get_node(_path_tools_container).get_node("Pencil") as ToolButton
onready var eraser_tool = get_node(_path_tools_container).get_node("Eraser") as ToolButton
onready var fill_tool = get_node(_path_tools_container).get_node("Fill") as ToolButton
onready var new_image_dialog = get_node(_path_new_image_dialog) as ConfirmationDialog
onready var scale_image_dialog = get_node(_path_scale_image_dialog) as ConfirmationDialog

class MenuIds:
	enum File {
		NEW = 0,
		IMPORT,
		EXPORT,
		EXPORT_AS,
		QUIT
	}

class MenuItem:
	extends Reference
	
	var title := ""
	var keybinding := 0
	
	func _init(p_title, p_keybinding):
		title = p_title
		keybinding = p_keybinding

var menu_items := {
	MenuIds.File.NEW: MenuItem.new(tr("New..."), KEY_MASK_CTRL + KEY_N),
	MenuIds.File.IMPORT: MenuItem.new(tr("Import..."), KEY_MASK_CTRL + KEY_O),
	MenuIds.File.EXPORT: MenuItem.new(tr("Export..."), KEY_MASK_CTRL + KEY_S),
	MenuIds.File.EXPORT_AS: MenuItem.new(tr("Export as..."), KEY_MASK_SHIFT + KEY_MASK_CTRL + KEY_S),
	MenuIds.File.QUIT: MenuItem.new(tr("Quit"), KEY_MASK_CTRL + KEY_Q)
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	var edit_menu_items := {
#		"Undo" : KEY_MASK_CTRL + KEY_Z,
#		"Redo" : KEY_MASK_SHIFT + KEY_MASK_CTRL + KEY_Z,
#		"Scale Image" : 0
#		}
	var file_menu : PopupMenu = Global.file_menu.get_popup()
#	var edit_menu : PopupMenu = Global.edit_menu.get_popup()
	var i = 0
	for a_id in MenuIds.File:
		print(a_id)
		print(MenuIds.File.NEW)
		print(typeof(a_id))
		print(typeof("hi"))
		print(typeof(1))
		print(typeof(MenuIds.File.NEW))
		print(menu_items)
		var item = menu_items[a_id]
		file_menu.add_item(item.title, i, item.keybinding)
		i += 1
#	i = 0
#	for item in edit_menu_items.keys():
#		edit_menu.add_item(item, i, edit_menu_items[item])
#		i += 1
	file_menu.connect("id_pressed", self, "file_menu_id_pressed")
	#edit_menu.connect("id_pressed", self, "edit_menu_id_pressed")
	
	pencil_tool.connect("pressed", self, "_on_Tool_pressed", [pencil_tool])
	eraser_tool.connect("pressed", self, "_on_Tool_pressed", [eraser_tool])
	fill_tool.connect("pressed", self, "_on_Tool_pressed", [fill_tool])
	pencil_tool.hint_tooltip = tr("P for left mouse button, Alt + P for right mouse button")
	eraser_tool.hint_tooltip = tr("E for left mouse button, Alt + E for right mouse button")
	fill_tool.hint_tooltip = tr("B for left mouse button, Alt + B for right mouse button")
	
func _input(event):
	#Handle tool shortcuts
	if event.is_action_pressed("right_pencil_tool"):
		_on_Tool_pressed(pencil_tool, false, false)
	elif event.is_action_pressed("left_pencil_tool"):
		_on_Tool_pressed(pencil_tool, false, true)
	elif event.is_action_pressed("right_eraser_tool"):
		_on_Tool_pressed(eraser_tool, false, false)
	elif event.is_action_pressed("left_eraser_tool"):
		_on_Tool_pressed(eraser_tool, false, true)
	elif event.is_action_pressed("right_fill_tool"):
		_on_Tool_pressed(fill_tool, false, false)
	elif event.is_action_pressed("left_fill_tool"):
		_on_Tool_pressed(fill_tool, false, true)

func file_menu_id_pressed(id : int) -> void:
	match id:
		MenuIds.File.NEW:
			$CreateNewImage.popup_centered()
			Global.can_draw = false
		MenuIds.File.IMPORT:
			$OpenSprite.popup_centered()
			Global.can_draw = false
			opensprite_file_selected = false
		MenuIds.File.EXPORT:
			if current_path == "":
				$SaveSprite.popup_centered()
				Global.can_draw = false
			else:
				save_sprite()
		MenuIds.File.EXPORT_AS:
			$SaveSprite.popup_centered()
			Global.can_draw = false
		MenuIds.File.QUIT:
			get_tree().quit()

func _on_CreateNewImage_confirmed() -> void:
	var width := clamp(float(new_image_dialog.get_width()), AXIS_SIZE_MIN, AXIS_SIZE_MAX)
	var height := clamp(float(new_image_dialog.get_height()), AXIS_SIZE_MIN, AXIS_SIZE_MAX)
	new_canvas(Vector2(width, height).floor())

func _on_OpenSprite_file_selected(path : String) -> void:
	var image := Image.new()
	if image.load(path) == OK:
		opensprite_file_selected = true
		new_canvas(image.get_size(), image)
	else:
		OS.alert(tr("Can't load file."))

func new_canvas(size : Vector2, sprite : Image = null) -> void:
	for child in Global.vbox_layer_container.get_children():
		if child is PanelContainer:
			child.queue_free()
	Global.canvas.queue_free()
	Global.canvas = load("res://Canvas.tscn").instance()
	Global.canvas.size = size
	if sprite:
		Global.canvas.current_sprite = sprite
		Global.canvas.current_sprite.convert(Image.FORMAT_RGBA8)
	Global.canvas_parent.add_child(Global.canvas)

func _on_SaveSprite_file_selected(path : String) -> void:
	current_path = path
	save_sprite()

func save_sprite() -> void:
	var whole_image := Image.new()
	whole_image.create(int(Global.canvas.size.x), int(Global.canvas.size.y), false, Image.FORMAT_RGBA8)
	for layer in Global.canvas.layers:
		whole_image.blend_rect(layer[0], Rect2(Global.canvas.position, Global.canvas.size), Vector2.ZERO)
		layer[0].lock()
	var err = whole_image.save_png(current_path)
	if err != OK:
		OS.alert("Can't save file")

func _on_OpenSprite_popup_hide() -> void:
	if !opensprite_file_selected:
		Global.can_draw = true
		print(Global.can_draw)

func _on_ViewportContainer_mouse_entered() -> void:
	Global.has_focus = true

func _on_ViewportContainer_mouse_exited() -> void:
	Global.has_focus = false
	
func _can_draw_true() -> void:
	Global.can_draw = true

func _can_draw_false() -> void:
	Global.can_draw = false

func _on_Tool_pressed(tool_pressed : BaseButton, mouse_press := true, key_for_left := true) -> void:
	var current_action := tool_pressed.name
	if (mouse_press && Input.is_action_just_released("left_mouse")) || (!mouse_press && key_for_left):
		Global.current_left_tool = current_action
		Global.left_indicator.get_parent().remove_child(Global.left_indicator)
		tool_pressed.add_child(Global.left_indicator)
	elif (mouse_press && Input.is_action_just_released("right_mouse")) || (!mouse_press && !key_for_left):
		Global.current_right_tool = current_action
		Global.right_indicator.get_parent().remove_child(Global.right_indicator)
		tool_pressed.add_child(Global.right_indicator)


func _on_ScaleImage_confirmed() -> void:
	var width := clamp(float(scale_image_dialog.get_width()), AXIS_SIZE_MIN, AXIS_SIZE_MAX)
	var height := clamp(float(scale_image_dialog.get_height()), AXIS_SIZE_MIN, AXIS_SIZE_MAX)
	
	for i in range(Global.canvas.layers.size() - 1, -1, -1):
		var sprite := Image.new()
		sprite = Global.canvas.layers[i][1].get_data()
		sprite.resize(width, height)
		Global.canvas.layers[i][0] = sprite
		Global.canvas.layers[i][0].lock()
		Global.canvas.update_texture(i)

	Global.canvas.size = Vector2(width, height).floor()

func add_layer(is_new := true) -> void:
	var new_layer := Image.new()
	if is_new:
		new_layer.create(int(Global.canvas.size.x), int(Global.canvas.size.y), false, Image.FORMAT_RGBA8)
	else: #clone layer
		new_layer.copy_from(Global.canvas.layers[Global.canvas.current_layer_index][0])
	new_layer.lock()
	var new_layer_tex := ImageTexture.new()
	new_layer_tex.create_from_image(new_layer, 0)
	Global.canvas.layers.append([new_layer, new_layer_tex, null, true])
	Global.canvas.generate_layer_panels()

func _on_AddLayerButton_pressed() -> void:
	add_layer()

func _on_RemoveLayerButton_pressed() -> void:
	Global.canvas.layers.remove(Global.canvas.current_layer_index)
	Global.canvas.generate_layer_panels()

func _on_MoveUpLayer_pressed() -> void:
	change_layer_order(1)

func _on_MoveDownLayer_pressed() -> void:
	change_layer_order(-1)

func change_layer_order(rate : int) -> void:
	var change = Global.canvas.current_layer_index + rate
	
	var temp = Global.canvas.layers[Global.canvas.current_layer_index]
	Global.canvas.layers[Global.canvas.current_layer_index] = Global.canvas.layers[change]
	Global.canvas.layers[change] = temp
	
	Global.canvas.generate_layer_panels()
	Global.canvas.current_layer_index = change
	Global.canvas.get_layer_container(Global.canvas.current_layer_index).changed_selection()
	
func _on_CloneLayer_pressed() -> void:
	add_layer(false)

func _on_MergeLayer_pressed() -> void:
	var selected_layer = Global.canvas.layers[Global.canvas.current_layer_index][0]
	Global.canvas.layers[Global.canvas.current_layer_index - 1][0].blend_rect(selected_layer, Rect2(Global.canvas.position, Global.canvas.size), Vector2.ZERO)
	Global.canvas.layers[Global.canvas.current_layer_index - 1][0].lock()
	Global.canvas.update_texture(Global.canvas.current_layer_index - 1)
	_on_RemoveLayerButton_pressed()
