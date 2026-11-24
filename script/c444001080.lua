-- The Bartender of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e

function s.initial_effect(c)
	-- 1. If you control no monsters: Reveal in hand; Normal Summon this card (HOPT)
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

	-- 2. Add 1 "Vampire" monster from Deck or GY to hand, and if you do, Normal Summon it (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, {id, 1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 3. Each time a "Vampire" monster is Summoned to your field, gain 500 LP (Only 1 applies at a time)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.lpcon)
	e3:SetOperation(s.lpop)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)
	local e3c=e3:Clone()
	e3c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e3c)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}

-- ==========================================
-- 1. REVEAL & NORMAL SUMMON IF NO MONSTERS
-- ==========================================
function s.normcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetFieldGroupCount(tp, LOCATION_MZONE, 0)==0
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
-- 2. ADD "VAMPIRE" FROM DECK/GY & NORMAL SUMMON
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(SET_VAMPIRE) and c:IsMonster() and c:IsAbleToHand() and c:IsSummonable(true, nil)
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK+LOCATION_GRAVE, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, nil, 1, tp, LOCATION_HAND)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.thfilter), tp, LOCATION_DECK+LOCATION_GRAVE, 0, 1, 1, nil)
	local tc=g:GetFirst()
	if tc and Duel.SendtoHand(tc, nil, REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp, tc)
		if tc:IsSummonable(true, nil) then
			Duel.ShuffleHand(tp)
			Duel.BreakEffect()
			Duel.Summon(tp, tc, true, nil)
		end
	end
end

-- ==========================================
-- 3. GAIN 500 LP ON "VAMPIRE" SUMMON (ONLY 1 COPY APPLIES)
-- ==========================================
function s.lpfilter(c, tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(SET_VAMPIRE)
end

function s.lpcon(e, tp, eg, ep, ev, re, r, rp)
	if not eg:IsExists(s.lpfilter, 1, nil, tp) then return false end
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode, id), tp, LOCATION_MZONE, 0, nil)
	if #g==0 then return false end
	local mg=g:GetMinGroup(Card.GetFieldID)
	return mg:IsContains(e:GetHandler())
end

function s.lpop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_CARD, 0, id)
	Duel.Recover(tp, 500, REASON_EFFECT)
end