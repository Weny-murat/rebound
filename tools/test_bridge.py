"""Run with python tools/test_bridge.py after installing lupa into build/test_deps."""
import pathlib
import sys
ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'build/test_deps'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute('''
buttons = {}; objects = {}; bindings = {W='MOVEFORWARD',UP='MOVEFORWARD',S='MOVEBACKWARD',DOWN='MOVEBACKWARD',A='TURNLEFT',D='TURNRIGHT',Q='STRAFELEFT',E='STRAFERIGHT',R='REPLY'}
local methods = {}
function methods:SetText(text) self.text=text; if self.kind=='Button' then buttons[text]=self end end
function methods:GetText() return self.text or '' end
function methods:SetScript(event,fn) self[event]=fn end
function methods:Disable() self.disabled=true end
function methods:Enable() self.disabled=false end
function methods:CreateFontString() return CreateFrame('Font') end
function methods:IsShown() return false end
setmetatable(methods,{__index=function() return function() end end})
function CreateFrame(kind)
  local obj=setmetatable({kind=kind},{__index=methods})
  objects[#objects+1]=obj
  if kind=='EditBox' then input=obj end
  return obj
end
UIParent={}; ChatFontNormal={}; SlashCmdList={}
function GetBuildInfo() return '7.3.5' end
function InCombatLockdown() return combat or false end
function UnitName() return 'Tester' end
function GetRealmName() return 'TestRealm' end
function GetCurrentBindingSet() return 2 end
function GetBindingAction(key) return bindings[key] or '' end
function GetBindingKey(action)
  local result={}; for key,command in pairs(bindings) do if command==action then result[#result+1]=key end end
  return unpack(result)
end
function GetSpellInfo(id) if id==29722 then return 'Incinerate' end end
function IsPlayerSpell(id) return id==29722 end
function SetBinding(key,command) bindings[key]=command; return true end
function SetBindingSpell(key,name) if failSpell then return false end; bindings[key]='SPELL '..name; return true end
function SaveBindings() saves=(saves or 0)+1 end
function print() end
function click(label) local b=buttons[label]; assert(not rawget(b,'disabled'),'Button is disabled: '..label); b.OnClick() end
''')
lua.execute((ROOT/'addon/ReboundBridge/ReboundBridge.lua').read_text(encoding='utf-8'))
profile = '\n'.join(['REBOUND:2:70305','MOVE:MOVEFORWARD=UP','MOVE:MOVEBACKWARD=NONE','MOVE:TURNLEFT=A','MOVE:TURNRIGHT=D','MOVE:STRAFELEFT=Q','MOVE:STRAFERIGHT=E','29722=S'])
lua.globals().payload = profile
lua.execute('''
input:SetText(payload); click('1. Preview'); click('2. Apply changes')
assert(bindings.S=='SPELL Incinerate'); assert(bindings.UP=='MOVEFORWARD'); assert(bindings.W==nil); assert(bindings.DOWN==nil)
assert(bindings.R=='REPLY')
click('Restore last import')
assert(bindings.S=='MOVEBACKWARD'); assert(bindings.W=='MOVEFORWARD'); assert(bindings.DOWN=='MOVEBACKWARD'); assert(bindings.UP=='MOVEFORWARD')
-- Failed spell application rolls movement and spell keys back together.
input:SetText(payload); click('1. Preview'); failSpell=true; click('2. Apply changes'); failSpell=false
assert(bindings.S=='MOVEBACKWARD'); assert(bindings.W=='MOVEFORWARD'); assert(bindings.DOWN=='MOVEBACKWARD')
-- A new secondary movement key added after preview invalidates the plan.
input:SetText(payload); click('1. Preview'); bindings.T='MOVEFORWARD'; click('2. Apply changes')
assert(bindings.S=='MOVEBACKWARD'); bindings.T=nil
-- In-combat preview is rejected.
combat=true; click('1. Preview'); assert(buttons['2. Apply changes'].disabled); combat=false
-- Duplicate movement/spell key is rejected.
input:SetText(payload:gsub('29722=S','29722=UP')); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
-- Incomplete v2 movement profile is rejected.
input:SetText('REBOUND:2:70305\\n29722=S'); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
-- Legacy spell-only import remains supported.
input:SetText('REBOUND:1:70305\\n29722=S'); click('1. Preview'); click('2. Apply changes')
assert(bindings.S=='SPELL Incinerate'); assert(bindings.DOWN=='MOVEBACKWARD')
input:SetText('REBOUND:1:70305\\n29722=CTRL-SHIFT-R'); click('1. Preview'); click('2. Apply changes')
assert(bindings['CTRL-SHIFT-R']=='SPELL Incinerate')
input:SetText('REBOUND:1:70305\\n29722=CTRL-CTRL-R'); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
''')
print('Lua 5.1 bridge checks passed: remap, clear secondary keys, restore, rollback, stale preview, combat, duplicate/incomplete payload, v1 compatibility.')
lua.execute('''
function GetSpellInfo(id) if id==20707 then return 'Soulstone' end; if id==29722 then return 'Incinerate' end end
function IsPlayerSpell(id) return id==20707 or id==29722 end
function GetMacroIndexByName(name) return macroExists and name=='ReboundSoulstone' and 1 or 0 end
function GetMacroInfo(index) return 'ReboundSoulstone',nil,macroBody end
function SetBindingMacro(key,name) if failMacro then return false end; bindings[key]='MACRO '..name; return true end
macroBody='#showtooltip Soulstone\\n/cast [@mouseover,help,dead][help,dead] Soulstone'
rezPayload=payload:gsub('REBOUND:2','REBOUND:3'):gsub('29722=S','MACRO:20707=SHIFT-E')
-- Missing macro must never silently import a normal spell.
input:SetText(rezPayload); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
macroExists=true
input:SetText(rezPayload); click('1. Preview'); click('2. Apply changes')
assert(bindings['SHIFT-E']=='MACRO ReboundSoulstone')
click('Restore last import'); assert(bindings['SHIFT-E']==nil)
-- Editing macro between preview and apply invalidates it before any mutation.
input:SetText(rezPayload); click('1. Preview'); local correct=macroBody; macroBody='/cast Incinerate'
click('2. Apply changes'); assert(bindings['SHIFT-E']==nil); macroBody=correct
input:SetText(rezPayload); click('1. Preview'); failMacro=true; click('2. Apply changes'); failMacro=false
assert(bindings['SHIFT-E']==nil)
-- Arbitrary macro spell IDs are rejected.
input:SetText(rezPayload:gsub('MACRO:20707','MACRO:29722')); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
''')
print('Combat rez macro checks passed: missing macro, apply, restore, stale macro, rollback, whitelist.')
lua.execute('''
function GetItemInfo(id) if not missingItem and id==5512 then return 'Healthstone' end end
function GetItemCount() return stones or 0 end
function SetBindingItem(key,name) if failItem then return false end; bindings[key]='ITEM '..name; return true end
itemPayload=payload:gsub('REBOUND:2','REBOUND:4')..'\\nITEM:5512=SHIFT-F'
input:SetText(itemPayload); click('1. Preview'); click('2. Apply changes')
assert(bindings['SHIFT-F']=='ITEM Healthstone'); assert(bindings.S=='SPELL Incinerate')
click('Restore last import'); assert(bindings['SHIFT-F']==nil)
-- No cached item data, unknown items and duplicate item keys are rejected.
missingItem=true; input:SetText(itemPayload); click('1. Preview'); assert(buttons['2. Apply changes'].disabled); missingItem=false
input:SetText(itemPayload:gsub('ITEM:5512','ITEM:123')); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
input:SetText(itemPayload..'\\nITEM:5512=SHIFT-R'); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
input:SetText(itemPayload:gsub('ITEM:5512=SHIFT%-F','ITEM:5512=S')); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
input:SetText(itemPayload:gsub('REBOUND:4','REBOUND:2')); click('1. Preview'); assert(buttons['2. Apply changes'].disabled)
-- Item failure rolls back spells and movement too.
local previousS=bindings.S; local previousW=bindings.W
input:SetText(itemPayload); click('1. Preview'); failItem=true; click('2. Apply changes'); failItem=false
assert(bindings['SHIFT-F']==nil); assert(bindings.S==previousS); assert(bindings.W==previousW)
-- Cached data changes invalidate an already previewed import.
input:SetText(itemPayload); click('1. Preview'); missingItem=true; click('2. Apply changes'); missingItem=false
assert(bindings['SHIFT-F']==nil)
-- Macro and item rows coexist in V4.
input:SetText(rezPayload:gsub('REBOUND:3','REBOUND:4')..'\\nITEM:5512=SHIFT-F')
click('1. Preview'); click('2. Apply changes'); assert(bindings['SHIFT-E']=='MACRO ReboundSoulstone'); assert(bindings['SHIFT-F']=='ITEM Healthstone')
click('Restore last import')
local savedCount=saves; local oldS=bindings.S
SlashCmdList.REBOUNDCHECK()
assert(input:GetText():find('REBOUND CLIENT CHECK',1,true)); assert(bindings.S==oldS); assert(saves==savedCount)
assert(buttons['2. Apply changes'].disabled)
''')
print('Item and diagnostic checks passed: V4, cache checks, duplicates, mixed macro/item, rollback, read-only report.')
