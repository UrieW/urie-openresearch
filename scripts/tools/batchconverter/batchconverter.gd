# BatchConverter.gd
@tool
extends EditorScript

# Paths to your folders (make sure the folders exist)
const TXT_DIR = "res://assets/txt/reports/"
const TRES_DIR = "res://reports/"

func _run():
	convert_batch()

func convert_batch():
	var dir = DirAccess.open(TXT_DIR)
	if not dir:
		print("Failed to open source directory: ", TXT_DIR)
		return
		
	# Ensure the output directory exists
	if not DirAccess.dir_exists_absolute(TRES_DIR):
		DirAccess.make_dir_absolute(TRES_DIR)

	# Start scanning the directory
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count = 0

	while file_name != "":
		# Ignore directories and only process .txt files
		if not dir.current_is_dir() and file_name.ends_with(".txt"):
			var txt_path = TXT_DIR + file_name
			# Replace extension .txt with .tres
			var tres_name = file_name.get_basename() + ".tres"
			var tres_path = TRES_DIR + tres_name
			
#			if parse_and_save(txt_path, tres_path):
#				count += 1
				
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Batch processing complete! Successfully converted ", count, " files.")
	
	# Force Godot to scan the file system so the new .tres files appear instantly
	get_editor_interface().get_resource_filesystem().scan()

#func parse_and_save(txt_path: String, tres_path: String) -> bool:
#	var file = FileAccess.open(txt_path, FileAccess.READ)
#	if not file:
#		print("Could not read file: ", txt_path)
#		return false
		
	# --- Adjust this parsing logic based on your text format ---
	#var name_data = file.get_line().trim_edges()
#	file.close()
	
	# Create and populate resource
	#var res = ItemData.new()
	#res.item_name = name_data
	
	# Save the resource
	#var error = ResourceSaver.save(res, tres_path)
	#if error == OK:
	#	return true
	#else:
	#	print("Error saving ", tres_path, " Code: ", error)
	#	return false
