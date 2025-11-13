local ADDON_NAME = "SecondaryStats"

SecondaryStatsDB = SecondaryStatsDB or {}

local DEFAULT_ORDER   = { "Crit", "Haste", "Mastery", "Vers", "RuneCD", "Move" }
local DEFAULT_VISIBLE = { Crit=true, Haste=true, Mastery=true, Vers=true, RuneCD=true, Move=true }

local statsOrder, visible
local mainFrame, configFrame, ticker

local COLORS = {
  Crit={1.00,0.25,0.25}, Haste={0.25,0.55,1.00}, Mastery={0.25,1.00,0.25},
  Vers={0.60,1.00,0.25}, RuneCD={0.90,0.90,0.90}, Move={1.00,1.00,1.00},
}
local LABEL = { Crit="Crit", Haste="Haste", Mastery="Mastery", Vers="Vers", RuneCD="Rune CD", Move="Move" }

local function tcopy(s) local d={} for k,v in pairs(s) do d[k]=v end return d end
local function SaveOrder()   SecondaryStatsDB.order   = { unpack(statsOrder) } end
local function SaveVisible() SecondaryStatsDB.visible = tcopy(visible) end

-- Main frame position
local function SaveMainPos()
  if not mainFrame then return end
  local p, _, rp, x, y = mainFrame:GetPoint(1)
  SecondaryStatsDB.pos = { p, rp, x, y }
end
local function ApplyMainPos()
  if not mainFrame then return end
  mainFrame:ClearAllPoints()
  if SecondaryStatsDB.pos then
    local v = SecondaryStatsDB.pos
    mainFrame:SetPoint(v[1], UIParent, v[2], v[3], v[4])
  else
    mainFrame:SetPoint("CENTER", 0, 0)
  end
end

-- Config frame position
local function SaveConfigPos()
  if not configFrame then return end
  local p, _, rp, x, y = configFrame:GetPoint(1)
  SecondaryStatsDB.configPos = { p, rp, x, y }
end
local function ApplyConfigPos()
  if not configFrame then return end
  configFrame:ClearAllPoints()
  if SecondaryStatsDB.configPos then
    local c = SecondaryStatsDB.configPos
    configFrame:SetPoint(c[1], UIParent, c[2], c[3], c[4])
  else
    configFrame:SetPoint("CENTER")
  end
end

-- Stat getters
local function GetCritValue()    local v=GetSpellCritChance(2) or 0; return string.format("%s: %.1f%%", LABEL.Crit, v) end
local function GetHasteValue()   local v=GetHaste() or 0;            return string.format("%s: %.1f%%", LABEL.Haste, v) end
local function GetMasteryValue() local v=GetMasteryEffect() or 0;    return string.format("%s: %.1f%%", LABEL.Mastery, v) end
local function GetVersValue()
  local dmg=(GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0) + (GetVersatilityBonus and (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE) or 0) or 0)
  local dt =(GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0) + (GetVersatilityBonus and (GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0) or 0)
  return string.format("%s: %.2f%% / %.2f%%", LABEL.Vers, dmg, dt)
end
local function GetRuneCDValue() local _,d=GetRuneCooldown and GetRuneCooldown(1) or nil; if not d then return string.format("%s: -", LABEL.RuneCD) end; return string.format("%s: %.1f%%", LABEL.RuneCD, d) end
local function GetMoveValue()   local _,run=GetUnitSpeed("player"); local pct=(run or 0)/7*100; return string.format("%s: %.1f%%", LABEL.Move, pct) end

local statFunctions = { Crit=GetCritValue, Haste=GetHasteValue, Mastery=GetMasteryValue, Vers=GetVersValue, RuneCD=GetRuneCDValue, Move=GetMoveValue }

-- Overlay
local function BuildLines()
  if not mainFrame then return end
  if mainFrame.lines then for _,r in ipairs(mainFrame.lines) do if r.fs then r.fs:Hide() end end end
  mainFrame.lines = {}
  local y=-2
  for _, key in ipairs(statsOrder) do
    if visible[key] then
      local fs = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      fs:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
      fs:SetJustifyH("LEFT")
      fs:SetPoint("TOPLEFT", 6, y)
      table.insert(mainFrame.lines, { key=key, fs=fs })
      y = y - 18
    end
  end
end

local function UpdateMainTexts()
  if not mainFrame or not mainFrame.lines then return end
  for _, row in ipairs(mainFrame.lines) do
    local key, fs = row.key, row.fs
    local txt = statFunctions[key] and statFunctions[key]() or ""
    fs:SetText(txt)
    local c = COLORS[key] or {1,1,1}
    fs:SetTextColor(c[1], c[2], c[3])
  end
end

local function StartTicker() if ticker then ticker:Cancel() end; ticker = C_Timer.NewTicker(0.25, UpdateMainTexts) end

local function BuildMainFrameOnce()
  if mainFrame then return end
  mainFrame = CreateFrame("Frame", "SecondaryStatsMainFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
  mainFrame:SetSize(240, 130)
  mainFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
  mainFrame:SetBackdropColor(0,0,0,0.0)
  mainFrame:SetMovable(true)
  mainFrame:EnableMouse(true)
  mainFrame:RegisterForDrag("LeftButton")
  mainFrame:SetScript("OnDragStart", function(self) if not self.locked then self:StartMoving() end end)
  mainFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing(); SaveMainPos() end)

  mainFrame:RegisterEvent("UNIT_STATS")
  mainFrame:RegisterEvent("UNIT_AURA")
  mainFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
  mainFrame:SetScript("OnEvent", function() UpdateMainTexts() end)

  ApplyMainPos()
  BuildLines()
  UpdateMainTexts()
  StartTicker()
end

-- Settings: rows refresh only
local function RefreshConfigRows()
  if not configFrame then return end
  if configFrame.rows then for _,r in ipairs(configFrame.rows) do r:Hide() end end
  configFrame.rows = {}

  local y = -60
  for i, key in ipairs(statsOrder) do
    local row = CreateFrame("Frame", nil, configFrame, BackdropTemplateMixin and "BackdropTemplate")
    row:SetSize(380, 28)
    row:SetPoint("TOP", 0, y)
    row:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 8, edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    row:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local cb = CreateFrame("CheckButton", nil, row, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("LEFT", 6, 0)
    cb:SetChecked(visible[key] and true or false)
    cb:SetScript("OnClick", function(self)
      visible[key] = self:GetChecked() and true or false
      SaveVisible()
      BuildLines(); UpdateMainTexts()
      RefreshConfigRows()
    end)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    label:SetText(LABEL[key] or key)

    local idx = i
    local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    upBtn:SetSize(28, 20); upBtn:SetPoint("RIGHT", -35, 0); upBtn:SetText("UP")
    upBtn:SetScript("OnClick", function()
      if idx > 1 then
        statsOrder[idx], statsOrder[idx-1] = statsOrder[idx-1], statsOrder[idx]
        SaveOrder()
        BuildLines(); UpdateMainTexts()
        RefreshConfigRows()
      end
    end)

    local dnBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    dnBtn:SetSize(28, 20); dnBtn:SetPoint("RIGHT", -3, 0); dnBtn:SetText("DN")
    dnBtn:SetScript("OnClick", function()
      if idx < #statsOrder then
        statsOrder[idx], statsOrder[idx+1] = statsOrder[idx+1], statsOrder[idx]
        SaveOrder()
        BuildLines(); UpdateMainTexts()
        RefreshConfigRows()
      end
    end)

    table.insert(configFrame.rows, row)
    y = y - 32
  end

  if not configFrame.resetBtn then
    local resetBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(100, 22)
    resetBtn:SetPoint("BOTTOMLEFT", 12, 12)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
      statsOrder = { unpack(DEFAULT_ORDER) }
      visible    = tcopy(DEFAULT_VISIBLE)
      SaveOrder(); SaveVisible()
      BuildLines(); UpdateMainTexts()
      RefreshConfigRows()
    end)
    configFrame.resetBtn = resetBtn
  end
end

local function BuildConfigFrameOnce()
  if configFrame then return end
  configFrame = CreateFrame("Frame", "SecondaryStatsConfigFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
  configFrame:SetSize(420, 360)
  configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  configFrame:SetMovable(true)

  local header = CreateFrame("Frame", nil, configFrame)
  header:SetPoint("TOPLEFT", 8, -8)
  header:SetPoint("TOPRIGHT", -28, -8)
  header:SetHeight(24)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function(self) self:GetParent():StartMoving() end)
  header:SetScript("OnDragStop",  function(self) local f=self:GetParent(); f:StopMovingOrSizing(); SaveConfigPos() end)

  local close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -5, -5)

  local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12)
  title:SetText("SecondaryStats - Settings")

  local info = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  info:SetPoint("TOP", title, "BOTTOM", 0, -8)
  info:SetText("Use arrows to reorder stats and checkboxes to show/hide:")

  ApplyConfigPos()
  RefreshConfigRows()
end

-- Slash
SLASH_SECONDARYSTATS1 = "/secondarystats"
SLASH_SECONDARYSTATS2 = "/ss"
SlashCmdList["SECONDARYSTATS"] = function()
  BuildConfigFrameOnce()
  if configFrame:IsShown() then configFrame:Hide() else configFrame:Show() end
end

-- Init
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
  if type(SecondaryStatsDB.order) ~= "table"   then SecondaryStatsDB.order   = { unpack(DEFAULT_ORDER) } end
  if type(SecondaryStatsDB.visible) ~= "table" then SecondaryStatsDB.visible = tcopy(DEFAULT_VISIBLE) end
  statsOrder = SecondaryStatsDB.order
  visible    = SecondaryStatsDB.visible
  BuildMainFrameOnce()
  if not SecondaryStatsDB.initialized then SecondaryStatsDB.initialized=true; SaveMainPos() end
end)
