-- The Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e

function s.initial_effect(c)
	-- 1. When this card is activated: You can add 1 "Vampire" monster from your Deck to your hand (HOPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Once per turn, if you would pay LP to activate a "Vampire" card or effect, send 1 "Vampire" card from Deck to GY instead (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_LPCOST_REPLACE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1, {id, 1})
	e2:SetCondition(s.lrcon)
	e2:SetOperation(s.lrop)
	c:RegisterEffect(e2)

	-- 3. Target 1 "Vampire" card in your GY or banishment; return to Deck (or GY, if banished), then you can destroy 1 "Vampire" card in hand or field (HOPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_TOGRAVE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1, {id, 2})
	e3:SetTarget(s.rtg)
	e3:SetOperation(s.rop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_VAMPIRE}

-- ==========================================
-- 1. SEARCH ON ACTIVATION
-- ==========================================
function s.thfilter(c)
	return c:IsSetCard(SET_VAMPIRE) and c:IsMonster() and c:IsAbleToHand()
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.thfilter, tp, LOCATION_DECK, 0, nil)
	if #g>0 and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local sg=g:Select(tp, 1, 1, nil)
		Duel.SendtoHand(sg, nil, REASON_EFFECT)
		Duel.ConfirmCards(1-tp, sg)
	end
end

-- ==========================================
-- 2. REPLACE LP COST BY SENDING FROM DECK TO GY
-- ==========================================
function s.lrfilter(c)
	return c:IsSetCard(SET_VAMPIRE) and c:IsAbleToGraveAsCost()
end

function s.lrcon(e, tp, eg, ep, ev, re, r, rp)
	if tp~=ep then return false end
	if not re or not re:IsActivated() then return false end
	local rc=re:GetHandler()
	return rc and rc:IsSetCard(SET_VAMPIRE)
		and Duel.IsExistingMatchingCard(s.lrfilter, tp, LOCATION_DECK, 0, 1, nil)
end

function s.lrop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_CARD, 0, id)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp, s.lrfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g>0 then
		Duel.SendtoGrave(g, REASON_COST)
	end
end

-- ==========================================
-- 3. RETURN FROM GY/BANISHMENT & OPTIONAL DESTROY
-- ==========================================
function s.rfilter(c)
	if not (c:IsSetCard(SET_VAMPIRE) and c:IsFaceup()) then return false end
	if c:IsLocation(LOCATION_GRAVE) then
		return c:IsAbleToDeck()
	elseif c:IsLocation(LOCATION_REMOVED) then
		return c:IsAbleToDeck() or true -- Retornar banido ao GY não exige IsAbleToGrave()
	end
	return false
end

function s.desfilter(c)
	return c:IsSetCard(SET_VAMPIRE) and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

function s.rtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.rfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.rfilter, tp, LOCATION_GRAVE+LOCATION_REMOVED, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp, s.rfilter, tp, LOCATION_GRAVE+LOCATION_REMOVED, 0, 1, 1, nil)
	local tc=g:GetFirst()
	if tc:IsLocation(LOCATION_GRAVE) then
		Duel.SetOperationInfo(0, CATEGORY_TODECK, g, 1, 0, 0)
	else
		Duel.SetPossibleOperationInfo(0, CATEGORY_TODECK, g, 1, 0, 0)
		Duel.SetPossibleOperationInfo(0, CATEGORY_TOGRAVE, g, 1, 0, 0)
	end
	Duel.SetPossibleOperationInfo(0, CATEGORY_DESTROY, nil, 1, tp, LOCATION_HAND+LOCATION_ONFIELD)
end

function s.rop(e, tp, eg, ep, ev, re, r, rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local moved=false
	if tc:IsLocation(LOCATION_GRAVE) then
		if Duel.SendtoDeck(tc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)>0 and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
			moved=true
		end
	elseif tc:IsLocation(LOCATION_REMOVED) then
		local b1=tc:IsAbleToDeck()
		local b2=true
		local op=Duel.SelectEffect(tp,
			{b1, aux.Stringid(id, 3)},
			{b2, aux.Stringid(id, 4)})
		if op==1 then
			if Duel.SendtoDeck(tc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)>0 and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
				moved=true
			end
		else
			if Duel.SendtoGrave(tc, REASON_EFFECT+REASON_RETURN)>0 and tc:IsLocation(LOCATION_GRAVE) then
				moved=true
			end
		end
	end

	if moved then
		local dg=Duel.GetMatchingGroup(s.desfilter, tp, LOCATION_HAND+LOCATION_ONFIELD, 0, nil)
		if #dg>0 and Duel.SelectYesNo(tp, aux.Stringid(id, 5)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg=dg:Select(tp, 1, 1, nil)
			if sg:GetFirst():IsLocation(LOCATION_ONFIELD) then
				Duel.HintSelection(sg)
			end
			Duel.Destroy(sg, REASON_EFFECT)
		end
	end
end