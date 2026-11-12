extends ReportData
class_name TxtReportData

# Match these to your Text Explorer's $explorer/text RichTextLabel size & font
const READER_BOX_SIZE := Vector2(400, 250) 
const READER_FONT: Font = preload("res://assets/fnt/AdventPro-SemiBold.ttf")
const READER_FONT_SIZE: int = 16

@export_multiline var body: String:
	set(value):
		body = value
		_update_stats()

var pages: int = 1
var paragraphs: int = 0
var words: int = 0
var sentences: int = 0
var lines: int = 0
var current_page: int = 0

func _update_stats() -> void:
	paragraphs = body.split("\n", false).size()
	words = body.split(" ", false).size()
	
	# Calculate exact wrapped height using your reader's width
	var text_size: Vector2 = READER_FONT.get_multiline_string_size(
		body,
		HORIZONTAL_ALIGNMENT_LEFT,
		READER_BOX_SIZE.x,
		READER_FONT_SIZE
	)
	
	var line_height: float = READER_FONT.get_height(READER_FONT_SIZE)
	lines = maxi(1, ceili(text_size.y / line_height))
	pages = maxi(1, ceili(text_size.y / READER_BOX_SIZE.y))
