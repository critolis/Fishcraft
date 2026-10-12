local _, F = ...
local S = { pending = {} }
F.Statistics = S
local fields={"seconds","casts","catches","measuredCasts","resolvedCasts","successes","lootSeconds","lootSamples"}
function S:Clean(row)
    row=type(row)=="table" and row or {}
    -- Older releases measured all casts. Preserve that historical denominator once.
    if row.resolvedCasts==nil then row.resolvedCasts=row.measuredCasts or 0 end
    for _,key in ipairs(fields) do row[key]=F.Model.Number(row[key],0,0,1e12) end
    row.items=type(row.items)=="table" and row.items or {}
    for id,value in pairs(row.items) do if type(id)~="number" or value~=true then row.items[id]=nil end end
    return row
end
function S:Add(total,row)
    for _,key in ipairs(fields) do total[key]=total[key]+(row[key] or 0) end
    for id in pairs(row.items or {}) do total.items[id]=true end
end
function S:Initialize(db)
    if type(db.statistics)~="table" then
        local total=self:Clean({sessions=0,since=time(),imported=#db.history>0 or db.activeSession~=nil})
        for _,row in ipairs(db.history) do self:Add(total,self:Clean(row));total.sessions=total.sessions+1 end
        db.statistics=total
    end
    local total=self:Clean(db.statistics)
    total.sessions=F.Model.Number(total.sessions,0,0,1e12)
    total.since=F.Model.Number(total.since,time(),0,9999999999)
    total.imported=total.imported==true
    if db.activeSession then self:Clean(db.activeSession) end
end
function S:Archive(row)
    self:Add(F.db.statistics,self:Clean(row))
    F.db.statistics.sessions=F.db.statistics.sessions+1
end
function S:Cast(guid)
    local token=F.Collection.cast
    if token and token.guid==guid and F.db.settings.trackCollection then
        token.session=self:Clean(F.Session.current);token.window=F.Session.recordingWindow
        token.session.measuredCasts=token.session.measuredCasts+1
        self.pending[token]=true
    end
end
function S:Valid(token)
    return token and not token.abandoned and token.session and token.session==F.Session.current
        and F.Session.runningSince and token.window==F.Session.recordingWindow
end
function S:Resolve(token)
    if self:Valid(token) and not token.resolved then
        token.resolved=true
        token.session.resolvedCasts=token.session.resolvedCasts+1
    end
    self.pending[token]=nil
end
function S:EndCast(token)
    if not self:Valid(token) then return end
    -- Bobber clicks end the channel before loot arrives. Give those events time.
    token.resolveAt=token.resolveAt or (GetTime()+3)
end
function S:ChannelEnded(unit,guid,id)
    if not F.API.Readable(unit) or not F.API.Readable(guid) or not F.API.Readable(id)
        or unit~="player" or not F.API.IsFishingSpell(id) then return end
    local token=F.Collection.cast
    if token and token.guid==guid and self:Valid(token) then self:EndCast(token);F.Session:Touch() end
end
function S:DiscardPending()
    for token in pairs(self.pending) do token.abandoned=true end
    self.pending={}
end
function S:Tick()
    if not F.db.settings.trackCollection then self:DiscardPending();return end
    local changed=false
    for token in pairs(self.pending) do
        if not self:Valid(token) then self.pending[token]=nil
        elseif not token.lootOpen and ((token.resolveAt and GetTime()>=token.resolveAt) or GetTime()-token.at>40) then
            self:Resolve(token);changed=true
        end
    end
    if changed then F:Emit("SESSION_UPDATED") end
end
function S:Recover(row,count)
    local token=row.cast;local session=F.Session
    if not self:Valid(token) or not F.db.settings.trackSessions then return end
    session:Touch()
    local current=self:Clean(session.current)
    current.catches=current.catches+count;current.items[row.id]=true
    if not token.recovered then
        token.recovered=true
        self:Resolve(token)
        current.successes=current.successes+1
        current.lootSeconds=current.lootSeconds+math.max(0,GetTime()-token.at)
        current.lootSamples=current.lootSamples+1
    end
end
function S:Snapshot(currentOnly)
    local total=self:Clean({sessions=0})
    if not currentOnly then self:Add(total,F.db.statistics);total.sessions=F.db.statistics.sessions end
    local session=F.Session
    if session.current then
        self:Add(total,session.current)
        total.seconds=total.seconds-(session.current.seconds or 0)+session:Elapsed()
        total.sessions=total.sessions+1
    end
    total.unique=0;for _ in pairs(total.items) do total.unique=total.unique+1 end
    total.perHour=total.seconds>0 and total.catches*3600/total.seconds or nil
    total.pending=0
    for token in pairs(self.pending) do if self:Valid(token) then total.pending=total.pending+1 end end
    total.success=total.resolvedCasts>0 and total.successes*100/total.resolvedCasts or nil
    total.average=total.lootSamples>0 and total.lootSeconds/total.lootSamples or nil
    return total
end
