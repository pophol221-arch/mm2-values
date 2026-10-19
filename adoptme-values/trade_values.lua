--// Adopt Me Trade Values — цены elvebredd.com над окном трейда, автооффер, автопринятие, заявки, анализ чата
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
local S = { enabled = true, lang = "ru", theme = 1, font = 1, textSize = 16, uiScale = 1, showDiff = true, details = true,
            iconX = 0.02, iconY = 0.35, calcVar = "r", calcPot = "fr",
            dryRun = true, autoOffer = false, target = 20, autoAdd = true, tolerance = false, fillOver = true,
            autoAccept = false, mirrorEmpty = true, emptyDecline = false, junkDecline = false, giftAccept = true,
            autoDecline = false, blacklist = {}, ordersOn = true, orders = {}, autoRequest = false,
            antiAfk = false, antiFling = false, chatAds = false, chatInTrade = false, chatRequests = true, declineMsg = true }
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
if type(S.blacklist) ~= "table" then S.blacklist = {} end
if type(S.orders) ~= "table" then S.orders = {} end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local C = {
    bg = rgb(15, 16, 21), card = rgb(25, 27, 35), line = rgb(255, 255, 255),
    text = rgb(238, 240, 246), muted = rgb(135, 140, 158),
    good = rgb(70, 215, 130), fair = rgb(245, 195, 70), bad = rgb(240, 85, 95),
    neon = rgb(120, 230, 120), mega = rgb(200, 120, 255), test = rgb(110, 180, 255),
}
local ACCENTS = {
    rgb(255, 110, 80), rgb(90, 140, 255), rgb(150, 110, 255),
    rgb(50, 205, 160), rgb(255, 95, 155), rgb(210, 215, 228),
}
local FONTS = {
    { "Gotham", Enum.Font.GothamBold, Enum.Font.GothamMedium },
    { "Fredoka", Enum.Font.FredokaOne, Enum.Font.FredokaOne },
    { "Ubuntu", Enum.Font.Ubuntu, Enum.Font.Ubuntu },
    { "Montserrat", Enum.Font.Montserrat, Enum.Font.Montserrat },
    { "Luckiest", Enum.Font.LuckiestGuy, Enum.Font.LuckiestGuy },
}
local function accent() return ACCENTS[S.theme] or ACCENTS[1] end
local function fontBold() return (FONTS[S.font] or FONTS[1])[2] end
local function fontReg() return (FONTS[S.font] or FONTS[1])[3] end

local L = {
    ru = { you = "ТЫ", them = "ОН", win = "ВЫГОДА", good = "ВЫГОДНО", fair = "ЧЕСТНО", bad = "НЕВЫГОДНО", empty = "ПУСТО",
           noPrice = "без цены: %d", appTitle = "Adopt Me Values",
           tabMain = "Основное", tabTrade = "Трейд", tabGame = "Игрок", tabChat = "Чат",
           enabled = "Скрипт включён", size = "Размер текста", scale = "Масштаб", theme = "Акцент", font = "Шрифт", lang = "Язык",
           diff = "Показывать разницу", details = "Список предметов в плашке", antiAfk = "Анти-АФК", antiFling = "Анти-флинг",
           reset = "Вернуть плашку на место", diag = "Диагностика трейда", diagBtn = "Скопировать",
           diagDone = "Диагностика скопирована — пришли её", diagPrinted = "Диагностика в консоли (F9)",
           valuesTitle = "Таблица цен", calcTitle = "Калькулятор", open = "Открыть",
           loaded = "Цен загружено: %d · %s", failed = "Цены не загрузились", noGame = "Не вижу данные Adopt Me — нажми «Диагностика»",
           dryRun = "Тестовый режим (ничего не нажимать)", dryTag = "ТЕСТ: ", dryWarn = "Тестовый режим: скрипт только пишет, что сделал бы",
           auto = "Автооффер", target = "Цель прибыли", autoAdd = "Авто-добавление", tolerance = "Допуск ±1%", fillOver = "Добивать сверх цели",
           autoAccept = "Автопринятие", mirrorEmpty = "Убирать, если он всё убрал", emptyDecline = "Пустой трейд: показать предмет и отклонить",
           junkDecline = "Отклонять хлам (без цены)", giftAccept = "Принимать подарки", autoRequest = "Принимать запросы на трейд",
           bl = "Нежелательные предметы", blCount = "%d шт.", autoDecline = "Автоотклонение", orders = "Заявки", ordersOn = "Заявки включены",
           chatAds = "Анализ чата", chatInTrade = "Показывать во время трейда", chatRequests = "Выполнять просьбы из чата", declineMsg = "Писать в чат причину отказа",
           search = "Поиск…", addYou = "+ТЫ", addThem = "+ОН", clear = "Очистить", noVals = "нет цены", all = "Все", marked = "Отмеченные",
           varR = "Обычный", varN = "Neon", varM = "Mega", potNp = "Без", potR = "R", potF = "F", potFr = "FR",
           hint = "Нажми на предмет сверху, чтобы убрать его",
           sugWait = "Цель %s: ждём предметы соперника", sugOk = "Цель %s достигнута", sugRemove = "Цель %s: убери ~%s",
           sugNone = "Цель %s: нечем добить (~%s)", sugAdd = "Цель %s: добавь ~%s: %s", sugAuto = "Цель %s: добавляю ~%s: %s", overTag = " (сверх цели)",
           acc = { wait = "автопринятие: ждём предметы соперника", busy = "автопринятие: скрипт кладёт предметы", unk = "автопринятие: у тебя предметы без цены",
                   theirUnk = "автопринятие: у него предметы без цены", bad = "автопринятие: нежелательный предмет", low = "автопринятие: прибыль ниже цели (%d%%)",
                   hold = "автопринятие: проверка %d с", accept = "автопринятие: принимаю (+%d%%)", confirm = "автопринятие: подтверждаю (+%d%%)",
                   waitThem = "автопринятие: ждём, пока он примет", gaveup = "автопринятие: 6 попыток без результата" },
           declined = "Отклонено: %s", declTry = "Нежелательный предмет: %s — отказ", blockedTrade = "%s в блоке на 3 мин — отказ",
           blockedReq = "Отклонил запрос от %s (блок 3 мин)", requestAccepted = "Запрос на трейд от %s принят",
           giftDoing = "Подарок: ты ничего не отдаёшь — принимаю", junkWait = "У него только предметы без цены — отклоню через %d с",
           nudgeWait = "Он ничего не предлагает — через %d с покажу предмет", nudging = "Показываю ему предмет…",
           emptyWait = "Всё ещё пусто — отклоню через %d с", emptyCleared = "Он всё убрал — убираю и я",
           reqPlan = "Просит: %s", reqAdd = "добавь %s", reqRemove = "убери %s", reqDone = "Просьба выполнена", reqTooMuch = "Просит %s — это больше, чем он даёт",
           reqDoing = "Выполняю просьбу: %s", reqMissing = "нет в инвентаре: %s", ordApplied = "Заявка: %s за %s",
           gives = "даёт", wants = "хочет", forYou = "для тебя", items = "предметы", anyOffers = "любые предложения", asksAdd = "просит добавить",
           ordersSub = "%d заявок · что отдаёшь за предмет", ordNew = "+ Новая заявка", ordAddVar = "+ Вариант", ordDel = "Удалить заявку",
           ordPickTarget = "Выбери предмет, на который заявка", ordPickOffer = "Что отдаёшь за %s — нажимай на предметы",
           ordSave = "Сохранить", ordCancel = "Отмена", ordGive = "отдаёшь %s за %s", ordEmpty = "Выбери заявку слева или создай новую",
           ordNoVars = "Пока нет вариантов — добавь, что отдаёшь", noInv = "Инвентарь не прочитан",
           types = { pets = "Питомцы", eggs = "Яйца", vehicles = "Транспорт", strollers = "Коляски", toys = "Игрушки", ["pet wear"] = "Одежда",
                     food = "Еда", gifts = "Подарки", stickers = "Стикеры", other = "Другое" } },
    en = { you = "YOU", them = "THEM", win = "GAIN", good = "WIN", fair = "FAIR", bad = "LOSE", empty = "EMPTY",
           noPrice = "no price: %d", appTitle = "Adopt Me Values",
           tabMain = "General", tabTrade = "Trading", tabGame = "Player", tabChat = "Chat",
           enabled = "Script enabled", size = "Text size", scale = "Scale", theme = "Accent", font = "Font", lang = "Language",
           diff = "Show difference", details = "Item list in the bar", antiAfk = "Anti-AFK", antiFling = "Anti-fling",
           reset = "Reset bar position", diag = "Trade diagnostics", diagBtn = "Copy",
           diagDone = "Diagnostics copied — send it over", diagPrinted = "Diagnostics printed to console (F9)",
           valuesTitle = "Value list", calcTitle = "Calculator", open = "Open",
           loaded = "Prices loaded: %d · %s", failed = "Failed to load prices", noGame = "Adopt Me data not found — press Diagnostics",
           dryRun = "Test mode (don't press anything)", dryTag = "TEST: ", dryWarn = "Test mode: the script only says what it would do",
           auto = "Auto-offer", target = "Profit target", autoAdd = "Auto-add", tolerance = "Allow ±1%", fillOver = "Top up past target",
           autoAccept = "Auto-accept", mirrorEmpty = "Clear mine if they clear", emptyDecline = "Empty trade: show an item, then decline",
           junkDecline = "Decline junk (no value)", giftAccept = "Accept gifts", autoRequest = "Accept trade requests",
           bl = "Unwanted items", blCount = "%d items", autoDecline = "Auto-decline", orders = "Orders", ordersOn = "Orders enabled",
           chatAds = "Chat analysis", chatInTrade = "Show during a trade", chatRequests = "Follow chat requests", declineMsg = "Say why I decline in chat",
           search = "Search…", addYou = "+YOU", addThem = "+THEM", clear = "Clear", noVals = "no value", all = "All", marked = "Marked",
           varR = "Normal", varN = "Neon", varM = "Mega", potNp = "None", potR = "R", potF = "F", potFr = "FR",
           hint = "Tap an item above to remove it",
           sugWait = "Target %s: waiting for their items", sugOk = "Target %s reached", sugRemove = "Target %s: remove ~%s",
           sugNone = "Target %s: nothing fits (~%s)", sugAdd = "Target %s: add ~%s: %s", sugAuto = "Target %s: adding ~%s: %s", overTag = " (over target)",
           acc = { wait = "auto-accept: waiting for their items", busy = "auto-accept: adding items", unk = "auto-accept: you have unpriced items",
                   theirUnk = "auto-accept: they have unpriced items", bad = "auto-accept: unwanted item", low = "auto-accept: profit below target (%d%%)",
                   hold = "auto-accept: checking %d s", accept = "auto-accept: accepting (+%d%%)", confirm = "auto-accept: confirming (+%d%%)",
                   waitThem = "auto-accept: waiting for them to accept", gaveup = "auto-accept: 6 tries, no result" },
           declined = "Declined: %s", declTry = "Unwanted item: %s — declining", blockedTrade = "%s is blocked for 3 min — declining",
           blockedReq = "Declined request from %s (3 min block)", requestAccepted = "Trade request from %s accepted",
           giftDoing = "Gift: you give nothing — accepting", junkWait = "Only unpriced items — declining in %d s",
           nudgeWait = "They offer nothing — showing an item in %d s", nudging = "Showing them an item…",
           emptyWait = "Still empty — declining in %d s", emptyCleared = "They removed everything — removing mine",
           reqPlan = "Asks: %s", reqAdd = "add %s", reqRemove = "remove %s", reqDone = "Request done", reqTooMuch = "Asks %s — more than they give",
           reqDoing = "Doing the request: %s", reqMissing = "not in inventory: %s", ordApplied = "Order: %s for %s",
           gives = "gives", wants = "wants", forYou = "for you", items = "items", anyOffers = "any offers", asksAdd = "asks to add",
           ordersSub = "%d orders · what you give for an item", ordNew = "+ New order", ordAddVar = "+ Variant", ordDel = "Delete order",
           ordPickTarget = "Pick the item this order is for", ordPickOffer = "What you give for %s — tap items",
           ordSave = "Save", ordCancel = "Cancel", ordGive = "you give %s for %s", ordEmpty = "Pick an order on the left or create one",
           ordNoVars = "No variants yet — add what you give", noInv = "Inventory not read",
           types = { pets = "Pets", eggs = "Eggs", vehicles = "Vehicles", strollers = "Strollers", toys = "Toys", ["pet wear"] = "Pet wear",
                     food = "Food", gifts = "Gifts", stickers = "Stickers", other = "Other" } },
}
local function T(k) return (L[S.lang] or L.ru)[k] or L.ru[k] end

local function notify(text)
    pcall(function() StarterGui:SetCore("SendNotification", { Title = "AM Values", Text = text, Duration = 6 }) end)
end

------------------------------------------------------------------
-- Цены
------------------------------------------------------------------
local DB = { byName = {}, list = {}, byType = {}, count = 0, updated = "",
             TYPES = { "pets", "eggs", "vehicles", "strollers", "toys", "pet wear", "food", "gifts", "stickers", "other" } }

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
    function DB.byKey(key)
        local lst = DB.byName[key]
        return lst and lst[1] or nil
    end

    -- ключ предмета с вариантом: у питомцев «owl|n|fr», у остального просто «owl»
    function DB.ik(e, var, pot)
        if e and e.v then return e.key .. "|" .. (var or "r") .. "|" .. (pot or "fr") end
        return e and e.key or "?"
    end

    function DB.load()
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(VALUES_URL .. "?t=" .. os.time()))
        end)
        if not ok or type(res) ~= "table" or type(res.items) ~= "table" then
            warn("[AMTV] не загрузил цены:", res)
            return false
        end
        local byName, arr, byType = {}, {}, {}
        for _, e in ipairs(res.items) do
            if type(e) == "table" and e.name then
                e.key = DB.norm(e.name)
                byName[e.key] = byName[e.key] or {}
                table.insert(byName[e.key], e)
                table.insert(arr, e)
                byType[e.type] = byType[e.type] or {}
                table.insert(byType[e.type], e)
            end
        end
        local function cmp(a, b)
            local pa, pb = a.type == "pets", b.type == "pets"
            if pa ~= pb then return pa end
            return (DB.price(a, "r", "fr") or -1) > (DB.price(b, "r", "fr") or -1)
        end
        table.sort(arr, cmp)
        for _, lst in pairs(byType) do table.sort(lst, cmp) end
        DB.byName, DB.list, DB.byType, DB.count = byName, arr, byType, #arr
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
-- Данные игры: трейд и инвентарь из клиентских модулей Adopt Me (Fsys),
-- действия — через RouterClient (TradeAPI/...)
------------------------------------------------------------------
local AM = { ok = false, remotes = {} }

;(function()
    -- категории инвентаря Adopt Me -> типы elvebredd
    local CAT = { pets = "pets", toys = "toys", pet_accessories = "pet wear", transport = "vehicles",
                  strollers = "strollers", food = "food", gifts = "gifts", stickers = "stickers" }
    AM.CAT = CAT

    function AM.init()
        local ok, load = pcall(function()
            return require(RS:WaitForChild("Fsys", 15)).load
        end)
        if not ok or type(load) ~= "function" then return false end
        local ok1, cd = pcall(load, "ClientData")
        local ok2, idb = pcall(load, "InventoryDB")
        local ok3, router = pcall(load, "RouterClient")
        AM.CD = ok1 and cd or nil
        AM.IDB = ok2 and idb or nil
        AM.Router = ok3 and router or nil
        AM.ok = AM.CD ~= nil
        return AM.ok
    end

    -- RemoteEvent/RemoteFunction по имени «TradeAPI/...»
    function AM.remote(name)
        if AM.remotes[name] ~= nil then return AM.remotes[name] or nil end
        local r = false
        if AM.Router and type(AM.Router.get) == "function" then
            local ok, res = pcall(AM.Router.get, name)
            if ok and typeof(res) == "Instance" then r = res end
        end
        AM.remotes[name] = r
        return r or nil
    end
    function AM.call(name, ...)
        local r = AM.remote(name)
        if not r then return false end
        local args = table.pack(...)
        return (pcall(function()
            if r:IsA("RemoteFunction") then r:InvokeServer(table.unpack(args, 1, args.n))
            else r:FireServer(table.unpack(args, 1, args.n)) end
        end))
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
    local function field(key)
        local d = AM.data()
        if d and d[key] ~= nil then return d[key] end
        local cd = AM.CD
        if cd and type(cd.get) == "function" then
            local ok, v = pcall(cd.get, key)
            if ok then return v end
        end
        return nil
    end

    function AM.trade()
        local t = AM.CD and field("trade")
        return type(t) == "table" and t or nil
    end

    function AM.isMe(p)
        if p == LP then return true end
        if type(p) == "string" then return p == LP.Name end
        if typeof(p) == "Instance" then return p == LP end
        if type(p) == "table" then return p.Name == LP.Name or p.name == LP.Name or p.user_id == LP.UserId end
        return false
    end
    function AM.nameOf(p)
        if typeof(p) == "Instance" then return p.Name end
        if type(p) == "table" then return p.Name or p.name or "?" end
        return tostring(p or "?")
    end

    -- mine, theirs, partner или nil
    function AM.offers(t)
        if type(t) ~= "table" then return nil end
        local so, ro = t.sender_offer, t.recipient_offer
        if type(so) ~= "table" or type(ro) ~= "table" then return nil end
        if AM.isMe(t.recipient) then
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

    -- предмет -> { uid, name, var, pot, typ, entry, price, pet, ik }
    function AM.describe(it, uid)
        local p = type(it.properties) == "table" and it.properties or {}
        local var = (p.mega_neon and "m") or (p.neon and "n") or "r"
        local fly, ride = p.flyable and true or false, p.rideable and true or false
        local pot = (fly and ride and "fr") or (fly and "f") or (ride and "r") or "np"
        local name = AM.itemName(it)
        local typ = CAT[it.category or ""]
        local e = DB.find(name, typ)
        local d = { uid = it.unique or (type(uid) == "string" and uid) or nil, name = name, var = var, pot = pot, typ = typ,
                    entry = e, price = DB.price(e, var, pot), pet = e ~= nil and e.v ~= nil, raw = it }
        d.ik = e and DB.ik(e, d.var, d.pot) or ("?" .. DB.norm(name))
        d.key = e and e.key or DB.norm(name)
        return d
    end

    function AM.sum(offer)
        local items = type(offer) == "table" and offer.items or nil
        local total, unk, out = 0, 0, {}
        if type(items) ~= "table" then return 0, 0, out end
        for k, it in pairs(items) do
            if type(it) == "table" then
                local d = AM.describe(it, k)
                table.insert(out, d)
                if d.price then total += d.price else unk += 1 end
            end
        end
        table.sort(out, function(a, b) return (a.price or -1) > (b.price or -1) end)
        return total, unk, out
    end

    -- свои предметы с ценой, которых ещё нет в оффере (кандидаты для автооффера)
    function AM.inventory(exclude)
        local inv = field("inventory")
        local out = {}
        if type(inv) ~= "table" then return out, false end
        for cat, items in pairs(inv) do
            if CAT[cat] and type(items) == "table" then
                for uid, it in pairs(items) do
                    if type(it) == "table" then
                        if it.category == nil then it = setmetatable({ category = cat }, { __index = it }) end
                        local d = AM.describe(it, uid)
                        if d.uid and d.price and d.price > 0 and not (exclude and exclude[d.uid]) then
                            table.insert(out, d)
                        end
                    end
                end
            end
        end
        table.sort(out, function(a, b) return a.price > b.price end)
        return out, true
    end

    -- этап трейда: «negotiation» (выбор) или «confirmation» (подтверждение)
    function AM.stage(t)
        local s = tostring(t and (t.current_stage or t.stage) or ""):lower()
        if s:find("confirm") then return "confirm" end
        return "negotiate"
    end
    function AM.flags(offer)
        offer = type(offer) == "table" and offer or {}
        return offer.negotiated and true or false, offer.confirmed and true or false
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

    AM.REMOTES = { "TradeAPI/AddItemToOffer", "TradeAPI/RemoveItemFromOffer", "TradeAPI/AcceptNegotiation", "TradeAPI/ConfirmTrade",
                   "TradeAPI/DeclineTrade", "TradeAPI/AcceptOrDeclineTradeRequest", "TradeAPI/TradeRequestReceived" }
    function AM.diagnostics()
        local lines = { "AMTV diag", "Fsys ok: " .. tostring(AM.ok), "IDB: " .. tostring(AM.IDB ~= nil), "Router: " .. tostring(AM.Router ~= nil) }
        for _, n in ipairs(AM.REMOTES) do
            local r = AM.remote(n)
            table.insert(lines, n .. ": " .. (r and r.ClassName or "nil"))
        end
        local d = AM.data()
        if d then
            local keys = {}
            for k in pairs(d) do table.insert(keys, tostring(k)) end
            table.sort(keys)
            table.insert(lines, "data keys: " .. table.concat(keys, ", "))
            local inv = type(d.inventory) == "table" and d.inventory or nil
            if inv then
                local cats = {}
                for k in pairs(inv) do table.insert(cats, tostring(k)) end
                table.insert(lines, "inventory cats: " .. table.concat(cats, ", "))
                local n = 0
                for uid, p in pairs(type(inv.pets) == "table" and inv.pets or {}) do
                    n += 1; if n > 2 then break end
                    table.insert(lines, "pet " .. tostring(uid) .. ": " .. AM.dump(p, 1))
                end
            end
        else
            table.insert(lines, "data: nil")
        end
        local t = AM.trade()
        table.insert(lines, "trade: " .. AM.dump(t))
        local mine = AM.offers(t)
        if mine then
            local _, _, out = AM.sum(mine)
            for _, x in ipairs(out) do table.insert(lines, ("mine: %s %s%s = %s"):format(x.name, x.var, x.pot, tostring(x.price))) end
        end
        local text = table.concat(lines, "\n")
        if setclipboard then pcall(setclipboard, text); notify(T("diagDone"))
        else print(text); notify(T("diagPrinted")) end
    end
end)()

------------------------------------------------------------------
-- Помощники интерфейса
------------------------------------------------------------------
local onTheme = {}  -- что перекрашивать при смене акцента / шрифта
local function themed(fn) table.insert(onTheme, fn); fn() end

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
-- надпись; bold = цифры/заголовки
local function label(parent, props, bold)
    local t = new("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = C.text, TextSize = 14, RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    }, parent)
    for k, v in pairs(props or {}) do t[k] = v end
    themed(function() t.Font = bold and fontBold() or fontReg() end)
    return t
end
-- надпись без подписки на тему (для строк списков, которые часто пересоздаются)
local function plain(parent, props, bold)
    local t = new("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = C.text, TextSize = 13, RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "", Font = bold and fontBold() or fontReg(),
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
local function esc(s) return (tostring(s):gsub("<", "&lt;")) end

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
-- «NFR Owl» без цвета (для чата и подсказок)
local function plainName(name, var, pot, pet)
    if not pet then return name end
    local tag = ((var == "m" and "M") or (var == "n" and "N") or "") .. (({ fr = "FR", f = "F", r = "R", np = "" })[pot] or "")
    return tag ~= "" and (tag .. " " .. name) or name
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
        local items = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 4, TextXAlignment = xa, Visible = false })
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

    -- строка автооффера / действий скрипта
    H.sugLine = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.2, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 2, Visible = false }, hud)
    corner(H.sugLine, 8)
    pad(H.sugLine, 10, 4)
    H.sugText = label(H.sugLine, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 13 })
    -- строка автопринятия
    H.accLine = label(hud, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 12, TextColor3 = C.muted, LayoutOrder = 3, Visible = false })
    -- значок тестового режима
    H.dry = label(hud, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 11, TextColor3 = C.test, LayoutOrder = 4, Visible = false })

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
        H.dry.Text = "🧪 " .. T("dryWarn")
    end

    function H.sug(text, col)
        H.sugLine.Visible = text ~= nil
        if text then H.sugText.Text = col and ('<font color="%s">%s</font>'):format(hex(col), text) or text end
    end

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
            local bl = S.blacklist[d.key] and (' <font color="%s">✕</font>'):format(hex(C.bad)) or ""
            local price = d.price and fmt(d.price) or ('<font color="%s">?</font>'):format(hex(C.muted))
            table.insert(lines, ("%s%s%s  <b>%s</b>"):format(tag ~= "" and (tag .. " ") or "", esc(d.name), bl, price))
        end
        side.items.Text = table.concat(lines, "\n")
        side.items.Visible = true
    end

    function H.render(v)
        local share, pct, col, status = verdict(v.my, v.th)
        local diff = v.th - v.my
        H.you.val.Text = fmt(v.my)
        local ds = ""
        if S.showDiff and v.my + v.th > 0 and math.abs(diff) > 0.001 then
            ds = (' <font color="%s" size="%d">%s%s</font>'):format(hex(diff > 0 and C.good or C.bad), math.max(10, S.textSize - 2), diff > 0 and "+" or "−", fmt(math.abs(diff)))
        end
        H.them.val.Text = fmt(v.th) .. ds
        setNote(H.you, v.myUnk)
        setNote(H.them, v.thUnk)
        setItems(H.you, v.myItems)
        setItems(H.them, v.thItems)
        H.win.Text = ('<font color="%s">%s %d%%</font>'):format(hex(col), T("win"), pct)
        H.status.Text = status
        H.status.TextColor3 = col
        tween(H.fill, 0.3, { Size = UDim2.fromScale(math.clamp(share, 0.03, 1), 1) })
        H.grad.Color = ColorSequence.new(col:Lerp(C.text, 0.3), col)
        H.dry.Visible = S.dryRun and (S.autoOffer or S.autoAccept or S.autoDecline or S.autoRequest or S.emptyDecline or S.junkDecline or S.giftAccept or S.ordersOn)
    end
end)()

------------------------------------------------------------------
-- Кнопка 🐾, окно настроек с вкладками
------------------------------------------------------------------
local W = { rows = {}, pages = {} }

;(function()
    local gear = new("TextButton", {
        Size = UDim2.fromOffset(46, 46), Position = UDim2.fromScale(S.iconX, S.iconY),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Text = "🐾", TextSize = 22,
        Font = Enum.Font.GothamBold, TextColor3 = C.text, AutoButtonColor = false,
    }, ui)
    corner(gear, 23)
    local ring = stroke(gear, accent(), 0.35, 1.5)
    themed(function() ring.Color = S.enabled and accent() or C.muted end)
    W.gear = gear
    W.gearScale = new("UIScale", {}, gear)

    local panel = new("Frame", {
        Size = UDim2.fromOffset(460, 0), AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Visible = false,
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.04,
    }, ui)
    corner(panel, 18)
    stroke(panel)
    pad(panel, 16, 16)
    list(panel, Enum.FillDirection.Vertical, 8)
    W.panel = panel
    W.scale = new("UIScale", {}, panel)

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
    local TABS = { "tabMain", "tabTrade", "tabGame", "tabChat" }
    local tabBar = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card, BackgroundTransparency = 0.3, LayoutOrder = 1 }, panel)
    corner(tabBar, 10)
    stroke(tabBar)
    local knob = new("Frame", { Size = UDim2.new(1 / #TABS, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = accent() }, tabBar)
    corner(knob, 8)
    themed(function() knob.BackgroundColor3 = accent() end)
    W.tabs, W.bodies = {}, {}
    for i, key in ipairs(TABS) do
        -- тело вкладки прокручивается: вкладка «Трейд» длинная
        local b = new("ScrollingFrame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 2, Visible = i == 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, panel)
        corner(b, 12)
        stroke(b)
        local lay = list(b, Enum.FillDirection.Vertical, 0, Enum.HorizontalAlignment.Center)
        local function fit() b.Size = UDim2.new(1, 0, 0, math.min(lay.AbsoluteContentSize.Y + 4, 430)) end
        on(lay:GetPropertyChangedSignal("AbsoluteContentSize"), fit)
        task.defer(fit)
        themed(function() b.ScrollBarImageColor3 = accent() end)
        W.bodies[i] = b
        local tb = new("TextButton", { Size = UDim2.fromScale(1 / #TABS, 1), Position = UDim2.fromScale((i - 1) / #TABS, 0), BackgroundTransparency = 1,
            Text = "", TextColor3 = C.text, TextSize = 13, ZIndex = 2 }, tabBar)
        themed(function() tb.Font = fontBold() end)
        W.tabs[i] = { btn = tb, key = key }
        on(tb.MouseButton1Click, function()
            for j, bd in ipairs(W.bodies) do bd.Visible = j == i end
            tween(knob, 0.25, { Position = UDim2.new((i - 1) / #TABS, 3, 0, 3) })
        end)
    end

    W.footer = label(panel, { Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 9 })

    function W.anyPage()
        for _, p in pairs(W.pages) do if p.Visible then return p end end
    end
    makeDraggable(gear, gear, function()
        local p = W.anyPage()
        if p then for _, pg in pairs(W.pages) do pg.Visible = false end; return end
        panel.Visible = not panel.Visible
        if panel.Visible then
            W.relabel()
            W.scale.Scale = sf() * 0.92
            tween(W.scale, 0.25, { Scale = sf() }, Enum.EasingStyle.Back)
        end
    end, function()
        local abs = ui.AbsoluteSize
        S.iconX, S.iconY = gear.AbsolutePosition.X / abs.X, gear.AbsolutePosition.Y / abs.Y
        gear.Position = UDim2.fromScale(S.iconX, S.iconY)
        saveSettings()
    end)

    -- ряды настроек
    local counts = {}
    function W.row(tab, key)
        local body = W.bodies[tab]
        counts[tab] = (counts[tab] or 0) + 1
        local n = counts[tab]
        if n > 1 then
            new("Frame", { BackgroundColor3 = C.line, BackgroundTransparency = 0.94, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 1), LayoutOrder = n * 2 - 1 }, body)
        end
        local r = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = n * 2 }, body)
        pad(r, 12, 0)
        local name = label(r, { Size = UDim2.new(1, -130, 1, 0), TextSize = 14, TextWrapped = true })
        table.insert(W.rows, { name, key })
        return r, name
    end
    function W.control(parent, w)
        local f = new("Frame", {
            Size = UDim2.fromOffset(w, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = C.bg, BackgroundTransparency = 0.2,
        }, parent)
        corner(f, 9)
        stroke(f)
        return f
    end
    function W.flatBtn(parent, text, size, pos)
        local b = new("TextButton", {
            Size = size, Position = pos, BackgroundColor3 = C.bg, BackgroundTransparency = 1,
            Text = text, TextColor3 = C.text, TextSize = 16, AutoButtonColor = false,
        }, parent)
        themed(function() b.Font = fontBold() end)
        corner(b, 8)
        return b
    end
    -- переключатель; draw() перерисовывает по текущему S[setting]
    function W.makeToggle(parent, get, set)
        local t = new("TextButton", {
            Size = UDim2.fromOffset(46, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = rgb(60, 62, 74), Text = "", AutoButtonColor = false,
        }, parent)
        corner(t, 13)
        local k = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = rgb(255, 255, 255) }, t)
        corner(k, 10)
        local function draw()
            local st = get()
            tween(t, 0.2, { BackgroundColor3 = st and accent() or rgb(60, 62, 74) })
            tween(k, 0.2, { Position = st and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
        end
        themed(draw)
        on(t.MouseButton1Click, function() set(not get()); saveSettings(); draw() end)
        return t, draw
    end
    function W.toggle(tab, key, setting, after)
        local r = W.row(tab, key)
        return W.makeToggle(r, function() return S[setting] end, function(v)
            S[setting] = v
            if after then after() end
        end)
    end
    function W.stepper(tab, key, show, dec, inc)
        local r = W.row(tab, key)
        local box = W.control(r, 108)
        local minus = W.flatBtn(box, "−", UDim2.fromOffset(32, 30), UDim2.fromOffset(0, 0))
        local val = label(box, { Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(32, 0), TextXAlignment = Enum.TextXAlignment.Center }, true)
        local plus = W.flatBtn(box, "+", UDim2.fromOffset(32, 30), UDim2.new(1, -32, 0, 0))
        themed(function() val.Text = show() end)
        on(minus.MouseButton1Click, function() dec(); saveSettings(); val.Text = show() end)
        on(plus.MouseButton1Click, function() inc(); saveSettings(); val.Text = show() end)
        return val
    end
    -- кнопка «Открыть  >» справа в ряду
    function W.openBtn(tab, key, textFn, onClick)
        local r = W.row(tab, key)
        local b = new("TextButton", { Size = UDim2.fromOffset(110, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false }, r)
        corner(b, 9)
        local st = stroke(b, accent(), 0.5)
        themed(function() b.Font = fontBold(); st.Color = accent(); b.Text = textFn() end)
        on(b.MouseButton1Click, onClick)
        return b
    end

    -- общая заготовка большого окна (таблица цен, нежелательные, калькулятор, заявки)
    function W.page(id, w, h)
        local page = new("Frame", { Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Visible = false, BackgroundColor3 = C.bg, BackgroundTransparency = 0.04 }, ui)
        corner(page, 18)
        stroke(page)
        pad(page, 16, 16)
        local sc = new("UIScale", {}, page)
        W.pages[id] = page
        local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) }, page)
        local back = new("TextButton", { Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.card, Text = "<", TextColor3 = C.text,
            TextSize = 18, Font = Enum.Font.GothamBold, AutoButtonColor = false }, head)
        corner(back, 16)
        stroke(back)
        local title = label(head, { Size = UDim2.new(1, -270, 0, 18), Position = UDim2.fromOffset(44, 0), TextSize = 16 }, true)
        local sub = label(head, { Size = UDim2.new(1, -270, 0, 14), Position = UDim2.fromOffset(44, 19), TextSize = 12, TextColor3 = C.muted })
        makeDraggable(title, page)
        local P = { frame = page, head = head, title = title, sub = sub, back = back }
        function P.show(from)
            P.from = from
            for _, pg in pairs(W.pages) do pg.Visible = false end
            panel.Visible = false
            page.AnchorPoint, page.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
            page.Visible = true
            local abs = ui.AbsoluteSize
            local target = math.min(sf(), (abs.X - 24) / (w + 32), (abs.Y - 24) / (h + 32))
            sc.Scale = target * 0.94
            tween(sc, 0.25, { Scale = target }, Enum.EasingStyle.Back)
        end
        function P.close()
            page.Visible = false
            if P.from then P.from.show() else panel.Visible = true; W.relabel() end
        end
        on(back.MouseButton1Click, function() P.close() end)
        return P
    end

    function W.scroll(parent, size, pos)
        local sc = new("ScrollingFrame", { Size = size, Position = pos, BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, parent)
        list(sc, Enum.FillDirection.Vertical, 4)
        themed(function() sc.ScrollBarImageColor3 = accent() end)
        return sc
    end
    function W.clear(sc) for _, c in ipairs(sc:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
    function W.btn(parent, text, size, pos, color)
        local b = new("TextButton", { Size = size, Position = pos, BackgroundColor3 = color or C.card, BackgroundTransparency = 0.2,
            Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false }, parent)
        corner(b, 9)
        stroke(b)
        return b
    end
    -- переключатель вариантов (Обычный / Neon / Mega, Без / R / F / FR)
    function W.segmented(parent, opts, get, set, size, pos)
        local f = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Size = size, Position = pos or UDim2.new() }, parent)
        corner(f, 9)
        stroke(f)
        local btns = {}
        local function draw()
            for _, x in ipairs(btns) do
                x.b.Text = T(x.o[2])
                x.b.BackgroundColor3 = accent()
                x.b.BackgroundTransparency = get() == x.o[1] and 0 or 1
            end
        end
        for i, o in ipairs(opts) do
            local b = new("TextButton", { Size = UDim2.new(1 / #opts, -4, 1, -4), Position = UDim2.new((i - 1) / #opts, 2, 0, 2),
                BackgroundColor3 = accent(), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 13,
                Font = Enum.Font.GothamBold, AutoButtonColor = false }, f)
            corner(b, 7)
            btns[i] = { b = b, o = o }
            on(b.MouseButton1Click, function() set(o[1]); saveSettings(); draw() end)
        end
        themed(draw)
        return f, draw
    end
end)()

------------------------------------------------------------------
-- Окно-список предметов: таблица цен / нежелательные / выбор предметов
------------------------------------------------------------------
local Picker = {}

;(function()
    local PW, PH, SIDE = 640, 480, 150
    local P = W.page("list", PW, PH)
    local mode = "values" -- values | bl | pick
    local curCat = "pets"
    local pickVar, pickPot = "r", "fr"

    -- справа в шапке: автоотклонение (в режиме bl) или варианты (в режиме pick)
    local declBox = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.fromOffset(210, 34),
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0) }, P.head)
    corner(declBox, 10)
    stroke(declBox)
    pad(declBox, 10, 0)
    local lDecl = label(declBox, { Size = UDim2.new(1, -54, 1, 0), TextSize = 13 })
    local _, drawDecl = W.makeToggle(declBox, function() return S.autoDecline end, function(v) S.autoDecline = v end)

    local side = new("ScrollingFrame", { Size = UDim2.new(0, SIDE, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundColor3 = C.card,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, P.frame)
    corner(side, 12)
    stroke(side)
    pad(side, 6, 6)
    list(side, Enum.FillDirection.Vertical, 2)

    local right = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -SIDE - 12, 1, -46), Position = UDim2.fromOffset(SIDE + 12, 46) }, P.frame)
    local search = new("TextBox", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Text = "",
        PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 14, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, right)
    corner(search, 9)
    stroke(search)
    pad(search, 10, 0)
    themed(function() search.Font = fontReg() end)
    -- варианты для режима выбора
    local segV = W.segmented(right, { { "r", "varR" }, { "n", "varN" }, { "m", "varM" } }, function() return pickVar end, function(v) pickVar = v; Picker.render() end,
        UDim2.new(0.5, -4, 0, 28), UDim2.fromOffset(0, 38))
    local segP = W.segmented(right, { { "np", "potNp" }, { "r", "potR" }, { "f", "potF" }, { "fr", "potFr" } }, function() return pickPot end, function(v) pickPot = v; Picker.render() end,
        UDim2.new(0.5, -4, 0, 28), UDim2.new(0.5, 4, 0, 38))
    local scroll = W.scroll(right, UDim2.new(1, 0, 1, -40), UDim2.fromOffset(0, 40))
    -- нижняя строка выбора: сумма и кнопки
    local bottom = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 76), Position = UDim2.new(0, 0, 1, -76), Visible = false }, right)
    local pSum = label(bottom, { Size = UDim2.new(1, 0, 0, 32), TextSize = 12, TextWrapped = true, TextColor3 = C.muted })
    local pSave = W.btn(bottom, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0, 0, 1, -38), C.good)
    local pCancel = W.btn(bottom, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0.5, 4, 1, -38))

    local pick -- { single = bool, items = {}, onDone = fn }

    local function blCount()
        local n = 0
        for _ in pairs(S.blacklist) do n += 1 end
        return n
    end

    local function source()
        if curCat == "marked" then
            local out = {}
            for _, e in ipairs(DB.list) do if S.blacklist[e.key] then table.insert(out, e) end end
            return out
        elseif curCat == "all" then
            return DB.list
        end
        return DB.byType[curCat] or {}
    end

    local function pickSumText()
        local parts, sum = {}, 0
        for _, it in ipairs(pick.items) do
            local e = DB.byKey(it.key)
            table.insert(parts, plainName(it.name, it.var, it.pot, e and e.v ~= nil) .. (it.count > 1 and (" x" .. it.count) or ""))
            sum += (DB.price(e, it.var, it.pot) or 0) * it.count
        end
        return table.concat(parts, ", "), sum
    end

    local function itemRow(e, order)
        local marked = mode == "bl" and S.blacklist[e.key] ~= nil
        local r = new("TextButton", { Size = UDim2.new(1, -6, 0, 38), BackgroundColor3 = C.card, BackgroundTransparency = marked and 0.1 or 0.6,
            ClipsDescendants = true, Text = "", AutoButtonColor = false, LayoutOrder = order }, scroll)
        corner(r, 9)
        pad(r, 8, 0)
        local typ = (T("types") or {})[e.type] or e.type
        plain(r, { Size = UDim2.new(1, -230, 1, 0), TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = ('%s <font color="%s" size="11">%s</font>'):format(esc(e.name), hex(C.muted), curCat == "all" and typ or "") }, true)
        local rightPad = mode == "bl" and 30 or 0
        if mode == "values" and e.v then
            -- обычный / neon / mega (зелья — как выбрано в калькуляторе)
            local pot = S.calcPot
            local cols = { { "r", C.text }, { "n", C.neon }, { "m", C.mega } }
            for i, c in ipairs(cols) do
                local p = DB.price(e, c[1], pot)
                plain(r, { Size = UDim2.fromOffset(70, 38), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(3 - i) * 72, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = c[2], TextSize = 13, Text = p and fmt(p) or "-" }, true)
            end
        else
            local p = mode == "pick" and DB.price(e, pickVar, pickPot) or DB.price(e, "r", "fr")
            plain(r, { Size = UDim2.fromOffset(80, 38), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -rightPad, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = p and C.text or C.muted, TextSize = 13,
                Text = p and fmt(p) or T("noVals") }, true)
        end
        if mode == "bl" then
            local box = new("Frame", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0),
                BackgroundColor3 = marked and accent() or C.bg, BackgroundTransparency = marked and 0 or 0.3 }, r)
            corner(box, 6)
            stroke(box, marked and accent() or C.line, marked and 0 or 0.8)
            on(r.MouseButton1Click, function()
                if S.blacklist[e.key] then S.blacklist[e.key] = nil else S.blacklist[e.key] = e.name end
                saveSettings()
                Picker.render()
            end)
        elseif mode == "pick" then
            on(r.MouseButton1Click, function()
                local var, pot = e.v and pickVar or "r", e.v and pickPot or "fr"
                if e.v and not e.v[var] then var = "r" end
                if pick.single then
                    local cb = pick.onDone
                    pick = nil
                    P.close()
                    cb({ key = e.key, name = e.name, var = var, pot = pot })
                    return
                end
                local found
                for _, it in ipairs(pick.items) do
                    if it.key == e.key and it.var == var and it.pot == pot then found = it end
                end
                if found then found.count += 1 else table.insert(pick.items, { key = e.key, name = e.name, var = var, pot = pot, count = 1 }) end
                local txt, sum = pickSumText()
                pSum.Text = txt .. "  =  " .. fmt(sum)
            end)
        end
    end

    function Picker.render()
        W.clear(scroll)
        local q = DB.norm(search.Text)
        local shown = 0
        for _, e in ipairs(source()) do
            if q == "" or e.key:find(q, 1, true) then
                shown += 1
                if shown > 120 then break end
                itemRow(e, shown)
            end
        end
        if mode == "bl" then P.sub.Text = T("blCount"):format(blCount())
        elseif mode == "values" then P.sub.Text = "elvebredd.com · " .. DB.count .. " · " .. DB.updated
        else P.sub.Text = "" end
    end

    local function renderSide()
        W.clear(side)
        local entries = {}
        if mode == "bl" then table.insert(entries, { "marked", T("marked") .. " (" .. blCount() .. ")" }) end
        table.insert(entries, { "all", T("all") })
        for _, t in ipairs(DB.TYPES) do
            if DB.byType[t] then table.insert(entries, { t, (T("types") or {})[t] or t }) end
        end
        for i, e in ipairs(entries) do
            local active = e[1] == curCat
            local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = accent(), BackgroundTransparency = active and 0.75 or 1,
                Text = e[2], TextColor3 = active and accent():Lerp(rgb(255, 255, 255), 0.4) or C.text, TextSize = 14,
                Font = active and fontBold() or fontReg(), TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i }, side)
            corner(b, 8)
            pad(b, 10, 0)
            on(b.MouseButton1Click, function() curCat = e[1]; search.Text = ""; renderSide(); Picker.render() end)
        end
    end

    local pending = false
    on(search:GetPropertyChangedSignal("Text"), function()
        if pending or not P.frame.Visible then return end
        pending = true
        task.delay(0.2, function() pending = false; pcall(Picker.render) end)
    end)

    -- m = values | bl | pick; opts для pick: { single, title, items, onDone, from }
    function Picker.open(m, opts)
        mode = m
        pick = m == "pick" and { single = opts.single, items = opts.items or {}, onDone = opts.onDone } or nil
        if mode ~= "bl" and curCat == "marked" then curCat = "pets" end
        P.title.Text = m == "bl" and T("bl") or (m == "values" and T("valuesTitle") or (opts.title or ""))
        declBox.Visible = m == "bl"
        lDecl.Text = T("autoDecline")
        drawDecl()
        search.PlaceholderText = T("search")
        segV.Visible, segP.Visible = m == "pick", m == "pick"
        bottom.Visible = m == "pick" and not opts.single
        local top = m == "pick" and 72 or 40
        local bot = (m == "pick" and not opts.single) and 80 or 0
        scroll.Position, scroll.Size = UDim2.fromOffset(0, top), UDim2.new(1, 0, 1, -top - bot)
        if pick and not pick.single then
            pSave.Text, pCancel.Text = T("ordSave"), T("ordCancel")
            local txt, sum = pickSumText()
            pSum.Text = #pick.items > 0 and (txt .. "  =  " .. fmt(sum)) or ""
        end
        search.Text = ""
        renderSide()
        Picker.render()
        P.show(opts and opts.from)
    end
    on(pSave.MouseButton1Click, function()
        if not pick then return end
        local cb, items = pick.onDone, pick.items
        pick = nil
        P.close()
        cb(items)
    end)
    on(pCancel.MouseButton1Click, function() pick = nil; P.close() end)
end)()

------------------------------------------------------------------
-- Калькулятор: собрать трейд вручную и сравнить
------------------------------------------------------------------
local Calc = {}

;(function()
    local P = W.page("calc", 560, 520)
    local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -44), Position = UDim2.fromOffset(0, 44) }, P.frame)
    list(body, Enum.FillDirection.Vertical, 8)
    local sides = { you = {}, them = {} }
    local boxes, heads = {}, {}

    local cols = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 140), LayoutOrder = 1 }, body)
    for i, side in ipairs({ "you", "them" }) do
        local col = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0) }, cols)
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

    local renderResults
    local segRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 4 }, body)
    W.segmented(segRow, { { "r", "varR" }, { "n", "varN" }, { "m", "varM" } }, function() return S.calcVar end, function(v) S.calcVar = v; renderResults() end,
        UDim2.new(0.5, -4, 1, 0))
    W.segmented(segRow, { { "np", "potNp" }, { "r", "potR" }, { "f", "potF" }, { "fr", "potFr" } }, function() return S.calcPot end, function(v) S.calcPot = v; renderResults() end,
        UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0))

    local bar = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 5 }, body)
    local search = new("TextBox", { Size = UDim2.new(1, -110, 1, 0), BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Text = "",
        PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 14, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, bar)
    corner(search, 9)
    stroke(search)
    pad(search, 10, 0)
    themed(function() search.Font = fontReg() end)
    local clearBtn = W.btn(bar, "", UDim2.new(0, 102, 1, 0), UDim2.new(1, -102, 0, 0))
    clearBtn.TextColor3 = C.bad

    local results = W.scroll(body, UDim2.new(1, 0, 0, 190), UDim2.new())
    results.LayoutOrder = 6

    local renderSides
    local function chip(side, idx, x)
        local p = DB.price(x.e, x.var, x.pot)
        local b = new("TextButton", { Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, Text = "", AutoButtonColor = false, LayoutOrder = idx }, boxes[side])
        corner(b, 6)
        local tag = varTag(x.var, x.pot, x.e.v ~= nil)
        plain(b, { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(6, 0), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = (tag ~= "" and (tag .. " ") or "") .. esc(x.e.name) })
        plain(b, { Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -64, 0, 0), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
            Text = p and fmt(p) or "?" }, true)
        on(b.MouseButton1Click, function() table.remove(sides[side], idx); renderSides() end)
    end
    renderSides = function()
        local tot = {}
        for _, side in ipairs({ "you", "them" }) do
            W.clear(boxes[side])
            local s = 0
            for i, x in ipairs(sides[side]) do chip(side, i, x); s += DB.price(x.e, x.var, x.pot) or 0 end
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

    renderResults = function()
        W.clear(results)
        local q = DB.norm(search.Text)
        local shown = 0
        for _, e in ipairs(DB.list) do
            if q == "" and e.type ~= "pets" then break end
            if q == "" or e.key:find(q, 1, true) then
                shown += 1
                if shown > 60 then break end
                local r = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.45, Size = UDim2.new(1, -6, 0, 30), LayoutOrder = shown }, results)
                corner(r, 7)
                local typ = (T("types") or {})[e.type] or e.type
                plain(r, { Size = UDim2.new(1, -230, 1, 0), Position = UDim2.fromOffset(8, 0), TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = ('%s <font color="%s" size="11">%s</font>'):format(esc(e.name), hex(C.muted), typ) })
                local p = DB.price(e, e.v and S.calcVar or "r", e.v and S.calcPot or "fr")
                plain(r, { Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -220, 0, 0), TextXAlignment = Enum.TextXAlignment.Right,
                    Text = p and fmt(p) or ('<font color="%s">%s</font>'):format(hex(C.muted), T("noVals")) }, true)
                for i, side in ipairs({ "you", "them" }) do
                    local b = new("TextButton", { Size = UDim2.fromOffset(60, 24), Position = UDim2.new(1, -132 + (i - 1) * 66, 0.5, -12),
                        BackgroundColor3 = i == 1 and C.bg or accent(), Text = T(i == 1 and "addYou" or "addThem"), TextColor3 = C.text,
                        TextSize = 12, Font = fontBold(), AutoButtonColor = true }, r)
                    corner(b, 6)
                    on(b.MouseButton1Click, function() addTo(side, e) end)
                end
            end
        end
    end

    local pending = false
    on(search:GetPropertyChangedSignal("Text"), function()
        if pending then return end
        pending = true
        task.delay(0.25, function() pending = false; pcall(renderResults) end)
    end)
    on(clearBtn.MouseButton1Click, function() sides.you, sides.them = {}, {}; renderSides() end)

    function Calc.open()
        P.title.Text = T("calcTitle")
        P.sub.Text = "elvebredd.com · " .. DB.updated
        search.PlaceholderText = T("search")
        clearBtn.Text = T("clear")
        hintLine.Text = T("hint")
        pcall(renderResults)
        pcall(renderSides)
        P.show()
    end
end)()

------------------------------------------------------------------
-- Окно «Заявки»: на какой предмет (слева) что отдаёшь (варианты справа)
------------------------------------------------------------------
local Orders = {}

;(function()
    local PW, PH, SIDE = 640, 480, 210
    local P = W.page("orders", PW, PH)
    local onBox = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.fromOffset(210, 34),
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0) }, P.head)
    corner(onBox, 10)
    stroke(onBox)
    pad(onBox, 10, 0)
    local onLbl = label(onBox, { Size = UDim2.new(1, -54, 1, 0), TextSize = 13 })
    local _, drawOn = W.makeToggle(onBox, function() return S.ordersOn end, function(v) S.ordersOn = v end)

    local left = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(0, SIDE, 1, -46), Position = UDim2.fromOffset(0, 46) }, P.frame)
    corner(left, 12)
    stroke(left)
    local newBtn = W.btn(left, "", UDim2.new(1, -12, 0, 34), UDim2.fromOffset(6, 6))
    local side = W.scroll(left, UDim2.new(1, -12, 1, -52), UDim2.fromOffset(6, 46))

    local right = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -SIDE - 12, 1, -46), Position = UDim2.fromOffset(SIDE + 12, 46) }, P.frame)
    local rTitle = label(right, { Size = UDim2.new(1, 0, 0, 22), TextSize = 16 }, true)
    local rSub = label(right, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 24), TextSize = 12, TextColor3 = C.muted })
    local vars = W.scroll(right, UDim2.new(1, 0, 1, -100), UDim2.fromOffset(0, 50))
    local addVar = W.btn(right, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0, 0, 1, -40))
    local delOrd = W.btn(right, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0.5, 4, 1, -40))
    delOrd.TextColor3 = C.bad

    local sel
    local renderSide, renderRight

    local function tgtName(o) return plainName(o.name, o.var, o.pot, (DB.byKey(o.target) or {}).v ~= nil) end
    local function orderValue(o) return DB.price(DB.byKey(o.target), o.var, o.pot) or 0 end
    local function offerText(v)
        local parts, sum = {}, 0
        for _, it in ipairs(v.items or {}) do
            local e = DB.byKey(it.key)
            table.insert(parts, plainName(it.name, it.var, it.pot, e and e.v ~= nil) .. (it.count > 1 and (" x" .. it.count) or ""))
            sum += (DB.price(e, it.var, it.pot) or 0) * it.count
        end
        return table.concat(parts, ", "), sum
    end

    renderSide = function()
        W.clear(side)
        for i, o in ipairs(S.orders) do
            local onN = 0
            for _, v in ipairs(o.offers or {}) do if v.on then onN += 1 end end
            local r = new("TextButton", { Size = UDim2.new(1, -4, 0, 42), BackgroundColor3 = accent(), BackgroundTransparency = sel == i and 0.75 or 1,
                Text = "", AutoButtonColor = false, LayoutOrder = i }, side)
            corner(r, 8)
            plain(r, { Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(8, 3), Text = esc(tgtName(o)), TextTruncate = Enum.TextTruncate.AtEnd }, true)
            plain(r, { Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(8, 22), Text = ("%d / %d · %s"):format(onN, #(o.offers or {}), fmt(orderValue(o))),
                TextColor3 = C.muted, TextSize = 11 })
            on(r.MouseButton1Click, function() sel = i; renderSide(); renderRight() end)
        end
        P.sub.Text = T("ordersSub"):format(#S.orders)
    end

    renderRight = function()
        W.clear(vars)
        local o = sel and S.orders[sel]
        addVar.Visible, delOrd.Visible = o ~= nil, o ~= nil
        if not o then rTitle.Text, rSub.Text = "", T("ordEmpty"); return end
        rTitle.Text = esc(tgtName(o))
        rSub.Text = fmt(orderValue(o))
        if #(o.offers or {}) == 0 then
            plain(vars, { Size = UDim2.new(1, 0, 0, 30), Text = T("ordNoVars"), TextColor3 = C.muted })
        end
        for i, v in ipairs(o.offers or {}) do
            local txt, sum = offerText(v)
            local card = new("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundColor3 = C.card, BackgroundTransparency = v.on and 0.1 or 0.6, LayoutOrder = i }, vars)
            corner(card, 10)
            pad(card, 10, 0)
            plain(card, { Size = UDim2.new(1, -96, 0, 22), Position = UDim2.fromOffset(0, 6), Text = esc(txt), TextTruncate = Enum.TextTruncate.AtEnd }, true)
            local diff = orderValue(o) - sum
            plain(card, { Size = UDim2.new(1, -96, 0, 18), Position = UDim2.fromOffset(0, 28), TextColor3 = C.muted, TextSize = 12,
                Text = T("ordGive"):format(fmt(sum), fmt(orderValue(o))) .. (' <font color="%s">(%s%s)</font>'):format(
                    hex(diff >= 0 and C.good or C.bad), diff >= 0 and "+" or "-", fmt(math.abs(diff))) })
            local tg = W.makeToggle(card, function() return v.on end, function(x) v.on = x; renderSide() end)
            tg.Position = UDim2.new(1, -36, 0.5, 0)
            local del = W.btn(card, "✕", UDim2.fromOffset(28, 28), UDim2.new(1, -28, 0.5, -14))
            del.TextColor3 = C.muted
            on(del.MouseButton1Click, function() table.remove(o.offers, i); saveSettings(); renderSide(); renderRight() end)
        end
    end

    local function refresh()
        P.title.Text = T("orders")
        onLbl.Text = T("ordersOn")
        drawOn()
        newBtn.Text, addVar.Text, delOrd.Text = T("ordNew"), T("ordAddVar"), T("ordDel")
        renderSide()
        renderRight()
    end
    P.show_ = P.show
    P.show = function(from) refresh(); P.show_(from) end

    on(newBtn.MouseButton1Click, function()
        Picker.open("pick", { single = true, title = T("ordPickTarget"), from = P, onDone = function(it)
            table.insert(S.orders, { target = it.key, name = it.name, var = it.var, pot = it.pot, offers = {} })
            sel = #S.orders
            saveSettings()
            task.defer(refresh)
        end })
    end)
    on(addVar.MouseButton1Click, function()
        local o = sel and S.orders[sel]
        if not o then return end
        Picker.open("pick", { title = T("ordPickOffer"):format(tgtName(o)), from = P, onDone = function(items)
            if #items > 0 then
                o.offers = o.offers or {}
                table.insert(o.offers, { on = true, items = items })
                saveSettings()
            end
            task.defer(refresh)
        end })
    end)
    on(delOrd.MouseButton1Click, function()
        if sel and S.orders[sel] then table.remove(S.orders, sel); sel = nil; saveSettings(); refresh() end
    end)

    function Orders.open() P.show() end
end)()

------------------------------------------------------------------
-- Ряды настроек по вкладкам
------------------------------------------------------------------
;(function()
    -- 1. Основное
    W.toggle(1, "enabled", "enabled", function() for _, f in ipairs(onTheme) do pcall(f) end end)
    W.stepper(1, "size", function() return tostring(S.textSize) end,
        function() S.textSize = math.max(10, S.textSize - 1); H.style() end,
        function() S.textSize = math.min(26, S.textSize + 1); H.style() end)
    W.stepper(1, "scale", function() return math.floor((S.uiScale or 1) * 100 + 0.5) .. "%" end,
        function() S.uiScale = math.max(0.6, math.floor((S.uiScale or 1) * 10 - 1 + 0.5) / 10); W.rescale() end,
        function() S.uiScale = math.min(1.8, math.floor((S.uiScale or 1) * 10 + 1 + 0.5) / 10); W.rescale() end)
    -- акцент: кружки
    local rTheme = W.row(1, "theme")
    local dotsBox = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(#ACCENTS * 26, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0) }, rTheme)
    list(dotsBox, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    for i, col in ipairs(ACCENTS) do
        local d = new("TextButton", { Size = UDim2.fromOffset(20, 20), BackgroundColor3 = col, Text = "", AutoButtonColor = false, LayoutOrder = i }, dotsBox)
        corner(d, 10)
        local ring = stroke(d, rgb(255, 255, 255), 1, 2)
        themed(function() ring.Transparency = S.theme == i and 0 or 1 end)
        on(d.MouseButton1Click, function() S.theme = i; saveSettings(); for _, f in ipairs(onTheme) do pcall(f) end end)
    end
    -- шрифт:  ‹ Gotham ›
    local rFont = W.row(1, "font")
    local fontBox = W.control(rFont, 140)
    local fPrev = W.flatBtn(fontBox, "<", UDim2.fromOffset(28, 30), UDim2.fromOffset(0, 0))
    local fName = label(fontBox, { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(28, 0), TextXAlignment = Enum.TextXAlignment.Center }, true)
    local fNext = W.flatBtn(fontBox, ">", UDim2.fromOffset(28, 30), UDim2.new(1, -28, 0, 0))
    themed(function() fName.Text = (FONTS[S.font] or FONTS[1])[1] end)
    local function setFont(d) S.font = (S.font - 1 + d) % #FONTS + 1; saveSettings(); for _, f in ipairs(onTheme) do pcall(f) end end
    on(fPrev.MouseButton1Click, function() setFont(-1) end)
    on(fNext.MouseButton1Click, function() setFont(1) end)
    -- язык: RU | EN
    local rLang = W.row(1, "lang")
    local seg = W.control(rLang, 100)
    for i, code in ipairs({ "ru", "en" }) do
        local b = new("TextButton", { Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale((i - 1) / 2, 0), BackgroundColor3 = accent(),
            BackgroundTransparency = 1, Text = code:upper(), TextColor3 = C.text, TextSize = 13, AutoButtonColor = false }, seg)
        corner(b, 8)
        themed(function() b.Font = fontBold(); b.BackgroundColor3 = accent(); b.BackgroundTransparency = S.lang == code and 0 or 1 end)
        on(b.MouseButton1Click, function() S.lang = code; saveSettings(); for _, f in ipairs(onTheme) do pcall(f) end; W.relabel() end)
    end
    W.toggle(1, "diff", "showDiff")
    W.toggle(1, "details", "details")
    W.openBtn(1, "valuesTitle", function() return T("open") .. "  >" end, function() Picker.open("values", {}) end)
    W.openBtn(1, "calcTitle", function() return T("open") .. "  >" end, function() Calc.open() end)
    W.openBtn(1, "diag", function() return T("diagBtn") end, function() pcall(AM.diagnostics) end)
    W.openBtn(1, "reset", function() return "↺" end, function() S.hudX, S.hudY = nil, nil; saveSettings(); H.place() end)

    -- 2. Трейд
    W.toggle(2, "dryRun", "dryRun")
    W.toggle(2, "auto", "autoOffer")
    local rT = W.row(2, "target")
    local tBox = W.control(rT, 108)
    local tMinus = W.flatBtn(tBox, "−", UDim2.fromOffset(32, 30), UDim2.fromOffset(0, 0))
    local tVal = new("TextBox", { Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(32, 0), BackgroundTransparency = 1,
        TextColor3 = C.text, TextSize = 14, ClearTextOnFocus = true, Text = "", PlaceholderText = "%", PlaceholderColor3 = C.muted }, tBox)
    local tPlus = W.flatBtn(tBox, "+", UDim2.fromOffset(32, 30), UDim2.new(1, -32, 0, 0))
    themed(function() tVal.Font = fontBold(); if not tVal:IsFocused() then tVal.Text = ("+%d%%"):format(S.target) end end)
    local function setTarget(n) S.target = math.clamp(math.floor(n + 0.5), 0, 500); saveSettings(); tVal.Text = ("+%d%%"):format(S.target) end
    on(tMinus.MouseButton1Click, function() setTarget(S.target - 5) end)
    on(tPlus.MouseButton1Click, function() setTarget(S.target + 5) end)
    on(tVal.FocusLost, function() setTarget(tonumber((tVal.Text:gsub("[^%d%.]", ""))) or S.target) end)
    W.toggle(2, "autoAdd", "autoAdd")
    W.toggle(2, "tolerance", "tolerance")
    W.toggle(2, "fillOver", "fillOver")
    W.toggle(2, "autoAccept", "autoAccept")
    W.toggle(2, "giftAccept", "giftAccept")
    W.toggle(2, "mirrorEmpty", "mirrorEmpty")
    W.toggle(2, "emptyDecline", "emptyDecline")
    W.toggle(2, "junkDecline", "junkDecline")
    W.toggle(2, "autoRequest", "autoRequest")
    W.openBtn(2, "bl", function()
        local n = 0
        for _ in pairs(S.blacklist) do n += 1 end
        return T("blCount"):format(n) .. "  >"
    end, function() Picker.open("bl", {}) end)
    W.openBtn(2, "orders", function() return tostring(#S.orders) .. "  >" end, function() Orders.open() end)

    -- 3. Игрок
    W.toggle(3, "antiAfk", "antiAfk")
    W.toggle(3, "antiFling", "antiFling")

    -- 4. Чат
    W.toggle(4, "chatAds", "chatAds")
    W.toggle(4, "chatInTrade", "chatInTrade")
    W.toggle(4, "chatRequests", "chatRequests")
    W.toggle(4, "declineMsg", "declineMsg")

    function W.relabel()
        for _, p in ipairs(W.rows) do p[1].Text = T(p[2]) end
        W.title.Text = T("appTitle")
        W.subtitle.Text = DB.count > 0 and T("loaded"):format(DB.count, DB.updated) or T("failed")
        for _, tb in ipairs(W.tabs) do tb.btn.Text = T(tb.key) end
        W.footer.Text = "elvebredd.com · " .. (AM.ok and "Adopt Me ✓" or T("noGame"))
        for _, f in ipairs(onTheme) do pcall(f) end
        H.style()
    end
    function W.rescale()
        W.scale.Scale = sf()
        W.gearScale.Scale = sf()
        H.scale.Scale = sf()
    end
end)()

------------------------------------------------------------------
-- Автоматика трейда
------------------------------------------------------------------
local A = { busy = false, blocked = {}, reqSeq = 0 }

;(function()
    -- действие в игре; в тестовом режиме — только надпись
    function A.act(what, remote, ...)
        if S.dryRun then
            H.sug(T("dryTag") .. what, C.test)
            return true
        end
        return AM.call(remote, ...)
    end
    function A.say(msg)
        if S.dryRun then H.sug(T("dryTag") .. "chat: " .. msg, C.test); return end
        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                local chans = tcs:FindFirstChild("TextChannels")
                local ch = chans and chans:FindFirstChild("RBXGeneral")
                if ch then ch:SendAsync(msg); return end
            end
            local ev = RS:FindFirstChild("DefaultChatSystemChatEvents")
            if ev and ev:FindFirstChild("SayMessageRequest") then ev.SayMessageRequest:FireServer(msg, "All") end
        end)
    end

    function A.block(name) if name and name ~= "" then A.blocked[name:lower()] = os.clock() + 180 end end
    function A.isBlocked(name)
        local t = name and A.blocked[name:lower()]
        return t ~= nil and t > os.clock()
    end

    function A.reset()
        if A.pendingBlock then A.block(A.pendingBlock); A.pendingBlock = nil end
        A.lastTh, A.stableSince, A.doneFor = -1, 0, -1
        A.declTries, A.declLast, A.declMsgSent, A.declNotified = 0, 0, false, false
        A.emptySince, A.hadTheirs, A.nudged, A.nudgeDone, A.nudgeUid = nil, false, false, nil, nil
        A.junkSig, A.junkSince = nil, nil
        A.giftTries, A.giftLast = 0, 0
        A.accSig, A.accSince, A.accTries, A.accLast, A.accStage = "", 0, 0, 0, nil
        A.fillTh, A.fillMy = nil, nil
        A.partner, A.partnerReq, A.ord = nil, nil, {}
        H.accLine.Visible = false
    end
    A.reset()

    function A.setAcc(key, ...)
        local acc = T("acc") or {}
        H.accLine.Visible = S.autoAccept and key ~= nil
        if key then H.accLine.Text = select("#", ...) > 0 and (acc[key] or key):format(...) or (acc[key] or key) end
    end

    local function decline(reasonText, col)
        H.sug(reasonText, col or C.bad)
        if os.clock() - A.declLast < 1.5 or A.declTries >= 6 then return true end
        A.declLast = os.clock()
        A.declTries += 1
        if A.declTries == 1 then A.pendingBlock = A.partner end -- в блок — когда трейд реально закроется
        A.act(reasonText, "TradeAPI/DeclineTrade")
        return true
    end

    -- принять / подтвердить по этапу трейда
    local function acceptStep(t, mine, label_)
        local stage = AM.stage(t)
        local negotiated, confirmed = AM.flags(mine)
        if stage == "confirm" then
            if confirmed then return "waitThem" end
            A.act(label_, "TradeAPI/ConfirmTrade")
            return "confirm"
        end
        if negotiated then return "waitThem" end
        A.act(label_, "TradeAPI/AcceptNegotiation")
        return "accept"
    end

    function A.unwanted(v)
        local out, seen = {}, {}
        for _, d in ipairs(v.thItems) do
            local hit = S.blacklist[d.key]
            if hit and not seen[hit] then seen[hit] = true; table.insert(out, hit) end
        end
        return out
    end

    -- трейд с тем, кто в блоке: сразу отказ
    function A.handleBlocked(v)
        if not (S.autoRequest and A.partner and A.isBlocked(A.partner)) then return false end
        return decline(T("blockedTrade"):format(A.partner))
    end

    -- нежелательный предмет у соперника
    function A.handleUnwanted(v)
        if not S.autoDecline then return false end
        local bad = A.unwanted(v)
        if #bad == 0 then return false end
        if S.declineMsg and not A.declMsgSent then
            A.declMsgSent = true
            A.say("No thanks, I don't need: " .. table.concat(bad, ", "))
        end
        if not A.declNotified then A.declNotified = true; notify(T("declined"):format(bad[1])) end
        return decline(T("declTry"):format(bad[1]))
    end

    -- подарок: у тебя пусто, у него что-то есть и он принял
    function A.handleGift(t, v)
        if not S.giftAccept or #v.myItems > 0 or #v.thItems == 0 then return false end
        local negotiated, confirmed = AM.flags(v.theirs)
        if not (negotiated or confirmed) then return false end
        if os.clock() - A.giftLast < 1.2 or A.giftTries >= 8 then return true end
        A.giftLast, A.giftTries = os.clock(), A.giftTries + 1
        H.sug(T("giftDoing"), C.good)
        acceptStep(t, v.mine, T("giftDoing"))
        return true
    end

    -- соперник ничего не даёт / даёт только хлам
    function A.handleEmpty(t, v)
        if v.th > 0 then A.emptySince, A.hadTheirs, A.nudged, A.nudgeDone, A.junkSig = nil, true, false, nil, nil; return false end
        if v.thUnk > 0 then
            A.emptySince = nil
            if not S.junkDecline then return false end
            local parts = {}
            for _, d in ipairs(v.thItems) do table.insert(parts, d.uid or d.name) end
            local sig = table.concat(parts, "|")
            if sig ~= A.junkSig then A.junkSig, A.junkSince = sig, os.clock() end
            local left = 10 - (os.clock() - A.junkSince)
            if left > 0 then H.sug(T("junkWait"):format(math.ceil(left))); return true end
            return decline(T("junkWait"):format(0))
        end
        A.emptySince = A.emptySince or os.clock()
        -- он всё убрал — убираю и я
        if S.mirrorEmpty and A.hadTheirs and #v.myItems > 0 and not A.busy then
            A.hadTheirs = false
            A.busy = true
            H.sug(T("emptyCleared"))
            local items = v.myItems
            task.spawn(function()
                for _, d in ipairs(items) do
                    if d.uid then A.act(T("emptyCleared"), "TradeAPI/RemoveItemFromOffer", d.uid); task.wait(0.35) end
                end
                A.busy = false
            end)
            return true
        end
        if not S.emptyDecline then return false end
        -- 12 с пусто — кладём самый дешёвый предмет на 2 с и убираем (показать, что ты на месте)
        if not A.nudged then
            local left = 12 - (os.clock() - A.emptySince)
            if left > 0 then H.sug(T("nudgeWait"):format(math.ceil(left))); return true end
            if A.busy then return true end
            A.nudged, A.busy = true, true
            H.sug(T("nudging"))
            task.spawn(function()
                local inv = AM.inventory()
                local cheap = inv[#inv]
                if cheap then
                    A.act(T("nudging") .. " " .. cheap.name, "TradeAPI/AddItemToOffer", cheap.uid)
                    task.wait(2)
                    A.act(T("nudging"), "TradeAPI/RemoveItemFromOffer", cheap.uid)
                end
                A.busy = false
                A.nudgeDone = os.clock()
            end)
            return true
        end
        if A.busy or not A.nudgeDone then return true end
        local left = 8 - (os.clock() - A.nudgeDone)
        if left > 0 then H.sug(T("emptyWait"):format(math.ceil(left))); return true end
        return decline(T("emptyWait"):format(0))
    end

    -- жадно набираем предметы, не превышая нужную сумму
    local function pickItems(items, need)
        local picks, sum = {}, 0
        for _, it in ipairs(items) do
            if sum + it.price <= need then table.insert(picks, it); sum += it.price end
        end
        return picks, sum
    end

    -- «Заявки»: соперник положил предмет, на который есть заявка -> кладём включённый вариант
    function A.handleOrders(v)
        if not (S.enabled and S.ordersOn) then return end
        local their = {}
        for _, d in ipairs(v.thItems) do their[d.key .. "|" .. d.var .. "|" .. d.pot] = true; their[d.key] = their[d.key] or true end
        local order, enabled
        for _, o in ipairs(S.orders) do
            local hit = (o.var and their[o.target .. "|" .. o.var .. "|" .. (o.pot or "fr")]) or (not o.var and their[o.target])
            if not hit and DB.byKey(o.target) and not DB.byKey(o.target).v then hit = their[o.target] end
            if hit then
                local en = {}
                for i, var in ipairs(o.offers or {}) do if var.on and #(var.items or {}) > 0 then table.insert(en, i) end end
                if #en > 0 then order, enabled = o, en; break end
            end
        end
        local st = A.ord
        if not order then
            if st.target and not st.lostAt then st.lostAt = os.clock() end
            if A.partnerReq and A.partnerReq.kind == "order" then A.partnerReq = nil end
            return
        end
        local pick
        if st.target ~= order.target then
            pick = enabled[math.random(1, #enabled)]
        elseif st.lostAt then
            if os.clock() - st.lostAt < 8 and #enabled > 1 then -- убрал и быстро вернул: другой вариант
                local others = {}
                for _, i in ipairs(enabled) do if i ~= st.idx then table.insert(others, i) end end
                pick = others[math.random(1, #others)]
            else
                pick = st.idx
            end
        end
        st.lostAt = nil
        if not pick then return end
        st.target, st.idx = order.target, pick
        local items = {}
        for _, it in ipairs(order.offers[pick].items) do
            local e = DB.byKey(it.key)
            table.insert(items, { key = it.key, name = it.name, var = it.var, pot = it.pot, count = it.count,
                ik = e and DB.ik(e, it.var, it.pot) or it.key, price = DB.price(e, it.var, it.pot) or 0, pet = e and e.v ~= nil })
        end
        A.reqSeq += 1
        A.partnerReq = { partner = A.partner, items = items, kind = "order", t = os.clock() + 1e6, id = A.reqSeq,
            orderName = plainName(order.name, order.var, order.pot, (DB.byKey(order.target) or {}).v ~= nil) }
    end

    -- просьба соперника из чата или заявка: привести свой оффер к списку
    function A.handleRequest(v)
        local req = A.partnerReq
        if not (req and (req.kind == "order" or (S.chatRequests and os.clock() - req.t < 90))) then return false end
        if req.partner ~= A.partner then return false end
        if req.applied then
            if A.busy then return true end
            if req.myAfter == nil then req.myAfter = v.my end
            if math.abs(v.my - req.myAfter) > 0.01 then A.partnerReq = nil; return false end
            H.sug(T("reqDone"), C.good)
            A.fillTh, A.fillMy = v.th, v.my -- для автопринятия: это и есть договорённость
            return true
        end
        local have = {}
        for _, d in ipairs(v.myItems) do
            local h = have[d.ik] or { uids = {}, count = 0, price = d.price or 0, name = plainName(d.name, d.var, d.pot, d.pet) }
            h.count += 1
            table.insert(h.uids, d.uid)
            have[d.ik] = h
        end
        local isOrder = req.kind == "order"
        local kind = isOrder and "exact" or (req.kind or "exact")
        local want, wantList, wantPrice, wantName = {}, {}, {}, {}
        for _, it in ipairs(req.items) do
            local base = kind == "extra" and (have[it.ik] and have[it.ik].count or 0) or 0
            want[it.ik] = math.max(want[it.ik] or 0, base) + it.count
            wantPrice[it.ik], wantName[it.ik] = it.price or 0, plainName(it.name, it.var, it.pot, it.pet)
            table.insert(wantList, (kind == "extra" and "+" or "") .. wantName[it.ik] .. (it.count > 1 and (" x" .. it.count) or ""))
        end
        local listText = table.concat(wantList, ", ")
        local after = 0
        for ik, h in pairs(have) do
            local n = h.count
            if want[ik] then n = kind == "exact" and want[ik] or math.max(n, want[ik]) elseif kind == "exact" then n = 0 end
            after += n * h.price
        end
        for ik, n in pairs(want) do if not have[ik] then after += n * (wantPrice[ik] or 0) end end
        if not isOrder and after > v.th + math.max(1, v.th * 0.02) then
            H.sug(T("reqTooMuch"):format(listText), C.bad)
            return true
        end
        -- что добавить из инвентаря и что убрать
        local inOffer = {}
        for _, d in ipairs(v.myItems) do if d.uid then inOffer[d.uid] = true end end
        local inv = AM.inventory(inOffer)
        local adds, removes, addText, remText, missing = {}, {}, {}, {}, {}
        local used = {}
        for ik, n in pairs(want) do
            local diff = n - (have[ik] and have[ik].count or 0)
            local got = 0
            for _, d in ipairs(inv) do
                if got >= diff then break end
                if d.ik == ik and not used[d.uid] then used[d.uid] = true; table.insert(adds, d); got += 1 end
            end
            if got > 0 then table.insert(addText, wantName[ik] .. (got > 1 and (" x" .. got) or "")) end
            if got < diff then table.insert(missing, wantName[ik]) end
        end
        for ik, h in pairs(have) do
            local extra = kind == "exact" and h.count - (want[ik] or 0) or 0
            for i = 1, math.max(0, extra) do table.insert(removes, h.uids[i]) end
            if extra > 0 then table.insert(remText, h.name .. (extra > 1 and (" x" .. extra) or "")) end
        end
        if #adds == 0 and #removes == 0 then
            req.applied, req.myAfter = true, v.my
            H.sug(#missing > 0 and T("reqMissing"):format(table.concat(missing, ", ")) or T("reqDone"), #missing > 0 and C.fair or C.good)
            A.fillTh, A.fillMy = v.th, v.my
            return true
        end
        local parts = { isOrder and T("ordApplied"):format(listText, req.orderName or "?") or T("reqPlan"):format(listText) }
        if #addText > 0 then table.insert(parts, T("reqAdd"):format(table.concat(addText, ", "))) end
        if #remText > 0 then table.insert(parts, T("reqRemove"):format(table.concat(remText, ", "))) end
        if #missing > 0 then table.insert(parts, T("reqMissing"):format(table.concat(missing, ", "))) end
        H.sug(table.concat(parts, " · "))
        if not (S.autoAdd and not A.busy and A.reqDoneId ~= req.id) then return true end
        A.busy, A.reqDoneId = true, req.id
        req.applied, req.myAfter = true, nil
        task.spawn(function()
            for _, uid in ipairs(removes) do A.act(T("reqDoing"):format(listText), "TradeAPI/RemoveItemFromOffer", uid); task.wait(0.35) end
            for _, d in ipairs(adds) do A.act(T("reqDoing"):format(listText), "TradeAPI/AddItemToOffer", d.uid); task.wait(0.35) end
            A.busy = false
        end)
        return true
    end

    -- автооффер: подбор своих предметов под цель прибыли
    function A.handleOffer(v)
        if not S.autoOffer then return end
        local tgt = ("+%d%%"):format(S.target)
        if v.th <= 0 then H.sug(T("sugWait"):format(tgt)); return end
        local maxMine = v.th / (1 + S.target / 100)
        local need = maxMine - v.my
        if S.fillOver and A.fillTh == v.th and A.fillMy and v.my <= A.fillMy + 0.01 and v.my >= maxMine then
            H.sug(T("sugOk"):format(tgt .. T("overTag")), C.good); return
        end
        if need < -math.max(0.05, maxMine * 0.02) then
            H.sug(T("sugRemove"):format(tgt, fmt(-need)), C.bad); return
        end
        local inOffer = {}
        for _, d in ipairs(v.myItems) do if d.uid then inOffer[d.uid] = true end end
        local items, okInv = AM.inventory(inOffer)
        if not okInv then H.sug(T("noInv"), C.bad); return end
        local picks, sum = pickItems(items, need)
        if S.tolerance then
            local needTol = v.th / (1 + (S.target - 1) / 100) - v.my
            local picks2, sum2 = pickItems(items, needTol)
            if sum2 > sum then picks, sum, need, tgt = picks2, sum2, needTol, tgt .. " (±1%)" end
        end
        -- добивать сверх цели: не хватает заметной части — кладём самый дешёвый подходящий предмет, если не уходим в минус
        if S.fillOver and need - sum >= math.max(0.05, maxMine * 0.01) then
            local rest, used = need - sum, {}
            for _, pk in ipairs(picks) do used[pk.uid] = true end
            local best
            for _, it in ipairs(items) do
                if not used[it.uid] and it.price >= rest and v.my + sum + it.price <= v.th then
                    if not best or it.price < best.price then best = it end
                end
            end
            if best then
                table.insert(picks, best)
                sum += best.price
                tgt = tgt .. T("overTag")
                A.fillTh, A.fillMy = v.th, v.my + sum
            end
        end
        if #picks == 0 then
            if need <= math.max(0.05, maxMine * 0.05) then H.sug(T("sugOk"):format(tgt), C.good)
            else H.sug(T("sugNone"):format(tgt, fmt(need))) end
            return
        end
        local names = {}
        for i, pk in ipairs(picks) do
            if i <= 4 then table.insert(names, plainName(pk.name, pk.var, pk.pot, pk.pet)) end
        end
        if #picks > 4 then table.insert(names, "...") end
        local listText = table.concat(names, ", ")
        H.sug(T("sugAdd"):format(tgt, fmt(sum), listText))
        if not S.autoAdd then return end
        -- добавляем, когда соперник 1.5 с ничего не меняет
        if v.th ~= A.lastTh then A.lastTh, A.stableSince = v.th, os.clock() end
        if A.busy then H.sug(T("sugAuto"):format(tgt, fmt(sum), listText)); return end
        if A.doneFor ~= v.th and os.clock() - A.stableSince > 1.5 then
            A.busy, A.doneFor = true, v.th
            H.sug(T("sugAuto"):format(tgt, fmt(sum), listText))
            task.spawn(function()
                for _, pk in ipairs(picks) do
                    if not (S.enabled and S.autoOffer and S.autoAdd) then break end
                    A.act(T("sugAuto"):format(tgt, fmt(sum), plainName(pk.name, pk.var, pk.pot, pk.pet)), "TradeAPI/AddItemToOffer", pk.uid)
                    task.wait(0.35)
                end
                A.busy = false
            end)
        end
    end

    -- автопринятие: выгодно по цели, всё с ценой, 2 с без изменений
    function A.handleAccept(t, v)
        if not (S.autoAccept and S.enabled) then A.setAcc(nil); H.accLine.Visible = false; return end
        if A.busy then A.setAcc("busy"); return end
        if v.th <= 0 then A.setAcc("wait"); return end
        if v.myUnk > 0 then A.setAcc("unk"); return end
        if v.thUnk > 0 then A.setAcc("theirUnk"); return end
        if S.autoDecline and #A.unwanted(v) > 0 then A.setAcc("bad"); return end
        local profit = v.my > 0 and (v.th - v.my) / v.my * 100 or 999
        local maxMine = v.th / (1 + (S.target - (S.tolerance and 1 or 0)) / 100)
        if S.fillOver and A.fillTh == v.th and A.fillMy then maxMine = math.max(maxMine, A.fillMy) end
        if v.my > maxMine + math.max(0.01, maxMine * 0.02) then
            A.accSig = ""
            A.setAcc("low", math.floor(profit + 0.5))
            return
        end
        local parts = {}
        for _, d in ipairs(v.myItems) do table.insert(parts, d.uid or d.name) end
        table.insert(parts, "/")
        for _, d in ipairs(v.thItems) do table.insert(parts, d.uid or d.name) end
        local sig = table.concat(parts, ",") .. "|" .. AM.stage(t)
        if sig ~= A.accSig then A.accSig, A.accSince, A.accTries = sig, os.clock(), 0; A.setAcc("hold", 2); return end
        if os.clock() - A.accSince < 2 then A.setAcc("hold", math.max(1, math.ceil(2 - (os.clock() - A.accSince)))); return end
        if A.accTries >= 6 then A.setAcc("gaveup"); return end
        if os.clock() - A.accLast < 1.5 then return end
        A.accLast, A.accTries = os.clock(), A.accTries + 1
        local pct = math.floor(profit + 0.5)
        local res = acceptStep(t, v.mine, T("acc")[AM.stage(t) == "confirm" and "confirm" or "accept"]:format(pct))
        A.setAcc(res, pct)
        if res == "waitThem" then A.accTries -= 1 end -- ожидание соперника попыткой не считаем
    end

    -- входящий запрос на трейд
    function A.onRequest(sender)
        if not (S.enabled and S.autoRequest) then return end
        local name = AM.nameOf(sender)
        task.wait(1)
        if A.isBlocked(name) then
            A.act(T("blockedReq"):format(name), "TradeAPI/AcceptOrDeclineTradeRequest", sender, false)
            notify(T("blockedReq"):format(name))
            return
        end
        if AM.trade() then return end
        A.act(T("requestAccepted"):format(name), "TradeAPI/AcceptOrDeclineTradeRequest", sender, true)
        notify(T("requestAccepted"):format(name))
    end
    function A.hookRequests()
        local r = AM.remote("TradeAPI/TradeRequestReceived")
        if r and r:IsA("RemoteEvent") then
            on(r.OnClientEvent, function(sender) task.spawn(A.onRequest, sender) end)
        end
    end

    -- один шаг автоматики (порядок как в MM2-версии)
    function A.step(t, v)
        H.sug(nil)
        if not S.enabled then return end
        if A.handleBlocked(v) then return end
        if A.handleUnwanted(v) then return end
        if A.handleGift(t, v) then return end
        if A.handleEmpty(t, v) then return end
        A.handleOrders(v)
        if not A.handleRequest(v) then A.handleOffer(v) end
        A.handleAccept(t, v)
    end
end)()

------------------------------------------------------------------
-- Анализ чата: предметы в сообщениях, выгодно ли это тебе; просьбы соперника
------------------------------------------------------------------
local Chat = {}

;(function()
    local feed = new("Frame", { Position = UDim2.new(0, 12, 0.42, 0), Size = UDim2.fromOffset(340, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false }, ui)
    list(feed, Enum.FillDirection.Vertical, 6)
    local feedScale = new("UIScale", {}, feed)
    Chat.feed = feed
    local order = 0

    -- нижний регистр и для кириллицы (string.lower меняет только латиницу)
    local function lowerAll(str)
        local out = {}
        for _, cp in utf8.codes(str) do
            if cp >= 0x410 and cp <= 0x42F then cp = cp + 0x20 elseif cp == 0x401 then cp = 0x451 end
            table.insert(out, utf8.char(cp))
        end
        return table.concat(out):lower()
    end
    local function cnorm(str)
        local ok, low = pcall(lowerAll, str)
        return DB.norm(ok and low or str)
    end

    -- [chatparse begin] — разбор сообщений чата (проверяется отдельными тестами)
    local NUMWORDS = {}
    for w, n in pairs({ one = 1, two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10,
        a = 1, an = 1, ["один"] = 1, ["одну"] = 1, ["одного"] = 1, ["два"] = 2, ["две"] = 2, ["три"] = 3, ["четыре"] = 4,
        ["пять"] = 5 }) do
        NUMWORDS[cnorm(w)] = n
    end
    -- сленг Adopt Me -> ключ предмета
    local ALIAS = {}
    for k, v in pairs({
        sd = "shadowdragon", shadow = "shadowdragon", shadows = "shadowdragon", bd = "batdragon", bat = "batdragon", bats = "batdragon",
        fd = "frostdragon", frost = "frostdragon", gd = "giantpanda", giraf = "giraffe", raffe = "giraffe", owls = "owl",
        evil = "evilunicorn", evu = "evilunicorn", eu = "evilunicorn", evilu = "evilunicorn", rein = "arcticreindeer", reindeer = "arcticreindeer", ar = "arcticreindeer",
        mk = "monkeyking", qb = "queenbee", ks = "kingmonkey", uni = "unicorn", dodo = "dodo", trex = "trex", ["t-rex"] = "trex",
        turt = "turtle", kanga = "kangaroo", roo = "kangaroo", hedge = "hedgehog", dalma = "dalmatian", flamin = "flamingo",
        bfly = "butterfly", parr = "parrot", pengu = "penguin", ["шадоу"] = "shadowdragon", ["шедоу"] = "shadowdragon", ["шэдоу"] = "shadowdragon",
        ["бат"] = "batdragon", ["фрост"] = "frostdragon", ["жираф"] = "giraffe", ["жирафа"] = "giraffe", ["сова"] = "owl", ["сову"] = "owl",
        ["попугай"] = "parrot", ["попугая"] = "parrot", ["ворона"] = "crow", ["ворону"] = "crow", ["олень"] = "arcticreindeer", ["оленя"] = "arcticreindeer",
        ["единорог"] = "unicorn", ["единорога"] = "unicorn", ["черепаха"] = "turtle", ["черепаху"] = "turtle", ["кенгуру"] = "kangaroo",
    }) do ALIAS[cnorm(k)] = v end

    -- вариант питомца: «nfr», «mfr», «neon», «mega», «fr», «f», «r», «np»
    local function varOf(w)
        local k = cnorm(w)
        if k == "neon" or k == "неон" then return "n", nil end
        if k == "mega" or k == "меги" or k == "мега" or k == "meganeon" then return "m", nil end
        if k == "np" or k == "nopot" or k == "nopotion" then return nil, "np" end
        local v, p = k:match("^([nmнм]?)(f?r?)$")
        if not v or (v == "" and k == "") then return nil end
        if p == "" and v == "" then return nil end
        local var = (v == "n" or v == "н") and "n" or ((v == "m" or v == "м") and "m" or nil)
        local pot = (p == "fr" and "fr") or (p == "f" and "f") or (p == "r" and "r") or nil
        if not var and not pot then return nil end
        return var, pot
    end

    local MARK = {}
    local function marks(kind, lst) for _, w in ipairs(lst) do MARK[cnorm(w)] = kind end end
    marks("give", { "my", "mine", "giving", "selling", "sell", "trading", "offering", "have", "got", "h",
        "мой", "моя", "мои", "моё", "мое", "моего", "мою", "отдам", "отдаю", "даю", "продаю", "меняю" })
    marks("want", { "for", "lf", "wf", "want", "wants", "need", "needs", "your", "ur", "yours", "gimme", "w",
        "хочу", "ищу", "на", "нужен", "нужна", "нужно", "нужны", "надо", "твой", "твоя", "твои", "твоё", "твое", "твою", "за", "дай",
        "por", "pour", "für", "fur", "per", "voor", "za", "için", "busco", "suche", "cherche", "cerco", "szukam" })
    marks("add", { "add", "adds", "plus", "+", "добавь", "докинь", "накинь", "плюс", "сверху", "доплати" })
    local EXACT = {}
    for _, w in ipairs({ "just", "only", "только", "лишь", "просто", "instead", "вместо" }) do EXACT[cnorm(w)] = true end
    local ANY = {}
    for _, w in ipairs({ "anything", "offers", "ofs", "anyth", "чтонибудь", "чтото", "любое", "любой", "предложения" }) do ANY[cnorm(w)] = true end
    local STOP = {}
    for _, w in ipairs({ "trade", "trading", "trades", "selling", "sell", "buying", "buy", "offer", "offers", "giving",
        "give", "need", "want", "have", "with", "your", "mine", "adds", "add", "plus", "and", "for", "anyone", "pls",
        "please", "value", "values", "upgrade", "downgrade", "overpay", "just", "only", "more", "less", "some", "that",
        "this", "them", "these", "those", "what", "okay", "legendary", "legend", "pet", "pets", "neon", "mega", "fly", "ride",
        "трейд", "обмен", "меняю", "продаю", "куплю", "ищу", "отдам", "даю", "кто", "есть", "или", "только", "давай" }) do
        STOP[cnorm(w)] = true
    end
    for k in pairs(NUMWORDS) do STOP[k] = true end
    for k in pairs(MARK) do STOP[k] = true end

    local function lev(a2, b2, maxD)
        local la, lb = #a2, #b2
        if math.abs(la - lb) > maxD then return maxD + 1 end
        local prev = {}
        for j = 0, lb do prev[j] = j end
        for i2 = 1, la do
            local cur, best = { [0] = i2 }, i2
            local ca = a2:byte(i2)
            for j = 1, lb do
                local cost = (ca == b2:byte(j)) and 0 or 1
                cur[j] = math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
                if cur[j] < best then best = cur[j] end
            end
            if best > maxD then return maxD + 1 end
            prev = cur
        end
        return prev[lb]
    end

    -- ключ фразы -> ключ предмета (точно, сленг, мн. число, начало слова, опечатка); только питомцы и дорогие вещи
    local function known(k) return DB.byName[k] ~= nil end
    local function resolve(key, single)
        if #key < 2 then return nil end
        if known(key) and #key >= 3 then return key end
        if ALIAS[key] and known(ALIAS[key]) then return ALIAS[key] end
        -- множественное число: «owls», «frost dragons»
        if #key >= 4 and key:sub(-1) == "s" and not STOP[key] then
            local k1 = key:sub(1, -2)
            if known(k1) then return k1 end
            if ALIAS[k1] and known(ALIAS[k1]) then return ALIAS[k1] end
        end
        if not single or #key < 4 or STOP[key] then return nil end
        local hit, hits = nil, 0
        for k, lst in pairs(DB.byName) do
            if lst[1].type == "pets" and k:sub(1, #key) == key then hit, hits = k, hits + 1; if hits > 1 then break end end
        end
        if hits == 1 then return hit end
        if hits > 1 then return nil end
        if #key >= 5 and key:match("^[%a%d]+$") then
            local maxD = #key >= 7 and 2 or 1
            local best, bestD, ties = nil, maxD + 1, 0
            for k, lst in pairs(DB.byName) do
                if lst[1].type == "pets" then
                    local d = lev(key, k, maxD)
                    if d < bestD then best, bestD, ties = k, d, 1 elseif d == bestD then ties += 1 end
                end
            end
            if best and bestD <= maxD and ties == 1 then return best end
        end
        return nil
    end

    local function numOf(w)
        if not w then return nil end
        local lw = lowerAll(w)
        local n = lw:match("^(%d+)$") or lw:match("^(%d+)[xх%*]$") or lw:match("^[xх%*×](%d+)$") or lw:match("^(%d+)шт%.?$")
        if n then return tonumber(n) end
        return NUMWORDS[cnorm(w)]
    end

    -- разбор: { gives, wants, loose, adds, exact, any }; предмет: { key, name, var, pot, count, price, pet, ik }
    function Chat.parse(text)
        local low = lowerAll(text)
        low = low:gsub("w/f", " wf "):gsub("[%+]", " + "):gsub("[,;&/]", " ")
        local words = {}
        for w in low:gmatch("%S+") do table.insert(words, w) end
        local res = { gives = {}, wants = {}, loose = {}, adds = {}, exact = false, any = false }
        local side, pVar, pPot = nil, nil, nil
        local i = 1
        while i <= #words do
            local w = words[i]
            local cw = cnorm(w)
            if w == "+" then side = "add"; i += 1; continue end
            if cw == "give" and cnorm(words[i + 1] or "") == "me" then side = "want"; i += 2; continue end
            if EXACT[cw] then res.exact = true end
            if ANY[cw] then res.any = true end
            if MARK[cw] then side = MARK[cw]; i += 1; continue end
            local vv, vp = varOf(w)
            if vv or vp then pVar = vv or pVar; pPot = vp or pPot; i += 1; continue end
            local matched = false
            for len = math.min(4, #words - i + 1), 1, -1 do
                local clean = true
                for j = i + 1, i + len - 1 do
                    local cj = cnorm(words[j])
                    local jv, jp = varOf(words[j])
                    if cj == "" or MARK[cj] or numOf(words[j]) or jv or jp then clean = false; break end
                end
                local itemKey = clean and resolve(cnorm(table.concat(words, " ", i, i + len - 1)), len == 1) or nil
                if itemKey then
                    -- число перед названием, в том числе перед вариантом: «2 fr frost»
                    local pv, pp = varOf(words[i - 1] or "")
                    local before = numOf(words[i - 1]) or ((pv or pp) and numOf(words[i - 2])) or nil
                    local after, skip = nil, 0
                    -- вариант сразу после названия: «owl nfr»
                    local av, ap = varOf(words[i + len] or "")
                    if av or ap then pVar = av or pVar; pPot = ap or pPot; skip = 1 end
                    if not before then
                        after = numOf(words[i + len + skip])
                        if after then skip += 1 end
                    end
                    local e = DB.byKey(itemKey)
                    local isPet = e ~= nil and e.v ~= nil
                    local var = isPet and (pVar or "r") or "r"
                    local pot = isPet and (pPot or "fr") or "fr"
                    if isPet and not e.v[var] then var = "r" end
                    local it = { key = itemKey, name = e and e.name or itemKey, var = var, pot = pot, pet = isPet,
                        count = math.clamp(before or after or 1, 1, 99), price = DB.price(e, var, pot) or 0 }
                    it.ik = e and DB.ik(e, var, pot) or itemKey
                    local bucket = side == "give" and res.gives or side == "want" and res.wants or side == "add" and res.adds or res.loose
                    table.insert(bucket, it)
                    pVar, pPot = nil, nil
                    i += len + skip
                    matched = true
                    break
                end
            end
            if not matched then i += 1 end
        end
        return res
    end
    local function sumOf(lst)
        local s = 0
        for _, it in ipairs(lst) do s += it.price * it.count end
        return s
    end
    -- [chatparse end]

    local function listText(found)
        local parts = {}
        for _, it in ipairs(found) do
            table.insert(parts, ('%s%s <font color="%s">%s</font>'):format(esc(plainName(it.name, it.var, it.pot, it.pet)),
                it.count > 1 and (" x" .. it.count) or "", hex(C.muted), fmt(it.price * it.count)))
        end
        return table.concat(parts, ", ")
    end

    local function placeFeed()
        feedScale.Scale = sf()
        local ok, pos, size = pcall(function()
            local cfg = game:GetService("TextChatService"):FindFirstChildOfClass("ChatWindowConfiguration")
            return cfg.AbsolutePosition, cfg.AbsoluteSize
        end)
        feed.AnchorPoint = Vector2.zero
        if ok and pos and size and size.Y > 0 then feed.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 8)
        else feed.Position = UDim2.new(0, 12, 0.42, 0) end
    end

    local function showCard(who, body)
        order += 1
        local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, LayoutOrder = -order }, feed)
        corner(card, 10)
        stroke(card, accent(), 0.5)
        pad(card, 10, 7)
        plain(card, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
            TextSize = math.max(12, S.textSize - 2), Text = ("<b>%s</b>\n%s"):format(esc(who), body) })
        local cards = {}
        for _, c in ipairs(feed:GetChildren()) do if c:IsA("Frame") then table.insert(cards, c) end end
        table.sort(cards, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
        for k = 1, #cards - 4 do cards[k]:Destroy() end
        task.delay(25, function() if card.Parent then card:Destroy() end end)
    end

    local function analyse(player, text)
        if not S.enabled or player == LP or not text or text == "" or DB.count == 0 then return end
        local okP, r = pcall(Chat.parse, text)
        if not okP or not r then return end
        -- сообщение соперника по трейду: его просьба
        if S.chatRequests and player and A.partner and (player.Name == A.partner or player.DisplayName == A.partner) then
            local kind, items
            if #r.adds > 0 then kind, items = "extra", r.adds
            elseif #r.wants > 0 then kind, items = r.exact and "exact" or "total", r.wants
            elseif #r.loose > 0 and #r.gives == 0 then kind, items = r.exact and "exact" or "total", r.loose end
            if kind then
                A.reqSeq += 1
                A.partnerReq = { partner = A.partner, items = items, kind = kind, t = os.clock(), id = A.reqSeq }
            end
        end
        if not S.chatAds or not player then return end
        local hasMarkers = #r.gives > 0 or #r.wants > 0 or #r.adds > 0 or r.any
        if not hasMarkers then
            local kept = {}
            for _, it in ipairs(r.loose) do if it.price >= 1 or it.count > 1 then table.insert(kept, it) end end
            r.loose = kept
        end
        local maxPrice = 0
        for _, lst in ipairs({ r.gives, r.wants, r.adds, r.loose }) do
            for _, it in ipairs(lst) do maxPrice = math.max(maxPrice, it.price) end
        end
        if maxPrice < 1 then return end
        placeFeed()
        local gives, wants, loose = {}, r.wants, r.loose
        for _, it in ipairs(r.gives) do table.insert(gives, it) end
        if #loose > 0 and (#wants > 0 or r.any) then
            for _, it in ipairs(loose) do table.insert(gives, it) end
            loose = {}
        end
        if #gives == 0 and #wants == 0 and #loose == 0 and #r.adds == 0 then return end
        local lines = {}
        if #gives > 0 then table.insert(lines, ("%s: %s"):format(T("gives"), listText(gives))) end
        if #wants > 0 then table.insert(lines, ("%s: %s"):format(T("wants"), listText(wants)))
        elseif r.any and #gives > 0 then table.insert(lines, ("%s: %s"):format(T("wants"), T("anyOffers"))) end
        if #r.adds > 0 then table.insert(lines, ("%s: %s"):format(T("asksAdd"), listText(r.adds))) end
        if #loose > 0 then table.insert(lines, ("%s: %s = <b>%s</b>"):format(T("items"), listText(loose), fmt(sumOf(loose)))) end
        if #gives > 0 and #wants > 0 then
            local diff = sumOf(gives) - sumOf(wants)
            local col = diff > 0 and C.good or (diff < 0 and C.bad or C.fair)
            local status = diff > 0 and T("good") or (diff < 0 and T("bad") or T("fair"))
            table.insert(lines, ('%s: <font color="%s"><b>%s%s · %s</b></font>'):format(T("forYou"), hex(col), diff >= 0 and "+" or "-", fmt(math.abs(diff)), status))
        elseif #gives > 0 then table.insert(lines, ("= <b>%s</b>"):format(fmt(sumOf(gives))))
        elseif #wants > 0 then table.insert(lines, ("= <b>%s</b>"):format(fmt(sumOf(wants)))) end
        showCard(player.DisplayName, table.concat(lines, "\n"))
    end

    function Chat.hook()
        local TextChatService = game:GetService("TextChatService")
        local okNew = pcall(function()
            on(TextChatService.MessageReceived, function(msg)
                local src = msg.TextSource
                local pl = src and Players:GetPlayerByUserId(src.UserId)
                analyse(pl, msg.Text)
            end)
        end)
        local function hookOld(pl) on(pl.Chatted, function(text) analyse(pl, text) end) end
        if not okNew or TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
            for _, pl in ipairs(Players:GetPlayers()) do hookOld(pl) end
            on(Players.PlayerAdded, hookOld)
        end
    end
end)()

------------------------------------------------------------------
-- Анти-АФК и анти-флинг
------------------------------------------------------------------
;(function()
    on(LP.Idled, function()
        if not (S.enabled and S.antiAfk) then return end
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
    local lastSafe, lastSafeAt = nil, 0
    on(RunService.Stepped, function()
        if not (S.enabled and S.antiFling) then return end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP and pl.Character then
                for _, part in ipairs(pl.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then return end
        local v, w = hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity
        if Vector3.new(v.X, 0, v.Z).Magnitude > 120 or w.Magnitude > 40 or v.Y > 150 then
            hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            if lastSafe then hrp.CFrame = lastSafe end
        elseif hum.FloorMaterial ~= Enum.Material.Air and os.clock() - lastSafeAt > 0.5 then
            lastSafe, lastSafeAt = hrp.CFrame, os.clock()
        end
    end)
end)()

------------------------------------------------------------------
-- Главный цикл: следим за трейдом
------------------------------------------------------------------
;(function()
    local acc, inTrade, errShown = 0, false, false
    local function tick()
        local t = (S.enabled and AM.ok) and AM.trade() or nil
        local mine, theirs, partner = AM.offers(t)
        Chat.feed.Visible = S.enabled and S.chatAds and (not mine or S.chatInTrade)
        if not mine then
            if inTrade then inTrade = false; H.frame.Visible = false; A.reset() end
            W.gear.Visible = true
            return
        end
        if not inTrade then
            inTrade = true
            A.reset()
            task.spawn(function() if DB.load() then W.relabel() end end) -- свежие цены на каждый трейд
            H.frame.Visible = true
            H.scale.Scale = sf() * 0.9
            tween(H.scale, 0.25, { Scale = sf() }, Enum.EasingStyle.Back)
        end
        A.partner = AM.nameOf(partner)
        local v = { mine = mine, theirs = theirs }
        v.my, v.myUnk, v.myItems = AM.sum(mine)
        v.th, v.thUnk, v.thItems = AM.sum(theirs)
        H.render(v)
        A.step(t, v)
    end
    on(RunService.Heartbeat, function(dt)
        acc += dt; if acc < 0.3 then return end; acc = 0
        local ok, err = pcall(tick)
        if not ok and not errShown then -- показать ошибку один раз, чтобы было что прислать
            errShown = true
            notify("Ошибка: " .. tostring(err):sub(1, 150))
        end
    end)
    on(ui:GetPropertyChangedSignal("AbsoluteSize"), function() W.rescale() end)
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
    A.hookRequests()
    Chat.hook()
    W.relabel()
    notify(okDB and T("loaded"):format(DB.count, DB.updated) or T("failed"))
    if not AM.ok then notify(T("noGame")) end
    if S.dryRun then notify(T("dryWarn")) end
end)
