Config =
{
	isMain = false,
	normalSkill = 1111011,
	rightSkill = 0,	
	rigidTime =0,
	
	--���������õ��ƶ��ٶ�
	moveSpeed = 2.0,
	--�����������ٶ�
	jumpSpeed = 5.0,
	--���������õ�ս��̬
	isBattleState = true,
	InitEffect = {602900,},	
	--�����ƶ�
	Run = 
	{
		--�����ص�ʱ��
		leftStepEventTime = nil,
		--�����ص���Ч
		leftStepSound = nil,
		--�����ص�ʱ��
		rightStepEventTime = nil,
		--�ҽŲ���ص���Ч
		rightStepSound = nil,	
	},
	
	--�����ƶ�
	Walk =
	{
		--�����ص�ʱ��
		leftStepEventTime = nil,
		--�����ص���Ч
		leftStepSound = nil,
		--�����ص�ʱ��
		rightStepEventTime = nil,
		--�ҽŲ���ص���Ч
		rightStepSound = nil,
	},
	
	--����
	BlowOff =
	{
		--���ʱ����Ч
		downEffect = 0,
	},
	
	--[[��ͨ����1
	Attack1 =
	{
		skillID = "Attack1",	
		
		Attack1 =
		{
			time = 0.37,
			effectID = 10000,	
		},
		
		SwordLight1 = 
		{
			startTime = 0.31,
			endTime = 0.60,
			tex = "TrailLight/Textures/MUX_Trail08.dds",	
		},
		
		Attack2 =
		{
			time = nil,
			effectID = nil,	
		},
		
		SwordLight2 = 
		{
			startTime = nil,
			endTime = nil,
			tex = nil,	
		},
		
		Sound = 
		{
			time = 0.17,
			sound = "m_goblin_g_atk01.wav",	
		},
	},
	
	--��ͨ����2
	Attack2 =
	{
		skillID = "Attack2",	
		
		Attack1 =
		{
			time = 0.37,
			effectID = 11110112,	
		},
		
		SwordLight1 = 
		{
			startTime = 0.62,
			endTime = 0.78,
			tex = "TrailLight/Textures/MUX_Trail08.dds",	
		},
		
		Attack2 =
		{
			time = 1.0,
			effectID = 11110112,	
		},
		
		SwordLight2 = 
		{
			startTime = 1.64,
			endTime = 1.78,
			tex = "TrailLight/Textures/MUX_Trail08.dds",	
		},
		
		Sound = 
		{
			time = 0.17,
			sound = "atk-hammer-01.wav",	
		},
	},
	]]
}