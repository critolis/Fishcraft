local passed = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ': ' .. tostring(err))
    passed = passed + 1; print('PASS: '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local M = F.Model
test('saved variables defaults and invalid scale',function()
    local db=M.Defaults({ui={scale=0/0,x=5,y=-1,locked='yes'}})
    eq(db.schema,2);eq(db.ui.scale,1);eq(db.ui.x,1);eq(db.ui.y,0);eq(db.ui.locked,false)
end)
test('existing preferences retained',function()
    local db=M.Defaults({ui={scale=1.2,locked=true,reducedMotion=true},settings={preferredPole=500}})
    eq(db.ui.scale,1.2);eq(db.ui.locked,true);eq(db.settings.preferredPole,500)
end)
test('future schema is not overwritten',function()
    local input={schema=3};local db=M.Defaults(input);eq(db,nil);eq(input.schema,3)
end)
test('malformed saved sessions normalize safely',function()
    local db=M.Defaults({history={false,{started=100,seconds='bad',casts=-3}},activeSession={started=100,seconds=0/0,casts='bad'}})
    eq(#db.history,1);eq(db.history[1].seconds,0);eq(db.history[1].casts,0);eq(db.activeSession.seconds,0);eq(db.activeSession.casts,0)
end)
test('layout fits nine anchors across four resolutions and three scales',function()
    for _,res in ipairs({{1920,1080},{1280,720},{2560,1440},{800,600}}) do
        for _,requested in ipairs({.75,1,1.5}) do
            local scale=math.min(requested,res[1]/850,res[2]/650)
            for _,nx in ipairs({0,.5,1}) do for _,ny in ipairs({0,.5,1}) do
                local x=M.Clamp(nx*res[1],52*scale,res[1]-52*scale)
                local y=M.Clamp(ny*res[2],52*scale,res[2]-52*scale)
                local points=M.Layout(x,y,res[1],res[2],scale)
                for i,p in ipairs(points) do
                    local px,py=x+p.x*scale,y+p.y*scale
                    assert(px>=48*scale-.001 and px<=res[1]-48*scale+.001)
                    assert(py>=44*scale-.001 and py<=res[2]-44*scale+.001)
                    for j=i+1,#points do
                        local dx,dy=p.x-points[j].x,p.y-points[j].y
                        assert(dx*dx+dy*dy>56*56,'overlapping action circles')
                        assert(math.abs(dx)>94 or math.abs(dy)>14,'overlapping labels')
                    end
                end
            end end
        end
    end
end)
test('corner, edge and center choose expected arcs',function()
    local _,a=M.Layout(52,52,1920,1080,1);eq(a,90)
    local _,b=M.Layout(52,540,1920,1080,1);eq(b,180)
    local _,c=M.Layout(960,540,1920,1080,1);eq(c,360)
end)
test('pole selection prioritizes user preference',function()
    local items={{id=1,bonus=50},{id=2,bonus=10}}
    eq(M.Choose(items,2).id,2);eq(M.Choose(items).id,1)
end)
test('unknown bonuses never masquerade as strongest',function()
    local item,known=M.Choose({{id=1},{id=2,bonus=50}});eq(item.id,1);eq(known,false)
end)
test('restoration distinguishes same-ID instances',function()
    local a={link='item:1',guid='a'};local b={link='item:1',guid='b',bag=0,slot=2}
    local step,msg=M.RestoreStep({main=a,off=false},{[16]=b},{b})
    eq(step,nil);assert(msg:find('missing'))
end)
test('restoration handles initially empty main hand',function()
    local off={link='item:2',guid='b'}
    local step=M.RestoreStep({main=false,off=off},{[16]={link='pole'},[17]=off},{})
    eq(step.slot,16);eq(step.empty,true)
end)
test('restoration clears off hand before a two-handed original',function()
    local main={link='item:1',guid='a'}
    local step=M.RestoreStep({main=main,off=false},{[16]={link='pole'},[17]={link='shield'}},{main})
    eq(step.slot,17);eq(step.empty,true)
end)
test('missing, locked and ambiguous items fail closed',function()
    local a={link='a'}
    eq(M.RestoreStep({main=a,off=false},{},{a,a}),nil)
    eq(M.RestoreStep({main=a,off=false},{},{{link='a',locked=true}}),nil)
    eq(M.RestoreStep({main=a,off=false},{},{}),nil)
end)
Mock.inventory[16]=Mock.Item(100,'main')
Mock.inventory[17]=Mock.Item(101,'off')
Mock.bags[1]=Mock.Item(200,'pole',true)
Mock.bags[2]=Mock.Item(6533,'lure');Mock.bags[2].count=5
test('login in combat defers all frame creation',function()
    Mock.combat=true;local n=#Mock.frames;F:Initialize();eq(F.ready,nil);eq(#Mock.frames,n)
    Mock.combat=false;F:Emit('PLAYER_REGEN_ENABLED');eq(F.ready,true)
end)
test('all six actions and settings initialize',function()
    eq(#F.Radial.buttons,6);eq(F.db.schema,2);eq(F.spellID,7620)
    eq(F.Radial.root.driver,'[combat] hide; show');assert(F.Panels.gear);assert(F.Panels.journal)
end)
test('macro is absent until a pole is equipped',function() eq(F.Radial.buttons[2]:GetAttribute('type'),nil) end)
test('uncached equipment is not mistaken for an empty slot',function()
    local old=GetInventoryItemLink;GetInventoryItemLink=function() return nil end
    F.Equipment:Equip();eq(F.db.equipment,nil);eq(Mock.inventory[16].id,100)
    GetInventoryItemLink=old;F:Refresh()
end)
test('equipment snapshot preserves both original item identities',function()
    F.Equipment:Equip();eq(Mock.inventory[16].id,200);eq(Mock.inventory[17],nil)
    eq(F.db.equipment.main.guid,'main');eq(F.db.equipment.off.guid,'off');eq(Mock.cursor,nil)
end)
test('repeated equip cannot overwrite the snapshot',function()
    F.Equipment:Equip();eq(F.db.equipment.main.guid,'main');eq(F.db.equipment.off.guid,'off')
end)
test('lure macro targets the actual bag slot and main hand',function()
    eq(F.Radial.buttons[2]:GetAttribute('type'),'macro')
    eq(F.Radial.buttons[2]:GetAttribute('macrotext'),'/use [nocombat] 0 2\n/use [nocombat] 16')
end)
test('active enchantment prevents lure replacement',function()
    Mock.enchant=true;F:Refresh();eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
    Mock.enchant=false;F:Refresh()
end)
test('unavailable enchant API prevents lure replacement',function()
    local old=C_PaperDollInfo;C_PaperDollInfo=nil;F:Refresh();eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
    C_PaperDollInfo=old;F:Refresh()
end)
test('lure pre-click rescan rejects a stale bag slot',function()
    local old=Mock.bags[2];Mock.bags[2]=Mock.Item(999,'unrelated')
    F.Radial.buttons[2].scripts.PreClick();eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
    Mock.bags[2]=old;F:Refresh()
end)
test('split lure stacks are aggregated without duplicate preferences',function()
    Mock.bags[9]=Mock.Item(6533,'second-lure');Mock.bags[9].count=3;F:Refresh()
    eq(#F.Lures.items,1);eq(F.Lures.selected.count,8);eq(F.Lures.selected.slot,2)
    Mock.bags[9]=nil;F:Refresh()
end)
test('cursor item blocks lure and equipment changes',function()
    Mock.cursor=Mock.Item(999,'cursor');F:Refresh();eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
    F.Equipment:Restore();eq(Mock.inventory[16].id,200);eq(Mock.cursor.id,999)
    Mock.cursor=nil;F:Refresh()
end)
test('gear restoration is one slot per click and completes exactly',function()
    F.Equipment:Restore();eq(Mock.inventory[16].guid,'main');assert(F.db.equipment)
    F.Equipment:Restore();eq(Mock.inventory[17].guid,'off');eq(F.db.equipment,nil);eq(Mock.cursor,nil)
end)
test('missing original item retains snapshot',function()
    F.Equipment:Equip();local missing
    for slot,item in pairs(Mock.bags) do if item.guid=='main' then missing=item;Mock.bags[slot]=nil end end
    F.Equipment:Restore();assert(F.db.equipment);eq(Mock.inventory[16].id,200)
    Mock.bags[8]=missing;F.Equipment:Restore();F.Equipment:Restore();eq(F.db.equipment,nil)
end)
test('full bags with an off-hand item block pole equip',function()
    local saved=Mock.bags;Mock.bags={}
    for i=1,10 do Mock.bags[i]=Mock.Item(300+i,'fill'..i) end
    Mock.bags[1]=Mock.Item(200,'pole',true);F:Refresh();F.Equipment:Equip()
    eq(Mock.inventory[16].id,100);eq(F.db.equipment,nil);Mock.bags=saved;F:Refresh()
end)
test('combat refresh and actions never mutate protected frames or equipment',function()
    Mock.combat=true;local n=Mock.mutations
    F:Refresh();F.Radial:ApplySettings();F.Radial:Toggle();F.Equipment:Equip();F.Equipment:Restore()
    F.Lures:Configure(F.Radial.buttons[2]);F.Radial.buttons[2].scripts.PreClick()
    eq(Mock.mutations,n);eq(Mock.inventory[16].id,100);eq(F.dirty,true)
    Mock.combat=false;F:Emit('PLAYER_REGEN_ENABLED');eq(F.dirty,false)
end)
test('animation completes and removes its OnUpdate',function()
    F.db.ui.reducedMotion=false;F.Radial:Toggle()
    assert(F.Radial.root.scripts.OnUpdate);F.Radial.root.scripts.OnUpdate(F.Radial.root,.5)
    eq(F.Radial.root.scripts.OnUpdate,nil);eq(F.Radial.buttons[1]:IsShown(),true)
    F.Radial:Close();F.Radial.root.scripts.OnUpdate(F.Radial.root,.5);eq(F.Radial.buttons[1]:IsShown(),false)
end)
test('reduced motion completes immediately',function()
    F.db.ui.reducedMotion=true;F.Radial:Toggle();eq(F.Radial.root.scripts.OnUpdate,nil);eq(F.Radial.buttons[1]:IsShown(),true)
    F.Radial:Close();eq(F.Radial.buttons[1]:IsShown(),false)
end)
test('dragging stops at combat entry without moving protected frames',function()
    F.Radial.launcher.scripts.OnDragStart();eq(F.Radial.dragging,true)
    Mock.cursorX=700;Mock.cursorY=500;F.Radial.dragDriver.scripts.OnUpdate()
    assert(F.db.ui.x>0 and F.db.ui.x<1)
    Mock.combat=true;local n=Mock.mutations;F:Emit('PLAYER_REGEN_DISABLED')
    eq(F.Radial.dragging,false);eq(F.Radial.dragDriver.scripts.OnUpdate,nil);eq(Mock.mutations,n)
    Mock.combat=false;F:Emit('PLAYER_REGEN_ENABLED')
end)
test('session filters unrelated and duplicated casts',function()
    F.Session:Start();F.Session:Cast('target','a',7620);F.Session:Cast('player','b',1)
    F.Session:Cast('player','c',7620);F.Session:Cast('player','c',7620)
    eq(F.Session.current.casts,1)
end)
test('pause and resume exclude paused time',function()
    Mock.clock=10;F.Session:Pause();eq(F.Session:Elapsed(),10)
    Mock.clock=30;F.Session:Cast('player','d',7620);eq(F.Session.current.casts,1)
    F.Session:Start();Mock.clock=40;eq(F.Session:Elapsed(),20)
    F.Session:Finish();eq(#F.db.history,1);eq(F.db.history[1].seconds,20)
end)
test('session history is bounded',function()
    for i=1,35 do F.Session:Start();F.Session:Finish() end;eq(#F.db.history,30)
end)
test('location shortcut is independent of learning fishing',function()
    Mock.spellKnown=false;F:Refresh();eq(F.spellID,nil);eq(F.Radial.buttons[3]:GetAttribute('type'),nil)
    Mock.spellKnown=true;F:Refresh();eq(F.spellID,7620);eq(F.Radial.buttons[3]:GetAttribute('type'),nil)
end)
test('unsupported interface disables gameplay controls',function()
    F.compatible=false;F:Refresh();eq(F.Radial.buttons[3]:GetAttribute('type'),nil)
    F.Equipment:Equip();eq(Mock.inventory[16].id,100);F.compatible=true;F:Refresh()
end)
test('bag events coalesce into one scheduled scan',function()
    Mock.Flush();F:QueueRefresh();F:QueueRefresh();F:QueueRefresh();eq(#Mock.timers,1);Mock.Flush()
end)
test('logout preserves active session without counting offline time',function()
    F.Session:Start();Mock.clock=50;F:Emit('PLAYER_LOGOUT');assert(F.db.activeSession);eq(F.Session.runningSince,nil)
end)
test('schema one migrates without losing weapons or session history',function()
    local old={schema=1,equipment={main={guid='weapon'},off=false},history={{started=10,casts=7,seconds=42}}}
    local db=M.Defaults(old);eq(db.schema,2);eq(db.equipment.main.guid,'weapon');eq(db.history[1].casts,7)
    eq(db.history[1].catches,0);eq(db.settings.trackCollection,true);eq(db.cooking.target,150)
end)
test('single workspace close button sits above its drag layer and closes every section',function()
    local P=F.Panels;local w=P.window
    for _,key in ipairs({'journal','settings','locations','cooking','stats'}) do
        P:OpenSection(key);eq(w:IsShown(),true);assert(w.close:GetFrameLevel()>w.drag:GetFrameLevel())
        eq(w.drag.point[2],-52);Mock.Click(w.close);eq(w:IsShown(),false)
    end
end)

test('radial pole click toggles both weapons in one subsequent click',function()
    local b=F.Radial.buttons[1];Mock.Click(b)
    eq(Mock.inventory[16].id,200);eq(Mock.inventory[17],nil);eq(b.label:GetText(),'Swap back')
    eq(F.Panels.settings:IsShown(),false)
    Mock.Click(b);eq(Mock.inventory[16].guid,'main');eq(Mock.inventory[17].guid,'off')
    eq(F.db.equipment,nil);eq(Mock.cursor,nil);eq(b.label:GetText(),'Fishing pole')
end)
test('missing off hand blocks the entire swap before main hand changes',function()
    F.Equipment:Toggle();local saved,slot
    for i,item in pairs(Mock.bags) do if item.guid=='off' then saved,slot=item,i;Mock.bags[i]=nil end end
    F.Equipment:Toggle();eq(Mock.inventory[16].id,200);assert(F.db.equipment)
    Mock.bags[slot]=saved;F.Equipment:Toggle();eq(Mock.inventory[17].guid,'off');eq(F.db.equipment,nil)
end)
test('toggle preserves initially empty off hand',function()
    local saved=Mock.inventory[17];Mock.inventory[17]=nil
    F.Equipment:Toggle();F.Equipment:Toggle();eq(Mock.inventory[16].guid,'main');eq(Mock.inventory[17],nil)
    eq(F.db.equipment,nil);Mock.inventory[17]=saved;F:Refresh()
end)
test('toggle restores initially empty weapon slots',function()
    local main,off=Mock.inventory[16],Mock.inventory[17];Mock.inventory={}
    F.Equipment:Toggle();eq(Mock.inventory[16].id,200);F.Equipment:Toggle()
    eq(Mock.inventory[16],nil);eq(Mock.inventory[17],nil);eq(F.db.equipment,nil);eq(Mock.cursor,nil)
    Mock.inventory[16],Mock.inventory[17]=main,off;F:Refresh()
end)
test('gear shortcut opens equipment preferences inside settings',function()
    SlashCmdList.FISHCRAFT('gear');eq(F.Panels.settings:IsShown(),true);eq(F.Panels.settingsTab,'equipment')
    eq(F.Panels.settings.equipment:IsShown(),true);eq(F.Panels.settings.general:IsShown(),false)
    Mock.Click(F.Panels.window.close)
end)
local J=F.Collection
local serial=0
local function loot(id,count,source)
    serial=serial+1;Mock.loot={id=id,count=count,source=source or ('GameObject-0-1-2-3-35591-'..serial)}
    F:Emit('UNIT_SPELLCAST_SUCCEEDED','player','cast'..serial,7620)
end
GetNumLootItems=function() return Mock.loot and 1 or 0 end
GetLootSlotLink=function() return Mock.loot and ('item:'..Mock.loot.id) end
GetLootSlotInfo=function() local r=Mock.loot;if r then return 'icon','Fish '..r.id,r.count,1,1 end end
GetLootSourceInfo=function() local r=Mock.loot;if r then return r.source,r.count end end
test('loot is counted only when recovered, not when observed',function()
    F.db.collection={};F.Session:Start();loot(6291,3);F:Emit('LOOT_READY');F:Emit('LOOT_OPENED')
    eq(F.db.collection[6291],nil);F:Emit('LOOT_SLOT_CLEARED',1)
    eq(F.db.collection[6291].count,3);eq(F.db.collection[6291].zones['Test shore'],3)
    eq(F.Session.current.catches,3);eq(F.db.collection[6291].first,Mock.wall)
end)
test('duplicate cleared events and reopened bobbers do not double count',function()
    F:Emit('LOOT_SLOT_CLEARED',1);F:Emit('LOOT_CLOSED');F:Emit('LOOT_OPENED');F:Emit('LOOT_SLOT_CLEARED',1)
    eq(F.db.collection[6291].count,3);F:Emit('LOOT_CLOSED')
end)
test('partial recovery and reopening count remaining fish once',function()
    loot(6291,5);F:Emit('LOOT_OPENED');Mock.loot.count=3;F:Emit('LOOT_SLOT_CHANGED',1)
    eq(F.db.collection[6291].count,5);F:Emit('LOOT_CLOSED');F:Emit('LOOT_OPENED');F:Emit('LOOT_SLOT_CLEARED',1)
    eq(F.db.collection[6291].count,8);F:Emit('LOOT_CLOSED')
end)
test('closing unlooted bobber does not add catches',function()
    loot(6291,10);F:Emit('LOOT_OPENED');F:Emit('LOOT_CLOSED');eq(F.db.collection[6291].count,8)
end)
test('corpse loot and unknown gameobjects are rejected',function()
    for _,source in ipairs({'Creature-0-1-2-3-35591-1','GameObject-0-1-2-3-99999-1'}) do
        loot(6291,9,source);F:Emit('LOOT_OPENED');F:Emit('LOOT_SLOT_CLEARED',1);F:Emit('LOOT_CLOSED')
    end
    eq(F.db.collection[6291].count,8)
end)
test('expired cast and intervening nonfishing spell invalidate attribution',function()
    loot(6291,9);Mock.clock=Mock.clock+41;F:Emit('LOOT_OPENED');F:Emit('LOOT_SLOT_CLEARED',1)
    loot(6291,9);F:Emit('UNIT_SPELLCAST_SUCCEEDED','player','other',1);F:Emit('LOOT_OPENED');F:Emit('LOOT_SLOT_CLEARED',1)
    eq(F.db.collection[6291].count,8)
end)
test('unavailable or mixed loot sources are skipped',function()
    local old=GetLootSourceInfo;GetLootSourceInfo=nil;loot(6291,9);J:Capture();J:Changed(1,true)
    GetLootSourceInfo=function() return Mock.loot.source,1,'Creature-0-1-2-3-55-1',1 end
    J:Capture();J:Changed(1,true);eq(F.db.collection[6291].count,8);GetLootSourceInfo=old
end)
test('disabled collection does not record catches',function()
    F.db.settings.trackCollection=false;loot(6291,9);J:Capture();J:Changed(1,true)
    eq(F.db.collection[6291].count,8);F.db.settings.trackCollection=true
end)
test('unknown fishing loot is retained separately from fish collection',function()
    loot(99999,2);J:Capture();J:Changed(1,true)
    eq(F.db.collection[99999].count,2);eq(#J:Rows('99999',nil,false),0);eq(#J:Rows('99999',nil,true),1)
    eq(#J:Rows('', 'Test shore',true),2);F:Emit('LOOT_CLOSED')
end)
test('reference fish remain searchable before discovery with source confidence',function()
    local rows=J:Rows('Raw Mithril',nil,false);eq(#rows,1);eq(rows[1].count,0);assert(rows[1].ref.source)
    eq(#J:Rows('Raw Mithril','Stranglethorn Vale',false),1);eq(#J:Rows('[',nil,true),0)
end)
test('vendor listings are never promoted to fishing locations',function()
    eq(#F.Data.fish[6289].zones,0);eq(#F.Locations:ForFish(6289),0)
    local lines=F.Locations:Summary('Stranglethorn Vale');assert(lines[1]:find('unknown'))
    for _,zone in pairs(F.Data.zones) do eq(zone.required,nil) end
end)
local C=F.Cooking
test('verified cooking route merges catfish bands and totals raw fish',function()
    local p=C:Build(1,225,false);eq(#p.rows,4);eq(p.total,282);eq(p.complete,true)
    eq(p.rows[3].from,100);eq(p.rows[3].to,175);eq(p.rows[3].need,120)
end)
test('partial bands and optional reserve stay explicit estimates',function()
    eq(C:Build(150,175,false).total,65);eq(C:Build(100,175,true).total,144)
    eq(C:Build(25,50,false).total,27);eq(C:Build(225,225,false).total,0)
end)
test('unsupported cooking target keeps coverage visibly incomplete',function()
    local p=C:Build(175,300,false);eq(p.complete,false);eq(p.covered,225);eq(p.total,55)
    eq(C:Build(250,300,false).complete,false);eq(#C:Build(250,300,false).rows,0)
end)
test('planner reads available bag ingredients and recipe knowledge',function()
    local saved=F.Equipment.items;F.Equipment.items={{id=6291,count=20},{id=6291,count=5}}
    F.db.cooking={current=1,target=50,buffer=false,active=true,auto=false}
    C_TradeSkillUI={GetRecipeInfo=function() return {learned=false} end};C:Refresh()
    local r=C.plan.rows[1];eq(r.have,25);eq(r.remaining,27);eq(r.known,false);assert(C:GoalText():find('Learn Brilliant Smallfish'))
    C_TradeSkillUI=nil;C:Refresh();eq(C.plan.rows[1].known,nil)
    F.Equipment.items=saved;F:Refresh()
end)
test('planner input validation and skill synchronization',function()
    F.Panels.cooking.current:SetText('150');F.Panels.cooking.target:SetText('100');F.Panels:ApplyCookingInputs()
    eq(F.db.cooking.current,1);F.Panels.cooking.target:SetText('225');F.Panels:ApplyCookingInputs()
    eq(F.db.cooking.current,150);eq(F.db.cooking.target,225);eq(C:UseCurrentSkill(),true);eq(F.db.cooking.current,100)
end)
test('new panels and current goal are reachable without extra radial actions',function()
    SlashCmdList.FISHCRAFT('cooking');eq(F.Panels.cooking:IsShown(),true)
    SlashCmdList.FISHCRAFT('locations');eq(F.Panels.locations:IsShown(),true);eq(#F.Radial.buttons,6)
    F.db.cooking.auto=false;F.db.cooking.current=100
    C_TradeSkillUI={GetRecipeInfo=function() return {learned=true} end};C:Refresh()
    local lines=F.Radial:LocationLines();local found=false
    for _,line in ipairs(lines) do if line:find('estimate') then found=true end end;eq(found,true);C_TradeSkillUI=nil
end)
test('delayed client equipment reads cannot erase a new snapshot',function()
    local main,off=Mock.inventory[16],Mock.inventory[17]
    local id,link,guid=GetInventoryItemID,GetInventoryItemLink,C_Item.GetItemGUID
    GetInventoryItemID=function(_,slot) local i=slot==16 and main or off;return i and i.id end
    GetInventoryItemLink=function(_,slot) local i=slot==16 and main or off;return i and i.link end
    C_Item.GetItemGUID=function(loc) if loc.inventory then local i=loc.inventory==16 and main or off;return i and i.guid end;return guid(loc) end
    F.Equipment:Equip();assert(F.db.equipment);eq(F.db.equipment.main.guid,'main');eq(F.db.equipment.phase,'equipping')
    F:Refresh();assert(F.db.equipment);eq(F.Radial.buttons[1].label:GetText(),'Swap back')
    GetInventoryItemID,GetInventoryItemLink,C_Item.GetItemGUID=id,link,guid
    F:Emit('PLAYER_EQUIPMENT_CHANGED',16);Mock.Flush();eq(F.db.equipment.poleObserved,true)
    Mock.Click(F.Radial.buttons[1]);eq(Mock.inventory[16].guid,'main');eq(Mock.inventory[17].guid,'off');eq(F.db.equipment,nil)
end)
test('manual original gear changes do not silently discard a snapshot',function()
    F.db.equipment={main=F.API.Inventory(16),off=F.API.Inventory(17)};F:Refresh();assert(F.db.equipment)
    F.Equipment:Toggle();eq(F.db.equipment,nil)
end)
local O=F.Optimizer
local function lure(id,count,locked) return {id=id,count=count or 1,locked=locked,bag=0,slot=2} end
test('optimizer uses weakest sufficient eligible lure independent of inventory order',function()
    local item,state=O:Choose(100,155,225,{lure(6533),lure(6532),lure(6529)},nil,false)
    eq(state,'recommend');eq(item.id,6532)
    eq(O:Choose(100,200,225,{lure(6533),lure(6529)},nil,false).id,6529)
end)
test('target already met saves lures unless keep-lure preference is enabled',function()
    local item,state=O:Choose(100,100,75,{lure(6533),lure(6529)},nil,false)
    eq(item,nil);eq(state,'enough');eq(O:Choose(100,100,75,{lure(6533),lure(6529)},nil,true).id,6529)
end)
test('optimizer checks base skill rather than buffed skill for lure eligibility',function()
    local item,state=O:Choose(49,100,150,{lure(6530),lure(6529)},nil,false)
    eq(item,nil);eq(state,'short')
    eq(O:Choose(50,100,150,{lure(6530)},nil,false).id,6530)
end)
test('unknown locked and exhausted lures cannot enter recommendations',function()
    local item,state=O:Choose(300,300,350,{lure(999),lure(6530,0),lure(6533,1,true)},nil,false)
    eq(item,nil);eq(state,'no_lure')
end)
test('preferred lure breaks equal-bonus ties but cannot select a wasteful upgrade',function()
    local items={lure(6811),lure(6530),lure(6533)}
    eq(O:Choose(100,100,150,items,6811,false).id,6811)
    eq(O:Choose(100,100,150,items,6533,false).id,6530)
end)
test('insufficient maximum bonus gives a shortfall without consuming anything',function()
    local item,state,missing=O:Choose(100,100,225,{lure(6533)},nil,false)
    eq(item,nil);eq(state,'short');eq(missing,25)
end)
test('skill snapshot includes live bonuses once and rejects invalid data',function()
    local old=C_SkillInfo.GetSkillLineInfoByID
    C_SkillInfo.GetSkillLineInfoByID=function() return {rank=100,modifier=30,tempPoints=50,maxRank=150} end
    eq(F.API.SkillSnapshot().total,180)
    C_SkillInfo.GetSkillLineInfoByID=function() return {rank=100,modifier=nil,tempPoints=0,maxRank=150} end
    eq(F.API.SkillSnapshot(),nil)
    C_SkillInfo.GetSkillLineInfoByID=function() return {rank=100,modifier=0/0,tempPoints=0,maxRank=150} end
    eq(F.API.SkillSnapshot(),nil);C_SkillInfo.GetSkillLineInfoByID=old
end)
test('conflicting pole bonuses are never added to the client total',function()
    eq(next(F.Data.poleBonuses),nil);eq(F.API.SkillSnapshot().total,130)
end)
test('guide targets exclude unresolved Stranglethorn waters and unknown zones',function()
    eq(O:Target('Darnassus',''),75);eq(O:Target('Stranglethorn Vale','Jaguero Isle'),nil)
    eq(O:Target('Stranglethorn Vale',''),nil);eq(O:Target('Stranglethorn Vale','Booty Bay'),225)
    eq(O:Target('Unverified zone',''),nil)
end)
test('personal target only applies to the exact location where it was set',function()
    F.Panels.settings.optimizer.target:SetText('225');F.Panels:SetOptimizerTarget()
    eq(O:Target('Test shore',''),225);eq(O:Target('Test shore','Another water'),nil);eq(O:Target('Darnassus',''),75)
    F.Panels.settings.optimizer.target:SetText('1001');F.Panels:SetOptimizerTarget();eq(F.db.optimizer.target,225)
end)
test('advice mode preserves manual lure and recommendation mode picks the evaluated result',function()
    F.Equipment:Equip();F.db.optimizer.useRecommended=false;F:Refresh()
    eq(O.result.state,'recommend');eq(F.Lures.selected.id,6533);eq(F.Lures.manual.id,6533)
    F.db.optimizer.useRecommended=true;F:Refresh();eq(F.Radial.buttons[2]:GetAttribute('type'),'macro')
    F.db.optimizer.target=75;F:Refresh();eq(O.result.state,'enough');eq(F.Lures.selected,nil)
    eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
end)
test('active or unreadable enchant never triggers replacement',function()
    F.db.optimizer.target=225;Mock.enchant=true;F:Refresh();eq(O.result.state,'active');eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
    Mock.enchant=false;local old=C_PaperDollInfo;C_PaperDollInfo=nil;F:Refresh()
    eq(O.result.state,'unknown_enchant');eq(F.Radial.buttons[2]:GetAttribute('type'),nil);C_PaperDollInfo=old;F:Refresh()
end)
test('unknown target disables recommended application and disabling optimizer restores manual mode',function()
    F.db.optimizer.target=nil;F:Refresh();eq(O.result.state,'unknown_target');eq(F.Radial.buttons[2]:GetAttribute('type'),nil)
    F.db.optimizer.enabled=false;F:Refresh();eq(F.Lures.selected.id,6533);eq(F.Radial.buttons[2]:GetAttribute('type'),'macro')
    F.db.optimizer.enabled=true;F.db.optimizer.useRecommended=false;F.Equipment:Toggle()
end)
test('optimizer requests actual pole equip before making a prediction',function()
    eq(O:Evaluate().state,'equip');eq(#O:Lines()>0,true)
end)
test('optimizer stays in settings and location shortcut always opens current zone',function()
    SlashCmdList.FISHCRAFT('optimizer');eq(F.Panels.settingsTab,'optimizer');eq(F.Panels.settings.optimizer:IsShown(),true)
    F.Panels.locationFish=6289;Mock.Click(F.Radial.buttons[3]);eq(F.Panels.locationFish,nil)
    eq(F.Panels.locations:IsShown(),true);assert(F.Panels.locations.zone:GetText():find('Test shore'))
    eq(F.Radial.buttons[3].label:GetText(),'Location info');assert(not F.Radial.buttons[3].secure);eq(#F.Radial.buttons,6)
end)
test('first fishing cast automatically starts a visible live statistics timer',function()
    F.Session:Finish();F.db.history={};F.db.statistics=nil;F.Statistics:Initialize(F.db);Mock.clock=200
    F.Session:Cast('player','auto-first',7620);eq(F.Session.runningSince,200);eq(F.Session.current.casts,1)
    Mock.clock=212;F.Panels.stats.scripts.OnUpdate(F.Panels.stats,1)
    assert(F.Panels.stats.live:GetText():find('00:00:12'));eq(F.Panels.stats.total:GetText(),'1')
    F.Session:Cast('player','auto-first',7620);eq(F.Session.current.casts,1)
end)
test('manual pause prevents auto-resume and excludes paused time',function()
    F.Session:Pause();Mock.clock=240;F.Session:Cast('player','paused-cast',7620)
    eq(F.Session.runningSince,nil);eq(F.Session:Elapsed(),12);eq(F.Session.current.casts,1)
    F.Session:Start();Mock.clock=245;eq(F.Session:Elapsed(),17)
end)
test('saving current session never double counts statistics and next cast starts a new one',function()
    F.Session:Finish();F.Panels:RefreshStats();eq(F.Panels.stats.total:GetText(),'1')
    F.Session:Cast('player','next-session',7620);F.Panels:RefreshStats();eq(F.Panels.stats.total:GetText(),'2')
end)
test('automatic sessions obey recording settings and ignore unrelated casts',function()
    F.Session:Finish();F.db.settings.autoStartSession=false;F.Session:Cast('player','auto-off',7620);eq(F.Session.current,nil)
    F.db.settings.autoStartSession=true;F.db.settings.trackSessions=false;F.Session:Cast('player','tracking-off',7620);eq(F.Session.current,nil)
    F.db.settings.trackSessions=true;F.Session:Cast('target','target-cast',7620);F.Session:Cast('player','other-cast',1);eq(F.Session.current,nil)
end)
test('logout pauses elapsed time without treating it as a manual pause',function()
    F.Session:Cast('player','before-logout',7620);Mock.clock=250;F:Emit('PLAYER_LOGOUT')
    eq(F.Session.runningSince,nil);eq(F.db.activeSession.manualPaused,false)
    Mock.clock=300;F.Session:Cast('player','after-reload',7620);eq(F.Session:Elapsed(),5)
end)
local D,P=F.Discoveries,F.Panels
test('discovery categories separate new Forever fish, quest rares and bloated fish',function()
    eq(#D:Rows('',nil,1),23);eq(#D:Rows('',nil,2),1);eq(D:Rows('',nil,2)[1].id,251524)
    eq(#D:Rows('',nil,3),3);eq(#D:Rows('',nil,4),3);eq(D:Tag(nil),'Unclassified fishing loot')
    for _,r in ipairs(D:Rows('',nil,3)) do assert(r.ref.rareSource);eq(r.ref.newForever,nil) end
    eq(#F.Data.fish[251524].zones,0);eq(#F.Locations:ForFish(251524),0)
end)
test('unclassified loot cannot inflate fish discovery or rare counts',function()
    local seen,total,rare,new=D:Totals();eq(seen,1);eq(total,23);eq(rare,0);eq(new,0)
    F.db.collection[99999].quality=4
    eq(#D:Rows('99999',nil,3),0);eq(#D:Rows('99999',nil,1),0);eq(#D:Rows('99999',nil,5),1)
end)
test('caught and unseen filters intersect category, name and zone',function()
    eq(#D:Rows('',nil,1,2),1);eq(#D:Rows('',nil,1,3),22)
    eq(#D:Rows('Whimsy',nil,2,2),0);eq(#D:Rows('Whimsy',nil,2,3),1)
    eq(#D:Rows('', 'Stranglethorn Vale',3,3),3);eq(#D:Rows('', 'Darnassus',3,3),0)
    eq(#D:Rows('[',nil,5),0)
end)
test('new discovery records its first location only after loot recovery',function()
    Mock.wall=1700000100;loot(251524,2);J:Capture();eq(F.db.collection[251524],nil)
    J:Changed(1,true);local r=F.db.collection[251524]
    eq(r.count,2);eq(r.first,1700000100);eq(r.firstZone,'Test shore');eq(r.firstSubzone,'')
    eq(#F.Data.fish[251524].zones,0);eq(F.Locations:ForFish(251524)[1].name,'Test shore')
    eq(#D:Rows('', 'Test shore',2,2),1)
end)
test('subsequent catches and duplicate events preserve first discovery',function()
    local old=GetRealZoneText;GetRealZoneText=function() return 'Another shore' end
    Mock.wall=1700000200;loot(251524,1);J:Capture();J:Changed(1,true);J:Changed(1,true)
    local r=F.db.collection[251524];eq(r.count,3);eq(r.first,1700000100);eq(r.last,1700000200)
    eq(r.firstZone,'Test shore');eq(r.zones['Another shore'],1);eq(#F.Locations:ForFish(251524),2)
    GetRealZoneText=old
end)
test('named rare fish counts independently of item quality and updates collection totals',function()
    Mock.wall=1700000300;loot(19805,1);J:Capture();J:Changed(1,true)
    eq(#D:Rows('',nil,3,2),1);eq(#D:Rows('',nil,3,3),2)
    local seen,total,rare,new=D:Totals();eq(seen,3);eq(total,23);eq(rare,1);eq(new,1)
end)
test('discovery dates sort newest first with unseen records last',function()
    eq(D:Rows('',nil,1,1,2)[1].id,19805)
    Mock.wall=1700000400;loot(251524,1);J:Capture();J:Changed(1,true)
    eq(D:Rows('',nil,1,1,3)[1].id,251524);eq(D:Rows('',nil,1,1,2)[1].id,19805)
    eq(D:Rows('',nil,1,1,3)[23].count,0);eq(D:Date(0),'Not recorded')
end)
test('old saved catches gain catalog classification without invented locations or dates',function()
    local old=F.db.collection[13890]
    F.db.collection[13890]={count=7,first=1600000000,last=1600000100,name='Raw Plated Armorfish',zones={['Old lake']=7}}
    F.Model.Defaults(F.db)
    eq(#D:Rows('Plated',nil,1,2),1);eq(F.db.collection[13890].firstZone,nil)
    P:OpenDiscovery(13890);assert(P.journal.discovery.where:GetText():find('Not recorded'))
    eq(F.db.collection[13890].first,1600000000);eq(F.db.collection[13890].count,7)
    F.db.collection[13890]=old
end)
test('discovery filter controls cycle and clamp empty pages',function()
    P.discoveryCategory=1;P.discoveryState=1;P.discoverySort=1;P.page=4;P:RefreshCollection()
    eq(P.page,4);Mock.Click(P.journal.collection.kind);eq(P.discoveryCategory,2);eq(P.page,1)
    Mock.Click(P.journal.collection.state);eq(P.discoveryState,2)
    Mock.Click(P.journal.collection.state);eq(P.discoveryState,3)
    P.page=99;P:RefreshCollection();eq(P.page,1);eq(P.journal.collection.rows[1]:IsShown(),false)
    assert(P.journal.collection.summary:GetText():find('0 matching entries'))
    Mock.Click(P.journal.collection.sort);eq(P.discoverySort,2)
    P.discoveryCategory=1;P.discoveryState=1;P:RefreshCollection()
end)
test('fish detail stays in the journal with honest sources and unchanged radial actions',function()
    Mock.Click(P.journal.collection.rows[1]);eq(P.journalTab,'discovery')
    eq(P.journal.discovery:IsShown(),true);eq(P.journal.collection:IsShown(),false)
    P:OpenDiscovery(251524);assert(P.journal.discovery.reference:GetText():find('No verified'))
    eq(P.Source,nil);eq(P.source,nil);eq(P.journal.discovery.source,nil)
    P:OpenDiscovery(19805);assert(P.journal.discovery.note:GetText():find('Rare Fish'))
    P:OpenDiscovery(99999)
    assert(P.journal.discovery.note:GetText():find('no catalog classification'));eq(#F.Radial.buttons,6)
    P.journalTab='collection';P:Refresh();eq(P.journal.discovery:IsShown(),false)
end)
test('expanded location lists expose every catch across pages and reset on zone changes',function()
    P.locationFish=nil;P.locationName='Stranglethorn Vale';P:RefreshLocations()
    local expected=J:Rows('', 'Stranglethorn Vale',true);assert(#expected>6)
    local found={}
    for page=1,math.ceil(#expected/6) do
        for _,row in ipairs(P.locations.rows) do if row:IsShown() then assert(not found[row.id]);found[row.id]=true end end
        Mock.Click(P.locations.nextPage)
    end
    for _,row in ipairs(expected) do assert(found[row.id]) end
    eq(P.locationPage,math.ceil(#expected/6))
    P.locationName='Darnassus';P:RefreshLocations();eq(P.locationPage,1)
end)
test('expanded reference records have consistent reverse locations and provenance',function()
    for id,ref in pairs(F.Data.fish) do
        assert(ref.source:find('/forever/item='));assert(ref.checked);eq(ref.dropRate,nil);eq(ref.requiredSkill,nil)
        for _,zone in ipairs(ref.zones) do
            local matches=0;for _,listed in ipairs(F.Data.zones[zone].fish) do if listed==id then matches=matches+1 end end
            eq(matches,1)
        end
    end
end)
test('radial icons share an upward lift before spreading along curved paths',function()
    local bounds={left=-900,right=900,bottom=-500,top=500}
    local points=M.Layout(960,540,1920,1080,1)
    for _,progress in ipairs({0,.1,.28}) do
        local x,y=M.RadialPose(points[1],progress,bounds)
        for _,point in ipairs(points) do local bx,by,_,label=M.RadialPose(point,progress,bounds);eq(bx,x);eq(by,y);eq(label,0) end
    end
    local _,start=M.RadialPose(points[1],0,bounds);local _,raised=M.RadialPose(points[1],.28,bounds);assert(raised>start)
    local x,y=M.RadialPose(points[2],.64,bounds);assert(x<0 and y>0)
    for _,point in ipairs(points) do local px,py,alpha,label=M.RadialPose(point,1,bounds);eq(px,point.x);eq(py,point.y);eq(alpha,1);eq(label,1) end
end)
test('entire lift and fan path stays inside screen bounds at edge and corner anchors',function()
    for _,res in ipairs({{1920,1080},{1280,720},{800,600}}) do
        for _,requested in ipairs({.75,1,1.5}) do
            local scale=math.min(requested,res[1]/850,res[2]/650)
            for _,nx in ipairs({0,.5,1}) do for _,ny in ipairs({0,.5,1}) do
                local x=M.Clamp(nx*res[1],52*scale,res[1]-52*scale)
                local y=M.Clamp(ny*res[2],52*scale,res[2]-52*scale)
                local bounds={left=48-x/scale,right=(res[1]-x)/scale-48,bottom=44-y/scale,top=(res[2]-y)/scale-44}
                for _,point in ipairs(M.Layout(x,y,res[1],res[2],scale)) do for frame=0,60 do
                    local px,py=M.RadialPose(point,frame/60,bounds)
                    assert(px>=bounds.left-.001 and px<=bounds.right+.001)
                    assert(py>=bounds.bottom-.001 and py<=bounds.top+.001)
                end end
            end end
        end
    end
end)
test('rapid radial toggles reverse without jumps and disable actions until settled',function()
    local R=F.Radial;F.db.ui.reducedMotion=false;R:Close(true);R:Animate(true)
    for _,b in ipairs(R.buttons) do eq(b.mouse,false);eq(b.alpha,0) end
    R.root.scripts.OnUpdate(R.root,.21)
    local x,y=R.buttons[2].point[4],R.buttons[2].point[5]
    R:Close();eq(R.buttons[2].point[4],x);eq(R.buttons[2].point[5],y)
    R.root.scripts.OnUpdate(R.root,.03)
    x,y=R.buttons[2].point[4],R.buttons[2].point[5]
    R:Animate(true);eq(R.buttons[2].point[4],x);eq(R.buttons[2].point[5],y)
    R.root.scripts.OnUpdate(R.root,1);eq(R.root.scripts.OnUpdate,nil)
    for i,b in ipairs(R.buttons) do eq(b.mouse,true);eq(b.point[4],R.points[i].x);eq(b.point[5],R.points[i].y);eq(b.label.alpha,1) end
    R:Close();for _,b in ipairs(R.buttons) do eq(b.mouse,false) end
    R.root.scripts.OnUpdate(R.root,1);eq(R.root.scripts.OnUpdate,nil)
    for _,b in ipairs(R.buttons) do eq(b:IsShown(),false) end
end)
test('combat interrupts a running radial animation before protected mutations',function()
    local R=F.Radial;R:Animate(true);R.root.scripts.OnUpdate(R.root,.1)
    Mock.combat=true;local n=Mock.mutations;R.root.scripts.OnUpdate(R.root,.1)
    eq(Mock.mutations,n);eq(R.root.scripts.OnUpdate,nil)
    Mock.combat=false;F:Emit('PLAYER_REGEN_ENABLED');eq(R.motionProgress,0)
    F.db.ui.reducedMotion=true;R:Animate(true)
    eq(R.motionProgress,1);eq(R.root.scripts.OnUpdate,nil);eq(R.buttons[1].label.alpha,1)
    R:Close();eq(R.motionProgress,0);eq(R.buttons[1]:IsShown(),false)
end)
local Stats=F.Statistics
local function resetStats()
    Stats:DiscardPending();F.Session.lastActivity=nil;F.Session.lastObservedGUID=nil;F.db.sessionStopped=nil
    F.db.settings.sessionIdleSeconds=300;J.lootTokens={}
    F.Session.current=nil;F.Session.runningSince=nil;F.Session.recordingWindow=nil;F.Session.seen={}
    F.db.history={};F.db.activeSession=nil;F.db.statistics=nil;Stats:Initialize(F.db)
    F.db.settings.trackSessions=true;F.db.settings.autoStartSession=true;F.db.settings.trackCollection=true
    J.ledger={};J.slots={};J.cast=nil;Mock.clock=100;P.statsCurrent=false
end
test('old session totals migrate once without inventing success or timing history',function()
    local db=M.Defaults({history={{started=1,seconds=60,casts=10,catches=4}},activeSession={started=2,seconds=5,casts=2}})
    Stats:Initialize(db);eq(db.statistics.casts,10);eq(db.statistics.catches,4);eq(db.statistics.sessions,1)
    eq(db.statistics.measuredCasts,0);eq(db.statistics.lootSamples,0);eq(next(db.statistics.items),nil);eq(db.statistics.imported,true)
    Stats:Initialize(db);eq(db.statistics.casts,10);eq(db.activeSession.casts,2)
end)
test('recovered stacks and several slots give one success and first-loot timing sample',function()
    resetStats();loot(6291,3);J:Capture();local row=J.slots[1]
    eq(Stats:Snapshot().success,nil);eq(Stats:Snapshot().pending,1);Mock.clock=112;Mock.loot.count=1;J:Changed(1,false)
    Mock.clock=115;J:Changed(1,true);J:Changed(1,true)
    J:Record({id=6289,name='Mud Snapper',zone='Test shore',subzone='',cast=row.cast},2)
    local v=Stats:Snapshot();eq(v.casts,1);eq(v.catches,5);eq(v.successes,1);eq(v.success,100)
    eq(v.average,12);eq(v.lootSamples,1);eq(v.unique,2);eq(v.seconds,15);eq(v.perHour,1200)
end)
test('missed and duplicate casts cannot inflate success rate or timing',function()
    local guid=J.cast.guid;F:Emit('UNIT_SPELLCAST_SUCCEEDED','player',guid,7620)
    eq(Stats:Snapshot().casts,1);eq(Stats:Snapshot().measuredCasts,1)
    loot(6291,1);J:Capture();F:Emit('LOOT_CLOSED')
    Mock.clock=Mock.clock+3;F.sessionTicker.callback()
    local v=Stats:Snapshot();eq(v.casts,2);eq(v.success,50);eq(v.average,12);eq(v.catches,5)
end)
test('pause and new-session boundaries exclude late loot from session rates',function()
    resetStats();loot(6291,1);J:Capture();Mock.clock=105;F.Session:Pause()
    Mock.clock=125;F.Session:Start();Mock.clock=127;J:Changed(1,true)
    eq(Stats:Snapshot().catches,0);eq(Stats:Snapshot().seconds,7);eq(Stats:Snapshot().average,nil)
    loot(6291,1);J:Capture();F.Session:Finish();F.Session:Start();J:Changed(1,true)
    eq(Stats:Snapshot().catches,0);eq(Stats:Snapshot(true).casts,0)
end)
test('disabled tracking does not introduce unmeasured successes',function()
    resetStats();F.db.settings.trackCollection=false;loot(6291,1)
    F.db.settings.trackCollection=true;J:Capture();J:Changed(1,true)
    eq(Stats:Snapshot().casts,1);eq(Stats:Snapshot().measuredCasts,0);eq(Stats:Snapshot().catches,0)
    F.db.settings.trackSessions=false;loot(6291,1);J:Capture();J:Changed(1,true)
    eq(Stats:Snapshot().catches,0);F.db.settings.trackSessions=true
end)
test('lifetime totals survive session history trimming and current totals never double count',function()
    resetStats()
    for i=1,35 do
        F.Session.current={started=Mock.wall,seconds=10,casts=2,catches=3,items={[6291]=true},zones={}}
        F.Session:Finish()
    end
    eq(#F.db.history,30);local v=Stats:Snapshot();eq(v.sessions,35);eq(v.seconds,350);eq(v.casts,70);eq(v.catches,105);eq(v.unique,1)
    F.Session:Start();loot(6289,2);J:Capture();Mock.clock=110;J:Changed(1,true)
    local current=Stats:Snapshot(true);eq(current.sessions,1);eq(current.seconds,10);eq(current.casts,1);eq(current.catches,2)
    v=Stats:Snapshot();eq(v.casts,71);eq(v.catches,107);eq(v.seconds,360);eq(v.unique,2)
    F.Session:Finish();local after=Stats:Snapshot();eq(after.casts,v.casts);eq(after.seconds,v.seconds);eq(after.sessions,v.sessions)
    eq(Stats:Snapshot(true).casts,0);eq(Stats:Snapshot(true).average,nil)
end)
test('reload uses persistent archive plus paused active session without offline time',function()
    resetStats();loot(6291,1);J:Capture();Mock.clock=108;J:Changed(1,true);F:Emit('PLAYER_LOGOUT')
    local db=M.Defaults(F.db);Stats:Initialize(db);F.Session.current=db.activeSession;db.activeSession=nil
    Mock.clock=500;local v=Stats:Snapshot();eq(v.seconds,8);eq(v.casts,1);eq(v.catches,1);eq(v.average,8)
    F.Session:Finish();Stats:Initialize(db);eq(Stats:Snapshot().catches,1);eq(Stats:Snapshot().seconds,8)
end)
test('statistics cards switch scope and show unavailable rates without division by zero',function()
    resetStats();P:RefreshStats();eq(P.stats.cards.success.value:GetText(),'—');eq(P.stats.cards.average.value:GetText(),'—')
    eq(P.stats.cards.perHour.value:GetText(),'—');eq(P.stats.cards.unique.value:GetText(),'0')
    loot(6291,1);J:Capture();Mock.clock=110;J:Changed(1,true);F.Session:Finish()
    Mock.Click(P.stats.current);eq(P.stats.cards.casts.value:GetText(),'0')
    Mock.Click(P.stats.lifetime);eq(P.stats.cards.casts.value:GetText(),'1');eq(P.stats.cards.success.value:GetText(),'100.0%')
    eq(P.stats.cards.average.value:GetText(),'10.0 s');eq(P.stats.cards.perHour.value:GetText(),'360.0')
end)
test('location rows now open journal details without creating URL popups',function()
    P.locationFish=nil;P.locationName='Darnassus';P:RefreshLocations();P:OpenSection('locations')
    local id=P.locations.rows[1].id;Mock.Click(P.locations.rows[1])
    eq(P.discoveryID,id);eq(P.journal:IsShown(),true);eq(P.locations:IsShown(),false);eq(P.Source,nil);eq(P.source,nil)
    for _,frame in ipairs(Mock.frames) do eq(frame.name=='FishcraftSource',false) end
end)
test('one shared workspace owns every section and only the selected section is shown',function()
    for _,key in ipairs({'journal','locations','cooking','stats','settings'}) do
        Mock.Click(P.nav[key]);eq(P.section,key);eq(P.window:IsShown(),true)
        local shown=0
        for name,view in pairs(P.views) do eq(view.parent,P.window);if view:IsShown() then shown=shown+1;eq(name,key) end end
        eq(shown,1);eq(P.nav[key].selected:IsShown(),true)
    end
    eq(#UISpecialFrames,1);eq(UISpecialFrames[1],'FishcraftWindow')
    eq(#F.Radial.buttons,6)
end)
test('cooking to locations to fish details and back preserves navigation context',function()
    P:OpenSection('cooking');P.cooking.target:SetText('210')
    local current=F.db.cooking.current;P:OpenFishLocations(6291);eq(P.section,'locations')
    P.locationName='Darnassus';P:RefreshLocations();local index=P.locationIndex
    Mock.Click(P.locations.rows[1]);eq(P.section,'journal');eq(P.journalTab,'discovery');eq(#P.routes,2)
    Mock.Click(P.back);eq(P.section,'locations');eq(P.locationFish,6291);eq(P.locationIndex,index)
    Mock.Click(P.back);eq(P.section,'cooking');eq(P.cooking.target:GetText(),'210');eq(F.db.cooking.current,current)
    eq(#P.routes,0);eq(P.back:IsShown(),false)
end)
test('discovery search category and paging survive detail and location navigation',function()
    P:OpenSection('journal');P.journalTab='collection';P.journal.collection.search:SetText('Raw')
    P.discoveryCategory=1;P.discoveryState=1;P.page=2;P:RefreshCollection()
    local id=P.journal.collection.rows[1].record.id;Mock.Click(P.journal.collection.rows[1])
    Mock.Click(P.journal.discovery.locations);eq(P.section,'locations')
    P:Back();eq(P.discoveryID,id);eq(P.journalTab,'discovery')
    Mock.Click(P.journal.discovery.back);eq(P.journalTab,'collection');eq(P.page,2);eq(P.journal.collection.search:GetText(),'Raw')
    P.journal.collection.search:SetText('');P.page=1;P:RefreshCollection()
end)
test('session history belongs to Statistics and hides the stat overview',function()
    P:OpenSection('stats');Mock.Click(P.stats.history)
    eq(P.journal.session.parent,P.stats);eq(P.journal.session:IsShown(),true);eq(P.stats.overview:IsShown(),false)
    Mock.Click(P.stats.current);eq(P.journal.session:IsShown(),false);eq(P.stats.overview:IsShown(),true)
end)
test('radial and slash shortcuts navigate the shared window and repeat toggles close it',function()
    P:OpenSection('stats');SlashCmdList.FISHCRAFT('settings');eq(P.section,'settings');eq(P.window:IsShown(),true)
    SlashCmdList.FISHCRAFT('settings');eq(P.window:IsShown(),false)
    SlashCmdList.FISHCRAFT('optimizer');eq(P.window:IsShown(),true);eq(P.settingsTab,'optimizer')
    Mock.Click(F.Radial.buttons[3]);eq(P.section,'locations');eq(P.window:IsShown(),true)
    Mock.Click(P.window.close);eq(P.window:IsShown(),false)
end)
test('pinned tracker updates independently and closing it changes only its preference',function()
    resetStats();P:SetTracker(true);P.window:Hide();eq(P.tracker:IsShown(),true)
    loot(6291,2);J:Capture();Mock.clock=115;J:Changed(1,true)
    P.tracker.scripts.OnUpdate(P.tracker,1);assert(P.tracker.session:GetText():find('00:00:15'));assert(P.tracker.session:GetText():find('2 items'))
    Mock.Click(P.tracker.open);eq(P.section,'stats');eq(P.window:IsShown(),true)
    Mock.Click(P.tracker.close);eq(F.db.ui.tracker,false);eq(P.tracker:IsShown(),false);eq(P.window:IsShown(),true)
    SlashCmdList.FISHCRAFT('tracker');eq(P.tracker:IsShown(),true);eq(F.db.ui.tracker,true)
    for _,check in ipairs(P.checks) do if check.key=='tracker' then eq(check:GetChecked(),true) end end
    P:SetTracker(false)
end)
test('window and tracker placements scale and clamp inside smaller screens',function()
    local w,h=UIParent:GetWidth(),UIParent:GetHeight();local u=F.db.ui
    local wx,wy,tx,ty,scale=u.windowX,u.windowY,u.trackerX,u.trackerY,u.scale
    for _,size in ipairs({{800,600},{1280,720},{1920,1080}}) do
        UIParent:SetSize(size[1],size[2]);u.scale=1.5
        for _,n in ipairs({0,.5,1}) do
            u.windowX,u.windowY,u.trackerX,u.trackerY=n,n,n,n
            for _,v in ipairs({{P.window,'windowX','windowY'},{P.tracker,'trackerX','trackerY'}}) do
                P:Place(unpack(v));local frame=v[1];local s=frame.frameScale
                local x,y=frame.point[4]*s,frame.point[5]*s
                assert(x-frame:GetWidth()*s/2>=7.99 and x+frame:GetWidth()*s/2<=size[1]-7.99)
                assert(y-frame:GetHeight()*s/2>=7.99 and y+frame:GetHeight()*s/2<=size[2]-7.99)
            end
        end
    end
    UIParent:SetSize(w,h);u.windowX,u.windowY,u.trackerX,u.trackerY,u.scale=wx,wy,tx,ty,scale
    P:Place(P.window,'windowX','windowY');P.window.drag.scripts.OnDragStop()
    local remembered=u.windowX;P.window:Hide();P:OpenSection('journal');eq(u.windowX,remembered)
    local db=M.Defaults({ui={windowX=0/0,windowY=2,trackerX=-1,trackerY='bad',tracker='yes'}})
    eq(db.ui.windowX,.5);eq(db.ui.windowY,1);eq(db.ui.trackerX,0);eq(db.ui.trackerY,.65);eq(db.ui.tracker,false)
end)
test('section transitions stop after settling or closing and respect reduced motion',function()
    F.db.ui.reducedMotion=false;P:OpenSection('stats');assert(P.window.scripts.OnUpdate)
    P.window.scripts.OnUpdate(P.window,.2);eq(P.stats.alpha,1);eq(P.window.scripts.OnUpdate,nil)
    P:OpenSection('journal');P.window:Hide();eq(P.window.scripts.OnUpdate,nil);eq(P.journal.alpha,1)
    F.db.ui.reducedMotion=true;P:OpenSection('settings');eq(P.window.scripts.OnUpdate,nil);eq(P.settings.alpha,1)
end)
test('discoveries always put caught items before unseen items in every sort mode',function()
    for sort=1,#D.sorts do
        local unseen=false
        for _,row in ipairs(D:Rows('',nil,1,1,sort)) do
            if row.count==0 then unseen=true else assert(not unseen,'caught item sorted after unseen item') end
        end
    end
    local saved=F.db.collection[13890]
    F.db.collection[13890]={name='Z old catch',count=1,first=0,last=0,zones={}}
    local rows=D:Rows('',nil,1,1,2);local found=false
    for _,row in ipairs(rows) do if row.id==13890 then found=true end;if row.count==0 then assert(found) end end
    F.db.collection[13890]=saved
end)
local cookingAPI,recipeAPI=C_SkillInfo.GetSkillLineInfoByID,C_TradeSkillUI
local cookingRank,cookingCap,recipeKnown=125,150,true
C_SkillInfo.GetSkillLineInfoByID=function(id)
    if id==185 then return {rank=cookingRank,maxRank=cookingCap,modifier=50,tempPoints=25} end
    return cookingAPI(id)
end
C_TradeSkillUI={GetRecipeInfo=function() return {learned=recipeKnown} end}
test('live cooking defaults on and uses base skill with current cap and bag quantities',function()
    eq(M.Defaults({}).cooking.auto,true);eq(M.Defaults({cooking={auto=false}}).cooking.auto,false)
    F.db.cooking={current=1,target=225,buffer=false,active=true,auto=true}
    F.Equipment.items={{id=6308,count=10}};C:Refresh()
    local p=C.plan;eq(p.current,125);eq(p.maximum,150);eq(p.target,225);eq(p.covered,150);eq(p.training,true)
    eq(#p.rows,1);eq(p.rows[1].need,28);eq(p.rows[1].remaining,18)
    assert(C:Advice():find('Cook your 10'));eq(F.db.cooking.target,225)
end)
test('skill ups and crafts without a skill up dynamically recalculate fish deficits',function()
    cookingRank=135;F.Equipment.items={{id=6308,count=3}};C:Refresh()
    eq(C.plan.rows[1].need,17);eq(C.plan.rows[1].remaining,14)
    F.Equipment.items={{id=6308,count=2}};C:Refresh();eq(C.plan.rows[1].remaining,15)
    cookingRank=140;F.Equipment.items={};C:Refresh()
    eq(C.plan.rows[1].need,11);assert(C:Advice():find('about 11 more for Cooking 150'))
end)
test('training cap stops gathering and expanding the cap unlocks the next steps',function()
    cookingRank=150;C:Refresh();eq(#C.plan.rows,0);assert(C:Advice():find('Raise your Cooking cap'))
    cookingCap=225;C:Refresh();eq(#C.plan.rows,2);eq(C.plan.rows[1].need,65);eq(C.plan.rows[2].recipe.fish,8365)
    eq(C.plan.training,false);eq(C.plan.complete,true);eq(F.db.cooking.target,225)
end)
test('focus stays on the current recipe and switches fish only after reaching the next band',function()
    F.Equipment.items={{id=6308,count=65}};C:Refresh();assert(C:Advice():find('Cook your 65'))
    cookingRank=175;C:Refresh();eq(C.plan.rows[1].recipe.fish,8365);eq(C.plan.rows[1].need,55)
    local _,id=C:Advice();eq(id,8365)
    recipeKnown=false;C:Refresh();assert(C:Advice():find('Learn Mithril'))
    recipeKnown=nil;C:Refresh();assert(C:Advice():find('Open Cooking'))
    recipeKnown=true
end)
test('unreadable live skill blocks stale estimates while manual mode remains explicit',function()
    for _,rank in ipairs({0,-1,301,0/0,'unknown',math.huge}) do
        cookingRank=rank;C:Refresh();eq(C.plan.unavailable,true);eq(#C.plan.rows,0)
        assert(C:GoalText():find('Open Cooking'))
    end
    P:RefreshCooking();eq(P.cooking.rows[1]:IsShown(),false);eq(P.cooking.current:GetText(),'')
    F.db.cooking.auto=false;F.db.cooking.current=125;C:Refresh();eq(C.plan.current,125);eq(C.plan.maximum,nil)
    assert(C:PlanNote():find('Manual scenario'))
    cookingRank=180;C:Refresh();eq(C.plan.current,125)
end)
test('completed targets and uncovered skills do not generate misleading fish goals',function()
    F.db.cooking.auto=true;F.db.cooking.target=150;cookingRank=180;cookingCap=225;C:Refresh()
    eq(#C.plan.rows,0);eq(C.plan.complete,true);assert(C:Advice():find('target reached'))
    F.db.cooking.target=300;cookingRank=225;C:Refresh();eq(C.plan.complete,false)
    assert(C:Advice():find('verified fish route ends at Cooking 225'))
    cookingCap=300;cookingRank=250;C:Refresh();eq(#C.plan.rows,0);eq(C.plan.complete,false)
end)
test('live planner refreshes on opening and skill events without changing a draft target',function()
    cookingRank=125;cookingCap=150;F.db.cooking.target=225
    P:OpenSection('cooking');eq(C.plan.current,125);eq(P.cooking.current:GetText(),'125');eq(P.cooking.current.mouse,false)
    P.cooking.target:SetText('200');cookingRank=130;F:Emit('SKILL_LINES_CHANGED');Mock.Flush()
    eq(C.plan.current,130);eq(P.cooking.current:GetText(),'130');eq(P.cooking.target:GetText(),'200');eq(F.db.cooking.target,225)
    P:ApplyCookingInputs();eq(F.db.cooking.target,200);eq(C.plan.current,130)
    Mock.Click(P.cooking.mode);eq(F.db.cooking.auto,false);eq(P.cooking.current.mouse,true)
    P.cooking.current:SetText('120');P:ApplyCookingInputs();eq(C.plan.current,120)
    cookingRank=135;F:Emit('SKILL_LINES_CHANGED');Mock.Flush();eq(C.plan.current,120)
    Mock.Click(P.cooking.mode);eq(C.plan.current,135);eq(F.db.cooking.auto,true)
end)
test('bag and cooking cast events update live estimates and pinned goals',function()
    local old=Mock.bags[8];Mock.bags[8]=Mock.Item(6308,'raw-catfish');Mock.bags[8].count=5
    F.db.cooking.active=true;F:Emit('BAG_UPDATE_DELAYED');Mock.Flush()
    eq(C.plan.rows[1].have,5);assert(P.tracker.goal:GetText():find('Cook your 5'))
    cookingRank=136;Mock.bags[8].count=4;F:Emit('UNIT_SPELLCAST_SUCCEEDED','player','cook-update',7755);Mock.Flush()
    eq(C.plan.current,136);eq(C.plan.rows[1].have,4);eq(C.plan.rows[1].need,16)
    Mock.bags[8]=old
end)
C_SkillInfo.GetSkillLineInfoByID=cookingAPI;C_TradeSkillUI=recipeAPI
local R=F.Radial
test('a new bobber does not temporarily lower an established success rate',function()
    resetStats();loot(6291,1);J:Capture();Mock.clock=110;J:Changed(1,true);F:Emit('LOOT_CLOSED')
    loot(6291,1);P:RefreshStats()
    local v=Stats:Snapshot();eq(v.casts,2);eq(v.resolvedCasts,1);eq(v.pending,1);eq(v.success,100)
    eq(P.stats.cards.success.value:GetText(),'100.0%');assert(P.stats.live:GetText():find('1 pending',1,true))
    J:Capture();Mock.clock=120;J:Changed(1,true)
    v=Stats:Snapshot();eq(v.pending,0);eq(v.resolvedCasts,2);eq(v.success,100)
end)
test('channel end grants loot grace and resolves a genuinely unrecovered cast once',function()
    resetStats();loot(6291,1);Mock.clock=110
    F:Emit('UNIT_SPELLCAST_CHANNEL_STOP','player',J.cast.guid,7620)
    Mock.clock=112;F.sessionTicker.callback();eq(Stats:Snapshot().success,nil)
    Mock.clock=113;F.sessionTicker.callback();eq(Stats:Snapshot().success,0);eq(Stats:Snapshot().pending,0)
    F.sessionTicker.callback();eq(Stats:Snapshot().resolvedCasts,1)
    -- Delayed verified recovery can correct this same outcome without another denominator.
    J:Capture();Mock.clock=115;J:Changed(1,true);J:Changed(1,true)
    eq(Stats:Snapshot().success,100);eq(Stats:Snapshot().resolvedCasts,1);eq(Stats:Snapshot().successes,1)
end)
test('verified open bobber loot stays pending beyond channel grace and the fallback timeout',function()
    resetStats();loot(6291,1);Mock.clock=110
    F:Emit('UNIT_SPELLCAST_CHANNEL_STOP','player',J.cast.guid,7620);J:Capture()
    Mock.clock=145;F.sessionTicker.callback();eq(Stats:Snapshot().pending,1);eq(Stats:Snapshot().success,nil)
    J:Changed(1,true);eq(Stats:Snapshot().success,100)
end)
test('empty recaptures do not lose the open-loot token at close',function()
    resetStats();loot(6291,1);J:Capture();Mock.loot.count=0;J:Capture();F:Emit('LOOT_CLOSED')
    Mock.clock=103;F.sessionTicker.callback();eq(Stats:Snapshot().pending,0);eq(Stats:Snapshot().success,0)
end)
test('recasting resolves the previous attempt after grace and leaves the new attempt pending',function()
    resetStats();loot(6291,1);Mock.clock=110;loot(6291,1)
    eq(Stats:Snapshot().pending,2);eq(Stats:Snapshot().success,nil)
    Mock.clock=113;F.sessionTicker.callback()
    eq(Stats:Snapshot().pending,1);eq(Stats:Snapshot().resolvedCasts,1);eq(Stats:Snapshot().success,0)
end)
test('unrelated cast endings and failed pre-casts cannot finalize a fishing attempt',function()
    resetStats();loot(6291,1)
    F:Emit('UNIT_SPELLCAST_CHANNEL_STOP','target',J.cast.guid,7620)
    F:Emit('UNIT_SPELLCAST_FAILED','player','wrong-guid',7620)
    F:Emit('UNIT_SPELLCAST_INTERRUPTED','player',J.cast.guid,1)
    Mock.clock=105;F.sessionTicker.callback();eq(Stats:Snapshot().pending,1);eq(Stats:Snapshot().resolvedCasts,0)
    F:Emit('UNIT_SPELLCAST_INTERRUPTED','player',J.cast.guid,7620)
    Mock.clock=108;F.sessionTicker.callback();eq(Stats:Snapshot().resolvedCasts,1)
end)
test('missing terminal events fall back to the existing forty-second attribution window',function()
    resetStats();loot(6291,1);Mock.clock=140;F.sessionTicker.callback();eq(Stats:Snapshot().pending,1)
    Mock.clock=141;F.sessionTicker.callback();eq(Stats:Snapshot().success,0);eq(Stats:Snapshot().pending,0)
end)
test('unfinished casts are excluded across manual stop and reload without erasing cast totals',function()
    resetStats();loot(6291,1);Mock.clock=102;F.Session:Stop(true)
    eq(Stats:Snapshot().casts,1);eq(Stats:Snapshot().resolvedCasts,0);eq(Stats:Snapshot().success,nil)
    M.Defaults(F.db);Stats:Initialize(F.db)
    eq(F.db.sessionStopped,nil);eq(Stats:Snapshot().success,nil)
    loot(6291,1);eq(F.Session.current.casts,1);eq(Stats:Snapshot().casts,2);eq(Stats:Snapshot().resolvedCasts,0)
end)
test('previous release denominators migrate once and newly pending casts stay excluded',function()
    local row=Stats:Clean({measuredCasts=4,successes=2})
    eq(row.resolvedCasts,4);row.measuredCasts=5;Stats:Clean(row);eq(row.resolvedCasts,4)
    local db=M.Defaults({statistics={measuredCasts=4,successes=2,sessions=1},activeSession={started=1,measuredCasts=2,successes=1}})
    Stats:Initialize(db);eq(db.statistics.resolvedCasts,4);eq(db.activeSession.resolvedCasts,2)
    Stats:Initialize(db);eq(db.statistics.resolvedCasts,4)
end)
test('session orb toggles recording and Stop allows the next cast to auto-start',function()
    resetStats();R:Refresh();eq(R.buttons[5].label:GetText(),'Start session')
    local section=P.section;Mock.Click(R.buttons[5]);eq(R.buttons[5].label:GetText(),'Stop session');eq(P.section,section)
    loot(6291,1);Mock.clock=110;Mock.Click(R.buttons[5])
    eq(R.buttons[5].label:GetText(),'Start session');eq(F.db.sessionStopped,nil);eq(#F.db.history,1)
    loot(6291,1);eq(F.Session.current.casts,1);eq(R.buttons[5].label:GetText(),'Stop session')
    Mock.Click(R.buttons[5]);eq(F.Session.current,nil);Mock.Click(R.buttons[5]);eq(R.buttons[5].label:GetText(),'Stop session')
    loot(6291,1);eq(F.Session.current.casts,1)
end)
test('idle stop uses last fishing activity and archives at the deadline even with a delayed tick',function()
    resetStats();loot(6291,1);J:Capture();Mock.clock=110;J:Changed(1,true)
    Mock.clock=409;F.sessionTicker.callback();assert(F.Session.runningSince)
    Mock.clock=450;F.sessionTicker.callback();eq(F.Session.current,nil);eq(F.db.sessionStopped,nil)
    eq(#F.db.history,1);eq(F.db.history[1].seconds,310);eq(F.db.history[1].endReason,'idle')
    eq(R.buttons[5].label:GetText(),'Start session')
    Mock.clock=500;loot(6291,1);eq(F.Session.runningSince,500);eq(F.Session.current.casts,1)
end)
test('the first cast after a long timer gap closes the idle session before starting a new one',function()
    resetStats();loot(6291,1);Mock.clock=600;loot(6291,1)
    eq(#F.db.history,1);eq(F.db.history[1].seconds,300);eq(F.Session.current.casts,1);eq(F.Session.runningSince,600)
end)
test('idle auto-stop can be disabled and never saves manually paused sessions',function()
    resetStats();F.db.settings.sessionIdleSeconds=0;loot(6291,1);Mock.clock=1000;F.sessionTicker.callback()
    assert(F.Session.runningSince);eq(#F.db.history,0)
    F.Session:Pause();F.db.settings.sessionIdleSeconds=120;Mock.clock=2000;F.sessionTicker.callback()
    eq(#F.db.history,0);eq(F.Session.runningSince,nil);assert(F.Session.current.manualPaused)
end)
test('idle stop never overrides a disabled automatic start preference',function()
    resetStats();F.db.settings.autoStartSession=false;F.Session:Start();loot(6291,1)
    Mock.clock=401;F.sessionTicker.callback();eq(F.Session.current,nil)
    loot(6291,1);eq(F.Session.current,nil);Mock.Click(R.buttons[5]);assert(F.Session.runningSince)
end)
test('session timeout settings validate and cycle without changing other preferences',function()
    eq(M.Defaults({}).settings.sessionIdleSeconds,300)
    eq(M.Defaults({settings={sessionIdleSeconds=0}}).settings.sessionIdleSeconds,0)
    eq(M.Defaults({settings={sessionIdleSeconds=0/0}}).settings.sessionIdleSeconds,300)
    resetStats();for _,expected in ipairs({600,0,120,300}) do Mock.Click(P.settings.idle);eq(F.db.settings.sessionIdleSeconds,expected) end
    eq(F.db.settings.autoStartSession,true)
end)
test('idle archival in combat avoids protected radial mutations and refreshes after combat',function()
    resetStats();loot(6291,1);Mock.combat=true;Mock.clock=401;F.sessionTicker.callback()
    eq(F.Session.current,nil);eq(#F.db.history,1)
    Mock.combat=false;F:Emit('PLAYER_REGEN_ENABLED');eq(R.buttons[5].label:GetText(),'Start session')
end)
test('disabled session recording leaves the session control harmless',function()
    resetStats();F.db.settings.trackSessions=false;Mock.Click(R.buttons[5]);eq(F.Session.current,nil)
    F.db.settings.trackSessions=true
end)
test('channel-start alone starts the timer and immediately switches the visible session icon',function()
    resetStats();R:Refresh();eq(R.buttons[5].icon.texture,F.Theme.icons.session)
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','channel-only',7620)
    eq(F.Session.runningSince,100);eq(F.Session.current.casts,1);eq(Stats:Snapshot().pending,1)
    eq(R.buttons[5].label:GetText(),'Stop session');eq(R.buttons[5].icon.texture,F.Theme.icons.sessionStop)
    Mock.clock=105;eq(F.Session:Elapsed(),5);eq(Stats:Snapshot().success,nil)
end)
test('channel-start and success in either order share one cast token and preserve its loot slots',function()
    for _,events in ipairs({{'UNIT_SPELLCAST_SUCCEEDED','UNIT_SPELLCAST_CHANNEL_START'},{'UNIT_SPELLCAST_CHANNEL_START','UNIT_SPELLCAST_SUCCEEDED'}}) do
        resetStats();Mock.loot={id=6291,count=1,source='GameObject-0-0-0-0-35591-order'}
        F:Emit(events[1],'player','paired-events',7620);J:Capture()
        local token,slots,at=J.cast,J.slots,J.castAt
        Mock.clock=102;F:Emit(events[2],'player','paired-events',7620)
        eq(J.cast,token);eq(J.slots,slots);eq(J.castAt,at);eq(F.Session.current.casts,1);eq(Stats:Snapshot().measuredCasts,1)
        J:Changed(1,true);eq(Stats:Snapshot().success,100);eq(Stats:Snapshot().catches,1)
    end
end)
test('learned-rank event IDs are recognized even when the spellbook reports another Fishing ID',function()
    resetStats();local original=F.spellID;F.spellID=7620
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','ranked-fishing',7732)
    eq(F.Session.current.casts,1);eq(J.cast.guid,'ranked-fishing');eq(Stats:Snapshot().pending,1)
    F:Emit('UNIT_SPELLCAST_CHANNEL_STOP','player','ranked-fishing',7732)
    Mock.clock=104;F.sessionTicker.callback();eq(Stats:Snapshot().resolvedCasts,1)
    F.spellID=original
end)
test('old persisted Stop flag is retired without changing the explicit auto-start preference',function()
    resetStats();F.db.sessionStopped=true;M.Defaults(F.db)
    eq(F.db.sessionStopped,nil);eq(F.db.settings.autoStartSession,true)
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','after-old-stop',7620)
    eq(R.buttons[5].icon.texture,F.Theme.icons.sessionStop);eq(F.Session.current.casts,1)
    local db=M.Defaults({sessionStopped=true,settings={autoStartSession=false}})
    eq(db.sessionStopped,nil);eq(db.settings.autoStartSession,false)
end)
test('Stop blocks late duplicate events for the same cast but permits the next genuine cast',function()
    resetStats();F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','stop-during-cast',7620)
    Mock.Click(R.buttons[5]);eq(F.Session.current,nil);eq(R.buttons[5].icon.texture,F.Theme.icons.session)
    F:Emit('UNIT_SPELLCAST_SUCCEEDED','player','stop-during-cast',7620)
    eq(F.Session.current,nil);eq(#F.db.history,1)
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','cast-after-stop',7620)
    eq(F.Session.current.casts,1);eq(R.buttons[5].icon.texture,F.Theme.icons.sessionStop)
end)
test('manual Start after Stop does not count a late duplicate from the archived session',function()
    resetStats();F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','old-session-cast',7620)
    F.Session:Stop(true);F.Session:Start()
    F:Emit('UNIT_SPELLCAST_SUCCEEDED','player','old-session-cast',7620)
    eq(F.Session.current.casts,0);eq(Stats:Snapshot(true).measuredCasts,0)
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','new-session-cast',7620);eq(F.Session.current.casts,1)
end)
test('channel events still respect recording off, automatic start off, and an explicit Pause',function()
    resetStats();F.db.settings.autoStartSession=false
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','auto-start-disabled',7620);eq(F.Session.current,nil)
    F.db.settings.autoStartSession=true;F.db.settings.trackSessions=false
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','recording-disabled',7620);eq(F.Session.current,nil)
    F.db.settings.trackSessions=true;F.Session:Start();F.Session:Pause()
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','explicitly-paused',7620)
    eq(F.Session.runningSince,nil);eq(F.Session.current.casts,0);eq(R.buttons[5].icon.texture,F.Theme.icons.session)
end)
test('unrelated channels cannot start a session or change the play icon',function()
    resetStats();R:Refresh()
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','target','not-player',7620)
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','not-fishing',1)
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player',nil,7620)
    eq(F.Session.current,nil);eq(R.buttons[5].icon.texture,F.Theme.icons.session)
end)
test('channel auto-start in combat refreshes the red stop icon after combat safely',function()
    resetStats();R:Refresh();Mock.combat=true
    F:Emit('UNIT_SPELLCAST_CHANNEL_START','player','combat-channel',7620)
    eq(F.Session.current.casts,1)
    Mock.combat=false;F:Emit('PLAYER_REGEN_ENABLED')
    eq(R.buttons[5].icon.texture,F.Theme.icons.sessionStop);eq(R.buttons[5].label:GetText(),'Stop session')
end)
test('location picker searches case-insensitively and selects a zone without changing the main section',function()
    P.locationFish=nil;P.locationName='Stranglethorn Vale';P:OpenSection('locations');Mock.Click(P.locations.chooseZone)
    local list=P.locations.picker;eq(list:IsShown(),true)
    list.search:SetText('  dArNa  ');list.search.scripts.OnTextChanged(list.search)
    eq(list.rows[1].zoneName,'Darnassus');eq(list.rows[2]:IsShown(),false)
    Mock.Click(list.rows[1]);eq(list:IsShown(),false);eq(P.section,'locations');eq(P.locations.zone:GetText(),'Darnassus');eq(P.locationPage,1)
end)
test('location picker exposes all locations through pages and clamps at the last page',function()
    P.locationFish=nil;P:RefreshLocations();P:ToggleZonePicker(true)
    local list=P.locations.picker;local seen={}
    for page=1,math.ceil(#P.locationNames/6) do
        for _,b in ipairs(list.rows) do if b:IsShown() then assert(not seen[b.zoneName]);seen[b.zoneName]=true end end
        Mock.Click(list.next)
    end
    local total=0;for _ in pairs(seen) do total=total+1 end;eq(total,#P.locationNames)
    eq(P.zonePickerPage,math.ceil(total/6))
end)
test('empty and literal-pattern zone searches do not change the selected location',function()
    local selected=P.locations.zone:GetText();local list=P.locations.picker
    for _,q in ipairs({'no-such-location','[.*%'}) do
        list.search:SetText(q);list.search.scripts.OnTextChanged(list.search)
        eq(list.empty:IsShown(),true);eq(list.rows[1].zoneName,nil);eq(list.rows[1]:IsShown(),false)
        list.search.scripts.OnEnterPressed(list.search);eq(P.locations.zone:GetText(),selected)
    end
    list.search:SetText('Darnassus');list.search.scripts.OnTextChanged(list.search)
    eq(P.zonePickerPage,1);list.search.scripts.OnEnterPressed(list.search);eq(list:IsShown(),false)
end)
test('fish-filtered zone picker preserves its scope until All locations is chosen',function()
    P:OpenFishLocations(6291);P:ToggleZonePicker(true)
    local expected=F.Locations:ForFish(6291);eq(#P.locationNames,#expected)
    for i,v in ipairs(expected) do eq(P.locationNames[i],v.name) end
    Mock.Click(P.locations.allZones);eq(P.locationFish,nil);eq(#P.locationNames,#F.Locations:Names());eq(P.locations.picker:IsShown(),true)
end)
test('zone picker dismisses on Escape, section navigation and closing the main window',function()
    local list=P.locations.picker
    list.search.scripts.OnEscapePressed(list.search);eq(list:IsShown(),false);eq(P.window:IsShown(),true)
    P:ToggleZonePicker(true);Mock.Click(P.nav.stats);eq(list:IsShown(),false);eq(P.section,'stats')
    P:OpenSection('locations');P:ToggleZonePicker(true);Mock.Click(P.window.close);eq(list:IsShown(),false)
end)
test('location badges distinguish personal catches in this zone from reference listings',function()
    local saved=F.db.collection[6291]
    F.db.collection[6291]={count=7,zones={Darnassus=2,['Test shore']=5},name='Raw Brilliant Smallfish'}
    P.locationFish=nil;P.locationName='Darnassus';P:RefreshLocations()
    local found=false
    for _,b in ipairs(P.locations.rows) do
        if b:IsShown() then
            assert(b.icon.texture)
            if b.id==6291 then eq(b.confidence:GetText(),'Personally caught · 2');found=true
            elseif not F.db.collection[b.id] or not F.db.collection[b.id].zones.Darnassus then eq(b.confidence:GetText(),'Reference listing') end
        end
    end
    assert(found);F.db.collection[6291]=saved
end)
test('text preference updates body and input fonts without changing UI scale or dial-label footprints',function()
    eq(M.Defaults({}).ui.textSize,1);eq(M.Defaults({ui={textSize=99}}).ui.textSize,1)
    F.db.ui.textSize=1;F.UI.RefreshFonts();local scale=F.db.ui.scale
    local labelSize=R.buttons[1].label.fontSize
    Mock.Click(P.settings.textSize);eq(F.db.ui.textSize,2);eq(P.cooking.current.fontSize,14)
    eq(P.locations.info.fontSize,13);eq(R.buttons[1].label.fontSize,labelSize);eq(F.db.ui.scale,scale)
    M.Defaults(F.db);eq(F.db.ui.textSize,2)
    Mock.combat=true;Mock.Click(P.settings.textSize);eq(F.db.ui.textSize,2);Mock.combat=false
    Mock.Click(P.settings.textSize);eq(F.db.ui.textSize,0);Mock.Click(P.settings.textSize);eq(F.db.ui.textSize,1)
end)
test('active page headings follow navigation and leave the Fishcraft brand subtitle stable',function()
    for key,title in pairs({journal='Discoveries',locations='Fishing locations',cooking='Cooking Planner',stats='Statistics',settings='Settings'}) do
        P:OpenSection(key);eq(P.window.title:GetText(),title);eq(P.window.subtitle:GetText(),'FISHCRAFT')
        for other,b in pairs(P.nav) do eq(b.selected:IsShown(),other==key) end
    end
end)
test('default discovery ordering uses lifetime count descending and stable name ties',function()
    local saved=F.db.collection
    F.db.collection={
        [6291]={name='Z fish',count=100,zones={}},
        [6308]={name='A fish',count=10,zones={}},
        [6289]={name='B fish',count=100,zones={}},
    }
    local rows=D:Rows('')
    eq(rows[1].id,6289);eq(rows[2].id,6291);eq(rows[3].id,6308);eq(rows[4].count,0)
    eq(D:Rows('',nil,1,1,1)[1].id,6308)
    eq(D:Rows('',nil,1,3)[1].count,0)
    F.db.collection=saved
end)

test('catch milestones change exactly at thresholds and stop at gold',function()
    for _,case in ipairs({{0,0,10},{9,0,10},{10,10,100},{99,10,100},{100,100,500},
        {499,100,500},{500,500,1000},{999,500,1000},{1000,1000},{1500,1000}}) do
        local tier,nextTier=D:Milestone(case[1]);eq(tier,case[2]);eq(nextTier,case[3])
    end
end)

test('reused discovery rows restore icon saturation and badge after unseen filtering',function()
    local saved=F.db.collection
    F.db.collection={}
    P.discoveryCategory=1;P.discoveryState=1;P.discoverySort=D.defaultSort;P.currentZoneOnly=false
    P.journal.collection.search:SetText('Brilliant Smallfish');P.page=1;P:RefreshCollection()
    local row=P.journal.collection.rows[1]
    eq(row.record.id,6291);eq(row.icon.desaturated,true);eq(row.badge:IsShown(),false)
    eq(row.name.textColor[1],F.Theme.undiscovered[1])
    for _,count in ipairs({1,10,100,500,1000}) do
        F.db.collection[6291]={name='Raw Brilliant Smallfish',count=count,zones={}}
        P:RefreshCollection();eq(row.icon.desaturated,false);eq(row.icon.vertexColor[1],1)
        eq(row.badge:IsShown(),true);eq(row.count:GetText(),tostring(count))
        local tier=D:Milestone(count)
        for i=1,3 do eq(row.count.textColor[i],F.Theme.catchMilestones[tier][i]) end
        P:OpenDiscovery(6291);eq(P.journal.discovery.badge.text:GetText(),count..' catches')
        P:Back()
    end
    P.journal.collection.search:SetText('Whimsyfin');P:RefreshCollection()
    eq(row.icon.desaturated,true);eq(row.badge:IsShown(),false)
    P:OpenDiscovery(251524);eq(P.journal.discovery.badge:IsShown(),false)
    eq(P.journal.discovery.name.textColor[1],F.Theme.undiscovered[1]);P:Back()
    F.db.collection=saved;P.journal.collection.search:SetText('');P:RefreshCollection()
end)
print(string.format('%d behavioral tests passed',passed))
