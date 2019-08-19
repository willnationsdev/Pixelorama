extends ConfirmationDialog

const DEFAULT_WIDTH := 64
const DEFAULT_HEIGHT := 64

export(NodePath) var _path_width_edit := ""
export(NodePath) var _path_height_edit := ""

onready var width_edit = get_node(_path_width_edit) as LineEdit
onready var height_edit = get_node(_path_height_edit) as LineEdit

var width := DEFAULT_WIDTH setget set_width, get_width
var height := DEFAULT_HEIGHT setget set_height, get_height

func get_width() -> int:
	return int(width_edit.text)

func set_width(p_value: int) -> void:
	width_edit.text = str(p_value)

func get_height() -> int:
	return int(height_edit.text)

func set_height(p_value: int) -> void:
	height_edit.text = str(p_value)
