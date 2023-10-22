extends Node3D

var hjtips = [ OpenXRInterface.HAND_JOINT_THUMB_TIP, OpenXRInterface.HAND_JOINT_INDEX_TIP, OpenXRInterface.HAND_JOINT_MIDDLE_TIP, 
			   OpenXRInterface.HAND_JOINT_RING_TIP, OpenXRInterface.HAND_JOINT_LITTLE_TIP ]

# Called when the node enters the scene tree for the first time.
func _ready():
	var axes3d = load("res://axes3d.tscn")
	var joints3D = $Joints3D
	var joints2D = $Joints2D
	for hand in range(2):
		var LRd = "L%d" if hand == 0 else "R%d"
		for j in range(OpenXRInterface.HAND_JOINT_MAX):
			var rj = axes3d.instantiate()
			rj.name = LRd % j
			rj.scale = Vector3(0.01, 0.01, 0.01)
			rj.get_node("SkinPad").visible = true
			rj.get_node("TipPad").visible = hjtips.has(j)
			joints3D.add_child(rj)

			var rjf = axes3d.instantiate()
			rjf.name = LRd % j
			rjf.scale = Vector3(0.01, 0.01, 0.01)
#			for arrow in rjf.get_children():
#				arrow.scale = Vector3(0.01, 0.01, 0.015)
			var p = flatlefthandjointsfromwrist[j]
			rjf.transform.origin = Vector3(p.x - 0.12, -p.z, p.y) if hand == 0 else Vector3(-p.x + 0.12, -p.z, p.y)
			joints2D.add_child(rjf)

	get_node("Joints3D/L0").transform.origin = Vector3(0,1.7,-0.2)


static func rotationtoalign(a, b):
	var axis = a.cross(b).normalized();
	if (axis.length_squared() != 0):
		var dot = a.dot(b)/(a.length()*b.length())
		dot = clamp(dot, -1.0, 1.0)
		var angle_rads = acos(dot)
		return Basis(axis, angle_rads)
	return Basis()

static func basisfrom(a, b):
	var vx = (b - a).normalized()
	var vy = vx.cross(-a.normalized())
	var vz = vx.cross(vy)
	return Basis(vx, vy, vz)


const jointvelocitydisplayfactor = 0.6

func arrowYbasis(v):
	var axisy = v
	var axisxL = Vector3(v.y, -v.x, 0.0) if abs(v.x) < abs(v.z) else Vector3(0.0, -v.x, v.z)
	var vlen = v.length()
	var axisx = axisxL * (vlen/axisxL.length())
	var axisz = axisx.cross(axisy)/(vlen if vlen != 0 else vlen)
	return Basis(axisx, axisy, axisz)
	
var Dt = 0
var ntimes = 0
func _process(delta):
	var xr_interface = XRServer.primary_interface
	if xr_interface != null:
		for hand in range(2):
			var wristtransform = Transform3D(Basis(xr_interface.get_hand_joint_rotation(hand, OpenXRInterface.HAND_JOINT_WRIST)), 
												   xr_interface.get_hand_joint_position(hand, OpenXRInterface.HAND_JOINT_WRIST))
			var LRd = "L%d" if hand == 0 else "R%d"
			for j in range(OpenXRInterface.HAND_JOINT_MAX):
				var jointradius = xr_interface.get_hand_joint_radius(hand, j)
				var handjointflags = xr_interface.get_hand_joint_flags(hand, j);

				var joint3d = $Joints3D.get_node(LRd % j)
				joint3d.get_node("InvalidMesh").visible = not (handjointflags & OpenXRInterface.HAND_JOINT_POSITION_VALID)
				joint3d.get_node("UntrackedMesh").visible = not (handjointflags & OpenXRInterface.HAND_JOINT_POSITION_TRACKED)
				var handjointtransform = Transform3D(Basis(xr_interface.get_hand_joint_rotation(hand, j)), xr_interface.get_hand_joint_position(hand, j))
				joint3d.transform = handjointtransform.scaled_local(Vector3(jointradius, jointradius, jointradius))

				var joint2d = $Joints2D.get_node(LRd % j)
				joint2d.get_node("InvalidMesh").visible = not (handjointflags & OpenXRInterface.HAND_JOINT_POSITION_VALID)
				joint2d.get_node("UntrackedMesh").visible = not (handjointflags & OpenXRInterface.HAND_JOINT_POSITION_TRACKED)
				joint2d.transform.basis = Basis(xr_interface.get_hand_joint_rotation(hand, j))*0.013

	Dt += delta
	if Dt > 5:
		Dt = 0
		ntimes += 1
		if ntimes <= 3:
			var headtransform = get_node("../XRCamera3D").transform	
			$Joints2D.transform = Transform3D(headtransform.basis, headtransform.origin - headtransform.basis.z*0.5 + Vector3(0,-0.2,0))

var flatlefthandjointsfromwrist = [
	Vector3(0.000861533, -0.0012695, -0.0477441), Vector3(0, 0, 0), Vector3(0.0315846, -0.0131271, -0.0329833), Vector3(0.0545926, -0.0174885, -0.0554602), 
	Vector3(0.0757424, -0.0190563, -0.0816979), Vector3(0.0965827, -0.0188126, -0.0947297), Vector3(0.0204946, -0.00802441, -0.0356591), 
	Vector3(0.0235117, -0.00730439, -0.0958373), Vector3(0.0364556, -0.00840877, -0.131404), Vector3(0.0444214, -0.00928009, -0.154306), 
	Vector3(0.0501041, -0.00590578, -0.175658), Vector3(0.00431204, -0.00690232, -0.0335003), Vector3(0.00172306, -0.00253896, -0.0954883), 
	Vector3(0.00447122, 0.00162174, -0.138053), Vector3(0.00599042, 0.00439228, -0.165375), Vector3(0.00627589, 0.0124663, -0.188982), 
	Vector3(-0.0149675, -0.00600582, -0.034718), Vector3(-0.0174363, -0.00651854, -0.0885469), Vector3(-0.0249593, 0.000487596, -0.126097), 
	Vector3(-0.0302005, 0.00494818, -0.151718), Vector3(-0.0342363, 0.0119404, -0.17468), Vector3(-0.0229605, -0.00940424, -0.0340171), 
	Vector3(-0.034996, -0.0136686, -0.0777668), Vector3(-0.0520341, -0.00539365, -0.101889), Vector3(-0.0647082, 0.000211, -0.116692), 
	Vector3(-0.0764616, 0.00869788, -0.133135)
]
