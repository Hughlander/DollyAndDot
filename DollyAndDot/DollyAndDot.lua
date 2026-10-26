-------------------------------------------------------------------------------
-- Dolly and Dot
--
-- Standalone port of the "Dolly and Dot" WeakAura (https://wago.io/ihJP5eZK2).
-- Requires the SharedMedia addon (LibSharedMedia-3.0) for the Expressway font.
--
-- What the original WeakAura did (37 child auras, all triggered by the
-- combat-log event SPELL_AURA_APPLIED for "Meerah's Jukebox", spell 288851):
--
--   * 32 text auras, one per lyric word, each anchored BOTTOM -> UIParent CENTER
--     at a fixed x offset, y = 119, font Expressway 36 OUTLINE, left-justified.
--     Each word's "main" animation is a custom colour function that returns
--     (255,165,0,1) once the song reaches that word. WoW clamps colour
--     components to 1.0, so the words actually render YELLOW in game.
--     Words of lines 2-4 return alpha 0 until their line starts.
--     Each line is hidden when its trigger duration elapses
--     (2.8 / 5.45 / 8.28 / 11.5 seconds).
--
--   * 4 invisible text auras ("yell", "yell1".."yell3") whose only purpose is
--     a "finish" action: /yell the line when the aura ends at 0.5 / 3.1 / 5.75
--     / 8.65 s. WeakAuras only sends SAY/YELL while in an instance, which this
--     port keeps.
--
--   * 1 model aura ("d&d1"): a 100x100 PlayerModel showing creature display
--     88594 (alpaca), facing 90 degrees, running (sequence 5, advanced by
--     SetSequenceTime), anchored CENTER -> UIParent CENTER at (-210, 198).
--     Its "start" animation is an 11.5 s custom translate that sweeps the
--     alpaca left-to-right across each line in turn, so the alpaca sits over
--     the word currently being sung. Shown for 11.49 s.
-------------------------------------------------------------------------------

local ADDON_NAME = ...

-- Tunables ------------------------------------------------------------------
local FONT_NAME   = "Expressway"     -- LibSharedMedia font name
local FONT_SIZE   = 36
local FONT_FLAGS  = "OUTLINE"
local LINE_Y      = 119              -- word baseline offset from screen centre
-- The WA returned 255,165,0 (orange) but the client clamps to 1,1,0 (yellow).
-- Set to {1, 0.647, 0} if you want the colour the author meant.
local HIGHLIGHT   = { 1, 1, 0 }
local NORMAL      = { 1, 1, 1 }

local SPELL_ID    = 288851
local SPELL_NAME  = "Meerah's Jukebox"

local MODEL_DISPLAY_ID = 88594       -- alpaca
local MODEL_SEQUENCE   = 5           -- run
local MODEL_FACING     = math.rad(90)
local MODEL_X, MODEL_Y = -210, 198
local MODEL_SIZE       = 100
local MODEL_DURATION   = 11.5        -- translate animation length
local MODEL_HIDE_AT    = 11.49       -- trigger duration of the model aura

local SONG_LENGTH = 11.5

-- Song data (times in seconds from trigger) ----------------------------------
-- Each line: showAt (words become visible, white), hideAt, yellAt + yell text,
-- and words {text, xOffset, highlightAt}.
local LINES = {
  {
    showAt = 0, hideAt = 2.8, yellAt = 0.5,
    yell = "Dolly and Dot are my best friends!",
    words = {
      { "Dolly",    -198.99975585938, 0.5 },
      { "and",      -115.99963378906, 0.9 },
      { "Dot",       -43.999877929688, 1.2 },
      { "are",        21.000183105469, 1.6 },
      { "my",         78.999755859375, 1.9 },
      { "best",      141.00012207031, 2.1 },
      { "friends!",  242.00024414063, 2.5 },
    },
  },
  {
    showAt = 2.8, hideAt = 5.45, yellAt = 3.1,
    yell = "They pull my wagon through dunes of sand!",
    words = {
      { "They",     -296.99993896484, 3.1 },
      { "pull",     -219.99957275391, 3.25 },
      { "my",       -154.99932861328, 3.6 },
      { "wagon",     -69.99951171875, 3.9 },
      { "through",    59,             4.3 },
      { "dunes",     177.00048828125, 4.6 },
      { "of",        252.00061035156, 4.85 },
      { "sand!",     314.00073242188, 5.15 },
    },
  },
  {
    showAt = 5.45, hideAt = 8.28, yellAt = 5.75,
    yell = "They have small teeth and they love to eat!",
    words = {
      { "They",     -302.99987792969, 5.75 },
      { "have",     -218.99945068359, 6.1 },
      { "small",    -126.99926757813, 6.4 },
      { "teeth",     -32.999694824219, 6.55 },
      { "and",        50.000183105469, 6.9 },
      { "they",      126.00073242188, 7.2 },
      { "love",      205.00073242188, 7.4 },
      { "to",        269.00073242188, 7.8 },
      { "eat!",      325.00073242188, 7.9 },
    },
  },
  {
    showAt = 8.28, hideAt = 11.5, yellAt = 8.65,
    yell = "They're the best 'Pacas in all the laaaand!",
    words = {
      { "They're",  -237.00001938677, 8.65 },
      { "the",      -146.00002154242, 8.92 },
      { "best",      -81.999273030373, 9.05 },
      { "'pacas",      5,             9.35 },
      { "in",         76.000116954125, 9.75 },
      { "all",       120.00059092963, 10.10 },
      { "the",       177.00057707892, 10.4 },
      { "laaaand!",  284,             10.65 },
    },
  },
}

-- Alpaca path: verbatim port of the WA start-animation translateFunc.
-- WeakAuras runs "start" animations with inverse progress and the author
-- undid that with realProg = 1 - progress, so realProg == t / 11.5.
local function AlpacaOffset(t)
  local p = t / MODEL_DURATION
  if p < (2.8 / 11.5) then
    return -80 + p * 2300
  elseif p < (5.45 / 11.5) then
    return -90 + (p - 2.87 / 11.5) * 2650
  elseif p < (8.28 / 11.5) then
    return -110 + (p - 5.44 / 11.5) * 2680
  else
    return -75 + (p - 8.27 / 11.5) * 2220
  end
end

-- Frames ---------------------------------------------------------------------
local root = CreateFrame("Frame", "DollyAndDotFrame", UIParent)
root:SetFrameStrata("MEDIUM")
root:SetAllPoints(UIParent)
root:Hide()

local fontPath
do
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    fontPath = LSM:Fetch("font", FONT_NAME, true)
  end
  if not fontPath then
    fontPath = STANDARD_TEXT_FONT
    print("|cffffd200Dolly and Dot:|r SharedMedia font \"" .. FONT_NAME .. "\" not found, falling back to the default font.")
  end
end

local function ApplyFont(fs)
  fs:SetFont(fontPath, FONT_SIZE, FONT_FLAGS)
end

-- Build one FontString per word, positioned exactly like the WA text regions
-- (selfPoint BOTTOM, anchor UIParent CENTER, offset x / 119).
for _, line in ipairs(LINES) do
  for _, w in ipairs(line.words) do
    local fs = root:CreateFontString(nil, "OVERLAY")
    ApplyFont(fs)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    fs:SetNonSpaceWrap(true)
    fs:SetText(w[1])
    fs:SetPoint("BOTTOM", UIParent, "CENTER", w[2], LINE_Y)
    fs:Hide()
    w.fs = fs
  end
end

-- Alpaca
local modelFrame = CreateFrame("Frame", nil, root)
modelFrame:SetSize(MODEL_SIZE, MODEL_SIZE)
modelFrame:SetPoint("CENTER", UIParent, "CENTER", MODEL_X, MODEL_Y)
modelFrame:Hide()

local model = CreateFrame("PlayerModel", nil, modelFrame)
model:SetAllPoints(modelFrame)
model:SetKeepModelOnHide(true)

local function SetupModel()
  pcall(model.SetDisplayInfo, model, MODEL_DISPLAY_ID)
  model:SetPortraitZoom(0)
  model:ClearTransform()
  model:SetPosition(0, 0, 0)
  model:SetFacing(MODEL_FACING)
end

-- Playback -------------------------------------------------------------------
local playing   = false
local startTime = 0
local yelled    = {}

-- Instance types where the client lets an addon /yell without a hardware
-- event. Since 8.2.5 SAY and YELL are hardware-event protected "outside of
-- instances"; in practice scenarios (which includes delves) are treated as
-- outdoors and the yell is silently ADDON_ACTION_BLOCKED, so they are not
-- listed here.
local YELL_INSTANCE_TYPES = { party = true, raid = true, pvp = true, arena = true }

local blockedDuringSend = false

local function GroupChannel()
  if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
    return "INSTANCE_CHAT"
  elseif IsInRaid() then
    return "RAID"
  elseif IsInGroup() then
    return "PARTY"
  end
  return nil
end

local function Yell(msg)
  local inInstance, instanceType = IsInInstance()

  -- 1. Real /yell where the client allows it (same rule the WeakAura used).
  if inInstance and YELL_INSTANCE_TYPES[instanceType] then
    blockedDuringSend = false
    local ok = pcall(SendChatMessage, msg, "YELL")
    if ok and not blockedDuringSend then
      return
    end
  end

  -- 2. Otherwise (open world, scenario/delve, or the yell got blocked) fall
  --    back to the group channel, which has no hardware-event restriction.
  local channel = GroupChannel()
  if channel then
    pcall(SendChatMessage, msg, channel)
  end
end

local function Stop()
  playing = false
  root:SetScript("OnUpdate", nil)
  root:Hide()
  modelFrame:Hide()
  for _, line in ipairs(LINES) do
    for _, w in ipairs(line.words) do w.fs:Hide() end
  end
end

local function Update(t)
  -- Lyrics
  for i, line in ipairs(LINES) do
    local visible = t >= line.showAt and t < line.hideAt
    for _, w in ipairs(line.words) do
      local fs = w.fs
      if visible then
        local c = (t > w[3]) and HIGHLIGHT or NORMAL
        fs:SetTextColor(c[1], c[2], c[3], 1)
        fs:Show()
      else
        fs:Hide()
      end
    end
    if not yelled[i] and t >= line.yellAt then
      yelled[i] = true
      Yell(line.yell)
    end
  end

  -- Alpaca
  if t < MODEL_HIDE_AT then
    modelFrame:SetPoint("CENTER", UIParent, "CENTER", MODEL_X + AlpacaOffset(t), MODEL_Y)
    model:SetSequenceTime(MODEL_SEQUENCE, math.floor(t * 1000))
    modelFrame:Show()
  else
    modelFrame:Hide()
  end
end

local function OnUpdate()
  local t = GetTime() - startTime
  if t >= SONG_LENGTH then
    Stop()
    return
  end
  Update(t)
end

local function Start()
  -- A re-trigger while playing restarts the song from the top.
  Stop()
  playing = true
  startTime = GetTime()
  wipe(yelled)
  SetupModel()
  root:Show()
  Update(0)
  root:SetScript("OnUpdate", OnUpdate)
end

-- Trigger --------------------------------------------------------------------
-- The WeakAura keyed off COMBAT_LOG SPELL_AURA_APPLIED for spell 288851. On
-- current clients that alone is unreliable (combat-log fields can be secret
-- or absent inside instances), so we watch three independent signals and
-- debounce them so one toy use only starts the song once:
--   1. UNIT_SPELLCAST_SUCCEEDED for any unit token (you, party, raid, target,
--      nameplates) casting 288851.
--   2. UNIT_AURA on the player with 288851 / "Meerah's Jukebox" in addedAuras
--      (someone nearby used it and you received the buff).
--   3. COMBAT_LOG_EVENT_UNFILTERED SPELL_CAST_SUCCESS / SPELL_AURA_APPLIED /
--      SPELL_AURA_REFRESH matching the id or name (secret-value safe).

local DEBOUNCE   = 1.0
local lastStart  = -math.huge

local function IsSecret(v)
  return issecretvalue and issecretvalue(v)
end

local function SafeEq(a, b)
  if a == nil or b == nil or IsSecret(a) or IsSecret(b) then return false end
  return a == b
end

local function Matches(spellId, spellName)
  if SafeEq(spellId, SPELL_ID) then return true end
  if type(spellName) == "string" and not IsSecret(spellName) and spellName == SPELL_NAME then
    return true
  end
  return false
end

local function Trigger()
  local now = GetTime()
  if now - lastStart < DEBOUNCE then return end
  lastStart = now
  Start()
end

local events = CreateFrame("Frame")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
events:SetScript("OnEvent", function(_, event, ...)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    local _, _, spellId = ...
    if Matches(spellId, nil) then
      Trigger()
    end

  elseif event == "UNIT_AURA" then
    local _, info = ...
    if not info or info.isFullUpdate or not info.addedAuras then return end
    for _, aura in ipairs(info.addedAuras) do
      if Matches(aura.spellId, aura.name) then
        Trigger()
        return
      end
    end

  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local ok, subevent, spellId, spellName = pcall(function()
      local _, sub, _, _, _, _, _, _, _, _, _, id, name = CombatLogGetCurrentEventInfo()
      return sub, id, name
    end)
    if not ok or IsSecret(subevent) then return end
    if subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
      if Matches(spellId, spellName) then
        Trigger()
      end
    end

  elseif event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" then
    local addon = ...
    if addon == ADDON_NAME then
      blockedDuringSend = true
    end
  end
end)
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:RegisterEvent("ADDON_ACTION_BLOCKED")

-- Slash command for testing --------------------------------------------------
SLASH_DOLLYANDDOT1 = "/dolly"
SLASH_DOLLYANDDOT2 = "/dollyanddot"
SlashCmdList.DOLLYANDDOT = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  if msg == "stop" then
    Stop()
  else
    Start()
  end
end
