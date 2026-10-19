--// Adopt Me Trade Values — цены elvebredd.com над окном трейда + калькулятор
local VALUES_URL = "https://raw.githubusercontent.com/pophol221-arch/mm2-values/main/adoptme-values/values.json"
local SETTINGS_FILE = "AMTradeValues_settings.json"

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui   = game:GetService("StarterGui")
local RS           = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- повторный запуск: убираем прошлую копию
local env = (getgenv and getgenv()) or _G
if env.AMTV_cleanup then pcall(env.AMTV_cleanup) end
for _, g in ipairs(PlayerGui:GetChildren()) do
    if g.Name == "AMTVOverlayUI" then g:Destroy() end
end
local conns = {}
local function on(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

------------------------------------------------------------------
-- Настройки (сохраняются в файл экзекьютора, если он умеет writefile)
------------------------------------------------------------------
local S = { enabled = true, lang = "ru", theme = 1, textSize = 16, uiScale = 1, showDiff = true, details = true,
            antiAfk = false, iconX = 0.02, iconY = 0.35, calcVar = "r", calcPot = "fr" }
local function saveSettings()
    if writefile then pcall(writefile, SETTINGS_FILE, HttpService:JSONEncode(S)) end
end
if readfile and isfile then
    pcall(function()
        if isfile(SETTINGS_FILE) then
            for k, v in pairs(HttpService:JSONDecode(readfile(SETTINGS_FILE))) do S[k] = v end
        end
    end)
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local C = {
    bg = rgb(15, 16, 21), card = rgb(25, 27, 35), line = rgb(255, 255, 255),
    text = rgb(238, 240, 246), muted = rgb(135, 140, 158),
    good = rgb(70, 215, 130), fair = rgb(245, 195, 70), bad = rgb(240, 85, 95),
    neon = rgb(120, 230, 120), mega = rgb(200, 120, 255),
}
local ACCENTS = {
    rgb(255, 110, 80), rgb(90, 140, 255), rgb(150, 110, 255),
    rgb(50, 205, 160), rgb(255, 95, 155), rgb(210, 215, 228),
}
local function accent() return ACCENTS[S.theme] or ACCENTS[1] end

local L = {
    ru = { you = "ТЫ", them = "ОН", win = "ВЫГОДА", good = "ВЫГОДНО", fair = "ЧЕСТНО", bad = "НЕВЫГОДНО", empty = "ПУСТО",
           noPrice = "без цены: %d", settings = "Adopt Me Values", tabMain = "Основное", tabCalc = "Калькулятор",
           enabled = "Скрипт включён", size = "Размер текста", scale = "Масштаб", theme = "Акцент", lang = "Язык",
           diff = "Показывать разницу", details = "Список предметов в плашке", antiAfk = "Анти-АФК",
           reset = "Вернуть плашку на место", diag = "Диагностика трейда", diagBtn = "Скопировать",
           diagDone = "Диагностика скопирована — пришли её", diagPrinted = "Диагностика в консоли (F9)",
           loaded = "Цен загружено: %d · %s", failed = "Цены не загрузились", noGame = "Не вижу данные Adopt Me — нажми «Диагностика»",
           search = "Поиск…", addYou = "+ТЫ", addThem = "+ОН", clear = "Очистить", noVals = "нет цены",
           varR = "Обычный", varN = "Neon", varM = "Mega", potNp = "Без", potR = "R", potF = "F", potFr = "FR",
           hint = "Нажми на предмет сверху, чтобы убрать его", updated = "обновлено %s",
           types = { pets = "питомец", eggs = "яйцо", toys = "игрушка", vehicles = "транспорт", ["pet wear"] = "одежда",
                     strollers = "коляска", food = "еда", gifts = "подарок", stickers = "стикер", other = "другое" } },
    en = { you = "YOU", them = "THEM", win = "GAIN", good = "WIN", fair = "FAIR", bad = "LOSE", empty = "EMPTY",
           noPrice = "no price: %d", settings = "Adopt Me Values", tabMain = "General", tabCalc = "Calculator",
           enabled = "Script enabled", size = "Text size", scale = "Scale", theme = "Accent", lang = "Language",
           diff = "Show difference", details = "Item list in the bar", antiAfk = "Anti-AFK",
           reset = "Reset bar position", diag = "Trade diagnostics", diagBtn = "Copy",
           diagDone = "Diagnostics copied — send it over", diagPrinted = "Diagnostics printed to console (F9)",
           loaded = "Prices loaded: %d · %s", failed = "Failed to load prices", noGame = "Adopt Me data not found — press Diagnostics",
           search = "Search…", addYou = "+YOU", addThem = "+THEM", clear = "Clear", noVals = "no value",
           varR = "Normal", varN = "Neon", varM = "Mega", potNp = "None", potR = "R", potF = "F", potFr = "FR",
           hint = "Tap an item above to remove it", updated = "updated %s",
           types = {} },
}
local function T(k) return (L[S.lang] or L.ru)[k] or L.ru[k] end

local function notify(text)
    pcall(function() StarterGui:SetCore("SendNotification", { Title = "AM Values", Text = text, Duration = 6 }) end)
end

------------------------------------------------------------------
-- Цены
------------------------------------------------------------------
local DB = { byName = {}, list = {}, count = 0, updated = "" }

;(function()
    -- норм-ключ: без регистра, пробелов и знаков (Fly&Ride, Hot-Doggo и т.п.)
    function DB.norm(s) return (tostring(s or "")):lower():gsub("[%s%p]", "") end

    -- цена предмета: var = r | n | m, pot = np | r | f | fr
    function DB.price(e, var, pot)
        if not e then return nil end
        if e.v then
            local row = e.v[var or "r"]
            if not row then return nil end
            return row[pot or "fr"] or row.base
        end
        return e.value
    end

    function DB.find(name, typ)
        local lst = DB.byName[DB.norm(name)]
        if not lst then return nil end
        if typ then
            for _, e in ipairs(lst) do if e.type == typ then return e end end
        end
        return lst[1]
    end

    function DB.load()
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(VALUES_URL .. "?t=" .. os.time()))
        end)
        if not ok or type(res) ~= "table" or type(res.items) ~= "table" then
            warn("[AMTV] не загрузил цены:", res)
            return false
        end
        local byName, arr = {}, {}
        for _, e in ipairs(res.items) do
            if type(e) == "table" and e.name then
                e.key = DB.norm(e.name)
                byName[e.key] = byName[e.key] or {}
                table.insert(byName[e.key], e)
                table.insert(arr, e)
            end
        end
        -- питомцы раньше остального, внутри — по цене
        table.sort(arr, function(a, b)
            local pa, pb = a.type == "pets", b.type == "pets"
            if pa ~= pb then return pa end
            return (DB.price(a, "r", "fr") or -1) > (DB.price(b, "r", "fr") or -1)
        end)
        DB.byName, DB.list, DB.count = byName, arr, #arr
        DB.updated = tostring(res.updated or ""):sub(1, 10)
        return true
    end
end)()

-- 1 234 / 12.5 / 0.07
local function fmt(n)
    if not n then return "?" end
    if n >= 100 then
        local s = tostring(math.floor(n + 0.5)); local r
        repeat s, r = s:gsub("^(%d+)(%d%d%d)", "%1 %2") until r == 0
        return s
    end
    local s = (n >= 1 and ("%.2f") or ("%.3f")):format(n)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s
end

------------------------------------------------------------------
-- Данные игры: трейд читается из клиентских модулей Adopt Me (Fsys)
------------------------------------------------------------------
local AM = { ok = false }

;(function()
    -- категории инвентаря Adopt Me -> типы elvebredd
    local CAT = { pets = "pets", toys = "toys", pet_accessories = "pet wear", transport = "vehicles",
                  strollers = "strollers", food = "food", gifts = "gifts", stickers = "stickers" }

    function AM.init()
        local ok, load = pcall(function()
            return require(RS:WaitForChild("Fsys", 15)).load
        end)
        if not ok or type(load) ~= "function" then return false end
        local ok1, cd = pcall(load, "ClientData")
        local ok2, idb = pcall(load, "InventoryDB")
        AM.CD = ok1 and cd or nil
        AM.IDB = ok2 and idb or nil
        AM.ok = AM.CD ~= nil
        return AM.ok
    end

    -- данные своего игрока (у ClientData разные способы доступа в разных версиях)
    function AM.data()
        local cd = AM.CD
        if not cd then return nil end
        if type(cd.get_data) == "function" then
            local ok, all = pcall(cd.get_data)
            if ok and type(all) == "table" then
                local mine = all[LP.Name] or all[LP]
                if type(mine) == "table" then return mine end
            end
        end
        return nil
    end

    function AM.trade()
        local cd = AM.CD
        if not cd then return nil end
        local d = AM.data()
        if d and type(d.trade) == "table" then return d.trade end
        if type(cd.get) == "function" then
            local ok, t = pcall(cd.get, "trade")
            if ok and type(t) == "table" then return t end
        end
        return nil
    end

    local function isMe(p)
        if p == LP then return true end
        if type(p) == "string" then return p == LP.Name end
        if typeof(p) == "Instance" then return p == LP end
        if type(p) == "table" then return p.Name == LP.Name or p.name == LP.Name or p.user_id == LP.UserId end
        return false
    end

    -- {mine, theirs, partnerName} или nil
    function AM.offers(t)
        if type(t) ~= "table" then return nil end
        local so, ro = t.sender_offer, t.recipient_offer
        if type(so) ~= "table" or type(ro) ~= "table" then return nil end
        if isMe(t.recipient) then
            return ro, so, t.sender
        end
        return so, ro, t.recipient
    end

    local function prettyKind(kind)
        return (tostring(kind):gsub("_", " "):gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
    end

    -- имя предмета для поиска цены
    function AM.itemName(it)
        local kind = it.kind or it.id
        local cat = it.category
        local idb = AM.IDB
        if idb and kind then
            local sect = cat and idb[cat]
            local rec = type(sect) == "table" and sect[kind]
            if type(rec) ~= "table" then
                for _, s in pairs(idb) do
                    if type(s) == "table" and type(s[kind]) == "table" then rec = s[kind]; break end
                end
            end
            if type(rec) == "table" and rec.name then return rec.name end
        end
        return prettyKind(kind or "?")
    end

    -- предмет трейда -> { name, var, pot, price, typ }
    function AM.describe(it)
        local p = type(it.properties) == "table" and it.properties or {}
        local var = (p.mega_neon and "m") or (p.neon and "n") or "r"
        local fly, ride = p.flyable and true or false, p.rideable and true or false
        local pot = (fly and ride and "fr") or (fly and "f") or (ride and "r") or "np"
        local name = AM.itemName(it)
        local typ = CAT[it.category or ""]
        local e = DB.find(name, typ)
        return { name = name, var = var, pot = pot, typ = typ, entry = e, price = DB.price(e, var, pot), pet = e and e.v ~= nil }
    end

    function AM.sum(offer)
        local items = type(offer) == "table" and offer.items or nil
        local total, unk, out = 0, 0, {}
        if type(items) ~= "table" then return 0, 0, out end
        for _, it in pairs(items) do
            if type(it) == "table" then
                local d = AM.describe(it)
                table.insert(out, d)
                if d.price then total += d.price else unk += 1 end
            end
        end
        table.sort(out, function(a, b) return (a.price or -1) > (b.price or -1) end)
        return total, unk, out
    end

    -- дамп для диагностики (глубина ограничена, Instance -> имя)
    function AM.dump(v, depth, seen)
        depth, seen = depth or 0, seen or {}
        local tv = typeof(v)
        if tv == "Instance" then return "<" .. v.ClassName .. " " .. v:GetFullName() .. ">" end
        if tv ~= "table" then return tostring(v) end
        if seen[v] then return "<cycle>" end
        if depth > 5 then return "{...}" end
        seen[v] = true
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n += 1
            if n > 40 then table.insert(parts, "..."); break end
            table.insert(parts, ("  "):rep(depth + 1) .. tostring(k) .. " = " .. AM.dump(x, depth + 1, seen))
        end
        return "{\n" .. table.concat(parts, "\n") .. "\n" .. ("  "):rep(depth) .. "}"
    end

    function AM.diagnostics()
        local lines = { "AMTV diag", "Fsys ok: " .. tostring(AM.ok), "IDB: " .. tostring(AM.IDB ~= nil) }
        local d = AM.data()
        if d then
            local keys = {}
            for k in pairs(d) do table.insert(keys, tostring(k)) end
            table.sort(keys)
            table.insert(lines, "data keys: " .. table.concat(keys, ", "))
            local inv = type(d.inventory) == "table" and d.inventory or nil
            local pets = inv and inv.pets
            if type(pets) == "table" then
                local n = 0
                for _, p in pairs(pets) do
                    n += 1; if n > 2 then break end
                    table.insert(lines, "pet sample: " .. AM.dump(p, 1))
                end
            end
        else
            table.insert(lines, "data: nil")
        end
        table.insert(lines, "trade: " .. AM.dump(AM.trade()))
        local text = table.concat(lines, "\n")
        if setclipboard then pcall(setclipboard, text); notify(T("diagDone"))
        else print(text); notify(T("diagPrinted")) end
    end
end)()

------------------------------------------------------------------
-- Помощники интерфейса
------------------------------------------------------------------
local onTheme = {}  -- что перекрашивать при смене акцента
local function themed(fn) table.insert(onTheme, fn); fn() end
local function retheme() for _, f in ipairs(onTheme) do pcall(f) end end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function stroke(p, col, tr, th)
    return new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = col or C.line, Transparency = tr or 0.92, Thickness = th or 1 }, p)
end
local function pad(p, x, y)
    return new("UIPadding", { PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x), PaddingTop = UDim.new(0, y), PaddingBottom = UDim.new(0, y) }, p)
end
local function list(p, dir, gap, hAlign, vAlign)
    return new("UIListLayout", {
        FillDirection = dir, Padding = UDim.new(0, gap or 0), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left, VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
    }, p)
end
local function label(parent, props, bold)
    local t = new("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = C.text, TextSize = 14, RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
    }, parent)
    for k, v in pairs(props or {}) do t[k] = v end
    return t
end
local function hex(c)
    return ("#%02X%02X%02X"):format(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function tween(o, t, props, style)
    TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

-- перетаскивание: короткое нажатие = клик, движение = перенос
local function makeDraggable(handle, target, onClick, onDrop)
    local dragging, moved, startInput, startPos = false, false, nil, nil
    on(handle.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, startInput, startPos = true, false, i.Position, target.AbsolutePosition
        end
    end)
    on(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.AnchorPoint = Vector2.zero
                target.Position = UDim2.fromOffset(startPos.X + d.X, startPos.Y + d.Y)
            end
        end
    end)
    on(UIS.InputEnded, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if moved then if onDrop then onDrop() end elseif onClick then onClick() end
        end
    end)
end

local ui = new("ScreenGui", { Name = "AMTVOverlayUI", ResetOnSpawn = false, DisplayOrder = 1000, IgnoreGuiInset = true, AutoLocalize = false }, PlayerGui)

-- общий масштаб: под высоту экрана (720p = 1) и ручная поправка
local function sf()
    local h = ui.AbsoluteSize.Y
    local base = h > 0 and math.clamp(h / 720, 0.8, 1.8) or 1
    return base * (S.uiScale or 1)
end

-- оценка трейда: доля «его» стороны, цвет и статус
local function verdict(my, th)
    local total = my + th
    local share = total > 0 and th / total or 0.5
    local pct = math.floor(share * 100 + 0.5)
    if total == 0 then return share, pct, C.muted, T("empty") end
    if math.abs(pct - 50) <= 5 then return share, pct, C.fair, T("fair") end
    if pct > 50 then return share, pct, C.good, T("good") end
    return share, pct, C.bad, T("bad")
end

-- тег варианта: «NFR», «M», «FR»
local function varTag(var, pot, pet)
    if not pet then return "" end
    local v = (var == "m" and ('<font color="%s">M</font>'):format(hex(C.mega)))
        or (var == "n" and ('<font color="%s">N</font>'):format(hex(C.neon))) or ""
    local p = ({ fr = "FR", f = "F", r = "R", np = "" })[pot] or ""
    return v .. p
end

------------------------------------------------------------------
-- Плашка над трейдом:  ТЫ 1 500 | ВЫГОДА 62% ▬▬▬ | ОН 2 400 (+900)
------------------------------------------------------------------
local H = {}

;(function()
    local hud = new("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), Visible = false,
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.08,
    }, ui)
    corner(hud, 14)
    stroke(hud)
    pad(hud, 16, 10)
    list(hud, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)
    H.frame = hud
    H.scale = new("UIScale", {}, hud)
    local topRow = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 1 }, hud)
    list(topRow, Enum.FillDirection.Horizontal, 18, nil, Enum.VerticalAlignment.Top)

    local function sideBlock(order, align, xa)
        local b = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = order }, topRow)
        list(b, Enum.FillDirection.Vertical, 1, align)
        local cap = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextColor3 = C.muted, LayoutOrder = 1 })
        local val = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 2 }, true)
        local note = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextColor3 = C.muted, LayoutOrder = 3, Visible = false })
        local items = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextColor3 = C.text, LayoutOrder = 4, TextXAlignment = xa, Visible = false })
        return { cap = cap, val = val, note = note, items = items }
    end
    H.you = sideBlock(1, Enum.HorizontalAlignment.Left, Enum.TextXAlignment.Left)

    local mid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 40), LayoutOrder = 2 }, topRow)
    H.win = label(mid, { Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Center }, true)
    H.status = label(mid, { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.muted })
    local track = new("Frame", { BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.9, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 21), BorderSizePixel = 0 }, mid)
    corner(track, 3)
    H.fill = new("Frame", { BackgroundColor3 = C.good, Size = UDim2.fromScale(0.5, 1), BorderSizePixel = 0 }, track)
    corner(H.fill, 3)
    H.grad = new("UIGradient", {}, H.fill)
    new("Frame", { BackgroundColor3 = C.text, BackgroundTransparency = 0.55, BorderSizePixel = 0, Size = UDim2.new(0, 2, 1, 6), Position = UDim2.new(0.5, -1, 0, -3) }, track)

    H.them = sideBlock(3, Enum.HorizontalAlignment.Right, Enum.TextXAlignment.Right)

    makeDraggable(hud, hud, nil, function()
        local abs = ui.AbsoluteSize
        S.hudX, S.hudY = hud.AbsolutePosition.X / abs.X, hud.AbsolutePosition.Y / abs.Y
        hud.Position = UDim2.fromScale(S.hudX, S.hudY)
        saveSettings()
    end)
    function H.place()
        if S.hudX then
            hud.AnchorPoint, hud.Position = Vector2.zero, UDim2.fromScale(S.hudX, S.hudY)
        else
            hud.AnchorPoint, hud.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.06)
        end
    end
    H.place()

    function H.style()
        local ts = S.textSize
        for _, side in ipairs({ H.you, H.them }) do
            side.cap.TextSize = math.max(10, ts - 4)
            side.val.TextSize = ts + 4
            side.note.TextSize = math.max(10, ts - 4)
            side.items.TextSize = math.max(10, ts - 3)
        end
        H.you.cap.Text, H.them.cap.Text = T("you"), T("them")
        H.win.TextSize = math.max(11, ts - 1)
        H.status.TextSize = math.max(9, ts - 6)
    end
    H.style()

    local function setNote(side, unk)
        side.note.Visible = unk > 0
        side.note.Text = unk > 0 and T("noPrice"):format(unk) or ""
    end
    local function setItems(side, out)
        if not S.details or #out == 0 then side.items.Visible = false; return end
        local lines = {}
        for i, d in ipairs(out) do
            if i > 9 then table.insert(lines, ("… +%d"):format(#out - 9)); break end
            local tag = varTag(d.var, d.pot, d.pet)
            local price = d.price and fmt(d.price) or ('<font color="%s">?</font>'):format(hex(C.muted))
            table.insert(lines, ("%s%s  <b>%s</b>"):format(tag ~= "" and (tag .. " ") or "", d.name, price))
        end
        side.items.Text = table.concat(lines, "\n")
        side.items.Visible = true
    end

    function H.render(mine, theirs)
        local my, myUnk, myItems = AM.sum(mine)
        local th, thUnk, thItems = AM.sum(theirs)
        local share, pct, col, status = verdict(my, th)
        local diff = th - my
        H.you.val.Text = fmt(my)
        local ds = ""
        if S.showDiff and my + th > 0 and math.abs(diff) > 0.001 then
            ds = (' <font color="%s" size="%d">%s%s</font>'):format(hex(diff > 0 and C.good or C.bad), math.max(10, S.textSize - 2), diff > 0 and "+" or "−", fmt(math.abs(diff)))
        end
        H.them.val.Text = fmt(th) .. ds
        setNote(H.you, myUnk)
        setNote(H.them, thUnk)
        setItems(H.you, myItems)
        setItems(H.them, thItems)
        H.win.Text = ('<font color="%s">%s %d%%</font>'):format(hex(col), T("win"), pct)
        H.status.Text = status
        H.status.TextColor3 = col
        tween(H.fill, 0.3, { Size = UDim2.fromScale(math.clamp(share, 0.03, 1), 1) })
        H.grad.Color = ColorSequence.new(col:Lerp(C.text, 0.3), col)
    end
end)()

------------------------------------------------------------------
-- Кнопка ⚙️ и окно
------------------------------------------------------------------
local W = {}

;(function()
    local gear = new("TextButton", {
        Size = UDim2.fromOffset(46, 46), Position = UDim2.fromScale(S.iconX, S.iconY),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Text = "🐾", TextSize = 22,
        Font = Enum.Font.GothamBold, TextColor3 = C.text, AutoButtonColor = false,
    }, ui)
    corner(gear, 23)
    local ring = stroke(gear, accent(), 0.35, 1.5)
    themed(function() ring.Color = accent() end)
    W.gearScale = new("UIScale", {}, gear)

    local panel = new("Frame", {
        Size = UDim2.fromOffset(500, 0), AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.06), Visible = false,
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.04,
    }, ui)
    corner(panel, 18)
    stroke(panel)
    pad(panel, 16, 16)
    list(panel, Enum.FillDirection.Vertical, 8)
    W.panel = panel
    W.scale = new("UIScale", {}, panel)

    makeDraggable(gear, gear, function()
        panel.Visible = not panel.Visible
        if panel.Visible then
            W.scale.Scale = sf() * 0.92
            tween(W.scale, 0.25, { Scale = sf() }, Enum.EasingStyle.Back)
            if W.refreshCalc then W.refreshCalc() end
        end
    end, function()
        local abs = ui.AbsoluteSize
        S.iconX, S.iconY = gear.AbsolutePosition.X / abs.X, gear.AbsolutePosition.Y / abs.Y
        gear.Position = UDim2.fromScale(S.iconX, S.iconY)
        saveSettings()
    end)

    -- шапка
    local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 0 }, panel)
    local logo = new("TextLabel", {
        Size = UDim2.fromOffset(38, 38), BackgroundColor3 = rgb(255, 255, 255), Text = "AM", TextColor3 = rgb(255, 255, 255),
        TextSize = 15, Font = Enum.Font.GothamBold,
    }, head)
    corner(logo, 11)
    local logoGrad = new("UIGradient", { Rotation = 45 }, logo)
    themed(function() logoGrad.Color = ColorSequence.new(accent(), accent():Lerp(rgb(0, 0, 0), 0.35)) end)
    W.title = label(head, { Size = UDim2.new(1, -96, 0, 20), Position = UDim2.fromOffset(50, 1), TextSize = 17 }, true)
    W.subtitle = label(head, { Size = UDim2.new(1, -96, 0, 14), Position = UDim2.fromOffset(50, 22), TextSize = 12, TextColor3 = C.muted })
    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.card, Text = "✕", TextColor3 = C.muted, TextSize = 14, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    }, head)
    corner(closeBtn, 16)
    stroke(closeBtn)
    on(closeBtn.MouseButton1Click, function() panel.Visible = false end)
    makeDraggable(W.title, panel)
    makeDraggable(logo, panel)

    -- вкладки
    local tabBar = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card, BackgroundTransparency = 0.3, LayoutOrder = 1 }, panel)
    corner(tabBar, 10)
    stroke(tabBar)
    local knob = new("Frame", { Size = UDim2.new(0.5, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = accent() }, tabBar)
    corner(knob, 8)
    themed(function() knob.BackgroundColor3 = accent() end)
    W.tabs = {}
    local bodies = {}
    local function makeBody(order, visible)
        local b = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Visible = visible }, panel)
        corner(b, 12)
        stroke(b)
        list(b, Enum.FillDirection.Vertical, 0, Enum.HorizontalAlignment.Center)
        new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, b)
        return b
    end
    W.bodyMain, W.bodyCalc = makeBody(2, true), makeBody(3, false)
    bodies = { W.bodyMain, W.bodyCalc }
    for i, key in ipairs({ "tabMain", "tabCalc" }) do
        local b = new("TextButton", { Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale((i - 1) / 2, 0), BackgroundTransparency = 1,
            Text = "", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 2 }, tabBar)
        W.tabs[i] = { btn = b, key = key }
        on(b.MouseButton1Click, function()
            for j, bd in ipairs(bodies) do bd.Visible = j == i end
            tween(knob, 0.25, { Position = UDim2.new((i - 1) / 2, 3, 0, 3) })
            if i == 2 and W.refreshCalc then W.refreshCalc() end
        end)
    end

    W.footer = label(panel, { Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 9 })
end)()

------------------------------------------------------------------
-- Вкладка «Основное»
------------------------------------------------------------------
;(function()
    local body = W.bodyMain
    local count = 0
    local texts = {} -- { label, key } для смены языка

    local function row(key)
        count += 1
        if count > 1 then
            new("Frame", { BackgroundColor3 = C.line, BackgroundTransparency = 0.94, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 1), LayoutOrder = count * 2 - 1 }, body)
        end
        local r = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = count * 2 }, body)
        pad(r, 12, 0)
        local name = label(r, { Size = UDim2.new(0.6, 0, 1, 0), TextSize = 14 })
        table.insert(texts, { name, key })
        return r
    end
    local function control(parent, w)
        local f = new("Frame", {
            Size = UDim2.fromOffset(w, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = C.bg, BackgroundTransparency = 0.2,
        }, parent)
        corner(f, 9)
        stroke(f)
        return f
    end
    local function flatBtn(parent, text, size, pos)
        local b = new("TextButton", {
            Size = size, Position = pos, BackgroundColor3 = C.bg, BackgroundTransparency = 1,
            Text = text, TextColor3 = C.text, TextSize = 16, Font = Enum.Font.GothamBold, AutoButtonColor = false,
        }, parent)
        corner(b, 8)
        return b
    end
    local function toggle(key, setting, after)
        local r = row(key)
        local t = new("TextButton", {
            Size = UDim2.fromOffset(46, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = rgb(60, 62, 74), Text = "", AutoButtonColor = false,
        }, r)
        corner(t, 13)
        local k = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = rgb(255, 255, 255) }, t)
        corner(k, 10)
        local function draw()
            local st = S[setting]
            tween(t, 0.2, { BackgroundColor3 = st and accent() or rgb(60, 62, 74) })
            tween(k, 0.2, { Position = st and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
        end
        themed(draw)
        on(t.MouseButton1Click, function()
            S[setting] = not S[setting]
            saveSettings(); draw()
            if after then after() end
        end)
    end
    local function stepper(key, show, dec, inc)
        local r = row(key)
        local box = control(r, 108)
        local minus = flatBtn(box, "−", UDim2.fromOffset(32, 30), UDim2.fromOffset(0, 0))
        local val = label(box, { Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(32, 0), TextXAlignment = Enum.TextXAlignment.Center }, true)
        local plus = flatBtn(box, "+", UDim2.fromOffset(32, 30), UDim2.new(1, -32, 0, 0))
        val.Text = show()
        on(minus.MouseButton1Click, function() dec(); saveSettings(); val.Text = show() end)
        on(plus.MouseButton1Click, function() inc(); saveSettings(); val.Text = show() end)
    end

    toggle("enabled", "enabled")
    stepper("size", function() return tostring(S.textSize) end,
        function() S.textSize = math.max(10, S.textSize - 1); H.style() end,
        function() S.textSize = math.min(26, S.textSize + 1); H.style() end)
    stepper("scale", function() return math.floor((S.uiScale or 1) * 100 + 0.5) .. "%" end,
        function() S.uiScale = math.max(0.6, (S.uiScale or 1) - 0.1); W.rescale() end,
        function() S.uiScale = math.min(1.6, (S.uiScale or 1) + 0.1); W.rescale() end)

    -- акцент: кружки
    local rTheme = row("theme")
    local dotsBox = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(#ACCENTS * 26, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) }, rTheme)
    list(dotsBox, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    for i, col in ipairs(ACCENTS) do
        local d = new("TextButton", { Size = UDim2.fromOffset(20, 20), BackgroundColor3 = col, Text = "", AutoButtonColor = false, LayoutOrder = i }, dotsBox)
        corner(d, 10)
        local ring = stroke(d, rgb(255, 255, 255), 1, 2)
        themed(function() ring.Transparency = S.theme == i and 0 or 1 end)
        on(d.MouseButton1Click, function() S.theme = i; saveSettings(); retheme() end)
    end

    -- язык: RU | EN
    local rLang = row("lang")
    local seg = control(rLang, 100)
    for i, code in ipairs({ "ru", "en" }) do
        local b = new("TextButton", { Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale((i - 1) / 2, 0), BackgroundColor3 = accent(),
            BackgroundTransparency = 1, Text = code:upper(), TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false }, seg)
        corner(b, 8)
        themed(function() b.BackgroundColor3 = accent(); b.BackgroundTransparency = S.lang == code and 0 or 1 end)
        on(b.MouseButton1Click, function() S.lang = code; saveSettings(); retheme(); W.relabel() end)
    end

    toggle("diff", "showDiff")
    toggle("details", "details")
    toggle("antiAfk", "antiAfk")

    -- диагностика
    local rDiag = row("diag")
    local diagBtn = new("TextButton", { Size = UDim2.fromOffset(120, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, Text = "", TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false }, rDiag)
    corner(diagBtn, 9)
    local diagStroke = stroke(diagBtn, accent(), 0.5)
    themed(function() diagStroke.Color = accent() end)
    on(diagBtn.MouseButton1Click, function() pcall(AM.diagnostics) end)

    -- сброс позиции плашки
    local rReset = row("reset")
    local resetBtn = new("TextButton", { Size = UDim2.fromOffset(120, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, Text = "↺", TextColor3 = C.text, TextSize = 16, Font = Enum.Font.GothamBold, AutoButtonColor = false }, rReset)
    corner(resetBtn, 9)
    local resetStroke = stroke(resetBtn, accent(), 0.5)
    themed(function() resetStroke.Color = accent() end)
    on(resetBtn.MouseButton1Click, function() S.hudX, S.hudY = nil, nil; saveSettings(); H.place() end)

    function W.relabel()
        for _, p in ipairs(texts) do p[1].Text = T(p[2]) end
        diagBtn.Text = T("diagBtn")
        W.title.Text = T("settings")
        W.subtitle.Text = DB.count > 0 and T("loaded"):format(DB.count, DB.updated) or T("failed")
        for _, tb in ipairs(W.tabs) do tb.btn.Text = T(tb.key) end
        W.footer.Text = "elvebredd.com · " .. (AM.ok and "Adopt Me ✓" or T("noGame"))
        H.style()
        if W.relabelCalc then W.relabelCalc() end
    end
    function W.rescale()
        W.scale.Scale = sf()
        W.gearScale.Scale = sf()
        H.scale.Scale = sf()
    end
end)()

------------------------------------------------------------------
-- Вкладка «Калькулятор»: собрать трейд вручную и сравнить
------------------------------------------------------------------
;(function()
    local body = W.bodyCalc
    pad(body, 10, 8)
    body:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 8)
    local sides = { you = {}, them = {} }
    local boxes = {}

    -- две колонки выбранных предметов
    local cols = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 150), LayoutOrder = 1 }, body)
    local heads = {}
    for i, side in ipairs({ "you", "them" }) do
        local col = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0) }, cols)
        corner(col, 10)
        stroke(col)
        heads[side] = label(col, { Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 4), TextSize = 13 }, true)
        local sc = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -8, 1, -30), Position = UDim2.fromOffset(4, 28),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3 }, col)
        list(sc, Enum.FillDirection.Vertical, 3)
        boxes[side] = sc
    end

    local totalLine = label(body, { Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2 }, true)
    local hintLine = label(body, { Size = UDim2.new(1, 0, 0, 12), TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 3 })

    -- вариант для добавляемых питомцев
    local segRefresh = {}
    local function segmented(order, opts, setting)
        local f = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = order }, body)
        corner(f, 9)
        stroke(f)
        local btns = {}
        for i, o in ipairs(opts) do
            local b = new("TextButton", { Size = UDim2.new(1 / #opts, -4, 1, -4), Position = UDim2.new((i - 1) / #opts, 2, 0, 2),
                BackgroundColor3 = accent(), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 13,
                Font = Enum.Font.GothamBold, AutoButtonColor = false }, f)
            corner(b, 7)
            btns[i] = { b = b, o = o }
            on(b.MouseButton1Click, function() S[setting] = o[1]; saveSettings(); for _, fn in ipairs(segRefresh) do fn() end end)
        end
        local function draw()
            for _, x in ipairs(btns) do
                x.b.Text = T(x.o[2])
                x.b.BackgroundColor3 = accent()
                x.b.BackgroundTransparency = S[setting] == x.o[1] and 0 or 1
            end
        end
        themed(draw)
        table.insert(segRefresh, draw)
    end
    segmented(4, { { "r", "varR" }, { "n", "varN" }, { "m", "varM" } }, "calcVar")
    segmented(5, { { "np", "potNp" }, { "r", "potR" }, { "f", "potF" }, { "fr", "potFr" } }, "calcPot")

    -- поиск + очистка
    local bar = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 6 }, body)
    local search = new("TextBox", { Size = UDim2.new(1, -110, 1, 0), BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "",
        PlaceholderText = "", PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamMedium,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, bar)
    corner(search, 9)
    stroke(search)
    pad(search, 10, 0)
    local clearBtn = new("TextButton", { Size = UDim2.new(0, 102, 1, 0), Position = UDim2.new(1, -102, 0, 0), BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.2, Text = "", TextColor3 = C.bad, TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false }, bar)
    corner(clearBtn, 9)
    stroke(clearBtn)

    local results = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 210), LayoutOrder = 7,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3 }, body)
    list(results, Enum.FillDirection.Vertical, 3)

    local function entryPrice(x) return DB.price(x.e, x.var, x.pot) end

    local renderSides
    local function chip(side, idx, x)
        local p = entryPrice(x)
        local b = new("TextButton", { Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = C.card, Text = "", AutoButtonColor = false, LayoutOrder = idx }, boxes[side])
        corner(b, 6)
        local tag = varTag(x.var, x.pot, x.e.v ~= nil)
        label(b, { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(6, 0), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = (tag ~= "" and (tag .. " ") or "") .. x.e.name })
        label(b, { Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -64, 0, 0), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
            Text = p and fmt(p) or "?" }, true)
        on(b.MouseButton1Click, function() table.remove(sides[side], idx); renderSides() end)
    end
    renderSides = function()
        local tot = {}
        for _, side in ipairs({ "you", "them" }) do
            for _, c in ipairs(boxes[side]:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
            local s = 0
            for i, x in ipairs(sides[side]) do chip(side, i, x); s += entryPrice(x) or 0 end
            tot[side] = s
        end
        heads.you.Text = ("%s  ·  %s"):format(T("you"), fmt(tot.you))
        heads.them.Text = ("%s  ·  %s"):format(T("them"), fmt(tot.them))
        local _, pct, col, status = verdict(tot.you, tot.them)
        local diff = tot.them - tot.you
        local ds = (tot.you + tot.them > 0 and math.abs(diff) > 0.001) and ("  (%s%s)"):format(diff > 0 and "+" or "−", fmt(math.abs(diff))) or ""
        totalLine.Text = ('<font color="%s">%s · %s %d%%%s</font>'):format(hex(col), status, T("win"), pct, ds)
    end

    local function addTo(side, e)
        local x = { e = e, var = e.v and S.calcVar or "r", pot = e.v and S.calcPot or "fr" }
        if e.v and not e.v[x.var] then x.var = "r" end
        table.insert(sides[side], x)
        renderSides()
    end

    local function renderResults()
        for _, c in ipairs(results:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local q = DB.norm(search.Text)
        local shown = 0
        for _, e in ipairs(DB.list) do
            if q == "" and e.type ~= "pets" then break end
            if q == "" or e.key:find(q, 1, true) then
                shown += 1
                if shown > 60 then break end
                local r = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.35, Size = UDim2.new(1, -6, 0, 30), LayoutOrder = shown }, results)
                corner(r, 7)
                local typ = (L[S.lang].types or {})[e.type] or e.type
                label(r, { Size = UDim2.new(1, -230, 1, 0), Position = UDim2.fromOffset(8, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = ('%s <font color="%s" size="11">%s</font>'):format(e.name, hex(C.muted), typ) })
                local p = DB.price(e, e.v and S.calcVar or "r", e.v and S.calcPot or "fr")
                label(r, { Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -220, 0, 0), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
                    Text = p and fmt(p) or ('<font color="%s">%s</font>'):format(hex(C.muted), T("noVals")) }, true)
                for i, side in ipairs({ "you", "them" }) do
                    local b = new("TextButton", { Size = UDim2.fromOffset(60, 24), Position = UDim2.new(1, -132 + (i - 1) * 66, 0.5, -12),
                        BackgroundColor3 = i == 1 and C.card or accent(), Text = T(i == 1 and "addYou" or "addThem"), TextColor3 = C.text,
                        TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = true }, r)
                    corner(b, 6)
                    on(b.MouseButton1Click, function() addTo(side, e) end)
                end
            end
        end
    end
    table.insert(segRefresh, function() renderResults() end)

    local pending = false
    on(search:GetPropertyChangedSignal("Text"), function()
        if pending then return end
        pending = true
        task.delay(0.25, function() pending = false; pcall(renderResults) end)
    end)
    on(clearBtn.MouseButton1Click, function() sides.you, sides.them = {}, {}; renderSides() end)

    function W.relabelCalc()
        search.PlaceholderText = T("search")
        clearBtn.Text = T("clear")
        hintLine.Text = T("hint")
        for _, fn in ipairs(segRefresh) do fn() end
        renderSides()
    end
    function W.refreshCalc() pcall(renderResults); pcall(renderSides) end
end)()

------------------------------------------------------------------
-- Анти-АФК
------------------------------------------------------------------
on(LP.Idled, function()
    if not (S.enabled and S.antiAfk) then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

------------------------------------------------------------------
-- Главный цикл: следим за трейдом
------------------------------------------------------------------
;(function()
    local acc, inTrade, errShown = 0, false, false
    local function tick()
        local t = (S.enabled and AM.ok) and AM.trade() or nil
        local mine, theirs = AM.offers(t)
        if not mine then
            if inTrade then inTrade = false; H.frame.Visible = false end
            return
        end
        if not inTrade then
            inTrade = true
            task.spawn(function() if DB.load() then W.relabel() end end) -- свежие цены на каждый трейд
            H.frame.Visible = true
            H.scale.Scale = sf() * 0.9
            tween(H.scale, 0.25, { Scale = sf() }, Enum.EasingStyle.Back)
        end
        H.render(mine, theirs)
    end
    on(RunService.Heartbeat, function(dt)
        acc += dt; if acc < 0.4 then return end; acc = 0
        local ok, err = pcall(tick)
        if not ok and not errShown then -- показать ошибку один раз, чтобы было что прислать
            errShown = true
            notify("Ошибка: " .. tostring(err):sub(1, 150))
        end
    end)
end)()

env.AMTV_cleanup = function()
    for _, c in ipairs(conns) do c:Disconnect() end
    if ui then ui:Destroy() end
end

-- старт: цены и данные игры грузятся в фоне, интерфейс уже на экране
W.rescale()
W.relabel()
task.spawn(function()
    local okDB = DB.load()
    AM.init()
    W.relabel()
    notify(okDB and T("loaded"):format(DB.count, DB.updated) or T("failed"))
    if not AM.ok then notify(T("noGame")) end
end)
