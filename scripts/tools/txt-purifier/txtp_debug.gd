@tool
extends EditorScript

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	const test = "res://reports/studies/history/The truth about Yin and Yang.txt"
	var target:TXTPurifier = TXTPurifier.new(test)
	print(target.purify())
