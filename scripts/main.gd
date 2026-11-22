extends Node2D

const SAVE_PATH := "user://aetheria_save.json"
const CREATURES := {
 "terracristal":{"name":"Terracristal","type":"Brote","hp":34,"atk":8,"skill":"Pulso de Raíz","power":14,"art":"res://assets/creatures/terracristal.svg"},
 "luminzorro":{"name":"Luminzorro","type":"Éter","hp":29,"atk":10,"skill":"Destello Lunar","power":16,"art":"res://assets/creatures/luminzorro.svg"},
 "brasalisco":{"name":"Brasalisco","type":"Brasa","hp":32,"atk":9,"skill":"Cola Ígnea","power":15,"art":"res://assets/creatures/brasalisco.svg"},
 "umbrongo":{"name":"Umbrongo","type":"Umbría","hp":30,"atk":8,"skill":"Esporas Oníricas","power":15,"art":"res://assets/creatures/umbrongo.svg"}
}
const WILD := ["terracristal","luminzorro","brasalisco","umbrongo"]
var tile := Vector2i(3,6)
var steps := 0
var party: Array[Dictionary] = []
var mode := "intro"
var enemy: Dictionary = {}
var enemy_hp := 0
var hero_hp := 0
var msg := "El faro antiguo vuelve a latir."
var hold_dir := Vector2i.ZERO
var repeat_time := 0.0
var battle_ui: Control
var hud_label: Label
var world_ui: Control

func _ready() -> void:
 randomize()
 _build_ui()
 _load_save()
 mode = "world" if not party.is_empty() else "intro"
 _sync_ui()
 queue_redraw()

func _process(delta: float) -> void:
 if mode == "world":
  repeat_time = maxf(0.0, repeat_time-delta)
  var d := hold_dir
  if d == Vector2i.ZERO:
   if Input.is_action_pressed("ui_up"): d = Vector2i.UP
   elif Input.is_action_pressed("ui_down"): d = Vector2i.DOWN
   elif Input.is_action_pressed("ui_left"): d = Vector2i.LEFT
   elif Input.is_action_pressed("ui_right"): d = Vector2i.RIGHT
  if d != Vector2i.ZERO and repeat_time <= 0.0:
   _move(d)
   repeat_time = 0.15

func _draw() -> void:
 if mode == "intro":
  draw_rect(Rect2(Vector2.ZERO,Vector2(960,540)),Color("#101d30"))
  draw_circle(Vector2(480,175),105,Color("#24556a"))
  draw_circle(Vector2(480,175),68,Color("#62c7bd"))
  draw_string(ThemeDB.fallback_font,Vector2(230,345),"ECOS DE AETHERIA",-1,Color("#eff5dc"),38)
  draw_string(ThemeDB.fallback_font,Vector2(330,385),"El despertar de los faros",-1,Color("#a9d9d2"),20)
  draw_string(ThemeDB.fallback_font,Vector2(280,465),"Pulsa INICIAR para elegir tu primer vínculo",-1,Color("#e4e8df"),18)
 elif mode == "world":
  _draw_world()
 elif mode == "battle":
  _draw_battle()

func _draw_world() -> void:
 draw_rect(Rect2(Vector2.ZERO,Vector2(960,540)),Color("#203b3d"))
 for y in range(11):
  for x in range(20):
   var p := Vector2(x*48,y*48)
   var col := Color("#456f59")
   if x==0 or y==0 or x==19 or y==10: col=Color("#263d43")
   elif x>=8 and x<=12 and y>=2 and y<=7: col=Color("#927b57")
   elif _grass(Vector2i(x,y)): col=Color("#315b45")
   elif (x+y)%6==0: col=Color("#527b5e")
   draw_rect(Rect2(p,Vector2(47,47)),col)
   if _grass(Vector2i(x,y)):
    draw_line(p+Vector2(9,37),p+Vector2(15,17),Color("#9bc37a"),2)
    draw_line(p+Vector2(28,38),p+Vector2(35,15),Color("#9bc37a"),2)
 draw_rect(Rect2(410,120,140,92),Color("#806448"))
 draw_rect(Rect2(440,88,80,48),Color("#c1a26d"))
 draw_circle(Vector2(480,110),14,Color("#74e9df"))
 draw_string(ThemeDB.fallback_font,Vector2(405,235),"ALDEA BRUMAL",-1,Color("#fff0c9"),17)
 var pos := Vector2(tile.x*48+24,tile.y*48+24)
 draw_circle(pos+Vector2(0,9),13,Color("#15232a"))
 draw_circle(pos,12,Color("#ead3a4"))
 draw_rect(Rect2(pos+Vector2(-9,7),Vector2(18,18)),Color("#4293a0"))
 draw_rect(Rect2(18,18,360,76),Color(0.02,0.06,0.09,0.88))
 draw_string(ThemeDB.fallback_font,Vector2(34,48),"AETHERIA  /  ALDEA BRUMAL",-1,Color("#e1efdc"),18)
 draw_string(ThemeDB.fallback_font,Vector2(34,73),"Pasos: %d   Vínculos: %d" % [steps,party.size()],-1,Color("#a7d1c6"),14)
 draw_string(ThemeDB.fallback_font,Vector2(250,520),"Explora la hierba brillante para hallar criaturas",-1,Color("#f5e9c9"),17)

func _draw_battle() -> void:
 draw_rect(Rect2(Vector2.ZERO,Vector2(960,540)),Color("#243c51"))
 draw_circle(Vector2(760,110),54,Color("#a4d9d0"))
 for i in range(7):
  var x := i*160-40
  draw_polygon(PackedVector2Array([Vector2(x,300),Vector2(x+85,130+(i%2)*40),Vector2(x+170,300)]),PackedColorArray([Color("#365b57")]))
 draw_rect(Rect2(0,300,960,240),Color("#54745a"))
 _draw_creature(enemy.get("id","terracristal"),Vector2(720,235),170)
 if not party.is_empty():
  _draw_creature(party[0].id,Vector2(245,365),180)
 draw_rect(Rect2(35,24,380,92),Color(0.02,0.06,0.1,0.9))
 draw_string(ThemeDB.fallback_font,Vector2(55,56),enemy.get("name","Criatura"),-1,Color("#f7e8d0"),23)
 draw_rect(Rect2(55,75,320,14),Color("#512e3a"))
 draw_rect(Rect2(55,75,320.0*float(enemy_hp)/maxf(1.0,float(enemy.get("max_hp",1))),14),Color("#83d48f"))
 draw_rect(Rect2(565,420,355,90),Color(0.02,0.06,0.1,0.9))
 if not party.is_empty():
  draw_string(ThemeDB.fallback_font,Vector2(585,450),party[0].name,-1,Color("#f7e8d0"),20)
  draw_string(ThemeDB.fallback_font,Vector2(585,481),"PV %d / %d" % [hero_hp,party[0].max_hp],-1,Color("#a9e4bd"),17)
 draw_rect(Rect2(25,420,510,90),Color(0.02,0.06,0.1,0.9))
 draw_string(ThemeDB.fallback_font,Vector2(44,454),msg,-1,Color("#f7eddb"),16)

func _draw_creature(id: String, center: Vector2, size: float) -> void:
 var tex := load(CREATURES[id].art) as Texture2D
 if tex:
  draw_texture_rect(tex,Rect2(center-Vector2(size/2,size/2),Vector2(size,size)),false)

func _grass(p: Vector2i) -> bool:
 return (p.x>=14 and p.y>=2 and p.y<=8) or (p.x>=2 and p.x<=5 and p.y<=2)

func _move(d: Vector2i) -> void:
 var n := tile+d
 if n.x<1 or n.x>18 or n.y<1 or n.y>9: return
 tile=n
 steps+=1
 if _grass(n) and randf()<0.18: _encounter()
 queue_redraw()

func _build_ui() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(root)
 var top := HBoxContainer.new()
 top.set_anchors_preset(Control.PRESET_TOP_WIDE)
 top.offset_left=12
 top.offset_top=10
 top.offset_right=-12
 top.offset_bottom=64
 root.add_child(top)
 var spacer := Control.new()
 spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 top.add_child(spacer)
 var save := _btn("Guardar",Vector2(112,46))
 save.pressed.connect(_save_game)
 top.add_child(save)
 world_ui=Control.new()
 world_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(world_ui)
 var pad := GridContainer.new()
 pad.columns=3
 pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
 pad.offset_left=18
 pad.offset_top=-168
 pad.offset_right=190
 pad.offset_bottom=-14
 world_ui.add_child(pad)
 for k in ["","▲","","◀","●","▶","","▼",""]:
  var b := _btn(k,Vector2(54,48))
  if k=="":
   b.disabled=true
   b.modulate=Color(1,1,1,0.08)
  elif k=="●":
   b.pressed.connect(_interact)
  else:
   b.button_down.connect(func(): hold_dir=_dir(k))
   b.button_up.connect(func(): hold_dir=Vector2i.ZERO)
  pad.add_child(b)
 var actions := VBoxContainer.new()
 actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
 actions.offset_left=-170
 actions.offset_top=-120
 actions.offset_right=-15
 actions.offset_bottom=-14
 world_ui.add_child(actions)
 var act := _btn("A / Acción",Vector2(150,52))
 act.pressed.connect(_interact)
 actions.add_child(act)
 var team := _btn("Equipo",Vector2(150,46))
 team.pressed.connect(_team)
 actions.add_child(team)
 battle_ui=Control.new()
 battle_ui.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
 battle_ui.offset_left=180
 battle_ui.offset_top=-100
 battle_ui.offset_right=-180
 battle_ui.offset_bottom=-10
 root.add_child(battle_ui)
 var row := HBoxContainer.new()
 battle_ui.add_child(row)
 for pair in [["Atacar",_attack],["Técnica",_skill],["Vínculo",_capture],["Huir",_flee]]:
  var b := _btn(pair[0],Vector2(130,64))
  b.pressed.connect(pair[1])
  row.add_child(b)
 var start := _btn("INICIAR",Vector2(230,60))
 start.set_anchors_preset(Control.PRESET_CENTER)
 start.position=Vector2(-115,210)
 root.add_child(start)
 start.pressed.connect(func(): _starter("terracristal"))
 hud_label=Label.new()
 hud_label.visible=false
 root.add_child(hud_label)

func _btn(text_value: String, size: Vector2) -> Button:
 var b := Button.new()
 b.text=text_value
 b.custom_minimum_size=size
 b.add_theme_font_size_override("font_size",17)
 return b

func _dir(k: String) -> Vector2i:
 match k:
  "▲": return Vector2i.UP
  "▼": return Vector2i.DOWN
  "◀": return Vector2i.LEFT
  "▶": return Vector2i.RIGHT
 return Vector2i.ZERO

func _sync_ui() -> void:
 if world_ui: world_ui.visible=mode=="world"
 if battle_ui: battle_ui.visible=mode=="battle"
 queue_redraw()

func _starter(id: String) -> void:
 var c: Dictionary=CREATURES[id]
 party=[{"id":id,"name":c.name,"max_hp":c.hp,"hp":c.hp,"level":5,"xp":0}]
 hero_hp=c.hp
 mode="world"
 msg="Tu vínculo con %s comienza." % c.name
 _save_game()
 _sync_ui()

func _interact() -> void:
 if mode=="intro": _starter("terracristal")
 elif mode=="world":
  msg="La guardiana del faro susurra: los ecos eligen a quien sabe escuchar."
  queue_redraw()

func _encounter() -> void:
 var id: String=WILD[randi_range(0,WILD.size()-1)]
 var c: Dictionary=CREATURES[id]
 enemy={"id":id,"name":c.name,"max_hp":c.hp+randi_range(-3,4),"atk":c.atk,"power":c.power}
 enemy_hp=enemy.max_hp
 hero_hp=party[0].hp
 mode="battle"
 msg="¡Un %s salvaje aparece!" % c.name
 _sync_ui()

func _attack() -> void:
 if mode!="battle": return
 enemy_hp=maxi(0,enemy_hp+(-int(CREATURES[party[0].id].atk)-randi_range(2,5)))
 if enemy_hp==0: _victory()
 else:
  msg="¡Golpe certero!"
  _enemy_turn()
 queue_redraw()

func _skill() -> void:
 if mode!="battle": return
 var c: Dictionary=CREATURES[party[0].id]
 enemy_hp=maxi(0,enemy_hp-int(c.power)-randi_range(3,7))
 if enemy_hp==0: _victory()
 else:
  msg="%s usa %s." % [party[0].name,c.skill]
  _enemy_turn()
 queue_redraw()

func _enemy_turn() -> void:
 var dmg:=randi_range(4,8)
 hero_hp=maxi(0,hero_hp-dmg)
 party[0].hp=hero_hp
 if hero_hp==0:
  hero_hp=maxi(1,int(party[0].max_hp)/2)
  party[0].hp=hero_hp
  mode="world"
  msg="Tu vínculo se debilita. El faro te devuelve a salvo."
  _sync_ui()
 else:
  msg+="  Recibes %d de daño." % dmg

func _victory() -> void:
 party[0].xp+=12
 if party[0].xp>=30:
  party[0].xp-=30
  party[0].level+=1
  party[0].max_hp+=4
  party[0].hp=party[0].max_hp
  msg="¡Victoria! %s alcanza nivel %d." % [party[0].name,party[0].level]
 else: msg="¡Victoria! Ganas 12 EXP."
 mode="world"
 _sync_ui()
 _save_game()

func _capture() -> void:
 if mode!="battle": return
 if party.size()>=3:
  msg="Tu equipo ya tiene tres vínculos."
 elif randf()<0.35+0.5*(1.0-float(enemy_hp)/float(enemy.max_hp)):
  var c: Dictionary=CREATURES[enemy.id]
  party.append({"id":enemy.id,"name":enemy.name,"max_hp":c.hp,"hp":c.hp,"level":3,"xp":0})
  msg="%s se une a tu equipo." % enemy.name
  mode="world"
  _sync_ui()
  _save_game()
 else:
  msg="La criatura resiste el vínculo."
  _enemy_turn()
 queue_redraw()

func _flee() -> void:
 if mode=="battle":
  mode="world"
  msg="Te retiras con cuidado."
  _sync_ui()

func _team() -> void:
 var labels: Array[String]=[]
 for c in party: labels.append("%s Nv.%d" % [c.name,c.level])
 msg="Equipo: "+" · ".join(labels)
 queue_redraw()

func _save_game() -> void:
 var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if f:
  f.store_string(JSON.stringify({"x":tile.x,"y":tile.y,"steps":steps,"party":party}))
  f.close()

func _load_save() -> void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var f:=FileAccess.open(SAVE_PATH,FileAccess.READ)
 if not f: return
 var data=JSON.parse_string(f.get_as_text())
 f.close()
 if data is Dictionary:
  tile=Vector2i(int(data.get("x",3)),int(data.get("y",6)))
  steps=int(data.get("steps",0))
  for c in data.get("party",[]): party.append(c)
