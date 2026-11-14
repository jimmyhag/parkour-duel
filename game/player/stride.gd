class_name Stride
extends RefCounted
## The stride of the clips of the locomotion (Walking, Running, Sprint), from measures of
## their bones (docs/specs/locomotion-blend.md): where in each clip the left foot touches
## the ground, the phase 0 of its stride, so that the clips blended are at the same phase;
## how many strides a second keep the feet up with the ground; and at which phase the run
## resumes after another clip, the one whose pose is nearest the pose shown. Only measures
## are given to it: it reads no file.

## How close to its lowest a bone of the foot is when the foot is on the ground, in m.
const ON_THE_GROUND: float = 0.01


## The phase (0 to 1) at which the foot whose bones are at the heights `feet` touches the
## ground: each array the heights of one bone at evenly spaced instants of one cycle, the
## first instant at phase 0, the cycle looping. The foot is on the ground at an instant
## when one of its bones is within ON_THE_GROUND of its lowest; the phase is the first
## instant of its longest time on the ground.
static func touchdown(feet: Array[PackedFloat32Array]) -> float:
	var samples: int = feet[0].size()
	var grounded: Array[bool] = []
	for sample: int in samples:
		grounded.append(false)
	for heights: PackedFloat32Array in feet:
		var lowest: float = INF
		for height: float in heights:
			lowest = minf(lowest, height)
		for sample: int in samples:
			grounded[sample] = grounded[sample] or heights[sample] <= lowest + ON_THE_GROUND
	var first: int = 0
	var longest: int = 0
	for sample: int in samples:
		if not grounded[sample] or grounded[sample - 1 if sample > 0 else samples - 1]:
			continue
		var length: int = 0
		while length < samples and grounded[(sample + length) % samples]:
			length += 1
		if length > longest:
			longest = length
			first = sample
	return float(first) / samples


## How many cycles a second the clips of the locomotion play, their weights `weights`,
## the speeds of their strides `speeds` (m/s) and the lengths of their cycles `lengths` (s),
## at the pace `pace` (the ground speed over the speed of their strides, weighted): every
## clip plays one cycle in the same time, at the same phase, and the foot on the ground of
## the blend goes back as fast as the ground passes. None when nothing moves.
static func cycles_per_second(
	pace: float,
	weights: PackedFloat32Array,
	speeds: PackedFloat32Array,
	lengths: PackedFloat32Array,
) -> float:
	var speed: float = 0.0
	var distance: float = 0.0
	for clip: int in weights.size():
		speed += weights[clip] * speeds[clip]
		distance += weights[clip] * speeds[clip] * lengths[clip]
	if distance <= 0.0:
		return 0.0
	return pace * speed / distance


## The phase (0 to 1) of the stride whose pose is nearest `pose`: `cycle` gives the pose at
## evenly spaced phases from 0, a pose being how far the left foot is ahead of the right
## one and how much higher. Each of the two is measured against how far it goes in the
## cycle.
static func nearest_phase(pose: Vector2, cycle: PackedVector2Array) -> float:
	var reach: Vector2 = Vector2.ZERO
	for place: Vector2 in cycle:
		reach = Vector2(maxf(reach.x, absf(place.x)), maxf(reach.y, absf(place.y)))
	var scale: Vector2 = Vector2(
		1.0 / reach.x if reach.x > 0.0 else 1.0, 1.0 / reach.y if reach.y > 0.0 else 1.0
	)
	var nearest: int = 0
	var shortest: float = INF
	for phase: int in cycle.size():
		var distance: float = ((cycle[phase] - pose) * scale).length_squared()
		if distance < shortest:
			shortest = distance
			nearest = phase
	return float(nearest) / cycle.size()
