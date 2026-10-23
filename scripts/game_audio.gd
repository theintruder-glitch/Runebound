extends Node
const CUES={"cook":preload("res://assets/audio/cook.wav"),"howl":preload("res://assets/audio/howl.wav"),"attack":preload("res://assets/audio/attack.wav"),"hit":preload("res://assets/audio/hit.wav"),"hurt":preload("res://assets/audio/hurt.wav"),"gather":preload("res://assets/audio/gather.wav"),"build":preload("res://assets/audio/build.wav"),"spell":preload("res://assets/audio/spell.wav"),"reward":preload("res://assets/audio/reward.wav")}
var enabled=true
var can_play=false
var voices:Array=[]
var voice_index=0
var music:AudioStreamPlayer
var last_hit=0
var last_howl=-2000
func _ready() -> void:
 can_play=DisplayServer.get_name()!="headless"
 var cfg=ConfigFile.new()
 if cfg.load("user://audio.cfg")==OK: enabled=bool(cfg.get_value("sound","enabled",true))
 for i in range(4):
  var voice=AudioStreamPlayer.new(); voice.volume_db=-12; add_child(voice); voices.append(voice)
 music=AudioStreamPlayer.new()
 var track=preload("res://assets/audio/forest.wav").duplicate()
 track.loop_mode=AudioStreamWAV.LOOP_FORWARD
 track.loop_begin=0; track.loop_end=track.data.size()/2
 music.stream=track; music.volume_db=-15; add_child(music)
 if enabled and can_play: music.play()
func play_cue(cue:String) -> void:
 if not can_play or not enabled or not CUES.has(cue) or voices.is_empty(): return
 if cue=="howl":
  if Time.get_ticks_msec()-last_howl<1800: return
  last_howl=Time.get_ticks_msec()
 if cue=="hit":
  if Time.get_ticks_msec()-last_hit<65: return
  last_hit=Time.get_ticks_msec()
 var voice=voices[voice_index]; voice_index=(voice_index+1)%voices.size()
 voice.stream=CUES[cue]; voice.play()
func toggle() -> void:
 enabled=not enabled
 if enabled and can_play: music.play()
 else:
  music.stop()
  for voice in voices: voice.stop()
 var cfg=ConfigFile.new(); cfg.set_value("sound","enabled",enabled); cfg.save("user://audio.cfg")

func _notification(what:int) -> void:
 if music==null: return
 if what==NOTIFICATION_APPLICATION_PAUSED:
  music.stream_paused=true
  for voice in voices: voice.stop()
 elif what==NOTIFICATION_APPLICATION_RESUMED:
  music.stream_paused=false
func _exit_tree() -> void:
 if music!=null: music.stop()
 for voice in voices: voice.stop()
