"""Exercise display-only ElvUI labels with Lua 5.1 and mocked Legion APIs."""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'build/test_deps'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute('''
registry = {}; slots = {}; bindings = {}; overrides = {}; combat = false
local methods = {}
function methods:RegisterEvent() end
function methods:SetScript(event, fn) self[event] = fn end
function methods:SetFont() end
function methods:SetPoint() end
function methods:SetTextColor() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetText(text) self.text = text end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:GetAction() return self.kind, self.id end
function methods:CreateFontString(name, layer, template, sublevel)
  assert(layer=='OVERLAY' and template==nil and sublevel==7)
  assert(not combat, 'Font creation in combat')
  self.label = setmetatable({}, {__index=methods}); return self.label
end
function CreateFrame()
  eventFrame = setmetatable({}, {__index=methods}); return eventFrame
end
function newButton(kind, id)
  local b=setmetatable({kind=kind,id=id,shown=true,HotKey={text='native'}}, {__index=methods})
  registry[b]=true; return b
end
function InCombatLockdown() return combat end
function GetActionInfo(slot) if slots[slot] then return unpack(slots[slot]) end end
function GetSpellInfo(id) return ({[29722]='Incinerate',[20707]='Soulstone'})[id] end
function GetItemInfo(id) if not uncached then return 'Healthstone' end end
function GetMacroIndexByName(name) return name=='ReboundSoulstone' and 1 or 0 end
function GetMacroInfo(id) if id==1 and not macroRemoved then return 'ReboundSoulstone' end end
function GetBindingKey(command)
  local result={}; for key,value in pairs(bindings) do
    if value==command then result[#result+1]=key end
  end
  table.sort(result); return unpack(result)
end
function GetBindingAction(key, checkOverride)
  assert(checkOverride); return overrides[key] or bindings[key] or ''
end
function SetBinding() error('Display adapter modified bindings') end
SetBindingSpell=SetBinding; SetBindingItem=SetBinding; SetBindingMacro=SetBinding
SetOverrideBinding=SetBinding; PickupAction=SetBinding; PlaceAction=SetBinding
''')
lua.execute((ROOT / 'addon/ReboundBridge/BindingLabels.lua').read_text(encoding='utf-8'))
lua.execute('''
local api=ReboundBindingLabels
api:Discover(); api:Refresh() -- ElvUI absent is harmless.
function LibStub(name, silent)
  assert(name=='LibActionButton-1.0-ElvUI' and silent)
  return {GetAllButtons=function() return registry end}
end
slots[1]={'spell',29722}; slots[2]={'item',5512}; slots[3]={'macro',1}
spell=newButton('action',1); item=newButton('action',2); macro=newButton('action',3)
plainSoulstone=newButton('spell',20707)
bindings['SHIFT-E']='SPELL Incinerate'; bindings['ALT-F']='ITEM Healthstone'
bindings['CTRL-R']='MACRO ReboundSoulstone'
eventFrame.OnEvent(eventFrame,'PLAYER_LOGIN')
assert(spell.label.text=='S-E' and item.label.text=='A-F' and macro.label.text=='C-R')
assert(not plainSoulstone.label.shown) -- Mouseover macro is not the plain spell.
assert(spell.HotKey.text=='native')
bindings['SHIFT-E']=nil; bindings.Q='SPELL Incinerate'
eventFrame.OnUpdate(eventFrame,0.25); assert(spell.label.text=='Q')
overrides.Q='OTHER'; api:Refresh(); assert(not spell.label.shown)
overrides.Q=nil; api:Refresh(); assert(spell.label.text=='Q')
slots[1]={'spell',20707}; api:Refresh(); assert(not spell.label.shown)
slots[1]={'spell',29722}; spell.shown=false; api:Refresh(); assert(not spell.label.shown)
spell.shown=true; api:Refresh(); assert(spell.label.text=='Q')
api:SetEnabled(false); assert(not spell.label.shown and not ReboundSettings.showBindingLabels)
api:SetEnabled(true); assert(spell.label.shown and ReboundSettings.showBindingLabels)
combat=true; newcomer=newButton('spell',29722); api:Discover(); assert(not newcomer.label)
bindings.Q=nil; bindings['SHIFT-BUTTON4']='SPELL Incinerate'; api:Refresh()
assert(spell.label.text=='S-M4') -- Existing labels update during combat.
combat=false; eventFrame.OnEvent(eventFrame,'PLAYER_REGEN_ENABLED')
assert(newcomer.label.text=='S-M4')
bindings['ALT-F']=nil; bindings.F='ITEM item:5512'; uncached=true
api:Refresh(); assert(item.label.text=='F')
macroRemoved=true; api:Refresh(); assert(not macro.label.shown)
registry[newcomer]=nil; api:Discover(); assert(not newcomer.label.shown)
slots[1]=nil; api:Refresh(); assert(not spell.label.shown)
''')
print('ElvUI binding labels: matching, updates, overrides, combat and toggle passed.')
