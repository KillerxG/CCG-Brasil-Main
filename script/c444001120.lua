-- Nightly Ritual of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e
local SET_VAMPIRE_CASTLE = 0x208e

function s.initial_effect(c)
	-- Activate during Main Phase: Synchro, Xyz, or Ritual Summon 1 "Vampire" monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={SET_VAMPIRE, SET_VAMPIRE_CASTLE}

function s.condition(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase()
end

-- ==========================================
-- MATERIAL FILTER (Seus monstros + Zumbis do Oponente)
-- ==========================================
function s.matfilter(c, tp)
	return c:IsFaceup() and (c:IsControler(tp) or c:IsRace(RACE_ZOMBIE))
end

-- ==========================================
-- MANUAL SYNCHRO HELPER (À prova de falhas da engine)
-- ==========================================
function s.can_synchro(c, e, tp, mg)
	if not (c:IsSynchroMonster() and c:IsLocation(LOCATION_EXTRA)) then return false end
	local lv = c:GetLevel()
	-- Simula se existe um grupo válido que passe na matemática do Sincro
	return aux.SelectUnselectGroup(mg, e, tp, 2, #mg, s.synrescon(lv, tp, c), 0)
end

function s.synrescon(lv, tp, sc)
	return function(sg, e, tp, mg)
		if Duel.GetMZoneCount(tp, sg)<=0 then return false end
		local sum = 0
		local strictly_tuners = 0
		local strictly_non_tuners = 0
		local flexible_tuners = 0 -- Monstros que podem ser Tuner OU Non-Tuner
		
		for tc in aux.Next(sg) do
			sum = sum + tc:GetLevel()
			
			if tc:IsType(TYPE_TUNER) then
				-- Se já é um Tuner normal
				strictly_tuners = strictly_tuners + 1
			elseif tc:IsControler(1-tp) then
				-- SE FOR DO OPONENTE: Ele vira flexível! Pode agir como Tuner ou Non-Tuner.
				flexible_tuners = flexible_tuners + 1
			else
				-- Seus próprios monstros que não são Tuners
				strictly_non_tuners = strictly_non_tuners + 1
			end
		end
		
		-- Agora testamos se existe alguma combinação válida (1 Tuner + 1+ Non-Tuners)
		local valid = false
		for i = 0, flexible_tuners do
			local t_count = strictly_tuners + i
			local nt_count = strictly_non_tuners + (flexible_tuners - i)
			
			if t_count == 1 and nt_count >= 1 then
				valid = true
				break
			end
		end
		
		return sum == lv and valid
	end
end

-- ==========================================
-- RITUAL HELPER
-- ==========================================
function s.ritval(c, sc, tp)
	if c:GetLevel()>0 then return c:GetLevel() end
	return 0
end

function s.ritrescon(sc, tp, lv)
	return function(sg, e, tp, mg)
		if Duel.GetMZoneCount(tp, sg)<=0 then return false end
		local sum=0
		for tc in aux.Next(sg) do
			sum = sum + s.ritval(tc, sc, tp)
		end
		return sum >= lv
	end
end

function s.can_ritual(c, e, tp, mg)
	if not (c:IsRitualMonster() and c:IsLocation(LOCATION_HAND)) then return false end
	if not c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_RITUAL, tp, false, true) then return false end
	local rmg=mg:Filter(Card.IsReleasableByEffect, nil):Filter(function(mc) return mc:HasLevel() or mc:GetOwner()==1-tp end, nil)
	local lv=c:GetLevel()
	return aux.SelectUnselectGroup(rmg, e, tp, 1, #rmg, s.ritrescon(c, tp, lv), 0)
end

-- ==========================================
-- MANUAL XYZ HELPER
-- ==========================================
function s.can_xyz(c, tp, mg)
	if not (c:IsXyzMonster() and c:IsLocation(LOCATION_EXTRA)) then return false end
	local rank = c:GetRank()
	local valid_mats = Group.CreateGroup()
	for mc in aux.Next(mg) do
		if mc:GetOwner()==1-tp then
			if mc:GetLevel()==rank or rank==5 or rank==6 or rank==8 then valid_mats:AddCard(mc) end
		else
			if mc:GetLevel()==rank or mc:IsHasEffect(EFFECT_XYZ_LEVEL) then valid_mats:AddCard(mc) end
		end
	end
	return #valid_mats >= 2
end

-- ==========================================
-- TARGET & OPERATION
-- ==========================================
function s.spfilter(c, e, tp, mg)
	if not c:IsSetCard(SET_VAMPIRE) then return false end
	-- Delega para as funções manuais, ignorando o IsSynchroSummonable nativo que trava
	if c:IsSynchroMonster() and c:IsLocation(LOCATION_EXTRA) and s.can_synchro(c, e, tp, mg) then return true end
	if s.can_xyz(c, tp, mg) then return true end
	if s.can_ritual(c, e, tp, mg) then return true end
	return false
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_MZONE, LOCATION_MZONE, nil, tp)
		if #mg==0 then return false end
		return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_EXTRA+LOCATION_HAND, 0, 1, nil, e, tp, mg)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA+LOCATION_HAND)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local mg=Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_MZONE, LOCATION_MZONE, nil, tp)
	if #mg==0 then return end

	local g=Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_EXTRA+LOCATION_HAND, 0, nil, e, tp, mg)
	if #g==0 then return end

	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local tc=g:Select(tp, 1, 1, nil):GetFirst()
	if not tc then return end

	-- 1. RESOLUÇÃO SINCRO
	if tc:IsSynchroMonster() then
		local lv = tc:GetLevel()
		-- Força a janela de seleção pedindo os monstros corretos da pool
		local mat = aux.SelectUnselectGroup(mg, e, tp, 2, #mg, s.synrescon(lv, tp, tc), 1, tp, HINTMSG_SPSUMMON)
		if mat and #mat>0 then
			tc:SetMaterial(mat)
			-- Manda as matérias selecionadas para o GY (o que a engine deveria fazer sozinha)
			Duel.SendtoGrave(mat, REASON_MATERIAL+REASON_SYNCHRO)
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc, SUMMON_TYPE_SYNCHRO, tp, tp, false, false, POS_FACEUP)>0 then
				tc:CompleteProcedure()
				s.register_ep_damage(c, tp, tc)
			end
		end
		
	-- 2. RESOLUÇÃO XYZ
	elseif tc:IsXyzMonster() then
		local rank = tc:GetRank()
		local valid_mats = Group.CreateGroup()
		for mc in aux.Next(mg) do
			if mc:GetOwner()==1-tp then
				if mc:GetLevel()==rank or rank==5 or rank==6 or rank==8 then valid_mats:AddCard(mc) end
			else
				if mc:GetLevel()==rank or mc:IsHasEffect(EFFECT_XYZ_LEVEL) then valid_mats:AddCard(mc) end
			end
		end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_XMATERIAL)
		local mat = valid_mats:Select(tp, 2, 99, nil)
		if mat and #mat>0 then
			tc:SetMaterial(mat)
			Duel.Overlay(tc, mat)
			if Duel.SpecialSummon(tc, SUMMON_TYPE_XYZ, tp, tp, false, false, POS_FACEUP)>0 then
				tc:CompleteProcedure()
				s.register_ep_damage(c, tp, tc)
			end
		end
		
	-- 3. RESOLUÇÃO RITUAL
	elseif tc:IsRitualMonster() then
		local rmg=mg:Filter(Card.IsReleasableByEffect, nil):Filter(function(mc) return mc:HasLevel() or mc:GetOwner()==1-tp end, nil)
		local lv=tc:GetLevel()
		local mat=aux.SelectUnselectGroup(rmg, e, tp, 1, #rmg, s.ritrescon(tc, tp, lv), 1, tp, HINTMSG_RELEASE)
		
		if mat and #mat>0 then
			tc:SetMaterial(mat)
			Duel.ReleaseRitualMaterial(mat)
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc, SUMMON_TYPE_RITUAL, tp, tp, false, true, POS_FACEUP)>0 then
				tc:CompleteProcedure()
				s.register_ep_damage(c, tp, tc)
			end
		end
	end
end

-- ==========================================
-- END PHASE BURN TRACKING
-- ==========================================
function s.register_ep_damage(c, tp, tc)
	if not tc or not tc:IsFaceup() then return end
	tc:RegisterFlagEffect(id, RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END, 0, 1)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetLabelObject(tc)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1, tp)
end

function s.damcon(e, tp, eg, ep, ev, re, r, rp)
	local tc=e:GetLabelObject()
	return tc and tc:GetFlagEffect(id)>0 and tc:IsLocation(LOCATION_MZONE) and tc:IsControler(tp) and tc:IsFaceup()
end

function s.damop(e, tp, eg, ep, ev, re, r, rp)
	local tc=e:GetLabelObject()
	if tc and tc:GetFlagEffect(id)>0 and tc:IsLocation(LOCATION_MZONE) and tc:IsControler(tp) and tc:IsFaceup() then
		local val = tc:HasLevel() and tc:GetLevel() or (tc:IsXyzMonster() and tc:GetRank() or 0)
		if val>0 then
			Duel.Hint(HINT_CARD, 0, id)
			Duel.Damage(tp, val*300, REASON_EFFECT)
		end
	end
end