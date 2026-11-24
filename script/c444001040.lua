-- The Clock Tower Keeper of Vampire Castle - Death
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e -- Ajuste se o seu setcode de "of Vampire Castle" for diferente

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 0. Synchro Summon (mesmo procedimento do Angler):
	-- 1 "Vampire" or Zombie Tuner + 1+ non-Tuner monsters
	-- Pode tratar 1 monstro que voce controla cujo dono e o oponente como Regulador Zumbi
	Synchro.AddProcedure(c, s.tfilter, 1, 1, Synchro.NonTuner(nil), 1, 99, s.exmatfilter)

	-- 1. (Quick Effect): Target 1 face-up monster opponent controls; take control, becomes DARK Zombie, negate effects (HOPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.ctltg)
	e1:SetOperation(s.ctlop)
	c:RegisterEffect(e1)

	-- 2. While you control a monster taken by this card's effect, opponent cannot target other "Vampire" monsters for attacks
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0, LOCATION_MZONE)
	e2:SetCondition(s.atkcon)
	e2:SetValue(s.atktg)
	c:RegisterEffect(e2)

	-- 3. Destruction replacement: Tribute 1 monster you control instead
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.reptg)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}

-- ==========================================
-- 0. SYNCHRO PROCEDURE (igual ao Angler)
-- ==========================================
-- sub1: monstro que voce controla mas cujo dono e o oponente vale como Regulador
function s.exmatfilter(c, scard, sumtype, tp)
	return c:GetOwner() ~= c:GetControler()
end

-- f1: so vale para Reguladores "de verdade"
function s.tfilter(c, scard, sumtype, tp)
	return c:IsSetCard(SET_VAMPIRE, scard, sumtype, tp)
		or c:IsRace(RACE_ZOMBIE, scard, sumtype, tp)
end

-- ==========================================
-- 1. QUICK EFFECT: TAKE CONTROL & NEGATE
-- ==========================================
function s.ctlfilter(c)
	return c:IsFaceup() and c:IsControlerCanBeChanged()
end

function s.ctltg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.ctlfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.ctlfilter, tp, 0, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp, s.ctlfilter, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_CONTROL, g, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
end

function s.ctlop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and Duel.GetControl(tc, tp) then
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			c:SetCardTarget(tc)
		end
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		-- Becomes DARK Zombie
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e1:SetValue(ATTRIBUTE_DARK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CHANGE_RACE)
		e2:SetValue(RACE_ZOMBIE)
		tc:RegisterEffect(e2)
		-- Effects are negated
		local e3=e1:Clone()
		e3:SetCode(EFFECT_DISABLE)
		tc:RegisterEffect(e3)
		local e4=e1:Clone()
		e4:SetCode(EFFECT_DISABLE_EFFECT)
		e4:SetValue(RESET_TURN_SET)
		tc:RegisterEffect(e4)
		-- Cannot activate its effects
		local e5=e1:Clone()
		e5:SetDescription(3302)
		e5:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e5:SetCode(EFFECT_CANNOT_TRIGGER)
		tc:RegisterEffect(e5)
	end
end

-- ==========================================
-- 2. ATTACK PROTECTION FOR OTHER "VAMPIRES"
-- ==========================================
function s.stolenfilter(c, tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
end

function s.atkcon(e)
	local c=e:GetHandler()
	local g=c:GetCardTarget()
	return g and g:IsExists(s.stolenfilter, 1, nil, e:GetHandlerPlayer())
end

function s.atktg(e, c)
	return c:IsFaceup() and c:IsSetCard(SET_VAMPIRE) and c~=e:GetHandler()
end

-- ==========================================
-- 3. DESTRUCTION REPLACEMENT (TRIBUTE 1 MONSTER)
-- ==========================================
function s.repfilter(c, e)
	return c:IsReleasableByEffect() and not c:IsStatus(STATUS_DESTROY_CONFIRMED+STATUS_BATTLE_DESTROYED)
end

function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		and Duel.IsExistingMatchingCard(s.repfilter, tp, LOCATION_MZONE, 0, 1, c, e) end
	if Duel.SelectEffectYesNo(tp, c, aux.Stringid(id, 1)) then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESREPLACE)
		local g=Duel.SelectMatchingCard(tp, s.repfilter, tp, LOCATION_MZONE, 0, 1, 1, c, e)
		e:SetLabelObject(g:GetFirst())
		g:GetFirst():SetStatus(STATUS_DESTROY_CONFIRMED, true)
		return true
	end
	return false
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
	local tc=e:GetLabelObject()
	tc:SetStatus(STATUS_DESTROY_CONFIRMED, false)
	Duel.Release(tc, REASON_EFFECT+REASON_REPLACE)
end