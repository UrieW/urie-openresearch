extends ReportData
class_name TxtReportData

@export_multiline var body: String # The magic keyword for long paragraphs
var pages: int
var paragraphs:int
var words: int
var sentences: int
var lines:int
var current_page: int
var max_page_chars: int = 285

func _init() -> void:
	make_pages(body)
	
func make_pages(text:String) -> Array[String]:
	var result:Array[String] = []
	var current_idx = 0
	while current_idx < text.length():
		var page_chunk = text.substr(current_idx, max_page_chars)
		result.append(page_chunk)
		current_idx += max_page_chars
		pages += 1
	return result
