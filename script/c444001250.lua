-- Mist of the Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- 1. "Vampire" monsters you control cannot be targeted by opponent's card effects during the turn they are Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE, 0)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	-- 2. If an opponent's monster(s) is destroyed by battle or effect while you control a "Vampire": Special Summon it, becomes DARK Zombie, treated as "Vampire" & "of Vampire Castle", negate effects, send to GY during End Phase (HOPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1, id)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}

-- ==========================================
-- 1. TARGET PROTECTION ON SUMMON TURN
-- ==========================================
function s.tgtg(e, c)
	return c:IsSetCard(SET_VAMPIRE) and c:IsStatus(STATUS_SUMMON_TURN|STATUS_SPSUMMON_TURN|STATUS_FLIP_SUMMON_TURN)
end

-- ==========================================
-- 2. REVIVE OPPONENT'S DESTROYED MONSTER
-- ==========================================
function s.vampfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_VAMPIRE)
end

function s.cfilter(c, e, tp)
	return c:IsPreviousControler(1-tp) and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP, tp)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.vampfilter, tp, LOCATION_MZONE, 0, 1, nil)
		and eg:IsExists(s.cfilter, 1, nil, e, tp)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return eg:IsContains(chkc) and s.cfilter(chkc, e, tp) end
	if chk==0 then return Duel.GetLocationCount(tp, LOCATION_MZONE)>0
		and eg:IsExists(s.cfilter, 1, nil, e, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g=eg:FilterSelect(tp, s.cfilter, 1, 1, nil, e, tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)>0 then
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

		-- Treated as "Vampire" and "of Vampire Castle" card + CLIENT HINT
		local e3=e1:Clone()
		e3:SetCode(EFFECT_ADD_SETCODE)
		e3:SetValue(SET_VAMPIRE)
		e3:SetProperty(EFFECT_FLAG_CLIENT_HINT) -- Avisa o jogo para mostrar o texto
		e3:SetDescription(aux.Stringid(id, 2)) -- Puxa a string 2 do seu banco de dados (.cdb)
		tc:RegisterEffect(e3)
		
		local e4=e1:Clone()
		e4:SetCode(EFFECT_ADD_SETCODE)
		e4:SetValue(SET_VAMPIRE_CASTLE)
		tc:RegisterEffect(e4)

		-- Effects are negated
		local e5=e1:Clone()
		e5:SetCode(EFFECT_DISABLE)
		tc:RegisterEffect(e5)
		local e6=e1:Clone()
		e6:SetCode(EFFECT_DISABLE_EFFECT)
		e6:SetValue(RESET_TURN_SET)
		tc:RegisterEffect(e6)

		-- Send to GY during the End Phase
		aux.DelayedOperation(tc, PHASE_END, id, e, tp, function(ag)
			Duel.SendtoGrave(ag, REASON_EFFECT)
		end, nil, 1, aux.Stringid(id, 1))
	end
end