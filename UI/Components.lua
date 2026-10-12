local _, F = ...
local U, T = { fonts = {} }, F.Theme
F.UI = U
function U.Font(f,size,fixed,flags)
    f.baseSize,f.fixedSize,f.fontFlags=size or 12,fixed,flags or ""
    U.fonts[#U.fonts+1]=f
    U.UpdateFont(f)
end
function U.UpdateFont(f)
    local extra=(not f.fixedSize and f.baseSize<=16) and (F.db and F.db.ui.textSize or 1) or 0
    f:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",f.baseSize+extra,f.fontFlags)
end
function U.RefreshFonts()
    if F.API.Locked() then return end
    for _,f in ipairs(U.fonts) do U.UpdateFont(f) end
end
function U.Text(parent, text, size, color, fixed, flags)
    local f = parent:CreateFontString(nil, "OVERLAY")
    U.Font(f,size,fixed,flags)
    f:SetText(F.L[text or ""])
    f:SetTextColor(unpack(color or T.text))
    f:SetJustifyH("LEFT")
    f:SetShadowColor(0, 0, 0, .8); f:SetShadowOffset(1, -1)
    return f
end
function U.Surface(frame, color)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(unpack(color or T.bg)); frame:SetBackdropBorderColor(unpack(T.gold))
end
function U.Tip(frame, title, lines)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(F.L[title], unpack(T.bright))
        local values = type(lines) == "function" and lines() or lines
        for _, line in ipairs(values or {}) do GameTooltip:AddLine(F.L[line], .85, .87, .86, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
function U.Button(parent, text, width, click)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 130, 30); U.Surface(b, T.panel)
    b:SetBackdropBorderColor(unpack(T.border))
    b:EnableMouse(true); b:RegisterForClicks("LeftButtonUp")
    b.text = U.Text(b, text, 12, T.bright); b.text:SetPoint("CENTER")
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(T.bright)) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(self.primary and T.gold or T.border)) end)
    b:SetScript("OnClick", click)
    return b
end
function U.Primary(b)
    b.primary=true;b:SetBackdropColor(unpack(T.blue));b:SetBackdropBorderColor(unpack(T.gold))
    return b
end
function U.Orb(parent, name, icon, size, secure)
    local b = CreateFrame("Button", name, parent, secure and "SecureActionButtonTemplate" or nil)
    b:SetSize(size, size)
    if secure then
        b:RegisterForClicks("AnyUp", "AnyDown")
        b:SetAttribute("useOnKeyDown", false)
    else b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    b.disk = b:CreateTexture(nil, "BACKGROUND"); b.disk:SetAllPoints(); b.disk:SetTexture(T.media .. "Orb")
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("CENTER"); b.icon:SetSize(size * .56, size * .56); b.icon:SetTexture(icon)
    if b.CreateMaskTexture then
        local mask = b:CreateMaskTexture(nil, "ARTWORK")
        mask:SetAllPoints(b.icon); mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        b.icon:AddMaskTexture(mask)
    end
    b.rim = b:CreateTexture(nil, "OVERLAY"); b.rim:SetAllPoints(); b.rim:SetTexture(T.media .. "Rim")
    b.hover=b:CreateTexture(nil,"HIGHLIGHT");b.hover:SetPoint("CENTER");b.hover:SetSize(size+4,size+4)
    b.hover:SetTexture(T.media.."Glow");b.hover:SetBlendMode("ADD");b.hover:SetAlpha(.8)
    return b
end
function U.Panel(name, title, subtitle)
    local p = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    p:SetSize(650, 460); p:SetPoint("CENTER"); p:SetFrameStrata("DIALOG")
    p:SetClampedToScreen(true); p:EnableMouse(true); p:SetMovable(true)
    U.Surface(p)
    local band = p:CreateTexture(nil, "BACKGROUND"); band:SetColorTexture(unpack(T.blue)); band:SetPoint("TOPLEFT", 5, -5); band:SetPoint("TOPRIGHT", -5, -5); band:SetHeight(70)
    p.title = U.Text(p, title, 23, T.bright); p.title:SetPoint("TOPLEFT", 25, -19)
    p.subtitle = U.Text(p, subtitle, 11, T.muted); p.subtitle:SetPoint("TOPLEFT", 26, -49)
    p.drag = CreateFrame("Frame", nil, p); p.drag:SetPoint("TOPLEFT"); p.drag:SetPoint("TOPRIGHT", -52, 0); p.drag:SetHeight(68)
    p.drag:EnableMouse(true); p.drag:RegisterForDrag("LeftButton")
    p.drag:SetScript("OnDragStart", function() p:StartMoving() end)
    p.drag:SetScript("OnDragStop", function() p:StopMovingOrSizing() end)
    local close = U.Button(p, "×", 28, function() p:Hide() end); close:SetPoint("TOPRIGHT", -14, -17)
    close:SetFrameLevel(p.drag:GetFrameLevel() + 2); p.close = close
    p.footer = U.Text(p, "FISHCRAFT  /  EVERY CAST HAS A STORY", 10, T.gold); p.footer:SetPoint("BOTTOMLEFT", 26, 18)
    p:SetScript("OnShow", function(self) self:SetScale(math.min(F.db.ui.scale, UIParent:GetWidth() / 690, UIParent:GetHeight() / 500)) end)
    table.insert(UISpecialFrames, name)
    p:Hide()
    return p
end
