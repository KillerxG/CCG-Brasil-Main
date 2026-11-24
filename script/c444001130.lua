-- Guardians of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e

function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- 1. While you control a Level 5+ "Vampire" monster, opponent's monsters lose ATK/DEF equal to half the LP difference
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(0, LOCATION_MZONE)
	e1:SetCondition(s.lpcon)
	e1:SetValue(s.lpval)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e1b)

	-- 2a. When opponent's monster declares an attack: Pay 800 LP, target 1 "Vampire" or Zombie in GY; Special Summon & change opponent's monster to Defense/Zombie (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_POSITION)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1, id)
	e2:SetCondition(s.atkcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 2b. When opponent activates a card or effect
	local e3=e2:Clone()
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetCondition(s.chaincon)
	c:RegisterEffect(e3)

	-- 3. If this face-up card in owner's control leaves field by opponent's card effect: Banish 1 Tuner + 1+ non-Tuners from field/GY to Synchro Summon 1 "Vampire" Synchro (HOPT)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1, {id, 1})
	e4:SetCondition(s.syncon)
	e4:SetTarget(s.syntg)
	e4:SetOperation(s.synop)
	c:RegisterEffect(e4)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}

-- ==========================================
-- 1. ATK/DEF DEBUFF (HALF LP DIFFERENCE)
-- ==========================================
function s.vamp5filter(c)
	return c:IsFaceup() and c:IsSetCard(SET_VAMPIRE) and c:IsLevelAbove(5)
end

function s.lpcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.vamp5filter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.lpval(e, c)
	local tp=e:GetHandlerPlayer()
	local diff=math.abs(Duel.GetLP(tp)-Duel.GetLP(1-tp))
	return -math.floor(diff/2)
end

-- ==========================================
-- 2. REVIVE ON ATTACK OR EFFECT & CHANGE TO DEFENSE / ZOMBIE
-- ==========================================
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetAttacker():IsControler(1-tp)
end

function s.chaincon(e, tp, eg, ep, ev, re, r, rp)
	return rp==1-tp
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.CheckLPCost(tp, 800) end
	Duel.PayLPCost(tp, 800)
end

function s.spfilter(c, e, tp)
	return (c:IsSetCard(SET_VAMPIRE) or c:IsRace(RACE_ZOMBIE))
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc, e, tp) end
	if chk==0 then return Duel.GetLocationCount(tp, LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
	Duel.SetPossibleOperationInfo(0, CATEGORY_POSITION, nil, 1, 1-tp, LOCATION_MZONE)
end

function s.posfilter(c)
	return c:IsFaceup() and c:IsAttackPos() and c:IsCanChangePosition()
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)>0 then
		local g=Duel.GetMatchingGroup(s.posfilter, tp, 0, LOCATION_MZONE, nil)
		if #g>0 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_POSCHANGE)
			local sg=g:Select(tp, 1, 1, nil)
			local sc=sg:GetFirst()
			if sc then
				Duel.HintSelection(sg)
				if Duel.ChangePosition(sc, POS_FACEUP_DEFENSE)>0 then
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CHANGE_RACE)
					e1:SetValue(RACE_ZOMBIE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					sc:RegisterEffect(e1)
				end
			end
		end
	end
end

-- ==========================================
-- 3. BANISH MATERIALS FROM FIELD/GY TO SYNCHRO SUMMON
-- ==========================================
function s.syncon(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousControler(tp)
		and c:GetOwner()==tp and c:IsReason(REASON_EFFECT) and rp==1-tp
end

function s.mfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:HasLevel() and c:IsAbleToRemove()
end

function s.rescon(sc)
	local lv=sc:GetLevel()
	return function(sg, e, tp, mg)
		if Duel.GetLocationCountFromEx(tp, tp, sg, sc)<=0 then return false end
		local t_ct=sg:FilterCount(Card.IsType, nil, TYPE_TUNER)
		return t_ct==1 and #sg>=2 and sg:GetSum(Card.GetLevel)==lv, t_ct>1 or sg:GetSum(Card.GetLevel)>lv
	end
end

function s.synfilter(c, e, tp, mg)
	if not (c:IsSetCard(SET_VAMPIRE) and c:IsSynchroMonster() and c:HasLevel()) then return false end
	if not c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_SYNCHRO, tp, false, false) then return false end
	return aux.SelectUnselectGroup(mg, e, tp, 2, #mg, s.rescon(c), 0)
end

function s.syntg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then
		if not Duel.IsPlayerCanRemove(tp) then return false end
		local mg=Duel.GetMatchingGroup(s.mfilter, tp, LOCATION_MZONE+LOCATION_GRAVE, 0, nil)
		return Duel.IsExistingMatchingCard(s.synfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg)
	end
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, 2, tp, LOCATION_MZONE+LOCATION_GRAVE)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.synop(e, tp, eg, ep, ev, re, r, rp)
	if not Duel.IsPlayerCanRemove(tp) then return end
	local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.mfilter), tp, LOCATION_MZONE+LOCATION_GRAVE, 0, nil)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp, s.synfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp, mg)
	local sc=g:GetFirst()
	if not sc then return end

	local matg=aux.SelectUnselectGroup(mg, e, tp, 2, #mg, s.rescon(sc), 1, tp, HINTMSG_REMOVE)
	if #matg>=2 then
		sc:SetMaterial(matg)
		if Duel.Remove(matg, POS_FACEUP, REASON_EFFECT+REASON_MATERIAL+REASON_SYNCHRO)>0 then
			Duel.SpecialSummon(sc, SUMMON_TYPE_SYNCHRO, tp, tp, false, false, POS_FACEUP)
			sc:CompleteProcedure()
		end
	end
end