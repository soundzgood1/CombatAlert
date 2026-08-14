-- CombatAlert by Soundz -- Options UI

-- ── Palette ───────────────────────────────────────────────────────────────────
local GOLD  = { 1.00, 0.45, 0.20, 1.0 }
local BG    = { 0.06, 0.06, 0.09, 0.97 }
local TITLE = { 0.09, 0.09, 0.13, 1.0 }
local BTN   = { 0.15, 0.15, 0.19, 1.0 }
local PRESS = { 0.07, 0.07, 0.10, 1.0 }
local BORD  = { 0.28, 0.28, 0.35, 1.0 }

-- ── Widget helpers ────────────────────────────────────────────────────────────
local function ApplyBorder(f, c)
    c = c or BORD
    local r, g, b, a = c[1], c[2], c[3], c[4] or 1
    local top = f:CreateTexture(nil, "BORDER"); top:SetColorTexture(r, g, b, a)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1)
    local bot = f:CreateTexture(nil, "BORDER"); bot:SetColorTexture(r, g, b, a)
    bot:SetPoint("BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT"); bot:SetHeight(1)
    local lft = f:CreateTexture(nil, "BORDER"); lft:SetColorTexture(r, g, b, a)
    lft:SetPoint("TOPLEFT", 0, -1); lft:SetPoint("BOTTOMLEFT", 0, 1); lft:SetWidth(1)
    local rgt = f:CreateTexture(nil, "BORDER"); rgt:SetColorTexture(r, g, b, a)
    rgt:SetPoint("TOPRIGHT", 0, -1); rgt:SetPoint("BOTTOMRIGHT", 0, 1); rgt:SetWidth(1)
end

local function MakeBtn(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 90, h or 24)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(BTN[1], BTN[2], BTN[3], 1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.11)
    local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetText(text)
    b.label = lbl
    b:SetScript("OnMouseDown", function() bg:SetColorTexture(PRESS[1], PRESS[2], PRESS[3], 1) end)
    b:SetScript("OnMouseUp",   function() bg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    b:SetScript("OnLeave",     function() bg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    ApplyBorder(b)
    return b
end

local function MakeCheckbox(parent)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(22, 22)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cb:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    return cb
end

-- Section header: left gold accent bar + gold text + faded underline
local function SectionLabel(parent, text, y)
    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT",    parent, "TOPLEFT", 20,  y + 1)
    bar:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 20, y - 11)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 27, y)
    lbl:SetText("|cffff7333" .. text .. "|r")
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.22)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y - 16)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y - 16)
end

local function Div(parent, y)
    local d = parent:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.18, 0.18, 0.24, 0.8)
    d:SetHeight(1)
    d:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y)
    d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)
end

-- Subtle vertical separator used between the Color and Sound groups
local function VertSep(parent, x, y1, y2)
    local s = parent:CreateTexture(nil, "ARTWORK")
    s:SetColorTexture(0.22, 0.22, 0.30, 0.9)
    s:SetWidth(1)
    s:SetPoint("TOPLEFT",    parent, "TOPLEFT", x, y1)
    s:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", x, y2)
end

local sliderN = 0
local function MakeSlider(parent, x, y, minV, maxV, step, loTxt, hiTxt)
    sliderN = sliderN + 1
    local name = "CombatAlertSlider" .. sliderN
    local sl = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetWidth(240)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    local lo = _G[name .. "Low"];  if lo then lo:SetText(loTxt or "") end
    local hi = _G[name .. "High"]; if hi then hi:SetText(hiTxt or "") end
    local tx = _G[name .. "Text"]; if tx then tx:SetText("") end
    return sl
end

-- Dropdown with ▼ arrow indicator.
-- onSelect(opt) receives the full option table.
-- getSelectedLabel() → label string of the current selection.
local function MakeCustomDropdown(parent, x, y, width, options, onSelect, getSelectedLabel)
    local rowH = 22
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 26)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(BTN[1], BTN[2], BTN[3], 1)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.09)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("LEFT",  btn, "LEFT",   8,  0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
    lbl:SetJustifyH("LEFT")

    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10); arrow:SetAtlas("auctionhouse-ui-sortarrow")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    arrow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9)

    btn:SetScript("OnMouseDown", function() bg:SetColorTexture(PRESS[1], PRESS[2], PRESS[3], 1) end)
    btn:SetScript("OnMouseUp",   function() bg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    btn:SetScript("OnLeave",     function() bg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    ApplyBorder(btn)

    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(199)
    catcher:Hide()

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(width, #options * rowH)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(200)
    popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    popup:Hide()
    local popBg = popup:CreateTexture(nil, "BACKGROUND")
    popBg:SetAllPoints(); popBg:SetColorTexture(0.09, 0.09, 0.12, 0.98)
    ApplyBorder(popup, BORD)

    local rows = {}
    for i, opt in ipairs(options) do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(width, rowH)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -(i - 1) * rowH)
        local rbg = row:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints(); rbg:SetColorTexture(0, 0, 0, 0)
        local rhl = row:CreateTexture(nil, "HIGHLIGHT")
        rhl:SetAllPoints(); rhl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.12)
        local rtxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rtxt:SetPoint("LEFT", row, "LEFT", 10, 0)
        rtxt:SetJustifyH("LEFT")
        rtxt:SetText(opt.label)
        row.optLabel = opt.label
        row.rbg = rbg
        row:SetScript("OnClick", function()
            lbl:SetText(opt.label)
            popup:Hide(); catcher:Hide()
            onSelect(opt)
        end)
        rows[i] = row
    end

    local function refreshHighlight()
        local cur = getSelectedLabel and getSelectedLabel() or ""
        for _, row in ipairs(rows) do
            if row.optLabel == cur then
                row.rbg:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.20)
            else
                row.rbg:SetColorTexture(0, 0, 0, 0)
            end
        end
    end

    catcher:SetScript("OnMouseDown", function() popup:Hide(); catcher:Hide() end)
    popup:SetScript("OnShow", function() refreshHighlight(); catcher:Show() end)
    popup:SetScript("OnHide", function() catcher:Hide() end)
    btn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else popup:Show() end
    end)

    function btn:SetSelection(label) lbl:SetText(label) end
    return btn
end

-- Scrollable font picker — renders each name in its own typeface, with a
-- hover preview panel and scroll indicators.  Must be called after PLAYER_LOGIN
-- so all LSM registrations (including PVPHUB's bundled fonts) are complete.
local function MakeFontDropdown(parent, x, y, btnWidth)
    local POPUP_W   = 230
    local ROW_H     = 22
    local MAX_H     = 200

    -- ── Button ────────────────────────────────────────────────────────────────
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(btnWidth, 26)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local bbg = btn:CreateTexture(nil, "BACKGROUND"); bbg:SetAllPoints()
    bbg:SetColorTexture(BTN[1], BTN[2], BTN[3], 1)
    local bhl = btn:CreateTexture(nil, "HIGHLIGHT"); bhl:SetAllPoints()
    bhl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.09)
    local blbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    blbl:SetPoint("LEFT",  btn, "LEFT",   8,  0)
    blbl:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
    blbl:SetJustifyH("LEFT")
    local barrow = btn:CreateTexture(nil, "OVERLAY")
    barrow:SetSize(10, 10); barrow:SetAtlas("auctionhouse-ui-sortarrow")
    barrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    barrow:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
    btn:SetScript("OnMouseDown", function() bbg:SetColorTexture(PRESS[1], PRESS[2], PRESS[3], 1) end)
    btn:SetScript("OnMouseUp",   function() bbg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    btn:SetScript("OnLeave",     function() bbg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    ApplyBorder(btn)

    -- ── Click catcher ─────────────────────────────────────────────────────────
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent); catcher:EnableMouse(true)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG"); catcher:SetFrameLevel(199); catcher:Hide()

    -- ── Font list (resolved now — all LSM fonts registered) ───────────────────
    local fontNames = CombatAlert.GetFontList()
    local totalH    = #fontNames * ROW_H
    local popH      = math.min(totalH, MAX_H)
    local needScroll = totalH > MAX_H

    -- ── Popup ─────────────────────────────────────────────────────────────────
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(POPUP_W, popH)
    popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetFrameLevel(200); popup:Hide()
    local popBg = popup:CreateTexture(nil, "BACKGROUND")
    popBg:SetAllPoints(); popBg:SetColorTexture(0.09, 0.09, 0.12, 0.98)
    ApplyBorder(popup, BORD)

    -- ── Scroll frame ──────────────────────────────────────────────────────────
    local rowParent, sf
    if needScroll then
        sf = CreateFrame("ScrollFrame", nil, popup)
        sf:SetPoint("TOPLEFT", 1, -1); sf:SetPoint("BOTTOMRIGHT", -1, 1)
        sf:EnableMouseWheel(true)
        local sc = CreateFrame("Frame", nil, sf)
        sc:SetSize(POPUP_W - 2, totalH); sf:SetScrollChild(sc)
        sf:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll()
            self:SetVerticalScroll(math.max(0, math.min(cur - delta * ROW_H * 3, self:GetVerticalScrollRange())))
        end)
        rowParent = sc

        local C = {0.09, 0.09, 0.12}
        local fadeTop = popup:CreateTexture(nil, "OVERLAY")
        fadeTop:SetPoint("TOPLEFT",  popup, "TOPLEFT",  1, -1)
        fadeTop:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, -1)
        fadeTop:SetHeight(28); fadeTop:SetTexture("Interface\\Buttons\\WHITE8x8")
        fadeTop:SetGradient("VERTICAL", CreateColor(C[1],C[2],C[3],0.92), CreateColor(C[1],C[2],C[3],0))
        fadeTop:Hide()
        local arrowTop = popup:CreateTexture(nil, "OVERLAY")
        arrowTop:SetSize(10, 10); arrowTop:SetAtlas("auctionhouse-ui-sortarrow")
        arrowTop:SetRotation(math.pi); arrowTop:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -6, -6)
        arrowTop:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9); arrowTop:Hide()

        local fadeBot = popup:CreateTexture(nil, "OVERLAY")
        fadeBot:SetPoint("BOTTOMLEFT",  popup, "BOTTOMLEFT",  1, 1)
        fadeBot:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -1, 1)
        fadeBot:SetHeight(28); fadeBot:SetTexture("Interface\\Buttons\\WHITE8x8")
        fadeBot:SetGradient("VERTICAL", CreateColor(C[1],C[2],C[3],0), CreateColor(C[1],C[2],C[3],0.92))
        local arrowBot = popup:CreateTexture(nil, "OVERLAY")
        arrowBot:SetSize(10, 10); arrowBot:SetAtlas("auctionhouse-ui-sortarrow")
        arrowBot:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -6, 6)
        arrowBot:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9)

        local function updateIndicators()
            local cur = sf:GetVerticalScroll(); local max = sf:GetVerticalScrollRange()
            fadeTop:SetShown(cur > 1);  arrowTop:SetShown(cur > 1)
            fadeBot:SetShown(cur < max - 1); arrowBot:SetShown(cur < max - 1)
        end
        sf:SetScript("OnVerticalScroll", updateIndicators)
        popup._sf = sf; popup._updateIndicators = updateIndicators
    else
        rowParent = popup
    end

    -- ── Hover preview panel ───────────────────────────────────────────────────
    local previewFrame = CreateFrame("Frame", nil, UIParent)
    previewFrame:SetSize(200, 52)
    previewFrame:SetFrameStrata("FULLSCREEN_DIALOG"); previewFrame:SetFrameLevel(202); previewFrame:Hide()
    local pvBg = previewFrame:CreateTexture(nil, "BACKGROUND"); pvBg:SetAllPoints()
    pvBg:SetColorTexture(0.05, 0.05, 0.08, 0.97)
    ApplyBorder(previewFrame, {GOLD[1], GOLD[2], GOLD[3], 0.35})
    local pvLbl = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pvLbl:SetPoint("TOP", previewFrame, "TOP", 0, -6); pvLbl:SetTextColor(0.5, 0.5, 0.55); pvLbl:SetText("Preview")
    local pvText = previewFrame:CreateFontString(nil, "OVERLAY")
    pvText:SetPoint("CENTER", previewFrame, "CENTER", 0, -5); pvText:SetTextColor(1, 1, 1)
    CombatAlert.SafeSetFont(pvText, CombatAlert.ResolveFontPath(CombatAlertDB and CombatAlertDB.fontName or "Friz Quadrata TT"), 18, "")
    pvText:SetText("AaBbCc 123")

    -- ── Rows ──────────────────────────────────────────────────────────────────
    local rows = {}
    for i, name in ipairs(fontNames) do
        local row = CreateFrame("Button", nil, rowParent)
        row:SetSize(POPUP_W - 2, ROW_H)
        row:SetPoint("TOPLEFT", rowParent, "TOPLEFT", 0, -(i - 1) * ROW_H)
        local rbg = row:CreateTexture(nil, "BACKGROUND"); rbg:SetAllPoints(); rbg:SetColorTexture(0, 0, 0, 0)
        local rhl = row:CreateTexture(nil, "HIGHLIGHT"); rhl:SetAllPoints()
        rhl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.12)
        local rtxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rtxt:SetPoint("LEFT", row, "LEFT", 8, 0); rtxt:SetJustifyH("LEFT"); rtxt:SetText(name)
        CombatAlert.SafeSetFont(rtxt, CombatAlert.ResolveFontPath(name), 12, "")
        row.fontName = name; row.rbg = rbg; rows[i] = row

        row:SetScript("OnClick", function()
            blbl:SetText(name)
            for _, r in ipairs(rows) do r.rbg:SetColorTexture(0, 0, 0, 0) end
            rbg:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.20)
            popup:Hide(); catcher:Hide()
            CombatAlertDB.fontName = name
            CombatAlert.RefreshFont()
        end)
        row:SetScript("OnEnter", function()
            CombatAlert.SafeSetFont(pvText, CombatAlert.ResolveFontPath(name), 18, "")
            previewFrame:ClearAllPoints()
            previewFrame:SetPoint("LEFT", popup, "RIGHT", 6, 0)
            previewFrame:Show()
        end)
        row:SetScript("OnLeave", function() previewFrame:Hide() end)
    end

    -- ── Open/close logic ──────────────────────────────────────────────────────
    local function refreshHighlight()
        local cur = CombatAlertDB and CombatAlertDB.fontName or "Friz Quadrata TT"
        for _, r in ipairs(rows) do
            local sel = r.fontName == cur
            r.rbg:SetColorTexture(sel and GOLD[1] or 0, sel and GOLD[2] or 0, sel and GOLD[3] or 0, sel and 0.20 or 0)
        end
        if sf then
            local selIdx = 0
            for i, n in ipairs(fontNames) do if n == cur then selIdx = i; break end end
            local centred = (selIdx - 1) * ROW_H - (popH / 2) + (ROW_H / 2)
            sf:SetVerticalScroll(math.max(0, math.min(centred, sf:GetVerticalScrollRange())))
        end
    end

    catcher:SetScript("OnMouseDown", function() popup:Hide(); catcher:Hide() end)
    popup:SetScript("OnShow", function()
        refreshHighlight()
        if popup._updateIndicators then popup._updateIndicators() end
        catcher:Show()
    end)
    popup:SetScript("OnHide", function() catcher:Hide(); previewFrame:Hide() end)
    btn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else popup:Show() end
    end)

    function btn:SetSelection(name) blbl:SetText(name) end
    return btn
end

-- Inline text editbox — returns container frame with .editBox inside.
local function MakeEditBox(parent, x, y, width, placeholder, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 28)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local cbg = container:CreateTexture(nil, "BACKGROUND")
    cbg:SetAllPoints(); cbg:SetColorTexture(BTN[1], BTN[2], BTN[3], 1)
    ApplyBorder(container, BORD)

    local box = CreateFrame("EditBox", nil, container)
    box:SetSize(width - 12, 24)
    box:SetPoint("LEFT", container, "LEFT", 6, 0)
    box:SetAutoFocus(false)
    box:SetMaxLetters(128)
    box:SetFontObject(GameFontHighlightSmall)

    local hint = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("LEFT", container, "LEFT", 7, 0)
    hint:SetTextColor(0.30, 0.30, 0.38, 1)
    hint:SetText(placeholder or "")
    hint:SetJustifyH("LEFT")

    box:SetScript("OnTextChanged", function(self)
        local t = self:GetText()
        hint:SetShown(t == "")
        if onChange then onChange(t) end
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)

    container.editBox = box
    return container
end

-- Color swatch button (caller positions it).
local function MakeColorSwatch(parent, getColor, onColorChanged)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(24, 24)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local swBg = btn:CreateTexture(nil, "BACKGROUND")
    swBg:SetAllPoints(); swBg:SetColorTexture(0.08, 0.08, 0.08, 1)
    local swTex = btn:CreateTexture(nil, "ARTWORK")
    swTex:SetPoint("TOPLEFT",     btn, "TOPLEFT",      2, -2)
    swTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2,  2)
    swTex:SetColorTexture(1, 1, 1, 1)
    ApplyBorder(btn, BORD)

    local function refresh()
        local c = getColor()
        swTex:SetColorTexture(c[1], c[2], c[3], 1)
    end

    btn:SetScript("OnClick", function()
        local c = getColor()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = c[1], g = c[2], b = c[3],
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                onColorChanged(nr, ng, nb)
                refresh()
            end,
            cancelFunc = function(prev)
                onColorChanged(prev.r, prev.g, prev.b)
                refresh()
            end,
        })
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to choose a color", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn.refresh = refresh
    return btn
end

-- ── Main settings window ──────────────────────────────────────────────────────
local win

local function BuildWindow()
    -- Layout plan (Y = distance from window top, negative):
    --  -50  Enable checkbox
    --  -80  Div
    --  -92  ENTER COMBAT section
    -- -116  [✓] Show on enter               [Preview Enter]
    -- -144  editbox
    -- -182  Color [■] [Reset] | Sound [dd]
    -- -212  Div
    -- -224  LEAVE COMBAT section
    -- -248  [✓] Show on leave               [Preview Leave]
    -- -276  editbox
    -- -314  Color [■] [Reset] | Sound [dd]
    -- -344  Div
    -- -356  APPEARANCE section
    -- -380  Font [dd]         Outline [dd]
    -- -418  Size XX     [slider]  [Default]
    -- -470  Duration XXs [slider] [Default]
    -- -508  Div
    -- -520  POSITION section
    -- -544  [✓] Lock position
    -- -570  hint text
    -- -588  Div
    -- -600  [Restore All Defaults]   credits text
    -- Window height: 638

    win = CreateFrame("Frame", "CombatAlertMainFrame", UIParent)
    win:SetSize(460, 750)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self) self:StartMoving() end)
    win:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    win:Hide()
    table.insert(UISpecialFrames, "CombatAlertMainFrame")

    local winBg = win:CreateTexture(nil, "BACKGROUND", nil, -1)
    winBg:SetAllPoints(); winBg:SetColorTexture(BG[1], BG[2], BG[3], BG[4])
    ApplyBorder(win, BORD)

    local accentTop = win:CreateTexture(nil, "BORDER", nil, 1)
    accentTop:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
    accentTop:SetHeight(3)
    accentTop:SetPoint("TOPLEFT"); accentTop:SetPoint("TOPRIGHT")

    local titleBg = win:CreateTexture(nil, "BACKGROUND", nil, 0)
    titleBg:SetColorTexture(TITLE[1], TITLE[2], TITLE[3], 1)
    titleBg:SetHeight(38)
    titleBg:SetPoint("TOPLEFT"); titleBg:SetPoint("TOPRIGHT")

    local titleSep = win:CreateTexture(nil, "ARTWORK")
    titleSep:SetColorTexture(0.22, 0.22, 0.30, 1)
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  win, "TOPLEFT",  0, -38)
    titleSep:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, -38)

    local titleIcon = win:CreateTexture(nil, "OVERLAY")
    titleIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", win, "TOPLEFT", 14, -21)

    local titleText = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    titleText:SetText("|cffff7333CombatAlert|r  |cff444455-- by Soundz|r")

    local closeBtn = CreateFrame("Button", nil, win)
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -6, -6)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1)
    closeX:SetText("X")
    closeBtn:SetScript("OnEnter", function() closeX:SetTextColor(1, 0.95, 0.65, 1) end)
    closeBtn:SetScript("OnLeave", function() closeX:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1) end)
    closeBtn:SetScript("OnClick", function() win:Hide() end)

    -- ─────────────────────────────────────────────────────────────────────────
    -- Content
    -- ─────────────────────────────────────────────────────────────────────────

    -- ── Enable ────────────────────────────────────────────────────────────────
    local cbEnable = MakeCheckbox(win)
    cbEnable:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -50)
    cbEnable:SetScript("OnClick", function(self)
        CombatAlertDB.enabled = self:GetChecked() and true or false
    end)
    local cbEnableLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbEnableLbl:SetPoint("LEFT", cbEnable, "RIGHT", 6, 0)
    cbEnableLbl:SetText("Enable CombatAlert")

    Div(win, -80)

    -- ── ENTER COMBAT ──────────────────────────────────────────────────────────
    SectionLabel(win, "ENTER COMBAT", -92)

    -- "Show on enter" checkbox + Preview Enter button on same row
    local cbEnterOn = MakeCheckbox(win)
    cbEnterOn:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -116)
    cbEnterOn:SetScript("OnClick", function(self)
        CombatAlertDB.enterEnabled = self:GetChecked() and true or false
    end)
    local cbEnterLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbEnterLbl:SetPoint("LEFT", cbEnterOn, "RIGHT", 6, 0)
    cbEnterLbl:SetText("Show on enter")

    local previewEnter = MakeBtn(win, "Preview", 112, 22)
    previewEnter:SetPoint("TOPRIGHT", win, "TOPRIGHT", -20, -117)
    do
        local ico = previewEnter:CreateTexture(nil, "ARTWORK")
        ico:SetSize(14, 14)
        ico:SetPoint("LEFT", previewEnter, "LEFT", 8, 0)
        ico:SetTexture("Interface\\Icons\\Spell_Holy_MindVision")
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        previewEnter.label:ClearAllPoints()
        previewEnter.label:SetPoint("LEFT",  previewEnter, "LEFT",  26, 0)
        previewEnter.label:SetPoint("RIGHT", previewEnter, "RIGHT", -6, 0)
        previewEnter.label:SetJustifyH("LEFT")
    end
    previewEnter:SetScript("OnClick", function()
        if not CombatAlertDB then return end
        local db   = CombatAlertDB
        local text = (db.enterText ~= "") and db.enterText or CombatAlert.DefaultEnterText()
        local c    = db.enterColor or {1, 0.25, 0.25}
        CombatAlert.ShowText(text, c[1], c[2], c[3])
        CombatAlert.PlayCombatSound(db.enterSound)
    end)

    local enterTextBox = MakeEditBox(win, 20, -144, 420,
        "Default: " .. CombatAlert.DefaultEnterText(),
        function(t)
            CombatAlertDB.enterText = t
            -- Feed live edits to the display frame while it's unlocked
            if CombatAlertDB and not CombatAlertDB.locked and CombatAlert.display:IsShown() then
                local c = CombatAlertDB.enterColor or {1, 0.25, 0.25}
                CombatAlert.display.text:SetText((t ~= "") and t or CombatAlert.DefaultEnterText())
                CombatAlert.display.text:SetTextColor(c[1], c[2], c[3], 1)
            end
        end)

    -- Color group
    local enterColorLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enterColorLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -182)
    enterColorLbl:SetText("|cff888888Color|r")

    local enterSwatch = MakeColorSwatch(win,
        function() return CombatAlertDB.enterColor or {1, 0.25, 0.25} end,
        function(r, g, b) CombatAlertDB.enterColor = {r, g, b} end)
    enterSwatch:SetPoint("LEFT", enterColorLbl, "RIGHT", 8, 0)

    local enterColorReset = MakeBtn(win, "Reset", 54, 22)
    enterColorReset:SetPoint("LEFT", enterSwatch, "RIGHT", 6, 0)
    enterColorReset:SetScript("OnClick", function()
        CombatAlertDB.enterColor = {1.0, 0.25, 0.25}
        enterSwatch.refresh()
    end)

    VertSep(win, 158, -176, -200)

    -- Sound group
    local enterSoundLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enterSoundLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 168, -182)
    enterSoundLbl:SetText("|cff888888Sound|r")

    local enterSoundDD = MakeCustomDropdown(win, 210, -178, 210,
        CombatAlert.SOUND_OPTIONS,
        function(opt) CombatAlertDB.enterSound = opt.label end,
        function() return CombatAlertDB.enterSound or "None" end)

    Div(win, -212)

    -- ── LEAVE COMBAT ──────────────────────────────────────────────────────────
    SectionLabel(win, "LEAVE COMBAT", -224)

    -- "Show on leave" checkbox + Preview Leave button on same row
    local cbLeaveOn = MakeCheckbox(win)
    cbLeaveOn:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -248)
    cbLeaveOn:SetScript("OnClick", function(self)
        CombatAlertDB.leaveEnabled = self:GetChecked() and true or false
    end)
    local cbLeaveLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbLeaveLbl:SetPoint("LEFT", cbLeaveOn, "RIGHT", 6, 0)
    cbLeaveLbl:SetText("Show on leave")

    local previewLeave = MakeBtn(win, "Preview", 112, 22)
    previewLeave:SetPoint("TOPRIGHT", win, "TOPRIGHT", -20, -249)
    do
        local ico = previewLeave:CreateTexture(nil, "ARTWORK")
        ico:SetSize(14, 14)
        ico:SetPoint("LEFT", previewLeave, "LEFT", 8, 0)
        ico:SetTexture("Interface\\Icons\\Spell_Holy_MindVision")
        ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        previewLeave.label:ClearAllPoints()
        previewLeave.label:SetPoint("LEFT",  previewLeave, "LEFT",  26, 0)
        previewLeave.label:SetPoint("RIGHT", previewLeave, "RIGHT", -6, 0)
        previewLeave.label:SetJustifyH("LEFT")
    end
    previewLeave:SetScript("OnClick", function()
        if not CombatAlertDB then return end
        local db   = CombatAlertDB
        local text = (db.leaveText ~= "") and db.leaveText or CombatAlert.DefaultLeaveText()
        local c    = db.leaveColor or {0.25, 1, 0.25}
        CombatAlert.ShowText(text, c[1], c[2], c[3])
        CombatAlert.PlayCombatSound(db.leaveSound)
    end)

    local leaveTextBox = MakeEditBox(win, 20, -276, 420,
        "Default: " .. CombatAlert.DefaultLeaveText(),
        function(t) CombatAlertDB.leaveText = t end)

    -- Color group
    local leaveColorLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leaveColorLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -314)
    leaveColorLbl:SetText("|cff888888Color|r")

    local leaveSwatch = MakeColorSwatch(win,
        function() return CombatAlertDB.leaveColor or {0.25, 1, 0.25} end,
        function(r, g, b) CombatAlertDB.leaveColor = {r, g, b} end)
    leaveSwatch:SetPoint("LEFT", leaveColorLbl, "RIGHT", 8, 0)

    local leaveColorReset = MakeBtn(win, "Reset", 54, 22)
    leaveColorReset:SetPoint("LEFT", leaveSwatch, "RIGHT", 6, 0)
    leaveColorReset:SetScript("OnClick", function()
        CombatAlertDB.leaveColor = {0.25, 1.0, 0.25}
        leaveSwatch.refresh()
    end)

    VertSep(win, 158, -308, -332)

    -- Sound group
    local leaveSoundLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leaveSoundLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 168, -314)
    leaveSoundLbl:SetText("|cff888888Sound|r")

    local leaveSoundDD = MakeCustomDropdown(win, 210, -310, 210,
        CombatAlert.SOUND_OPTIONS,
        function(opt) CombatAlertDB.leaveSound = opt.label end,
        function() return CombatAlertDB.leaveSound or "None" end)

    Div(win, -344)

    -- ── APPEARANCE ────────────────────────────────────────────────────────────
    SectionLabel(win, "APPEARANCE", -356)

    -- Font + Outline: equal-width dropdowns on same row
    -- Font list built from LSM + builtins at window-creation time (PLAYER_LOGIN
    -- guarantees LSM is fully loaded before BuildWindow runs).
    local fontLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -380)
    fontLbl:SetText("|cff888888Font|r")

    local fontDD = MakeFontDropdown(win, 20, -376, 200)
    fontDD:SetSelection(CombatAlertDB and CombatAlertDB.fontName or "Friz Quadrata TT")

    local outlineLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    outlineLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 230, -380)
    outlineLbl:SetText("|cff888888Outline|r")

    local outlineDD = MakeCustomDropdown(win, 276, -376, 164,
        CombatAlert.OUTLINES,
        function(opt)
            CombatAlertDB.outlineId = opt.id
            CombatAlert.RefreshFont()
        end,
        function()
            local o = CombatAlert.OutlinesById[CombatAlertDB.outlineId or "thick"]
            return o and o.label or "Thick Outline"
        end)

    Div(win, -406)

    -- ── ANIMATION ─────────────────────────────────────────────────────────────
    SectionLabel(win, "ANIMATION", -418)

    local animStyleOpts = {}
    for _, s in ipairs(CombatAlert.ANIM_STYLES) do
        animStyleOpts[#animStyleOpts+1] = { label = s.label, id = s.id }
    end
    local animDD = MakeCustomDropdown(win, 20, -438, 160,
        animStyleOpts,
        function(opt) CombatAlertDB.animStyle = opt.id end,
        function()
            local cur = CombatAlertDB and CombatAlertDB.animStyle or "fade"
            for _, s in ipairs(CombatAlert.ANIM_STYLES) do
                if s.id == cur then return s.label end
            end
            return "Fade"
        end)

    Div(win, -476)

    -- ── DISPLAY ───────────────────────────────────────────────────────────────
    SectionLabel(win, "DISPLAY", -488)

    -- Size slider
    local sizeLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -512)
    sizeLbl:SetText("|cff888888Size|r")
    local sizeVal = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sizeVal:SetPoint("LEFT", sizeLbl, "RIGHT", 8, 0)

    local sizeSlider = MakeSlider(win, 20, -528, 12, 72, 1,
        "|cff555566small|r", "|cff555566large|r")
    sizeSlider:SetScript("OnValueChanged", function(self, val)
        CombatAlertDB.fontSize = math.floor(val + 0.5)
        sizeVal:SetText(string.format("|cffff7333%dpt|r", CombatAlertDB.fontSize))
        CombatAlert.RefreshFont()
    end)
    local sizeDef = MakeBtn(win, "Default", 72, 22)
    sizeDef:SetPoint("LEFT", sizeSlider, "RIGHT", 8, 0)
    sizeDef:SetScript("OnClick", function()
        CombatAlertDB.fontSize = 36
        sizeSlider:SetValue(36)
        CombatAlert.RefreshFont()
    end)

    -- Duration slider
    local durLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    durLbl:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -564)
    durLbl:SetText("|cff888888Duration|r")
    local durVal = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    durVal:SetPoint("LEFT", durLbl, "RIGHT", 8, 0)

    local durSlider = MakeSlider(win, 20, -580, 0.5, 10.0, 0.5,
        "|cff555566short|r", "|cff555566long|r")
    durSlider:SetScript("OnValueChanged", function(self, val)
        CombatAlertDB.displayDuration = val
        durVal:SetText(string.format("|cffff7333%.1fs|r", val))
    end)
    local durDef = MakeBtn(win, "Default", 72, 22)
    durDef:SetPoint("LEFT", durSlider, "RIGHT", 8, 0)
    durDef:SetScript("OnClick", function()
        CombatAlertDB.displayDuration = 2.5
        durSlider:SetValue(2.5)
    end)

    Div(win, -614)

    -- ── POSITION ──────────────────────────────────────────────────────────────
    SectionLabel(win, "POSITION", -626)

    local lockCb = MakeCheckbox(win)
    lockCb:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -650)
    lockCb:SetScript("OnClick", function(self)
        CombatAlert.SetLocked(self:GetChecked() and true or false)
    end)
    local lockCbLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lockCbLbl:SetPoint("LEFT", lockCb, "RIGHT", 6, 0)
    lockCbLbl:SetText("Lock position")

    local posHint = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    posHint:SetPoint("TOPLEFT", win, "TOPLEFT", 48, -672)
    posHint:SetText("|cff555566Uncheck to drag the text frame to any position on screen.|r")

    Div(win, -690)

    -- ── Restore defaults + credits ────────────────────────────────────────────
    local restoreBtn = MakeBtn(win, "Restore All Defaults", 180, 26)
    restoreBtn:SetPoint("TOPLEFT", win, "TOPLEFT", 20, -702)

    StaticPopupDialogs["COMBATALERT_RESET_CONFIRM"] = {
        text         = "Reset all CombatAlert settings to defaults?\nThis will reload the UI.",
        button1      = "Reset",
        button2      = "Cancel",
        OnAccept     = function() CombatAlertDB = nil; ReloadUI() end,
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
    }
    restoreBtn:SetScript("OnClick", function()
        StaticPopup_Show("COMBATALERT_RESET_CONFIRM")
    end)

    local credits = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    credits:SetPoint("LEFT",   restoreBtn, "RIGHT", 14, 0)
    credits:SetPoint("BOTTOM", restoreBtn, "BOTTOM", 0, 1)
    credits:SetText("|cff333344twitch.tv/soundzgood  ·  Discord: soundz1|r")

    -- ── Sync all controls when the window opens ────────────────────────────────
    win:SetScript("OnShow", function()
        local db = CombatAlertDB
        if not db then return end

        cbEnable:SetChecked(db.enabled)
        cbEnterOn:SetChecked(db.enterEnabled)
        cbLeaveOn:SetChecked(db.leaveEnabled)
        lockCb:SetChecked(db.locked)

        -- SetText fires OnTextChanged which auto-updates the placeholder hint
        enterTextBox.editBox:SetText(db.enterText or "")
        leaveTextBox.editBox:SetText(db.leaveText or "")

        enterSwatch.refresh()
        leaveSwatch.refresh()

        enterSoundDD:SetSelection(db.enterSound or "None")
        leaveSoundDD:SetSelection(db.leaveSound or "None")

        fontDD:SetSelection(db.fontName or "Friz Quadrata TT")

        local ol = CombatAlert.OutlinesById[db.outlineId or "thick"]
        outlineDD:SetSelection(ol and ol.label or "Thick Outline")

        local curStyle = db.animStyle or "fade"
        for _, s in ipairs(CombatAlert.ANIM_STYLES) do
            if s.id == curStyle then animDD:SetSelection(s.label); break end
        end

        sizeSlider:SetValue(db.fontSize or 36)
        sizeVal:SetText(string.format("|cffff7333%dpt|r", db.fontSize or 36))

        durSlider:SetValue(db.displayDuration or 2.5)
        durVal:SetText(string.format("|cffff7333%.1fs|r", db.displayDuration or 2.5))
    end)
end

-- ── Blizzard settings panel ───────────────────────────────────────────────────
local panel

local function BuildPanel()
    panel      = CreateFrame("Frame")
    panel.name = "CombatAlert"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffff7333CombatAlert|r  |cffaaaaaa-- by Soundz|r")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText("|cffaaaaaaDisplays customizable text on combat enter and leave.|r")

    local divTex = panel:CreateTexture(nil, "ARTWORK")
    divTex:SetColorTexture(0.25, 0.25, 0.30, 0.6)
    divTex:SetHeight(1)
    divTex:SetPoint("TOPLEFT",  panel, "TOPLEFT",  16, -56)
    divTex:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -56)

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetSize(200, 26)
    openBtn:SetText("Open CombatAlert Settings")
    openBtn:SetPoint("TOPLEFT", 16, -80)
    openBtn:SetScript("OnClick", function() CombatAlert.ToggleWindow() end)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    hint:SetPoint("TOPLEFT", 16, -120)
    hint:SetText("Slash commands:  /combatalert  ·  /calt")

    local credits = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    credits:SetPoint("TOPLEFT", 16, -148)
    credits:SetText("Feedback & Bugreports:  twitch.tv/soundzgood  ·  Discord: soundz1")

    return panel
end

-- ── Public API ────────────────────────────────────────────────────────────────
function CombatAlert.ToggleWindow()
    if not win then return end
    if win:IsShown() then win:Hide() else win:Show() end
end

function CombatAlert.OpenSettings()
    if not win then return end
    win:Show()
end

-- ── Registration ──────────────────────────────────────────────────────────────
local optFrame = CreateFrame("Frame")
optFrame:RegisterEvent("PLAYER_LOGIN")
optFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    -- Defer one tick so all other addons' PLAYER_LOGIN handlers complete first
    -- (e.g. PVPHUB registers its bundled fonts with LSM in its own PLAYER_LOGIN).
    C_Timer.After(0, function()
        BuildWindow()
        BuildPanel()
        if Settings and Settings.RegisterCanvasLayoutCategory then
            local cat = Settings.RegisterCanvasLayoutCategory(panel, "CombatAlert")
            Settings.RegisterAddOnCategory(cat)
        elseif InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end)
end)
