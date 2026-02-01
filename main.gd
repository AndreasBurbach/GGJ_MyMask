extends Node

const extensions = preload("res://scene_extensions.gd")

@onready var coursorObj = $Interaction_stuff/CourserLayer/CourserObj
@onready var messageObj = $CusceneLayer/TextBubble
@onready var sfxSoundPlayer = $SfxAudioScene

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
		
	sfxSoundPlayer.playSoundByItems([extensions.Item[a1.name],extensions.Item[a2.name]])
	
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

	if Item[selectedObj.name] in removedItems:
		selected = false 
		coursorObj.hide()  
	if next_try:
		return
	var  t : Timer 

	if game_over:
		$Interaction_stuff.hide()
		$Interaction_stuff/CourserLayer/CourserObj.hide()
		$CusceneLayer/GameOverScreen.show()
		await get_tree().create_timer(5).timeout 
		print("GAME Over")
		return

	if getRandomIssue()==null:
		print("GAME WON")
		messageObj.show_text_for("GAME WON",10)
		return
	scene_new_iteration()
	
		

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
	
func getLeftItemsWithoutSources()-> Array[Item]:
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

var NoiseIssueStartMessage = "Wie soll ich einschlafen bei dem ganzen Lärm?"
var LightIssueStartMessage = "Selbst wenn ich die Augen zu mache, brennen sie von dem ganzen Licht hier. Wie soll ich da einschlafen?"

var AwakeAgain1 = "Ähm... wieso, bin ich schon wieder Wach? Was ist hier los?"
var AwakeAgain2 = "Was zur Hölle ist hier los. Ich war doch gerade noch im Bett?"
var AwakeAgain3 = "Was... was ist hier los?"
var AwakeAgain4 = "Oh man... Einschlafen wird immer schwerer."
var AwakeAgain5 = "Wieso liege ich nicht mehr im Bett? Bewegt sich der Raum um mich herum?"
var AwakeAgain6 = "... müde!"
var AwakeAgain7 = "Träume ich...?"
var AwakeAgain8 = "Ist das mein Zimmer?"

var NothingHappend = "Hm... irgendwie ist dabei nichts passiert!"

var SleepFinaly = "Endlich... die süße Dunkelheit umarmt mich. Gute Nacht, grausame Welt."
var HidingInWardrobe = "Zwischen alten Socken hört dich niemand schreien – oder schnarchen. Ein herrlich muffiges Grab."
	
var CrushLamp = "Es werde Licht? Von wegen. Es werde Dunkelheit. Dauerhaft und schmerzhaft."
var CrushLampWithApple = "Nun ist das Licht weg, ich kann schlafen, aber mein Frühstück ist voller Scherben."
var CrushWindowGlass = "Scherben bringen Glück. Und hoffentlich das Ende dieser verdammten Photonen-Invasion!"
var CoverWindows = "Was ich nicht sehe, existiert nicht. Ein Hoch auf die totale Verleugnung der Außenwelt."
var ShutOfLamp = "Ein kleiner Klick für mich, ein gigantischer Schritt Richtung REM-Phase."
var ShutOfWindowLigth = "Endlich ist dieser gelbe Feuerball da draußen ausgesperrt. Bleib wo der Pfeffer wächst!"
	
var KillRacoonByPeeler = "Waschbären waschen im Jenseits keine Wäsche mehr. Die Stille ist fast so schön wie sein entsetzter Blick."
var KillSnakeByPeeler = "Ein Gürtel, der früher mal gezischt hat. Sehr kleidsam und vor allem: ABSOLUT STILL."
var KillSingerByKnive = "Das letzte hohe C war sein finales. Die Stille danach ist die schönste Musik, die ich je gehört habe."
var UseHearingProtection = "Ich höre nur noch mein eigenes Herz klopfen... wenigstens nervt das rhythmisch."
	
var CreateSleepingMask = "Aus Müll eine Maske gebastelt. Ich sehe aus wie ein Irrer im Hungerstreik, aber es ist dunkel."
var CreateAppleSleepingMask = "Vitamine direkt auf die Netzhaut. Wenn ich nicht schlafen kann, kriege ich wenigstens keine Augenringe."
var CreateRacoonSleepingMask = "Das Fell ist noch warm und riecht nach Mülltonne, aber es blockiert das Licht perfekt. Wer braucht schon Hygiene?"
var CreateSnakeSleepingMask = "Kaltes Schuppenleder auf den Augen. Die Schlange starrt nicht mehr, jetzt starre ich – in die unendliche Schwärze."

var CrushLampWithStone = "Ein Steinzeit-Tool für ein modernes Problem. Funken, Glas, Dunkelheit. Die Evolution ist ein Kreis."
var CrushLampWithPillow = "Ich habe das Licht erstickt. Es hat sich kaum gewehrt. Wenn es doch nur bei meinen Gedanken so einfach wäre."
var CrushLampWithBlanket = "Unter dieser Decke stirbt jede Hoffnung – und zum Glück auch diese verdammte Glühbirne."
var CrushLampWithHammer = "Ein kräftiger Schlag gegen die Erleuchtung. Wer braucht schon Sichtweite, wenn er Abgründe hat?"
var CrushLampWithKnive = "Ich habe die Photonen erstochen. Ein chirurgischer Eingriff in die Atmosphäre. Patient tot, Zimmer dunkel. Perfekt."
var CrushLampWithFork = "Ein metallisches 'Zapp', ein kurzer Schmerz im Arm und... Stille im Stromkreis. Ein Hoch auf die elektrische Hinrichtung."

var CoverWindowsWithBlanket = "Mein Zimmer ist jetzt ein gepolstertes Grab. Die Außenwelt kann draußen verrotten, ich sehe sie nicht mehr."
var CrushWindowGlassWithAxe = "Frische Luft? Nein, nur Scherben und das Ende dieser voyeuristischen Glasbarriere. Komm rein, Nacht."
var CoverWindowsWithNewsletter = "Endlich nützliche Nachrichten: Sie blockieren die Sicht auf eine Welt, die ohnehin keinen Sinn ergibt."

var CreatePeelerMaskWithRacoon = "Präzisionsarbeit mit dem Sparschäler. Das Ergebnis ist haarig, blutig und riecht nach Mülltonne – aber es ist blickdicht."
var CreatePeelerMaskWithSnake = "Ich habe der Schlange die Haut abgezogen, damit ich nicht mehr sehen muss. Ein fairer Tausch, sie braucht sie im Jenseits eh nicht."
var CreateSleepingMaskWithNewsletter = "Schlagzeilen direkt auf den Augäpfeln. So sehe ich wenigstens schwarz auf weiß, dass alles den Bach runtergeht."
var CreateSleepingMaskWithCurtains = "Ich habe die Vorhänge verspeist – metaphorisch. Jetzt hängen sie als Sichtschutz vor meinem geistigen Verfall."
var CreateSleepingMaskWithBlanket = "Viel zu schwer, viel zu warm, aber die totale Isolation hat eben ihren Preis. Ich nenne es 'Die Festung der Müdigkeit'."
var CreateSleepingMaskWithPillow = "Ich habe ein Kissen um meinen Kopf geschnallt. Ich sehe aus wie ein Unfall, aber es ist fast so leise wie im Sarg."
var CreateSleepingMaskWithWallpaper = "Ich habe die Tapete von den Wänden gerissen. Wenn die Wohnung mich anstarrt, starre ich eben mit Kleisterresten zurück."

var CreateHearingProtectionByPillow = "Ich presse mir das Kissen auf die Ohren, bis das Blut rauscht. Mein eigener Puls ist der einzige Soundtrack, den ich noch ertrage."

# Lärm-Eliminierung (Blutig & Makaber)
var KillSingerByAxe = "Sein letzter hoher Ton war ein gurgelndes E. Die Axet hat die Partitur beendet. Applaus für die ewige Stille."
var KillRacoonByAxe = "Waschbären sind erstaunlich aerodynamisch, wenn man sie mit einer Axet spaltet. Der Müll gehört jetzt wieder mir."
var KillSnakeByAxe = "Aus eins mach zwei. Beide Teile zappeln noch, aber das Zischen hat endlich ein Ende gefunden."
var KillRacoonByKnive = "Ein kurzer Schnitt, ein langes Schweigen. Der Pelz eignet sich hervorragend als Handwärmer."
var KillSnakeByKnive = "Ich habe sie entgrätet, während sie noch von Mäusen träumte. Ein zynisches Ende für ein kriechendes Problem."
var KillRacoonByHammer = "Ein dumpfer Schlag, ein kurzes Knacken. Der Waschbär hat jetzt ein sehr flaches Weltbild."
var KillSnakeByHammer = "Kopf oder Zahl? Der Hammer entschied sich für Matsch. Die Schlange ist jetzt so flach wie meine Lebensfreude."
var KillSingerByHammer = "Ich habe ihm den Rhythmus eingeprügelt – bis sein Herz aufgehört hat zu schlagen. Ein echtes One-Hit-Wonder."
var KillSingerByStone = "Zurück zu den Wurzeln der Kritik. Ein Stein gegen die Stirn beendet jede künstlerische Differenz."
var KillSingerBySnake = "Ich habe die Schlange in sein Bett gelegt. Ein biologisches Attentat. Ironisch, dass sein letztes Wort ein Schrei war."
var KillSingerByRacoon = "Ich habe den tollwütigen Waschbären auf ihn gehetzt. Ein Duett des Grauens, das in herrlicher Stille endete."
var KillSingerByPerson = "Ich habe ihn einfach erwürgt. Handarbeit ist in dieser digitalen Welt so selten geworden. Man spürt das Leben weichen."
var KillRacoonByFork = "Es hat lange gedauert und war furchtbar mühselig, aber mit der Gabel ist jeder Stich ein Statement gegen den Lärm."
var KillSnakeByFork = "Wie Spaghetti, nur widerspenstiger. Jetzt zappelt nichts mehr auf meinem Teller – oder in meinem Gehörgang."
var KillSingerByFork = "Punktierung nennt man das in der Musik, oder? Ich habe ihn an so vielen Stellen punktiert, bis die Musik auslief."
var KillSingerByPeeler = "Ich habe ihm alle Noten einzeln von der Zunge geschält. Der gibt erstmal Ruhe"

var SelfKillPersonByStone = "Ein schwerer Stein, ein leichter Abgang. Endlich ist der Kopf leer und die Nacht dauerhaft."
var SelfKillPersonByAxe = "Ein letzter, schwungvoller Akt der Selbstbefreiung. Die Axet trennt nicht nur Holz, sondern auch Sorgen vom Körper."
var SelfKillPersonByKnive = "Ein kleiner Schnitt für einen Menschen, ein riesiger Sprung in die absolute Belanglosigkeit. Gute Nacht."
var SelfKillPersonByHammer = "Ich habe mir die Probleme aus dem Kopf geschlagen. Buchstäblich. Es war ein sehr kurzer, sehr lauter Moment der Klarheit."
var SelfKillPersonByFork = "Ein bizarres Ende durch Besteck. Ich gehe ab wie ein ungeliebtes Abendessen. Wenigstens stört mich das Kauen nicht mehr."
var SelfKillPersonByPeeler = "Ich habe meine eigene Geduld geschält, bis nichts mehr übrig war. Die letzte Schicht war die Freiheit."
var SelfKillPersonByWindow = "Der schnellste Weg nach unten ist ein Fenster. Ein kurzer Flug, ein harter Aufprall, ein ewiger Schlaf. Keine Verspätung."
var SelfKillPersonBySnake = "Ein letzter Kuss der Viper. Das Gift ist das einzige Schlafmittel, das bei mir noch wirkt."
var SelfKillPersonByRacoon = "Kuscheln mit wilden Plez lässt einen für immer blutig einschlafen."

var WakeUpNoSleepingMask = "Ich bin wach. Wo ist die Maske? Wahrscheinlich hat sie sich aus Verzweiflung selbst aufgelöst, um mein Gesicht nicht mehr sehen zu müssen."
var WakeUpNoLamp = "Die Lampe ist weg. Ein klassischer Fall von Ghosting. Sie konnte meine dunkle Aura wohl einfach nicht mehr beleuchten."
var WakeUpNoWindow = "Kein Fenster mehr. Die Wand hat das Glas gefressen. Endlich Schluss mit dem HD-Livestream der Welt da draußen."
var WakeUpNoBlanket = "Die Decke ist weg. Was kann ich jetzt Kuscheln?"
var WakeUpNoWindowGlas = "Kein Fenster mehr. Wer braucht schon Fenster, wenn man Windows benutzt."
var WakeUpNoNewsletter = "Die Zeitung ist fort. Ich habe ehr nug geblättert."
var WakeUpNoRacoon = "Ein Glück ist der Waschbär weg. Der hat mir schon die ganze Zeit Angst gemacht."
var WakeUpNoSnake = "Die Schlange ist weg. Endlich mal ein Abschied ohne Drama und Zischen. Ich schätze, ich war ihr einfach zu kaltblütig."
var WakeUpNoApple = "Der Apfel ist weg. Dann halt kein Frühstück"
var WakeUpNoPillow = "Kissen weg. Mein Kopf liegt auf der nackten Matratze. Hart, aber ehrlich, gemütlichkeit oder schlafen?."
var WakeUpNoCurtains = "Die Vorhänge sind weg. Dann bleibt doch weg!"
var WakeUpNoWallpaper = "Die Tapete ist weg. Purer Minimalismus. Oder mein Zimmer versucht, sich zu häuten, um diese Flecken loszuwerden."
var WakeUpNoWardrobe = "Kein Schrank mehr. Narnia ist wohl wegen Umbau geschlossen. Jetzt stehe ich hier im Raum wie bestellt und nicht abgeholt."
var WakeUpNoHearingProtection = "Stöpsel weg. Der Lärm der Welt ist zurück. Ein herrlicher Chor aus Chaos und Verzweiflung. Wer braucht schon Stille, wenn man Tinnitus haben kann?"
var WakeUpNoDoor = "Die Tür ist weg. Aber wer braucht die schon?"

var GoToSingerWithFork = "Jetzt habe ich den Nachbar gepiekst! Er war leicht verschreckt."
var GoToSnakeWithFork = "Eine Schlange an der Gabel macht sich bestimmt gut vor der Tür zur Dekoration."
var GoToRacoonWithFork = "Na Waschbär, Piercing gefällig?"
var GoToSingerWithPerson = "Netter Plausch mit meinem Nachbar, aber ich bin schon ziemlich müde."
var GoToSingerWithRacoon = "Mein Nachbar war leicht verwundert über den Waschbären, aber die freunden sich schon noch an."
var GoToSingerWithSnake = "Als ich meinem Nachbar die Schlange gezeigt habe, hat er mir die Tür vor der Nase zugeschlagen."
var GoToSingerWithStone = "Einen Nachbarn weniger."
var GoToSingerWithHammer = "Hab meinem Nachbarn einfach mal den Hammer ausgeliehen, ohne das er es wollte."
var GoToSnakeWithHammer = "Eine flache Schlange einget sich besser als Gürtel."
var GoToRacoonWithHammer = "Morgen gibt es sehr dünne Schnitzel!"
var GoToSingerWithKnive = "As mein Nachbar das Messer sah, konnte er aufeinmal viel besser das hohe C Singen."
var GoToSingerWithAxe = "Ich wollte schon immer einmal Shining bei meinem Nachbar nachspielen."
var UseHearingProtectionByLight = "Wenigstens höre ich jetzt nichts mehr. Aber das Licht stört mich trotzdem."
var JustDestroy = "Einfach mal was kaputt machen.Vielleicht schlafe ich dann von genugtuung."
var JustDestroyApple = "Ich kann keine Äpfel mehr sehen... Wahhhh..."
var CrushLampByNoise = "Jetzt muss ich die Lampe wenigstens nie wieder Ausschalten, aber es ist mir trotzdem zu laut."
var CrushLampWithAppleByNoise = "Apfel mit Scherben zum Frühstück. Mal was anderes..."
var CoverWindowsWithNewsletterByNoise = "Eine dünne Zeitung hilft nicht gegen Geräusche die mich wach halten."
var CrushWindowGlassByNoise = "Ich weiß nicht ob es sinnvoll ist, das Fenster zu Zertören, wenn ich es leiser haben möchte."
var ShutOfWindowLigthByNoise = "Immerhin sieht mich keiner mehr von draußen. Laut ist es trotzdem noch."
var CoverWindowsWithBlanketByNoise = "Jetzt sieht mich keiner mehr und ich kann endlich ohne Decke schlafen. Dann ist mir halt kalt."
var CrushLampWithBlanketByNoise = "Jetzt habe ich scherben in meiner Decke. Dadrunter möchte ich nicht mehr schlafen."
var CrushLampWithPillowByNoise = "Auf einem Kissen mit Scherben schlafe ich mit Sicherheit nicht!"

# Struktur: Vector3(Item, Ziel, Issue) : [GameOver: bool, nextTry: bool, personMessage: String, wakeUpMessage: String, hidingItems: Array]
var itemActionDict : Dictionary[Vector3, Array] = {
	# --- LICHT (Issue.LIGHT) ---
	Vector3(extensions.Item.SleepingMask, extensions.Item.Person, Issue.LIGHT): [false, false, SleepFinaly, WakeUpNoSleepingMask, [extensions.Item.SleepingMask]],
	Vector3(extensions.Item.Stone, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithStone, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Stone, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CrushWindowGlass, WakeUpNoWindow, []],
	Vector3(extensions.Item.Pillow, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithPillow, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Blanket, extensions.Item.Lamp, Issue.LIGHT): [false, false, CrushLampWithBlanket, WakeUpNoLamp, [extensions.Item.Lamp]],
	Vector3(extensions.Item.Blanket, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, CoverWindowsWithBlanket, WakeUpNoBlanket, [extensions.Item.Blanket]],
	Vector3(extensions.Item.Curtains, extensions.Item.WindowGlas, Issue.LIGHT): [false, false, ShutOfWindowLigth, WakeUpNoWindowGlas, [extensions.Item.Curtains, extensions.Item.WindowGlas]],
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
	Vector3(extensions.Item.Axe, extensions.Item.Racoon, Issue.LIGHT): [false, false, CreateRacoonSleepingMask, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Knive, extensions.Item.Racoon, Issue.LIGHT): [false, false, CreateRacoonSleepingMask, WakeUpNoRacoon, [extensions.Item.Racoon]],
	Vector3(extensions.Item.Axe, extensions.Item.Snake, Issue.LIGHT): [false, false, CreateSnakeSleepingMask, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Knive, extensions.Item.Snake, Issue.LIGHT): [false, false, CreateSnakeSleepingMask, WakeUpNoSnake, [extensions.Item.Snake]],
	Vector3(extensions.Item.Axe, extensions.Item.Apple, Issue.LIGHT): [false, false, CreateAppleSleepingMask, WakeUpNoApple, [extensions.Item.Apple]],
	Vector3(extensions.Item.Knive, extensions.Item.Apple, Issue.LIGHT): [false, false, CreateAppleSleepingMask, WakeUpNoApple, [extensions.Item.Apple]],
	Vector3(extensions.Item.Apple, extensions.Item.Peeler, Issue.LIGHT): [false, false, CreateAppleSleepingMask, WakeUpNoApple, [extensions.Item.Apple]],
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
	Vector3(extensions.Item.Curtains, extensions.Item.WindowGlas, Issue.NOISE): [false, true, ShutOfWindowLigthByNoise, "", [extensions.Item.Curtains, extensions.Item.WindowGlas]],
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
