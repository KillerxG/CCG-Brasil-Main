--Vampire Hunter - Tragic Prince, Alucard
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--(1) Reveal this card and Ritual Summon it
	local params={lvtype=RITPROC_GREATER,filter=function(rc) return rc==c end,matfilter=s.matfilter}
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(s.ritcost)
	e1:SetTarget(Ritual.Target(params))
	e1:SetOperation(Ritual.Operation(params))
	c:RegisterEffect(e1)
	--(2) Gains 500 ATK for each "Vampire Hunter" monster in your GY or banishment
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	--(3) Inflict piercing battle damage
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e3)
	--(4) Grant Tribute protection to your "Vampire Hunter" Ritual Monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCondition(s.prcon)
	e4:SetTarget(s.prtg)
	e4:SetOperation(s.prop)
	c:RegisterEffect(e4)
end
s.listed_names={80485722}
s.listed_series={0x8e,0x108e}
--(1) Reveal this card and Ritual Summon it
function s.ritcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
	Duel.ShuffleHand(tp)
end
function s.matfilter(c,e,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND|LOCATION_MZONE)
end
--(2) Gains 500 ATK for each "Vampire Hunter" monster in your GY or banishment
function s.atkfilter(c)
	return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsMonster()
		and (c:IsSetCard(0x108e) or c:IsCode(80485722))
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,e:GetHandlerPlayer(),LOCATION_GRAVE|LOCATION_REMOVED,0,nil)*500
end
--(3) Inflict piercing battle damage
--Handled by EFFECT_PIERCE
--(4) Grant Tribute protection to your "Vampire Hunter" Ritual Monsters
function s.prcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsRitualSummoned()
end
function s.prfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x108e) and c:IsRitualMonster()
end
function s.prtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.prfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.prfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.prfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,0,g,1,tp,LOCATION_MZONE)
end
function s.protectfilter(e,c)
	return c:IsFaceup() and c:IsSetCard(0x108e) and c:IsRitualMonster()
end
function s.rellimit(e,c)
	return c and c:IsControler(1-e:GetHandlerPlayer())
end
function s.prop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	local e1=Effect.CreateEffect(tc)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_UNRELEASABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.protectfilter)
	e1:SetValue(s.rellimit)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
end
