--The Gardener of Vampire Castle
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--(1) Tribute Summon this card by Tributing 1 monster
	aux.AddNormalSummonProcedure(c,true,true,1,1,SUMMON_TYPE_TRIBUTE,aux.Stringid(id,0))
	--(2) Reveal this card and Normal Summon it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,{id,0})
	e2:SetCost(s.sumcost)
	e2:SetTarget(s.sumtg)
	e2:SetOperation(s.sumop)
	c:RegisterEffect(e2)
	--(3) Special Summon 1 "The Rose of Vampire Castle Token" to either field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.tktg)
	e3:SetOperation(s.tkop)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)
	--(4) Change an attacking opponent's monster's ATK/DEF to 0 and banish this card
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_ATTACK_ANNOUNCE)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.atkcon)
	e4:SetCost(s.atkcost)
	e4:SetTarget(s.atktg)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)
end
s.listed_names={444001051}
s.listed_series={0x8e,0x208e}
--(1) Tribute Summon this card by Tributing 1 monster
--Handled by aux.AddNormalSummonProcedure
--(2) Reveal this card and Normal Summon it
function s.sumcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
	Duel.ShuffleHand(tp)
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSummonable(true,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,c,1,tp,LOCATION_HAND)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSummonable(true,nil) then Duel.Summon(tp,c,true,nil) end
end
--(3) Special Summon 1 "The Rose of Vampire Castle Token" to either field
function s.cantoken(tp,p)
	return Duel.GetLocationCount(p,LOCATION_MZONE,tp)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,444001051,0x208e,TYPES_TOKEN|TYPE_TUNER,0,0,2,RACE_PLANT,ATTRIBUTE_EARTH,POS_FACEUP,p)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.cantoken(tp,tp) or s.cantoken(tp,1-tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	local b1=s.cantoken(tp,tp)
	local b2=s.cantoken(tp,1-tp)
	if not b1 and not b2 then return end
	local p=tp
	if b1 and b2 then
		local op=Duel.SelectOption(tp,aux.Stringid(id,4),aux.Stringid(id,5))
		p=op==0 and tp or 1-tp
	elseif b2 then
		p=1-tp
	end
	local token=Duel.CreateToken(tp,444001051)
	Duel.SpecialSummon(token,0,tp,p,false,false,POS_FACEUP)
end
--(4) Change an attacking opponent's monster's ATK/DEF to 0 and banish this card
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	return tc and tc:IsControler(1-tp)
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=Duel.GetAttacker()
	if chk==0 then return tc and tc:IsFaceup() and (tc:GetAttack()~=0 or tc:HasDefense() and tc:GetDefense()~=0) end
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,tc,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,tp,LOCATION_GRAVE)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetAttacker()
	if not tc or not tc:IsRelateToBattle() or not tc:IsFaceup() or tc:IsImmuneToEffect(e) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetValue(0)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e1)
	if tc:HasDefense() then
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
		tc:RegisterEffect(e2)
	end
	if c:IsRelateToEffect(e) then Duel.Remove(c,POS_FACEUP,REASON_EFFECT) end
end
