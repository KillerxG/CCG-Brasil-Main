-- Vampire Matriarch Elizabeth
local s, id = GetID()

local ID_PRINCESS = 444001020
local ID_EMPRESS = 444001010

function s.initial_effect(c)
	-- Must first be Special Summoned (from your Extra Deck) by shuffling the above cards from your field and/or GY into the Deck
	c:EnableReviveLimit()
	Fusion.AddProcMix(c, true, true, ID_PRINCESS, ID_EMPRESS)
	Fusion.AddContactProc(c, s.contactfil, s.contactop, s.splimit)

	-- 1. Cannot be targeted or destroyed by opponent's card effects while LP > opponent's
	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_SINGLE)
	e1a:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1a:SetRange(LOCATION_MZONE)
	e1a:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1a:SetCondition(s.lpcon)
	e1a:SetValue(aux.tgoval)
	c:RegisterEffect(e1a)
	local e1b=e1a:Clone()
	e1b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1b:SetValue(aux.indoval)
	c:RegisterEffect(e1b)

	-- 2. Cannot be destroyed by battle, also no battle damage
	local e2a=Effect.CreateEffect(c)
	e2a:SetType(EFFECT_TYPE_SINGLE)
	e2a:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2a:SetValue(1)
	c:RegisterEffect(e2a)
	local e2b=Effect.CreateEffect(c)
	e2b:SetType(EFFECT_TYPE_SINGLE)
	e2b:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e2b:SetValue(1)
	c:RegisterEffect(e2b)

	-- 3. Opponent's monsters must attack this card, if able
	local e3a=Effect.CreateEffect(c)
	e3a:SetType(EFFECT_TYPE_FIELD)
	e3a:SetCode(EFFECT_MUST_ATTACK)
	e3a:SetRange(LOCATION_MZONE)
	e3a:SetTargetRange(0, LOCATION_MZONE)
	c:RegisterEffect(e3a)
	local e3b=Effect.CreateEffect(c)
	e3b:SetType(EFFECT_TYPE_FIELD)
	e3b:SetCode(EFFECT_MUST_ATTACK_MONSTER)
	e3b:SetRange(LOCATION_MZONE)
	e3b:SetTargetRange(0, LOCATION_MZONE)
	e3b:SetValue(s.atklimit)
	c:RegisterEffect(e3b)

	-- 4. Inflict damage equal to opponent's battling monster's ATK before damage calculation
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 0))
	e4:SetCategory(CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e4:SetCondition(s.damcon)
	e4:SetTarget(s.damtg)
	e4:SetOperation(s.damop)
	c:RegisterEffect(e4)

	-- 5. Opponent's End Phase: LP tax or take control
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_CONTROL)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.ctcon)
	e5:SetTarget(s.cttg)
	e5:SetOperation(s.ctop)
	c:RegisterEffect(e5)

	--[[ 6. End Phase: Pay 1000 LP to Special Summon from GY if sent from field this turn
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id, 3))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_GRAVE)
	e6:SetCountLimit(1, {id, 1})
	e6:SetCondition(s.spcon)
	e6:SetCost(s.spcost)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
	]]
end

s.listed_names={ID_PRINCESS, ID_EMPRESS}
s.listed_series={0x8e}

-- ==========================================
-- 0. CONTACT FUSION & SUMMON LIMIT
-- ==========================================
function s.contactfil(tp)
	return Duel.GetMatchingGroup(function(c)
		return c:IsFaceup() and c:IsAbleToDeckOrExtraAsCost()
	end, tp, LOCATION_ONFIELD+LOCATION_GRAVE, 0, nil)
end

function s.contactop(g, tp)
	Duel.ConfirmCards(1-tp, g)
	Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_COST+REASON_MATERIAL)
end

function s.splimit(e, se, sp, st)
	return not e:GetHandler():IsLocation(LOCATION_EXTRA)
end

-- ==========================================
-- 1 & 3. LP PROTECTION & MUST ATTACK
-- ==========================================
function s.lpcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetLP(tp) > Duel.GetLP(1-tp)
end

function s.atklimit(e, c)
	return c==e:GetHandler()
end

-- ==========================================
-- 4. BURN BEFORE DAMAGE CALCULATION
-- ==========================================
function s.damcon(e, tp, eg, ep, ev, re, r, rp)
	local bc=e:GetHandler():GetBattleTarget()
	return bc and bc:IsControler(1-tp)
end

function s.damtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return true end
	local bc=e:GetHandler():GetBattleTarget()
	if bc then
		Duel.SetOperationInfo(0, CATEGORY_DAMAGE, nil, 0, 1-tp, math.max(0, bc:GetAttack()))
	end
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
	local bc=e:GetHandler():GetBattleTarget()
	if bc and bc:IsRelateToBattle() and bc:IsFaceup() then
		local dam=bc:GetAttack()
		if dam>0 then
			Duel.Damage(1-tp, dam, REASON_EFFECT)
		end
	end
end

-- ==========================================
-- 5. OPPONENT'S END PHASE: TAX OR CONTROL
-- ==========================================
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsAbleToChangeControler()
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,1-tp,LOCATION_MZONE)
end
function s.vampfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_VAMPIRE)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsControler(1-tp)
		or not tc:IsAbleToChangeControler()
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local ct=Duel.GetMatchingGroupCount(s.vampfilter,tp,LOCATION_MZONE,0,nil)
	local cost=ct*400
	if cost>0 and Duel.IsChainDisablable(0)
		and Duel.CheckLPCost(1-tp,cost)
		and Duel.SelectYesNo(1-tp,aux.Stringid(id,1)) then
		Duel.PayLPCost(1-tp,cost)
		Duel.NegateEffect(0)
		return
	end
	if Duel.GetControl(tc,tp) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e1:SetValue(ATTRIBUTE_DARK)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CHANGE_RACE)
		e2:SetValue(RACE_ZOMBIE)
		tc:RegisterEffect(e2)
	end
end

-- ==========================================
-- 6. END PHASE GY REVIVE
-- ==========================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	return c:GetTurnID()==Duel.GetTurnCount() and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.CheckLPCost(tp, 1000) end
	Duel.PayLPCost(tp, 1000)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp, LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end