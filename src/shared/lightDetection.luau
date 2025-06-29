local module = {}

local Lighting = game.Lighting
local Run_Service = game:GetService("RunService")

local function SpotLight(x: Vector3, dir: Vector3, p: Vector3, ang: number, range: number) -- Cone
	ang = ang > 0 and ang or 1
	-- Expand the angle slightly to make detection more forgiving at edges
	local expandedAng = ang * 2 -- 40% larger detection area

	local A = CFrame.lookAt(x, x + dir) * CFrame.Angles(0, math.rad(expandedAng / 2), 0) * CFrame.new(0, 0, -range)
	local B = CFrame.lookAt(x, x + dir) * CFrame.Angles(0, math.rad(-expandedAng / 2), 0) * CFrame.new(0, 0, -range)

	local r = (A.Position - B.Position).Magnitude / 2
	local midPoint = A:Lerp(B, 0.5).Position
	local h = (midPoint - x).Magnitude

	local dist = (p - x):Dot(dir)
	local cone_radius = (dist / h) * r

	local dist2 = ((p - x) - dist * dir).Magnitude

	return (dist2 < cone_radius)
end

local function Side4D(p1, p2, p3, p4, p)
	local dp = (p1 + p2 + p3 + p4) / 4

	local up = (p2 - p1)
	local right = (p2 - p4)

	local dir = up:Cross(right)

	local dir2 = (dp - p)
	local dot = dir:Dot(dir2)

	return dot >= 1
end

local function SurfaceLight(p1, p2, p3, p4, p5, p6, p7, p8, p)
	local x, x1, x2, x3, x4, x5 =
		Side4D(p1, p2, p3, p4, p),
		Side4D(p1, p5, p6, p2, p),
		Side4D(p2, p6, p7, p3, p),
		Side4D(p3, p7, p8, p4, p),
		Side4D(p4, p8, p5, p1, p),
		Side4D(p5, p8, p7, p6, p)

	return x and x1 and x2 and x3 and x4 and x5
end

local function PointLight(x, p, r)
	return x:Dot(p) < r ^ 2
end

local function CheckObfuscated(t)
	for i, part: BasePart in t do
		if part.CastShadow == false then
			table.remove(t, i)
		end
		if part.Transparency >= 0.5 then
			table.remove(t, i)
		end
	end

	return t
end

local function GetVectorFromNormal(BasePart: BasePart | Attachment, Normal)
	local Dirs = {}

	if BasePart:IsA("BasePart") then
		Dirs = {
			[Enum.NormalId.Top] = BasePart.CFrame.UpVector,
			[Enum.NormalId.Bottom] = -BasePart.CFrame.UpVector,
			[Enum.NormalId.Right] = BasePart.CFrame.RightVector,
			[Enum.NormalId.Left] = -BasePart.CFrame.RightVector,
			[Enum.NormalId.Front] = BasePart.CFrame.LookVector,
			[Enum.NormalId.Back] = -BasePart.CFrame.LookVector,
		}
	else
		Dirs = {
			[Enum.NormalId.Top] = BasePart.WorldCFrame.UpVector,
			[Enum.NormalId.Bottom] = -BasePart.WorldCFrame.UpVector,
			[Enum.NormalId.Right] = BasePart.WorldCFrame.RightVector,
			[Enum.NormalId.Left] = -BasePart.WorldCFrame.RightVector,
			[Enum.NormalId.Front] = BasePart.WorldCFrame.LookVector,
			[Enum.NormalId.Back] = -BasePart.WorldCFrame.LookVector,
		}
	end

	return Dirs[Normal]
end

local function Side(v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, p: Vector3)
	local normal = (v2 - v1):Cross(v3 - v1)
	local dotV4 = normal:Dot(v4 - v1)
	local dotP = normal:Dot(p - v1)
	return math.sign(dotV4) == math.sign(dotP)
end

local function SurfaceLightAtt(v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, p: Vector3)
	return Side(v1, v2, v3, v4, p) and Side(v2, v3, v4, v1, p) and Side(v3, v4, v1, v2, p) and Side(v4, v1, v2, v3, p)
end

local OVP = OverlapParams.new()
OVP.FilterType = Enum.RaycastFilterType.Blacklist

local function CheckInSunlight(Point: Vector3)
	local sunlightDir = Lighting:GetSunDirection()
	local sp = Point + sunlightDir * 500
	local scf = CFrame.lookAt(sp, sp + sunlightDir)
	local ssize = Vector3.new(1, 1, 1000)

	local Det = workspace:GetPartBoundsInBox(CFrame.new(Point), Vector3.one / 10)[1]
	local FilterList = {}

	-- If we detected a part, filter it out
	if Det then
		table.insert(FilterList, Det)

		-- If the detected part belongs to a character, filter out the entire character
		local character = Det.Parent
		if character and character:FindFirstChild("Humanoid") then
			table.insert(FilterList, character)
		end
	end

	-- Filter out all player characters to prevent them from blocking sunlight
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character then
			table.insert(FilterList, player.Character)
		end
	end

	OVP.FilterDescendantsInstances = FilterList

	local Sunlight = if Lighting.GlobalShadows
		then CheckObfuscated(workspace:GetPartBoundsInBox(scf, ssize, OVP))
		else {}
	if #Sunlight == 0 and 18 > Lighting.ClockTime and Lighting.ClockTime > 8 then
		return true
	end

	return false
end

local AllLights: { Light } = {}

workspace.DescendantAdded:Connect(function(child: Light)
	if child:IsA("Light") then
		table.insert(AllLights, child)
	end
end)

for _, v: Light in workspace:GetDescendants() do
	if v:IsA("Light") then
		table.insert(AllLights, v)
	end
end

export type LightObject = {
	LightLevel: number,
	Lights: { Light },
	Sunlight: boolean,
	InLight: boolean,
}

function module:DetectLightAtObject(Object: BasePart)
	local self = {
		Part = Object,
	}

	function self:Update()
		local info = module:DetectLightAtPoint(Object.Position)
		return info
	end

	return self
end

function module:DetectLightAtPoint(Point: Vector3)
	local Detected = {
		Lights = {},
		Sunlight = false,
		InLight = false,
		LightLevel = 0,
	} :: LightObject

	local SunLight = CheckInSunlight(Point)

	if SunLight then
		Detected.Sunlight = true
		Detected.LightLevel = 15
	end

	for _, Light in AllLights do
		local LightParent = Light.Parent
		local LightPos = LightParent:IsA("BasePart") and LightParent.Position
			or (LightParent:IsA("Attachment") and LightParent.WorldPosition or nil)

		if not LightPos then
			continue
		end
		if not Light.Enabled then
			continue
		end

		local Brightness = Light.Brightness / 2
		local range = Light.Range

		local magnitude = (Point - LightPos).Magnitude
		local unit = (LightPos - Point).Unit

		local p = Point:Lerp(LightPos, 0.5)
		local cf = CFrame.lookAt(p, p + unit)
		local size = Vector3.new(1, 1, magnitude)

		local Det = workspace:GetPartBoundsInBox(CFrame.new(Point), Vector3.one / 10)[1]
		local FilterList = { Det, LightParent }

		-- Filter out all player characters to prevent them from blocking light
		for _, player in ipairs(game.Players:GetPlayers()) do
			if player.Character then
				table.insert(FilterList, player.Character)
			end
		end

		OVP.FilterDescendantsInstances = FilterList

		local obfuscated = if Light.Shadows then CheckObfuscated(workspace:GetPartBoundsInBox(cf, size, OVP)) else {}

		if #obfuscated > 0 then
			continue
		end

		if Light:IsA("PointLight") then
			local InRadius = PointLight(LightPos, Point, Light.Range)

			if InRadius then
				table.insert(Detected.Lights, Light)
				Detected.LightLevel =
					math.min((Detected.LightLevel + (range - magnitude) * (1 + Brightness / magnitude)) * 2, 15)
			end
		end

		if Light:IsA("SpotLight") then
			local dir = GetVectorFromNormal(LightParent, Light.Face)
			local InCone = SpotLight(LightPos, dir, Point, Light.Angle, range)

			-- Make range detection more generous (use 97.5% of range instead of 95%)
			if InCone and magnitude < range - range / 40 then
				table.insert(Detected.Lights, Light)
				Detected.LightLevel =
					math.min((Detected.LightLevel + (range - magnitude) * (1 + Brightness / magnitude)) * 2, 15)
			end
		end

		if Light:IsA("SurfaceLight") then
			local dir = LightParent.CFrame * CFrame.new(Vector3.FromNormalId(Light.Face))

			if LightParent:IsA("BasePart") then
				local ParentSize = LightParent.Size / 2

				local deg = Light.Angle
				local ang = math.rad(deg)

				local p1 = (dir * CFrame.new(-ParentSize.X, -ParentSize.Y, 0)).Position
				local p2 = (dir * CFrame.new(ParentSize.X, -ParentSize.Y, 0)).Position

				local p3 = (
					CFrame.new(p2, p2 + dir.LookVector)
					* CFrame.new(ang * 10, 0, -range)
					* CFrame.Angles(0, -ang / 2, 0)
				) * CFrame.new(0, -range * ang / 2 + math.max(0, deg - 45) / 30, 0)
				local p4 = (
					CFrame.new(p1, p1 + dir.LookVector)
					* CFrame.new(-ang * 10, 0, -range)
					* CFrame.Angles(0, ang / 2, 0)
				) * CFrame.new(0, -range * ang / 2 + math.max(0, deg - 45) / 30, 0)

				local p5 = (dir * CFrame.new(-ParentSize.X, ParentSize.Y, 0)).Position
				local p6 = (dir * CFrame.new(ParentSize.X, ParentSize.Y, 0)).Position

				local p7 = p3.Position * Vector3.new(1, -1, 1) + Vector3.new(0, p6.Y, 0)
				local p8 = p4.Position * Vector3.new(1, -1, 1) + Vector3.new(0, p5.Y, 0)

				local InsideCube = SurfaceLight(p1, p2, p3.Position, p4.Position, p5, p6, p7, p8, Point)

				if InsideCube and magnitude < range - range / 10 then
					table.insert(Detected.Lights, Light)
					Detected.LightLevel =
						math.min((Detected.LightLevel + (range - magnitude) * (1 + Brightness / magnitude)) * 2, 15)
				end
			else
				local dir = GetVectorFromNormal(LightParent, Light.Face)
				local InCone = SpotLight(LightPos, dir, Point, Light.Angle, range)

				if InCone and magnitude < range - range / 10 then
					table.insert(Detected.Lights, Light)
					Detected.LightLevel =
						math.min((Detected.LightLevel + (range - magnitude) * (1 + Brightness / magnitude)) * 2, 15)
				end
			end
		end
	end

	Detected.InLight = #Detected.Lights > 0 or Detected.Sunlight

	return Detected
end

return module
