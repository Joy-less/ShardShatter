@tool
class_name ShardShatter
extends Node

signal on_finished(target: Node3D)

@export_group("Fade")
@export var fade_duration: float = 1.0
@export var fade_color: Color = Color.WHITE
@export var fade_emission: Color = Color.AQUA
@export var fade_emission_multiplier: float = 2.0
@export_group("Shatter")
@export var shatter_offset_use_aabb: bool = true
@export var shatter_offset: Vector3 = Vector3.ZERO
@export var shatter_radius_use_aabb: bool = true
@export var shatter_radius: float = 0.0
@export var shatter_color: Color = Color.WHITE
@export var shatter_emission: Color = Color.AQUA
@export var shatter_emission_multiplier: float = 2.0
@export var shatter_amount: int = 1024
@export var shatter_velocity: Vector2 = Vector2(3.5, 3.5)
@export var shatter_damping: Vector2 = Vector2(1.0, 1.0)
@export var shatter_scale: Vector2 = Vector2(0.8, 1.2)
@export_group("Editor")
@export var target_path: NodePath = ^"."
@export_tool_button("Shatter") var shatter_button := shatter

static var fade_material: ShaderMaterial = preload("res://addons/ShardShatter/FadeMaterial.tres")
static var shatter_particles: PackedScene = preload("res://addons/ShardShatter/ShatterParticles.tscn")

func shatter() -> void:
	var target: Node = get_node(target_path)
	shatter_target(target)

func shatter_target(target: Node3D) -> void:
	var shatter_offset_final: Vector3 = shatter_offset
	if shatter_offset_use_aabb:
		if target is VisualInstance3D:
			shatter_offset_final = target.get_aabb().get_center() * target.scale
	
	var shatter_radius_final: float = shatter_radius
	if shatter_radius_use_aabb:
		if target is VisualInstance3D:
			shatter_radius_final = _get_average_component(target.get_aabb().size) \
				* _get_average_component(target.scale) / 2
	
	_shatter_core(target, fade_duration, fade_color, fade_emission,
		fade_emission_multiplier, shatter_offset_final, shatter_radius_final,
		shatter_color, shatter_emission, shatter_emission_multiplier,
		shatter_amount, shatter_velocity, shatter_damping,
		shatter_scale)

func _shatter_core(
	target: Node3D, fade_duration: float, fade_color: Color, fade_emission: Color,
	fade_emission_multiplier: float, shatter_offset: Vector3, shatter_radius: float,
	shatter_color: Color, shatter_emission: Color, shatter_emission_multiplier: float,
	shatter_amount: int, shatter_velocity: Vector2, shatter_damping: Vector2,
	shatter_scale: Vector2
) -> void:
	var fade_material_instance: ShaderMaterial = fade_material.duplicate()
	fade_material_instance.set_shader_parameter(&"color", fade_color)
	fade_material_instance.set_shader_parameter(&"emission", fade_emission)
	fade_material_instance.set_shader_parameter(&"emission_multiplier", fade_emission_multiplier)
	
	for mesh_instance: GeometryInstance3D in _get_geometry_instances(target):
		mesh_instance.material_overlay = fade_material_instance
	
	var fade_material_instance_tween: Tween = target.get_tree().create_tween()
	fade_material_instance_tween.tween_property(fade_material_instance,
		^"shader_parameter/progress", 1.0, fade_duration)
	await fade_material_instance_tween.finished
	
	for mesh_instance: GeometryInstance3D in _get_geometry_instances(target):
		mesh_instance.material_overlay = null
	
	target.call_deferred(&"hide")
	
	var shatter_particles_instance: GPUParticles3D = shatter_particles.instantiate()
	target.get_tree().root.add_child(shatter_particles_instance)
	shatter_particles_instance.global_position = target.global_position + shatter_offset
	shatter_particles_instance.amount = shatter_amount
	var process_material: ParticleProcessMaterial = shatter_particles_instance.process_material
	process_material.emission_sphere_radius = shatter_radius
	process_material.initial_velocity_min = shatter_velocity.x
	process_material.initial_velocity_max = shatter_velocity.y
	process_material.damping_min = shatter_damping.x
	process_material.damping_max = shatter_damping.y
	process_material.scale_min = shatter_scale.x
	process_material.scale_max = shatter_scale.y
	var pass_1: PrimitiveMesh = shatter_particles_instance.draw_pass_1
	var pass_1_material: StandardMaterial3D = pass_1.material
	pass_1_material.albedo_color = shatter_color
	pass_1_material.emission = shatter_emission
	pass_1_material.emission_energy_multiplier = shatter_emission_multiplier
	
	shatter_particles_instance.restart()
	await shatter_particles_instance.finished
	
	shatter_particles_instance.queue_free()
	
	on_finished.emit(target)

static func _get_geometry_instances(node: Node) -> Array[GeometryInstance3D]:
	var geometry_instances: Array[GeometryInstance3D] = []
	if node is GeometryInstance3D:
		geometry_instances.push_back(node)
	for descendant: Node in node.find_children("*"):
		geometry_instances.push_back(descendant)
	return geometry_instances

static func _get_average_component(vector: Vector3) -> float:
	return (vector.x + vector.y + vector.z) / 3.0
