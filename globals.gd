extends Node

var global_reading_percentage:float = 0
var current_report: ReportData = null
var year:int = 2026
var age:String = "AD"
var total_year:String = str(year) + age
var version:float = 0.01
var game_title:String = "Urie's Open Research"
var game_subtitle:String = "Starring Yululu"
var full_title:String = game_title + "-" + game_subtitle

#var d_scene: Control = Disclaimer.new()
#var tutorial1:Tutorial = Tutorial.new(1)
#var tutorial2:Tutorial = Tutorial.new(2)
#var tutorial3:Tutorial = Tutorial.new(3)
var current_dir: String = "res://reports"
