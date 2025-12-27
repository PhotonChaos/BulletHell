class_name DialogueChain
extends RefCounted

# The Level should be the one to call most of the dialogue methods.

#class DialogueLink:
	#var speaker: String
	#var emotion: String
	#var text: String
	#
	#func _init(_speaker: String, _emotion: String, _text: String) -> void:
		#speaker = _speaker
		#emotion = _emotion
		#text = _text

## Emitted when a dialogue script or chain trigger an event
signal new_text(on_left: bool, speaker: String, emotion: String, text: String)

## Emitted when the script calls for the speaker to exit the dialogue. Used to hide the sprite.
signal speaker_exit(on_left: bool)

## Emits when the script calls for a cue. Used by Levels for things like effects and bosses entering
signal event_cue(cue: String, args: Array[String])


const DIALOGUE_TEXT = "text"
const DIALOGUE_EVENT = "event"
const DIALOGUE_CALLBACK = "callback"

const _ACTION_BGM = "bgm"
const _ACTION_TITLECARD = "titlecard"
const _ACTION_EXIT = "exit"
#const _ACTION_ENTER = "enter"

var chain: Array = []
var chain_index: int = 0

# Builder Functions

static func new_from_script(path: String):
	return DialogueChain.new().add_script_from_text(path)

func add_link(side: String, speaker: String, emotion: String, text: String) -> DialogueChain:
	chain.push_back([DIALOGUE_TEXT, side, speaker, emotion, text])
	return self


func add_callback(callback: Callable) -> DialogueChain:
	chain.push_back([DIALOGUE_CALLBACK, callback])
	return self
	

## Append dialogue to this object based on a text file of the following format:[br]
## - Each newline is a new dialogue link[br]
## - [L|R]:[speaker_id]:[emotion]:This is an example sentence. Observe: Colons after the first two can be used normally.[br]
## - *event_name param1 param2 etc...*
func add_script_from_text(path: String) -> DialogueChain:
	for i in _parse_text(path):
		chain.push_back(i)
		
	return self

func set_script_from_text(path: String) -> DialogueChain:
	chain.clear()
	add_script_from_text(path)
	
	return self

func _parse_text(path: String) -> Array:
	var parsed = []
	
	var textFile = FileAccess.open(path, FileAccess.READ)
	var text = textFile.get_as_text()
	textFile.close()
	
	for line in text.split("\n"):
		line = line.strip_edges()
		
		if line.is_empty() or line[0] == "#":
			# Ignore empty lines and comments
			continue
		
		if line[0] == "*":
			# Case for actions
			var params = line.substr(1, len(line)-2).split(" ")
			
			if len(params) < 1:
				Log.error("Dialogue event with no params in file " + path)
				continue
			
			parsed.push_back([DIALOGUE_EVENT, params[0], params.slice(1)])
			
		else:
			# Case for text
			var params = line.split(":", true, 3)

			if len(params) < 4:
				# If the line is messed up, throw an error but continue
				Log.error("Invalid dialogue line in file " + path)
				continue
			
			parsed.push_back([DIALOGUE_TEXT, params[0], params[1], params[2], params[3]])
		
	return parsed

# Running Functions
## Runs the next link in the chain, emitting signals as needed.[br]
## Returns the type of link run. If no link was run because the chain is empty, returns an empty string
func run_next_link() -> String:
	var link = chain.pop_front()
	
	if not link:
		return ""
	
	if len(link) == 0:
		Log.error("Empty link!")
		return ""
	
	if link[0] == DIALOGUE_TEXT:
		new_text.emit(link[1], link[2], link[3], link[4])
	elif link[0] == DIALOGUE_EVENT:
		if link[1] == _ACTION_EXIT:
			speaker_exit.emit(link[2][0] == "L")
			
		event_cue.emit(link[1], link[2])
	elif link[0] == DIALOGUE_CALLBACK:
		if not link[1] is Callable:
			Log.error("Callback dialogue link does not have a callable as it's parameter!")
			return ""
			
		if len(link) == 3:
			(link[1] as Callable).callv(link[2])
		else:
			(link[1] as Callable).call()
	else:
		Log.error("Dialogue has invalid link type " + link[0])
		return ""
		
	return link[0]
