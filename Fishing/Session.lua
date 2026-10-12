local _, F = ...
local S = { seen = {} }
F.Session = S
function S:Start()
    if not F.db.settings.trackSessions then F:Say("Enable session recording in Settings > General first.");return end
    self.current = self.current or { started = time(), seconds = 0, casts = 0, zones = {} }
    self.current.manualPaused = false
    if not self.runningSince then self.recordingWindow={};self:Touch() end
    self.runningSince = self.runningSince or GetTime()
    F:Emit("SESSION_UPDATED")
end
function S:Touch()
    self.lastActivity=GetTime()
end
function S:Elapsed(at)
    return self.current and (self.current.seconds + (self.runningSince and math.max(0,(at or GetTime()) - self.runningSince) or 0)) or 0
end
function S:Pause(system,at)
    F.Statistics:Tick()
    F.Statistics:DiscardPending()
    if self.current then self.current.seconds = self:Elapsed(at);if not system then self.current.manualPaused=true end end
    self.runningSince = nil
    self.recordingWindow = nil
    F:Emit("SESSION_UPDATED")
end
function S:Finish(at,reason)
    self:Pause(false,at)
    if self.current then
        self.current.ended = time()-math.max(0,GetTime()-(at or GetTime()))
        self.current.endReason=reason
        F.Statistics:Archive(self.current)
        table.insert(F.db.history, self.current)
        while #F.db.history > 30 do table.remove(F.db.history, 1) end
    end
    self.current, self.seen, self.lastActivity = nil, {}, nil
    F:Emit("SESSION_UPDATED")
end
function S:Stop(manual,at)
    self:Finish(at,manual==false and "idle" or "manual")
end
function S:Toggle()
    if self.runningSince then self:Stop(true) else self:Start() end
end
function S:Tick()
    F.Statistics:Tick()
    local timeout=F.db.settings.sessionIdleSeconds or 300
    if self.runningSince and self.lastActivity and timeout>0 and GetTime()>=self.lastActivity+timeout then
        self:Stop(false,self.lastActivity+timeout)
        F:Say("Fishing session saved after "..math.floor(timeout/60).." minutes idle."..(F.db.settings.autoStartSession and " Your next cast starts a new session." or " Click Start session when ready."))
    end
end
function S:Cast(unit, guid, id, event)
    if not F.API.Readable(unit) or unit ~= "player" or not F.API.IsFishingSpell(id) or not F.API.Readable(guid) or not guid then return end
    self.lastEvent=event or self.lastEvent;self.lastCastID=id
    -- Both events describe one cast. Keep this guard across Stop/Start boundaries.
    if self.lastObservedGUID==guid then return end
    self.lastObservedGUID=guid
    if not F.db.settings.trackSessions or self.seen[guid] then return end
    self:Tick()
    if not self.runningSince and F.db.settings.autoStartSession and (not self.current or not self.current.manualPaused) then self:Start() end
    if not self.runningSince or self.seen[guid] then return end
    self.seen[guid] = true
    self:Touch()
    self.current.casts = self.current.casts + 1
    F.Statistics:Cast(guid)
    local zone = F.API.Zone()
    self.current.zones[zone] = true
    -- Keep deduplication memory bounded; cast GUIDs are unique per cast.
    if self.current.casts % 500 == 0 then self.seen = { [guid] = true } end
    F:Emit("SESSION_UPDATED")
end
