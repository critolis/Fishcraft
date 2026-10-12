local _, F = ...
local R, U, T, A = { buttons = {}, opened = false }, F.UI, F.Theme, F.API
F.Radial = R
function R:LocationLines()
    local zone, sub = A.Zone()
    local rank, bonus, maximum = A.Skill()
    local lines = { sub ~= "" and (zone .. " / " .. sub) or zone }
    lines[#lines + 1] = rank and string.format(F.L["Fishing: %d + %d / %d"], rank, bonus or 0, maximum or 0) or F.L["Fishing skill unavailable"]
    for _, line in ipairs(F.Locations:Summary(zone)) do lines[#lines + 1] = line end
    local goal = F.Cooking:GoalText()
    if goal then lines[#lines + 1] = goal end
    for _,line in ipairs(F.Optimizer:Lines()) do lines[#lines+1]=line end
    lines[#lines + 1] = F.L["Click: quick actions · Right-click: settings · Drag: move"]
    return lines
end
function R:Create()
    self.root = CreateFrame("Frame", "FishcraftRadial", UIParent, "SecureHandlerStateTemplate")
    self.root:SetSize(44, 44); self.root:SetMovable(true); self.root:SetFrameStrata("HIGH")
    -- Visibility changes in combat are performed by the secure state driver.
    if RegisterStateDriver then RegisterStateDriver(self.root, "visibility", "[combat] hide; show") end
    self.launcher = U.Orb(self.root, "FishcraftLauncher", T.media .. "Hook", T.launcher)
    self.launcher:SetPoint("CENTER"); self.launcher:RegisterForDrag("LeftButton")
    self.dragDriver = CreateFrame("Frame", nil, UIParent)
    self.launcher:SetScript("OnDragStart", function()
        if A.Locked() or F.db.ui.locked then return end
        self:Close(true); self.dragging = true
        local cx, cy = GetCursorPosition()
        local x, y = self.root:GetCenter()
        local parentScale = UIParent:GetEffectiveScale()
        local ratio = self.root:GetEffectiveScale() / parentScale
        local dx, dy = cx / parentScale - x * ratio, cy / parentScale - y * ratio
        self.dragDriver:SetScript("OnUpdate", function()
            if A.Locked() then self:StopDrag(); return end
            local mouseX, mouseY = GetCursorPosition()
            local w, h = UIParent:GetWidth(), UIParent:GetHeight()
            local margin = 52 * self.scale
            local px = F.Model.Clamp(mouseX / parentScale - dx, margin, w - margin)
            local py = F.Model.Clamp(mouseY / parentScale - dy, margin, h - margin)
            F.db.ui.x, F.db.ui.y = px / w, py / h
            self.root:ClearAllPoints(); self.root:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px / self.scale, py / self.scale)
        end)
    end)
    self.launcher:SetScript("OnDragStop", function()
        if not self.dragging then return end
        self:StopDrag()
        if not A.Locked() then self:ApplySettings() end
    end)
    self.launcher:SetScript("OnClick", function(_, button)
        if A.Locked() then return end
        if button == "RightButton" then F.Panels:Toggle("settings") else self:Toggle() end
    end)
    U.Tip(self.launcher, "Fishcraft", function() return self:LocationLines() end)
    local specs = {
        { "Fishing pole", "pole" }, { "Lure", "lure", nil, true },
        { "Location info", "location" }, { "Journal", "journal", "journal" },
        { "Fishing session", "session" }, { "Settings", "settings", "settings" },
    }
    for i, spec in ipairs(specs) do
        local b = U.Orb(self.root, "FishcraftAction" .. i, T.icons[spec[2]], T.action, spec[4])
        b.icon:SetSize(T.action * T.actionIconScale, T.action * T.actionIconScale)
        b.label = U.Text(b, spec[1], 11, T.bright, true, "OUTLINE"); b.label:SetPoint("TOP", b, "BOTTOM", 0, -5)
        b.label:SetShadowColor(0,0,0,1)
        b.label:SetWidth(94); b.label:SetJustifyH("CENTER")
        b.dot = b:CreateTexture(nil, "OVERLAY"); b.dot:SetTexture(T.media .. "Dot"); b.dot:SetSize(11, 11); b.dot:SetPoint("TOPRIGHT", -2, -2)
        if spec[3] then b:SetScript("OnClick", function() if not A.Locked() then F.Panels:Toggle(spec[3]); self:AfterAction() end end) end
        if i == 1 then b:SetScript("OnClick", function() if not A.Locked() then F.Equipment:Toggle(); self:AfterAction() end end) end
        if i == 3 then b:SetScript("OnClick", function() if not A.Locked() then F.Panels:OpenCurrentLocation();self:AfterAction() end end) end
        if i == 5 then b:SetScript("OnClick", function() if not A.Locked() then F.Session:Toggle();self:AfterAction() end end) end
        if spec[4] then b:SetScript("PostClick", function(_, _, down) if not down then self:AfterAction() end end) end
        if i == 2 then b:SetScript("PreClick", function() if not A.Locked() then F:Refresh() end end) end
        U.Tip(b, spec[1], function()
            if i == 1 then return { F.db.equipment and F.L["Click to swap back to your saved main-hand and off-hand equipment."] or F.L["Click to save your weapons and equip your preferred pole."], F.L["Pole and lure preferences are in Settings > Equipment."] }
            elseif i == 2 then
                local lines={F.Lures:Status(),F.L["Click to apply the selected lure. Active enchantments are preserved."]}
                for _,line in ipairs(F.Optimizer:Lines()) do lines[#lines+1]=line end
                return lines
            elseif i == 3 then
                local lines=self:LocationLines();lines[#lines]="Click to open your current fishing location.";return lines
            elseif i == 4 then return { F.L["Browse your collection, fishing locations, sessions and Cooking Planner."] }
            elseif i == 5 then
                local idle=F.db.settings.sessionIdleSeconds
                return {
                    not F.db.settings.trackSessions and "Enable session recording in Settings > General."
                        or F.Session.runningSince and "Click to stop and save this session."
                        or "Click to start or resume session recording.",
                    F.Session.current and F.Session.current.manualPaused and "Manually paused. Click Start to resume."
                        or F.db.settings.autoStartSession and "Your next Fishing cast automatically starts a session."
                        or "Automatic start is off in Settings > General.",
                    "Recorded time: "..F.Model.Duration(F.Session:Elapsed()),
                    idle>0 and ("Auto-stop after "..math.floor(idle/60).." minutes without fishing activity.") or "Idle auto-stop is off.",
                    "Statistics and session history are in Journal > Statistics.",
                }
            else return { spec[1] } end
        end)
        b:Hide(); self.buttons[i] = b
    end
    if Minimap then
        self.minimap = U.Orb(Minimap, "FishcraftMinimap", T.media .. "Hook", 30)
        self.minimap:SetFrameStrata("MEDIUM")
        self.minimap:SetScript("OnClick", function(_, button)
            if A.Locked() then F:Say(F.L["Fishcraft quick actions are available after combat."]); return end
            if button == "RightButton" then F.Panels:Toggle("settings") else self:Toggle() end
        end)
        U.Tip(self.minimap, "Fishcraft", { "Click: quick actions", "Right-click: settings" })
    end
    self:ApplySettings()
end
function R:StopDrag()
    self.dragging = false
    self.dragDriver:SetScript("OnUpdate", nil)
end
function R:ApplySettings()
    if A.Locked() then F.dirty = true; return end
    self:Close(true)
    local u, w, h = F.db.ui, UIParent:GetWidth(), UIParent:GetHeight()
    self.scale = math.min(u.scale, w / 850, h / 650)
    self.root:SetScale(self.scale)
    local margin = 52 * self.scale
    local x, y = F.Model.Clamp(u.x * w, margin, w - margin), F.Model.Clamp(u.y * h, margin, h - margin)
    self.root:ClearAllPoints(); self.root:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / self.scale, y / self.scale)
    self.points = F.Model.Layout(x, y, w, h, self.scale)
    self.motionBounds = { left=48-x/self.scale, right=(w-x)/self.scale-48,
        bottom=44-y/self.scale, top=(h-y)/self.scale-44 }
    if self.minimap then
        local angle = math.rad(u.minimapAngle)
        self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * (Minimap:GetWidth() / 2 + 4), math.sin(angle) * (Minimap:GetHeight() / 2 + 4))
        self.minimap:SetShown(u.minimap)
    end
    self:Refresh()
end
function R:Animate(open, instant)
    if A.Locked() then return end
    self.root:SetScript("OnUpdate", nil)
    self.opened = open
    GameTooltip:Hide()
    if open then for _, b in ipairs(self.buttons) do b:Show() end end
    local target=open and 1 or 0
    local duration=open and T.duration or T.closeDuration
    local immediate=instant or F.db.ui.reducedMotion
    -- Keep progress when reversing a partly completed animation: no position jump.
    self.motionProgress=self.motionProgress or 0
    local function tick(_, dt)
        if A.Locked() then self.root:SetScript("OnUpdate", nil); return end
        self.motionProgress=immediate and target or F.Model.Clamp(self.motionProgress+(open and 1 or -1)*dt/duration,0,1)
        local finished=self.motionProgress==target
        for i, b in ipairs(self.buttons) do
            local x,y,alpha,detail=F.Model.RadialPose(self.points[i],self.motionProgress,self.motionBounds)
            b:ClearAllPoints();b:SetPoint("CENTER",self.root,"CENTER",x,y)
            b:SetAlpha(alpha);b.label:SetAlpha(detail);b.dot:SetAlpha(detail)
            b:EnableMouse(open and finished)
        end
        if finished then
            self.root:SetScript("OnUpdate", nil)
            if not open then for _, b in ipairs(self.buttons) do b:Hide() end end
        end
    end
    -- Place hidden/reversing icons immediately, and disable overlapping hit areas.
    tick(nil,0)
    if not immediate and self.motionProgress~=target then self.root:SetScript("OnUpdate",tick) end
end
function R:Close(instant)
    if not self.points then return end
    self:Animate(false, instant); GameTooltip:Hide()
end
function R:Toggle()
    if A.Locked() then return end
    if self.opened then self:Close() else F:Refresh(); self:Animate(true) end
end
function R:AfterAction()
    if A.Locked() then return end
    if F.db.ui.autoCollapse then self:Close() end
end
function R:Refresh()
    if A.Locked() then return end
    local E, L = F.Equipment, F.Lures
    local pole = E.main and E.main.pole
    local saved = F.db.equipment and F.db.equipment.main
    self.buttons[1].label:SetText(F.db.equipment and F.L["Swap back"] or F.L["Fishing pole"])
    self.buttons[1].icon:SetTexture((saved and saved.icon) or (F.db.equipment and "Interface\\Icons\\INV_Sword_04") or (pole and E.main.icon) or (E.selected and E.selected.icon) or T.icons.pole)
    self.buttons[2].icon:SetTexture((L.selected and L.selected.icon) or T.icons.lure)
    self.buttons[1].dot:SetVertexColor(unpack(pole and T.green or T.amber))
    self.buttons[2].dot:SetVertexColor(unpack(L.active and T.green or T.amber))
    local advice=F.Optimizer.result
    self.buttons[3].dot:SetVertexColor(unpack(advice and advice.target and T.amber or T.muted))
    for i = 4, 6 do self.buttons[i].dot:Hide() end
    self.buttons[5].label:SetText(F.Session.runningSince and "Stop session" or "Start session")
    self.buttons[5].icon:SetTexture(F.Session.runningSince and T.icons.sessionStop or T.icons.session)
    L:Configure(self.buttons[2])
end
