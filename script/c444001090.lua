-- The Angler of Vampire Castle
local s, id = GetID()
local SET_VAMPIRE = 0x8e

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- 0. Synchro Summon procedure (baseado no Chaos Angel)
    Synchro.AddProcedure(c, s.tfilter, 1, 1, Synchro.NonTuner(nil), 1, 99, s.exmatfilter)

    -- 1. Each player must pay 500 LP to Special Summon from the Extra Deck, except "Vampire" monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_COST)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_EXTRA, LOCATION_EXTRA)
    e1:SetTarget(s.sumtg)
    e1:SetCost(s.ccost)
    e1:SetOperation(s.acop)
    c:RegisterEffect(e1)

    -- 2. Monsters Special Summoned from the GY become Zombie monsters
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CHANGE_RACE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
    e2:SetTarget(s.zomtg)
    e2:SetValue(RACE_ZOMBIE)
    c:RegisterEffect(e2)

    -- 3. Send top card of Deck to GY; Special Summon 1 monster from opponent's GY to either field in Defense Position, negate effects (HOPT)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1, id)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    -- 4. If destroyed by opponent's card effect: Pay 1000 LP instead, banish until next Standby Phase
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetCode(EFFECT_DESTROY_REPLACE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTarget(s.reptg)
    e4:SetOperation(s.repop)
    c:RegisterEffect(e4)
end

s.listed_series={SET_VAMPIRE}

-- ==========================================
-- 0. SYNCHRO PROCEDURE
-- ==========================================
-- sub1: monstro que você controla mas cujo dono é o oponente vale como Regulador
function s.exmatfilter(c, scard, sumtype, tp)
	return c:GetOwner() ~= c:GetControler()
end

-- f1: só vale para Reguladores "de verdade"
function s.tfilter(c, scard, sumtype, tp)
    return c:IsSetCard(SET_VAMPIRE, scard, sumtype, tp)
        or c:IsRace(RACE_ZOMBIE, scard, sumtype, tp)
end

-- ==========================================
-- 1 & 2. EXTRA DECK LP TAX & GY ZOMBIE CHANGE
-- ==========================================
function s.sumtg(e, c)
    return not c:IsSetCard(SET_VAMPIRE)
end

function s.ccost(e, c, tp)
    return Duel.CheckLPCost(tp, 500)
end

function s.acop(e, tp, eg, ep, ev, re, r, rp)
    Duel.PayLPCost(tp, 500)
end

function s.zomtg(e, c)
    return c:IsSummonLocation(LOCATION_GRAVE)
end

-- ==========================================
-- 3. MILL 1; SPECIAL SUMMON FROM OPPONENT'S GY TO EITHER FIELD
-- ==========================================
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk==0 then return Duel.IsPlayerCanDiscardDeckAsCost(tp, 1) end
    Duel.DiscardDeck(tp, 1, REASON_COST)
end

function s.spfilter(c, e, tp)
    local b1 = Duel.GetLocationCount(tp, LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE)
    local b2 = Duel.GetLocationCount(1-tp, LOCATION_MZONE, tp)>0
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE, 1-tp)
    return b1 or b2
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter, tp, 0, LOCATION_GRAVE, 1, nil, e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, 1-tp, LOCATION_GRAVE)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.spfilter), tp, 0, LOCATION_GRAVE, 1, 1, nil, e, tp)
    local tc=g:GetFirst()
    if not tc then return end

    local b1 = Duel.GetLocationCount(tp, LOCATION_MZONE)>0
        and tc:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE)
    local b2 = Duel.GetLocationCount(1-tp, LOCATION_MZONE, tp)>0
        and tc:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP_DEFENSE, 1-tp)
    if not (b1 or b2) then return end

    local op=Duel.SelectEffect(tp,
        {b1, aux.Stringid(id, 1)},
        {b2, aux.Stringid(id, 2)})
    local target_p = (op==1) and tp or (1-tp)

    if Duel.SpecialSummonStep(tc, 0, tp, target_p, false, false, POS_FACEUP_DEFENSE) then
        local c=e:GetHandler()
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        tc:RegisterEffect(e2)
    end
    Duel.SpecialSummonComplete()
end

-- ==========================================
-- 4. DESTRUCTION REPLACEMENT (PAY 1000 LP & TEMP BANISH)
-- ==========================================
function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsFaceup() and not c:IsReason(REASON_REPLACE)
        and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
        and Duel.CheckLPCost(tp, 1000) and c:IsAbleToRemove() end
    return Duel.SelectEffectYesNo(tp, c, aux.Stringid(id, 3))
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
    local c=e:GetHandler()
    Duel.PayLPCost(tp, 1000)
    if Duel.Remove(c, POS_FACEUP, REASON_EFFECT+REASON_REPLACE+REASON_TEMPORARY)>0 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
        e1:SetLabelObject(c)
        e1:SetCountLimit(1)
        if Duel.IsPhase(PHASE_STANDBY) then
            e1:SetLabel(Duel.GetTurnCount())
            e1:SetCondition(s.retcon)
            e1:SetReset(RESET_PHASE+PHASE_STANDBY, 2)
        else
            e1:SetReset(RESET_PHASE+PHASE_STANDBY)
        end
        e1:SetOperation(s.retop)
        Duel.RegisterEffect(e1, tp)
    end
end

function s.retcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnCount()~=e:GetLabel()
end

function s.retop(e, tp, eg, ep, ev, re, r, rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_REMOVED) then
        Duel.ReturnToField(tc)
    end
end