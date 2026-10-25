extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if ok:print("PASS: "+message)
 else:failures+=1;push_error("FAIL: "+message)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=99999
 var art=game.world.field_visuals;var image=art.ATLAS.get_image()
 check(art.textures.size()==16 and image.get_size()==Vector2i(512,512),"Sixteen props share one 1 MiB base RGBA atlas")
 var hashes={}
 for id in art.KINDS:
  var tex=art.textures[id];var visible=0;var transparent=0;var region=Rect2i(tex.region)
  for x in range(region.position.x,region.end.x,4):
   for y in range(region.position.y,region.end.y,4):
    if image.get_pixel(x,y).a>.1:visible+=1
    else:transparent+=1
  check(visible>50 and transparent>100 and tex.filter_clip,"Visible detailed art, transparent padding and clipped sampling: "+id)
  hashes[image.get_region(region).get_data().hex_encode().sha256_text()]=true
 check(hashes.size()==16,"Every resource and story site has distinct artwork")
 var kinds={}
 for pos in [Vector2.ZERO,Vector2(2050,0),Vector2(-2050,0),Vector2(0,-2050)]:
  game.set_player_position(pos);game.survival.refresh(true)
  for n in game.survival.nodes:kinds[n.kind]=true
 check(kinds.size()==12 and kinds.keys().all(func(id):return art.textures.has(id)),"All twelve actual regional gathering kinds have atlas art")
 game.set_player_position(Vector2.ZERO);game.hero.survival.structures.clear();game.survival.refresh(true)
 for id in kinds:
  var node={"id":"art-gather-"+id,"kind":id,"pos":Vector2.ZERO};game.survival.nodes=[node];game.survival.gather_cooldown=0
  var count=game.survival.count(id);var amount=game.survival.gather_amount(id)
  check(game.survival.gather() and game.survival.count(id)==count+amount and game.hero.survival.harvested.has(node.id),"New art retains actual gathering yield and harvested identity: "+id)
 check(game.forest.objective().contains("woodpile") or game.hero.journey.wood,"Opening guide remains consistent with woodpile art")
 var preserved=JSON.stringify(game.hero)
 for quality in game.graphics.LEVELS:
  game.graphics.set_quality(quality);game.graphics._process(0)
  check(game.world.field_visuals.textures.size()==16,"All detailed pickups remain visible at "+quality)
  if quality=="Performance":check(game.graphics.lights.all(func(l):return not l.enabled),"Fieldcraft adds no lights in Performance mode")
 check(JSON.stringify(game.hero)==preserved,"Artwork quality changes do not mutate character progression")
 game.graphics.set_quality("Performance");game.set_player_position(game.chapter.CLUES.cart.point);game.world.refresh(true)
 var rebuilt=game.world.scenery_rebuilds
 for i in range(6):await process_frame
 check(game.world.scenery_rebuilds==rebuilt,"Detailed resource and story-site draw commands stay cached while stationary")
 var chapter=game.chapter;game.hero.chapter.accepted=true;game.hero.chapter.clues.clear()
 check(chapter.nearby_clue()=="cart","Wagon investigation keeps the original physical location")
 check(chapter.investigate("cart") and game.world.scenery_rebuilds>rebuilt,"Investigation updates the cached found-marker immediately")
 check(not chapter.investigate("cart"),"Detailed wagon cannot award its clue twice")
 var restored=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not restored.is_empty() and restored.chapter.clues.cart,"Existing character schema preserves investigated props and materials")
 check(art.bounds("cart",Vector2.ZERO).size.x>art.bounds("Wood",Vector2.ZERO).size.x,"Wagon silhouette is larger than a gatherable woodpile")
 for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
  root.size=dims;game.adapt_screen();game.world.refresh(true);await process_frame;await process_frame
  check(art.textures.size()==16 and game.world.scenery.visible,"Shared cached prop art remains active in "+str(dims))
 game.set_player_position(game.exploration.RUINS);game.hero.chapter.clues={"watch":true,"cart":true,"grove":true};game.hero.chapter.translated=true
 check(chapter.begin(),"New site art leaves story expedition entry intact")
 game.set_player_position(chapter.cache_position());var gold=game.hero.gold
 check(chapter.cache_near(),"Detailed runic cache retains its existing interaction position")
 chapter.interact();check(game.hero.gold==gold+20 and not chapter.cache_near(),"Detailed cache still pays once and closes")
 print("%d FIELDCRAFT CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
