--Magician Girl of the Egyptian Divinity
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--(1) Reveal a Level 10 monster; Special Summon this card and 2 "Dark Magician Girl", then Normal Summon the revealed monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--(2) Protect a Level 10 or higher monster Tribute Summoned using this card
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_PRE_MATERIAL)
	e2:SetCondition(s.protcon)
	e2:SetOperation(s.protop)
	c:RegisterEffect(e2)
end
s.listed_names={38033121}
--(1) Reveal a Level 10 monster; Special Summon this card and 2 "Dark Magician Girl", then Normal Summon the revealed monster
function s.revealfilter(c)
	return c:IsLevel(10) and c:IsSummonableCard() and not c:IsPublic()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.revealfilter,tp,LOCATION_HAND,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.revealfilter,tp,LOCATION_HAND,0,1,1,e:GetHandler())
	local tc=g:GetFirst()
	e:SetLabelObject(tc)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
end
function s.dmgfilter(c,e,tp)
	return c:IsCode(38033121) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.dmgpool(e,tp)
	return Duel.GetMatchingGroup(aux.NecroValleyFilter(s.dmgfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,nil,e,tp)
end
function s.cansummongirls(tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
		and Duel.IsPlayerCanSpecialSummonCount(tp,2)
		and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=3
			and Duel.IsPlayerCanSpecialSummonCount(tp,3)
			and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and #s.dmgpool(e,tp)>=2
	end
	local tc=e:GetLabelObject()
	tc:CreateEffectRelation(e)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,3,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SUMMON,tc,1,tp,LOCATION_HAND)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	if not s.cansummongirls(tp) then return end
	local g=s.dmgpool(e,tp)
	if #g<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Select(tp,2,2,nil)
	if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)~=2 then return end
	if tc and tc:IsRelateToEffect(e) and tc:IsControler(tp) and tc:IsLocation(LOCATION_HAND)
		and tc:IsSummonable(true,nil) then
		Duel.BreakEffect()
		Duel.Summon(tp,tc,true,nil)
	end
end
--(2) Protect a Level 10 or higher monster Tribute Summoned using this card
function s.protcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	return r==REASON_SUMMON and rc and rc:IsFaceup() and rc:IsLevelAbove(10)
end
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.indoval)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetValue(aux.tgoval)
	rc:RegisterEffect(e2)
end
