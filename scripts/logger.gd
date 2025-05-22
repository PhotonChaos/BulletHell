class_name Logger extends Object

enum LogLevel {
	ERROR = 0,
	WARNING,
	INFO,
	DEBUG
}

static var log_level: LogLevel = LogLevel.ERROR

static func error(text: String) -> void:
	print_rich("[color=red]", text, "[/color]")

static func warning(text: String) -> void:
	if log_level >= LogLevel.WARNING:
		print_rich("[color=yellow]", text, "[/color]")

static func info(text: String) -> void:
	if log_level >= LogLevel.INFO:
		print(text)

static func debug(text: String) -> void:
	if log_level >= LogLevel.DEBUG:
		print_rich("[color=gray]", text, "[/color]")
