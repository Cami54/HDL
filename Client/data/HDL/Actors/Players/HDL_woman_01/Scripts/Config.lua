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