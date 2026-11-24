--The Rose of Vampire Castle Token
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--(1) Cannot be used as Fusion, Synchro, or Link Material, except for a "Vampire" monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(444001050,6))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e1:SetValue(s.matlimit)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e2)
	local e3=e1:Clone()
	e3:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e3)
end
s.listed_series={0x8e}
--(1) Cannot be used as Fusion, Synchro, or Link Material, except for a "Vampire" monster
function s.matlimit(e,c)
	if not c then return false end
	return not c:IsSetCard(0x8e)
end
