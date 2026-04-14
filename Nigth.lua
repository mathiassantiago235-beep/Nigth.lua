

--// =========================
-- ORRXL4 HUB (ACTUALIZADO)
-- =========================

local noWalkConnection1
local noWalkConnection2
local lastPos

local fovConnection = nil
local oldFOV = nil

local TweenService = game:GetService("TweenService")
 
--// ORRXL4 HUB CONFIG SYSTEM

local HttpService = game:GetService("HttpService")

local FolderName = "Nigth Hub"
local FileName = FolderName.."/Nigthconfig.json"

local Config = {

    ["Super Jump"] = false,
    ["FOV"] = false,
    ["Lock UI"] = false,
    ["No Camera Collision"] = false,
    ["Auto Exit Duel"] = false,
    ["Speed Enabled"] = false,
    ["Speed Minimized"] = false,
    ["AutoPlay Minimized"] = false,
    ["Speed Customizer"] = false,
    ["Optimizer"] = false,
    ["Spin Body"] = false,
    ["Anti Ragdoll"] = false,
    ["Anti FPS Devourer"] = false,
    ["Anti Sentry"] = false,
    ["Infinite Jump"] = false,
    ["Xray Base"] = false,
    ["ESP Players"] = false,
    ["No Walk Animation"] = false,
    ["Auto Bat"] = false,
    ["Lock Target"] = false,
    ["Auto Medusa"] = false,
    ["Melee Aimbot"] = false,
    ["TP Down"] = false,
    ["Auto Play"] = false,
    ["Fast Steal"] = false,
    ["Drop Brainrot"] = false,
    ["No Player Collision"] = false,
    ["Fling"] = false,
    ["Instant Grab"] = false,

    ["LockButtonX"] = 0.5,
    ["LockButtonY"] = 0.5,
    ["LockButtonOffsetX"] = -70,
    ["LockButtonOffsetY"] = 0,

    ["Toggle Button X"] = 1,
    ["Toggle Button Y"] = 0,
    ["Toggle Button OffsetX"] = -70,
    ["Toggle Button OffsetY"] = 70,

    ["TP Down Button X"] = 0.5,
    ["TP Down Button Y"] = 0.7,
    ["TP Down Button OffsetX"] = -70,
    ["TP Down Button OffsetY"] = 0,

    ["Fling Button X"] = 0.5,
    ["Fling Button Y"] = 0.85,
    ["Fling Button OffsetX"] = -70,
    ["Fling Button OffsetY"] = 0,

    ["Walk GUI X"] = 0.5,
    ["Walk GUI Y"] = 0.15,
    ["Walk GUI OffsetX"] = -100,
    ["Walk GUI OffsetY"] = 0,

    ["Drop Button X"] = 0.5,
    ["Drop Button Y"] = 0.55,
    ["Drop Button OffsetX"] = -70,
    ["Drop Button OffsetY"] = 0,

    ["Spin Button X"] = 0.5,
    ["Spin Button Y"] = 0.75,
    ["Spin Button OffsetX"] = -70,
    ["Spin Button OffsetY"] = 0,

    ["AutoPlay GUI X"] = 0.5,
    ["AutoPlay GUI Y"] = 0.15,
    ["AutoPlay GUI OffsetX"] = -100,
    ["AutoPlay GUI OffsetY"] = 0,

    ["Speed GUI X"] = 0.5,
    ["Speed GUI Y"] = 0.2,
    ["Speed GUI OffsetX"] = -100,
    ["Speed GUI OffsetY"] = 0,

    ["Manual TP"] = 0.8,
    ["TP Button X"] = false,
    ["TP Button Y"] = 0.6,
    ["TP Button OffsetX"] = 0,
    ["TP Button OffsetY"] = 0,

    -- TEXTBOX VALUES
    ["Speed Value"] = 53,
    ["Steal Speed Value"] = 29,
    ["Jump Value"] = 60,

    ["AutoPlay Speed"] = 51,
    ["AutoPlay StealSpeed"] = 29,
    ["AutoPlay Cooldown"] = 0.1,

    ["Melee Range"] = 20,
    ["Spin Speed"] = 40,
    ["FOV Value"] = 90,

    -- AUTOPLAY POINTS
    ["AutoPlay Point1 X"] = 1,
    ["AutoPlay Point1 Z"] = 1,

    ["AutoPlay Point2 X"] = 1,
    ["AutoPlay Point2 Z"] = 1,

    ["AutoPlay Point3 X"] = 1,
    ["AutoPlay Point3 Z"] = 1,

    ["AutoPlay Point4 X"] = 1,
    ["AutoPlay Point4 Z"] = 1,

    ["AutoPlay Point5 X"] = 1,
    ["AutoPlay Point5 Z"] = 1
}

if not isfolder(FolderName) then
    makefolder(FolderName)
end

if not isfile(FileName) then
    writefile(FileName, HttpService:JSONEncode(Config))
end

local function LoadConfig()

    local success,data = pcall(readfile,FileName)

    if success then
        local decoded = HttpService:JSONDecode(data)

        for k,v in pairs(decoded) do
            Config[k] = v
        end
    end

end


function SaveConfig()
    writefile(FileName,HttpService:JSONEncode(Config))
end

LoadConfig()

task.spawn(function()
    task.wait(1)

    for text, enabled in pairs(Config) do
        if enabled then
            ApplyToggle(text, true)
        end
    end
end)

local playActive = false
local currentRoute = nil
local minimized = false

local Lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")

local optimizerEnabled = false
local savedLighting = {}
local optimized = {}
local optimizerConnection

-- 🔥 ANTI-LAG
local function applyAntiLag(instance)
    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Smoke") or instance:IsA("Fire") then
        
        if optimized[instance] == nil then
            optimized[instance] = instance.Enabled
            instance.Enabled = false
        end

    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        
        if optimized[instance] == nil then
            optimized[instance] = instance.Transparency
            instance.Transparency = 1
        end

    elseif instance:IsA("BasePart") then
        
        if not optimized[instance] then
            optimized[instance] = {
                instance.Material,
                instance.Reflectance,
                instance.CastShadow
            }
        end

        instance.Material = Enum.Material.Plastic
        instance.Reflectance = 0
        instance.CastShadow = false
    end
end

-- ✅ ACTIVAR (MISMA LÓGICA QUE TU SCRIPT)
function enableOptimizer()
    if optimizerEnabled then return end
    optimizerEnabled = true

    savedLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }

    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    -- Quitar efectos (igual que tu script)
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("BloomEffect") or child:IsA("BlurEffect") or child:IsA("SunRaysEffect") or child:IsA("ColorCorrectionEffect") then
            if optimized[child] == nil then
                optimized[child] = child.Enabled
                child.Enabled = false
            end
        end
    end

    -- Aplicar a TODO + lógica ULTRA (CastShadow forzado)
    for _, v in ipairs(workspace:GetDescendants()) do
        applyAntiLag(v)

        if v:IsA("BasePart") then
            v.CastShadow = false
        end
    end

    -- Tiempo real
    optimizerConnection = workspace.DescendantAdded:Connect(function(desc)
        if optimizerEnabled then
            applyAntiLag(desc)

            if desc:IsA("BasePart") then
                desc.CastShadow = false
            end
        end
    end)
end

-- ❌ DESACTIVAR
function disableOptimizer()
    if not optimizerEnabled then return end
    optimizerEnabled = false

    if optimizerConnection then
        optimizerConnection:Disconnect()
        optimizerConnection = nil
    end

    for k,v in pairs(savedLighting) do
        Lighting[k] = v
    end

    for obj,val in pairs(optimized) do
        if obj and obj.Parent then
            if typeof(val) == "table" then
                obj.Material = val[1]
                obj.Reflectance = val[2]
                obj.CastShadow = val[3]

            elseif typeof(val) == "boolean" then
                pcall(function() obj.Enabled = val end)

            elseif typeof(val) == "number" then
                pcall(function() obj.Transparency = val end)
            end
        end
    end

    optimized = {}
end

--// XRAY BASE

local baseOriginalTransparencies = {}
local plotConnections = {}
local xrayConnection

local function applyXray(plot)
    if baseOriginalTransparencies[plot] then return end

    baseOriginalTransparencies[plot] = {}

    local oldHL = plot:FindFirstChild("BaseXRayHighlight")
    if oldHL then
        oldHL:Destroy()
    end

    for _, part in ipairs(plot:GetDescendants()) do
        if part:IsA("BasePart") then
            
            local oldPartHL = part:FindFirstChild("BaseXRayHighlight")
            if oldPartHL then
                oldPartHL:Destroy()
            end

            if part.Transparency < 0.6 then
                baseOriginalTransparencies[plot][part] = part.Transparency
                part.Transparency = 0.68
            end
        end
    end

    plotConnections[plot] = plot.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            if desc.Transparency < 0.6 then
                baseOriginalTransparencies[plot][desc] = desc.Transparency
                desc.Transparency = 0.68
            end
        end
    end)
end

function toggleESPBases(enable)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end

    if not enable then
        for _, conn in pairs(plotConnections) do
            conn:Disconnect()
        end
        plotConnections = {}

        if xrayConnection then
            xrayConnection:Disconnect()
            xrayConnection = nil
        end

        for plot, parts in pairs(baseOriginalTransparencies) do
            for part, original in pairs(parts) do
                if part and part.Parent then
                    part.Transparency = original
                end
            end
        end

        baseOriginalTransparencies = {}
        return
    end

    for _, plot in ipairs(plots:GetChildren()) do
        applyXray(plot)
    end

    xrayConnection = plots.ChildAdded:Connect(function(newPlot)
        task.wait(0.2)
        applyXray(newPlot)
    end)
end

--// ESP PLAYERS

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local espConnections = {}
local espEnabled = false

local function createESP(plr)
	if plr == lp then return end
	if not plr.Character then return end
	if plr.Character:FindFirstChild("ESP_BLUE") then return end

	local char = plr.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not (hrp and head) then return end

--------------------------------------------------
-- HIGHLIGHT AZUL EQUILIBRADO
--------------------------------------------------

local highlight = Instance.new("Highlight")
highlight.Name = "ESP_BLUE"

highlight.FillColor = Color3.fromRGB(0, 110, 220)
highlight.OutlineColor = Color3.fromRGB(0, 110, 220)

highlight.FillTransparency = 0.4
highlight.OutlineTransparency = 0.15

highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

highlight.Parent = char
end

local function removeESP(plr)
	if not plr.Character then return end

	local char = plr.Character

	local highlight = char:FindFirstChild("ESP_BLUE")
	if highlight then highlight:Destroy() end
end

function toggleESPPlayers(enable)
	espEnabled = enable

	if enable then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp then
				if plr.Character then
					createESP(plr)
				end

				local conn = plr.CharacterAdded:Connect(function()
					task.wait(0.2)
					if espEnabled then
						createESP(plr)
					end
				end)

				table.insert(espConnections, conn)
			end
		end

		local playerAddedConn = Players.PlayerAdded:Connect(function(plr)
			if plr == lp then return end

			local charAddedConn = plr.CharacterAdded:Connect(function()
				task.wait(0.2)
				if espEnabled then
					createESP(plr)
				end
			end)

			table.insert(espConnections, charAddedConn)
		end)

		table.insert(espConnections, playerAddedConn)

	else
		for _, plr in ipairs(Players:GetPlayers()) do
			removeESP(plr)
		end

		for _, conn in ipairs(espConnections) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end

		espConnections = {}
	end
end

-- =========================
-- MANUAL TP SISTEMA
-- =========================

ManualTPEnabled = false

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local char
local hrp
local humanoid

local tpGui
local debounce = false

local function setupCharacter(c)
    char = c
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

-- SPAWN DETECTION

local PUNTOS_ACTIVACION = {
    Vector3.new(-465.7, -7.1, 4.8),
    Vector3.new(-465.9, -6.9, 113.2)
}

local DISTANCIA_ACTIVACION = 5

local TP_COORDS = {

    [1] = {
        Vector3.new(-471,-8,91),
        Vector3.new(-486,-5,95)
    },

    [2] = {
        Vector3.new(-463,-8,40),
        Vector3.new(-488,-6,19)
    }

}

local coords = nil
local detectedSpawn = nil

task.spawn(function()

    while true do
        task.wait(0.5)

        if detectedSpawn then continue end
        if not hrp then continue end

        local pos = hrp.Position

        for i,punto in ipairs(PUNTOS_ACTIVACION) do

            local dist = (pos - punto).Magnitude

            if dist < DISTANCIA_ACTIVACION then
                detectedSpawn = i
                coords = TP_COORDS[i]
                break
            end

        end

    end

end)

-- =========================
-- TP FUNCTION
-- =========================

local function doTP()

    if not coords then return end
    if not hrp then return end

    for _,v in ipairs(coords) do

        hrp.CFrame = CFrame.new(v)
        task.wait(0.1)

    end

end

-- TELEPORT

local function teleport(pos)

    if not hrp then return end

    local cf = CFrame.new(pos)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = cf

    local lowerTorso = char:FindFirstChild("LowerTorso")
    if lowerTorso then
        lowerTorso.CFrame = cf
    end

    if camera then
        camera.CFrame = cf
    end

end

local function doTP()

    if not coords then return end

    teleport(coords[1])
    task.wait(0.15)
    teleport(coords[2])

end

-- BOTON

function CreateTPButton()

    if tpGui then return end

    tpGui = Instance.new("ScreenGui")
    tpGui.Name = "TPButtonGui"
    tpGui.ResetOnSpawn = false
    tpGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,120,0,40)

    button.Position = UDim2.new(
        Config["TP Button X"],
        Config["TP Button OffsetX"],
        Config["TP Button Y"],
        Config["TP Button OffsetY"]
    )

    button.Text = "TP"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(25,25,25)
    button.Parent = tpGui

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,8)

    -- MISMO DRAG QUE TUS OTROS BOTONES
    button.Active = true
    button.Draggable = not UILocked

    -- GUARDAR POSICIÓN
    button.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            local pos = button.Position

            Config["TP Button X"] = pos.X.Scale
            Config["TP Button OffsetX"] = pos.X.Offset
            Config["TP Button Y"] = pos.Y.Scale
            Config["TP Button OffsetY"] = pos.Y.Offset

            SaveConfig()

        end
    end)

    -- CLICK TP
    button.MouseButton1Click:Connect(function()

        if not ManualTPEnabled then return end
        if debounce then return end

        debounce = true
        button.BackgroundColor3 = Color3.fromRGB(200,0,0)

        doTP()

        task.wait(0.2)

        button.BackgroundColor3 = Color3.fromRGB(25,25,25)
        debounce = false

    end)

end

function RemoveTPButton()

    if tpGui then
        tpGui:Destroy()
        tpGui = nil
    end

end

-- FLING SISTEMA

local flingGui
local flingActive = false
local flingConnection

local function startFling()

    if flingConnection then return end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    flingConnection = RunService.Heartbeat:Connect(function()

        if not flingActive then return end

        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if character and root then

            local vel = root.Velocity
            local movel = 0.1

            root.Velocity = vel * 10000 + Vector3.new(0,10000,0)

            RunService.RenderStepped:Wait()

            if root then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()

            if root then
                root.Velocity = vel + Vector3.new(0,movel,0)
            end

        end

    end)

end

local function stopFling()
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
end

local function setupFlingTouch()

    local char = lp.Character
    if not char then return end

    local root = char:WaitForChild("HumanoidRootPart")

    root.Touched:Connect(function(hit)

        local otherChar = hit.Parent
        local otherPlayer = game.Players:GetPlayerFromCharacter(otherChar)

        if otherPlayer and otherPlayer ~= lp then

            local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                otherRoot.AssemblyLinearVelocity = Vector3.new(0,200,0)
            end

        end

    end)

end

--// =========================
-- ANTI FPS DEVOURER SISTEMA
-- =========================

local ANTI_FPS_DEVOURER = {
    enabled = false,
    connections = {},
    hiddenAccessories = {}
}

-- Ocultar accesorio específico
local function removeAccessory(accessory)
    if not ANTI_FPS_DEVOURER.hiddenAccessories[accessory] then
        ANTI_FPS_DEVOURER.hiddenAccessories[accessory] = accessory.Parent
        accessory.Parent = nil
    end
end

-- Escanear modelo completo
local function scanModel(model)
    for _, obj in ipairs(model:GetDescendants()) do
if obj:IsA("Accessory")
or obj:IsA("Shirt")
or obj:IsA("Pants")
or obj:IsA("ShirtGraphic") then
    removeAccessory(obj)
end
    end
end

function enableAntiFPSDevourer()
    if ANTI_FPS_DEVOURER.enabled then return end
    ANTI_FPS_DEVOURER.enabled = true

    -- Escanea cualquier accesorio o ropa 3d de modelos y usuarios 
    for _, obj in ipairs(workspace:GetDescendants()) do
if obj:IsA("Accessory")
or obj:IsA("Shirt")
or obj:IsA("Pants")
or obj:IsA("ShirtGraphic") then
    removeAccessory(obj)
end
    end

    -- Detectar nuevos objetos 
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if ANTI_FPS_DEVOURER.enabled then
if obj:IsA("Accessory")
or obj:IsA("Shirt")
or obj:IsA("Pants")
or obj:IsA("ShirtGraphic") then
    removeAccessory(obj)
end
        end
    end)

    table.insert(ANTI_FPS_DEVOURER.connectio
