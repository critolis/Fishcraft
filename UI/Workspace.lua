local _, F = ...
local P,U,T=F.Panels,F.UI,F.Theme
local sections={{"journal","Discoveries"},{"locations","Locations"},{"cooking","Cooking"},{"stats","Statistics"},{"settings","Settings"}}
local titles={journal="Discoveries",locations="Fishing locations",cooking="Cooking Planner",stats="Statistics",settings="Settings"}
local stateKeys={"section","journalTab","discoveryID","locationFish","locationIndex","locationPage","locationContext","locationName"}
function P:Place(frame,xKey,yKey)
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    local scale=frame==self.window and math.min(F.db.ui.scale,w/960,h/620) or math.min(F.db.ui.scale,w/340,h/240)
    frame:SetScale(scale)
    local x=F.Model.Clamp(F.db.ui[xKey]*w,frame:GetWidth()*scale/2+8,w-frame:GetWidth()*scale/2-8)
    local y=F.Model.Clamp(F.db.ui[yKey]*h,frame:GetHeight()*scale/2+8,h-frame:GetHeight()*scale/2-8)
    frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
end
function P:Remember(frame,xKey,yKey)
    local x,y=frame:GetCenter();if not x or not y then return end
    local ratio=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    F.db.ui[xKey]=F.Model.Clamp(x*ratio/UIParent:GetWidth(),0,1)
    F.db.ui[yKey]=F.Model.Clamp(y*ratio/UIParent:GetHeight(),0,1)
end
function P:CreateWorkspace()
    self.section="journal";self.routes={};self.views={};self.nav={}
    local w=U.Panel("FishcraftWindow","Fishcraft","DISCOVERIES");self.window=w;w:SetSize(920,580)
    w.subtitle:ClearAllPoints();w.subtitle:SetPoint("TOPLEFT",26,-16);w.subtitle:SetText("FISHCRAFT")
    w.title:ClearAllPoints();w.title:SetPoint("TOPLEFT",25,-35)
    w:SetBackdropColor(T.bg[1],T.bg[2],T.bg[3],1)
    w:SetScript("OnShow",function() self:Place(w,"windowX","windowY") end)
    w:SetScript("OnHide",function() w:SetScript("OnUpdate",nil);for _,v in pairs(self.views) do v:SetAlpha(1) end;if self.locations then self:CloseZonePicker() end;GameTooltip:Hide() end)
    w.drag:SetScript("OnDragStop",function() w:StopMovingOrSizing();self:Remember(w,"windowX","windowY") end)
    for i,spec in ipairs(sections) do
        local key,label=spec[1],spec[2]
        local b=U.Button(w,label,124,function() self:OpenSection(key) end);b:SetPoint("TOPLEFT",18,-106-(i-1)*43)
        -- Selection survives hover and reflects the displayed section.
        b:SetScript("OnEnter",function() b:SetBackdropBorderColor(unpack(T.bright)) end)
        b:SetScript("OnLeave",function() self:RefreshNavigation() end);self.nav[key]=b
        b.selected=b:CreateTexture(nil,"ARTWORK");b.selected:SetColorTexture(unpack(T.gold));b.selected:SetSize(3,20);b.selected:SetPoint("LEFT",3,0)
    end
    self.back=U.Button(w,"Back",124,function() self:Back() end);self.back:SetPoint("TOPLEFT",18,-348)
    self.pin=U.Button(w,"Pin tracker",124,function() self:SetTracker(not F.db.ui.tracker) end);self.pin:SetPoint("TOPLEFT",18,-490)
    U.Tip(self.pin,"Fishing tracker",{"Keep a compact session, lure and cooking summary visible while the main window is closed.","Drag its header to move it; X unpins it."})
end
function P:CreateSection(key)
    local p=CreateFrame("Frame",nil,self.window);p:SetPoint("TOPLEFT",152,0);p:SetSize(760,560);p:Hide()
    self.views[key]=p;return p
end
function P:RefreshNavigation()
    if not self.window then return end
    for _,spec in ipairs(sections) do
        local selected=self.section==spec[1];local b=self.nav[spec[1]]
        b:SetBackdropColor(unpack(selected and T.blue or T.panel))
        b:SetBackdropBorderColor(unpack(selected and T.gold or T.border))
        b.text:SetText(spec[2]);b.selected:SetShown(selected)
        if selected then self.window.title:SetText(titles[spec[1]]) end
    end
    for key,view in pairs(self.views) do view:SetShown(key==self.section) end
    self.back:SetShown(#self.routes>0)
    self.pin.text:SetText(F.db.ui.tracker and "Unpin tracker" or "Pin tracker")
end
function P:DisplaySection(key)
    if not self.views[key] then return end
    if self.locations then self:CloseZonePicker() end
    self.window:SetScript("OnUpdate",nil)
    for _,view in pairs(self.views) do view:SetAlpha(1) end
    if key=="cooking" then F:Refresh() end
    self.section=key;self:Refresh();self:RefreshNavigation();self.window:Show()
    if not F.db.ui.reducedMotion then
        local elapsed,view=0,self.views[key];view:SetAlpha(0)
        self.window:SetScript("OnUpdate",function(_,dt)
            elapsed=elapsed+dt;view:SetAlpha(math.min(1,elapsed/.12))
            if elapsed>=.12 then self.window:SetScript("OnUpdate",nil) end
        end)
    end
end
function P:OpenSection(key)
    self.routes={};self:DisplaySection(key)
end
function P:PushRoute()
    local route={};for _,key in ipairs(stateKeys) do route[key]=self[key] end
    self.routes[#self.routes+1]=route
    if #self.routes>20 then table.remove(self.routes,1) end
end
function P:Back()
    local route=table.remove(self.routes)
    if route then for _,key in ipairs(stateKeys) do self[key]=route[key] end
    else self.section="journal";self.journalTab="collection" end
    self:DisplaySection(self.section)
end
function P:OpenFishLocations(id)
    self:PushRoute();self.locationFish=id;self.locationIndex=1;self.locationPage=1;self.locationContext=nil
    self:DisplaySection("locations")
end
function P:CreateTracker()
    local t=CreateFrame("Frame","FishcraftTracker",UIParent,"BackdropTemplate");self.tracker=t
    t:SetSize(290,196);t:SetFrameStrata("MEDIUM");t:SetMovable(true);t:SetClampedToScreen(true);t:EnableMouse(true)
    U.Surface(t,T.bg);t:SetBackdropColor(T.bg[1],T.bg[2],T.bg[3],1)
    local title=U.Text(t,"Fishcraft",14,T.bright);title:SetPoint("TOPLEFT",14,-12)
    local drag=CreateFrame("Frame",nil,t);t.drag=drag;drag:SetPoint("TOPLEFT");drag:SetSize(248,35)
    drag:EnableMouse(true);drag:RegisterForDrag("LeftButton");drag:SetScript("OnDragStart",function() t:StartMoving() end)
    drag:SetScript("OnDragStop",function() t:StopMovingOrSizing();self:Remember(t,"trackerX","trackerY") end)
    t.close=U.Button(t,"×",24,function() self:SetTracker(false) end);t.close:SetSize(24,24);t.close:SetPoint("TOPRIGHT",-8,-8)
    t.close:SetFrameLevel(drag:GetFrameLevel()+2)
    local function line(y,size)
        local f=U.Text(t,"",size,T.text);f:SetPoint("TOPLEFT",14,y);f:SetWidth(262);return f
    end
    t.session=line(-45,13);t.lure=line(-72,11);t.lure:SetHeight(30)
    t.goal=line(-111,11);t.goal:SetHeight(42)
    t.open=U.Button(t,"Open Statistics",150,function() self:OpenSection("stats") end);t.open:SetPoint("BOTTOMLEFT",14,10);t.open:SetHeight(24)
    U.Tip(t,"Fishing summary",function() return {F.Lures:Status(),F.Cooking:GoalText() or "Choose a cooking goal in the planner."} end)
    t:SetScript("OnShow",function() self:Place(t,"trackerX","trackerY") end)
    local elapsed=0;t:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;self:RefreshTracker() end end)
    self:SetTracker(F.db.ui.tracker)
end
function P:SetTracker(enabled)
    F.db.ui.tracker=not not enabled
    if self.tracker then self.tracker:SetShown(F.db.ui.tracker);self:RefreshTracker() end
    self:RefreshNavigation();self:RefreshSettings()
end
function P:RefreshTracker()
    if not self.tracker then return end
    local t,s=self.tracker,F.Session
    t.session:SetText((s.runningSince and "" or "Paused · ")..F.Model.Duration(s:Elapsed()).." · "..(s.current and s.current.catches or 0).." items")
    t.lure:SetText(F.Lures:Status());t.goal:SetText(F.Cooking:GoalText() or "No cooking goal selected")
end
