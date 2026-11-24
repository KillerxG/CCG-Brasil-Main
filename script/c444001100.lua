-- The Sentinel of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e

function s.initial_effect(c)
	-- 1. If this card battles a monster, neither can be destroyed by that battle
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	e1:SetTarget(s.indtg)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. Monsters your opponent controls must attack this card, if able
	local e2a=Effect.CreateEffect(c)
	e2a:SetType(EFFECT_TYPE_FIELD)
	e2a:SetCode(EFFECT_MUST_ATTACK)
	e2a:SetRange(LOCATION_MZONE)
	e2a:SetTargetRange(0, LOCATION_MZONE)
	c:RegisterEffect(e2a)
	local e2b=Effect.CreateEffect(c)
	e2b:SetType(EFFECT_TYPE_FIELD)
	e2b:SetCode(EFFECT_MUST_ATTACK_MONSTER)
	e2b:SetRange(LOCATION_MZONE)
	e2b:SetTargetRange(0, LOCATION_MZONE)
	e2b:SetValue(s.atklimit)
	c:RegisterEffect(e2b)

	-- 3. When opponent's monster declares an attack: Reveal in hand; Normal Summon and change to Defense Position
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_SUMMON+CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_HAND)
	e3:SetCondition(s.sumcon)
	e3:SetCost(s.sumcost)
	e3:SetTarget(s.sumtg)
	e3:SetOperation(s.sumop)
	c:RegisterEffect(e3)

	-- 4. Once per turn, before damage calculation, if attacked by opponent's monster: Other "Vampire" monsters gain ATK/DEF
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.atkcon)
	e4:SetTarget(s.atktg)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)

	-- 5. Banish from GY, target 1 "Vampire" card in GY or banishment; shuffle into Deck (HOPT)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id, 2))
	e5:SetCategory(CATEGORY_TODECK)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetCountLimit(1, id)
	e5:SetCost(aux.bfgcost)
	e5:SetTarget(s.tdtg)
	e5:SetOperation(s.tdop)
	c:RegisterEffect(e5)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}

-- ==========================================
-- 1 & 2. ILLUSION BATTLE PROTECTION & TAUNT
-- ==========================================
function s.indtg(e, c)
	local handler=e:GetHandler()
	return c==handler or c==handler:GetBattleTarget()
end

function s.atklimit(e, c)
	return c==e:GetHandler()
end

-- ==========================================
-- 3. NORMAL SUMMON ON ATTACK & CHANGE TO DEFENSE
-- ==========================================
function s.sumcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetAttacker():IsControler(1-tp)
end

function s.sumcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp, c)
	Duel.ShuffleHand(tp)
end

function s.sumtg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSummonable(true, nil) end
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, c, 1, 0, 0)
end

function s.sumop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSummonable(true, nil) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_SUMMON_SUCCESS)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetOperation(s.posop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
		c:RegisterEffect(e1)
		Duel.Summon(tp, c, true, nil)
	end
end

function s.posop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsAttackPos() then
		Duel.ChangePosition(c, POS_FACEUP_DEFENSE)
	end
	e:Reset()
end

-- ==========================================
-- 4. BUFF OTHER "VAMPIRE" MONSTERS BEFORE DAMAGE CALC
-- ==========================================
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return d==c and a and a:IsControler(1-tp) and a:GetBaseAttack()>0
end

function s.atktg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard, SET_VAMPIRE), tp, LOCATION_MZONE, 0, 1, c) end
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	if not a or not a:IsRelateToBattle() or a:IsFacedown() then return end
	local val=math.floor(a:GetBaseAttack()/2)
	if val<=0 then return end

	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard, SET_VAMPIRE), tp, LOCATION_MZONE, 0, c)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(val)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END, 2)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)
	end
end

-- ==========================================
-- 5. BANISH FROM GY; SHUFFLE 1 "VAMPIRE" CARD INTO DECK
-- ==========================================
function s.tdfilter(c)
	return c:IsSetCard(SET_VAMPIRE) and c:IsFaceup() and c:IsAbleToDeck()
end

function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.tdfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter, tp, LOCATION_GRAVE+LOCATION_REMOVED, 0, 1, e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp, s.tdfilter, tp, LOCATION_GRAVE+LOCATION_REMOVED, 0, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_TODECK, g, 1, 0, 0)
end

function s.tdop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoDeck(tc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
	end
end