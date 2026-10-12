-- A deliberately strict subset of the WoW frame API, plus mutable inventory fixtures.
Mock = { combat = false, clock = 0, wall = 1700000000, frames = {}, bags = {}, inventory = {}, timers = {}, mutations = 0, spellKnown = true }
unpack = unpack or table.unpack
STANDARD_TEXT_FONT = 'font'; UISpecialFrames = {}; SlashCmdList = {}; NUM_BAG_SLOTS = 4
local methods = {}
local function protected(f)
    if f.secure then return true end
    return f.parent and protected(f.parent)
end
local function guard(f)
    if Mock.combat and protected(f) then error('Protected frame mutation in combat: '..tostring(f.name)) end
    Mock.mutations = Mock.mutations + 1
end
function methods:SetSize(w,h) guard(self);self.w=w;self.h=h end
function methods:SetWidth(w) guard(self);self.w=w end
function methods:SetHeight(h) guard(self);self.h=h end
function methods:GetWidth() return self.w or 0 end
function methods:GetHeight() return self.h or 0 end
function methods:SetScale(s) guard(self);self.frameScale=s end
function methods:GetEffectiveScale() return (self.frameScale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetPoint(...) guard(self);self.point={...} end
function methods:ClearAllPoints() guard(self);self.point=nil end
function methods:GetCenter() return 500,400 end
function methods:SetAllPoints() end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:Show() guard(self);self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() guard(self);self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:EnableMouse(v) guard(self);self.mouse=v end
function methods:SetAttribute(k,v) guard(self);self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text or "" end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel()+1) or 0 end
for _,name in ipairs({'SetAutoFocus','SetFontObject','SetNumeric','SetMaxLetters','ClearFocus','HighlightText','SetFocus'}) do methods[name]=function() end end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:StartMoving() guard(self);self.moving=true end
function methods:StopMovingOrSizing() guard(self);self.moving=false end
function methods:SetAlpha(v) guard(self);self.alpha=v end
for _,name in ipairs({'SetFrameStrata','SetMovable','SetClampedToScreen','RegisterForDrag','RegisterForClicks','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetFont','SetTextColor','SetJustifyH','SetShadowColor','SetShadowOffset','SetColorTexture','SetTexture','SetHighlightTexture','SetVertexColor','AddMaskTexture','SetOwner','AddLine'}) do methods[name]=function() end end
function CreateFrame(kind,name,parent,template)
    local f = setmetatable({name=name,parent=parent,secure=template and template:find('Secure')~=nil,attrs={},scripts={},events={},shown=true}, {__index=methods})
    Mock.frames[#Mock.frames+1]=f;if name then _G[name]=f end;return f
end
function methods:CreateTexture() return CreateFrame('Texture',nil,self) end
function methods:SetTexture(value) guard(self);self.texture=value end
function methods:SetBlendMode(value) self.blendMode=value end
function methods:SetDesaturated(value) self.desaturated=value end
function methods:SetVertexColor(...) self.vertexColor={...} end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetFont(path,size,flags) guard(self);self.fontPath,self.fontSize,self.fontFlags=path,size,flags end
function methods:CreateMaskTexture() return CreateFrame('Mask',nil,self) end
function methods:CreateFontString() return CreateFrame('FontString',nil,self) end
UIParent=CreateFrame('Frame','UIParent');UIParent:SetSize(1920,1080)
Minimap=CreateFrame('Frame','Minimap',UIParent);Minimap:SetSize(140,140)
GameTooltip=CreateFrame('Frame','GameTooltip',UIParent)
function RegisterStateDriver(frame,state,condition) frame.driver=condition end
function InCombatLockdown() return Mock.combat end
function GetBuildInfo() return '1.60.1','70170','Oct 1 2026',16001 end
function GetTime() return Mock.clock end
function GetCursorPosition() return Mock.cursorX or 500,Mock.cursorY or 400 end
function time() return Mock.wall end
date=os.date
function GetRealZoneText() return 'Test shore' end
function GetSubZoneText() return '' end
function CursorHasItem() return Mock.cursor~=nil end
function GetInventoryItemLink(_,slot) return Mock.inventory[slot] and Mock.inventory[slot].link end
function GetInventoryItemID(_,slot) return Mock.inventory[slot] and Mock.inventory[slot].id end
function PickupInventoryItem(slot) Mock.cursor,Mock.inventory[slot]=Mock.inventory[slot],Mock.cursor end
function EquipCursorItem(slot)
    assert(not Mock.combat)
    Mock.cursor,Mock.inventory[slot]=Mock.inventory[slot],Mock.cursor
    if Mock.inventory[slot] and Mock.inventory[slot].pole and Mock.inventory[17] then
        for i=1,10 do if not Mock.bags[i] then Mock.bags[i]=Mock.inventory[17];Mock.inventory[17]=nil;break end end
    end
end
ItemLocation={}
function ItemLocation:CreateFromEquipmentSlot(slot) return {inventory=slot} end
function ItemLocation:CreateFromBagAndSlot(bag,slot) return {bag=bag,slot=slot} end
function Mock.Item(id,guid,pole) return {id=id,guid=guid,pole=pole,link='item:'..id..':'..guid,name='Item '..id} end
function Mock.Find(id)
    for _,item in pairs(Mock.inventory) do if item.id==id or item.link==id then return item end end
    for _,item in pairs(Mock.bags) do if item.id==id or item.link==id then return item end end
end
C_Item={
    GetItemInfoInstant=function(id) local v=Mock.Find(id);if v then return v.id,'Weapon','',v.pole and 'INVTYPE_2HWEAPON' or 'INVTYPE_WEAPON','icon',2,v.pole and 20 or 7 end end,
    GetItemInfo=function(id) local v=Mock.Find(id);return v and v.name end,
    GetItemGUID=function(loc) local v=loc.inventory and Mock.inventory[loc.inventory] or (loc.bag==0 and Mock.bags[loc.slot]);return v and v.guid end,
}
C_Container={
    GetContainerNumSlots=function(bag) return bag==0 and 10 or 0 end,
    GetContainerNumFreeSlots=function() local n=0;for i=1,10 do if not Mock.bags[i] then n=n+1 end end;return n,0 end,
    GetContainerItemInfo=function(bag,slot) local v=bag==0 and Mock.bags[slot];if v then return {itemID=v.id,hyperlink=v.link,isLocked=v.locked,stackCount=v.count or 1} end end,
    PickupContainerItem=function(bag,slot) assert(not Mock.combat);assert(bag==0);Mock.cursor,Mock.bags[slot]=Mock.bags[slot],Mock.cursor end,
}
C_Spell={GetSpellInfo=function(id) return {name='Fishing',spellID=id} end}
C_SpellBook={IsSpellKnown=function(id) return Mock.spellKnown and id==7620 end}
C_PaperDollInfo={GetTemporaryEnchantmentInfo=function() if Mock.enchant then return {remainingTimeMs=600000} end end}
C_SkillInfo={GetSkillLineInfoByID=function() return {rank=100,modifier=5,tempPoints=25,maxRank=150} end}
C_Timer={After=function(_,fn) table.insert(Mock.timers,fn) end,NewTicker=function(_,fn) return {callback=fn} end}
function Mock.Flush() local timers=Mock.timers;Mock.timers={};for _,fn in ipairs(timers) do fn() end end
function Mock.Click(b) if b.scripts.OnClick then b.scripts.OnClick(b,'LeftButton',false) end end
