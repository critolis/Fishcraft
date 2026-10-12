local _, F = ...
local P,U,T,D=F.Panels,F.UI,F.Theme,F.Discoveries
local function text(p,value,x,y,size,width,color)
    local t=U.Text(p,value,size or 12,color or T.muted);t:SetPoint("TOPLEFT",x,y);t:SetWidth(width or 700);return t
end
local function button(p,label,x,y,width,fn)
    local b=U.Button(p,label,width,fn);b:SetPoint("TOPLEFT",x,y);return b
end
local function page(p)
    local f=CreateFrame("Frame",nil,p);f:SetPoint("TOPLEFT",27,-142);f:SetSize(706,360);return f
end
local function badge(parent,width)
    local b=CreateFrame("Frame",nil,parent,"BackdropTemplate");b:SetSize(width,26);b:EnableMouse(false)
    U.Surface(b,T.panel);b.text=U.Text(b,"",12,T.text);b.text:SetPoint("CENTER")
    return b
end
local function styleBadge(b,count,suffix)
    local tier=D:Milestone(count);local color=T.catchMilestones[tier]
    b:SetShown(count>0)
    b:SetBackdropColor(color[1]*.16,color[2]*.16,color[3]*.16,1)
    b:SetBackdropBorderColor(color[1],color[2],color[3],.45)
    b.text:SetTextColor(unpack(color));b.text:SetText(tostring(count)..(suffix or ""))
end
function P:CreateDiscoveries()
    self.discoveryCategory,self.discoveryState,self.discoverySort=1,1,D.defaultSort
    local j=self.journal;j.collection=page(j);local c=j.collection
    c.search=CreateFrame("EditBox",nil,c,"InputBoxTemplate");c.search:SetSize(220,28);c.search:SetPoint("TOPLEFT",5,0)
    c.search:SetAutoFocus(false);c.search:SetFontObject("GameFontHighlight");c.search:SetText("")
    U.Font(c.search,12)
    c.search:SetScript("OnTextChanged",function() self.page=1;self:RefreshCollection() end)
    c.search:SetScript("OnEscapePressed",function(b) b:ClearFocus() end)
    c.search:SetScript("OnEnterPressed",function(b) b:ClearFocus() end)
    U.Tip(c.search,"Search discoveries",{"Type part of a fish or loot item name."})
    c.kind=button(c,"",240,0,190,function() self.discoveryCategory=self.discoveryCategory%#D.categories+1;self.page=1;self:RefreshCollection() end)
    c.zone=button(c,"All zones",444,0,150,function() self.currentZoneOnly=not self.currentZoneOnly;self.page=1;self:RefreshCollection() end)
    c.state=button(c,"",0,-40,150,function() self.discoveryState=self.discoveryState%#D.states+1;self.page=1;self:RefreshCollection() end)
    c.sort=button(c,"",162,-40,180,function() self.discoverySort=self.discoverySort%#D.sorts+1;self.page=1;self:RefreshCollection() end)
    U.Tip(c.kind,"Discovery categories",{"Click to cycle: all fish, new in Forever, rare catches, bloated fish, all loot.","Rare means a named Rare Fish quest, not a measured drop chance.","Unclassified catches remain under All loot."})
    U.Tip(c.sort,"Sort discoveries",{"Most catches first by default; ties use the item name.","Click to cycle name, newest discovery, latest catch, and most catches.","Caught items always appear first. Entries without dates sort last in date modes."})
    c.summary=text(c,"",356,-43,11,347);c.rows={}
    for i=1,6 do
        local b=CreateFrame("Button",nil,c,"BackdropTemplate");b:SetSize(704,38);b:SetPoint("TOPLEFT",0,-84-(i-1)*40)
        U.Surface(b,T.panel);b:SetBackdropBorderColor(unpack(T.border));b:EnableMouse(true);b:RegisterForClicks("LeftButtonUp")
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(28,28);b.icon:SetPoint("LEFT",8,0)
        b.name=text(b,"",47,-4,12,540,T.bright);b.detail=text(b,"",47,-21,10,545)
        b.badge=badge(b,96);b.badge:SetPoint("RIGHT",-9,0);b.count=b.badge.text
        b:SetScript("OnClick",function() if b.record then self:OpenDiscovery(b.record.id) end end)
        U.Tip(b,"Discovery",function()
            local r=b.record;if not r then return {} end
            local lines={r.name,D:Tag(r.ref)}
            if r.owned and r.count>0 then
                local tier,nextTier=D:Milestone(r.count)
                lines[#lines+1]="Lifetime catches: "..r.count
                if tier>0 then lines[#lines+1]="Catch milestone: "..tier.."+" end
                lines[#lines+1]=nextTier and ("Next milestone: "..nextTier.." ("..(nextTier-r.count).." to go)") or "Highest catch milestone reached: 1000+"
                lines[#lines+1]="First catch: "..D:Date(r.owned.first)
                lines[#lines+1]="Latest catch: "..D:Date(r.owned.last)
            else lines[#lines+1]="Not yet personally caught" end
            lines[#lines+1]="Click for history and fishing locations.";return lines
        end);c.rows[i]=b
    end
    button(c,"Previous",0,-333,100,function() self.page=math.max(1,self.page-1);self:RefreshCollection() end)
    c.pages=text(c,"",118,-341,12,150)
    button(c,"Next",280,-333,85,function() self.page=self.page+1;self:RefreshCollection() end)
    text(c,"Click a fish to explore its discovery",390,-341,10,310)
    j.discovery=page(j);local p=j.discovery
    p.back=button(p,"Back",0,0,110,function() self:Back() end)
    p.badge=badge(p,180);p.badge:SetPoint("TOPRIGHT",-2,0)
    p.name=text(p,"",0,-48,20,690,T.bright);p.tags=text(p,"",0,-78,11)
    p.history=text(p,"",0,-108,12,690,T.text)
    p.where=text(p,"",0,-163,11)
    p.reference=text(p,"",0,-194,11)
    p.note=text(p,"",0,-271,11)
    p.locations=button(p,"Known locations",0,-333,170,function() self:OpenFishLocations(self.discoveryID) end)
    U.Tip(p.where,"Personal catch locations",function()
        local r=F.db.collection[self.discoveryID];local lines={}
        if r then for zone,n in pairs(r.zones) do lines[#lines+1]=zone..": "..n end end
        table.sort(lines);if #lines==0 then lines[1]="No personal catch locations recorded." end;return lines
    end)
end
function P:OpenDiscovery(id)
    self:PushRoute();self.discoveryID=id;self.journalTab="discovery";self:DisplaySection("journal")
end
function P:RefreshCollection()
    if not self.journal or not self.journal.collection or not self.journal.collection.rows then return end
    local c=self.journal.collection;local zone=self.currentZoneOnly and F.API.Zone() or nil
    local rows=D:Rows(c.search:GetText(),zone,self.discoveryCategory,self.discoveryState,self.discoverySort)
    local pages=math.max(1,math.ceil(#rows/6));self.page=F.Model.Clamp(self.page,1,pages)
    c.zone.text:SetText(zone and "Current zone" or "All zones")
    c.kind.text:SetText(D.categories[self.discoveryCategory]);c.state.text:SetText(D.states[self.discoveryState]);c.sort.text:SetText("Sort: "..D.sorts[self.discoverySort])
    local seen,total=D:Totals()
    c.summary:SetText(seen.." / "..total.." catalog fish discovered\n"..#rows.." matching entries")
    for i,b in ipairs(c.rows) do
        local r=rows[(self.page-1)*6+i];b.record=r;b:SetShown(r~=nil)
        if r then
            local item=F.API.Item(r.id);b.icon:SetTexture((r.owned and r.owned.icon) or (item and item.icon) or "Interface\\Icons\\INV_Misc_Fish_02")
            local caught=r.count>0
            b.icon:SetDesaturated(not caught);b.icon:SetVertexColor(caught and 1 or .65,caught and 1 or .65,caught and 1 or .65)
            b.name:SetText(r.name);b.name:SetTextColor(unpack(caught and T.bright or T.undiscovered))
            b.detail:SetTextColor(unpack(caught and T.muted or T.undiscovered))
            styleBadge(b.badge,r.count)
            b.detail:SetText(D:Tag(r.ref).." · "..(r.count>0 and "Caught · latest "..D:Date(r.owned.last) or "Not yet discovered"))
        end
    end
    c.pages:SetText("Page "..self.page.." / "..pages)
end
function P:RefreshDiscovery()
    local p=self.journal.discovery;p:SetShown(self.journalTab=="discovery")
    if self.journalTab~="discovery" then return end
    local ref,owned=F.Data.fish[self.discoveryID],F.db.collection[self.discoveryID]
    p.name:SetText(owned and owned.name or ref and ref.name or ("Item "..tostring(self.discoveryID)))
    p.tags:SetText(D:Tag(ref)..(ref and (" · Reference checked "..ref.checked) or " · Personal observation"))
    local caught=owned and owned.count>0
    p.name:SetTextColor(unpack(caught and T.bright or T.undiscovered))
    styleBadge(p.badge,caught and owned.count or 0," catches")
    p.history:SetText(caught and (owned.count.." recovered\nFirst catch: "..D:Date(owned.first).."\nLatest catch: "..D:Date(owned.last)) or "Not yet personally caught.\nDiscoveries are recorded when verified bobber loot is recovered.")
    local n=0;if owned then for _,count in pairs(owned.zones) do if count>0 then n=n+1 end end end
    p.where:SetText("Personal locations: "..n.." · hover for counts"..(caught and ("\nFirst location: "..(owned.firstZone or "Not recorded in older history")) or ""))
    local zones=ref and ref.zones or {}
    p.reference:SetText(#zones>0 and ("REFERENCE LOCATIONS (zone listings)\n"..table.concat(zones,", ")) or "REFERENCE LOCATIONS\nNo verified fishing-location listing yet. Personal catches are kept separately.")
    p.note:SetText(ref and (ref.note or (ref.bloated and "Bloated fish are listed separately. Contents, camp requirements and catch rates are not inferred." or "Zone listings do not establish specific water, time, skill or catch-rate requirements.")) or "Recovered fishing loot has no catalog classification yet. It does not count toward catalog fish discoveries.")
end
