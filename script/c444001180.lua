--Vampire Hunter - Cursed Daughter
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
	--(2) Negate 1 face-up opponent's card, then optionally banish 1 card from their GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
	--(3) Grant battle destruction protection to your "Vampire Hunter" Ritual Monsters
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.prcon)
	e3:SetTarget(s.prtg)
	e3:SetOperation(s.prop)
	c:RegisterEffect(e3)
end
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
--(2) Negate 1 face-up opponent's card, then optionally banish 1 card from their GY
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsRitualSummoned()
end
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and s.negfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,1-tp,LOCATION_ONFIELD)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_GRAVE)
end
function s.rmfilter(c)
	return c:IsAbleToRemove()
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup()
		or tc:IsDisabled() or tc:IsImmuneToEffect(e) then return end
	tc:NegateEffects(e:GetHandler(),RESET_PHASE|PHASE_END)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_GRAVE,nil)
	if #g==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,4)) then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=g:Select(tp,1,1,nil)
	Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
end
--(3) Grant battle destruction protection to your "Vampire Hunter" Ritual Monsters
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
function s.indval(e,re,r,rp)
	return (r&REASON_BATTLE)~=0 and 1 or 0
end
function s.prop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	local e1=Effect.CreateEffect(tc)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.protectfilter)
	e1:SetValue(s.indval)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
end
