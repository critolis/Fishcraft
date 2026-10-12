local _, F = ...
function F:Refresh()
    if not self.ready then return end
    if self.API.Locked() then self.dirty = true; return end
    self.dirty = false
    self.spellID, self.spellName = self.API.FishingSpell()
    self.Equipment:Scan(); self.Lures:Scan()
    self.Optimizer:Refresh()
    self.Cooking:Refresh()
    if self.Radial.root then self.Radial:Refresh() end
    self.Panels:Refresh()
end
function F:QueueRefresh()
    if self.refreshQueued then return end
    self.refreshQueued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(.1, function() self.refreshQueued = false; self:Refresh() end)
    else self.refreshQueued = false; self:Refresh() end
end
function F:Initialize()
    if self.ready then return end
    if self.API.Locked() then
        if not self.waitingForCombat then
            self.waitingForCombat = true
            self:Register("PLAYER_REGEN_ENABLED", function() if not self.ready then self:Initialize() end end)
        end
        return
    end
    local db, message = self.Model.Defaults(FishcraftDB)
    if not db then self:Say(message); return end
    FishcraftDB, self.db = db, db
    self.Statistics:Initialize(db)
    self.compatible, self.build, self.interface = self.API.Supported()
    if not RegisterStateDriver then self.compatible = false end
    self.ready = true
    self.Collection:Initialize()
    self:Refresh(); self.Panels:Create(); self.Radial:Create()
    if type(db.activeSession) == "table" then
        self.Session.current = db.activeSession; self.Session.runningSince = nil
        db.activeSession = nil
    end
    self:Register("UNIT_SPELLCAST_SUCCEEDED", function(unit,guid,id)
        self.Session:Cast(unit,guid,id,"UNIT_SPELLCAST_SUCCEEDED")
        if self.API.Readable(unit) and self.API.Readable(id) and unit=="player" and self.Data.recipes[id] then self:QueueRefresh() end
    end)
    self:Register("UNIT_SPELLCAST_CHANNEL_START",function(unit,guid,id)
        self.Session:Cast(unit,guid,id,"UNIT_SPELLCAST_CHANNEL_START")
    end)
    self:Register("PLAYER_LOGOUT", function() self.Session:Pause(true); db.activeSession = self.Session.current end)
    for _,event in ipairs({"UNIT_SPELLCAST_CHANNEL_STOP","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_FAILED"}) do
        self:Register(event,function(...) self.Statistics:ChannelEnded(...) end)
    end
    self:Register("PLAYER_REGEN_DISABLED", function()
        if self.Radial.dragging then self.Radial:StopDrag() end
        self.dirty = true
    end)
    self:Register("PLAYER_REGEN_ENABLED", function() self:Refresh(); self.Radial:ApplySettings() end)
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "SPELLS_CHANGED", "SKILL_LINES_CHANGED", "GET_ITEM_INFO_RECEIVED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED" }) do
        self:Register(event, function() self:QueueRefresh() end)
    end
    for _, event in ipairs({ "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
        self:Register(event, function() self.Radial:ApplySettings();self.Panels:Place(self.Panels.window,"windowX","windowY");self.Panels:Place(self.Panels.tracker,"trackerX","trackerY") end)
    end
    self:Register("UNIT_AURA",function(unit) if self.API.Readable(unit) and unit=="player" then self:QueueRefresh() end end)
    self:Register("ZONE_CHANGED_INDOORS",function() self:QueueRefresh() end)
    self:On("SESSION_UPDATED", function()
        self.Panels:Refresh()
        if self.Radial.root then self.Radial:Refresh() end
    end)
    self:On("COLLECTION_UPDATED", function() self.Panels:Refresh() end)
    -- Refresh lure expiration while visible/idle without a permanent OnUpdate loop.
    if C_Timer and C_Timer.NewTicker then
        self.sessionTicker=C_Timer.NewTicker(1,function() self.Session:Tick() end)
        self.lureTicker = C_Timer.NewTicker(5, function()
            if not self.API.Locked() then self.Lures:Scan(); self.Optimizer:Refresh(); self.Radial:Refresh(); self.Panels:RefreshSettings() end
        end)
    end
    if not self.compatible then self:Say("Client interface " .. tostring(self.interface) .. ": gameplay actions disabled; target is 16001.") end
    self:Refresh()
    self:Say(self.version .. " ready. /fishcraft opens quick actions; right-click the hook for settings.")
end
F:Register("PLAYER_LOGIN", function() F:Initialize() end)
SLASH_FISHCRAFT1 = "/fishcraft"
SLASH_FISHCRAFT2 = "/fc"
SlashCmdList.FISHCRAFT = function(message)
    if not F.ready then return end
    local cmd = (message or ""):match("^%s*(%S*)"):lower()
    if cmd == "settings" then F.Panels:Toggle("settings")
    elseif cmd == "journal" then F.Panels:Toggle("journal")
    elseif cmd == "locations" then F.Panels:Toggle("locations")
    elseif cmd == "cooking" then F.Panels:Toggle("cooking")
    elseif cmd == "gear" then F.Panels:Toggle("gear")
    elseif cmd == "optimizer" then F.Panels.settingsTab="optimizer";F:Refresh();F.Panels:OpenSection("settings")
    elseif cmd == "tracker" then F.Panels:SetTracker(not F.db.ui.tracker)
    elseif cmd == "stats" then F.Panels:Toggle("stats")
    elseif cmd == "diag" then
        F:Say("Version " .. F.version .. " / build " .. tostring(F.build) .. " / interface " .. tostring(F.interface))
        F:Say("Fishing spell: " .. tostring(F.spellID) .. " / poles: " .. #F.Equipment.poles .. " / lures: " .. #F.Lures.items)
        F:Say("Session: "..(F.Session.runningSince and "recording" or F.Session.current and F.Session.current.manualPaused and "manually paused" or "ready").." / recording enabled: "..tostring(F.db.settings.trackSessions).." / auto-start: "..tostring(F.db.settings.autoStartSession))
        F:Say("Last Fishing event: "..tostring(F.Session.lastEvent or "none").." / spell: "..tostring(F.Session.lastCastID or "none"))
        F:Say("Secure actions: " .. tostring(F.compatible) .. " / combat: " .. tostring(not not F.API.Locked()))
        local snapshot=F.db.equipment
        F:Say("Weapons saved: "..tostring(snapshot~=nil).." / phase: "..tostring(snapshot and snapshot.phase).." / pole observed: "..tostring(snapshot and snapshot.poleObserved))
    elseif cmd == "reset" then
        if F.API.Locked() then F:Say("Reset the launcher after combat."); return end
        F.db.ui.x, F.db.ui.y, F.db.ui.scale = .78, .35, 1; F.Radial:ApplySettings()
    elseif cmd == "" then F.Radial:Toggle()
    else F:Say("/fc [settings | gear | optimizer | journal | locations | cooking | stats | tracker | reset | diag]") end
end
