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
	
	make_paragraphs()
	make_words()
	make_sentences()
	make_lines()
	
func make_pages(text:String) -> Array[String]:
	var result:Array[String] = []
	var current_idx = 0
	while current_idx < text.length():
		var page_chunk = text.substr(current_idx, max_page_chars)
		result.append(page_chunk)
		current_idx += max_page_chars
		pages += 1
	return result

func make_paragraphs()->int:
	var new_pages:Array[String] = make_pages(body)
	for i in new_pages:
		var result: PackedStringArray = i.split("/n/n")
		paragraphs += result.size()
	return paragraphs
	
func make_words()->int:
	var new_pages:Array[String] = make_pages(body)
	var regex := RegEx.new()
	regex.compile("\\S+")
	
	for i in new_pages:
		var result := regex.search_all(i)
		words += result.size()
	return words
	
func make_sentences()->int:
	var new_pages:Array[String] = make_pages(body)
	var regex = RegEx.new()
	# Match any ., !, or ? that is followed by whitespace (including newlines) or end of string
	regex.compile("[.!?]+(\\s|$)")
	
	for i in new_pages:
		var matches = regex.search_all(i)
		sentences += matches.size()
	return sentences

func make_lines()->int:
	var new_pages:Array[String] = make_pages(body)
	for i in new_pages:
		lines += i.get_slice_count("/n")
	return lines
