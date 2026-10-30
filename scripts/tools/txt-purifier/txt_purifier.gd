extends Node
class_name TXTPurifier
#turns a formatted string into long, one line paragraph seen in
#text editors.

@export_file("txt") var path:String
var lines:PackedStringArray
var text:String

#call method, use, by using the class name, instead of _init, in the
#func's name
func _init(_filename:String) -> void:
	path = _filename
	
#does exactly, as pictured...	
func load_text_file(file_path: String) -> String:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close() # Optional, but good practice
		return content
	else:
		push_error("File not found: " + file_path)
		return ""
	
#main purify method, CALL AFTER _init!!!!!!
func purify() -> String:
	var spliced_txt:String = text
	var new_txt:String = "none"
	
	text = load_text_file(path)
	text = text.replace("/n", " ")
	text = text.replace("  ", " ")
	lines = text.split(" ", true)
	
	spliced_txt = " ".join(lines)
	
	#return the result text, in the func...
	new_txt = spliced_txt
	return new_txt
	
