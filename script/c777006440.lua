--Shinato, King of the Sacred Plane
--Scripted by Codex
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Ritual Summon this card from the hand
	local e1=Ritual.CreateProc({
		handler=c,
		lvtype=RITPROC_GREATER,
		filter=aux.FilterBoolFunction(Card.IsCode,id),
		extrafil=s.extrafil,
		extraop=s.extraop,
		location=LOCATION_HAND
	})
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER|TIMING_MAIN_END)
	e1:SetCondition(s.ritcon)
	e1:SetCost(s.ritcost)
	c:RegisterEffect(e1)
	--Cannot be destroyed by card effects while you have more LP
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.indcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--Gain 500 LP when a card is sent to the opponent's GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD|EFFECT_TYPE_TRIGGER_F)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET|EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.reccon)
	e3:SetTarget(s.rectg)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
	--Gain LP when this card destroys a monster by battle
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_RECOVER)
	e4:SetType(EFFECT_TYPE_SINGLE|EFFECT_TYPE_TRIGGER_F)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetCode(EVENT_BATTLE_DESTROYING)
	e4:SetCondition(aux.bdocon)
	e4:SetTarget(s.battg)
	e4:SetOperation(s.batop)
	c:RegisterEffect(e4)
end
s.listed_names={id}

function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.ritcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
end
function s.gymatfilter(c)
	return c:IsMonster() and c:IsType(TYPE_SPIRIT) and c:HasLevel() and c:IsAbleToRemove()
end
function s.oppmatfilter(c,e)
	return c:IsFaceup() and c:HasLevel() and c:IsReleasable() and not c:IsImmuneToEffect(e)
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.gymatfilter,tp,LOCATION_GRAVE,0,nil)
	if Duel.GetLP(tp)>Duel.GetLP(1-tp) then
		g:Merge(Duel.GetMatchingGroup(s.oppmatfilter,tp,0,LOCATION_MZONE,nil,e))
	end
	if chk==0 then return g end
	return g:Filter(function(c)
		return not c:IsLocation(LOCATION_GRAVE) or aux.nvfilter(c)
	end,nil)
end
function s.extraop(mat,e,tp,eg,ep,ev,re,r,rp,tc)
	local gy=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	mat:Sub(gy)
	if #mat>0 then
		Duel.ReleaseRitualMaterial(mat)
	end
	if #gy>0 then
		Duel.Remove(gy,POS_FACEUP,REASON_EFFECT|REASON_MATERIAL|REASON_RITUAL)
	end
end

function s.indcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetLP(tp)>Duel.GetLP(1-tp)
end

function s.recfilter(c,tp)
	return c:IsControler(1-tp) and c:IsLocation(LOCATION_GRAVE)
end
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.recfilter,1,nil,tp)
end
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(500)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500)
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local p,amount=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,amount,REASON_EFFECT)
end

function s.battg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetHandler():GetBattleTarget()
	local amount=bc and math.max(bc:GetBaseAttack(),bc:GetBaseDefense(),0) or 0
	if chk==0 then return amount>0 end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(amount)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,amount)
end
function s.batop(e,tp,eg,ep,ev,re,r,rp)
	local p,amount=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	if amount>0 then
		Duel.Recover(p,amount,REASON_EFFECT)
	end
end
