skills = {}
stance = {}
SkillCtrl = {}

EventFunc = 
{
	Init = function(this, action)
		this.action = action;
	end,
	
	Update =  function(this)
		if this.time == nil then
			return;
		end
		
		if this.triggered == false and Self:Time() - this.beginTime >= this.time then
			this.triggered = true;
			
			if this.Func ~= nil then
				this:Func();
			end
		end
	end,
	
	SysEnter = function(this)
		this.beginTime = Self:Time();
		this.triggered = false;
	end,
	
	SysLeave = function(this)
	end,
}

ActionFunc =
{
	Init = function(this, skill)
		this.skill = skill;
		
		local skillAction = this.skill.Actions[this.nextAction];
		if skillAction ~= nil then
			this.time = Self:GetActionTime(this.name, skillAction.name);
		else
			this.time = Self:GetActionTime(this.name, this.nextAction);
		end
		
		--������ʱ������Ϊ�ض�����
		--if this.fixTime ~= nil then
		--	this.time = this.fixTime;
		--end
		
		if this.Events ~= nil then
			for k in pairs(this.Events) do
				SetTableFunc(this.Events[k], EventFunc);
				this.Events[k]:Init(this);
			end
		end
	end,
	
	SysEnter = function(this, isLoopEnter)
		Self:DebugPrint("[lua]Action Enter:" .. this.name .. " " .. this.time);
		--Self:ChangeAction(this.name);
		Self:SetUpbody(this.upbody);
		Self:SetStance(this.stance);
		this.beginTime = Self:Time();
		this.isActive = true;
		this.isPaused = false;
		this.pauseTime = 0;
		
		if isLoopEnter == nil then
			this.leftTime = this.fixTime;
		end
		
		if this.skill.isCollideDown then
			this:OnEvent("SysCollideDown");
		end
		
		if this.Events ~= nil then
			for k, v in pairs(this.Events) do
				v:SysEnter();
			end
			
			if this.Events.ActionBegin ~= nil then
				this.Events.ActionBegin:Func();
			end
		end
	end,
	
	SysLeave = function(this)
		if this.Events ~= nil then
			for k, v in pairs(this.Events) do
				v:SysLeave();
			end
			
			if this.Events.ActionEnd ~= nil then
				this.Events.ActionEnd:Func();
			end
		end
		
		Self:CancelEffect("ACTION");
	end,
	
	OnEvent = function(this, name, args)
		Self:DebugPrint("event:" .. name .. "------------------------");
		
		if this.Events ~= nil then
			local ent = this.Events[name];
			if ent ~= nil then
				ent.args = args;
				ent:Func();
			end
		end
		
		Self:DebugPrint("stance:" .. this.stance .. "------------------------");
		local curStance = stance[this.stance];
		if curStance ~= nil then
			local funcName = curStance[name];
			if funcName ~= nil then
				funcName(name, args);
			end
		end
	end,
	
	Update = function(this)
		if this.isActive == false then
			return;
		end
		
		if this.leftTime ~= nil then
			this.leftTime = this.leftTime - Self:TimeDelta();
			if this.leftTime <= 0 then
				this.isActive = false;
				
				return;
			end
		end
		
		if this.isPaused then
			local timeDelta = Self:TimeDelta();
			
			this.pauseTime = this.pauseTime - timeDelta;
			if this.pauseTime < 0 then
				this:Resume();
			else	
				this.beginTime = this.beginTime + timeDelta;
				
				if this.Events ~= nil then
					for k, v in pairs(this.Events) do
						v.beginTime = v.beginTime + timeDelta;
					end
				end
				
				return;
			end
		end
		
		if (Self:Time() - this.beginTime >= this.time) then
			if this.loop then
				this:SysEnter(true);
			else
				this.isActive = false;	
			end
		end
		
		if this.Events ~= nil then
			for k, v in pairs(this.Events) do
				v:Update();
			end
		end
		
		--���°���ָ�ļ���ȫ��Ķ�����ͻ���������
		if this.upbody == nil then
			Self:ChangeAction(this.name);
		end
	end,
	
	IsEventTriggered = function(this, eventName)
		if this.Events ~= nil then
			for k, v in pairs(this.Events) do
				if k == eventName and v.triggered then
					return true;
				end
			end
		end
		
		return false;
	end,
	
	Pause = function(this, t)
		Self:PauseAction();
		this.isPaused = true;
		this.pauseTime = t;
	end,
	
	Resume = function(this)
		Self:ResumeAction();
		this.isPaused = false;
		this.pauseTime = 0;
	end,
}

SkillFunc = 
{
	Init = function(this)
		if this.Actions ~= nil then
			for k in pairs(this.Actions) do
				SetTableFunc(this.Actions[k], ActionFunc);
				this.Actions[k]:Init(this);
			end
		end
	end,
	
	SysEnter = function(this)
		Self:OnSkillEnter(this.name);
		
		Self:EndSwordLight{};
		Self:EndGhost{hand = "body",};
		Self:EndGhost{hand = "both",};
		Self:ResumeAction();
		Self:SetJumpAccel(-10);
		this.isCollideDown = false;
		
		if this.Actions ~= nil then
			if this.randAction then
				this.curAction = this:SelectRandAction();--this.Actions[math.random(table.getn(this.Actions))];
			else
				this.curAction = this:SelectAction();
			end
		end
		
		if this.curAction ~= nil then
			if this.Enter ~= nil then
				this:Enter();
			end
			
			this.curAction:SysEnter();
		end
		
		this:OnCtrlEvent("SkillEnter");
	end,
	
	SysLeave = function(this)
		if this.curAction ~= nil then
			this.curAction:SysLeave();
		end
		
		Self:DebugPrint("Skill Leave:" .. this.name);
		if this.Leave ~= nil then
			this:Leave();
		end
		
		Self:OnSkillLeave();
		this:OnCtrlEvent("SkillLeave");
		Self:CancelEffect("SKILL");
	end,
	
	OnEvent = function(this, name, args)
		if name == "SysCollideDown" then
			this.isCollideDown = true;
		end
		
		if this.curAction ~= nil then
			this.curAction:OnEvent(name, args);
		end
	end,
	
	Update = function(this)
		if this.curAction ~= nil then
			this.curAction:Update();
			
			if this.curAction.isActive == false then
				this:NextAction();
			end
		end
		
		if this.UpdateCtrl ~= nil and Config.isMain then
			local curActionName = "";
			if this.curAction ~= nil then
				curActionName = this.curAction.name;
			end
			
			this:UpdateCtrl(curActionName);
		end
	end,	
	
	NextAction = function(this)
		if this.curAction ~= nil and this.curAction.nextAction ~= nil then
			this.curAction:SysLeave();
			this.curAction = this:FindActionByKey(this.curAction.nextAction);
			 
			if this.curAction ~= nil then
				this.curAction:SysEnter();
			end
		end
	end,
	
	FindActionByKey = function(this, key)
		if this.Actions ~= nil then
			--[[
			for k in pairs(this.Actions) do
				if this.Actions[k].name == actionName then
					return this.Actions[k];
				end
			end]]
			
			for k, v in pairs(this.Actions) do
				if k == key then
					return v;
				end
			end
		end
		
		return nil;
	end,
	
	SelectAction = function(this)
		if this.Actions == nil then
			return;
		end
		
		local selAction = nil;
		
		for k in pairs(this.Actions) do
			local curAction = this.Actions[k];
			if curAction.priority ~= nil and curAction.IsReady ~= nil and curAction.IsReady() then
				if selAction == nil then
					selAction = curAction;
				elseif selAction.priority < curAction.priority then
					selAction = curAction;
				end
			end
		end
		
		return selAction;
	end,
	
	SelectRandAction = function(this)
		local normalAction = this:SelectAction();
		if this:IsRandAction(normalAction) then
			local key = this.randAction[math.random(table.getn(this.randAction))];
			Self:DebugPrint("[lua]rand action:" .. key);
			return this.Actions[key];
		else
			return normalAction;
		end
	end,
	
	IsRandAction = function(this, act)
		for k, v in pairs(this.randAction) do
			if this.Actions[v] == act then
				return true;
			end
		end
		
		return false;
	end,
	
	IsEventTriggered = function(this, eventName)
		if this.Actions ~= nil then
			for k, v in pairs(this.Actions) do
				if v:IsEventTriggered(eventName) then
					return true;
				end
			end
		end
		
		return false;
	end,
	
	OnCtrlEvent = function(this, eventName)
		if this.CtrlEvent ~= nil and Config.isMain then
			this:CtrlEvent(eventName);
		end 
	end,
}

SkillMgr = 
{
	curSkill = nil,
	selectedSkill = nil,
	
	OnEvent = function(this, name, args)
		if this.curSkill ~= nil then
			this.curSkill:OnEvent(name, args);
		end
	end,
	
	ReEnter = function(this)
		if this.curSkill ~= nil then
			Self:DebugPrint("[lua]ReEnter");
			this.curSkill:SysEnter();
		end
	end,
	
	--���ż���
	PlaySkill = function(this, key)
		this:ChangeTo(skills[key]);
	end,
	
	CancelSkill = function(this, key)
		if this.curSkill ~= nil then
			this.curSkill:NextAction();
		end
	end,
	
	--���ű���
	PlayHit = function(this, hitName)
		this:ChangeTo(hit[hitName]);
	end,
	
	--�ڲ�ת������
	ChangeTo = function(this, skill)
		if skill ~= nil then
			Self:DebugPrint("[lua]ChangeTo:" .. skill.name);
			
			if this.curSkill ~= nil then
				this.curSkill:SysLeave();
			end
			
			this.curSkill = skill;
			this.curSkill:SysEnter();
		end
	end,
	
	--���ܵ�ǰ�Ƿ����
	IsSkillReady = function(this, skillID)
		local skill = skills[skillID];
		if skill ~= nil then
			return skill:IsReady();
		end
		
		return false;
	end,
	
	Update = function(this, delta)
		if this.curSkill ~= nil then
			this.curSkill:Update();
			if this.curSkill.curAction == nil then
				if this.curSkill.nextSkill ~= nil then
					this:PlaySkill(this.curSkill.nextSkill);
				else
					this.curSkill:SysLeave();
					this.curSkill = nil;
				end
			end
		end
		
		if this.curSkill == nil then
			this:PlaySkill("Idle");
		end
	end,	
}

function SetTableFunc(t0, t1)
	if t0 == nil or t1 == nil then
		return;
	end
	
	for k in pairs(t1) do
		t0[k] = t1[k];
	end
end

---------------------------------------------------------------------------------------------------------
--��ɫ�ű���ʼ��ʱ����һ��
function Init()
	for k in pairs(skills) do
		SetTableFunc(skills[k], SkillFunc);
		SetTableFunc(skills[k], SkillCtrl[k]);
		skills[k]:Init();
	end
	
	Self:DebugPrint("[lua]Script inited");
	
	if Config.InitEffect ~= nil then
		Self:DebugPrint("[lua]InitEffect");
		for k, v in pairs(Config.InitEffect) do
			Self:DebugPrint("[lua]InitEffect" .. v);
			Self:PlayLocalEffect{id = v};
		end
	end
end

--ÿ֡����
function Update(delta)
	SkillMgr:Update(delta);
end

function PlaySkill(skillID)
	SkillMgr:PlaySkill(skillID);
end

function CancelSkill(skillID)
	SkillMgr:CancelSkill(skillID);
end

--���Ż�������
function PlayBase(actionName)
	SkillMgr:PlaySkill(actionName);
end

--���²��ŵ�ǰ����
function ReEnter()
	SkillMgr:ReEnter();
end

function OnEvent(name, args)
	SkillMgr:OnEvent(name, args);
end

function SetConfig(key, value)
	Config[key] = value;
end

--���ü��ܶ�����ʱ��
function SetBaseTime(skillName, time)
	skill = skills[skillName];
	if skill ~= nil and skill.Actions ~= nil then
		for k, v in pairs(skill.Actions) do
			v.time = time;
			v.loop = false;
		end
	end
end



Ctrl = 
{
	MOVE = 0,
	ATK = 1,
	
	TurnToKeyboardDir = function(this, rotate)
		local kd = nil;
		if this:IsRunUp() and this:IsRunLeft() then
			kd = "WA";
		elseif this:IsRunUp() and this:IsRunRight() then
			kd = "WD";
		elseif this:IsRunLeft() and this:IsRunDown() then
			kd = "AS";
		elseif this:IsRunDown() and this:IsRunRight() then
			kd = "SD";
		elseif this:IsRunUp() then
			kd = "W";
		elseif this:IsRunLeft() then
			kd = "A";
		elseif this:IsRunDown() then
			kd = "S";
		elseif this:IsRunRight() then
			kd = "D";
		end
		
		if rotate == nil then
			rotate = true;
		end
		
		if kd ~= nil then
			Self:TurnToDir(kd);
		end
		
		return kd;
	end,
	
	TurnToRandDir = function(this)
		local dirset = {"WA", "WD", "AS", "SD", "W", "A", "S", "D",};
		local kd = dirset[math.random(table.getn(dirset))];
		Self:TurnToDir(kd);
	end,
	
	TurnToMouse = function(this)
		Self:TurnToMouse();
	end,
	
	HaveAttackTarget = function(this)
		return Self:HaveAttackTarget();
	end,
	
	TurnToAttackTarget = function(this)
		Self:TurnToAttackTarget();
	end,
	
	IsKeyboardRun = function(this)
		return this:IsRunLeft() or this:IsRunRight() or this:IsRunUp() or this:IsRunDown();
	end,
	
	IsRunLeft = function(this)
		return Self:IsKeyDown(CtrlMap["RunLeft"].Key);
	end,	
	
	IsRunRight = function(this)
		return Self:IsKeyDown(CtrlMap["RunRight"].Key);
	end,
	
	IsRunUp = function(this)
		return Self:IsKeyDown(CtrlMap["RunUp"].Key);
	end,
	
	IsRunDown = function(this)
		return Self:IsKeyDown(CtrlMap["RunDown"].Key);
	end,
	
	IsJump = function(this)
		return Self:IsKeyClicked(CtrlMap["Jump"].Key);
	end,
	
	IsDefense = function(this)
		return Self:IsKeyClicked(CtrlMap["Defense"].Key);
	end,
	
	IsDash = function(this)
		--1.˫��WSAD
		--[[
		if Self:IsKeyDoubleClicked(CtrlMap["RunLeft"].Key) or 
		   Self:IsKeyDoubleClicked(CtrlMap["RunRight"].Key) or 
		   Self:IsKeyDoubleClicked(CtrlMap["RunUp"].Key) or 
		   Self:IsKeyDoubleClicked(CtrlMap["RunDown"].Key) then
			return true;
		end]]
		
		--2.Shift + WSAD
		if this:IsKeyboardRun() and Self:IsKeyClicked("LSHIFT") then
			return true;
		end
		
		return false;
	end,
	
	--ʹ�ü��ܵ�����
	IsUseSkill = function(this)
		--ʹ����ͨ����
		if this:IsUseAtk() then
			return GetSkillID(Ctrl.ATK);
		end
		
		--������̶�Ӧ��ݼ�������ͼ1��2��3��4��5��6��Q��E����ֱ��ʩ�ţ�
		if SkillTable ~= nil then
			for k, v in pairs(SkillTable) do
				if Self:IsKeyClicked(k) then
					return v;
				end
			end
		end
		
		--������ICON��������Ҽ����������ʱ����������Ҽ���
		if Config.mouseRight ~= Ctrl.MOVE and Config.mouseRight ~= Ctrl.ATK and Self:IsMouseRClicked() then
			return Config.mouseRight;
		end
		
		return 0;
	end,
	
	--ʹ�õļ����Ƿ�Ϊ����״̬
	IsUseSkillPressed = function(this, skillID)
		Self:DebugPrint("[skillpressed]right:" .. Config.mouseRight .. " left:" .. Config.mouseLeft);
		
		if GetSkillID(Ctrl.ATK) == skillID then
			skillID = Ctrl.ATK;
		end
		
		if Config.mouseRight == skillID and Self:IsMouseRDown() then
			Self:DebugPrint("[skillpressed]is mouse r down");
			
			return true;
		end
		
		if Config.mouseLeft == skillID and Self:IsMouseLDown() then
			Self:DebugPrint("[skillpressed]is mouse l down");
			
			return true;
		end
		
		Self:DebugPrint("[skillpressed]nothing is mouse r down");
		
		return false;
	end,
	
	--ʩ����ͨ����������
	IsUseAtk = function(this)
		if Config.mouseLeft == Ctrl.ATK and Self:IsMouseLClicked() then
			return true;
		elseif Config.mouseRight == Ctrl.ATK and Self:IsMouseRClicked() then
			return true;
		else
			return false;
		end
	end,
	
	--�Ƿ�������ƶ�
	IsAutoRun = function(this)
		if Config.mouseLeft == Ctrl.MOVE and Self:IsMouseLClicked() then
			return true;
		elseif Config.mouseRight == Ctrl.MOVE and Self:IsMouseRClicked() then
			return true;
		else
			return false;
		end
	end,
	
	--�Ƿ���NPC�Ի�
	IsClickNpc = function(this)
		return Self:IsMouseLClicked() and Self:GetMouseActorType() == "NPC";
	end,
	
	ClickNpc = function(this)

	end,
	
	--ʹ�ü���ʱ�������ͨ��
	UseSkill = function(this, skillID)
		SkillMgr:PlaySkill(skillID);
	end,
	
	--����֮���������ʱʹ�ã���ʱ����鵱ǰ�����ܷ�ʩ��
	LinkSkill = function(this, skillID)
		SkillMgr:PlaySkill(skillID);
	end,
	
	--ȡ������
	CancelSkill = function(this)
		--Self:SendMsg{name = "CancelSkill", };
	end,
	
	--�л���������
	PlayAction = function(this, actionName)
		SkillMgr:PlaySkill(actionName);
		--Self:SendPlayAction(actionName);
		--Self:DebugPrint("[move]PlayAction:" .. actionName);
	end,
	
	StartMove = function(this)
		--Self:SendStartMove();
		--Self:DebugPrint("[luamove]startmove");
	end,
	
	StopMove = function(this)
		--Self:SendStopMove();
		--Self:DebugPrint("[luamove]stopmove");
	end,
	
	--��鼼�ܵ�ǰ�Ƿ�����һ���߽ӵ�������
	IsNextSkillRange = function(this, skillTable)
		return skillTable:IsEventTriggered("NextBegin");-- and (not skillTable:IsEventTriggered("NextEnd"));
	end,
	
	UpdateLinkSkill = function(this, skillTable, groupID, skillID)
		if Ctrl:IsNextSkillRange(skillTable) and skillTable.isInput then
			Ctrl:TurnToMouse();
			Ctrl:LinkSkill(skillID);
			skillTable.isInput = false;
		else
			if (Ctrl:IsUseSkill() == groupID) then
				skillTable.isInput = true;
			elseif Ctrl:IsUseSkillPressed(groupID) then
				skillTable.isInput = true;
			end
		end
	end,
	
	UpdateUseSkill = function(this, skillTable, groupID, skillID)
		if Ctrl:IsNextSkillRange(skillTable) and skillTable.isInput then
			Ctrl:TurnToAttackTarget();
			Ctrl:UseSkill(skillID);
			skillTable.isInput = false;
		else
			if (Ctrl:IsUseSkill() == groupID) then
				skillTable.isInput = true;
			end
		end
	end,
	
	--һ���������ӵ��������ܣ�
	--skillTable ���ƽű�
	--ent ���¼���
	--from ��ǰ���ܺ�
	--to Ҫ�л����ļ�����
	UpdateUseSkillSet = function(this, skillTable, ent, from, to)
		if skillTable:IsEventTriggered(ent) then 
			local skillID = Ctrl:IsUseSkill();
			
			if to ~= nil then
				for k, v in pairs(to) do
					if to[k] == skillID then
						Ctrl:TurnToAttackTarget();
						Ctrl:UseSkill(skillID);
						break;
					end
				end
			else
				if skillID ~= 0 and skillID ~= from then
					Ctrl:TurnToAttackTarget();
					Ctrl:UseSkill(skillID);
				end
			end
		end
	end,
	
	GetMouseActorType = function(this)
		return Self:GetMouseActorType();
	end,
	
	GetAttackTargetType = function(this)
		return Self:GetAttackTargetType();
	end,
	
	--Idle
	UpdateIdle = function(this, skillTable)
		if Ctrl:IsClickNpc() then
			Ctrl:ClickNpc();
		else
			if Self:IsKeyClicked(1) then
				Ctrl:TurnToMouse();
				SkillMgr:PlaySkill(200020);
				--Ctrl:LinkSkill(200020);
				return;
			end
			
			if Self:IsMouseRDown() then
				if Self:GetWeaponID() == 1 then
					SkillMgr:PlaySkill(200011);
				elseif Self:GetWeaponID() == 2 then
					SkillMgr:PlaySkill(200012);
				else
					SkillMgr:PlaySkill(200010);
				end
			elseif Ctrl:IsKeyboardRun() then
				Ctrl:TurnToKeyboardDir();
				Ctrl:PlayAction("Run");
			--[[
			elseif Ctrl:IsAutoRun() then
				Ctrl:PlayAction("AutoRun");
			elseif Ctrl:IsJump() then
				Ctrl:PlayAction("Jump");
			else
				local skillID = Ctrl:IsUseSkill();
				if skillID ~= 0 then
					Ctrl:TurnToMouse();
					Ctrl:UseSkill(skillID);
				end]]
			end
		end
	end,
	
	UpdateRun = function(this, skillTable)
		if Ctrl:IsDash() then
			Ctrl:UseSkill(GetSkillID("Dash"));
		elseif Ctrl:IsKeyboardRun() then
			if Self:IsMouseRDown() then
				if Self:GetWeaponID() == 1 then
					SkillMgr:PlaySkill(200011);
				elseif Self:GetWeaponID() == 2 then
					SkillMgr:PlaySkill(200012);
				else
					SkillMgr:PlaySkill(200010);
				end
			elseif Ctrl:IsJump() then
				Ctrl:PlayAction("JumpForward");
			elseif Ctrl:IsUseSkill() ~= 0 then
				Ctrl:TurnToMouse();
				Ctrl:UseSkill(Ctrl:IsUseSkill());
			else
				Ctrl:TurnToKeyboardDir();
			end
		else
			Ctrl:PlayAction("Idle");
		end
	end,
	
	UpdateAutoRun = function(this)
		if Ctrl:IsDash() then
			Ctrl:UseSkill(GetSkillID("Dash"));
		elseif Ctrl:IsUseSkill() ~= 0 then
			Ctrl:TurnToMouse();
			Ctrl:UseSkill(Ctrl:IsUseSkill());
		elseif Ctrl:IsKeyboardRun() then
			Ctrl:TurnToKeyboardDir();
			Ctrl:PlayAction("Run");
		elseif Ctrl:IsAutoRun() then
			Ctrl:PlayAction("AutoRun");
		end
	end,
}

CtrlMap = {}

CtrlMap["RunUp"] =
{
	Key = "W",	
}

CtrlMap["RunDown"] =
{
	Key = "S",	
}

CtrlMap["RunLeft"] =
{
	Key = "A",		
}

CtrlMap["RunRight"] =
{
	Key = "D",	
}

CtrlMap["Jump"] =
{
	Key = "SPACE",	
}

CtrlMap["Defense"] =
{
	Key = "Q",		
}

CtrlMap["UseSkill"] =
{
	Mouse = "RIGHT",	
}

CtrlMap["Dash"] =
{
	Key = "LALT",	
}
stance["stand_free"] =
{
	["Rigide"] = function(name, args)
		Config.rigidTime = args["Time"];
		SkillMgr:PlaySkill("Rigide");
	end,
	
	["Float"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = 0;
		SkillMgr:PlaySkill("Float");
	end,
	
	["BlowOff"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = args["MoveSpeed"];
		SkillMgr:PlaySkill("BlowOff");
	end,
	
	["Dismembered"] = function(name, args)
		SkillMgr:PlaySkill("Dismembered");
	end,
}

stance["ground_action"] =
{
	["Rigide"] = function(name, args)
		Config.rigidTime = args["Time"];
		SkillMgr:PlaySkill("Rigide");
	end,
	
	["Float"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = 0;
		SkillMgr:PlaySkill("Float");
	end,
	
	["BlowOff"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = args["MoveSpeed"];
		SkillMgr:PlaySkill("BlowOff");
	end,
	
	["Dismembered"] = function(name, args)
		SkillMgr:PlaySkill("Dismembered");
	end,
}

stance["rigide"] =
{
	["Rigide"] = function(name, args)
		Config.rigidTime = args["Time"];
		SkillMgr:PlaySkill("RigideSecond");
	end,
	
	["Float"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = 0;
		SkillMgr:PlaySkill("Float");
	end,
	
	["BlowOff"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = args["MoveSpeed"];
		SkillMgr:PlaySkill("BlowOff");
	end,
	
	["Dismembered"] = function(name, args)
		SkillMgr:PlaySkill("Dismembered");
	end,
}

stance["rigidsecond"] =
{
	["Rigide"] = function(name, args)
		Config.rigidTime = args["Time"];
		SkillMgr:PlaySkill("Rigide");
	end,
	
	["Float"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = 0;
		SkillMgr:PlaySkill("Float");
	end,
	
	["BlowOff"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = args["MoveSpeed"];
		SkillMgr:PlaySkill("BlowOff");
	end,
	
	["Dismembered"] = function(name, args)
		SkillMgr:PlaySkill("Dismembered");
	end,
}

stance["down"] =
{

	

}

stance["float"] =
{
	
	["Float"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = 0;
		SkillMgr:PlaySkill("FloatHit");
	end,
	
	["BlowOff"] = function(name, args)
		Config.jumpSpeed = args["JumpSpeed"];
		Config.moveSpeed = args["MoveSpeed"];
		SkillMgr:PlaySkill("BlowOff");
	end,
}
Config =
{
	--����Ƿ�������
	isMain = false,
	
	--��ͨ����
	--normalSkill = 1111011,
	
	--��ǰ�Ҽ�����
	--rightSkill = 1127011,	
	
	--Ӳֵʱ��
	rigidTime = 0.0,
	
	--�ƶ��ٶ�
	moveSpeed = 5.0,
	
	--�����ٶ�
	jumpSpeed = 5.0,
	
	--�ɼ�Ŀ���ID
	gatherTarget = 0,
	
	--�ɼ�ʱ��
	gatherTime = 3.0,
	
	--������Ҽ�����Ϣ
	--ATK, MOVE, all other is skill
	mouseRight = "ATK",
	mouseLeft = "MOVE",
}

PlayerConfig = Self:GetPlayerConfig();

SkillTable = 
{
	["1"] = 1111011,
	["2"] = 100040,
	["3"] = 100050,
	["4"] = 100060,
	["5"] = 100070,
	["6"] = 100080,
	["Q"] = 100020,
	["E"] = 1111011,
}

function GetSkillID(name)
	if name == "Dash" then
	 	return 100040;
	elseif name == "ATK" then
		return 300010;
	end
end

function OnToolInit()
	Self:SetWeapon{id=3};
	--Self:SetWeapon{model="Equipments/Glave_001.MODEL", bone="Bip01 Prop2", weaponType="Glave", hand="LEFT",};
end
skills[200020] = 
{
	name = "����",
	
	Enter = function()
		Self:DecSP(PlayerConfig.SpecSkillSP);
	end,
	
	Actions = 
	{
		["A"] =
		{
			name = "transfer",
			loop = false,
			stance = "ground",
			weapon = 0,
			switch = 1,
			priority = 0,
			nextAction = "Idle",
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
				["Shoot1"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayLocalEffect{id = 2000201};
					end,
				},
				
				["Shoot2"] = 
				{
					time = 0.95,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000201};
					end,
				},
			},
		},	
	},
	
	IsReady = function()
		return true;
	end,
}
skills[200011] = 
{
	name = "��һ��ǹ",
	Actions = 
	{
		["A"] =
		{
			name = "a_RunBack",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			upbody = {left="a_RunRight", right="a_RunRight", stand="a_Shoot",run="a_RunShoot", back="a_RunBack"},
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.11,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-L.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},				
				["RStep"] =
				{
					time = 0.71,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-R.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				["Shoot1"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000111};
					end,
				},	
				["Shoot2"] = 
				{
					time = 0.25,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000111};
					end,
				},	
				["Shoot3"] = 
				{
					time = 0.5,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000111};
					end,
				},	
				["Shoot4"] = 
				{
					time = 0.75,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000111};
					end,
				},	
			},
		},	
	},
	
	IsReady = function()
		return true;
	end,
}
skills[200012] = 
{
	name = "�ڶ���ǹ",
	Actions = 
	{
		[0] =
		{
			name = "b_RunBack",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			upbody = {left="b_RunLeft", right="b_RunRight", stand="b_Shoot",run="b_RunShoot", back="b_RunBack"},
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.11,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-L.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				["Particle2"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000121};
						Self:PlaySound{path="A_C_Roll_1.wav", time = 1.0, volume = 1.0, distance = 10};
					end,
				},				
				["RStep"] =
				{
					time = 0.71,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-R.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
			},
		},	
	},
	
	IsReady = function()
		return true;
	end,
}
skills[200010] = 
{
	name = "��ǹ����",
	Actions = 
	{
		[0] =
		{
			name = "c_RunBack",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			upbody = {left="c_RunLeft", right="c_RunRight", stand="c_Shoot", run="c_RunShoot", back="c_RunBack"},
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.11,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-L.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},			
				["RStep"] =
				{
					time = 0.71,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-R.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				["Shoot1"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000101};
					end,
				},	
				["Shoot2"] = 
				{
					time = 0.25,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000101};
					end,
				},	
				["Shoot3"] = 
				{
					time = 0.5,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000101};
					end,
				},	
				["Shoot4"] = 
				{
					time = 0.75,
					Func = function(this)
						Self:PlayGlobalEffect{id = 2000101};
					end,
				},	
			},
		},	
	},
	
	IsReady = function()
		return true;
	end,
}
skills["Dash"] =
{
	name = "Dash",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(8);
		Self:PlayGlobalEffect{id=12,};
	end,
	
	Leave = function(this)
		Self:SetMoveSpeed(0);
	end,
	
	Actions = 
	{
		[1] =
		{
			name = "c_BattleIdle",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 0,
			nextAction = "idle",
			
			IsReady = function(this)
				return true;
			end,
		},	
	},	
}
skills["Death"] =
{
	name = "Death",
	nextSkill = "Die",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(0);
	end,
	
	Actions = 
	{
		["Death"] =
		{
			name = "a_Die_01",
			loop = false,
			stance = "death",
			weapon = 0,
			switch = 0,
			priority = 0,
			nextAction = "Die",
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
		     	["Sound"] = 
				{
					time = 0.07,
					Func = function(this)
						Self:PlaySound{path="A_Die_Voice.wav", time = 1.0, volume = 1.0, distance = 10};
					end,
				},	
			},
		},	
	},	
}
skills["Die"] =
{
	name = "Die",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(0);
	end,
	
	Actions = 
	{
		["Die"] =
		{
			name = "a_Die",
			loop = true,
			stance = "die",
			weapon = 0,
			switch = 0,
			priority = 0,
			
			IsReady = function(this)
				return true;
			end,
		},	
	},	
}
skills["Float"] =
{
	name = "Float",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		
	end,
	
	Actions = 
	{
		["Up"] =
		{
			name = "air_float_up",
			loop = false,
			stance = "float",
			weapon = 0,
			switch = 0,
			priority = 0,
			nextAction = "Down",
			
			IsReady = function(this)
				return true;
			end,
			
			Events =
			{
				["ActionBegin"] =
				{
					Func = function(this)
						Self:SetJumpSpeed(Config.jumpSpeed);
					end,	
				},
			}
				
		},	
		
		["Down"] = 
		{
			name = "air_float_down",
			loop = false,
			stance = "float",
			weapon = 0,
			switch = 0,
			priority = 0,
			nextAction = "Land",
			
			Events =
			{
				["ActionBegin"] =
				{
					Func = function(this)
						Self:SetJumpSpeed(-2);
					end,	
				},
				
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},
			}
		},
		
		["Land"] = 
		{
			name = "air_float_land",
			loop = false,
			stance = "float",
			weapon = 0,
			switch = 0,
			priority = 0,
			nextAction = "raise",
		},
		
		["raise"] = 
		{
			name = "raise",
			loop = false,
			stance = "float",
			weapon = 0,
			switch = 0,
			priority = 0,
			nextAction = "idle",
		},
	},	
}
skills["Idle"] =
{
	name = "Idle",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(0);
	end,
	
	Actions = 
	{
		[1] =
		{
			name = "a_BattleIdle",
			loop = true,
			stance = "stand_free",
			weapon = 0,
			switch = 1,
			priority = 0,
			
			IsReady = function(this)
				return true;
			end,
		},	
		
		[2] =
		{
			name = "b_BattleIdle",
			loop = true,
			stance = "stand_free",
			weapon = 0,
			switch = 1,
			priority = 0,
			
			IsReady = function(this)
				return Self:GetWeaponID() == 2;
			end,
		},	
		
		[3] =
		{
			name = "c_attleIdle",
			loop = true,
			stance = "stand_free",
			weapon = 0,
			switch = 1,
			priority = 0,
			
			IsReady = function(this)
				return Self:GetWeaponID() == 3;
			end,
		},	
	},	
}
skills["Jump"] =
{
	name = "Jump",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetJumpSpeed(10.0);
		Self:SetJumpAccel(-30);
	end,
	
	Actions = 
	{
		--normal
		["normal0"] =
		{
			name = "jump_blades",
			loop = false,
			stance = "hang_free",
			weapon = 0,
			switch = 1,
			priority = 0,
			nextAction = "normal1",
			
			IsReady = function(this)
				return true;
			end,
		},	
		
		["normal1"] =
		{
			name = "hang_blades",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 0,
			nextAction = "normal2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},	
		
		["normal2"] =
		{
			name = "land_blades",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 0,
			nextAction = "idle",
		},	
		
		--mace
		["mace0"] = 
		{
			name = "jump_mace",
			loop = false,
			stance = "hang_free",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "mace1",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Hammer");
			end,
		},
		
		["mace1"] = 
		{
			name = "hang_mace",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "mace2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},
		
		["mace2"] = 
		{
			name = "land_mace",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "idle",
		},
		
		--blades
		["blades0"] = 
		{
			name = "jump_blades",
			loop = false,
			stance = "hang_free",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "blades1",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Glave");
			end,
		},
		
		["blades1"] = 
		{
			name = "hang_blades",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "blades2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},
		
		["blades2"] = 
		{
			name = "land_blades",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "idle",
		},
		
		--shield
		["shield0"] = 
		{
			name = "jump_shield",
			loop = false,
			stance = "hang_free",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "shield1",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Shield");
			end,
		},
		
		["shield1"] = 
		{
			name = "hang_shield",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "shield2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},
		
		["shield2"] = 
		{
			name = "land_shield",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "idle",
		},
	},	
}
skills["JumpForward"] =
{
	name = "Jump",
	nextSkill = "Run",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(5.0);
		Self:SetJumpSpeed(10.0);
		Self:SetJumpAccel(-30);
	end,
	
	Actions = 
	{
		--normal
		["normal0"] =
		{
			name = "jump_blades",
			loop = false,
			stance = "hang_free",
			weapon = 0,
			switch = 1,
			priority = 0,
			nextAction = "normal1",
			
			IsReady = function(this)
				return true;
			end,
		},	
		
		["normal1"] =
		{
			name = "hang_blades",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 0,
			nextAction = "normal2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},	
		
		["normal2"] =
		{
			name = "land_blades",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 0,
			nextAction = "run_blades",
			
			Events =
			{
				["Land"] =
				{
					time = 0.21,
					Func = function(this)
						Self:SetMoveSpeed(0.0);
					end,	
				},
			},
		},	
		
		--mace
		["mace0"] = 
		{
			name = "jump_mace",
			loop = false,
			stance = "hang_free",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "mace1",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Hammer");
			end,
		},
		
		["mace1"] = 
		{
			name = "hang_mace",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "mace2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},
		
		["mace2"] = 
		{
			name = "land_mace",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "run_mace",
			
			Events =
			{
				["Land"] =
				{
					time = 0.07,
					Func = function(this)
						Self:SetMoveSpeed(0.0);
					end,	
				},
			},
		},
		
		--blades
		["blades0"] = 
		{
			name = "jump_blades",
			loop = false,
			stance = "hang_free",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "blades1",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Glave");
			end,
		},
		
		["blades1"] = 
		{
			name = "hang_blades",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "blades2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},
		
		["blades2"] = 
		{
			name = "land_blades",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "run_blades",
			
			Events =
			{
				["Land"] =
				{
					time = 0.21,
					Func = function(this)
						Self:SetMoveSpeed(0.0);
					end,	
				},
			},
		},
		
		--shield
		["shield0"] = 
		{
			name = "jump_shield",
			loop = false,
			stance = "hang_free",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "shield1",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Shield");
			end,
		},
		
		["shield1"] = 
		{
			name = "hang_shield",
			loop = true,
			stance = "hang_free",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "shield2",
			
			Events = 
			{
				["SysCollideDown"] =
				{
					Func = function(this)
						this.action.skill:NextAction();
					end,	
				},	
			},
		},
		
		["shield2"] = 
		{
			name = "land_shield",
			loop = false,
			stance = "ground_action",
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "run_shield",
			
			Events =
			{
				["Land"] =
				{
					time = 0.21,
					Func = function(this)
						Self:SetMoveSpeed(0.0);
					end,	
				},
			},
		},
	},	
}
skills["Rigide"] =
{
	name = "Rigide",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(0);
		Self:DebugPrint("Enter Rigide");
	end,
	
	Actions = 
	{
		[1] =
		{
			name = "hit",
			loop = false,
			stance = "rigide",
			weapon = 1,
			switch = 0,
			priority = 0,
			nextAction = "idle",
			
			IsReady = function(this)
				return true;
			end,
			
			Events =
			{
				["Rigide"] =
				{
					time = 0.04,
					
					Func = function(this)
						this.action:Pause(Config.rigidTime);
					end,	
				},
			},
		},	
		
		[2] = 
		{
			name = "hit_blades_a",
			loop = false,
			stance = "rigide",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "idle",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Glave");
			end,
			
			Events =
			{
				["Rigide"] =
				{
					time = 0.06,
					
					Func = function(this)
						this.action:Pause(Config.rigidTime);
					end,	
				},
			},
		},
		
		[3] = 
		{
			name = "hit_mace_a",
			loop = false,
			stance = "rigide",	
			weapon = 1,
			switch = 0,
			priority = 1,
			nextAction = "idle",
			
			IsReady = function(this)
				return Self:HasEquipSubType("Hammer");
			end,
			
			Events =
			{
				["Rigide"] =
				{
					time = 0.04,
					
					Func = function(this)
						this.action:Pause(Config.rigidTime);
					end,	
				},
			},
		},
	},	
}
skills["Run"] =
{
	name = "Run",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(PlayerConfig.MoveSpeed);
	end,
	
	Leave = function(this)
		Self:SetMoveSpeed(0.0);
	end,
	
	Actions = 
	{
		[1] =
		{
			name = "a_Run",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.02,
					Func = function(this)
						Self:PlaySound{path="robot_run.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				
				["RStep"] =
				{
					time = 0.1,
					Func = function(this)
						Self:PlaySound{path="robot_run.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
			},
		},	
		
		[2] =
		{
			name = "b_Run",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			
			IsReady = function(this)
				return Self:GetWeaponID() == 2;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.02,
					Func = function(this)
						Self:PlaySound{path="robot_run.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				
				["RStep"] =
				{
					time = 0.1,
					Func = function(this)
						Self:PlaySound{path="robot_run.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
			},
		},

		[3] =
		{
			name = "c_Run",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			
			IsReady = function(this)
				return Self:GetWeaponID() == 3;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.02,
					Func = function(this)
						Self:PlaySound{path="robot_run.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				
				["RStep"] =
				{
					time = 0.1,
					Func = function(this)
						Self:PlaySound{path="robot_run.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
			},
		},	
	},	
}
skills["Shoot"] =
{
	name = "Shoot",
	
	IsReady = function(this)
		return true;
	end, 
	
	Actions = 
	{
		["A"] =
		{
			name = "a_RunBack",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			upbody = {left="a_RunRight", right="a_RunRight", stand="a_Shoot",run="a_RunShoot", back="a_RunBack"},
			
			IsReady = function(this)
				return Self:GetWeaponID() == 1;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.11,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-L.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},				
				["RStep"] =
				{
					time = 0.71,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-R.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				["Shoot1"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000101};
					end,
				},	
				["Shoot2"] = 
				{
					time = 0.25,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000101};
					end,
				},	
				["Shoot3"] = 
				{
					time = 0.5,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000101};
					end,
				},	
				["Shoot4"] = 
				{
					time = 0.75,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000101};
					end,
				},	
			},
		},	
		
		[2] =
		{
			name = "b_RunBack",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			upbody = {left="b_RunLeft", right="b_RunRight", stand="b_Shoot",run="b_RunShoot", back="b_RunBack"},
			
			IsReady = function(this)
				return Self:GetWeaponID() == 2;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.11,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-L.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				["Particle2"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000111};
						Self:PlaySound{path="A_C_Roll_1.wav", time = 1.0, volume = 1.0, distance = 10};
					end,
				},				
				["RStep"] =
				{
					time = 0.71,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-R.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
			},
		},	
		
		[3] =
		{
			name = "c_RunBack",
			loop = true,
			stance = "move",
			weapon = 0,
			switch = 1,
			priority = 0,
			upbody = {left="c_RunLeft", right="c_RunRight", stand="c_Shoot", run="c_RunShoot", back="c_RunBack"},
			
			IsReady = function(this)
				return Self:GetWeaponID() == 3;
			end,
			
			Events = 
			{
				["LStep"] =
				{
					time = 0.11,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-L.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},			
				["RStep"] =
				{
					time = 0.71,
					Func = function(this)
						Self:PlaySound{path="fst-female-dirt-metal-R.wav", time = 1.0, volume = 1.0, distance = 10};
					end,	
				},	
				["Shoot1"] = 
				{
					time = 0.01,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000121};
					end,
				},	
				["Shoot2"] = 
				{
					time = 0.25,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000121};
					end,
				},	
				["Shoot3"] = 
				{
					time = 0.5,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000121};
					end,
				},	
				["Shoot4"] = 
				{
					time = 0.75,
					Func = function(this)
						Self:PlayGlobalEffect{id = 1000121};
					end,
				},	
			},
		},	
	},	
}
skills["Stun"] =
{
	name = "Stun",
	
	IsReady = function(this)
		return true;
	end, 
	
	Enter = function(this)
		Self:SetMoveSpeed(0);
	end,
	
	Leave = function(this)
	end,
	
	Actions = 
	{
		["Stun"] =
		{
			name = "Stun",
			loop = true,
			stance = "stun",
			weapon = 0,
			switch = 0,
			priority = 0,
			nextAction = "Idle",
			
			IsReady = function(this)
				return true;
			end,
			
			Events = 
			{
			    ["Sound"] = 
		     	{
					time = 0.0,
					Func = function(this)
						
					end,
		    	},	
            },
		},	
	},	
}
SkillCtrl[200011] =
{
	CtrlEvent = function(this, eventName)
		if eventName == "SkillEnter" then
			this.useTime = 0.0;
			this.waitingLeave = 0.3;
		end
		
		if eventName == "SkillLeave" then
			this:Stop();
			this.switching = false;
			Self:DebugPrint("ctrl event skillleave");
		end
	end,
	
	UpdateCtrl = function(this, actionName)
		this.useTime = this.useTime + Self:TimeDelta();
		
		if this.switching then
			return;
		end
		
		--���ƽ�ɫ���ƶ���ֹͣ
		if Ctrl:IsKeyboardRun() then
			Ctrl:TurnToKeyboardDir(false);
			Self:SetMoveSpeed(PlayerConfig.MoveSpeed);
			this.isMoving = true;
			Self:DebugPrint("ctrl event move");
		elseif this.isMoving then
			this:Stop();
		end
		
		if not Self:IsMouseRDown() then
			this.waitingLeave = this.waitingLeave - Self:TimeDelta();
			if this.waitingLeave < 0.0 then
				this:Stop();
				this.switching = true;
				Ctrl:PlayAction("Idle");
			end
		else
			this.waitingLeave = 0.3;
		end
	end,	
	
	Stop = function(this)
		Self:SetMoveSpeed(0);
		Ctrl:StopMove();
		this.isMoving = false;
		Self:DebugPrint("ctrl event stop move");
	end,
}
SkillCtrl[200012] =
{
	CtrlEvent = function(this, eventName)
		if eventName == "SkillEnter" then
			this.useTime = 0.0;
			this.waitingLeave = 0.3;
		end
		
		if eventName == "SkillLeave" then
			this:Stop();
			this.switching = false;
			Self:DebugPrint("ctrl event skillleave");
		end
	end,
	
	UpdateCtrl = function(this, actionName)
		this.useTime = this.useTime + Self:TimeDelta();
		
		if this.switching then
			return;
		end
		
		--���ƽ�ɫ���ƶ���ֹͣ
		if Ctrl:IsKeyboardRun() then
			Ctrl:TurnToKeyboardDir(false);
			Self:SetMoveSpeed(PlayerConfig.MoveSpeed);
			this.isMoving = true;
			Self:DebugPrint("ctrl event move");
		elseif this.isMoving then
			this:Stop();
		end
		
		if not Self:IsMouseRDown() then
			this.waitingLeave = this.waitingLeave - Self:TimeDelta();
			if this.waitingLeave < 0.0 then
				this:Stop();
				this.switching = true;
				Ctrl:PlayAction("Idle");
			end
		else
			this.waitingLeave = 0.3;
		end
	end,	
	
	Stop = function(this)
		Self:SetMoveSpeed(0);
		Ctrl:StopMove();
		this.isMoving = false;
		Self:DebugPrint("ctrl event stop move");
	end,
}
SkillCtrl[200010] =
{
	CtrlEvent = function(this, eventName)
		if eventName == "SkillEnter" then
			this.useTime = 0.0;
			this.waitingLeave = 0.3;
		end
		
		if eventName == "SkillLeave" then
			this:Stop();
			this.switching = false;
			Self:DebugPrint("ctrl event skillleave");
		end
	end,
	
	UpdateCtrl = function(this, actionName)
		this.useTime = this.useTime + Self:TimeDelta();
		
		if this.switching then
			return;
		end
		
		--���ƽ�ɫ���ƶ���ֹͣ
		if Ctrl:IsKeyboardRun() then
			Ctrl:TurnToKeyboardDir(false);
			Self:SetMoveSpeed(PlayerConfig.MoveSpeed);
			this.isMoving = true;
			Self:DebugPrint("ctrl event move");
		elseif this.isMoving then
			this:Stop();
		end
		
		if not Self:IsMouseRDown() then
			this.waitingLeave = this.waitingLeave - Self:TimeDelta();
			if this.waitingLeave < 0.0 then
				this:Stop();
				this.switching = true;
				Ctrl:PlayAction("Idle");
			end
		else
			this.waitingLeave = 0.3;
		end
	end,	
	
	Stop = function(this)
		Self:SetMoveSpeed(0);
		Ctrl:StopMove();
		this.isMoving = false;
		Self:DebugPrint("ctrl event stop move");
	end,
}
SkillCtrl["Dash"] =
{
	CtrlEvent = function(this, eventName)
		if eventName == "SkillEnter" then
			this.useTime = 0.0;
			this.waitingLeave = 0.3;
		end
		
		if eventName == "SkillLeave" then
			this:Stop();
			this.switching = false;
			Self:DebugPrint("ctrl event skillleave");
		end
	end,
	
	UpdateCtrl = function(this, actionName)
		this.useTime = this.useTime + Self:TimeDelta();
		
		if this.switching then
			return;
		end
		
		--���ƽ�ɫ���ƶ���ֹͣ
		if Ctrl:IsKeyboardRun() then
			Ctrl:TurnToKeyboardDir(false);
			Self:SetMoveSpeed(3);
			this.isMoving = true;
			Self:DebugPrint("ctrl event move");
		elseif this.isMoving then
			this:Stop();
		end
		
		if not Self:IsMouseRDown() then
			this.waitingLeave = this.waitingLeave - Self:TimeDelta();
			if this.waitingLeave < 0.0 then
				this:Stop();
				this.switching = true;
				Ctrl:PlayAction("Idle");
			end
		else
			this.waitingLeave = 0.3;
		end
	end,	
	
	Stop = function(this)
		Self:SetMoveSpeed(0);
		Ctrl:StopMove();
		this.isMoving = false;
		Self:DebugPrint("ctrl event stop move");
	end,
}

SkillCtrl["Gather"] =
{
	CtrlEvent = function(this, eventName)
		if eventName == "SkillEnter" then
			this.isUpdate = true;
		end
	end,
	
	UpdateCtrl = function(this, actionName)
		
		Self:DebugPrint("gather update ctrl");
		
		if this.isUpdate == false then
			return;
		end
		
		Self:DebugPrint("gather 2");
		
		Config.gatherTime = Config.gatherTime - Self:TimeDelta();
		if Config.gatherTime <= 0.0 then
			Self:DebugPrint("gather 3:" .. Config.gatherTarget);
			Self:SendGatherObject(Config.gatherTarget);
			this.isUpdate = false;
		end
	end,	
}

SkillCtrl["Idle"] =
{
	UpdateCtrl = function(this)
		Ctrl:UpdateIdle(this);
	end,	
}

SkillCtrl["Run"] =
{
	UpdateCtrl = function(this)
		Ctrl:UpdateRun();
	end,	
}
SkillCtrl["Shoot"] =
{
	CtrlEvent = function(this, eventName)
		if eventName == "SkillEnter" then
			this.useTime = 0.0;
			this.waitingLeave = 0.3;
		end
		
		if eventName == "SkillLeave" then
			this:Stop();
			this.switching = false;
			Self:DebugPrint("ctrl event skillleave");
		end
	end,
	
	UpdateCtrl = function(this, actionName)
		this.useTime = this.useTime + Self:TimeDelta();
		
		if this.switching then
			return;
		end
		
		--���ƽ�ɫ���ƶ���ֹͣ
		if Ctrl:IsKeyboardRun() then
			Ctrl:TurnToKeyboardDir(false);
			Self:SetMoveSpeed(3);
			this.isMoving = true;
			Self:DebugPrint("ctrl event move");
		elseif this.isMoving then
			this:Stop();
		end
		
		if not Self:IsMouseRDown() then
			this.waitingLeave = this.waitingLeave - Self:TimeDelta();
			if this.waitingLeave < 0.0 then
				this:Stop();
				this.switching = true;
				Ctrl:PlayAction("Idle");
			end
		else
			this.waitingLeave = 0.3;
		end
	end,	
	
	Stop = function(this)
		Self:SetMoveSpeed(0);
		Ctrl:StopMove();
		this.isMoving = false;
		Self:DebugPrint("ctrl event stop move");
	end,
}
