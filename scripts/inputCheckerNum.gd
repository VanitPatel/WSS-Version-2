extends Node

class_name InputChecker

var regex = RegEx.new()

func digitChecker(text: String, textBoxPath: Node) -> bool:
	#set to only search for positive and negative whole numbers
	regex.compile("^-?[0-9]+$")
		#Check for only digits in text.
	var result = regex.search(text)
	if result:
		return true
	else:
		textBoxPath.clear()
		return false
