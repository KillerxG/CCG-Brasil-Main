--Dragonmaid Making
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetOperation(s.activate)
	c:RegisterEffect(e0)
	--(1) You cannot Special Summon non-Dragon monsters from the Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	--(2) Add 1 "Dragonmaid" monster and Special Summon another
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thspcon)
	e2:SetCost(s.thspcost)
	e2:SetTarget(s.thsptg)
	e2:SetOperation(s.thspop)
	c:RegisterEffect(e2)
	--(3) Destroy 1 Spell/Trap your opponent controls
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_DRAGONMAID}

--Activate
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,0,1)
end

--(1) You cannot Special Summon non-Dragon monsters from the Extra Deck
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsRace(RACE_DRAGON)
end

--(2) Add 1 "Dragonmaid" monster and Special Summon another
function s.thspcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end
function s.thspcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST|REASON_DISCARD)
end
function s.thspfilter(c,e,tp)
	return c:IsMonster() and c:IsSetCard(SET_DRAGONMAID)
		and (c:IsAbleToHand()
			or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.rescon(sg,e,tp)
	if #sg~=2 then return false end
	local tc1=sg:GetFirst()
	local tc2=sg:GetNext()
	if tc1:GetLevel()==tc2:GetLevel() then return false end
	return (tc1:IsAbleToHand()
			and tc2:IsCanBeSpecialSummoned(e,0,tp,false,false))
		or (tc2:IsAbleToHand()
			and tc1:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.thsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
		local g=Duel.GetMatchingGroup(s.thspfilter,tp,LOCATION_DECK,0,nil,e,tp)
		return aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.thspop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.GetMatchingGroup(s.thspfilter,tp,LOCATION_DECK,0,nil,e,tp)
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_SELECT)
	if #sg~=2 then return end
	local tc1=sg:GetFirst()
	local tc2=sg:GetNext()
	local hg=Group.CreateGroup()
	if tc1:IsAbleToHand()
		and tc2:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		hg:AddCard(tc1)
	end
	if tc2:IsAbleToHand()
		and tc1:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		hg:AddCard(tc2)
	end
	if #hg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local thc=hg:Select(tp,1,1,nil):GetFirst()
	local spc=tc1==thc and tc2 or tc1
	if Duel.SendtoHand(thc,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,thc)
	end
	Duel.SpecialSummon(spc,0,tp,tp,false,false,POS_FACEUP)
end

--(3) Destroy 1 Spell/Trap your opponent controls
function s.desfilter(c,tp)
	return c:GetPreviousRaceOnField()&RACE_DRAGON~=0
		and c:GetPreviousControler()==tp
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousPosition(POS_FACEUP)
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsDamageStep()
		and eg:IsExists(s.desfilter,1,nil,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_ONFIELD)
			and chkc:IsSpellTrap()
	end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsSpellTrap,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsSpellTrap,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end