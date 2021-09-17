screen = {}

screen.x = 0
screen.y = 0
screen.z = 0
screen.rotation = 0
screen.zoom = 1
screen.zoomx = 1
screen.zoomy = 1

screen.update = true

local condor = {}
condor.const1 = math.sqrt(math.pow(SCREEN_WIDTH / 2, 2) + math.pow(SCREEN_HEIGHT / 2, 2))
condor.const2 = 180 + math.deg(math.atan(SCREEN_HEIGHT / SCREEN_WIDTH))

update_hooks['screen'] = function()

	if not screen.update then return end

	local zx = screen.zoomx * screen.zoom
	local zy = screen.zoomy * screen.zoom
	--
	local ts = SCREENMAN:GetTopScreen()
	ts:rotationz(screen.rotation)
	ts:zoomx(zx)
	ts:zoomy(zy)
	ts:x(SCREEN_CENTER_X + screen.x + (condor.const1 * zx *
	math.cos((screen.rotation + condor.const2) / 180 * math.pi)))
	ts:y(SCREEN_CENTER_Y + screen.y + (condor.const1 * zy *
	math.sin((screen.rotation + condor.const2) / 180 * math.pi)))
	ts:z( screen.z )

end