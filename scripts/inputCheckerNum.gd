extends Node

class_name InputChecker

# ─────────────────────────────────────────────────────────────────────────────
# inputCheckerNum.gd
# A small utility class for validating user text input in the options menu.
# Currently supports one check: integer-only input (whole numbers, positive
# or negative).  Used by game_options_menu.gd to validate the seed, map
# width, and map height text fields.
#
# Usage:
#   var checker = InputChecker.new()
#   if checker.digitChecker(text, text_box_node):
#       # text is a valid integer; proceed
# ─────────────────────────────────────────────────────────────────────────────

# RegEx object reused across calls (compiling once is more efficient)
var regex = RegEx.new()

# ─────────────────────────────────────────────────────────────────────────────
# digitChecker(text, textBoxPath) -> bool
# Returns true  if `text` is a valid integer (digits only, optional leading minus).
# Returns false if `text` contains non-digit characters, and also clears the
# text box so the user gets visual feedback that the input was rejected.
#
# text        : The string to validate (usually from a LineEdit.text signal)
# textBoxPath : The LineEdit node to clear if the input is invalid
#
# The regex "^-?[0-9]+$" means:
#   ^   = start of string
#   -?  = optional minus sign
#   [0-9]+ = one or more digits
#   $   = end of string
# ─────────────────────────────────────────────────────────────────────────────
func digitChecker(text: String, textBoxPath: Node) -> bool:
	# Compile the pattern for positive and negative whole numbers
	regex.compile("^-?[0-9]+$")

	var result = regex.search(text)  # Returns a RegExMatch or null
	if result:
		return true  # Valid integer
	else:
		textBoxPath.clear()  # Wipe the invalid text from the input box
		return false
