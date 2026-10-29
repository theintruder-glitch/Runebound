extends Node3D
const Touch=preload("res://scripts/touch_controls.gd")
var player:CharacterBody3D
var camera:Camera3D
var touch:Control
var avatar:Node3D
var yaw=0.0
var pitch=-0.26
var walk_phase=0.0
var left_leg:MeshInstance3D
var right_leg:MeshInstance3D
var left_arm:MeshInstance3D
var right_arm:MeshInstance3D
const SPEED=5.5
const GRID=64
const STEP=2.0
func terrain_height(x:float,z:float) -> float:
	return 0.9*sin(x*.075)*cos(z*.065)+0.35*sin(x*.19+z*.11)+0.6*cos(z*.045)
func material(c:Color,roughness:float=1.0) -> StandardMaterial3D:
	var m=StandardMaterial3D.new();m.albedo_color=c;m.roughness=roughness;return m
func _ready() -> void:
	make_environment();make_ground();make_landmarks();make_player();make_hud()
func make_environment() -> void:
	var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("91afbf");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c7d9d8");env.ambient_light_energy=.75
	var world=WorldEnvironment.new();world.environment=env;add_child(world)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-30,0);sun.light_color=Color("ffecce");sun.light_energy=1.1;sun.shadow_enabled=false;add_child(sun)
func make_ground() -> void:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half=GRID*STEP/2
	for z in range(GRID):
		for x in range(GRID):
			var x0=x*STEP-half;var z0=z*STEP-half
			var a=Vector3(x0,terrain_height(x0,z0),z0);var b=Vector3(x0+STEP,terrain_height(x0+STEP,z0),z0);var c=Vector3(x0,terrain_height(x0,z0+STEP),z0+STEP);var d=Vector3(x0+STEP,terrain_height(x0+STEP,z0+STEP),z0+STEP)
			for v in [a,b,c,b,d,c]:
				var blend=clampf((v.y+1.0)/3.0,0.0,1.0);st.set_color(Color("526742").lerp(Color("9aa476"),blend));st.add_vertex(v)
	st.generate_normals();var mesh=st.commit()
	var ground=MeshInstance3D.new();ground.mesh=mesh;var mat=material(Color.WHITE);mat.vertex_color_use_as_albedo=true;ground.material_override=mat;add_child(ground)
	var body=StaticBody3D.new();var shape=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();body.add_child(shape);add_child(body)
func add_mesh(parent:Node3D,mesh:Mesh,pos:Vector3,color:Color,rotation_value:Vector3=Vector3.ZERO) -> MeshInstance3D:
	var n=MeshInstance3D.new();n.mesh=mesh;n.position=pos;n.rotation=rotation_value;n.material_override=material(color);parent.add_child(n);return n
func box(parent:Node3D,dimensions:Vector3,pos:Vector3,color:Color) -> MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=dimensions;return add_mesh(parent,mesh,pos,color)
func cylinder(parent:Node3D,radius:float,height:float,pos:Vector3,color:Color) -> MeshInstance3D:
	var mesh=CylinderMesh.new();mesh.top_radius=radius*.7;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=8;return add_mesh(parent,mesh,pos,color)
func make_landmarks() -> void:
	var rng=RandomNumberGenerator.new();rng.seed=9012
	for i in range(95):
		var x=rng.randf_range(-55,55);var z=rng.randf_range(-55,55)
		if Vector2(x,z).length()<8 or (absf(x)<9 and z < -28): continue
		var p=Vector3(x,terrain_height(x,z),z);var tree=Node3D.new();tree.position=p;add_child(tree)
		var h=rng.randf_range(3.5,6.5);cylinder(tree,.24,h*.55,Vector3(0,h*.28,0),Color("584638"))
		var crown=CylinderMesh.new();crown.top_radius=0;crown.bottom_radius=h*.30;crown.height=h*.66;crown.radial_segments=7
		add_mesh(tree,crown,Vector3(0,h*.72,0),[Color("38563d"),Color("4a6a46"),Color("587451")][i%3])
	# A distant castle silhouette provides a destination without collision or a dungeon yet.
	var castle=Node3D.new();castle.position=Vector3(0,terrain_height(0,-43),-43);add_child(castle)
	box(castle,Vector3(14,6,4),Vector3(0,3,0),Color("59616b"))
	for side in [-1,1]:
		box(castle,Vector3(4,10,5),Vector3(side*8,5,0),Color("646d74"))
		for x in range(-1,2):box(castle,Vector3(.7,1,5),Vector3(side*8+x*1.5,10.4,0),Color("7b8280"))
	box(castle,Vector3(3.5,4,.2),Vector3(0,2,2.1),Color("222b32"))
func make_player() -> void:
	player=CharacterBody3D.new();player.name="Player";add_child(player);player.position=Vector3(0,terrain_height(0,0)+2,0)
	var collision=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.35;capsule.height=1.8;collision.shape=capsule;collision.position.y=.9;player.add_child(collision)
	avatar=Node3D.new();avatar.name="Avatar";player.add_child(avatar)
	var leather=Color("49414b");var armor=Color("72818b");var trim=Color("b99a61")
	box(avatar,Vector3(.72,.80,.38),Vector3(0,1.14,0),armor)
	box(avatar,Vector3(.74,.13,.42),Vector3(0,.84,0),trim)
	box(avatar,Vector3(.64,.78,.1),Vector3(0,1.07,.25),Color("46384f"))
	var head=SphereMesh.new();head.radius=.24;head.height=.48;head.radial_segments=12;head.rings=6;add_mesh(avatar,head,Vector3(0,1.84,0),Color("c8a68b"))
	box(avatar,Vector3(.5,.14,.42),Vector3(0,2.02,.03),leather)
	left_leg=box(avatar,Vector3(.25,.7,.29),Vector3(-.19,.37,0),leather);right_leg=box(avatar,Vector3(.25,.7,.29),Vector3(.19,.37,0),leather)
	left_arm=box(avatar,Vector3(.24,.7,.25),Vector3(-.49,1.13,0),armor);right_arm=box(avatar,Vector3(.24,.7,.25),Vector3(.49,1.13,0),armor)
	var sword=box(avatar,Vector3(.07,1.05,.12),Vector3(.52,1.02,.16),Color("d5d7c8"));sword.rotation.z=-.35
	camera=Camera3D.new();camera.current=true;camera.fov=65;add_child(camera);update_camera(1.0)
func make_hud() -> void:
	var layer=CanvasLayer.new();add_child(layer);touch=Touch.new();layer.add_child(touch)
	var title=Label.new();title.text="VYRNSPIRE · 3D TEST AREA";title.position=Vector2(22,18);title.add_theme_font_size_override("font_size",20);touch.add_child(title)
	var desc=Label.new();desc.text="Left thumb: move  ·  Right thumb: look around\nPrototype: terrain, movement and camera only";desc.position=Vector2(22,48);desc.add_theme_font_size_override("font_size",14);touch.add_child(desc)
func update_camera(dt:float) -> void:
	var target=player.position+Vector3(0,1.4,0)
	var offset=Vector3(0,2.4,7).rotated(Vector3.RIGHT,-pitch).rotated(Vector3.UP,yaw)
	var desired=target+offset
	camera.global_position=camera.global_position.lerp(desired,clampf(dt*9,0,1));camera.look_at(target,Vector3.UP)
func _physics_process(dt:float) -> void:
	if player==null:return
	var look=touch.take_look();yaw-=look.x*.005;pitch=clampf(pitch-look.y*.003,-.7,.3)
	var input=touch.direction
	if input==Vector2.ZERO:
		input=Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W))).limit_length(1)
	var right=Vector3.RIGHT.rotated(Vector3.UP,yaw);var forward=Vector3(0,0,1).rotated(Vector3.UP,yaw)
	var move=(right*input.x+forward*input.y).limit_length(1)
	player.velocity.x=move.x*SPEED;player.velocity.z=move.z*SPEED;player.velocity.y-=18*dt
	player.move_and_slide()
	if move.length()>.05:
		avatar.rotation.y=atan2(-move.x,-move.z);walk_phase+=dt*9
	else: walk_phase=lerpf(walk_phase,round(walk_phase/PI)*PI,dt*8)
	left_leg.rotation.x=sin(walk_phase)*.45;right_leg.rotation.x=-left_leg.rotation.x;left_arm.rotation.x=-left_leg.rotation.x*.7;right_arm.rotation.x=left_leg.rotation.x*.7
	if player.position.y < -10:player.position=Vector3(0,terrain_height(0,0)+2,0);player.velocity=Vector3.ZERO
	update_camera(dt)
