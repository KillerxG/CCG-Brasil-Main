--Vampire Hunter - Bloodlines
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--(1) Activate 1 of these effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.actcost)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	--(2) Banish 1 other "Vampire" card or 1 Zombie monster from the GY to recover this card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,0})
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_names={80485722}
s.listed_series={0x8e,0x108e}
--(1) Activate 1 of these effects
function s.ritualfilter(c)
	return c:IsSetCard(0x108e) and c:IsRitualMonster()
end
function s.matfilter(c,e,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND|LOCATION_MZONE)
end
function s.directfilter(c,e,tp)
	return s.ritualfilter(c) and Duel.CheckLPCost(tp,c:GetLevel()*500)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end
function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local params={handler=e:GetHandler(),lvtype=RITPROC_GREATER,filter=s.ritualfilter,location=LOCATION_HAND|LOCATION_GRAVE,matfilter=s.matfilter}
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.directfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
	local b2=Ritual.Target(params)(e,tp,eg,ep,ev,re,r,rp,0)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)},
		{b2,aux.Stringid(id,2)})
	e:SetLabel(op)
	if op==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local g=Duel.SelectMatchingCard(tp,s.directfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
		local tc=g:GetFirst()
		e:SetLabelObject(tc)
		Duel.ConfirmCards(1-tp,g)
		Duel.PayLPCost(tp,tc:GetLevel()*500)
		Duel.ShuffleHand(tp)
	else
		e:SetLabelObject(nil)
	end
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	if e:GetLabel()==1 then
		local tc=e:GetLabelObject()
		tc:CreateEffectRelation(e)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,tp,LOCATION_HAND)
	else
		local params={handler=e:GetHandler(),lvtype=RITPROC_GREATER,filter=s.ritualfilter,location=LOCATION_HAND|LOCATION_GRAVE,matfilter=s.matfilter}
		Ritual.Target(params)(e,tp,eg,ep,ev,re,r,rp,1)
	end
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()==1 then
		local tc=e:GetLabelObject()
		if tc and tc:IsRelateToEffect(e) and tc:IsControler(tp) and tc:IsLocation(LOCATION_HAND)
			and tc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
			and Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
		end
		e:SetLabelObject(nil)
	else
		local params={handler=e:GetHandler(),lvtype=RITPROC_GREATER,filter=s.ritualfilter,location=LOCATION_HAND|LOCATION_GRAVE,matfilter=s.matfilter}
		Ritual.Operation(params)(e,tp,eg,ep,ev,re,r,rp)
	end
end
--(2) Banish 1 other "Vampire" card or 1 Zombie monster from the GY to recover this card
function s.costfilter(c)
	return (c:IsSetCard(0x8e) or c:IsCode(80485722) or c:IsRace(RACE_ZOMBIE)) and c:IsAbleToRemoveAsCost()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
