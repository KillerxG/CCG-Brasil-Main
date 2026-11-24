-- The Harpy of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 0. Synchro Summon (mesmo procedimento do Angler):
	-- 1 "Vampire" or Zombie Tuner + 1+ non-Tuner monsters
	-- Pode tratar 1 monstro que voce controla cujo dono e o oponente como Regulador Zumbi
	Synchro.AddProcedure(c, s.tfilter, 1, 1, Synchro.NonTuner(nil), 1, 99, s.exmatfilter)

	-- 1. During each Standby Phase: Turn player must pay 700 LP, or skip their Main Phase 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetOperation(s.skipop)
	c:RegisterEffect(e1)

	-- 2. Each player must pay 500 LP to declare an attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_ATTACK_COST)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1, 1)
	e2:SetCost(s.atcost)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)

	-- 3. This card must attack, if able
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_MUST_ATTACK)
	c:RegisterEffect(e3)

	-- 4. Can attack directly, but battle damage is halved when using this effect
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e5:SetCondition(s.rdcon)
	e5:SetValue(aux.ChangeBattleDamage(1, HALF_DAMAGE))
	c:RegisterEffect(e5)

	-- 5. If this card inflicts battle damage to your opponent: Target 1 card they control; return it to the hand (HOPT)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id, 2))
	e6:SetCategory(CATEGORY_TOHAND)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_BATTLE_DAMAGE)
	e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e6:SetCountLimit(1, id)
	e6:SetCondition(s.thcon)
	e6:SetTarget(s.thtg)
	e6:SetOperation(s.thop)
	c:RegisterEffect(e6)
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
-- 1. STANDBY PHASE: PAY 700 LP OR SKIP MP1
-- ==========================================
function s.skipop(e, tp, eg, ep, ev, re, r, rp)
	local p=Duel.GetTurnPlayer()
	if Duel.CheckLPCost(p, 700) and Duel.SelectYesNo(p, aux.Stringid(id, 1)) then
		Duel.PayLPCost(p, 700)
	else
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_SKIP_M1)
		if p==tp then
			e1:SetTargetRange(1, 0)
		else
			e1:SetTargetRange(0, 1)
		end
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1, tp)
	end
end

-- ==========================================
-- 2. ATTACK COST (500 LP)
-- ==========================================
function s.atcost(e, c, tp)
	return Duel.CheckLPCost(tp, 500)
end

function s.atop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.IsAttackCostPaid()~=2 then
		Duel.PayLPCost(tp, 500)
		Duel.AttackCostPaid()
	end
end

-- ==========================================
-- 4. DIRECT ATTACK HALVED DAMAGE CONDITION
-- ==========================================
function s.rdcon(e)
	local c=e:GetHandler()
	local tp=e:GetHandlerPlayer()
	return Duel.GetAttackTarget()==nil and c:GetEffectCount(EFFECT_DIRECT_ATTACK)<2
		and Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE)>0
end

-- ==========================================
-- 5. BATTLE DAMAGE: BOUNCE 1 OPPONENT'S CARD
-- ==========================================
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
	return ep~=tp
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp, Card.IsAbleToHand, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc, nil, REASON_EFFECT)
	end
end