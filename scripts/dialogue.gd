class_name DialogueChain
extends RefCounted

class DialogueLink:
	var speaker: String
	var emotion: String
	var text: String
	
	func _init(_speaker: String, _emotion: String, _text: String) -> void:
		speaker = _speaker
		emotion = _emotion
		text = _text


var actions: Array = []


func add_link(speaker: String, emotion: String, text: String) -> DialogueChain:
	actions.push_back(DialogueLink.new(speaker, emotion, text))
	return self


func add_callback(callback: Callable) -> DialogueChain:
	actions.push_back(callback)
	return self

func add_script_from_text(path: String) -> DialogueChain:
	# Append dialogue to this object based on a text file of the following format:
	# - Each newline is a new dialogue link
	# speaker_id:emotion:This is an example sentence. Obsere: Colons after the first two can be used normally.
	return self

func set_script_from_text(path: String) -> DialogueChain:
	# Replace the entire chain using the text file.
	return self

func _parse_text(path: String) -> Array[DialogueLink]:
	var parsed = []
	
	var textFile = FileAccess.open(path, FileAccess.READ)
	var text = textFile.get_as_text()
	textFile.close()
	
	for line in text.split("\n"):
		var params = line.split(":", true, 2)
		
		if len(params) < 3:
			if not line.strip_edges().is_empty():
				# If the line is messed up (and not just a blank spacer line) throw an error, but continue
				Logger.error("Invalid dialogue line in file " + path)
				
			continue
		
		parsed.push_back(DialogueLink.new(params[0], params[1], params[2]))
		
	return parsed
