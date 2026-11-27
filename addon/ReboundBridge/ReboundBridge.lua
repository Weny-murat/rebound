local f = CreateFrame('Frame', 'ReboundBridgeFrame', UIParent)
f:SetSize(640, 540); f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG')
f:SetBackdrop({bgFile='Interface/Tooltips/UI-Tooltip-Background', edgeFile='Interface/Tooltips/UI-Tooltip-Border', tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
f:SetBackdropColor(0.06,0.08,0.12,1); f:EnableMouse(true); f:Hide()
local title = f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
title:SetPoint('TOP',0,-20); title:SetText('Rebound / Legion import (experimental)')
local close = CreateFrame('Button',nil,f,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
local scroll = CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
scroll:SetPoint('TOPLEFT',24,-55); scroll:SetSize(565,210)
local input = CreateFrame('EditBox',nil,scroll)
input:SetMultiLine(true); input:SetFontObject(ChatFontNormal); input:SetWidth(560); input:SetAutoFocus(false); input:SetMaxLetters(12000); scroll:SetScrollChild(input)
local status = f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
status:SetPoint('TOPLEFT',24,-285); status:SetSize(590,170); status:SetJustifyH('LEFT'); status:SetJustifyV('TOP')
status:SetText('Paste import text, then preview. Apply overwrites the listed keys in the current account/character binding set. Restore overwrites those keys with the previous values.')
local pending, apply
local function button(label,x,action)
  local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate')
  b:SetSize(180,28); b:SetPoint('BOTTOMLEFT',x,24); b:SetText(label); b:SetScript('OnClick',action)
  return b
end
local allowed={['1']=true,['2']=true,['3']=true,['4']=true,['5']=true,W=true,A=true,S=true,D=true,UP=true,DOWN=true,LEFT=true,RIGHT=true,Q=true,E=true,R=true,T=true,F=true,G=true,Z=true,X=true,C=true,V=true,B=true,BUTTON4=true,BUTTON5=true}
local movementActions={MOVEFORWARD=true,MOVEBACKWARD=true,TURNLEFT=true,TURNRIGHT=true,STRAFELEFT=true,STRAFERIGHT=true}
local rezMacros={[20707]='ReboundSoulstone',[61999]='ReboundRaiseAlly'}
local function checkedMacro(id,spellName)
  local name=rezMacros[id]
  if not name then return end
  local index=GetMacroIndexByName(name)
  if not index or index==0 then return end
  local _,_,body=GetMacroInfo(index)
  local expected='#showtooltip '..spellName..'\n/cast [@mouseover,help,dead][help,dead] '..spellName
  if not body or body:gsub('\r','')~=expected then return end
  return name
end
local function validKey(key)
  if not key then return false end
  local base=key:gsub('^CTRL%-',''):gsub('^ALT%-',''):gsub('^SHIFT%-','')
  local prefix=''
  if key:find('CTRL%-') then prefix=prefix..'CTRL-' end
  if key:find('ALT%-') then prefix=prefix..'ALT-' end
  if key:find('SHIFT%-') then prefix=prefix..'SHIFT-' end
  return allowed[base] and key==prefix..base
end
local function owner() return UnitName('player')..'-'..GetRealmName() end
local function ready()
  if InCombatLockdown() then status:SetText('Leave combat first.'); return false end
  local version=GetBuildInfo()
  if version~='7.3.5' then status:SetText('Only client 7.3.5 is supported.'); return false end
  return true
end
local function restore(b)
  local ok=true
  for key,command in pairs(b.keys) do
    local result
    if command=='' then result=SetBinding(key) else result=SetBinding(key,command) end
    if not result then ok=false end
  end
  SaveBindings(b.set)
  return ok
end
button('1. Preview',24,function()
  pending=nil; apply:Disable()
  if not ready() then return end
  local rows,seen,spells,report,actions,oldKeys={},{},{},{},{},{}
  local header=false
  local version
  for line in input:GetText():gmatch('[^\r\n]+') do
    if not header then
      if line~='REBOUND:1:70305' and line~='REBOUND:2:70305' and line~='REBOUND:3:70305' then status:SetText('Invalid header.'); return end
      version=line
      header=true
    else
      local action,movementKey=line:match('^MOVE:([A-Z]+)=([A-Z0-9]+)$')
      if action then
        if version=='REBOUND:1:70305' or not movementActions[action] or actions[action] or (movementKey~='NONE' and (not validKey(movementKey) or seen[movementKey])) then status:SetText('Invalid or duplicate movement command.'); return end
        actions[action]=true
        for _,oldKey in ipairs({GetBindingKey(action)}) do
          oldKeys[oldKey]=GetBindingAction(oldKey) or ''
          report[#report+1]='Clear old movement: '..oldKey..' ('..action..')'
        end
        if movementKey~='NONE' then
          oldKeys[movementKey]=GetBindingAction(movementKey) or ''
          rows[#rows+1]={key=movementKey,command=action}
          seen[movementKey]=true
        end
        report[#report+1]=action..' -> '..movementKey
      else
        local isMacro=line:sub(1,6)=='MACRO:'
        if isMacro and version~='REBOUND:3:70305' then status:SetText('Macro import requires version 3.'); return end
        local spellLine=isMacro and line:sub(7) or line
        local id,key=spellLine:match('^(%d+)=([A-Z0-9%-]+)$'); id=tonumber(id)
        if not id or not validKey(key) or seen[key] or spells[id] then status:SetText('Invalid or duplicate spell/key.'); return end
        local name=GetSpellInfo(id)
        if not name or not IsPlayerSpell(id) then status:SetText('Unknown/unlearned spell: '..id..'. Check talents/spec.'); return end
        local macro=isMacro and checkedMacro(id,name) or nil
        if isMacro and not macro then status:SetText('Create the exact combat rez macro from Rebound first: '..(rezMacros[id] or tostring(id))); return end
        local old=GetBindingAction(key) or ''
        oldKeys[key]=old
        rows[#rows+1]={key=key,name=name,id=id,macro=macro}
        report[#report+1]=key..' -> '..(macro and ('MACRO '..macro) or name)..(old~='' and (' [replaces '..old..']') or '')
        seen[key],spells[id]=true,true
      end
    end
  end
  if version~='REBOUND:1:70305' then
    for action in pairs(movementActions) do if not actions[action] then status:SetText('Incomplete movement profile.'); return end end
  end
  if #rows==0 or #rows>80 then status:SetText('Expected 1 to 80 assignments.'); return end
  pending={rows=rows,keys=oldKeys,set=GetCurrentBindingSet(),owner=owner(),movement=version~='REBOUND:1:70305'}
  for _,line in ipairs(report) do print('Rebound: '..line) end
  status:SetText('Full preview printed in chat. Review it before applying.\n'..(pending.movement and 'Movement keys will be replaced, including old secondary movement keys.\n' or '')..table.concat(report,'\n')); apply:Enable()
end)
apply=button('2. Apply changes',224,function()
  if not ready() or not pending then return end
  if pending.set~=GetCurrentBindingSet() or pending.owner~=owner() then status:SetText('Binding set changed. Preview again.'); return end
  for _,row in ipairs(pending.rows) do
    if row.id and not IsPlayerSpell(row.id) then status:SetText('Spells changed. Preview again.'); return end
    if row.macro and checkedMacro(row.id,row.name)~=row.macro then status:SetText('Macro changed. Preview again.'); return end
  end
  for key,old in pairs(pending.keys) do
    if (GetBindingAction(key) or '')~=old then status:SetText('Bindings changed. Preview again.'); return end
  end
  if pending.movement then
    for action in pairs(movementActions) do
      for _,key in ipairs({GetBindingKey(action)}) do
        if pending.keys[key]==nil then status:SetText('Movement changed. Preview again.'); return end
      end
    end
  end
  local backup={keys=pending.keys,set=pending.set,owner=owner()}
  ReboundBackup=backup
  for key in pairs(backup.keys) do
    if not SetBinding(key) then
      local restored=restore(backup)
      status:SetText(restored and 'Could not clear keys. Restored.' or 'Clear and restore failed. Check manually.')
      pending=nil; apply:Disable(); return
    end
  end
  for _,row in ipairs(pending.rows) do
    local ok
    if row.command then ok=SetBinding(row.key,row.command)
    elseif row.macro then ok=SetBindingMacro(row.key,row.macro)
    else ok=SetBindingSpell(row.key,row.name) end
    if not ok then
      local restored=restore(backup)
      status:SetText(restored and 'Import failed. Previous bindings restored.' or 'Import and rollback failed. Check bindings manually.')
      pending=nil; apply:Disable(); return
    end
  end
  SaveBindings(pending.set); status:SetText('Saved. Test spells outside combat. Restore is available.'); pending=nil; apply:Disable()
end)
apply:Disable()
input:SetScript('OnTextChanged',function() pending=nil; apply:Disable() end)
button('Restore last import',424,function()
  if not ready() then return end
  if not ReboundBackup or ReboundBackup.owner~=owner() or ReboundBackup.set~=GetCurrentBindingSet() then status:SetText('No backup for this character/binding set.'); return end
  if restore(ReboundBackup) then status:SetText('Previous bindings restored.'); ReboundBackup=nil else status:SetText('Restore failed. Check manually.') end
  pending=nil; apply:Disable()
end)
SLASH_REBOUNDBRIDGE1='/rebound'
SlashCmdList.REBOUNDBRIDGE=function() if f:IsShown() then f:Hide() else f:Show() end end
