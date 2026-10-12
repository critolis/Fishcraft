local name, F = ...
F.name, F.version = name, "1.0.0"
F.modules, F.listeners = {}, {}
function F:On(event, callback)
    self.listeners[event] = self.listeners[event] or {}
    table.insert(self.listeners[event], callback)
end
function F:Emit(event, ...)
    for _, callback in ipairs(self.listeners[event] or {}) do callback(...) end
end
function F:Say(message)
    print("|cffE7C789Fishcraft|r  " .. tostring(message))
end
F.frame = CreateFrame("Frame")
F.frame:SetScript("OnEvent", function(_, event, ...) F:Emit(event, ...) end)
function F:Register(event, callback)
    local ok = pcall(self.frame.RegisterEvent, self.frame, event)
    if ok then self:On(event, callback) end
    return ok
end
