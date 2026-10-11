extends Node

const extensions = preload("res://scene_extensions.gd")

@onready var coursorObj = $Interaction_stuff/CourserLayer/CourserObj
@onready var messageObj = $CusceneLayer/TextBubble
@onready var sfxSoundPlayer = $SfxAudioScene
@onready var musicPlayer = $MusicPlayerScene

var selectedObj: Area2D
var cursorOffset: Vector2 = Vector2(0,10)
var name2item: Dictionary[String,Area2D]
var selected = false
var rng = RandomNumberGenerator.new()
var currentIssue: Issue

#Returns GameOver:bool, nextTry:bool, personMessage:String, removedItems:Array[Item]
func getInteraction(item1: extensions.Item, item2: extensions.Item, issue: Issue) -> Array:
	if Vector3(item1,item2,issue) in itemActionDict:
		return itemActionDict[Vector3(item1,item2, issue)]
	elif Vector3(item2,item1,issue) in itemActionDict:
		return itemActionDict[Vector3(item2,item1, issue)]
	else:
		return [false, true, "Irgendwie passiert nichts!", []]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var children = get_tree().get_nodes_in_group("Placeholder")
	for child in children: 
		child = child as Placeholder
		child.hide()
		name2item[child.name] = child
		child.selected.connect(_on_placeholder_selected) 
		print(child.name)
	coursorObj.hide()
	scene_new_iteration()
	musicPlayer.playStartMusic()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		if selected == true and selectedObj != null:
			selectedObj.show() 
		coursorObj.hide()
		selected = false
	coursorObj.position = get_viewport().get_mouse_position() + cursorOffset
	pass

func interaction(a1:Area2D,a2:Area2D) -> void: 
	print("use ", a1.name, " on ", a2.name)
	var interaction_key = Vector3(extensions.Item[a1.name],extensions.Item[a2.name],currentIssue)
	if not interaction_key in itemActionDict:
		print("Nothing happened")
		messageObj.show_text_for(NothingHappend,5)
		return
		
	sfxSoundPlayer.playSoundByItems(
		[extensions.Item[a1.name],extensions.Item[a2.name]] as Array[extensions.Item]
		)
	
	if extensions.Item[a1.name] == extensions.Item.SleepingMask or extensions.Item[a2.name] == extensions.Item.SleepingMask:
		musicPlayer.playSleepMask()
	
	var res = itemActionDict[interaction_key] 
	# Struktur: Vector3(extensions.Item, Ziel, Issue) : [GameOver: bool, nextTry: bool, personMessage: String, wakeUpMessage: String, hidingItems: Array]
	var game_over = res[0] as bool
	var next_try = res[1] as bool
	var person_message =res[2] as String
	var wakeup_message =res[3] as String  
	var hide_items = res[4] as Array[extensions.Item]
	messageObj.show_text_for(person_message,5)
	for hide_item in hide_items:
		var item_repr = name2item[extensions.Item.find_key(hide_item)]
		item_repr.hide()
		if hide_item not in removedItems:
			removedItems.append(hide_item) 

	if extensions.Item[selectedObj.name] in removedItems:
		selected = false 
		coursorObj.hide()  
	if next_try:
		return

	if game_over:
		$Interaction_stuff.hide()
		$Interaction_stuff/CourserLayer/CourserObj.hide()
		$CusceneLayer/GameOverScreen.show()
		musicPlayer.playGameOver()
		print("GAME Over")
		return

	if getRandomIssue()==null:
		print("GAME WON")
		messageObj.show_text_for("GAME WON",10)
		return
	
	musicPlayer.playDream()
	$CusceneLayer/Fade.start()
	await get_tree().create_timer(2).timeout
	scene_new_iteration()
	await get_tree().create_timer(2).timeout

	
		

func _on_placeholder_selected(name: String,texture:Texture,offset:Vector2) -> void:
	if selected: 
		var other = name2item[name] 
		interaction(selectedObj,other)
		return
	print(name )
	selectedObj = name2item[name]
	coursorObj.texture = texture
	#cursorOffset = Vector2(coursorObj.texture.get_width()/2, coursorObj.texture.get_height() / 2) + offset
	cursorOffset = offset
	coursorObj.position = get_viewport().get_mouse_position() + cursorOffset
	coursorObj.show()
	selected = true
	pass # Replace with function body.


func scene_new_iteration():
	print("new scene iteration")
	for item in name2item.values():
		item.hide
	var scene_cfg = getScene()
	var issue = scene_cfg[0] as Issue
	var issue_source = scene_cfg[1] as extensions.Item
	
	if issue_source == extensions.Item.Door:
		musicPlayer.playOpera()
		
	var scene_items = scene_cfg[2] as Array[extensions.Item]
	for item in scene_items:
		name2item[extensions.Item.find_key(item)].show()
	pass

func getSolutionsByRemovedItems(issue: Issue) -> Array[extensions.Item]:
	var solutions = issueSolutionsDict[issue]
	var leftSolutions = []
	for items in solutions:
		if not items[0] in removedItems and not items[1] in removedItems:
			leftSolutions.append(items)
	return leftSolutions
	
func getNotRemovedAndNotIssueSourceItems(issue: Issue) -> Array[extensions.Item]:
	var items: Array[extensions.Item] = []
	for item in extensions.Item.values():
		if not item in issueSources[issue] and not item in removedItems:
			items.append(item)
	return items
	
func getRandomIssueSource(issue: Issue):
	var leftSources = getLeftIssueSources(issue)
	if len(leftSources) == 1:
		return leftSources[0]
		
	var sourceNumber = rng.randi_range(0, len(leftSources)-1)
	return leftSources[sourceNumber]
	
func getLeftItemsWithoutSources()-> Array[extensions.Item]:
	var items :Array[extensions.Item]=[]
	for item in extensions.Item.values():
		if not item in removedItems and not item in issueSources[Issue.NOISE] and not item in issueSources[Issue.LIGHT]:
			items.append(item)
	return items
	
# Array[Array[Item]]
func getSolutionsForIssue(issue: Issue, issueSource: extensions.Item) -> Array:
	const maxSolutionCount = 3
	var solutions = []
	for solutionItems in issueSolutionsDict[issue]:
		if issueSource in solutionItems and solutionItems[0] not in removedItems and  solutionItems[1] not in removedItems:
			solutions.append(solutionItems)
	
	var result = []
	for i in range(0, min(maxSolutionCount, len(solutions))):
		var solution = solutions.pick_random()
		result.append(solution)
		solutions.remove_at(solutions.find(solution))
		
	return result
		
			
func getIssueAndIssueSource() -> Array:
	var issue = getRandomIssue();
	var issueSource = getRandomIssueSource(issue)
	return [issue, issueSource]
	
#Array with [issue, issueSource, itemsForScene, MessageWhenAwakes, MessageForIssue]
func getScene() -> Array:
	const maxDifferentItems = 8
	
	var issue = getRandomIssue();
	var issueSource = getRandomIssueSource(issue)
	
	var leftItems = getNotRemovedAndNotIssueSourceItems(issue)
	var solutions = getSolutionsForIssue(issue, issueSource)
	
	var possibleItems = getLeftItemsWithoutSources()
	var sceneItems = []
	for i in range(0,min(maxDifferentItems, len(possibleItems))):
		var item = possibleItems.pick_random()
		sceneItems.append(item)
		possibleItems.remove_at(possibleItems.find(item))
		
	for solution in solutions:
		if not solution[0] in sceneItems:
			sceneItems.append(solution[0])
		if not solution[1] in sceneItems:
			sceneItems.append(solution[1])
			
	if not extensions.Item.Person in sceneItems:
		sceneItems.append(extensions.Item.Person)
		
	var awakeMessage = AwakeAgainMessages.pick_random()
	var issueMessage = NoiseIssueStartMessage if issue == Issue.NOISE else LightIssueStartMessage
			
	return [issue, issueSource, sceneItems, awakeMessage, issueMessage]
		
	
	
	

func getRandomIssue():
	var hasNoiseSources = hasIssueSources(Issue.NOISE)
	var hasLightSources = hasIssueSources(Issue.LIGHT)
	
	if hasNoiseSources and not hasLightSources:
		return Issue.NOISE
	elif not hasNoiseSources and hasLightSources:
		return Issue.LIGHT
	elif not hasNoiseSources and not hasLightSources:
		return null
	
	var issueNumber = rng.randi_range(0, 1)
	if issueNumber == 0:
		return Issue.NOISE
	else:
		return Issue.LIGHT

func hasIssueSources(issue: Issue) -> bool:
	for item in issueSources[issue]:
		if not item in removedItems:
			return true
	return false
	
func getLeftIssueSources(issue: Issue) -> Array:
	var sources = []
	for item in issueSources[issue]:
		if not item in removedItems:
			sources.append(item)
	return sources

var removedItems: Array[extensions.Item]

var issueSources: Dictionary[Issue,Array] = {
	Issue.NOISE: [extensions.Item.Racoon, extensions.Item.Snake, extensions.Item.Door],
	Issue.LIGHT: [extensions.Item.Lamp, extensions.Item.WindowGlas]
}



# Enums für die bessere Lesbarkeit und Typsicherheit
enum Issue {
	NOISE = 0,
	LIGHT = 1
}

var AwakeAgainMessages = [AwakeAgain1,AwakeAgain2,AwakeAgain3,AwakeAgain4,AwakeAgain5,AwakeAgain6,AwakeAgain7,AwakeAgain8]

var NoiseIssueStartMessage = "Meine Ohren klingeln von dem Lärm hier. Das soll Gesang sein?!? Vielleicht sollte ich dafür sorgen, dass das Singen aufhört..."
var LightIssueStartMessage = "Es ist hier so hell wie in Griechenland in der Mittagssonne. Wie soll man da schlafen?"

# AwakeAgain
var AwakeAgain1 = "Bitte kneif mich mal in den Arm. Träume ich? Das ist nicht mein normales Zimmer."
var AwakeAgain2 = "Irgendwie sieht das hier immer noch gruselig aus. Ich scheine noch nicht wach zu sein."
var AwakeAgain3 = "Was zur Hölle ist hier los?"
var AwakeAgain4 = "Ich wusste immer schon, dass ich Schwierigkeiten mit dem Einschlafen habe. Aber so schlimm...?"
var AwakeAgain5 = "Hilfe, hört das denn nie auf?!"
var AwakeAgain6 = "Ich bin so müde!"
var AwakeAgain7 = "Vielleicht sollte ich abends weniger Alkohol trinken."
var AwakeAgain8 = "Langsam habe ich die Schnauze voll. Ich hätte nie gedacht, dass ich das mal sage, aber... Wann klingelt endlich mein Wecker?"

var NothingHappend = "Schade, das hat nicht funktioniert."

var SleepFinaly = "Ich hätte nie gedacht, dass ich so lange brauchen würde, um einzuschlafen... Aber ich habe es geschafft! Bitte begleite mich doch auch in der nächsten Nacht, du hast mir sehr geholfen."
var HidingInWardrobe = "Irgendwie hätte ich nicht gedacht, dass die Tricks aus der Kindheit wirklich funktionieren. Vielleicht sollte mir auch öfter die Augen zuhalten, damit mich niemand sieht."

# SimplyShutOff
var ShutOfLamp = "So einfach kann es gehen. Warum nicht immer so."
var CoverWindowWithCurtains = "Ah, endlich kann ich mein Grottenolmleben weiterführen. Wer braucht schon Tageslicht?"

# Destroy
var JustDestroy = "Das war sowieso hässlich. Jetzt kann ich es ruhigen Gewissens wegschmeißen."
var JustDestroyApple = "Eigentlich wollte ich den zum Frühstück essen, aber gut. Diese Tatsache muss ich jetzt radikal akzeptieren."

# Hearing Protection
var UseHearingProtection = "Ich wusste schon immer, dass Ohrstöpsel eines Tages mein Leben retten würden."
var UseHearingProtectionByLight = "Jetzt höre ich nichts mehr. Aber bei diesem grässlichen Licht kann ich trotzdem nicht einschlafen."

# EsIstNochLaut
var CoverWindowsWithNewsletterByNoise = "Wenn ich mir die Zeitung jetzt auch noch in die Ohren stopfe gegen den Lärm, könnte das mit dem Schlafen vielleicht was werden."
var CrushWindowGlassByNoise = "War es wirklich so sinnvoll, das Fenster zu zerstören, wenn mich Lärm am Einschlafen hindert?"
var CoverWindowWithCurtainsByNoise = "Gute Nacht, du schöne Welt. Jetzt muss ich nur noch dem Lärm hier ebenso gute Nacht sagen."
var CoverWindowsWithBlanketByNoise = "Warum die Bettdecke im Bett verwenden, wenn ich sie auch am Fenster benutzen kann? Aber es ist immer noch zu laut zum Schlafen."

var CrushLampByNoise = "Das hat gut getan. Aber ob ich im Dunkeln wohl noch die Lärmquelle ausfindig machen kann? Die Lampe war offentlichlich nicht der Verursacher."
var CrushLampWithBlanketByNoise = "So im Nachhinein denke ich mir, dass das vielleicht doch keine so gute Idee war. Jetzt ist meine Bettdecke voller Scherben. Aber ob ich im Dunkeln wohl noch die Lärmquelle ausfindig machen kann? Die Lampe war offentlichlich nicht der Verursacher."
var CrushLampWithPillowByNoise = "So im Nachhinein denke ich mir, dass das vielleicht doch keine so gute Idee war. Jetzt ist mein Kissen voller Scherben. Aber ob ich im Dunkeln wohl noch die Lärmquelle ausfindig machen kann? Die Lampe war offentlichlich nicht der Verursacher."
var CrushLampWithAppleByNoise = "Ha! Das war ein guter Wurf. Aber ob ich im Dunkeln wohl noch die Lärmquelle ausfindig machen kann? Die Lampe war offentlichlich nicht der Verursacher."

# CrushLamp
var CrushLamp = "Das Licht zerfließt auf den Scherben der Dunkelheit."
var CrushLampWithApple = "Das Licht ist weg, aber dafür habe ich den Apfel geopfert?! Ich sollte meine Prioritäten eindeutig überdenken."
var CrushLampWithStone = "Steine sind solche Allrounder. Straßen, Häuser und Grüber werden damit gebaut - und Lampen zerstört."
var CrushLampWithPillow = "Kissen sind die ideale Waffe. Und es ist nicht verboten, sie überall mit hin zu nehmen."
var CrushLampWithBlanket = "Gute Nacht, liebe Glühbirne."
var CrushLampWithHammer = "Es ist immer gut, einen Hammer da zu haben."
var CrushLampWithKnive = "Ein präzises Werkzeug für einen präzisen Anwendungsfall. Viel schonender als ein Hammer."
var CrushLampWithFork = "Ich habe das Auge der Elektrik aufgespießt. Wo ist der Grill?"

# Window
var CrushWindowGlass = "Kühle Luft hilft beim Einschlafen. Schade nur, dass es draußen wärmer als drinnen ist."
var CoverWindows = "Jetzt sind alle meine Sorgen endlich ausgesperrt. Das hilft bestimmt beim Schlafen."
var CoverWindowsWithBlanket = "Warum die Bettdecke im Bett verwenden, wenn ich sie auch am Fenster benutzen kann?"
var CrushWindowGlassWithAxe = "Das wollte ich schon immer mal machen. Eigentlich im Zug, aber was soll's. Evakuiert werde ich hier wohl nicht."
var CoverWindowsWithNewsletter = "Jetzt darf ich mein Fenster nur nicht merh angucken. Sonst kann ich bei den ganzen schlechten Schlagzeilen kein Auge mehr zumachen."

# Create
var CreateSleepingMask = "Aus Müll eine Maske gebastelt. Ich sehe aus wie ein Irrer im Hungerstreik, aber es ist dunkel."
var CreateSleepingMaskWithApple = "Vitamine direkt auf die Netzhaut. Wenn ich nicht schlafen kann, kriege ich wenigstens keine Augenringe."
var CreateSleepingMaskWithRacoon = "Das Fell ist noch warm und riecht nach Mülltonne, aber es blockiert das Licht perfekt. Wer braucht schon Hygiene?"
var CreateSleepingMaskWithSnake = "Kaltes Schuppenleder auf den Augen. Die Schlange starrt nicht mehr, jetzt starre ich – in die unendliche Schwärze."

var CreatePeelerMaskWithRacoon = "Präzisionsarbeit mit dem Sparschäler. Das Ergebnis ist haarig, blutig und riecht nach Mülltonne – aber es ist blickdicht."
var CreatePeelerMaskWithSnake = "Ich habe der Schlange die Haut abgezogen, damit ich nicht mehr sehen muss. Ein fairer Tausch, sie braucht sie im Jenseits eh nicht."
var CreateSleepingMaskWithNewsletter = "Schlagzeilen direkt auf den Augäpfeln. So sehe ich wenigstens schwarz auf weiß, dass alles den Bach runtergeht."
var CreateSleepingMaskWithCurtains = "Ich habe die Vorhänge verspeist – metaphorisch. Jetzt hängen sie als Sichtschutz vor meinem geistigen Verfall."
var CreateSleepingMaskWithBlanket = "Viel zu schwer, viel zu warm, aber die totale Isolation hat eben ihren Preis. Ich nenne es 'Die Festung der Müdigkeit'."
var CreateSleepingMaskWithPillow = "Ich habe ein Kissen um meinen Kopf geschnallt. Ich sehe aus wie ein Unfall, aber es ist fast so leise wie im Sarg."
var CreateSleepingMaskWithWallpaper = "Ich habe die Tapete von den Wänden gerissen. Wenn die Wohnung mich anstarrt, starre ich eben mit Kleisterresten zurück."

var CreateHearingProtectionByPillow = "Ein überdimensionaler Kopfhörer. Mit eingebauter Noise-Cancelling-Funktion - das sollte funktionieren."

# Lärm-Eliminierung (Blutig & Makaber)
var KillSingerByAxe = "Das war ein sauberer Schalg. Aus diesem Hals strömen jetzt keine Töne mehr, sondern nur noch Blut."
var KillSingerByHammer = "Das war laut. Die ganzen splitternden Knochen... Aber zum Glück war danach Stille."
var KillSingerByStone = "Die klassische Methode. Wenn's nicht anders geht, ist das Steinigen immer noch eine gute Option."
var KillSingerBySnake = "Jetzt haben die beiden ihren Spaß zusammen und belästigen mich nicht mehr."
var KillSingerByRacoon = "Jetzt hat sie ein neues Haustier. Nur, dass sie es nicht mehr genießen kann."
var KillSingerByPerson = "Puh, das war anstrengend. Ich wusste gar nicht, wie viel Kraft es benötigt, eine Person zu erwürgen. Naja, anders war sie nicht zur Ruhe zu bewegen. Sie argumentierte damit, dass die Nachtruhe nicht gelten würde - es sei doch schließlich Tag."
var KillSingerByFork = "Sie dachte tatsächlich, ich wolle sie füttern. Dieser Irrglaube war tödlich."
var KillSingerByPeeler = "Als ich ihr den Schäler brachte, musste ich gar nichts machen. Sie war so wahnsinnig geworden (ich vermute ja, von ihrer eigenen Musik), dass ihr auch diese Methode gut genug vorkam, um diesem Albtraum von Leben zu entkommen."
var KillSingerByKnive = "Herzen machen auch eine Art von Musik, wenn man auf sie einsticht. Vor allem, wenn man es mehrmals macht."

var KillRacoonByAxe = "Kennt ihr die Geschichte von dem Mord im Schloss. Wo das Blut in Strömen die Treppe runter floss. Der Kopf ist ab, der Kopf ist ab, der Kopf der Kopf, der Kopf ist ab... Geile Trophäe. Aber was mache ich mit dem Rest?"
var KillRacoonByKnive = "Prima Wurfgeschoss. 100 Prozent Erfolg, 0 Prozent Risiko. 100 Prozent tot."
var KillRacoonByHammer = "Das hat lang gedauert. Der war widerstandfähiger als gedacht."
var KillRacoonByFork = "Das war ein mühseliger Kampf. Aber ich habe ihn gewonnen. Gabeln sind definitiv praktischer als Löffel. Den hätte ich bestimmt abgeben müssen. Die Gabel habe ich noch."
var KillRacoonByPeeler = "Ich hätte nicht gedacht, dass ich mal einen Waschbären häuten würde. Kommt definitiv nicht auf meine Bucketlist. Und was mache ich jetzt mit dem Fell?"

var KillSnakeByPeeler = "Ein Wunder, dass ich das überlebt habe. Das war gar nicht so einfach. Ich muss mir jetzt nur noch überlegn, was ich aus der Haut mache. Die Zähne verkaufe ich nach China."
var KillSnakeByAxe = "Dass das so einfach geht, hätte ich nicht gedacht. Aber wie bekomme ich die Axt wieder aus der Wand?"
var KillSnakeByKnive = "Es hat es echt lange gedauert, den Rücken aufzuschlitzen. Vielleicht sollte ich mich doch lieber auf Menschen spezialisieren."
var KillSnakeByHammer = "Die habe ich platt geklopft wie ein Schnitzel. Warum gibt es hier keine Küche? Ich ahbe wirklich Hunger."
var KillSnakeByFork = "Einmal in den Rachen gestochen. Zum Glück hat sie mich nicht erwischt. Jetzt habe ich eine lange Peitsche."

#Selfkill
var SelfKillPersonByStone = "Steine sind so nützlich. Schade, dass ich diese Erkenntnis nicht mehr teilen werde können."
var SelfKillPersonByAxe = "Auf was für neue Anwendungszwecke man nicht immer wieder stößt... Ich muss zusehen, dass ich genügend Schwung aufbaue."
var SelfKillPersonByKnive = "Wenigstens ein weitestgehend harmloser Tod in dieser schmerzhaften Welt."
var SelfKillPersonByHammer = "Wie heißt es so schön? Ein Schlag auf den Kopf löst alle Probleme."
var SelfKillPersonByFork = "Nun, das wird lange dauern. Aber wenn ich sonst nichts zur Verfügung habe, dann eben mit der Gabel."
var SelfKillPersonByPeeler = "Das wird schmerzhaft. Aber wenn ich sonst nichts zur Verfügung habe, dann eben so."
var SelfKillPersonByWindow = "Dort finde ich den ewigen Schlaf. Das Licht wird kein Problem mehr für mich sein."
var SelfKillPersonBySnake = "Das Ende in einer herzhaften Umarmung kann nicht das schlimmste Ende sein."
var SelfKillPersonByRacoon = "Leider war das eine Fehleinschätzung und kein Kuscheltier. Immerhin war es kein sinnloser Tod. Der Waschbär wird bestimmt einen Nutzen aus mir ziehen."

# WakeUp
var WakeUpNoSleepingMask = "Wo ist meine Maske hin? Kein Wunder, dass ich nicht mehr schlafen kann."
var WakeUpNoLamp = "Oh, die Lampe hat wohl den Geist aufgegeben. Aber so komplett."
var WakeUpNoWindow = "Wo ist das Fenster hin?!? Per se mochte ich es ja. Jetzt brauche ich einen neuen Plan für meinen letzten Ausweg."
var WakeUpNoBlanket = "Wo ist meine Bettdecke hin? Das wird schwierig, ohne einzuschlafen. Ich mag diesen Traum immer weniger."
var WakeUpNoWindowGlas = "Das Fensterglas ist weg. Kein Wunder, dass ich wieder wach geworden bin - es ist ganz schön kalt hier drin."
var WakeUpNoNewsletter = "Die Zeitung ist weg. Endlich muss ich mich nur noch mit den schlechten Nachrichten aus meinem Zimmer befassen."
var WakeUpNoRacoon = "Der Waschbär ist weg. Aber wo ist er hin? Ich traue dem Freieden nicht so recht. Vielleicht hat er sich unter dem Bett vertseckt."
var WakeUpNoSnake = "Die Schlange ist weg. Ein Glück. Aber wo ist sie hin? Früher hatte ich immer Angst vor Monstern unter dem Bett, jetzt ist die Angst real."
var WakeUpNoApple = "Ach Mann, der Apfel ist weg. Träume ohne Essen sind mir echt unsympathisch."
var WakeUpNoPillow = "Mein Kissen ist weg. Kein Wunder, dass ich wieder wach bin und immer noch Albträume habe."
var WakeUpNoCurtains = "Die Vorhänge sind weg. Und ich dachte, die wären im Zimmer und nicht außerhalb gewesen. Naja, die muss wohl jemand mitgenommen haben. Schön waren sie jedenfalls nicht."
var WakeUpNoWallpaper = "Die Tapete ist weg. Schön sieht das ja nicht aus."
var WakeUpNoWardrobe = "Wo ist mein Schrank hin? Ich habe keine Lust, schon wieder einkaufen zu müssen. Immerhin habe ich jetzt keine Klamotten mehr, die ich aussorteiren muss. Eine zweite Unterhose wäre aber schon echt praktisch."
var WakeUpNoHearingProtection = "Meine Ohrstöpsel sind weg! Mein Ende naht! Ohne bin ich definitiv nicht überlebensfähig. Allein, um die Geräusche des Pärchens nebenan nachts nicht hören zu müssen..."
var WakeUpNoDoor = "Die Tür ist weg. Ich bereue immer mehr, dass ich weder einen Herd noch eine Toilette direkt neben meinem Bett habe."

# Intentions
var GoToSingerWithFork = "Mal gucken, ob sie die Gabel genauso weit in den Hals bekommt wie ich..."
var GoToSingerWithPerson = "Ich werde ihn bestimmt davon überzeugen können, mit dem Singen aufzuhören. Schließlich gibt es so etwas wie Nachtruhe."
var GoToSingerWithRacoon = "Mein Nachbar wird sich bestimmt über den Waschbären freuen und sich mit ihm anfreunden."
var GoToSingerWithSnake = "Die packe ich mal schön ein. So eine Schlange als Geschenk macht sich doch immer super."
var GoToSingerWithStone = "Vielleicht mag sie den Stein genauso gerne wie ich."
var GoToSingerWithHammer = "Vielleicht sollte ich den Hammer zurückbringen (das ist nämlich gar nicht meiner)."
var GoToSingerWithKnive = "Ich? Ich habe doch keine dummen Gedanken. Niemals. Das war in der Schule nicht so und jetzt auch nicht."
var GoToSingerWithAxe = "Ich ahbe ja so einige Fantasien, die ich noch nie ausgelebt habe... Für diese ist jetzt ein guter Zeitpunkt, denke ich."

var GoToSnakeWithFork = "Das ist bestimmt eine gute Idee. Ich sehe da gar keine Probleme auf mich zukommen."
var GoToSnakeWithHammer = "Ein Betäubungsschlag gegen den Kopf und dann ist gut."

var GoToRacoonWithFork = "Hier! Ich habe auch eine Pfote mit Krallen!"
var GoToRacoonWithHammer = "Ein Sschlag gegen den Kopf und dann ist gut."


# Struktur: Vector3(Item, Ziel, Issue) : [GameOver: bool, nextTry: bool, personMessage: String, wakeUpMessage: String, hidingItems: Array]
var itemActionDict : Dictionary[Vector3, Array] = {
	# --- LICHT (Issue.LIGHT) ---
	Vector3(extensions.Item.SleepingMask, extensions.Item.Person, Issue.LIGHT): [false, false, SleepFinaly, WakeUpNoSleepingMask, [extensions.Item.SleepingMask]],
	Vector3(extensions.Item.Stone, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithStone, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Stone, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CrushWindowGlass, WakeUpNoWindow, []],
	Vector3(extensions.Item.Pillow, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithPillow, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Blanket, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithBlanket, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Blanket, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CoverWindowsWithBlanket, WakeUpNoBlanket, [extensions.Item.Blanket]],
	Vector3(extensions.Item.Curtains, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CoverWindowWithCurtains, WakeUpNoWindowGlas, [extensions.Item.Curtains, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.LightSwitch, extensions.Item.Lamp, Issue.LIGHT): [false, false, ShutOfLamp, WakeUpNoLamp, [extensions.Item.LightSwitch, extensions.Item.Lamp]],
	Vector3(extensions.Item.Axe, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLamp, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Axe, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CrushWindowGlassWithAxe, WakeUpNoWindowGlas, [extensions.Item.Axe, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Hammer, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithHammer, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Hammer, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CrushWindowGlass, WakeUpNoWindowGlas, [extensions.Item.Hammer, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Knive, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithKnive, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Newsletter, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CoverWindowsWithNewsletter, WakeUpNoNewsletter, [extensions.Item.Newsletter, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Apple, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithApple, WakeUpNoLamp, [extensions.Item.Apple, extensions.Item.Lamp]],
	Vector3(extensions.Item.Fork, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithFork, WakeUpNoLamp, [extensions.Item.Fork, extensions.Item.Lamp]],
	Vector3(extensions.Item.Peeler, extensions.Item.Racoon, Issue.LIGHT): [false, false, CreatePeelerMaskWithRacoon, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Peeler, extensions.Item.Snake, Issue.LIGHT): [false, false, CreatePeelerMaskWithSnake, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Axe, extensions.Item.Racoon, Issue.LIGHT): [false, false, CreateSleepingMaskWithRacoon, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Knive, extensions.Item.Racoon, Issue.LIGHT): [false, false, CreateSleepingMaskWithRacoon, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Axe, extensions.Item.Snake, Issue.LIGHT): [false, false, CreateSleepingMaskWithSnake, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Knive, extensions.Item.Snake, Issue.LIGHT): [false, false, CreateSleepingMaskWithSnake, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Axe, extensions.Item.Apple, Issue.LIGHT): [false, false, CreateSleepingMaskWithApple, WakeUpNoApple, [extensions.Item.Apple]],
	Vector3(extensions.Item.Knive, extensions.Item.Apple, Issue.LIGHT): [false, false, CreateSleepingMaskWithApple, WakeUpNoApple, [extensions.Item.Apple]],
	Vector3(extensions.Item.Apple, extensions.Item.Peeler, Issue.LIGHT): [false, false, CreateSleepingMaskWithApple, WakeUpNoApple, [extensions.Item.Apple]],
	Vector3(extensions.Item.Pillow, extensions.Item.Peeler, Issue.LIGHT): [false, false, CreateSleepingMask, WakeUpNoPillow, [extensions.Item.Pillow]],
	Vector3(extensions.Item.Axe, extensions.Item.Newsletter, Issue.LIGHT): [false, false, CreateSleepingMaskWithNewsletter, WakeUpNoNewsletter, [extensions.Item.Newsletter]],
	Vector3(extensions.Item.Axe, extensions.Item.Curtains, Issue.LIGHT): [false, false, CreateSleepingMaskWithCurtains, WakeUpNoCurtains, [extensions.Item.Curtains]],
	Vector3(extensions.Item.Axe, extensions.Item.Blanket, Issue.LIGHT): [false, false, CreateSleepingMaskWithBlanket, WakeUpNoBlanket, [extensions.Item.Blanket]],
	Vector3(extensions.Item.Axe, extensions.Item.Pillow, Issue.LIGHT): [false, false, CreateSleepingMaskWithPillow, WakeUpNoPillow, [extensions.Item.Pillow]],
	Vector3(extensions.Item.Axe, extensions.Item.Wallpaper, Issue.LIGHT): [false, false, CreateSleepingMaskWithWallpaper, WakeUpNoWallpaper, [extensions.Item.Wallpaper]],
	Vector3(extensions.Item.Knive, extensions.Item.Newsletter, Issue.LIGHT): [false, false, CreateSleepingMaskWithNewsletter, WakeUpNoNewsletter, [extensions.Item.Newsletter]],
	Vector3(extensions.Item.Knive, extensions.Item.Curtains, Issue.LIGHT): [false, false, CreateSleepingMaskWithCurtains, WakeUpNoCurtains, [extensions.Item.Curtains]],
	Vector3(extensions.Item.Knive, extensions.Item.Blanket, Issue.LIGHT): [false, false, CreateSleepingMaskWithBlanket, WakeUpNoBlanket, [extensions.Item.Blanket]],
	Vector3(extensions.Item.Knive, extensions.Item.Pillow, Issue.LIGHT): [false, false, CreateSleepingMaskWithPillow, WakeUpNoPillow, [extensions.Item.Pillow]],
	Vector3(extensions.Item.Knive, extensions.Item.Wallpaper, Issue.LIGHT): [false, false, CreateSleepingMaskWithWallpaper, WakeUpNoWallpaper, [extensions.Item.Wallpaper]],
	Vector3(extensions.Item.Person, extensions.Item.Wardrobe, Issue.LIGHT): [false, false, HidingInWardrobe, WakeUpNoWardrobe, [extensions.Item.Wardrobe]],

	# --- LÄRM (Issue.NOISE) ---
	Vector3(extensions.Item.HearingProtection, extensions.Item.Person, Issue.NOISE): [false, false, UseHearingProtection, WakeUpNoHearingProtection, [extensions.Item.HearingProtection]],
	Vector3(extensions.Item.Pillow, extensions.Item.Person, Issue.NOISE): [false, false, CreateHearingProtectionByPillow, WakeUpNoPillow, [extensions.Item.Pillow]],
	Vector3(extensions.Item.Axe, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByAxe, WakeUpNoDoor, [extensions.Item.Axe, extensions.Item.Door]],
	Vector3(extensions.Item.Axe, extensions.Item.Racoon, Issue.NOISE): [false, false, KillRacoonByAxe, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Axe, extensions.Item.Snake, Issue.NOISE): [false, false, KillSnakeByAxe, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Knive, extensions.Item.Racoon, Issue.NOISE): [false, false, KillRacoonByKnive, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Knive, extensions.Item.Snake, Issue.NOISE): [false, false, KillSnakeByKnive, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Knive, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByKnive, WakeUpNoDoor, [extensions.Item.Knive, extensions.Item.Door]],
	Vector3(extensions.Item.Hammer, extensions.Item.Racoon, Issue.NOISE): [false, false, KillRacoonByHammer, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Hammer, extensions.Item.Snake, Issue.NOISE): [false, false, KillSnakeByHammer, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Hammer, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByHammer, WakeUpNoDoor, [extensions.Item.Hammer, extensions.Item.Door]],
	Vector3(extensions.Item.Stone, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByStone, WakeUpNoDoor, [extensions.Item.Stone, extensions.Item.Door]],
	Vector3(extensions.Item.Snake, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerBySnake, WakeUpNoDoor, [extensions.Item.Snake, extensions.Item.Door]],
	Vector3(extensions.Item.Racoon, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByRacoon, WakeUpNoDoor, [extensions.Item.Racoon, extensions.Item.Door]],
	Vector3(extensions.Item.Person, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByPerson, WakeUpNoDoor, [extensions.Item.Door]],
	Vector3(extensions.Item.Fork, extensions.Item.Racoon, Issue.NOISE): [false, false, KillRacoonByFork, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Fork, extensions.Item.Snake, Issue.NOISE): [false, false, KillSnakeByFork, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Fork, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByFork, WakeUpNoDoor, [extensions.Item.Fork, extensions.Item.Door]],
	Vector3(extensions.Item.Peeler, extensions.Item.Racoon, Issue.NOISE): [false, false, KillRacoonByPeeler, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Peeler, extensions.Item.Snake, Issue.NOISE): [false, false, KillSnakeByPeeler, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Peeler, extensions.Item.Door, Issue.NOISE): [false, false, KillSingerByPeeler, WakeUpNoDoor, [extensions.Item.Fork, extensions.Item.Door]],
	Vector3(extensions.Item.Person, extensions.Item.Wardrobe, Issue.NOISE): [false, false, HidingInWardrobe, WakeUpNoWardrobe, [extensions.Item.Wardrobe]],

	# --- GAME OVER (KillPerson / Fatal) ---
	Vector3(extensions.Item.Stone, extensions.Item.Person, Issue.NOISE): [true, false, SelfKillPersonByStone, "", []],
	Vector3(extensions.Item.Stone, extensions.Item.Person, Issue.LIGHT): [true, false, SelfKillPersonByStone, "", []],
	Vector3(extensions.Item.Axe, extensions.Item.Person, Issue.NOISE): [true, false, SelfKillPersonByAxe, "", []],
	Vector3(extensions.Item.Axe, extensions.Item.Person, Issue.LIGHT): [true, false, SelfKillPersonByAxe, "", []],
	Vector3(extensions.Item.Knive, extensions.Item.Person, Issue.NOISE): [true, false, SelfKillPersonByKnive, "", []],
	Vector3(extensions.Item.Knive, extensions.Item.Person, Issue.LIGHT): [true, false, SelfKillPersonByKnive, "", []],
	Vector3(extensions.Item.Hammer, extensions.Item.Person, Issue.NOISE): [true, false, SelfKillPersonByHammer, "", []],
	Vector3(extensions.Item.Hammer, extensions.Item.Person, Issue.LIGHT): [true, false, SelfKillPersonByHammer, "", []],
	Vector3(extensions.Item.Fork, extensions.Item.Person, Issue.NOISE): [true, false, SelfKillPersonByFork, "", []],
	Vector3(extensions.Item.Fork, extensions.Item.Person, Issue.LIGHT): [true, false, SelfKillPersonByFork, "", []],
	Vector3(extensions.Item.Person, extensions.Item.Peeler, Issue.NOISE): [true, false, SelfKillPersonByPeeler, "", []],
	Vector3(extensions.Item.Person, extensions.Item.Peeler, Issue.LIGHT): [true, false, SelfKillPersonByPeeler, "", []],
	Vector3(extensions.Item.Person, extensions.Item.WindowGlas, Issue.NOISE): [true, false, SelfKillPersonByWindow, "", []],
	Vector3(extensions.Item.Person, extensions.Item.WindowGlas, Issue.LIGHT): [true, false, SelfKillPersonByWindow, "", []],
	Vector3(extensions.Item.Person, extensions.Item.Racoon, Issue.NOISE): [true, false, SelfKillPersonByRacoon, "", []],
	Vector3(extensions.Item.Person, extensions.Item.Snake, Issue.NOISE): [true, false, SelfKillPersonBySnake, "", []],
	
	
	Vector3(extensions.Item.SleepingMask, extensions.Item.Person, Issue.NOISE): [false, true, CrushLampByNoise, "", [extensions.Item.SleepingMask]],
	Vector3(extensions.Item.Stone, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampByNoise, "", [extensions.Item.Lamp]],
	Vector3(extensions.Item.Stone, extensions.Item.WindowGlas, Issue.NOISE): [false, true, CrushWindowGlassByNoise, "", [extensions.Item.Stone, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Pillow, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampWithPillowByNoise, "", [extensions.Item.Pillow, extensions.Item.Lamp]],
	Vector3(extensions.Item.Blanket, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampWithBlanketByNoise, "", [extensions.Item.Blanket, extensions.Item.Lamp]],
	Vector3(extensions.Item.Blanket, extensions.Item.WindowGlas, Issue.NOISE): [false, true, CoverWindowsWithBlanketByNoise, "", [extensions.Item.Blanket]],
	Vector3(extensions.Item.LightSwitch, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampByNoise, "", []],
	Vector3(extensions.Item.Axe, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampByNoise, "", [extensions.Item.Lamp]],
	Vector3(extensions.Item.Axe, extensions.Item.WindowGlas, Issue.NOISE): [false, true, CrushWindowGlassByNoise, "", [extensions.Item.Axe, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Hammer, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampByNoise, "", [extensions.Item.Lamp]],
	Vector3(extensions.Item.Hammer, extensions.Item.WindowGlas, Issue.NOISE): [false, true, CrushWindowGlassByNoise, "", [extensions.Item.Hammer, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Knive, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushWindowGlassByNoise, "", [extensions.Item.Lamp]],
	Vector3(extensions.Item.Newsletter, extensions.Item.WindowGlas, Issue.NOISE): [false, true, CoverWindowsWithNewsletterByNoise, "", [extensions.Item.Newsletter, extensions.Item.WindowGlas]],
	Vector3(extensions.Item.Apple, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampWithAppleByNoise, "", [extensions.Item.Apple, extensions.Item.Lamp]],
	Vector3(extensions.Item.Fork, extensions.Item.Lamp, Issue.NOISE): [false, true, CrushLampByNoise, "", [extensions.Item.Lamp]],
	Vector3(extensions.Item.Axe, extensions.Item.Apple, Issue.NOISE): [false, true, JustDestroyApple,"", [extensions.Item.Apple]],
	Vector3(extensions.Item.Knive, extensions.Item.Apple, Issue.NOISE): [false, true, JustDestroyApple, "", [extensions.Item.Apple]],
	Vector3(extensions.Item.Apple, extensions.Item.Peeler, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Apple]],
	Vector3(extensions.Item.Pillow, extensions.Item.Peeler, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Pillow]],
	Vector3(extensions.Item.Axe, extensions.Item.Newsletter, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Newsletter]],
	Vector3(extensions.Item.Axe, extensions.Item.Curtains, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Curtains]],
	Vector3(extensions.Item.Axe, extensions.Item.Blanket, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Blanket]],
	Vector3(extensions.Item.Axe, extensions.Item.Pillow, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Pillow]],
	Vector3(extensions.Item.Axe, extensions.Item.Wallpaper, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Wallpaper]],
	Vector3(extensions.Item.Knive, extensions.Item.Newsletter, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Newsletter]],
	Vector3(extensions.Item.Knive, extensions.Item.Curtains, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Curtains]],
	Vector3(extensions.Item.Knive, extensions.Item.Blanket, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Blanket]],
	Vector3(extensions.Item.Knive, extensions.Item.Pillow, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Pillow]],
	Vector3(extensions.Item.Knive, extensions.Item.Wallpaper, Issue.NOISE): [false, true, JustDestroy, "", [extensions.Item.Wallpaper]],

	Vector3(extensions.Item.HearingProtection, extensions.Item.Person, Issue.LIGHT): [false, true, UseHearingProtectionByLight, "", [extensions.Item.HearingProtection]],
	Vector3(extensions.Item.Axe, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithAxe, "", [extensions.Item.Door]],
	Vector3(extensions.Item.Knive, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithKnive, "", [extensions.Item.Knive, extensions.Item.Door]],
	Vector3(extensions.Item.Hammer, extensions.Item.Racoon, Issue.LIGHT): [false, true, GoToRacoonWithHammer, "", []],
	Vector3(extensions.Item.Hammer, extensions.Item.Snake, Issue.LIGHT): [false, true, GoToSnakeWithHammer, "", [extensions.Item.Snake]],
	Vector3(extensions.Item.Hammer, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithHammer, "", []],
	Vector3(extensions.Item.Stone, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithStone, "", [extensions.Item.Stone, extensions.Item.Door]],
	Vector3(extensions.Item.Snake, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithSnake, "", []],
	Vector3(extensions.Item.Racoon, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithRacoon, "", []],
	Vector3(extensions.Item.Person, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithPerson, "", []],
	Vector3(extensions.Item.Fork, extensions.Item.Racoon, Issue.LIGHT): [false, true, GoToRacoonWithFork, "", [extensions.Item.Racoon]],
	Vector3(extensions.Item.Fork, extensions.Item.Snake, Issue.LIGHT): [false, true, GoToSnakeWithFork, "", [extensions.Item.Snake]],
	Vector3(extensions.Item.Fork, extensions.Item.Door, Issue.LIGHT): [false, true, GoToSingerWithFork, "", [extensions.Item.Fork, extensions.Item.Door]],
}


# Hilfs-Dictionary für Hinweissysteme oder Lösungs-Checks
# Key: Issue, Value: Array von [Item_A, Item_B] Paaren
var issueSolutionsDict : Dictionary = {
	Issue.NOISE: [
		[extensions.Item.HearingProtection, extensions.Item.Person],
		[extensions.Item.Pillow, extensions.Item.Person],
		[extensions.Item.Axe, extensions.Item.Door],
		[extensions.Item.Axe, extensions.Item.Racoon],
		[extensions.Item.Axe, extensions.Item.Snake],
		[extensions.Item.Knive, extensions.Item.Racoon],
		[extensions.Item.Knive, extensions.Item.Snake],
		[extensions.Item.Knive, extensions.Item.Door],
		[extensions.Item.Hammer, extensions.Item.Racoon],
		[extensions.Item.Hammer, extensions.Item.Snake],
		[extensions.Item.Hammer, extensions.Item.Door],
		[extensions.Item.Stone, extensions.Item.Door],
		[extensions.Item.Snake, extensions.Item.Door],
		[extensions.Item.Racoon, extensions.Item.Door],
		[extensions.Item.Person, extensions.Item.Door],
		[extensions.Item.Fork, extensions.Item.Racoon],
		[extensions.Item.Fork, extensions.Item.Snake],
		[extensions.Item.Fork, extensions.Item.Door],
		[extensions.Item.Person, extensions.Item.Wardrobe]
	],
	Issue.LIGHT: [
		[extensions.Item.SleepingMask, extensions.Item.Person],
		[extensions.Item.Stone, extensions.Item.Lamp],
		[extensions.Item.Stone, extensions.Item.WindowGlas],
		[extensions.Item.Pillow, extensions.Item.Lamp],
		[extensions.Item.Blanket, extensions.Item.Lamp],
		[extensions.Item.Blanket, extensions.Item.WindowGlas],
		[extensions.Item.Curtains, extensions.Item.WindowGlas],
		[extensions.Item.LightSwitch, extensions.Item.Lamp],
		[extensions.Item.Axe, extensions.Item.Lamp],
		[extensions.Item.Axe, extensions.Item.WindowGlas],
		[extensions.Item.Hammer, extensions.Item.Lamp],
		[extensions.Item.Hammer, extensions.Item.WindowGlas],
		[extensions.Item.Knive, extensions.Item.Lamp],
		[extensions.Item.Newsletter, extensions.Item.WindowGlas],
		[extensions.Item.Apple, extensions.Item.Lamp],
		[extensions.Item.Fork, extensions.Item.Lamp],
		[extensions.Item.Peeler, extensions.Item.Racoon],
		[extensions.Item.Peeler, extensions.Item.Snake],
		[extensions.Item.Axe, extensions.Item.Racoon],
		[extensions.Item.Knive, extensions.Item.Racoon],
		[extensions.Item.Axe, extensions.Item.Snake],
		[extensions.Item.Knive, extensions.Item.Snake],
		[extensions.Item.Axe, extensions.Item.Apple],
		[extensions.Item.Knive, extensions.Item.Apple],
		[extensions.Item.Apple, extensions.Item.Peeler],
		[extensions.Item.Pillow, extensions.Item.Peeler],
		[extensions.Item.Axe, extensions.Item.Newsletter],
		[extensions.Item.Axe, extensions.Item.Curtains],
		[extensions.Item.Axe, extensions.Item.Blanket],
		[extensions.Item.Axe, extensions.Item.Pillow],
		[extensions.Item.Axe, extensions.Item.Wallpaper],
		[extensions.Item.Knive, extensions.Item.Newsletter],
		[extensions.Item.Knive, extensions.Item.Curtains],
		[extensions.Item.Knive, extensions.Item.Blanket],
		[extensions.Item.Knive, extensions.Item.Pillow],
		[extensions.Item.Knive, extensions.Item.Wallpaper],
		[extensions.Item.Person, extensions.Item.Wardrobe]
	]
}
