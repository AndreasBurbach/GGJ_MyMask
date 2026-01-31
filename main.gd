extends Node

@onready var coursorObj = $CourserLayer/CourserObj

var selectedObj: Area2D
var cursorOffset: Vector2 = Vector2(0,10)
var name2item: Dictionary[String,Area2D]
var selected = false

enum Item {
	Person,
	SleepingMask,
	Blanket,
	Pillow,
	Wardrobe,
	LightSwitch,
	Curtains,
	Ax,
	Hammer,
	HearingProtection,
	Stone,
	WindowGlas,
	Knive,
	Appel,
	Racoon,
	Peeler,
	Newsletter,
	Glue,
	Wallpaper,
	Fork,
	Lamp,
	Snake,
	Door,
}

enum ItemAction{
	UsePillowAsSleepingMask,
	UseBlanketAsSleepingMask,
	UseSleepingMask,
	CreateAppleSleepingMask,
	CreateRacoonSleepingMask,
	CreateSnakeSleepingMask,
	CreateSleepingMask,
	CrushWindowGlass,
	CrushLamp,
	ShutOfLamp,
	KillRacoon,
	UseHearingProtection,
	UsePillowAsHearingProtection,
	CloseDoor,
	KillSinger,
	KillSnake,
	KillPerson,
	ShutOfWindowLigth,
	HidingInWardrobe,
	UseCurtainsAsSleepingMask,
	CoverWindows,
}

# Vector2 => Item was man auf das Item zieht
var itemActionDict : Dictionary[Vector2,ItemAction] = {
	Vector2(Item.SleepingMask,Item.Person): ItemAction.UseSleepingMask,
	Vector2(Item.SleepingMask,Item.Racoon): ItemAction.KillRacoon,
	Vector2(Item.Stone,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Stone,Item.WindowGlas): ItemAction.CrushWindowGlass,
	Vector2(Item.Stone,Item.Person): ItemAction.KillPerson,
	Vector2(Item.Stone,Item.Door): ItemAction.KillSinger,
	Vector2(Item.Pillow,Item.Knive): ItemAction.KillRacoon,
	Vector2(Item.Pillow,Item.Peeler): ItemAction.CreateSleepingMask,	
	Vector2(Item.Pillow,Item.Person): ItemAction.UsePillowAsSleepingMask,
	Vector2(Item.Pillow,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Blanket,Item.Person): ItemAction.UseBlanketAsSleepingMask,
	Vector2(Item.Blanket,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Blanket,Item.Racoon): ItemAction.KillRacoon,
	Vector2(Item.Blanket,Item.Snake): ItemAction.KillSnake,
	Vector2(Item.Blanket,Item.WindowGlas): ItemAction.CoverWindows,
	Vector2(Item.Curtains,Item.WindowGlas): ItemAction.ShutOfWindowLigth,
	Vector2(Item.Curtains,Item.Person): ItemAction.UseCurtainsAsSleepingMask,
	Vector2(Item.LightSwitch,Item.Lamp): ItemAction.ShutOfLamp,
	Vector2(Item.Ax,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Ax,Item.WindowGlas): ItemAction.CrushWindowGlass,
	Vector2(Item.Ax,Item.Appel): ItemAction.CreateAppleSleepingMask,
	Vector2(Item.Ax,Item.Racoon): ItemAction.KillRacoon,
	Vector2(Item.Ax,Item.Snake): ItemAction.KillSnake,
	Vector2(Item.Ax,Item.Newsletter): ItemAction.CreateSleepingMask,
	Vector2(Item.Ax,Item.Curtains): ItemAction.CreateSleepingMask,
	Vector2(Item.Ax,Item.Door): ItemAction.KillSinger,
	Vector2(Item.Ax,Item.Person): ItemAction.KillPerson,
	Vector2(Item.Ax,Item.Blanket): ItemAction.CreateSleepingMask,
	Vector2(Item.Ax,Item.Pillow): ItemAction.CreateSleepingMask,
	Vector2(Item.Ax,Item.Wallpaper): ItemAction.CreateSleepingMask,
	Vector2(Item.Knive,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Knive,Item.Appel): ItemAction.CreateAppleSleepingMask,
	Vector2(Item.Knive,Item.Racoon): ItemAction.KillRacoon,
	Vector2(Item.Knive,Item.Snake): ItemAction.KillSnake,
	Vector2(Item.Knive,Item.Newsletter): ItemAction.CreateSleepingMask,
	Vector2(Item.Knive,Item.Curtains): ItemAction.CreateSleepingMask,
	Vector2(Item.Knive,Item.Door): ItemAction.KillSinger,
	Vector2(Item.Knive,Item.Person): ItemAction.KillPerson,
	Vector2(Item.Knive,Item.Blanket): ItemAction.CreateSleepingMask,
	Vector2(Item.Knive,Item.Pillow): ItemAction.CreateSleepingMask,
	Vector2(Item.Knive,Item.Wallpaper): ItemAction.CreateSleepingMask,
	Vector2(Item.Fork,Item.Racoon): ItemAction.KillRacoon,
	Vector2(Item.Fork,Item.Snake): ItemAction.KillSnake,
	Vector2(Item.Fork,Item.Door): ItemAction.KillSinger,
	Vector2(Item.Fork,Item.Person): ItemAction.KillPerson,
	Vector2(Item.Fork,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Hammer,Item.Racoon): ItemAction.KillRacoon,
	Vector2(Item.Hammer,Item.Snake): ItemAction.KillSnake,
	Vector2(Item.Hammer,Item.Door): ItemAction.KillSinger,
	Vector2(Item.Hammer,Item.Person): ItemAction.KillPerson,
	Vector2(Item.Hammer,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Hammer,Item.WindowGlas): ItemAction.CrushWindowGlass,
	Vector2(Item.HearingProtection,Item.Person): ItemAction.UseHearingProtection,
	Vector2(Item.Appel,Item.Lamp): ItemAction.CrushLamp,
	Vector2(Item.Appel,Item.Peeler): ItemAction.CreateAppleSleepingMask,
	Vector2(Item.Snake,Item.Door): ItemAction.KillSinger,
	Vector2(Item.Racoon,Item.Door): ItemAction.KillRacoon,
	Vector2(Item.Person,Item.Door): ItemAction.KillSinger,	
	Vector2(Item.Person,Item.Wardrobe): ItemAction.HidingInWardrobe,
	Vector2(Item.Person,Item.Racoon): ItemAction.KillPerson,
	Vector2(Item.Person,Item.Snake): ItemAction.KillPerson,
	Vector2(Item.Person,Item.WindowGlas): ItemAction.KillPerson,
	Vector2(Item.Person,Item.Peeler): ItemAction.KillPerson,
	Vector2(Item.Newsletter,Item.WindowGlas): ItemAction.CoverWindows,
	Vector2(Item.Newsletter,Item.Person): ItemAction.UseSleepingMask,
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var children = $ItemContainer.get_children()
	for child in children: 
		name2item[child.name] = child 
	coursorObj.hide()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		if selectedObj != null:
			selectedObj.show() 
		coursorObj.hide()
		selected = false
	var x = Vector2(coursorObj.texture.get_width()/2, coursorObj.texture.get_height() / 2)
	coursorObj.position = get_viewport().get_mouse_position() + x
	pass

func interaction(a1:Area2D,a2:Area2D) -> void: 
	print("use ", a1.name, " on ", a2.name)

func _on_placeholder_selected(name: String,texture:Texture) -> void:
	if selected: 
		var other = name2item[name] 
		interaction(selectedObj,other)
		return
	print(name )
	selectedObj = name2item[name]
	selectedObj.hide() 
	coursorObj.texture = texture
	coursorObj.show()
	selected = true
	pass # Replace with function body.
