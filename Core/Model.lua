local _, F = ...
local M = {}
F.Model = M
function M.Clamp(n, low, high) return math.max(low, math.min(high, n)) end
function M.Number(n, fallback, low, high)
    if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then return fallback end
    return M.Clamp(n, low, high)
end
function M.SessionRecord(record)
    if type(record) ~= "table" or type(record.started) ~= "number" then return nil end
    record.started = M.Number(record.started, 0, 0, 9999999999)
    record.seconds = M.Number(record.seconds, 0, 0, 31536000)
    record.casts = math.floor(M.Number(record.casts, 0, 0, 10000000))
    record.catches = math.floor(M.Number(record.catches, 0, 0, 10000000))
    record.manualPaused = record.manualPaused == true
    record.zones = type(record.zones) == "table" and record.zones or {}
    return record
end
function M.Defaults(db)
    if type(db) ~= "table" then db = {} end
    if type(db.schema) == "number" and db.schema > 2 then return nil, "Newer saved data detected. Use a newer Fishcraft build." end
    db.schema = 2
    db.ui = type(db.ui) == "table" and db.ui or {}
    local u = db.ui
    u.scale = M.Number(u.scale, 1, .75, 1.5)
    if u.textSize~=0 and u.textSize~=1 and u.textSize~=2 then u.textSize=1 end
    u.x, u.y = M.Number(u.x, .78, 0, 1), M.Number(u.y, .35, 0, 1)
    u.windowX,u.windowY=M.Number(u.windowX,.5,0,1),M.Number(u.windowY,.5,0,1)
    u.trackerX,u.trackerY=M.Number(u.trackerX,.82,0,1),M.Number(u.trackerY,.65,0,1)
    u.tracker=u.tracker==true
    u.minimapAngle = M.Number(u.minimapAngle, 225, 0, 360)
    for k, v in pairs({ locked = false, reducedMotion = false, autoCollapse = true, minimap = true }) do
        if type(u[k]) ~= "boolean" then u[k] = v end
    end
    db.settings = type(db.settings) == "table" and db.settings or {}
    if type(db.settings.trackSessions) ~= "boolean" then db.settings.trackSessions = true end
    if type(db.settings.autoStartSession) ~= "boolean" then db.settings.autoStartSession = true end
    local idle=db.settings.sessionIdleSeconds
    if idle~=0 and idle~=120 and idle~=300 and idle~=600 then idle=300 end
    db.settings.sessionIdleSeconds=idle
    -- 0.8.0-0.8.2 persisted Stop as an implicit auto-start disable. Retire it.
    db.sessionStopped=nil
    if type(db.settings.trackCollection) ~= "boolean" then db.settings.trackCollection = true end
    if type(db.settings.preferredPole) ~= "number" then db.settings.preferredPole = nil end
    if type(db.settings.preferredLure) ~= "number" then db.settings.preferredLure = nil end
    local history = {}
    for _, record in ipairs(type(db.history) == "table" and db.history or {}) do
        local clean = M.SessionRecord(record)
        if clean then history[#history + 1] = clean end
    end
    db.history = history
    db.activeSession = M.SessionRecord(db.activeSession)
    while #db.history > 30 do table.remove(db.history, 1) end
    if type(db.equipment) ~= "table" then db.equipment = nil end
    db.collection = type(db.collection) == "table" and db.collection or {}
    for id, record in pairs(db.collection) do
        if type(id) ~= "number" or type(record) ~= "table" then db.collection[id] = nil
        else
            record.count = math.floor(M.Number(record.count, 0, 0, 100000000))
            record.first = M.Number(record.first, 0, 0, 9999999999)
            record.last = M.Number(record.last, record.first, 0, 9999999999)
            record.name = type(record.name) == "string" and record.name or ("Item " .. id)
            record.firstZone = type(record.firstZone)=="string" and record.firstZone or nil
            record.firstSubzone = type(record.firstSubzone)=="string" and record.firstSubzone or nil
            record.zones = type(record.zones) == "table" and record.zones or {}
            for zone, count in pairs(record.zones) do
                if type(zone) ~= "string" then record.zones[zone] = nil else record.zones[zone] = M.Number(count, 0, 0, 100000000) end
            end
        end
    end
    db.cooking = type(db.cooking) == "table" and db.cooking or {}
    db.cooking.current = math.floor(M.Number(db.cooking.current, 1, 1, 300))
    db.cooking.target = math.floor(M.Number(db.cooking.target, 150, 1, 300))
    db.cooking.buffer = db.cooking.buffer == true
    db.cooking.active = db.cooking.active == true
    if type(db.cooking.auto)~="boolean" then db.cooking.auto=true end
    db.optimizer = type(db.optimizer)=="table" and db.optimizer or {}
    local o=db.optimizer
    if type(o.enabled)~="boolean" then o.enabled=true end
    o.useRecommended=o.useRecommended==true;o.keepLure=o.keepLure==true
    if type(o.target)~="number" or o.target~=o.target or o.target<1 or o.target>1000 or type(o.zone)~="string" or type(o.subzone)~="string" then
        o.target,o.zone,o.subzone=nil,nil,nil
    else o.target=math.floor(o.target) end
    return db
end
-- UIParent logical coordinates; label footprints are included in edge checks.
function M.Layout(x, y, width, height, scale)
    local radius, halfW, halfH = 106, 48, 44
    local left, right = x < 165 * scale, width - x < 165 * scale
    local bottom, top = y < 165 * scale, height - y < 165 * scale
    local start, span = 90, 360
    if (left or right) and (bottom or top) then
        radius, span = 290, 90
        start = left and (bottom and 0 or -90) or (bottom and 90 or 180)
    elseif left then start, span, radius = -90, 180, 176
    elseif right then start, span, radius = 90, 180, 176
    elseif bottom then start, span, radius = 0, 180, 176
    elseif top then start, span, radius = 180, 180, 176 end
    radius = radius * .90
    local points = {}
    for i = 1, 6 do
        local degrees = start + (i - 1) * span / (span == 360 and 6 or 5)
        -- Slightly inset corner endpoints so the closer labels remain separated.
        if span == 90 then degrees = start + 2 + (i - 1) * 86 / 5 end
        local a = math.rad(degrees)
        local px = M.Clamp(x + math.cos(a) * radius * scale, halfW * scale, width - halfW * scale)
        local py = M.Clamp(y + math.sin(a) * radius * scale, halfH * scale, height - halfH * scale)
        points[i] = { x = (px - x) / scale, y = (py - y) / scale }
    end
    return points, span
end
-- One reversible timeline: shared upward lift, then curved fan from twelve o'clock.
-- Clamp the whole path, not just the final layout, to protect screen-edge anchors.
function M.RadialPose(point, progress, bounds)
    if progress>=1 then return point.x,point.y,1,1 end
    local function smooth(t) t=M.Clamp(t,0,1);return M.Clamp(t*t*t*(t*(t*6-15)+10),0,1) end
    local lift=smooth(progress/.28)
    local fan=smooth((progress-.28)/.72)
    local start,stage=math.min(16,bounds.top),math.min(98*.90,bounds.top)
    local radius=math.sqrt(point.x*point.x+point.y*point.y)
    local angle=radius>0 and math.acos(M.Clamp(point.y/radius,-1,1)) or 0
    if point.x<0 then angle=-angle end
    local x,y
    if progress<=.28 then x,y=0,start+(stage-start)*lift
    else
        local distance=stage+(radius-stage)*fan
        x,y=math.sin(angle*fan)*distance,math.cos(angle*fan)*distance
    end
    return M.Clamp(x,bounds.left,bounds.right),M.Clamp(y,bounds.bottom,bounds.top),lift,smooth((fan-.55)/.45)
end
function M.Choose(items, preferred)
    for _, item in ipairs(items) do if item.id == preferred then return item end end
    -- Only compare bonuses if every candidate has a verified value.
    local best, allKnown = items[1], #items > 0
    for _, item in ipairs(items) do if type(item.bonus) ~= "number" then allKnown = false end end
    if allKnown then
        for _, item in ipairs(items) do if item.bonus > best.bonus then best = item end end
    end
    return best, allKnown
end
function M.Same(a, b)
    if not a or not b then return a == b end
    if a.guid and b.guid then return a.guid == b.guid end
    return a.link == b.link
end
function M.RestoreStep(snapshot, current, bagItems)
    if not snapshot then return nil, "No saved equipment." end
    -- Clear the off hand before restoring a two-handed main hand, if needed.
    local order = snapshot.off == false and { 17, 16 } or { 16, 17 }
    for _, slot in ipairs(order) do
        local wanted
        if slot == 16 then wanted = snapshot.main else wanted = snapshot.off end
        local actual = current[slot] or false
        if not M.Same(wanted, actual) then
            if wanted == false then return { slot = slot, empty = true } end
            if type(wanted) ~= "table" or not wanted.link then return nil, "Saved equipment data is incomplete." end
            local matches = {}
            for _, item in ipairs(bagItems) do if M.Same(wanted, item) then table.insert(matches, item) end end
            if #matches ~= 1 then return nil, #matches == 0 and "Saved item is missing from your bags." or "More than one matching item. Restore it manually." end
            if matches[1].locked then return nil, "Saved item is locked. Try again." end
            return { slot = slot, item = matches[1] }
        end
    end
    return { done = true }
end
function M.Duration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
