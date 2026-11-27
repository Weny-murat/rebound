-- Display-only adapter for the installed Legion ElvUI 10.73 / LAB-ElvUI API.
-- Never changes bindings, action slots, secure attributes or ElvUI's HotKey text.
ReboundSettings=ReboundSettings or {}
if ReboundSettings.showBindingLabels==nil then ReboundSettings.showBindingLabels=true end
ReboundBindingLabels={}
local api=ReboundBindingLabels
local labels={}
local library
local elapsed,discovery=0,0
local function shortKey(key)
  return key:gsub('CTRL%-','C-'):gsub('ALT%-','A-'):gsub('SHIFT%-','S-'):gsub('BUTTON','M'):gsub('NUMPAD','N')
end
local function commands(kind,id)
  if kind=='action' then
    local slot=tonumber(id)
    if not slot then return {} end
    kind,id=GetActionInfo(slot)
  end
  if not id then return {} end
  if kind=='spell' then
    local name=GetSpellInfo(id)
    return name and {'SPELL '..name} or {}
  elseif kind=='item' then
    local name=GetItemInfo(id)
    local itemId=tonumber(id) or (type(id)=='string' and tonumber(id:match('item:(%d+)')))
    local result={}
    if name then result[#result+1]='ITEM '..name end
    if itemId then result[#result+1]='ITEM item:'..itemId end
    return result
  elseif kind=='macro' then
    local index=tonumber(id) or (GetMacroIndexByName and GetMacroIndexByName(id))
    local name=index and index>0 and GetMacroInfo(index)
    return name and {'MACRO '..name} or {}
  end
  -- Do not equate macros with GetMacroSpell: a mouseover macro is a different action.
  return {}
end
local function boundKeys(button)
  local kind,id=button:GetAction()
  local keys,seen={},{}
  for _,command in ipairs(commands(kind,id)) do
    for _,key in ipairs({GetBindingKey(command)}) do
      -- Include active override bindings in the check; never advertise a shadowed key.
      if not seen[key] and GetBindingAction(key,true)==command then
        seen[key]=true; keys[#keys+1]=shortKey(key)
      end
    end
  end
  return table.concat(keys,' / ')
end
function api:Discover()
  if not self:IsEnabled() or InCombatLockdown() then return end
  library=LibStub and LibStub('LibActionButton-1.0-ElvUI',true)
  if not library or type(library.GetAllButtons)~='function' then return end
  local current=library:GetAllButtons()
  for button in pairs(current) do
    if type(button.GetAction)=='function' and not labels[button] then
      local label=button:CreateFontString(nil,'OVERLAY',nil,7)
      label:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',12,'OUTLINE')
      label:SetPoint('TOPLEFT',button,'TOPLEFT',2,-2)
      label:SetTextColor(0.47,0.95,0.82)
      label:SetShadowColor(0,0,0,1); label:SetShadowOffset(1,-1)
      label:Hide(); labels[button]=label
    end
  end
  for button,label in pairs(labels) do
    if not current[button] then label:Hide(); labels[button]=nil end
  end
end
function api:IsEnabled() return ReboundSettings.showBindingLabels==true end
function api:Refresh()
  for button,label in pairs(labels) do
    local text=self:IsEnabled() and button:IsShown() and boundKeys(button) or ''
    if text~='' then label:SetText(text); label:Show() else label:SetText(''); label:Hide() end
  end
end
function api:SetEnabled(enabled)
  ReboundSettings.showBindingLabels=enabled==true
  self:Discover(); self:Refresh()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_LOGIN','ADDON_LOADED','UPDATE_BINDINGS','ACTIONBAR_SLOT_CHANGED','ACTIONBAR_PAGE_CHANGED','UPDATE_MACROS','PLAYER_REGEN_ENABLED','GET_ITEM_INFO_RECEIVED'}) do
  events:RegisterEvent(event)
end
events:SetScript('OnEvent',function() api:Discover(); api:Refresh() end)
events:SetScript('OnUpdate',function(_,delta)
  if not api:IsEnabled() then return end
  elapsed=elapsed+delta; discovery=discovery+delta
  if discovery>=2 then discovery=0; api:Discover() end
  if elapsed>=0.25 then elapsed=0; api:Refresh() end
end)
