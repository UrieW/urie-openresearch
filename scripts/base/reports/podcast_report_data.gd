extends ReportData
class_name PodcastReportData

var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
@export_file("*.mp3") var file: String
var minutes: int
var seconds:int
var hours: int

func equip_time()->String:
	audio_player.stream = load(file)
	var duration = audio_player.stream.get_length()
	hours = int(duration / 3600)
	minutes = int(duration / 60)
	seconds = int(duration) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
	
	
