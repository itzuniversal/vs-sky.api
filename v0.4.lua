local plrs = game:GetService("Players")
local rss = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")

local lp = plrs.LocalPlayer
local m = lp:GetMouse()

local targetted = nil
local active = false
local onced = false
local conn
local API = {}
local env = getgenv()

local setnet = rs.GrabEvents.SetNetworkOwner
local spawnt = rs.MenuToys.SpawnToyRemoteFunction
local delete = rs.MenuToys.DestroyToy
local r1 = rs.PlayerEvents.StickyPartEvent

env.vssky = env.vssky or {}
vssky.SpawnToyWarning = true

function API:GetVersion()
	return "v0.4"
end
function API:SetPerson(t, arg2)
	if t == 1 then
		vssky.SecondPersonToggle = false
		local camera = workspace.CurrentCamera
		lp.CameraMode = Enum.CameraMode.LockFirstPerson
		lp.CameraMaxZoomDistance = 0.5
		if lp.Character and camera then
			camera.CameraSubject = lp.Character
		end

	elseif t == 2 then
		if typeof(arg2) == "Instance" then
			targetted = arg2
			vssky.SecondPersonToggle = true
		else
			error("Only instances are supported!")
		end
	elseif t == 3 then
		vssky.SecondPersonToggle = false
		lp.CameraMode = Enum.CameraMode.Classic
		lp.CameraMaxZoomDistance = arg2 or 100
	end
end

conn = rss.PreRender:Connect(function()
	local camera = workspace.CurrentCamera
	if vssky.SecondPersonToggle == true then
		if onced == false then
			active = true
			onced = true
		end
	else
		active = false
	end
	if camera then
		if active then
			if camera.CameraType ~= Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Scriptable
				if targetted then
					pcall(function()
						camera.CFrame = targetted.CFrame
					end)
				end
			else
				if targetted then
					pcall(function()
						camera.CFrame = targetted.CFrame
					end)
				end
			end
			if targetted then
				if targetted.Parent:FindFirstChildOfClass("Humanoid") then
					for _, v in pairs(targetted.Parent:GetDescendants()) do
						if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
							v.Transparency = 1
						end
					end
				end
			end
		else
			if camera.CameraType ~= Enum.CameraType.Custom then
				camera.CameraType = Enum.CameraType.Custom
			end
			if onced == true then
				if targetted then
					for _, v in pairs(targetted.Parent:GetDescendants()) do
						if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
							v.Transparency = 0
						end
					end
				end
				if conn then
					conn:Disconnect()
					conn = nil
				end
			end
		end
	end
end)
function API:GetHitbox(model)
	if typeof(model) ~= "Instance" then error("function GetHitbox expects a toy, found " .. typeof(model)) end
	if model:FindFirstChild("Hitbox", true) then
		return model:FindFirstChild("Hitbox", true)
	elseif model:FindFirstChild("Hot", true) then
		return model:FindFirstChild("Hot", true)
	elseif model:FindFirstChild("Body", true) then
		return model:FindFirstChild("Body", true)
	elseif model:FindFirstChild("Stick", true) then
		return model:FindFirstChild("Stick", true)
	elseif model:FindFirstChild("SoundPart", true) then
		return model:FindFirstChild("SoundPart", true)
	elseif model:FindFirstChild("Head", true) then
		return model:FindFirstChild("Head", true)
	elseif model:FindFirstChild("Ball80", true) then
		return model:FindFirstChild("Ball80", true)
	elseif model:FindFirstChild("GrabbableHitbox", true) then
		return model:FindFirstChild("GrabbableHitbox", true)
	elseif model:FindFirstChild("HitboxPart", true) then
		return model:FindFirstChild("HitboxPart", true)
	else
		error("GetHitbox currently does not support this toy.")
	end
end
function API:GetInstanceFromPath(path : string)
	local names = path:split(".")
	if names[1] == "game" then table.remove(names, 1) end
	if #names == 0 then return nil end
	if names[1] == "workspace" then names[1] = "Workspace" end
	local success, inst = pcall(function()
		return game:GetService(names[1])
	end)
	if not success then 
		inst = game:FindFirstChild(names[1])
		if not inst then return nil end
	end 
	for i = 2, #names do
		inst = inst:FindFirstChild(names[i])
		if inst == nil then break end
	end
	return inst 
end
function API:LetGo(part : Instance)
	if typeof(part) ~= "Instance" then error("LetGo expects a part of a toy / toy, got "..typeof(part).." instead") end
	if part:IsA("BasePart") then
		rs.GrabEvents.DestroyGrabLine:FireServer(part,part.CFrame)
	elseif part:IsA("Model") then
		rs.GrabEvents.DestroyGrabLine:FireServer(API:GetHitbox(part),API:GetHitbox(part).CFrame)
	else
		error("LetGo expects a part of a toy / toy")
	end
end
function API:SearchForPlayer(name: string)
	if type(name) ~= "string" then error("SearchForPlayer expects a string / player name, got "..typeof(name).." instead") end
	name = name:lower()
	for _, player in pairs(plrs:GetPlayers()) do
		if player.DisplayName:lower():sub(1, #name) == name or player.Name:lower():sub(1, #name) == name then
			return player
		end
	end
	return nil
end
function API:DoIHaveACharacter(name : string)
	local p = API:SearchForPlayer(name)
	if p and p.Character then
		return p.Character
	end
	return nil
end
function API:SetNetworkOwner(instance : Instance)
	if typeof(instance) ~= "Instance" then error("SetNetworkOwner expects a part of a toy / toy, got "..typeof(instance).." instead") end
	local hitbox = nil
	if instance:IsA("Model") then
		hitbox = API:GetHitbox(instance)
	elseif instance.Parent:IsA("Model") then
		hitbox = instance
	end
	local conn5
	local flag
	setnet:FireServer(hitbox,hitbox.CFrame)
	conn5 = hitbox.ChildAdded:Connect(function(v)
		if v.Name == "PartOwner" then
			flag = v
		end
		conn5:Disconnect()
	end)
	while not flag do task.wait() end
	return true
end
function API:GetSpawnedInToysFolder(plr)
    if plr then
        return workspace:FindFirstChild(plr.Name.."SpawnedInToys")
    else
        return workspace:FindFirstChild(lp.Name.."SpawnedInToys")
    end
end
function API:SpawnToy(toyname,cf)
	if vssky.SpawnToyWarning == true then
		warn('SpawnToy is currently in beta and may not work as expected. You can disable this warning by running "vssky.SpawnToyWarning = false" at the start of your script.')
	end
	task.spawn(function()
		spawnt:InvokeServer(toyname,cf,vector.create(0,138,0))
	end)
	local conn
	local flag
	conn = API:GetSpawnedInToysFolder().ChildAdded:Connect(function(v)
		flag = v
		conn:Disconnect()
	end)
	while not flag do task.wait() end
	return flag
end
function API:DestroyToy(toy)
	delete:FireServer(toy)
end
function API:StickToy(toy,plr,part,offset)
	r1:FireServer(toy.StickyPart,part,offset)
end
function API:Ragdoll(t)
	local i = 0
	rss:BindToRenderStep("Ragdoll_12",Enum.RenderPriority.Character.Value,function()
		local char = lp.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				if i % 2 == 0 then
					rs.CharacterEvents.RagdollRemote:FireServer(hrp,1)
				else
					rs.CharacterEvents.RagdollRemote:FireServer(hrp,0)
				end
			end
		end
		i += 1
	end)
	task.wait(t)
	pcall(function()
		rss:UnbindFromRenderStep("Ragdoll_12")
	end)
end

return API





