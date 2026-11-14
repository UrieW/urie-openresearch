extends Control

const FolderItemButtonPreload = preload("res://scenes/ui/buttons/navigation/items/exploreitem.tscn")

@export var items_per_page: int = 12
@onready var file_grid: GridContainer = $explorer/fcmargins/filegrid

@onready var page_label: Label = $explorer/navibox/pagelabel

@onready var item_info: RichTextLabel = $iteminfo/info
@onready var sub_info: VBoxContainer = $subinfo1/textrows2

@onready var navbox: HBoxContainer = $explorer/navibox
@onready var ae_btn: Button = $explorer/navibox/ae
@onready var d_btn: Button = $explorer/navibox/dbtn
@onready var fe_btn: Button = $explorer/navibox/fexit
@onready var t_btn: Button = $explorer/navibox/tbtn
@onready var back_btn: Button = $explorer/navibox/back
@onready var nxt_btn: Button = $explorer/navibox/next
@onready var ea_btn: Button = $explorer/navibox/eabtn

# Store all master item nodes or data
var all_items: Array = []
var current_page: int = 0
var total_pages: int = 1
signal app_closed

func _ready()->void:
	set_items_by_path.call_deferred(Globals.current_dir)
#	ae_btn.pressed.connect(show_ae_menu)
	d_btn.pressed.connect(show_disclaimer)
#	t_btn.pressed.connect(show_tutorial)
	fe_btn.pressed.connect(exit_folder)
	back_btn.pressed.connect(prev_page)
	nxt_btn.pressed.connect(next_page)
#	ea_btn.pressed.connect(exit_explorer)
	
func set_items(new_items: Array) -> void:
	all_items = new_items
	total_pages = int(ceil(float(all_items.size()) / items_per_page))
	current_page = clampi(current_page, 0, max(0, total_pages - 1))
	page_label.text = str(current_page + 1)
	show_page(current_page)
	grid_focus_first_item.call_deferred()
	
func grid_focus_first_item():
	if file_grid.get_child_count() > 0:
		var first_child = file_grid.get_child(0)
		
		# If your child is a custom Scene container holding a button:
		if first_child.has_node("exploreitem"):
			first_child.get_node("exploreitem").grab_focus()
			
		# If the child itself is the Button node:
		elif first_child is Button:
			first_child.grab_focus()
			
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_file_exp_folderescape"):
		# Wait for the fade-out (0.5s) PLUS your custom delay before continuing
		#await get_tree().create_timer(0.3).timeout
		
		if Globals.current_dir == "res://reports": #or Input.is_action_pressed("ui_cancel"):			
			exit_explorer()
		else:
			exit_folder()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_mainapp_escape"):
		exit_explorer()
		get_viewport().set_input_as_handled()

func set_items_by_path(path_str: String) -> void:	
	var dir = DirAccess.open(path_str)
	if not dir:
		print("Failed to open directory: ", path_str)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var result: Array = []
	
	while file_name != "":
		# Ignore system navigation shorthand (. and ..)
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
			
		# Construct the absolute full path to the item
		var full_path = path_str.path_join(file_name)
		
		if dir.current_is_dir():
			# It's a folder! Save it to your array
			result.append(full_path)
		else:
			# It's a file! Only append it if it matches your expected data type
			if file_name.ends_with(".tres"):
				result.append(full_path)
			
		file_name = dir.get_next()
		
	dir.list_dir_end()
	
	# --- SORT NUMERICALLY (NATURAL ORDER) HERE ---
	result.sort_custom(func(a: String, b: String):
		# naturalnocasecmp_to returns -1 if 'a' should come before 'b'
		return a.naturalnocasecmp_to(b) < 0
	)
	
	# Push the newly populated array to set_items
	set_items(result)

func show_page(page: int) -> void:
	current_page = clampi(page, 0, max(0, total_pages - 1))
	page_label.text = str(current_page + 1) # Update label on every page turn
	
	# Clear current children in grid
	for child in file_grid.get_children():
		file_grid.remove_child(child)
		child.queue_free()
	
	# Calculate slice range
	var start = current_page * items_per_page
	var end = min(start + items_per_page, all_items.size())
	
	# Add items for the current page
	for i in range(start, end):
		var folder_item_button: Button = FolderItemButtonPreload.instantiate() as Button
		var rslot: Node = folder_item_button.get_node("reportslot") as Node
		var itemnum: Label = folder_item_button.get_node("itemnum") as Label
		
		file_grid.add_child(folder_item_button)
		if rslot and itemnum:
			rslot.equip_report(all_items[i])
			folder_item_button.equip_icon()
			folder_item_button.equip_report_info()
			folder_item_button.equip_folder()
			folder_item_button.focus_entered.connect(show_report_info.bind(folder_item_button))
			folder_item_button.focus_exited.connect(erase_report_info.bind(folder_item_button))
			folder_item_button.mouse_entered.connect(show_report_info.bind(folder_item_button))
			folder_item_button.mouse_exited.connect(erase_report_info.bind(folder_item_button))
			folder_item_button.pressed.connect(check_entry.bind(folder_item_button))
			itemnum.text = str(i+1)
		
		folder_item_button.show()
		
	# Add this at the end of show_page() after adding all folder_item_button children:
	var children = file_grid.get_children()
	for idx in range(children.size()):
		var btn: Control = children[idx]
		var last_btn: Control = children[-1]
		last_btn.focus_neighbor_right = ae_btn.get_path()
		last_btn.focus_neighbor_bottom = ae_btn.get_path()
		ae_btn.focus_neighbor_left = last_btn.get_path()
		
		# If this button is in the bottom row (no item 5 slots below it), point Down to navbox
		if idx + file_grid.columns >= children.size():
			btn.focus_neighbor_bottom = ae_btn.get_path()
			
	# Point navbox buttons Up back to the first grid item (or last grid item)
	if children.size() > 0:
		for nav_child in navbox.get_children():
			if nav_child is Button:
				nav_child.focus_neighbor_top = children[0].get_path()

		
func show_report_info(target: Button) -> void:
	item_info.text = target.s3text
	var report = target.get_node("reportslot").report
	
	if DirAccess.dir_exists_absolute(report):
		item_info.text = target.s3text
		return
	
	var report_instance = load(report)
	if report_instance is ReportData:
		sub_info.show()
		sub_info.show_report_info(report_instance)

		
func erase_report_info(target:Button)->void:
	if target.focus_exited:
		item_info.text = ""
		sub_info.hide_report_info()
		sub_info.hide()
		
func next_page() -> void:
	if current_page < total_pages - 1:
		show_page(current_page + 1)

func prev_page() -> void:
	if current_page > 0:
		show_page(current_page - 1)

#func show_ae_menu()->void:
#	var AEMENUPRELOAD: PackedScene = preload()
#	var ae_menu: Control = AEMENUPRELOAD.instantiate()
#	get_tree().current_scene.add_child(ae_menu)
	
func show_disclaimer()->void:
	var DISCLAIMERPRELOAD: PackedScene = preload("res://scenes/app/disclaimer/disclaimer.tscn")
	var disclaimer:Control = DISCLAIMERPRELOAD.instantiate()
	add_child(disclaimer)

#func show_tutorial()->void:
#	var TUTORIALPRELOAD: PackedScene = preload()
#	var tutorial: Control = TUTORIALPRELOAD.instantiate()
#	get_tree().current_scene.add_child(tutorial)

func exit_folder()->void:
	if Globals.current_dir == "res://reports":
		return
	
	else:	
		Globals.current_dir = Globals.current_dir.get_base_dir() 
		set_items_by_path.call_deferred(Globals.current_dir)
	
func enter_folder(file_name: String)->void:
	var target: String = "/"
	if file_name.ends_with(".tres"):
		return
			
	target += file_name
	
	Globals.current_dir += target
	set_items_by_path.call_deferred(Globals.current_dir)
	
func enter_file(file_name:String)->void:
	var target: String = file_name.get_base_dir()
	
	if !file_name.ends_with(".tres"):
		return
	
	Globals.current_dir = target
	Globals.current_report = load(file_name)
		
	if Globals.current_report is TxtReportData:
		get_parent().get_parent().text_opened.emit()
	else:
		get_parent().get_parent().audio_opened.emit()

#used for checking the dest, by button press
func check_entry(target:Button)->void:
	var rslot = target.get_node("reportslot")
	if not rslot:
		return
		
	if !rslot._is_report_data():
		enter_folder(rslot.folder)
	else:
		enter_file(rslot.report)
		
func exit_explorer()->void:
	#open_universal_menu
	#if yes:
	#fade_out
	app_closed.emit()
