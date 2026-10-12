local _, F = ...
local U,T,P=F.UI,F.Theme,{journalTab="collection",settingsTab="general",page=1}
F.Panels=P
local function text(p,value,x,y,size,color,width)
    local t=U.Text(p,value,size or 12,color);t:SetPoint("TOPLEFT",x,y);t:SetWidth(width or 680);return t
end
local function button(p,label,x,y,width,fn)
    local b=U.Button(p,label,width,fn);b:SetPoint("TOPLEFT",x,y);return b
end
local function page(p)
    local f=CreateFrame("Frame",nil,p);f:SetPoint("TOPLEFT",27,-142);f:SetSize(706,360);return f
end
local function edit(p,x,y,width,value,numeric)
    local b=CreateFrame("EditBox",nil,p,"InputBoxTemplate")
    b:SetSize(width,28);b:SetPoint("TOPLEFT",x,y);b:SetAutoFocus(false);b:SetFontObject("GameFontHighlight")
    U.Font(b,12)
    if numeric then b:SetNumeric(true);b:SetMaxLetters(3) end
    b:SetText(tostring(value or ""));b:SetScript("OnEscapePressed",function(self) self:ClearFocus() end);return b
end
function P:Create()
    self:CreateWorkspace()
    self.journal=self:CreateSection("journal")
    local j=self.journal
    self:CreateDiscoveries()
    self.settings=self:CreateSection("settings");self.gear=self.settings
    local p=self.settings
    button(p,"General",27,-89,140,function() self.settingsTab="general";self:RefreshSettings() end)
    button(p,"Equipment & lures",177,-89,180,function() self.settingsTab="equipment";self:RefreshSettings() end)
    button(p,"Optimizer",369,-89,145,function() self.settingsTab="optimizer";self:RefreshSettings() end)
    p.general=page(p);p.equipment=page(p);p.optimizer=page(p);self.checks={}
    for i,spec in ipairs({{"locked","Lock launcher position"},{"reducedMotion","Reduced motion"},{"autoCollapse","Collapse after a radial action"},{"minimap","Show minimap launcher"},{"trackSessions","Enable session recording",true},{"trackCollection","Record fishing catches",true},{"autoStartSession","Start session on first Fishing cast",true},{"tracker","Show compact fishing tracker"}}) do
        local b=CreateFrame("CheckButton",nil,p.general,"UICheckButtonTemplate");b:SetSize(28,28);b:SetPoint("TOPLEFT",0,-(i-1)*35)
        local t=U.Text(b,spec[2],13);t:SetPoint("LEFT",b,"RIGHT",7,0)
        b.group,b.key=spec[3] and "settings" or "ui",spec[1]
        b:SetScript("OnClick",function(self)
            if F.API.Locked() then self:SetChecked(F.db[self.group][self.key]);return end
            F.db[self.group][self.key]=not not self:GetChecked()
            if self.key=="trackSessions" and not self:GetChecked() then F.Session:Pause() end
            if self.key=="trackCollection" and not self:GetChecked() then F.Statistics:DiscardPending() end
            F.Radial:ApplySettings();if self.key=="tracker" then P:SetTracker(F.db.ui.tracker) end;P:RefreshSettings()
        end);self.checks[#self.checks+1]=b
    end
    text(p.general,"READABILITY",390,0,11,T.gold,300)
    p.textSize=button(p.general,"",390,-29,280,function()
        if F.API.Locked() then return end
        F.db.ui.textSize=(F.db.ui.textSize+1)%3;U.RefreshFonts();self:RefreshSettings()
    end)
    text(p.general,"Changes body text independently of UI scale.\nHeadings and dial spacing stay fixed.",390,-75,11,T.muted,300)
    text(p.general,"SESSION IDLE STOP",390,-140,11,T.gold,300)
    p.idle=button(p.general,"",390,-169,280,function()
        local nextValue={[0]=120,[120]=300,[300]=600,[600]=0}
        F.db.settings.sessionIdleSeconds=nextValue[F.db.settings.sessionIdleSeconds] or 300
        self:RefreshSettings()
    end)
    text(p.general,"Stop saves your session. With auto-start enabled, your next cast starts a new one.\nPause in Statistics waits for Start / resume.",390,-216,12,T.muted,300)
    U.Tip(p.idle,"Idle auto-stop",{"Click to cycle: Off, 2, 5 or 10 minutes.","Counts time since your last cast, channel end or recovered loot. A manual pause never auto-stops."})
    p.scale=text(p.general,"",0,-287,13,T.bright)
    button(p.general,"Smaller",0,-321,100,function() self:Scale(-.1) end)
    button(p.general,"Larger",112,-321,100,function() self:Scale(.1) end)
    button(p.general,"Reset position",224,-321,140,function() if not F.API.Locked() then F.db.ui.x,F.db.ui.y=.78,.35;F.Radial:ApplySettings() end end)
    local e=p.equipment
    text(e,"PREFERRED FISHING POLE",0,0,11,T.gold);e.pole=text(e,"",0,-26,16,T.bright)
    button(e,"Next available pole",0,-58,185,function() self:NextPreference("pole") end)
    text(e,"The radial pole button saves both weapons, then equips your pole.\nClick Swap back to restore both weapons in the same click.",0,-104,12,T.muted)
    text(e,"PREFERRED LURE",0,-163,11,T.gold);e.lure=text(e,"",0,-189,16,T.bright)
    button(e,"Next available lure",0,-223,185,function() self:NextPreference("lure") end)
    e.status=text(e,"",0,-267,12,T.muted)
    text(e,"Pole bonuses use the live skill total. Lure advice: Optimizer tab.",0,-319,11,T.muted)
    local o=p.optimizer
    o.enabled=button(o,"",0,0,170,function() self:SetOptimizerOption("enabled") end)
    o.mode=button(o,"",182,0,275,function() self:SetOptimizerOption("useRecommended") end)
    o.keep=button(o,"",0,-42,360,function() self:SetOptimizerOption("keepLure") end)
    U.Tip(o.keep,"Keep a lure active",{"Optional for perks such as Luremaster.","Recommends the weakest eligible lure even when your target is met.","Perks are not automatically detected or included in yield estimates."})
    text(o,"Personal skill target",0,-92,12,T.muted,155)
    o.target=edit(o,166,-83,65,F.db.optimizer.target or "",true);o.target:SetMaxLetters(4)
    o.set=button(o,"Set for here",247,-83,135,function() self:SetOptimizerTarget() end)
    o.clear=button(o,"Use guide",394,-83,135,function()
        if F.API.Locked() then F:Say("Change optimizer settings after combat.");return end
        F.db.optimizer.target,F.db.optimizer.zone,F.db.optimizer.subzone=nil,nil,nil;o.target:SetText("");F:Refresh()
    end)
    o.target:SetScript("OnEnterPressed",function(b) b:ClearFocus();self:SetOptimizerTarget() end)
    o.context=text(o,"",0,-127,12,T.gold,700)
    o.skill=text(o,"",0,-165,13,T.text,700)
    o.advice=text(o,"",0,-208,15,T.bright,700)
    text(o,"Current equipment and buffs are already included in the live skill total.\nGuide and personal targets do not guarantee catches in every water.",0,-261,11,T.muted,700)
    local inventory=button(o,"Carried lure details",0,-319,180,function() end)
    U.Tip(inventory,"Lure inventory",function() return F.Optimizer:InventoryLines() end)
    self:CreateLocations();self:CreateCooking();self:CreateStats();self:CreateTracker();self:Refresh();self:RefreshNavigation()
end
function P:NextPreference(kind)
    if F.API.Locked() then F:Say("Change equipment preferences after combat.");return end
    F:Refresh()
    local owner=kind=="pole" and F.Equipment or F.Lures
    local items=kind=="pole" and owner.poles or owner.items
    for i,item in ipairs(items) do
        local selected=kind=="pole" and owner.selected or owner.manual
        if selected and item.id==selected.id then
            F.db.settings[kind=="pole" and "preferredPole" or "preferredLure"]=items[i%#items+1].id;F:Refresh();return
        end
    end
end
function P:SetOptimizerOption(key)
    if F.API.Locked() then F:Say("Change optimizer settings after combat.");return end
    F.db.optimizer[key]=not F.db.optimizer[key];F:Refresh()
end
function P:SetOptimizerTarget()
    if F.API.Locked() then F:Say("Change optimizer settings after combat.");return end
    local n=tonumber(self.settings.optimizer.target:GetText())
    if not n or n<1 or n>1000 or n~=math.floor(n) then F:Say("Enter a whole-number skill target from 1 to 1000.");return end
    local c=F.db.optimizer;c.target=n;c.zone,c.subzone=F.API.Zone();F:Refresh()
end
function P:OpenCurrentLocation()
    self.locationFish=nil;self.locationName=F.API.Zone();self.locationPage=1;F:Refresh();self:OpenSection("locations")
end
function P:CreateLocations()
    local p=self:CreateSection("locations");self.locations=p
    p.chooseZone=button(p,"Choose a location",27,-89,350,function() self:ToggleZonePicker() end)
    p.chooseZone.text:SetWidth(304);p.chooseZone.text:ClearAllPoints();p.chooseZone.text:SetPoint("CENTER",-8,0)
    p.chooseZone.arrow=p.chooseZone:CreateTexture(nil,"ARTWORK");p.chooseZone.arrow:SetSize(14,14)
    p.chooseZone.arrow:SetPoint("RIGHT",-12,0);p.chooseZone.arrow:SetTexture(T.media.."ChevronDown")
    button(p,"Current location",389,-89,165,function() self:CloseZonePicker();self.locationFish=nil;self.locationName=F.API.Zone();self:RefreshLocations() end)
    p.allZones=button(p,"All locations",566,-89,165,function()
        self.locationName=self.locationNames and self.locationNames[self.locationIndex]
        self.locationFish=nil;self:RefreshLocations();self:ToggleZonePicker(true)
    end)
    p.zone=text(p,"",27,-142,20,T.bright);p.info=text(p,"",27,-177,11,T.muted,700);p.rows={}
    for i=1,6 do
        local b=button(p,"",27,-235-(i-1)*35,704,function() end);b:SetHeight(32)
        b.text:ClearAllPoints();b.text:SetPoint("LEFT",42,0);b.text:SetWidth(453);b.text:SetJustifyH("LEFT")
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(24,24);b.icon:SetPoint("LEFT",9,0)
        b.confidence=U.Text(b,"",10,T.muted);b.confidence:SetPoint("RIGHT",-12,0);b.confidence:SetWidth(184);b.confidence:SetJustifyH("RIGHT")
        b:SetScript("OnClick",function(self) if self.id then P:OpenDiscovery(self.id) end end);p.rows[i]=b
    end
    p.previousPage=button(p,"Previous catches",27,-450,150,function() self.locationPage=math.max(1,(self.locationPage or 1)-1);self:RefreshLocations() end)
    p.pages=text(p,"",191,-458,11,T.muted,130)
    p.nextPage=button(p,"Next catches",335,-450,135,function() self.locationPage=(self.locationPage or 1)+1;self:RefreshLocations() end)
    p.note=text(p,"",27,-488,10,T.muted,540)
    p.empty=text(p,"No catches listed here yet.",27,-235,13,T.muted,700)
    self:CreateZonePicker()
end
function P:CreateZonePicker()
    local p=self.locations
    local list=CreateFrame("Frame",nil,p,"BackdropTemplate");p.picker=list
    list:SetPoint("TOPLEFT",27,-125);list:SetSize(380,326);list:SetFrameLevel(p:GetFrameLevel()+20)
    list:EnableMouse(true);U.Surface(list,T.bg);list:SetBackdropColor(T.bg[1],T.bg[2],T.bg[3],1)
    text(list,"FIND A LOCATION",14,-12,11,T.gold,300)
    list.close=button(list,"×",344,-7,26,function() self:CloseZonePicker() end);list.close:SetHeight(26)
    list.search=edit(list,18,-42,340,"")
    list.search:SetScript("OnTextChanged",function() self.zonePickerPage=1;self:RefreshZonePicker() end)
    list.search:SetScript("OnEscapePressed",function() self:CloseZonePicker() end)
    list.search:SetScript("OnEnterPressed",function()
        local row=list.rows[1];if row.zoneName then self:SelectZone(row.zoneName) end
    end)
    list.rows={}
    for i=1,6 do
        local b=button(list,"",12,-79-(i-1)*32,356,function(self) if self.zoneName then P:SelectZone(self.zoneName) end end)
        b:SetHeight(29);b.text:SetWidth(330);b.text:SetJustifyH("LEFT");list.rows[i]=b
    end
    list.empty=text(list,"No matching locations",16,-91,13,T.muted,345)
    list.previous=button(list,"Previous",12,-282,95,function() self.zonePickerPage=math.max(1,(self.zonePickerPage or 1)-1);self:RefreshZonePicker() end)
    list.count=text(list,"",115,-290,10,T.muted,150)
    list.next=button(list,"Next",273,-282,95,function() self.zonePickerPage=(self.zonePickerPage or 1)+1;self:RefreshZonePicker() end)
    list:Hide()
end
function P:CloseZonePicker()
    local list=self.locations and self.locations.picker
    if list then list.search:ClearFocus();list:Hide() end
end
function P:ToggleZonePicker(force)
    local list=self.locations.picker
    if list:IsShown() and not force then self:CloseZonePicker();return end
    self.zonePickerPage=1;list.search:SetText("");self:RefreshZonePicker();list:Show();list.search:SetFocus()
end
function P:RefreshZonePicker()
    local list=self.locations and self.locations.picker;if not list then return end
    local query=list.search:GetText():lower():match("^%s*(.-)%s*$")
    local names={}
    for _,name in ipairs(self.locationNames or {}) do
        if name:lower():find(query,1,true) then names[#names+1]=name end
    end
    local pages=math.max(1,math.ceil(#names/6));self.zonePickerPage=F.Model.Clamp(self.zonePickerPage or 1,1,pages)
    for i,b in ipairs(list.rows) do
        b.zoneName=names[(self.zonePickerPage-1)*6+i];b:SetShown(b.zoneName~=nil);b.text:SetText(b.zoneName or "")
        b.primary=b.zoneName~=nil and b.zoneName==self.locationNames[self.locationIndex]
        b:SetBackdropColor(unpack(b.primary and T.blue or T.panel));b:SetBackdropBorderColor(unpack(b.primary and T.gold or T.border))
    end
    list.empty:SetShown(#names==0);list.count:SetText(#names.." zones · "..self.zonePickerPage.." / "..pages)
    list.previous:SetShown(pages>1);list.next:SetShown(pages>1)
end
function P:SelectZone(name)
    self.locationName=name;self.locationPage=1;self:CloseZonePicker();self:RefreshLocations()
end
function P:RefreshLocations()
    if not self.locations then return end
    local names={}
    if self.locationFish then for _,z in ipairs(F.Locations:ForFish(self.locationFish)) do names[#names+1]=z.name end
    else names=F.Locations:Names() end
    self.locationNames=names
    if self.locationName then for i,name in ipairs(names) do if name==self.locationName then self.locationIndex=i end end;self.locationName=nil end
    self.locationIndex=F.Model.Clamp(self.locationIndex or 1,1,math.max(1,#names))
    local zone=names[self.locationIndex];local p=self.locations
    p.zone:SetText(zone or "No verified fishing locations yet")
    p.chooseZone.text:SetText(zone or "Choose a location")
    local ref=zone and F.Data.zones[zone]
    p.info:SetText("Exact water requirement: unknown. Pool and inland/coastal catches may differ.\n"..(ref and ref.guideSkill and ("Forever guide skill: "..ref.guideSkill.." — zone-level guidance only.") or "No verified numerical requirement for this location."))
    local rows=zone and F.Collection:Rows("",zone,true) or {}
    local context=tostring(self.locationFish)..":"..tostring(zone)
    if self.locationContext~=context then self.locationPage=1;self.locationContext=context end
    local pages=math.max(1,math.ceil(#rows/6));self.locationPage=F.Model.Clamp(self.locationPage or 1,1,pages)
    p.pages:SetText("Page "..self.locationPage.." / "..pages)
    p.empty:SetShown(#rows==0)
    p.previousPage:SetShown(pages>1);p.nextPage:SetShown(pages>1);p.pages:SetShown(pages>1)
    local controlsY=-235-math.max(1,math.min(6,#rows))*35-12
    p.previousPage:ClearAllPoints();p.previousPage:SetPoint("TOPLEFT",27,controlsY)
    p.pages:ClearAllPoints();p.pages:SetPoint("TOPLEFT",191,controlsY-8)
    p.nextPage:ClearAllPoints();p.nextPage:SetPoint("TOPLEFT",335,controlsY)
    p.note:ClearAllPoints();p.note:SetPoint("TOPLEFT",27,controlsY-(pages>1 and 38 or 0))
    for i,b in ipairs(p.rows) do
        local row=rows[(self.locationPage-1)*6+i];b:SetShown(row~=nil);b.id=row and row.id
        if row then
            local n=row.owned and row.owned.zones[zone];local caught=n and n>0
            local item=F.API.Item(row.id);b.icon:SetTexture((row.owned and row.owned.icon) or (item and item.icon) or T.icons.fish)
            b.text:SetText(row.name);b.confidence:SetText(caught and ("Personally caught · "..n) or "Reference listing")
            b.confidence:SetTextColor(unpack(caught and T.green or T.muted))
        end
    end
    p.note:SetText(self.locationFish and ("Filtered: "..(F.Data.fish[self.locationFish] and F.Data.fish[self.locationFish].name or "Fishing loot").."\nMissing locations are not inferred from vendor listings.") or "Reference records checked 11 Oct 2026. Click a fish for its journal entry.\nPersonal records are kept separately from reference data.")
    self:RefreshZonePicker()
end
function P:CreateCooking()
    local p=self:CreateSection("cooking");self.cooking=p
    text(p,"Current",27,-96,12,T.muted,70);p.current=edit(p,100,-89,55,F.db.cooking.current,true)
    text(p,"Target",179,-96,12,T.muted,60);p.target=edit(p,241,-89,55,F.db.cooking.target,true)
    p.mode=button(p,"",322,-89,145,function()
        F.db.cooking.auto=F.db.cooking.auto==false
        p.current:SetText(tostring(F.db.cooking.current));p.current:ClearFocus();F:Refresh()
    end)
    U.Tip(p.mode,"Cooking skill mode",{"Live uses your current Cooking skill and training cap, updating as you cook.","Manual lets you enter a hypothetical starting skill. Fish quantities remain estimates."})
    U.Tip(p.current,"Current Cooking skill",{"Live mode reads your base Cooking skill automatically.","Switch to Manual to enter a hypothetical skill."})
    U.Primary(button(p,"Update plan",479,-89,130,function() self:ApplyCookingInputs() end))
    p.current:SetScript("OnEnterPressed",function(b) b:ClearFocus();self:ApplyCookingInputs() end)
    p.target:SetScript("OnEnterPressed",function(b) b:ClearFocus();self:ApplyCookingInputs() end)
    p.buffer=button(p,"",27,-131,250,function() F.db.cooking.buffer=not F.db.cooking.buffer;F.Cooking:Refresh();self:RefreshCooking();self:RefreshTracker() end)
    p.status=text(p,"",301,-133,11,T.muted,400)
    p.nextStep=CreateFrame("Frame",nil,p,"BackdropTemplate");p.nextStep:SetPoint("TOPLEFT",27,-182);p.nextStep:SetSize(704,80)
    U.Surface(p.nextStep,T.blue);p.nextStep:SetBackdropBorderColor(unpack(T.gold))
    text(p.nextStep,"NEXT STEP",14,-10,10,T.gold,670)
    p.goal=text(p.nextStep,"",14,-30,14,T.bright,672);p.goal:SetHeight(44)
    text(p,"COOKING / RECIPE",27,-280,11,T.gold,370)
    for i,label in ipairs({"EST.","HAVE","LEFT"}) do text(p,label,529+(i-1)*66,-280,11,T.gold,58):SetJustifyH("RIGHT") end
    p.rows={}
    for i=1,4 do
        local b=button(p,"",27,-301-(i-1)*44,704,function() end);b:SetHeight(40);b.text:Hide()
        b.title=text(b,"",12,-5,12,T.bright,470);b.detail=text(b,"",12,-24,10,T.muted,480)
        b.counts={}
        for j=1,3 do b.counts[j]=text(b,"",502+(j-1)*66,-13,12,T.text,58);b.counts[j]:SetJustifyH("RIGHT") end
        b:SetScript("OnClick",function(self) if self.row then P:OpenFishLocations(self.row.recipe.fish) end end)
        U.Tip(b,"Recipe details",function()
            if not b.row then return {} end
            local r=b.row
            return {r.recipe.name,"Recipe item: "..r.recipe.recipeItem,"Uses 1 "..F.Data.fish[r.recipe.fish].name.." per craft.",r.known==true and "Known recipe" or r.known==false and "Recipe not learned" or "Recipe knowledge unavailable; open Cooking to refresh.","Quantities are guide estimates, not guaranteed skill-ups.","Click for fishing locations."}
        end);p.rows[i]=b
    end
    p.note=text(p,"",27,-489,10,T.muted,450)
    p.activate=button(p,"Track fishing checklist",506,-505,225,function() F.db.cooking.active=not F.db.cooking.active;self:RefreshCooking();self:RefreshTracker() end)
end
function P:ApplyCookingInputs()
    local cfg=F.db.cooking
    local current,target=tonumber(self.cooking.current:GetText()),tonumber(self.cooking.target:GetText())
    if not target or target<1 or target>300 or target~=math.floor(target) then F:Say("Enter a whole-number Cooking target from 1 to 300.");return end
    if cfg.auto==false then
        if not current or current<1 or current>300 or current~=math.floor(current) or target<current then
            F:Say("Enter a current skill from 1 to 300 and a target at least as high.");return
        end
        cfg.current=current
    end
    cfg.target=target;F:Refresh()
end
function P:RefreshCooking()
    if not self.cooking then return end
    local p,plan=self.cooking,F.Cooking.plan;if not plan then return end
    local live=F.db.cooking.auto~=false
    p.mode.text:SetText(live and "Skill: live" or "Skill: manual")
    p.current:EnableMouse(not live);p.current:SetAlpha(live and .65 or 1)
    if live then p.current:ClearFocus();p.current:SetText(plan.current and tostring(plan.current) or "") end
    p.status:SetText(plan.unavailable and "Cooking skill unavailable\nOpen Cooking to refresh" or
        ((live and "Live Cooking: " or "Manual starting skill: ")..plan.current..(plan.maximum and (" / "..plan.maximum) or "").." · target "..plan.target.."\n"..
        (plan.current>=plan.target and "Target reached" or plan.training and ("Planning through current cap: "..plan.maximum) or "Verified fish route through 225")))
    p.buffer.text:SetText(F.db.cooking.buffer and "Reserve: +20% extra fish" or "Reserve: guide estimate only")
    for i,b in ipairs(p.rows) do
        local r=plan.rows[i];b.row=r;b:SetShown(r~=nil)
        if r then
            b.title:SetText(r.from.."–"..r.to.."  "..r.recipe.name)
            b.detail:SetText(F.Data.fish[r.recipe.fish].name.."  ·  "..(r.known==true and "Recipe known" or r.known==false and "Learn recipe first" or "Knowledge unknown"))
            b.counts[1]:SetText(tostring(r.need));b.counts[2]:SetText(tostring(r.have));b.counts[3]:SetText(tostring(r.remaining))
        end
    end
    p.note:SetText(F.Cooking:PlanNote())
    p.goal:SetText(F.Cooking:Advice())
    p.activate.text:SetText(F.db.cooking.active and "Stop tracking checklist" or "Track fishing checklist")
end
function P:CreateStats()
    self.stats=self:CreateSection("stats")
    local p=self.stats;self.statsCurrent=false;self.statsTab="overview";p.cards={}
    p.overview=CreateFrame("Frame",nil,p);p.overview:SetSize(760,560);p.overview:SetPoint("TOPLEFT",0,0)
    p.lifetime=button(p,"Lifetime",27,-89,140,function() self.statsCurrent=false;self.statsTab="overview";self:RefreshStats() end)
    p.current=button(p,"Current session",179,-89,170,function() self.statsCurrent=true;self.statsTab="overview";self:RefreshStats() end)
    p.history=button(p,"Session history",361,-89,170,function() self.statsTab="history";self:RefreshStats();self:RefreshSessions() end)
    p.live=text(p.overview,"",27,-130,12,T.bright,700)
    local specs={
        {"seconds","Time fishing","Elapsed recording time. Paused and offline time is excluded.",T.icons.time},
        {"casts","Casts","Recorded player Fishing casts, including casts with no recovered loot.",T.media.."Hook"},
        {"catches","Items caught","Item quantities recovered from verified bobbers during a recorded cast. A stack can contain several items.",T.icons.fish},
        {"success","Success rate","Casts with recovered bobber loot / resolved casts. A cast in progress stays pending. Channel end has a 3-second loot grace period; verified open bobber loot remains pending. Unfinished casts at pause or Stop are excluded. One success per cast; uncollected or unverified loot is not a success.",T.icons.success},
        {"perHour","Items / hour","Recovered item quantity divided by recorded session hours, including time between casts.",T.icons.rate},
        {"average","Avg. cast to loot","Time from a Fishing cast to its first recovered item, including your reaction and looting time. Only casts without a recording pause are sampled.",T.icons.stopwatch},
        {"sessions","Sessions","Saved sessions plus the current session. Lifetime totals survive the 30-session history limit.",T.icons.sessions},
        {"unique","Unique catches","Distinct item IDs recovered in recorded sessions since this update, including unclassified loot. Older collection history remains in Discoveries.",T.icons.collection},
    }
    for i,spec in ipairs(specs) do
        local card=CreateFrame("Frame",nil,p.overview,"BackdropTemplate");card:SetSize(344,64)
        card:SetPoint("TOPLEFT",27+((i-1)%2)*360,-163-math.floor((i-1)/2)*69);U.Surface(card,T.panel);card:SetBackdropBorderColor(unpack(T.border))
        local icon=card:CreateTexture(nil,"ARTWORK");card.icon=icon;icon:SetSize(32,32);icon:SetPoint("LEFT",12,0);icon:SetTexture(spec[4])
        text(card,spec[2],55,-9,11,T.muted,275)
        card.value=text(card,"—",55,-29,21,T.bright,275);card:EnableMouse(true);U.Tip(card,spec[2],{spec[3]})
        p.cards[spec[1]]=card
    end
    p.total=p.cards.casts.value
    U.Primary(button(p.overview,"Start / resume",27,-448,150,function() F.Session:Start() end))
    button(p.overview,"Pause",189,-448,100,function() F.Session:Pause() end)
    button(p.overview,"Save session",301,-448,140,function() F.Session:Finish() end)
    p.note=text(p.overview,"",27,-491,10,T.muted,700)
    self:CreateSessionHistory()
    p:SetScript("OnUpdate",function(_,elapsed)
        self.statsElapsed=(self.statsElapsed or 0)+elapsed
        if self.statsElapsed>=1 then self.statsElapsed=0;self:RefreshStats();self:RefreshSessions() end
    end)
end
function P:CreateSessionHistory()
    self.journal.session=page(self.stats);local s=self.journal.session
    s.status=text(s,"",0,0,21,T.bright);s.detail=text(s,"",0,-37,12,T.muted)
    button(s,"Start / resume",0,-72,150,function() F.Session:Start();self:Refresh() end)
    button(s,"Pause",162,-72,100,function() F.Session:Pause();self:Refresh() end)
    button(s,"Save session",274,-72,140,function() F.Session:Finish();self:Refresh() end)
    text(s,"RECENT SESSIONS",0,-132,11,T.gold);s.rows={}
    for i=1,5 do s.rows[i]=text(s,"",0,-162-(i-1)*28,12,T.text) end
    text(s,"Items count only after verified bobber loot is recovered.",0,-327,11,T.muted)
end
function P:RefreshSessions()
    if not self.journal then return end
    local p,S=self.journal.session,F.Session
    p.status:SetText(S.current and (F.Model.Duration(S:Elapsed()).."  /  "..S.current.casts.." casts  /  "..(S.current.catches or 0).." items") or "Your next session starts here")
    p.detail:SetText(F.API.Zone().." · "..(S.runningSince and "Recording" or "Paused"))
    for i,t in ipairs(p.rows) do
        local r=F.db.history[#F.db.history-i+1]
        t:SetText(r and (date("%d %b  %H:%M",r.started).."    "..F.Model.Duration(r.seconds).."    "..r.casts.." casts    "..(r.catches or 0).." items") or (i==1 and "No saved sessions yet." or ""))
    end
end
function P:RefreshSettings()
    if not self.settings then return end
    local p=self.settings;p.general:SetShown(self.settingsTab=="general");p.equipment:SetShown(self.settingsTab=="equipment");p.optimizer:SetShown(self.settingsTab=="optimizer")
    for _,b in ipairs(self.checks) do b:SetChecked(F.db[b.group][b.key]) end
    p.textSize.text:SetText("Text size: "..({[0]="Compact",[1]="Comfortable",[2]="Large"})[F.db.ui.textSize])
    local idle=F.db.settings.sessionIdleSeconds
    p.idle.text:SetText(idle==0 and "Auto-stop: Off" or ("Auto-stop: "..math.floor(idle/60).." minutes idle"))
    p.scale:SetText(string.format("UI scale: %d%%",math.floor(F.db.ui.scale*100+.5)))
    p.equipment.pole:SetText(F.Equipment.selected and F.Equipment.selected.name or "No fishing pole found")
    p.equipment.lure:SetText(F.Lures.manual and F.Lures.manual.name or "No recognized lures found")
    p.equipment.status:SetText(F.Lures:Status().."\n"..(F.db.equipment and "Weapons saved. Use Swap back on the radial menu." or "No pending weapon swap."))
    local o,c,r=p.optimizer,F.db.optimizer,F.Optimizer:Evaluate()
    o.enabled.text:SetText(c.enabled and "Optimizer: on" or "Optimizer: off")
    o.mode.text:SetText(c.useRecommended and "Lure button: recommended" or "Lure button: manual preference")
    o.keep.text:SetText(c.keepLure and "Keep a lure for perks: yes" or "Keep a lure for perks: no")
    o.context:SetText(r.zone..(r.subzone~="" and (" / "..r.subzone) or "").."\n"..r.label..(r.target and (": "..r.target) or ""))
    o.skill:SetText(r.skill and ("Effective Fishing: "..r.skill.total.."\n"..r.skill.rank.." base + "..r.skill.modifier.." modifier + "..r.skill.temporary.." temporary") or "Fishing skill unavailable")
    o.advice:SetText(F.Optimizer:Message(r))
end
function P:Scale(delta)
    if F.API.Locked() then return end
    F.db.ui.scale=F.Model.Clamp(F.db.ui.scale+delta,.75,1.5);F.Radial:ApplySettings()
    self:Place(self.window,"windowX","windowY");self:Place(self.tracker,"trackerX","trackerY")
    self:RefreshSettings()
end
function P:Toggle(key)
    if key=="gear" then self.settingsTab="equipment";self:OpenSection("settings");return end
    if self.window:IsShown() and self.section==key then self.window:Hide() else self:OpenSection(key) end
end
function P:Refresh()
    if not self.journal or not self.stats then return end
    self.journal.collection:SetShown(self.journalTab=="collection")
    self:RefreshCollection();self:RefreshDiscovery();self:RefreshSessions();self:RefreshSettings();self:RefreshLocations();self:RefreshCooking()
    self:RefreshStats();self:RefreshTracker();self:RefreshNavigation()
end
function P:RefreshStats()
    if not self.stats then return end
    local p,S=self.stats,F.Session
    p.overview:SetShown(self.statsTab~="history");self.journal.session:SetShown(self.statsTab=="history")
    p.history.text:SetText(self.statsTab=="history" and "Session history •" or "Session history")
    local data=F.Statistics:Snapshot(self.statsCurrent)
    p.lifetime.text:SetText(not self.statsCurrent and self.statsTab~="history" and "Lifetime •" or "Lifetime")
    p.current.text:SetText(self.statsCurrent and self.statsTab~="history" and "Current session •" or "Current session")
    p.live:SetText(S.current and ((S.runningSince and "Recording: " or "Paused: ")..F.Model.Duration(S:Elapsed()).." · "..S.current.casts.." casts · "..(S.current.catches or 0).." items"..(data.pending>0 and (" · "..data.pending.." pending") or "")) or (F.db.settings.trackSessions and F.db.settings.autoStartSession and "Your next Fishing cast starts the timer." or "Start a session to record fishing time."))
    for key,card in pairs(p.cards) do
        local value=data[key]
        if key=="seconds" then value=F.Model.Duration(value)
        elseif key=="success" then value=value and string.format("%.1f%%",value) or "—"
        elseif key=="average" then value=value and string.format("%.1f s",value) or "—"
        elseif key=="perHour" then value=value and string.format("%.1f",value) or "—" end
        card.value:SetText(tostring(value))
    end
    p.note:SetText((self.statsCurrent and "Current session only. " or "Lifetime totals survive saving sessions and history cleanup. ").."Hover a stat for details.\n"..(F.db.statistics.imported and "Older session totals retained; success, timing and unique catches use new tracking." or "Success, timing and unique catches cover recorded casts since this update."))
end
