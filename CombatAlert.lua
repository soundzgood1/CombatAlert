-- CombatAlert by Soundz
-- Displays customizable text when entering or leaving combat.
-- SavedVariables: CombatAlertDB

CombatAlert = {}

-- ── DB defaults ───────────────────────────────────────────────────────────────
local DB_DEFAULTS = {
    enabled         = true,
    enterEnabled    = true,
    enterText       = "",
    enterColor      = { 1.0, 0.25, 0.25 },
    enterSound      = "None",
    leaveEnabled    = true,
    leaveText       = "",
    leaveColor      = { 0.25, 1.0, 0.25 },
    leaveSound      = "None",
    fontName        = "Friz Quadrata TT",
    fontSize        = 36,
    outlineId       = "thick",
    displayDuration = 2.5,
    animStyle       = "fade",
    posX            = 0,
    posY            = 100,
    locked          = true,
    minimapAngle    = 220,
}

local function SetupDB()
    if not CombatAlertDB then CombatAlertDB = {} end
    for k, v in pairs(DB_DEFAULTS) do
        if type(v) == "table" then
            if CombatAlertDB[k] == nil then
                CombatAlertDB[k] = { v[1], v[2], v[3] }
            end
        elseif CombatAlertDB[k] == nil then
            CombatAlertDB[k] = v
        end
    end
end

-- ── Localized defaults ────────────────────────────────────────────────────────
local LOCALE = GetLocale and GetLocale() or "enUS"

local L_ENTER = {
    enUS = "Entering Combat", enGB = "Entering Combat",
    deDE = "Kampf beginnt",
    frFR = "Combat engagé",
    esES = "Entrando en combate", esMX = "Entrando en combate",
    zhCN = "进入战斗",           zhTW = "進入戰鬥",
    koKR = "전투 시작",
    ruRU = "В бою",
    ptBR = "Entrando em combate", ptPT = "Em combate",
    itIT = "In combattimento",
}
local L_LEAVE = {
    enUS = "Leaving Combat",  enGB = "Leaving Combat",
    deDE = "Kampf beendet",
    frFR = "Combat terminé",
    esES = "Saliendo del combate", esMX = "Saliendo del combate",
    zhCN = "离开战斗",              zhTW = "離開戰鬥",
    koKR = "전투 종료",
    ruRU = "Бой окончен",
    ptBR = "Saindo do combate", ptPT = "Combate terminado",
    itIT = "Combattimento terminato",
}

function CombatAlert.DefaultEnterText() return L_ENTER[LOCALE] or L_ENTER.enUS end
function CombatAlert.DefaultLeaveText() return L_LEAVE[LOCALE] or L_LEAVE.enUS end

-- ── Font system (LibSharedMedia-3.0 aware) ───────────────────────────────────
-- WoW builtins, keyed by the name LSM also uses so lookups are consistent.
CombatAlert.BUILTIN_FONTS = {
    ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"]     = "Fonts\\ARIALN.TTF",
    ["Morpheus"]         = "Fonts\\MORPHEUS.TTF",
    ["Skurri"]           = "Fonts\\skurri.ttf",
}

-- Resolve a font name to a file path.
-- Prefers LSM:HashTable (raw paths, bypasses global font-manager overrides),
-- then falls back to builtins, then the WoW default.
function CombatAlert.ResolveFontPath(name)
    if LibStub then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM and LSM.HashTable then
            local tbl = LSM:HashTable("font")
            if tbl and tbl[name] then return tbl[name] end
        end
    end
    return CombatAlert.BUILTIN_FONTS[name] or "Fonts\\FRIZQT__.TTF"
end

-- Returns a sorted array of font name strings (LSM + builtins merged).
function CombatAlert.GetFontList()
    local seen, list = {}, {}
    if LibStub then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            for _, name in ipairs(LSM:List("font") or {}) do
                if not seen[name] then seen[name] = true; list[#list+1] = name end
            end
        end
    end
    for name in pairs(CombatAlert.BUILTIN_FONTS) do
        if not seen[name] then seen[name] = true; list[#list+1] = name end
    end
    table.sort(list)
    return list
end

-- ── Outline table ─────────────────────────────────────────────────────────────
CombatAlert.ANIM_STYLES = {
    { id = "none",  label = "None"       },
    { id = "fade",  label = "Fade"       },
    { id = "up",    label = "Slide Up"   },
    { id = "down",  label = "Slide Down" },
}

CombatAlert.OUTLINES = {
    { id = "none",    label = "None",          flag = ""             },
    { id = "outline", label = "Outline",       flag = "OUTLINE"      },
    { id = "thick",   label = "Thick Outline", flag = "THICKOUTLINE" },
}
CombatAlert.OutlinesById = {}
for _, o in ipairs(CombatAlert.OUTLINES) do CombatAlert.OutlinesById[o.id] = o end

-- ── Sound options ─────────────────────────────────────────────────────────────
CombatAlert.SOUND_OPTIONS = {
    { label = "None"            , id = nil   },
    { label = "Soft Ping"       , id = 32791 },
    { label = "UI Click"        , id = 1013  },
    { label = "Minimap Ping"    , id = 862   },
    { label = "Invite Chime"    , id = 121   },
    { label = "Whisper"         , id = 5274  },
    { label = "Quest Complete"  , id = 878   },
    { label = "Achievement"     , id = 6134  },
    { label = "Alarm Clock"     , id = 18871 },
    { label = "Ready Check"     , id = 8960  },
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function GetOutlineFlag(id)
    local o = CombatAlert.OutlinesById[id]
    return o and o.flag or "THICKOUTLINE"
end

function CombatAlert.PlayCombatSound(label)
    if not label or label == "None" then return end
    for _, opt in ipairs(CombatAlert.SOUND_OPTIONS) do
        if opt.label == label and opt.id then
            PlaySound(opt.id, "Master")
            return
        end
    end
end

-- ── Display frame ─────────────────────────────────────────────────────────────
local display = CreateFrame("Frame", "CombatAlertDisplayFrame", UIParent)
display:SetSize(320, 52)
display:SetFrameStrata("HIGH")
display:SetFrameLevel(100)
display:SetClampedToScreen(true)
display:SetMovable(true)
display:EnableMouse(false)
display:Hide()

-- Unlock indicator: background + gold border shown when frame is draggable
local unlockBg = display:CreateTexture(nil, "BACKGROUND")
unlockBg:SetAllPoints()
unlockBg:SetColorTexture(0, 0, 0, 0.35)
unlockBg:Hide()

local function MakeDisplayBorderTex(display, r, g, b, a)
    local t = display:CreateTexture(nil, "BORDER")
    t:SetColorTexture(r, g, b, a)
    t:Hide()
    return t
end
local bTop = MakeDisplayBorderTex(display, 1, 0.8, 0.1, 0.7)
bTop:SetPoint("TOPLEFT"); bTop:SetPoint("TOPRIGHT"); bTop:SetHeight(1)
local bBot = MakeDisplayBorderTex(display, 1, 0.8, 0.1, 0.7)
bBot:SetPoint("BOTTOMLEFT"); bBot:SetPoint("BOTTOMRIGHT"); bBot:SetHeight(1)
local bLft = MakeDisplayBorderTex(display, 1, 0.8, 0.1, 0.7)
bLft:SetPoint("TOPLEFT", 0, -1); bLft:SetPoint("BOTTOMLEFT", 0, 1); bLft:SetWidth(1)
local bRgt = MakeDisplayBorderTex(display, 1, 0.8, 0.1, 0.7)
bRgt:SetPoint("TOPRIGHT", 0, -1); bRgt:SetPoint("BOTTOMRIGHT", 0, 1); bRgt:SetWidth(1)

local function SetUnlockVisuals(shown)
    unlockBg:SetShown(shown)
    bTop:SetShown(shown); bBot:SetShown(shown)
    bLft:SetShown(shown); bRgt:SetShown(shown)
end

-- "Drag to reposition" hint shown when unlocked
local dragHint = display:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dragHint:SetPoint("BOTTOM", display, "BOTTOM", 0, 4)
dragHint:SetText("|cffffe066Drag to move  ·  Lock in Settings|r")
dragHint:Hide()
display.dragHint = dragHint

-- Combat text
local combatText = display:CreateFontString(nil, "OVERLAY")
combatText:SetPoint("CENTER", display, "CENTER", 0, 8)
combatText:SetFont("Fonts\\FRIZQT__.TTF", 36, "THICKOUTLINE")
combatText:SetShadowColor(0, 0, 0, 0.85)
combatText:SetShadowOffset(2, -2)
combatText:SetText("")
display.text = combatText

-- Forward-declare ag so agIn's OnFinished closure can reference it as an upvalue.
local ag

-- Phase 1: fade-in (alpha 0→1) with optional directional slide.
-- On finish it resets the anchor and hands off to ag (phase 2).
local agIn = display:CreateAnimationGroup()
local fadeInAnim = agIn:CreateAnimation("Alpha")
fadeInAnim:SetOrder(1); fadeInAnim:SetFromAlpha(0); fadeInAnim:SetToAlpha(1); fadeInAnim:SetDuration(0.3)
local moveInAnim = agIn:CreateAnimation("Translation")
moveInAnim:SetOrder(1); moveInAnim:SetOffset(0, 0); moveInAnim:SetDuration(0.3)
agIn:SetScript("OnFinished", function()
    local db = CombatAlertDB
    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, "CENTER", db and db.posX or 0, db and db.posY or 100)
    display:SetAlpha(1)
    ag:Play()
end)

-- Phase 2: hold then fade-out with optional directional slide.
ag = display:CreateAnimationGroup()
local holdAnim = ag:CreateAnimation("Alpha")
holdAnim:SetOrder(1); holdAnim:SetFromAlpha(1); holdAnim:SetToAlpha(1)
local fadeAnim = ag:CreateAnimation("Alpha")
fadeAnim:SetOrder(2); fadeAnim:SetFromAlpha(1); fadeAnim:SetToAlpha(0); fadeAnim:SetDuration(0.5)
local moveOutAnim = ag:CreateAnimation("Translation")
moveOutAnim:SetOrder(2); moveOutAnim:SetOffset(0, 0); moveOutAnim:SetDuration(0.5)
ag:SetScript("OnFinished", function()
    if CombatAlertDB and CombatAlertDB.locked then display:Hide() end
end)

-- Drag: save position as offset from screen center
display:RegisterForDrag("LeftButton")
display:SetScript("OnDragStart", function(self) self:StartMoving() end)
display:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local left, bottom = self:GetLeft(), self:GetBottom()
    if left and bottom then
        CombatAlertDB.posX = left + self:GetWidth()  / 2 - UIParent:GetWidth()  / 2
        CombatAlertDB.posY = bottom + self:GetHeight() / 2 - UIParent:GetHeight() / 2
    end
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER",
        CombatAlertDB.posX or 0, CombatAlertDB.posY or 100)
end)

CombatAlert.display = display

-- ── Fontmancer-safe SetFont ───────────────────────────────────────────────────
-- Fontmancer hooks FontString.SetFont globally via hooksecurefunc to replace
-- every font with the user's chosen global font.  Setting .IsFontmancerPreview
-- = true on the FontString before the call tells Fontmancer's hook to skip it,
-- so our explicit font choice is preserved.  (Same technique used by PVPHUB.)
function CombatAlert.SafeSetFont(fs, path, size, flags)
    fs.IsFontmancerPreview = true
    local ok, result = pcall(function() return fs:SetFont(path, size, flags) end)
    if not (ok and result) then
        fs:SetFont("Fonts\\FRIZQT__.TTF", size, flags)
    end
end
local SafeSetFont = CombatAlert.SafeSetFont

-- ── Apply current DB font to the display text ─────────────────────────────────
function CombatAlert.RefreshFont()
    if not CombatAlertDB then return end
    local db   = CombatAlertDB
    local path = CombatAlert.ResolveFontPath(db.fontName or "Friz Quadrata TT")
    local size = db.fontSize or 36
    local flag = GetOutlineFlag(db.outlineId)
    SafeSetFont(combatText, path, size, flag)
end

-- ── Lock / unlock display frame ───────────────────────────────────────────────
function CombatAlert.SetLocked(locked)
    CombatAlertDB.locked = locked
    display:EnableMouse(not locked)
    SetUnlockVisuals(not locked)
    dragHint:SetShown(not locked)
    if locked then
        if not agIn:IsPlaying() and not ag:IsPlaying() then display:Hide() end
    else
        if agIn:IsPlaying() then agIn:Stop() end
        if ag:IsPlaying()   then ag:Stop()   end
        CombatAlert.RefreshFont()
        local db   = CombatAlertDB
        local text = (db.enterText ~= "") and db.enterText or CombatAlert.DefaultEnterText()
        local c    = db.enterColor or { 1, 0.25, 0.25 }
        combatText:SetText(text)
        combatText:SetTextColor(c[1], c[2], c[3], 1)
        display:SetAlpha(1)
        display:Show()
    end
end

-- ── Show combat text ──────────────────────────────────────────────────────────
function CombatAlert.ShowText(text, r, g, b)
    CombatAlert.RefreshFont()
    if agIn:IsPlaying() then agIn:Stop() end
    if ag:IsPlaying()   then ag:Stop()   end
    combatText:SetText(text)
    combatText:SetTextColor(r, g, b, 1)

    local db    = CombatAlertDB
    local style = (db and db.animStyle) or "fade"
    local dur   = (db and db.displayDuration) or 2.5
    local posX  = (db and db.posX) or 0
    local posY  = (db and db.posY) or 100

    -- Fade-out slide direction
    if style == "up" then
        moveOutAnim:SetOffset(0, 40)
    elseif style == "down" then
        moveOutAnim:SetOffset(0, -40)
    else
        moveOutAnim:SetOffset(0, 0)
    end

    if style == "none" then
        -- Instant on, hold, instant off
        display:ClearAllPoints()
        display:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
        display:SetAlpha(1); display:Show()
        holdAnim:SetDuration(math.max(0.05, dur))
        ag:Play()
    elseif style == "up" or style == "down" then
        -- Slide in from below ("up") or from above ("down"), then slide out same direction.
        -- Start anchor is offset so the translation animation brings it to posY.
        local dy = (style == "up") and -40 or 40
        display:ClearAllPoints()
        display:SetPoint("CENTER", UIParent, "CENTER", posX, posY + dy)
        moveInAnim:SetOffset(0, -dy)
        holdAnim:SetDuration(math.max(0.05, dur - 0.3 - 0.5))
        display:SetAlpha(0); display:Show()
        agIn:Play()
    else
        -- Fade only: alpha 0→1 with no movement, then hold, then fade out
        display:ClearAllPoints()
        display:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
        moveInAnim:SetOffset(0, 0)
        holdAnim:SetDuration(math.max(0.05, dur - 0.3 - 0.5))
        display:SetAlpha(0); display:Show()
        agIn:Play()
    end
end

-- ── Combat event handler ──────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        SetupDB()
        CombatAlert.RefreshFont()
        display:ClearAllPoints()
        display:SetPoint("CENTER", UIParent, "CENTER",
            CombatAlertDB.posX or 0, CombatAlertDB.posY or 100)
        local locked = CombatAlertDB.locked
        display:EnableMouse(not locked)
        SetUnlockVisuals(not locked)
        dragHint:SetShown(not locked)
        if not locked then
            local c    = CombatAlertDB.enterColor or { 1, 0.25, 0.25 }
            local text = (CombatAlertDB.enterText ~= "") and CombatAlertDB.enterText
                         or CombatAlert.DefaultEnterText()
            combatText:SetText(text)
            combatText:SetTextColor(c[1], c[2], c[3], 1)
            display:SetAlpha(1)
            display:Show()
        end
        CreateCombatAlertMinimapButton()
        self:UnregisterEvent("PLAYER_LOGIN")

    elseif event == "PLAYER_REGEN_DISABLED" then
        if not CombatAlertDB or not CombatAlertDB.enabled then return end
        if not CombatAlertDB.enterEnabled then return end
        local db   = CombatAlertDB
        local text = (db.enterText ~= "") and db.enterText or CombatAlert.DefaultEnterText()
        local c    = db.enterColor or { 1, 0.25, 0.25 }
        CombatAlert.RefreshFont()
        CombatAlert.ShowText(text, c[1], c[2], c[3])
        CombatAlert.PlayCombatSound(db.enterSound)

    elseif event == "PLAYER_REGEN_ENABLED" then
        if not CombatAlertDB or not CombatAlertDB.enabled then return end
        if not CombatAlertDB.leaveEnabled then return end
        local db   = CombatAlertDB
        local text = (db.leaveText ~= "") and db.leaveText or CombatAlert.DefaultLeaveText()
        local c    = db.leaveColor or { 0.25, 1, 0.25 }
        CombatAlert.RefreshFont()
        CombatAlert.ShowText(text, c[1], c[2], c[3])
        CombatAlert.PlayCombatSound(db.leaveSound)
    end
end)

-- ── Minimap button ────────────────────────────────────────────────────────────
local minimapShapes = {
    ["ROUND"]                 = { true,  true,  true,  true  },
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPLEFT"]        = { false, false, false, true  },
    ["CORNER-TOPRIGHT"]       = { false, false, true,  false },
    ["CORNER-BOTTOMLEFT"]     = { false, true,  false, false },
    ["CORNER-BOTTOMRIGHT"]    = { true,  false, false, false },
    ["SIDE-LEFT"]             = { false, true,  false, true  },
    ["SIDE-RIGHT"]            = { true,  false, true,  false },
    ["SIDE-TOP"]              = { false, false, true,  true  },
    ["SIDE-BOTTOM"]           = { true,  true,  false, false },
    ["TRICORNER-TOPLEFT"]     = { false, true,  true,  true  },
    ["TRICORNER-TOPRIGHT"]    = { true,  false, true,  true  },
    ["TRICORNER-BOTTOMLEFT"]  = { true,  true,  false, true  },
    ["TRICORNER-BOTTOMRIGHT"] = { true,  true,  true,  false },
}

local function MinimapButtonPos(btn, deg)
    local rad = math.rad(deg or 0)
    local x, y = math.cos(rad), math.sin(rad)
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local shape     = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadTable = minimapShapes[shape]
    local w = Minimap:GetWidth()  / 2 + 5
    local h = Minimap:GetHeight() / 2 + 5
    if quadTable[q] then
        x, y = x * w, y * h
    else
        local dw = math.sqrt(2 * w ^ 2) - 10
        local dh = math.sqrt(2 * h ^ 2) - 10
        x = math.max(-w, math.min(x * dw, w))
        y = math.max(-h, math.min(y * dh, h))
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function CreateCombatAlertMinimapButton()
    local mb = CreateFrame("Button", "CombatAlertMinimapButton", Minimap)
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFixedFrameStrata(true)
    mb:SetFrameLevel(8)
    mb:SetFixedFrameLevel(true)
    mb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mb:RegisterForDrag("LeftButton")

    local icon = mb:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Ability_DualWield")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")

    local border = mb:CreateTexture(nil, "OVERLAY")
    border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
    border:SetSize(WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and 50 or 53,
                   WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and 50 or 53)
    border:SetPoint("TOPLEFT", 0, 0)
    mb:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])

    mb:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale  = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local pos = math.deg(math.atan2(py - my, px - mx)) % 360
            CombatAlertDB.minimapAngle = pos
            MinimapButtonPos(mb, pos)
        end)
    end)
    mb:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)
    mb:SetScript("OnClick", function(self, btn)
        if btn == "RightButton" then
            CombatAlertDB.enabled = not CombatAlertDB.enabled
            local state = CombatAlertDB.enabled
                and "|cff00ff00Enabled|r" or "|cffff4040Disabled|r"
            print("|cffffe066CombatAlert:|r " .. state)
        else
            CombatAlert.OpenSettings()
        end
    end)
    mb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("CombatAlert", 1, 1, 0)
        GameTooltip:AddLine("|cffaaaaaaLeft-click:|r Open Settings", 1, 1, 1)
        GameTooltip:AddLine("|cffaaaaaaRight-click:|r Toggle on/off", 1, 1, 1)
        GameTooltip:Show()
    end)
    mb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    MinimapButtonPos(mb, CombatAlertDB.minimapAngle or 220)

    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        AddonCompartmentFrame:RegisterAddon({
            text                = "CombatAlert",
            icon                = "Interface\\Icons\\Ability_DualWield",
            registerForAnyClick = true,
            notCheckable        = true,
            func = function(_, _, _, _, buttonName)
                if buttonName == "RightButton" then
                    CombatAlertDB.enabled = not CombatAlertDB.enabled
                    local state = CombatAlertDB.enabled
                        and "|cff00ff00Enabled|r" or "|cffff4040Disabled|r"
                    print("|cffffe066CombatAlert:|r " .. state)
                else
                    CombatAlert.OpenSettings()
                end
            end,
        })
    end
end

-- ── Stub (populated by CombatAlertOptions.lua) ────────────────────────────────
function CombatAlert.OpenSettings() end

-- ── Slash commands ────────────────────────────────────────────────────────────
SLASH_COMBATALERT1 = "/combatalert"
SLASH_COMBATALERT2 = "/calt"
SlashCmdList["COMBATALERT"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if     msg == "on"     then
        CombatAlertDB.enabled = true
        print("|cffffe066CombatAlert:|r |cff00ff00Enabled|r")
    elseif msg == "off"    then
        CombatAlertDB.enabled = false
        print("|cffffe066CombatAlert:|r |cffff4040Disabled|r")
    elseif msg == "toggle" then
        CombatAlertDB.enabled = not CombatAlertDB.enabled
        local state = CombatAlertDB.enabled and "|cff00ff00Enabled|r" or "|cffff4040Disabled|r"
        print("|cffffe066CombatAlert:|r " .. state)
    elseif msg == "unlock" then
        CombatAlert.SetLocked(false)
        print("|cffffe066CombatAlert:|r Frame unlocked — drag to reposition.")
    elseif msg == "lock"   then
        CombatAlert.SetLocked(true)
        print("|cffffe066CombatAlert:|r Frame locked.")
    else
        CombatAlert.OpenSettings()
    end
end
