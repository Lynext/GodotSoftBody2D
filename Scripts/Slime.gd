extends Node2D

var points = 12
var radius = 50.0
var circumfrenceMultiplier = 1.0

var area = radius * radius * PI
var circumfrence = radius * 2.0 * PI * circumfrenceMultiplier
var length = circumfrence * 1.15 / float(points)
var iterations = 10

var blob = []
var blobOld = []
var accumulatedDisplacements = {}
var normals = []
var center = Vector2(0.0, 0.0)
var gravity = Vector2(0.0, 30.0)
export(float) var splineLength = 12.0
export(Curve2D) var curve

func verletIntegrate(i, delta):
	var temp = Vector2(blob[i])
	blob[i] = (blob[i] + (blob[i] - blobOld[i]))
	blobOld[i] = temp

func setDistance(currentPoint, anchor, distance):
	var toAnchor = currentPoint - anchor
	toAnchor = toAnchor.normalized() * distance
	return toAnchor + anchor

func _ready():
	resetBlob()

func findCentroid():
	var x = 0.0
	var y = 0.0
	for i in range(points): 
		x += blob[i].x
		y += blob[i].y
	var cent = Vector2(0.0, 0.0)
	cent.x = x / float(points)
	cent.y = y / float(points)
	return cent

func getPoint(i):
	var pointCount = curve.get_point_count()
	i = wrapi(i, 0, pointCount - 1)
	return curve.get_point_position(i)

func getSpline(i):
	var lastPoint = getPoint(i - 1)
	var nextPoint = getPoint(i + 1)
	var spline = lastPoint.direction_to(nextPoint) * splineLength
	return spline

func updateSprite ():
	var polBlob = blob + [blob[0]]
	
	curve.clear_points()
	for i in range(points + 1):
		curve.add_point(polBlob[i])
	
	var point_count = curve.get_point_count()
	for i in point_count:
		var spline = getSpline(i)
		curve.set_point_in(i, -spline)
		curve.set_point_out(i, spline)


func getCurArea ():
	var area = 0.0
	var j = points - 1 
	for i in range(points):
		area += (blob[j].x + blob[i].x) * (blob[j].y - blob[i].y)
		j = i
	return abs(area / 2.0)

func _draw():
#	for i in range(points):
#		draw_line(normals[i][0], normals[i][1], Color(255, 0, 0), 3)
	
	var bakedPoints = Array(curve.get_baked_points())
	
	var drawPoints = bakedPoints + []
	
	if Geometry.triangulate_polygon(drawPoints).empty():
		drawPoints = Geometry.convex_hull_2d(bakedPoints)
	
	#draw_polyline(drawPoints, Color.black, 2.0, true)
	
	draw_polygon(drawPoints, [Color(0.0,1.0,0.0,1.0)])
	
#	for i in range (points):
#		draw_line(blob[i], blob[(i + 1) % points], Color.blue, 3)

func _process (delta):
	for i in range(points):
		verletIntegrate(i, delta)
		blob[i] += gravity * delta
	
	for iterate in range(iterations):
		for i in range(points):
			var segment = blob[i]
			var nextIndex = i + 1
			if i == points - 1:
				nextIndex = 0
			var nextSegment = blob[nextIndex]
			var toNext = segment - nextSegment
			if toNext.length() > length:
				toNext = toNext.normalized() * length
				var offset = (segment - nextSegment) - toNext
				accumulatedDisplacements[(i * 3)] -= offset.x / 2.0
				accumulatedDisplacements[(i * 3) + 1] -= offset.y / 2.0
				accumulatedDisplacements[(i * 3) + 2] += 1.0
				accumulatedDisplacements[(nextIndex * 3)] += offset.x / 2.0
				accumulatedDisplacements[(nextIndex * 3) + 1] += offset.y / 2.0
				accumulatedDisplacements[(nextIndex * 3) + 2] += 1.0
			
		var deltaArea = 0.0
		var curArea = getCurArea()
		if curArea < area * 2.0:
			deltaArea = area - curArea
		var dilationDistance = deltaArea / circumfrence
	
		for i in range(points):
			var prevIndex = i - 1
			if i == 0:
				prevIndex = points - 1
			var nextIndex = i + 1
			if i == points - 1:
				nextIndex = 0
			var normal = blob[nextIndex] - blob[prevIndex]
			normal = Vars.getVectorByLA(1, rad2deg(normal.angle()) - 90.0)
			normals[i][0] = blob[i]
			normals[i][1] = blob[i] + (normal * 200.0)
			accumulatedDisplacements[(i * 3)] += normal.x * dilationDistance
			accumulatedDisplacements[(i * 3) + 1] += normal.y * dilationDistance
			accumulatedDisplacements[(i * 3) + 2] += 1.0
	
		for i in range (points):
			if (accumulatedDisplacements[(i * 3) + 2] > 0):
				blob[i] += Vector2(accumulatedDisplacements[(i * 3)], accumulatedDisplacements[(i * 3) + 1]) / accumulatedDisplacements[(i * 3) + 2]
	
		for i in range (points * 3): 
			accumulatedDisplacements[i] = 0
	
		for i in range(points):
			if Input.is_action_pressed('leftClick') && (blob[i] - get_global_mouse_position()).length() < 40.0:
				blob[i] = setDistance(blob[i], get_global_mouse_position(), 40.0);
			if (blob[i] - Vector2(0.0, 0.0)).length() > 175.0:
				blob[i] = setDistance(blob[i], Vector2(0.0, 0.0), 175.0)
	
	#print(curArea)
	updateSprite()
	update()

func resetBlob ():
	blob = []
	blobOld = []
	normals = []
	accumulatedDisplacements = {}
	for i in range(points):
		var delta = Vars.getVectorByLA(radius, (360.0 / float(points)) * i)
		blob.append(position + delta)
		blobOld.append(position + delta)
		normals.append([])
		normals[i].append(position + delta)
		normals[i].append(position + delta * 1.5)
	for i in range (points * 3): 
		accumulatedDisplacements[i] = 0.0
	updateSprite()
	update()


# Circumfrence Slider
func _on_HSlider_value_changed(value):
	circumfrenceMultiplier = value
	circumfrence = radius * 2.0 * PI * circumfrenceMultiplier
	length = circumfrence * 1.15 / float(points)

# Gravity Slider
func _on_HSlider2_value_changed(value):
	gravity.y = value

# Area Slider
func _on_HSlider3_value_changed(value):
	radius = value
	area = radius * radius * PI
	circumfrence = radius * 2.0 * PI * circumfrenceMultiplier
	length = circumfrence * 1.15 / float(points)
	print(area)

# Points Slider
func _on_HSlider4_value_changed(value):
	points = value
	area = radius * radius * PI
	circumfrence = radius * 2.0 * PI * circumfrenceMultiplier
	length = circumfrence * 1.15 / float(points)
	print(points)
	
	resetBlob()
