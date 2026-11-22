--Fenrir, the Ragnarok Beast
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon procedure: 1 Beast/Beast-Warrior Link Monster + 1 Link Monster
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)
	Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit)
	--(1) Set this card's original ATK/DEF based on a Link Monster's Link Rating
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
	--(2) Destroy 1 opponent's card and make its former zone unusable this turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	--(3) Move this card instead of destroying it
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.reptg)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

--Special Summon procedure
function s.matfilter1(c,fc,sumtype,tp)
	return c:IsType(TYPE_LINK,fc,sumtype,tp)
		and c:IsRace(RACE_BEAST|RACE_BEASTWARRIOR,fc,sumtype,tp)
end
function s.matfilter2(c,fc,sumtype,tp)
	return c:IsType(TYPE_LINK,fc,sumtype,tp)
end
function s.splimit(e,se,sp,st)
	return e:GetHandler():GetLocation()~=LOCATION_EXTRA
end
function s.contactfilter(c,tp)
	return c:IsType(TYPE_LINK) and c:IsCanBeFusionMaterial()
		and c:IsAbleToGraveAsCost() and (c:IsControler(tp) or c:IsFaceup())
end
function s.contactfil(tp)
	return Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil,tp)
end
function s.contactop(g,tp,c)
	Duel.SendtoGrave(g,REASON_COST|REASON_MATERIAL)
end

--(1) Set this card's original ATK/DEF based on a Link Monster's Link Rating
function s.atkfilter(c,e)
	return c:IsType(TYPE_LINK) and c:IsCanBeEffectTarget(e)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.atkfilter(chkc,e) end
	if chk==0 then
		return Duel.IsExistingTarget(s.atkfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,e)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.atkfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,e)
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE,e:GetHandler(),1,tp,0)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (c:IsFaceup() and c:IsRelateToEffect(e)
		and tc and tc:IsRelateToEffect(e) and tc:IsType(TYPE_LINK)) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	local value=tc:GetLink()*1000
	e1:SetValue(value)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_BASE_DEFENSE)
	e2:SetValue(value)
	c:RegisterEffect(e2)
end

--(2) Destroy 1 opponent's card and make its former zone unusable this turn
function s.desfilter(c,e)
	return c:IsCanBeEffectTarget(e) and c:IsDestructable()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD)
			and s.desfilter(chkc,e)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil,e)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil,e)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.getzonemask(c,tp)
	local location=c:GetLocation()
	local sequence=c:GetSequence()
	local zone=0
	if location==LOCATION_MZONE then
		zone=1<<sequence
	elseif location==LOCATION_SZONE then
		zone=1<<(sequence+8)
	elseif location==LOCATION_FZONE then
		zone=1<<13
	elseif location==LOCATION_PZONE then
		zone=1<<(sequence+14)
	end
	if zone~=0 and c:GetControler()~=tp then
		zone=zone<<16
	end
	return zone
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local zone=s.getzonemask(tc,tp)
	if Duel.Destroy(tc,REASON_EFFECT)==0 or zone==0 then return end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetValue(zone)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	Duel.Hint(HINT_ZONE,tp,zone)
end

--(3) Move this card instead of destroying it
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return not c:IsReason(REASON_REPLACE)
			and (c:IsReason(REASON_BATTLE) or c:IsReason(REASON_EFFECT))
			and Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,ZONES_MMZ)>0
	end
	if not Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,2)) then return false end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE)
	local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,ZONES_EMZ)
	local new_sequence=math.floor(math.log(zone,2))
	e:SetLabel(c:GetSequence(),new_sequence,c:GetControler())
	return true
end
function s.previouszoneop(e,tp)
	local sequence,previous_player=e:GetLabel()
	local zone=1<<sequence
	if previous_player~=tp then
		zone=zone<<16
	end
	return zone
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local old_sequence,new_sequence,previous_player=e:GetLabel()
	if not (c:IsFaceup() and c:IsLocation(LOCATION_MZONE)
		and Duel.MoveSequence(c,new_sequence)) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetRange(LOCATION_MZONE)
	e1:SetLabel(old_sequence,previous_player)
	e1:SetOperation(s.previouszoneop)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
end
