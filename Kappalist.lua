if(myHero.charName ~= "Kalista") then return end

local Config = MenuElement({type = MENU, name = "Kappalista", id = "Kalista", leftIcon = "http://ddragon.leagueoflegends.com/cdn/7.6.1/img/champion/Kalista.png"})

-- Q Settings
--Config:MenuElement({type = MENU, name = "Q Settings", id = "Q"}) kek, too lazy to finish this

-- E Settings
Config:MenuElement({type = MENU, name = "E Settings", id = "E"})
Config.E:MenuElement({type = MENU, name = "Combo", id = "Combo"})
Config.E.Combo:MenuElement({name = "Enabled", id = "Enabled", value = true})
Config.E.Combo:MenuElement({name = "E if target getting Out of E Range", id = "OutOfRange", value = true})
Config.E.Combo:MenuElement({name = "Only E When can Reset Cooldown", id = "EReset", value = true})
Config.E.Combo:MenuElement({name = "Min Stacks for E", id = "Count", value = 3, min = 1, max = 15})

Config.E:MenuElement({type = MENU, name = "Lane Clear", id = "Lane"})
Config.E.Lane:MenuElement({name = "Enabled", id = "Enabled", value = true})
Config.E.Lane:MenuElement({name = "Minion Secure Count", id = "Count", value = 2, min = 1, max = 10})

Config.E:MenuElement({type = MENU, name = "Kill Steal", id = "KS"})
Config.E.KS:MenuElement({name = "Auto KS Enemies", id = "Enabled", value = true})

Config.E:MenuElement({type = MENU, name = "Jungle Steal", id = "JS"})
Config.E.JS:MenuElement({name = "Steal Baron", id = "Baron", value = true})
Config.E.JS:MenuElement({name = "Steal RiftHerald", id = "Rift", value = true})
Config.E.JS:MenuElement({name = "Steal Dragon", id = "Dragon", value = true})
Config.E.JS:MenuElement({name = "Steal Red", id = "Red", value = true})
Config.E.JS:MenuElement({name = "Steal Blue", id = "Blue", value = true})

Config.E:MenuElement({name = "Draw Damage", id = "Draw", value = true})
Config.E:MenuElement({name = "Draw Range", id = "Range", value = true})
Config.E:MenuElement({name = "Draw Color", id = "Color", color = Draw.Color(255, 173, 255, 47)})


-- Spells
local E = { range = 1000, delay = 200, IsReady = function() return Game.CanUseSpell(_E) == READY end }


-- Global variables
local EStackName = "kalistaexpungemarker"

function GetERawDamage(unit)
	if(myHero:GetSpellData(_E).level == 0 or unit == nil) then
		return 0
	end

	local basedmg = 10 + (10 * myHero:GetSpellData(_E).level) + 0.6 * myHero.totalDamage
	local perStackArray = { 10, 14, 19, 25, 32 }
	local perStackdmg = perStackArray[myHero:GetSpellData(_E).level - 1]
	local perStackMod = (0.2 + (0.025 * myHero:GetSpellData(_E).level)) * myHero.totalDamage
	local stacks = GetRendCount(unit) - 1
	local currentDamage = (basedmg + (stacks * (perStackdmg + perStackMod))) * 0.54

	return currentDamage
end

function GetEDamage(unit)
	if(myHero:GetSpellData(_E).level == 0 or unit == nil or GetRendCount(unit) < 1 or _G.SDK.Utilities:IsValidTarget(unit) == false) then
		return 0
	end

	return _G.SDK.Damage:CalculateDamage(myHero, unit, DAMAGE_TYPE_PHYSICAL, GetERawDamage(unit))
end

function GetRendCount(unit)
	return _G.SDK.BuffManager:GetBuffCount(unit, EStackName)
end

function unitIsKillable(unit)
	if(unit == nil) then
		return false
	end

	return GetEDamage(unit) > unit.health
end

function KillableHerosInRange(count)
	if(count == nil) then
		count = 1
	end

	local enemies = _G.SDK.ObjectManager:GetEnemyHeroes(E.range)
	local x = 0
	for i = 0, #enemies do
		local enemy = enemies[i]
		if(unitIsKillable(enemies[i]) and GetRendCount(enemy) >= count) then
			x = x + 1
		end
	end
	return x
end

function KillableMinionsInRange()
	local enemies = _G.SDK.ObjectManager:GetEnemyMinions(E.range)
	local x = 0
	for i = 0, #enemies do
		local enemy = enemies[i]
		if(unitIsKillable(enemies[i])) then
			x = x + 1
		end
	end
	return x
end

function MobIsKillable(name)
	local monsters = _G.SDK.ObjectManager:GetMonsters(E.range)
	local x = 0
	for i = 0, #monsters do
		local enemy = monsters[i]
		if(enemy ~= nil and startWith(enemy.charName, name) and unitIsKillable(enemy)) then
			x = x + 1
			break
		end
	end
	return x > 0
end

function startWith(String, Start)
   return string.sub(String,1,string.len(Start))==Start
end


local lastECast = 1
function CanCastE()
	return GetTickCount() - lastECast > 250 and E.IsReady()
end

function CastE()
	if(CanCastE()) then
		lastECast = GetTickCount()
		Control.KeyDown(HK_E)
		Control.KeyUp(HK_E)
	end
end

-- Modes
local Combo = function()
	if(Config.E.Combo.Enabled:Value() and CanCastE()) then
		local willReset = Config.E.Combo.EReset:Value() == false or KillableHerosInRange() > 0 or KillableMinionsInRange() > 0
		if(willReset) then
			local target = _G.SDK.Orbwalker:GetTarget()

			if(Config.E.Combo.OutOfRange:Value() and target ~= nil) then
				if(_G.SDK.Utilities:GetDistance(myHero, target) >= _G.SDK.Utilities:GetAutoAttackRange(myHero, target) - 30) then
					CastE()
				end
			end

			if(KillableHerosInRange(Config.E.Combo.Count:Value()) > 0) then
				CastE()
			end
		end
	end
end

local Clear = function()
	if(Config.E.Lane.Enabled:Value() and CanCastE()) then
		if(KillableMinionsInRange() >= Config.E.Lane.Count:Value()) then
			CastE()
		end
	end
end

local Jungle = function()
end

-- Events
local OnDraw = function()
	if(Config.E.Range:Value()) then
		Draw.Circle(myHero.pos, E.range, 3, Config.E.Color:Value())
	end

	if(Config.E.Draw:Value()) then
		local heros = _G.SDK.ObjectManager:GetEnemyHeroes(E.Range)
		for i = 0, #heros do
			local unit = heros[i]
			if(_G.SDK.Utilities:IsValidTarget(unit) and GetRendCount(unit) > 0) then
				Draw.Text(math.floor(GetEDamage(unit)).."/"..math.floor(unit.health), unit.pos:To2D())
			end
		end

		local minions = _G.SDK.ObjectManager:GetEnemyMinions(E.Range)
		for i = 0, #minions do
			local unit = minions[i]
			if(_G.SDK.Utilities:IsValidTarget(unit) and GetRendCount(unit) > 0) then
				Draw.Text(math.floor(GetEDamage(unit)).."/"..math.floor(unit.health), unit.pos:To2D())
			end
		end

		local monsters = _G.SDK.ObjectManager:GetMonsters(E.Range)
		for i = 0, #monsters do
			local unit = monsters[i]
			if(_G.SDK.Utilities:IsValidTarget(unit) and GetRendCount(unit) > 0) then
				Draw.Text(math.floor(GetEDamage(unit)).."/"..math.floor(unit.health), unit.pos:To2D())
			end
		end
	end
end

local OnTick = function()
	if(myHero.dead) then
	 return
	 end

	 if(CanCastE()) then
	 	if(Config.E.KS.Enabled:Value()) then
			if(KillableHerosInRange() > 0) then
				CastE()
			end
		end
		if(Config.E.JS.Baron:Value()) then
			if(MobIsKillable("SRU_Baron")) then
				CastE()
			end
		end
		if(Config.E.JS.Dragon:Value()) then
			if(MobIsKillable("SRU_Dragon")) then
				CastE()
			end
		end
		if(Config.E.JS.Red:Value()) then
			if(MobIsKillable("SRU_Red")) then
				CastE()
			end
		end
		if(Config.E.JS.Blue:Value()) then
			if(MobIsKillable("SRU_Blue")) then
				CastE()
			end
		end
		if(Config.E.JS.Rift:Value()) then
			if(MobIsKillable("SRU_RiftHerald")) then
				CastE()
			end
		end
	end

	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then 
		Combo()
	end

	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then 
		Clear()
	end
	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then 
		Jungle()
	end
end

Callback.Add("Tick", function() OnTick() end)
Callback.Add("Draw", function() OnDraw() end)