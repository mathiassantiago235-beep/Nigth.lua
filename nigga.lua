repeat task.wait() until game:IsLoaded()
local Players,RunService,UIS,TS,Lighting,HS = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService")
local LP = Players.LocalPlayer

local NS,CS,DAS,DAD = 60,30,150,0.2

local speedMode,antiRagdollEnabled,infJumpEnabled = false,false,false
local medusaCounterEnabled,brainrotLeftEnabled,brainrotRightEnabled = false,false,false
local tpMode = "Manuel"
local medusaMode = false
local unwalkEnabled = false
local unwalkAnimations = {}
local floatEnabled = false
local floatHeight = 9.5
local floatJumping = false
local lastHealth,medusaDebounce,medusaLastUsed,dropActive = 100,false,0,false
local stretchRezEnabled = false
local autoLeftEnabled,autoRightEnabled = false,false
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local medusaConns = {}
local autoBatEnabled = false
local autoBatSetVisual = nil
local _anyKeyListening = false

local KB = {
	DropBrainrot={kb=Enum.KeyCode.X,gp=nil},
	AutoLeft    ={kb=Enum.KeyCode.Z,gp=nil},
	AutoRight   ={kb=Enum.KeyCode.C,gp=nil},
	AutoBat     ={kb=Enum.KeyCode.E,gp=nil},
	TPLeft      ={kb=Enum.KeyCode.V,gp=nil},
	TPRight     ={kb=Enum.KeyCode.B,gp=nil},
	TPFloor     ={kb=Enum.KeyCode.F,gp=nil},
	GuiHide     ={kb=Enum.KeyCode.LeftControl,gp=nil},
	Float       ={kb=Enum.KeyCode.J,gp=nil},
	SpeedToggle ={kb=Enum.KeyCode.Q,gp=nil},
}

local AP_L1,AP_L2 = Vector3.new(-476.48,-6.28,92.73),Vector3.new(-483.12,-4.95,94.80)
local AP_L_FACE = Vector3.new(-482.25,-4.96,92.09)
local AP_R1,AP_R2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local AP_R_FACE = Vector3.new(-482.06,-6.93,35.47)
local BR_L1,BR_L2,BR_L3 = Vector3.new(-469,-6,78),Vector3.new(-471,-6,96),Vector3.new(-484,-4,99)
local BR_R1,BR_R2,BR_R3 = Vector3.new(-468,-6,41),Vector3.new(-473,-6,24),Vector3.new(-484,-4,20)
local SEMI_L1,SEMI_L2,SEMI_L3 = Vector3.new(-474.9,-7.0,94.9),Vector3.new(-481.7,-5.1,97.7),Vector3.new(-465.7,-7.0,83.2)
local SEMI_R1,SEMI_R2,SEMI_R3 = Vector3.new(-474.9,-7.0,24.1),Vector3.new(-482.64,-5.20,21.06),Vector3.new(-466.78,-7.10,40.83)

local Steal = {
	AutoStealEnabled=false,StealRadius=20,StealDuration=0.25,
	Data={},plotCache={},plotCacheTime={},cachedPrompts={},promptCacheTime=0,
}
local isStealing=false
local stealStartTime=nil
local lastStealTick=0
local Conns = {autoSteal=nil,antiRag=nil,float=nil,anchor={},progress=nil}
local PLOT_CACHE_DURATION = 2
local PROMPT_CACHE_REFRESH = 0.15
local STEAL_COOLDOWN = 0.1
local MEDUSA_COOLDOWN = 25

local progressRadLbl,progressFill,progressPct
local setFloat,modeValLbl

local function resetProgressBar()
	progressPct.Text="0%";progressFill.Size=UDim2.new(0,0,1,0)
end

local function isMyPlotByName(plotName)
	local ct = tick()
	if Steal.plotCache[plotName] and (ct-(Steal.plotCacheTime[plotName] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[plotName] end
	local plots = workspace:FindFirstChild("Plots")
	if not plots then Steal.plotCache[plotName]=false;Steal.plotCacheTime[plotName]=ct;return false end
	local plot = plots:FindFirstChild(plotName)
	if not plot then Steal.plotCache[plotName]=false;Steal.plotCacheTime[plotName]=ct;return false end
	local sign = plot:FindFirstChild("PlotSign")
	if sign then
		local yb = sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then
			local r = yb.Enabled==true;Steal.plotCache[plotName]=r;Steal.plotCacheTime[plotName]=ct;return r
		end
	end
	Steal.plotCache[plotName]=false;Steal.plotCacheTime[plotName]=ct;return false
end

local function findNearestPrompt()
	local char = LP.Character;if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart");if not root then return nil end
	local ct = tick()
	if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then
		local np,nd = nil,math.huge
		for _,data in ipairs(Steal.cachedPrompts) do
			if data.spawn then
				local dist = (data.spawn.Position-root.Position).Magnitude
				if dist<=Steal.StealRadius and dist<nd then np=data.prompt;nd=dist end
			end
		end
		if np then return np end
	end
	Steal.cachedPrompts={};Steal.promptCacheTime=ct
	local plots = workspace:FindFirstChild("Plots");if not plots then return nil end
	local np,nd = nil,math.huge
	for _,plot in ipairs(plots:GetChildren()) do
		if isMyPlotByName(plot.Name) then continue end
		local pods = plot:FindFirstChild("AnimalPodiums");if not pods then continue end
		for _,pod in ipairs(pods:GetChildren()) do
			pcall(function()
				local base = pod:FindFirstChild("Base");local sp = base and base:FindFirstChild("Spawn")
				if sp then
					local att = sp:FindFirstChild("PromptAttachment")
					if att then
						for _,child in ipairs(att:GetChildren()) do
							if child:IsA("ProximityPrompt") then
								local dist = (sp.Position-root.Position).Magnitude
								table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp,name=pod.Name})
								if dist<=Steal.StealRadius and dist<nd then np=child;nd=dist end
								break
							end
						end
					end
				end
			end)
		end
	end
	return np
end

-- ===== VYSE-STYLE INSTA STEAL =====
local function executeSteal(prompt)
	local ct = tick()
	if ct-lastStealTick<STEAL_COOLDOWN then return end
	if isStealing then return end
	if not Steal.Data[prompt] then
		Steal.Data[prompt]={hold={},trigger={},ready=true}
		pcall(function()
			if getconnections then
				for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
				for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
			else Steal.Data[prompt].useFallback=true end
		end)
	end
	local data = Steal.Data[prompt];if not data.ready then return end
	data.ready=false;isStealing=true;stealStartTime=ct;lastStealTick=ct
	if Conns.progress then Conns.progress:Disconnect() end
	Conns.progress = RunService.Heartbeat:Connect(function()
		if not isStealing then Conns.progress:Disconnect();return end
		local prog = math.clamp((tick()-stealStartTime)/Steal.StealDuration,0,1)
		progressFill.Size=UDim2.new(prog,0,1,0);progressPct.Text=math.floor(prog*100).."%"
	end)
	task.spawn(function()
		local ok = false
		pcall(function()
			if not data.useFallback then
				for _,fn in ipairs(data.hold) do task.spawn(fn) end
				task.wait(Steal.StealDuration)
				for _,fn in ipairs(data.trigger) do task.spawn(fn) end
				ok=true
			end
		end)
		if not ok and fireproximityprompt then pcall(function() fireproximityprompt(prompt);ok=true end) end
		if not ok then pcall(function() prompt:InputHoldBegin();task.wait(Steal.StealDuration);prompt:InputHoldEnd() end) end
		task.wait(Steal.StealDuration*0.3)
		if Conns.progress then Conns.progress:Disconnect() end
		resetProgressBar();task.wait(0.05);data.ready=true;isStealing=false
	end)
end

local function startAutoSteal()
	if Conns.autoSteal then return end
	Conns.autoSteal = RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or isStealing then return end
		local p = findNearestPrompt();if p then executeSteal(p) end
	end)
end

local function stopAutoSteal()
	if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
	isStealing=false;lastStealTick=0
	Steal.plotCache={};Steal.plotCacheTime={};Steal.cachedPrompts={};resetProgressBar()
end
-- ===== END INSTA STEAL =====

RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	local md=hum.MoveDirection
	local spd=speedMode and CS or NS
	if md.Magnitude>0 and not autoLeftEnabled and not autoRightEnabled then
		hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,hrp.AssemblyLinearVelocity.Y,md.Z*spd)
	end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z).Magnitude) end
end)

local alConn,arConn = nil,nil
local alPhase,arPhase = 1,1

local function stopAutoLeft()
	if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
	local char = LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
end

local function stopAutoRight()
	if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
	local char = LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
end

local function startAutoLeft()
	if alConn then alConn:Disconnect() end;alPhase=1
	alConn=RunService.Heartbeat:Connect(function()
		if not autoLeftEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		local spd=NS
		if alPhase==1 then
			local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				alPhase=2
				local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd);return
			end
			local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif alPhase==2 then
			local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
				alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end
				if (AP_L_FACE-hrp.Position).Magnitude>0.01 then hrp.CFrame=CFrame.new(hrp.Position,Vector3.new(AP_L_FACE.X,hrp.Position.Y,AP_L_FACE.Z)) end
				return
			end
			local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end

local function startAutoRight()
	if arConn then arConn:Disconnect() end;arPhase=1
	arConn=RunService.Heartbeat:Connect(function()
		if not autoRightEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		local spd=NS
		if arPhase==1 then
			local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				arPhase=2
				local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd);return
			end
			local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif arPhase==2 then
			local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
				arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end
				if (AP_R_FACE-hrp.Position).Magnitude>0.01 then hrp.CFrame=CFrame.new(hrp.Position,Vector3.new(AP_R_FACE.X,hrp.Position.Y,AP_R_FACE.Z)) end
				return
			end
			local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end

local function setupSpeedIndicator(char)
	local head = char:WaitForChild("Head",5);if not head then return end
	local bb = Instance.new("BillboardGui",head)
	bb.Size=UDim2.new(0,140,0,25);bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true
	speedLabel = Instance.new("TextLabel",bb)
	speedLabel.Size=UDim2.new(1,0,1,0);speedLabel.BackgroundTransparency=1
	speedLabel.Text="Speed: 0";speedLabel.TextColor3=Color3.fromRGB(180,20,40)
	speedLabel.Font=Enum.Font.GothamBold;speedLabel.TextScaled=true
	speedLabel.TextStrokeTransparency=0;speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
end

local function startAntiRagdoll()
	if Conns.antiRag then return end
	Conns.antiRag = RunService.Heartbeat:Connect(function()
		local char = LP.Character;if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
		if hum then
			local st = hum:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject=hum
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule");if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.zero;root.RotVelocity=Vector3.zero end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end

local function stopAntiRagdoll()
	if Conns.antiRag then Conns.antiRag:Disconnect();Conns.antiRag=nil end
end

local IJ_JumpConn,IJ_FallConn = nil,nil

local function startInfiniteJump()
	if IJ_JumpConn then IJ_JumpConn:Disconnect() end
	if IJ_FallConn then IJ_FallConn:Disconnect() end
	IJ_JumpConn = UIS.JumpRequest:Connect(function()
		if not infJumpEnabled then return end
		local char = LP.Character;if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
	end)
	IJ_FallConn = RunService.Heartbeat:Connect(function()
		if not infJumpEnabled then return end
		local char = LP.Character;if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and root.Velocity.Y<-120 then root.Velocity=Vector3.new(root.Velocity.X,-120,root.Velocity.Z) end
	end)
end

local function stopInfiniteJump()
	if IJ_JumpConn then IJ_JumpConn:Disconnect();IJ_JumpConn=nil end
	if IJ_FallConn then IJ_FallConn:Disconnect();IJ_FallConn=nil end
end

local function disableAnimations()
	local char = LP.Character;if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid");if not hum then return end
	for _,track in pairs(unwalkAnimations) do pcall(function() track:Stop() end) end
	unwalkAnimations={}
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			track:Stop();table.insert(unwalkAnimations,track)
		end
	end
end

local function enableAnimations() unwalkAnimations={} end

RunService.Heartbeat:Connect(function()
	if not unwalkEnabled then return end
	disableAnimations()
end)

local brainrotReturnCooldown = false
local RAGDOLL_STATES = {[Enum.HumanoidStateType.Ragdoll]=true,[Enum.HumanoidStateType.FallingDown]=true,[Enum.HumanoidStateType.Physics]=true}

local function isRagdolledCheck()
	local c = LP.Character;if not c then return false end
	local hum = c:FindFirstChildOfClass("Humanoid");if not hum then return false end
	if RAGDOLL_STATES[hum:GetState()] then return true end
	for _,obj in ipairs(c:GetDescendants()) do
		if obj:IsA("Motor6D") and obj.Enabled==false then return true end
	end
	return false
end

local function doReturnTeleport(side)
	if brainrotReturnCooldown then return end
	brainrotReturnCooldown=true
	task.spawn(function()
		local char = LP.Character;if not char then brainrotReturnCooldown=false;return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not(hrp and hum) then brainrotReturnCooldown=false;return end
		local s1,s2,s3
		if tpMode=="Semi" then
			s1=side=="left" and SEMI_L1 or SEMI_R1
			s2=side=="left" and SEMI_L2 or SEMI_R2
			s3=side=="left" and SEMI_L3 or SEMI_R3
		else
			s1=side=="left" and BR_L1 or BR_R1
			s2=side=="left" and BR_L2 or BR_R2
			s3=side=="left" and BR_L3 or BR_R3
		end
		if tpMode=="Semi" then
			pcall(function()
				for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") then obj.Enabled=true end end
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				task.wait(0.20)
				hrp.AssemblyLinearVelocity=Vector3.zero;hrp.AssemblyAngularVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(s1+Vector3.new(0,3,0))
				task.wait(0.20)
				hrp.AssemblyLinearVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(s2+Vector3.new(0,3,0))
				task.wait(0.20)
				hrp.AssemblyLinearVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(s3+Vector3.new(0,3,0))
				hum:ChangeState(Enum.HumanoidStateType.Running)
				hum:Move(Vector3.zero,false)
				for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") then obj.Enabled=true end end
			end)
			task.wait(0.6)
		else
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.CFrame=CFrame.new(s1+Vector3.new(0,3,0))
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.1)
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.CFrame=CFrame.new(s2+Vector3.new(0,3,0))
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.1)
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.CFrame=CFrame.new(s3+Vector3.new(0,3,0))
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.6)
		end
		brainrotReturnCooldown=false
	end)
end

RunService.Heartbeat:Connect(function()
	if not(brainrotLeftEnabled or brainrotRightEnabled) or brainrotReturnCooldown then return end
	local char = LP.Character;if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid");if not hum then return end
	local hp = hum.Health
	local hit = hp<lastHealth-1
	local rag = RAGDOLL_STATES[hum:GetState()] or isRagdolledCheck()
	lastHealth=hp
	if not(hit or rag) then return end
	if brainrotLeftEnabled then doReturnTeleport("left")
	elseif brainrotRightEnabled then doReturnTeleport("right") end
end)

UIS.JumpRequest:Connect(function()
	if floatEnabled then floatJumping=true end
end)

local function startFloat()
	if Conns.float then Conns.float:Disconnect() end
	Conns.float = RunService.Heartbeat:Connect(function()
		if not floatEnabled then return end
		if dropActive then return end
		local char = LP.Character;if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart");if not root then return end
		local rp = RaycastParams.new();rp.FilterDescendantsInstances={char};rp.FilterType=Enum.RaycastFilterType.Exclude
		local rr = workspace:Raycast(root.Position,Vector3.new(0,-200,0),rp)
		if rr then
			local diff = (rr.Position.Y+floatHeight)-root.Position.Y
			if floatJumping then
				if root.AssemblyLinearVelocity.Y<=0 and diff>=-2 then
					floatJumping=false
				else
					return
				end
			end
			if math.abs(diff)>0.3 then
				root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,diff*15,root.AssemblyLinearVelocity.Z)
			else
				root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z)
			end
		end
	end)
end

local function stopFloat()
	if Conns.float then Conns.float:Disconnect();Conns.float=nil end
	floatJumping=false
	local char = LP.Character;if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z) end
	end
end

local function runDrop()
	if dropActive then return end
	local char = LP.Character;if not char then return end
	local hrp = char:FindFirstChild("HumanoidRoo
