-- The Researcher of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e
local TOKEN_PET = id + 1 -- 444001071

function s.initial_effect(c)
	-- 1. If you control a "Vampire" monster: Reveal in hand; Normal Summon this card (HOPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.normcon)
	e1:SetCost(s.normcost)
	e1:SetTarget(s.normtg)
	e1:SetOperation(s.normop)
	c:RegisterEffect(e1)

	-- 2. If this card leaves the field: Special Summon 1 "The Pet of Vampire Castle Token" (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1, {id, 1})
	e2:SetCondition(s.tkcon)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)

	-- 3. Each time a "Vampire" monster is Normal/Special Summoned to your field: Inflict 300 damage (Only 1 applies at a time)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.burncon)
	e3:SetTarget(s.burntg)
	e3:SetOperation(s.burnop)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}
s.listed_names={TOKEN_PET}

-- ==========================================
-- 1. REVEAL & NORMAL SUMMON
-- ==========================================
function s.normcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard, SET_VAMPIRE), tp, LOCATION_MZONE, 0, 1, nil)
end

function s.normcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp, c)
	Duel.ShuffleHand(tp)
end

function s.normtg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSummonable(true, nil) end
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, c, 1, 0, 0)
end

function s.normop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSummonable(true, nil) then
		Duel.Summon(tp, c, true, nil)
	end
end

-- ==========================================
-- 2. SPECIAL SUMMON TOKEN WITH LEVEL EFFECT
-- ==========================================
function s.tkcon(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.tktg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.GetLocationCount(tp, LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp, TOKEN_PET, SET_VAMPIRE_CASTLE, TYPES_TOKEN+TYPE_TUNER, 0, 0, 1, RACE_BEAST, ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0, CATEGORY_TOKEN, nil, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, 0)
end

function s.tkop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE)<=0 then return end
	if Duel.IsPlayerCanSpecialSummonMonster(tp, TOKEN_PET, SET_VAMPIRE_CASTLE, TYPES_TOKEN+TYPE_TUNER, 0, 0, 1, RACE_BEAST, ATTRIBUTE_DARK) then
		local token=Duel.CreateToken(tp, TOKEN_PET)
		if Duel.SpecialSummonStep(token, 0, tp, tp, false, false, POS_FACEUP) then
			-- Up to thrice per turn: Target 1 face-up monster; increase or decrease its Level by 1
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(aux.Stringid(id, 3))
			e1:SetCategory(CATEGORY_LVCHANGE)
			e1:SetType(EFFECT_TYPE_IGNITION)
			e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CLIENT_HINT)
			e1:SetRange(LOCATION_MZONE)
			e1:SetCountLimit(3)
			e1:SetTarget(s.lvtg)
			e1:SetOperation(s.lvop)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1, true)
		end
		Duel.SpecialSummonComplete()
	end
end

function s.lvfilter(c)
	return c:IsFaceup() and c:HasLevel()
end

function s.lvtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.lvfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.lvfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp, s.lvfilter, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_LVCHANGE, g, 1, 0, 1)
end

function s.lvop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:HasLevel() then
		local b1=true
		local b2=tc:IsLevelAbove(2)
		local op=Duel.SelectEffect(tp,
			{b1, aux.Stringid(id, 4)},
			{b2, aux.Stringid(id, 5)})
		local val = (op==1) and 1 or -1
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(val)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- ==========================================
-- 3. BURN 300 ON "VAMPIRE" SUMMON (ONLY 1 COPY APPLIES)
-- ==========================================
function s.vfilter(c, tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(SET_VAMPIRE)
end

function s.burncon(e, tp, eg, ep, ev, re, r, rp)
	if not eg:IsExists(s.vfilter, 1, nil, tp) then return false end
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode, id), tp, LOCATION_MZONE, 0, nil)
	if #g==0 then return false end
	local mg=g:GetMinGroup(Card.GetFieldID)
	return mg:IsContains(e:GetHandler())
end

function s.burntg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(300)
	Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1-tp, 300)
end

function s.burnop(e, tp, eg, ep, ev, re, r, rp)
	local p, d=Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Damage(p, d, REASON_EFFECT)
end