local f = CreateFrame('Frame', 'ReboundBridgeFrame', UIParent)
f:SetSize(740, 680); f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG')
f:SetBackdrop({bgFile='Interface/Tooltips/UI-Tooltip-Background', edgeFile='Interface/Tooltips/UI-Tooltip-Border', tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
f:SetBackdropColor(0.06,0.08,0.12,1); f:EnableMouse(true); f:Hide()
local title = f:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
title:SetPoint('TOP',0,-20); title:SetText('Rebound / Control panel')
f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag('LeftButton')
f:SetScript('OnDragStart',function(self) self:StartMoving() end)
f:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
local close = CreateFrame('Button',nil,f,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
local scroll = CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
scroll:SetPoint('TOPLEFT',24,-155); scroll:SetSize(665,345)
local input = CreateFrame('EditBox','ReboundImportText',scroll)
input:SetMultiLine(true); input:SetFontObject(ChatFontNormal); input:SetWidth(660); input:SetAutoFocus(false); input:SetMaxLetters(12000); scroll:SetScrollChild(input)
local outputScroll = CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
outputScroll:SetPoint('TOPLEFT',24,-155); outputScroll:SetSize(665,345); outputScroll:Hide()
local output = CreateFrame('EditBox','ReboundOutputText',outputScroll)
output:SetMultiLine(true); output:SetFontObject(ChatFontNormal); output:SetWidth(660); output:SetAutoFocus(false); output:SetMaxLetters(30000); outputScroll:SetScrollChild(output)
local section = f:CreateFontString(nil,'OVERLAY','GameFontHighlight')
section:SetPoint('TOPLEFT',24,-122); section:SetSize(680,28); section:SetJustifyH('LEFT')
section:SetText('Import: paste the desktop app export here (Ctrl+V), then Preview.')
local status = f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
status:SetPoint('TOPLEFT',24,-520); status:SetSize(690,85); status:SetJustifyH('LEFT'); status:SetJustifyV('TOP')
status:SetText('Paste import text, then preview. Apply overwrites the listed keys in the current account/character binding set. Restore overwrites those keys with the previous values.')
local pending, apply
local labelToggle=CreateFrame('CheckButton','ReboundBindingLabelsToggle',f,'UICheckButtonTemplate')
labelToggle:SetSize(26,26); labelToggle:SetPoint('TOPLEFT',24,-88)
local labelText=labelToggle:CreateFontString(nil,'OVERLAY','GameFontHighlight')
labelText:SetPoint('LEFT',labelToggle,'RIGHT',4,0)
labelText:SetText('Show bindings on ElvUI bars  (cyan: direct key; S=Shift, C=Ctrl, A=Alt, M=mouse)')
labelToggle:SetChecked(ReboundBindingLabels and ReboundBindingLabels:IsEnabled())
labelToggle:SetScript('OnClick',function(self)
  if ReboundBindingLabels then ReboundBindingLabels:SetEnabled(self:GetChecked()) end
end)
local function showOutput(heading,text,selectAll)
  input:ClearFocus(); scroll:Hide(); outputScroll:Show(); outputScroll:SetVerticalScroll(0)
  section:SetText(heading); output:SetText(text)
  if selectAll then output:SetFocus(); output:HighlightText() else output:ClearFocus() end
end
local function showImport()
  pending=nil; if apply then apply:Disable() end
  output:ClearFocus(); outputScroll:Hide(); scroll:Show()
  section:SetText('Import: paste the desktop app export here (Ctrl+V), then Preview.')
  status:SetText('Your draft is preserved while viewing reports/help. Preview shows every change before Apply is enabled.')
  input:SetFocus()
end
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
      if line~='REBOUND:1:70305' and line~='REBOUND:2:70305' and line~='REBOUND:3:70305' and line~='REBOUND:4:70305' then status:SetText('Invalid header.'); return end
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
        local itemId,itemKey=line:match('^ITEM:(%d+)=([A-Z0-9%-]+)$')
        if itemId then
          itemId=tonumber(itemId)
          if version~='REBOUND:4:70305' or itemId~=5512 or not validKey(itemKey) or seen[itemKey] or spells['item:'..itemId] then status:SetText('Invalid or duplicate item/key.'); return end
          local itemName=GetItemInfo(itemId)
          if not itemName then status:SetText('Healthstone item data is not cached. Create or inspect a Healthstone, then preview again.'); return end
          oldKeys[itemKey]=GetBindingAction(itemKey) or ''
          rows[#rows+1]={key=itemKey,itemId=itemId,name=itemName}
          report[#report+1]=itemKey..' -> ITEM '..itemName..' [previous: '..(oldKeys[itemKey]~='' and oldKeys[itemKey] or 'unbound')..']'..(GetItemCount(itemId)==0 and ' [WARNING: none in bags]' or '')
          seen[itemKey],spells['item:'..itemId]=true,true
        else
        local isMacro=line:sub(1,6)=='MACRO:'
        if isMacro and version~='REBOUND:3:70305' and version~='REBOUND:4:70305' then status:SetText('Macro import requires version 3 or 4.'); return end
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
  end
  if version~='REBOUND:1:70305' then
    for action in pairs(movementActions) do if not actions[action] then status:SetText('Incomplete movement profile.'); return end end
  end
  if #rows==0 or #rows>80 then status:SetText('Expected 1 to 80 assignments.'); return end
  pending={rows=rows,keys=oldKeys,set=GetCurrentBindingSet(),owner=owner(),movement=version~='REBOUND:1:70305'}
  for _,line in ipairs(report) do print('Rebound: '..line) end
  showOutput('Preview: review all changes below; nothing has been applied.',table.concat(report,'\n'))
  status:SetText('Preview ready. Apply changes uses the current account/character binding set.\n'..(pending.movement and 'All movement bindings will be replaced, including secondary keys.\n' or '')..'Return to Import text to edit the draft.'); apply:Enable()
end)
apply=button('2. Apply changes',274,function()
  if not ready() or not pending then return end
  if pending.set~=GetCurrentBindingSet() or pending.owner~=owner() then status:SetText('Binding set changed. Preview again.'); return end
  for _,row in ipairs(pending.rows) do
    if row.id and not IsPlayerSpell(row.id) then status:SetText('Spells changed. Preview again.'); return end
    if row.itemId and GetItemInfo(row.itemId)~=row.name then status:SetText('Item data changed. Preview again.'); return end
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
    elseif row.itemId then ok=SetBindingItem(row.key,row.name)
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
button('Restore last import',524,function()
  if not ready() then return end
  if not ReboundBackup or ReboundBackup.owner~=owner() or ReboundBackup.set~=GetCurrentBindingSet() then status:SetText('No backup for this character/binding set.'); return end
  if restore(ReboundBackup) then status:SetText('Previous bindings restored.'); ReboundBackup=nil else status:SetText('Restore failed. Check manually.') end
  pending=nil; apply:Disable()
end)
SLASH_REBOUNDBRIDGE1='/rebound'
SlashCmdList.REBOUNDBRIDGE=function() if f:IsShown() then f:Hide() else f:Show(); showImport() end end
input:SetScript('OnEscapePressed',function(self) self:ClearFocus(); f:Hide() end)
output:SetScript('OnEscapePressed',function(self) self:ClearFocus(); f:Hide() end)
f:SetScript('OnHide',function() input:ClearFocus(); output:ClearFocus(); pending=nil; apply:Disable() end)

-- Read-only evidence collection; never changes bindings or casts abilities.
local function clientReport()
  local version,build=GetBuildInfo()
  local report={'REBOUND CLIENT CHECK','Client: '..tostring(version)..' build '..tostring(build)}
  report[#report+1]='Override API available: '..tostring(type(FindSpellOverrideByID)=='function')
  local spec=GetSpecialization and GetSpecialization()
  if spec and GetSpecializationInfo then report[#report+1]='Spec: '..tostring(GetSpecializationInfo(spec)) end
  if UnitCreatureFamily then report[#report+1]='Pet family: '..tostring(UnitCreatureFamily('pet')) end
  if UnitExists then report[#report+1]='Pet exists: '..tostring(UnitExists('pet')) end
  if GetInventoryItemLink then report[#report+1]='Main hand: '..tostring(GetInventoryItemLink('player',16)) end
  for _,id in ipairs({196586,216698,190778,205223,234153,198590,17877,17962,48018,48020,108503,119898,119910,119905,119907,119909,171140,171152,20707,61999}) do
    local name=GetSpellInfo(id)
    local override=FindSpellOverrideByID and FindSpellOverrideByID(id)
    local known=IsSpellKnown and IsSpellKnown(id)
    local usable,noResource
    if IsUsableSpell then usable,noResource=IsUsableSpell(id) end
    report[#report+1]=id..' '..tostring(name)..' learned='..tostring(IsPlayerSpell(id))..' known='..tostring(known)..' usable='..tostring(usable)..' resourceBlocked='..tostring(noResource)..' override='..tostring(override)
    if GetSpellDescription and (id==17877 or id==108503 or id==48018) then
      report[#report+1]=GetSpellDescription(id) or '(no description)'
    end
  end
  report[#report+1]='Healthstones in bags: '..tostring(GetItemCount(5512))
  report[#report+1]='Read-only report. Import this text nowhere; copy it for review.'
  pending=nil; apply:Disable(); f:Show(); showOutput('Client report: selected for copying (Ctrl+C). Import draft is preserved.',table.concat(report,'\n'),true)
  status:SetText('Client report selected. Ctrl+C to copy. No bindings were changed. Test casts manually using the checklist.')
end

local function menuButton(label,x,action)
  local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate')
  b:SetSize(210,28); b:SetPoint('TOPLEFT',x,-52); b:SetText(label); b:SetScript('OnClick',action)
  return b
end
menuButton('Import text',24,showImport)
menuButton('Client report',264,clientReport)
menuButton('Help / first import',504,function()
  pending=nil; apply:Disable()
  showOutput('Help: one entry command, /rebound.',
    'FIRST IMPORT\n\n1. In the desktop app, match your spec and talents. Disable artifact abilities you have not learned.\n2. Click Export to WoW, then Copy text.\n3. In WoW, type /rebound. Click Import text, click the text area and press Ctrl+V.\n4. Click 1. Preview. Scroll through every assignment and previous binding.\n5. If the preview is correct, click 2. Apply changes.\n6. Test outside combat. Restore last import returns the previous bindings.\n\nHEALTHSTONE\nUse Healthstone is an ITEM action, not Create Healthstone. Have a stone in your bags. The preview shows its exact key.\n\nMOUSEOVER COMBAT REZ\nIf enabled in the app, create the named macro shown there using the game Macros window before previewing. Otherwise turn that option off for your first test.\n\nCLIENT REPORT\nClick Client report, then Ctrl+C. This reads information only. Import text returns to your preserved draft.\n\nApply and Restore are blocked during combat. Imports change the current account/character binding set; account-wide changes affect other characters using that set.')
  status:SetText('Nothing has been changed. Click Import text to begin. The panel can be moved by dragging its background.')
end)
