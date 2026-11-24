-- The Maid of Vampire Castle
local s, id = GetID()

function s.initial_effect(c)
	-- 1. If a "Vampire" monster(s) you control is sent to the GY or banished: Reveal in hand; Normal Summon/Set this card (HOPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.sumcon)
	e1:SetCost(s.sumcost)
	e1:SetTarget(s.sumtg)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e1b)

	-- 2. (Quick Effect): Target 1 Spell/Trap opponent controls; add to your hand or Set to your field (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0, TIMING_MAIN_END+TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1, {id, 1})
	e2:SetTarget(s.sttg)
	e2:SetOperation(s.stop)
	c:RegisterEffect(e2)
end

s.listed_series={0x8e, 0x208e}

-- ==========================================
-- 1. NORMAL SUMMON / SET WHEN VAMPIRE IS SENT TO GY OR BANISHED
-- ==========================================
function s.cfilter(c, tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousSetCard(0x8e)
		and c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.sumcon(e, tp, eg, ep, ev, re, r, rp)
	return eg:IsExists(s.cfilter, 1, nil, tp)
end

function s.sumcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp, c)
	Duel.ShuffleHand(tp)
end

function s.sumtg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSummonable(true, nil) or c:IsMSetable(true, nil) end
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, c, 1, 0, 0)
end

function s.sumop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1=c:IsSummonable(true, nil)
	local b2=c:IsMSetable(true, nil)
	if not (b1 or b2) then return end

	local op=Duel.SelectEffect(tp,
		{b1, aux.Stringid(id, 2)},
		{b2, aux.Stringid(id, 3)})
	if op==1 then
		Duel.Summon(tp, c, true, nil)
	else
		Duel.MSet(tp, c, true, nil)
	end
end

-- ==========================================
-- 2. STEAL OPPONENT'S SPELL/TRAP (HAND OR SET)
-- ==========================================
function s.can_set(c, tp)
	if c:IsFieldSpell() then
		return true
	end
	return Duel.GetLocationCount(tp, LOCATION_SZONE)>0
end

function s.stfilter(c, tp)
	return c:IsSpellTrap() and (c:IsAbleToHand(tp) or s.can_set(c, tp))
end

function s.sttg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and s.stfilter(chkc, tp) end
	if chk==0 then return Duel.IsExistingTarget(s.stfilter, tp, 0, LOCATION_ONFIELD, 1, nil, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp, s.stfilter, tp, 0, LOCATION_ONFIELD, 1, 1, nil, tp)
	Duel.SetPossibleOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
	Duel.SetChainLimit(s.chainlm(g:GetFirst()))
end

function s.chainlm(tc)
	return function(e, rp, tp)
		return e:GetHandler()~=tc
	end
end

function s.stop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsControler(1-tp) then return end

	local b1=tc:IsAbleToHand(tp)
	local b2=s.can_set(tc, tp)
	if not (b1 or b2) then return end

	local op=Duel.SelectEffect(tp,
		{b1, aux.Stringid(id, 4)},
		{b2, aux.Stringid(id, 5)})
	if op==1 then
		Duel.SendtoHand(tc, tp, REASON_EFFECT)
		Duel.ConfirmCards(1-tp, tc)
	else
		-- Removido o bloco Duel.ChangePosition que causava a animação dupla
		local loc = tc:IsFieldSpell() and LOCATION_FZONE or LOCATION_SZONE
		if loc==LOCATION_FZONE then
			local fc=Duel.GetFieldCard(tp, LOCATION_FZONE, 0)
			if fc then
				Duel.SendtoGrave(fc, REASON_RULE)
				Duel.BreakEffect()
			end
		end
		-- MoveToField já a coloca em POS_FACEDOWN no seu lado do campo
		if Duel.MoveToField(tc, tp, tp, loc, POS_FACEDOWN, true) then
			tc:SetStatus(STATUS_SET_TURN, true)
			Duel.RaiseEvent(tc, EVENT_SSET, e, REASON_EFFECT, tp, tp, 0)
		end
	end
end