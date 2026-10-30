extends ReportData
class_name PodcastReportData

var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
@export_file("*.mp3") var file: String
var minutes: int
var seconds:int
var milliseconds: int
var hours: int

func equip_time()->String:
	audio_player.stream = load(file)
	var duration = audio_player.stream.get_length()
	minutes = int(duration / 60)
	seconds = int(duration) % 60
	milliseconds = int((duration - int(duration)) * 1000)
	return "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
	
	
