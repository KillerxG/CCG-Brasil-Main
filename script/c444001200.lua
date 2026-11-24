--Vampire Hunter Weapon - Vampire Killer
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	--Equip limit
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_EQUIP_LIMIT)
	e0:SetValue(s.eqlimit)
	c:RegisterEffect(e0)
	--(1) Special Summon 1 "Vampire Hunter", then equip this card to 1 face-up monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--(2) A "Vampire Hunter" monster gains 800 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(s.huntercon)
	e2:SetValue(800)
	c:RegisterEffect(e2)
	--(3) A "Vampire Hunter" monster can attack all DARK monsters once each
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_ATTACK_ALL)
	e3:SetCondition(s.huntercon)
	e3:SetValue(s.atkfilter)
	c:RegisterEffect(e3)
	--(4) Negate a non-"Vampire Hunter" monster's effects
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_EQUIP)
	e4:SetCode(EFFECT_DISABLE)
	e4:SetCondition(s.nonhuntercon)
	c:RegisterEffect(e4)
	--(5) A non-"Vampire Hunter" monster becomes DARK
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_EQUIP)
	e5:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e5:SetCondition(s.nonhuntercon)
	e5:SetValue(ATTRIBUTE_DARK)
	c:RegisterEffect(e5)
	--(6) A non-"Vampire Hunter" monster becomes Zombie
	local e6=e5:Clone()
	e6:SetCode(EFFECT_CHANGE_RACE)
	e6:SetValue(RACE_ZOMBIE)
	c:RegisterEffect(e6)
	--(7) If a "Vampire Hunter" monster is Special Summoned, recover this card, then optionally recover 1 "Vampire" card
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_TOHAND)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	e7:SetRange(LOCATION_GRAVE)
	e7:SetCountLimit(1,{id,1})
	e7:SetCondition(s.thcon)
	e7:SetTarget(s.thtg)
	e7:SetOperation(s.thop)
	c:RegisterEffect(e7)
end
s.listed_names={80485722}
s.listed_series={0x8e,0x108e}
function s.ishunter(c)
	return c:IsSetCard(0x108e) or c:IsCode(80485722)
end
function s.eqlimit(e,c)
	return c:IsFaceup()
end
--(1) Special Summon 1 "Vampire Hunter", then equip this card to 1 face-up monster
function s.spfilter(c,e,tp)
	return (c:IsCode(80485722) or (c:IsLocation(LOCATION_GRAVE) and c:IsSetCard(0x108e) and c:IsRitualMonster()))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc or Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 or not c:IsRelateToEffect(e) then return end
	local fg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #fg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local ec=fg:Select(tp,1,1,nil):GetFirst()
	if ec then Duel.Equip(tp,c,ec,true) end
end
--(2) A "Vampire Hunter" monster gains 800 ATK
--(3) A "Vampire Hunter" monster can attack all DARK monsters once each
function s.huntercon(e)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and s.ishunter(ec)
end
function s.atkfilter(e,c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK)
end
--(4) Negate a non-"Vampire Hunter" monster's effects
--(5) A non-"Vampire Hunter" monster becomes DARK
--(6) A non-"Vampire Hunter" monster becomes Zombie
function s.nonhuntercon(e)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and not s.ishunter(ec)
end
--(7) If a "Vampire Hunter" monster is Special Summoned, recover this card, then optionally recover 1 "Vampire" card
function s.cfilter(c)
	return s.ishunter(c)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil)
end
function s.thfilter(c)
	return (c:IsSetCard(0x8e) or c:IsCode(80485722)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SendtoHand(c,nil,REASON_EFFECT)==0 or not c:IsLocation(LOCATION_HAND) then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,nil)
	if #g==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=g:Select(tp,1,1,nil)
	Duel.SendtoHand(sg,nil,REASON_EFFECT)
end
