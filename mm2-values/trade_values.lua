--// MM2 Auto Trade — цены Supreme Values над окном трейда (цены обновляет бот на GitHub)
local VALUES_URL = "https://raw.githubusercontent.com/pophol221-arch/mm2-values/main/mm2-values/values.json"
local SETTINGS_FILE = "TradeValues_settings.json"

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui   = game:GetService("StarterGui")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- повторный запуск: убираем прошлую копию
local env = (getgenv and getgenv()) or _G
if env.TV_cleanup then pcall(env.TV_cleanup) end
-- метка этой копии: запустили скрипт ещё раз — старая копия перестаёт реагировать и закрывается сама
-- (даже если она ещё грузилась и не успела оставить TV_cleanup)
local INST = {}
env.TV_inst = INST
for _, g in ipairs(PlayerGui:GetChildren()) do
    if g.Name == "TradeValuesOverlay" or g.Name == "TVSettingsUI" or g.Name == "TVOverlayUI" or g.Name == "TVHighlightUI" then g:Destroy() end
end
local conns = {}
local function on(sig, fn)
    local c = sig:Connect(function(...) if env.TV_inst == INST then return fn(...) end end)
    table.insert(conns, c)
    return c
end

------------------------------------------------------------------
-- Настройки (сохраняются в файл Delta, если он умеет writefile)
------------------------------------------------------------------
local S = { textSize = 16, theme = 1, font = 1, lang = "ru", showDiff = true, iconX = 0.02, iconY = 0.35, autoOffer = false, target = 20, enabled = true, highlight = true, autoAdd = true, tolerance = false, uiScale = 1, autoAccept = false, fillOver = true, mirrorEmpty = true, emptyDecline = true, junkDecline = true, giftAccept = true, ordersOn = true, orders = {}, antiAfk = false, antiFling = false, autoRequest = false, chatAds = false, chatInTrade = false, chatRequests = true, declineMsg = true, autoDecline = false, blacklist = {}, keep = {}, idleDecline = true, cheapGodly = true }
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
-- тёмная тёплая тема: «бумага», коралловый акцент
local C = {
    bg = rgb(19, 17, 14), card = rgb(36, 33, 27), line = rgb(238, 230, 216),
    text = rgb(238, 230, 216), muted = rgb(166, 156, 141),
    good = rgb(125, 192, 140), fair = rgb(214, 174, 82), bad = rgb(255, 138, 128),
}
-- темы = акцентный цвет
local ACCENTS = {
    rgb(238, 111, 78), rgb(122, 166, 204), rgb(127, 176, 139),
    rgb(156, 147, 214), rgb(214, 174, 82), rgb(197, 122, 166),
}
local FONTS = {
    { "Classic", Enum.Font.Merriweather, Enum.Font.GothamMedium }, -- заголовки с засечками, текст — простой
    { "Gotham", Enum.Font.GothamBold, Enum.Font.GothamMedium },
    { "Fredoka", Enum.Font.FredokaOne, Enum.Font.FredokaOne },
    { "Ubuntu", Enum.Font.Ubuntu, Enum.Font.Ubuntu },
    { "Montserrat", Enum.Font.Montserrat, Enum.Font.Montserrat },
    { "Luckiest", Enum.Font.LuckiestGuy, Enum.Font.LuckiestGuy },
    { "Arcade", Enum.Font.Arcade, Enum.Font.Arcade },
}
if S.styleV ~= 2 then S.theme, S.font, S.styleV = 1, 1, 2 end -- новый вид: как на сайте
local function accent() return ACCENTS[S.theme] or ACCENTS[1] end
local function fontBold() return (FONTS[S.font] or FONTS[1])[2] end
local function fontReg() return (FONTS[S.font] or FONTS[1])[3] end

local L = {
    ru = { you = "ТЫ", them = "ОН", win = "ВЫГОДА", good = "ВЫГОДНО", fair = "ЧЕСТНО", bad = "НЕВЫГОДНО", empty = "ПУСТО",
           noPrice = "без цены: %d", settings = "Настройки", size = "Размер текста", scale = "Масштаб", tabMain = "Основное", tabTrade = "Трейд", tabTrade2 = "Принятие", tabGame = "Прочее", tabChat = "Чат", valuesTitle = "Таблица цен", invStats = "Статистика инвентаря", invTotal = "Общая цена инвентаря", histItems = "Предметы", histSum = "Трейдов: %d · итог: %s", histPending = "⏳ — на проверке (%d): подтвердится, когда скрипт увидит инвентарь (следующий трейд или открытие инвентаря)", histTrades = "История трейдов", histNone = "Пока нет трейдов — после каждого состоявшегося трейда он появится здесь", histGave = "отдал", histGot = "получил", invTitle = "Инвентарь · сейчас %s", invNote = "За 24 ч: %s  ·  за 7 дн: %s  ·  точек: %d", invEmpty = "Пока нет данных: открой трейд, когда в твоём предложении пусто, — скрипт запишет стоимость инвентаря", openValues = "Открыть", rangeL = "Диапазон", demandL = "Спрос", rarityL = "Редкость", stab = { ["Stable"] = "Стабильно", ["Doing Well"] = "Растёт", ["Fluctuating"] = "Колеблется", ["Underpaid For"] = "Недоплачивают", ["Overpaid For"] = "Переплачивают" }, chatInTrade = "Показывать во время трейда", chatRequests = "Выполнять просьбы из чата", declineMsg = "Писать в чат причину отказа", declPress = "отказ: кнопок %d, попытка %d (сработали способы: %s)", declWait = "Не нужен %s — отклоню через %d с", declNoBtn = "кнопка «Отказ» не найдена [%s]", declTry = "Нежелательный предмет: %s — отказ, попытка %d", reqPlan = "Просит: %s", reqAdd = "добавь %s", reqRemove = "убери %s", reqDone = "Просьба выполнена", reqTooMuch = "Просит %s — это больше, чем он даёт", reqDoing = "Выполняю просьбу: %s", acc = { off = "", wait = "автопринятие: ждём предметы соперника", busy = "автопринятие: скрипт кладёт предметы", unk = "автопринятие: у тебя предметы без цены", bad = "автопринятие: нежелательный предмет", low = "автопринятие: прибыль ниже цели (%d%%)", hold = "автопринятие: проверка %d с", countdown = "автопринятие: ждём отсчёт MM2", nobtn = "автопринятие: кнопка «Принять» не найдена [%s]", click = "автопринятие: нажал, способ %d (попытка %d)", gaveup = "автопринятие: 9 попыток без результата" }, antiAfk = "Анти-АФК", chatAdvert = "«Let's trade!» в чат раз в 2,5 минуты", outreach = "Самому предлагать трейд игрокам по списку", outSent = "Предложил трейд: %s", outNoPlus = "Авто-предложения: не нашёл «+» возле числа игроков", outNoList = "Авто-предложения: нажал «+», но списка игроков не видно", outNoTradeBtn = "Авто-предложения: нажал на %s, но кнопки «Обмен» нет", outAllSent = "Авто-предложения: всем уже предложено, следующий круг через 10 мин", outWait = "%s ничего не кладёт — отклоню через %d с", chatAdvertMsg = "Let's trade!", rerolling = "Убрал и вернул — значит, хочет другое: собираю другой набор", antiFling = "Анти-флинг", theme = "Акцент",
           font = "Шрифт", lang = "Язык", diff = "Показывать разницу", reset = "Вернуть плашку на место",
           loaded = "Цен загружено: %d", failed = "Цены не загрузились", noOffers = "Окно трейда не распознано",
           auto = "Автооффер", target = "Цель прибыли", enabled = "Скрипт включён", allLabel = "Все функции", allOff = "Всё выкл.", allOn = "Всё вкл.", allOffDone = "Все функции выключены", allOnDone = "Все функции включены", highlight = "Подсветка", autoAdd = "Авто-добавление",
           bl = "Нежелательные предметы", keep = "Не отдавать", keepTitle = "Не отдавать", myInv = "Мой инвентарь", invHint = "Пока пусто: открой любой трейд — скрипт запишет, что сейчас лежит в твоём инвентаре", invClear = "Очистить (обновится в следующем трейде)", keepHint = "Отмеченные предметы скрипт никогда сам не кладёт в трейд", orders = "Заявки", ordersSub = "%d заявок · на какой предмет что отдаёшь", ordersOn = "Заявки включены", ordNew = "+ Новая заявка", ordAddVar = "+ Вариант", ordDel = "Удалить заявку", ordPickTarget = "Выбери предмет, на который заявка", ordPickOffer = "Что отдаёшь за %s — нажимай на предметы", ordSave = "Сохранить", ordCancel = "Отмена", ordGive = "отдаёшь %s за %s", ordEmpty = "Выбери заявку слева или создай новую", ordNoVars = "Пока нет вариантов — добавь, что отдаёшь", ordProfit = "Своя прибыль за этот предмет", ordGone = "Заявка больше не подходит — убираю её предметы", ordProfitOn = "автооффер наберёт +%d%% (варианты не используются)", ordProfitOff = "выкл. — кладутся варианты ниже", ordProfitTag = " · заявка", ordApplied = "Заявка: %s за %s", chartTitle = "%s · сейчас %s", chartSince = "%s с %s · изменений: %d", chartLine = "Линия", chartCandles = "Свечи", candleTip = "<b>%s</b>\nоткр %s · макс %s\nмин %s · закр %s\n%s", kindGun = "пистолет", kindKnife = "нож", kindAsk = "%s: это нож или пистолет? (скрипт думает: %s)", kindBtnKnife = "Нож", kindBtnGun = "Пистолет", ordUnsure = "Заявка: определяю, нож это или пистолет… [%s]", chartFew = "История копится с %s — чем больше обновлений, тем подробнее график",  blCount = "%d шт.", autoDecline = "Автоотклонение", tolerance = "Допуск ±1%", fillOver = "Добивать сверх цели", adSent = "Написал в чат: Let's trade!", adFail = "Не получилось написать в чат: %s", tiers = "Прибыль по цене предмета (ступени)", tierUpTo = "до", tiersOn = "Включить ступени", tierCount = "%d ступ.", tierOff = "выкл.", tierAdd = "+ Ступень", tierHint = "Считается по цене того, что даёт он. Дороже последней ступени — её процент. Заявки со своей прибылью важнее.", mirrorEmpty = "Убирать, если он всё убрал", junkDecline = "Отклонять хлам (без цены)", giftAccept = "Принимать подарки", idleDecline = "Отклонять, если 20 с ничего не меняется", cheapGodly = "За мелочь — 1 самый дешёвый годли", cheapNeed = "Мелочь: за %s нужно от %s, он даёт %s", cheapOk = "Мелочь → %s x1", cheapDoing = "Кладу %s x1 за мелочь…", idleWait = "20 с ничего не меняется — отклоню через %d с", giftDoing = "Подарок: он принял, ты ничего не отдаёшь — принимаю (попытка %d)", junkWait = "У него только предметы без цены — отклоню через %d с", emptyDecline = "Пустой трейд: показать предметы и отклонить", nudgeWait = "Он ничего не предлагает — через %d с покажу предметы", nudging = "Показываю ему предметы…", blockedReq = "Отклонил запрос от %s (блок 80 с)", blockedTrade = "%s в блоке на 80 с — отказ", emptyWait = "Всё ещё пусто — отклоню через %d с", emptyCleared = "Он всё убрал — убираю и я", overTag = " (сверх цели)", autoAccept = "Автопринятие", accepting = "Принимаю трейд (+%d%%), способ %d", autoRequest = "Принимать запросы", chatAds = "Анализ чата", gives = "даёт", wants = "хочет", forYou = "для тебя", items = "предметы", anyOffers = "любые предложения", asksAdd = "просит добавить", requestAccepted = "Запрос на трейд принят", accepted = "Трейд принят: +%d%%",
           search = "Поиск…", marked = "Отмеченные", catMark = "Отметить всю категорию", catUnmark = "Снять отметки со всей категории", ordAddProfit = "+ Вариант: % прибыли", ordProfitVar = "Прибыль +%d%%", ordProfitVarSub = "автооффер наберёт с этой прибылью", all = "Все",
           cats = { sets = "Сеты", uniques = "Уникальные", ancients = "Древние", vintages = "Винтажные",
                    chromas = "Хромы", godlies = "Годли", legendaries = "Легендарные", rares = "Редкие",
                    uncommons = "Необычные", commons = "Обычные", pets = "Питомцы", misc = "Разное" }, declined = "Отклонено: %s", declineFail = "Не нашёл кнопку «Отклонить»", sugAuto = "Цель %s: добавляю ~%s: %s",
           sugPick = "Цель %s: выбери ~%s: %s (есть варианты)", sugAdd = "Цель %s: добавь ~%s: %s",
           sugOk = "Цель %s достигнута", sugRemove = "Цель %s: убери ~%s", sugRemoving = "Цель %s: убираю лишнее (~%s)", sugNone = "Цель %s: нечем добить (~%s)",
           sugWait = "Цель %s: ждём предметы соперника" },
    en = { you = "YOU", them = "THEM", win = "GAIN", good = "PROFIT", fair = "FAIR", bad = "LOSS", empty = "EMPTY",
           noPrice = "no price: %d", settings = "Settings", size = "Text size", scale = "Scale", tabMain = "General", tabTrade = "Trading", tabTrade2 = "Accepting", tabGame = "Other", tabChat = "Chat", valuesTitle = "Value list", invStats = "Inventory stats", invTotal = "Total inventory value", histItems = "Items", histSum = "Trades: %d · total: %s", histPending = "⏳ — being verified (%d): confirmed once the script sees your inventory (next trade or opening the inventory)", histTrades = "Trade history", histNone = "No trades yet — every completed trade will show up here", histGave = "gave", histGot = "got", invTitle = "Inventory · now %s", invNote = "24 h: %s  ·  7 days: %s  ·  points: %d", invEmpty = "No data yet: open a trade while your offer is empty — the script records your inventory value", openValues = "Open", rangeL = "Range", demandL = "Demand", rarityL = "Rarity", stab = {}, chatInTrade = "Show during a trade", chatRequests = "Follow chat requests", declineMsg = "Say why I decline in chat", declPress = "decline: buttons %d, try %d (methods fired: %s)", declWait = "Unwanted %s — declining in %d s", declNoBtn = "Decline button not found [%s]", declTry = "Unwanted item: %s — declining, try %d", reqPlan = "Asks: %s", reqAdd = "add %s", reqRemove = "remove %s", reqDone = "Request done", reqTooMuch = "Asks %s — more than they give", reqDoing = "Doing the request: %s", acc = { off = "", wait = "auto-accept: waiting for their items", busy = "auto-accept: adding items", unk = "auto-accept: you have unpriced items", bad = "auto-accept: unwanted item", low = "auto-accept: profit below target (%d%%)", hold = "auto-accept: checking %d s", countdown = "auto-accept: waiting for MM2 countdown", nobtn = "auto-accept: Accept button not found [%s]", click = "auto-accept: clicked, method %d (try %d)", gaveup = "auto-accept: 9 tries, no result" }, antiAfk = "Anti-AFK", chatAdvert = "«Let's trade!» in chat every 2.5 minutes", outreach = "Send trade requests to players in the list", outSent = "Sent a trade request: %s", outNoPlus = "Outreach: can't find «+» next to the player count", outNoList = "Outreach: pressed «+», but no player list", outNoTradeBtn = "Outreach: tapped %s, but no «Trade» button", outAllSent = "Outreach: everyone got a request, next round in 10 min", outWait = "%s puts nothing — declining in %d s", chatAdvertMsg = "Let's trade!", rerolling = "Removed and returned — wants something else: building another set", antiFling = "Anti-fling", theme = "Accent",
           font = "Font", lang = "Language", diff = "Show difference", reset = "Reset bar position",
           loaded = "Prices loaded: %d", failed = "Failed to load prices", noOffers = "Trade window not recognised",
           auto = "Auto-offer", target = "Profit target", enabled = "Script enabled", allLabel = "All features", allOff = "All off", allOn = "All on", allOffDone = "All features are off", allOnDone = "All features are on", highlight = "Highlight", autoAdd = "Auto-add",
           bl = "Unwanted items", keep = "Never give", keepTitle = "Never give", myInv = "My inventory", invHint = "Empty for now: open any trade — the script records what is in your inventory right now", invClear = "Clear (refreshes in the next trade)", keepHint = "Marked items are never put into a trade by the script", orders = "Orders", ordersSub = "%d orders · what you give for an item", ordersOn = "Orders enabled", ordNew = "+ New order", ordAddVar = "+ Variant", ordDel = "Delete order", ordPickTarget = "Pick the item this order is for", ordPickOffer = "What you give for %s — tap items", ordSave = "Save", ordCancel = "Cancel", ordGive = "you give %s for %s", ordEmpty = "Pick an order on the left or create one", ordNoVars = "No variants yet — add what you give", ordProfit = "Own profit for this item", ordGone = "Order no longer matches — taking its items back", ordProfitOn = "auto-offer aims for +%d%% (variants are not used)", ordProfitOff = "off — the variants below are used", ordProfitTag = " · order", ordApplied = "Order: %s for %s", chartTitle = "%s · now %s", chartSince = "%s since %s · changes: %d", chartLine = "Line", chartCandles = "Candles", candleTip = "<b>%s</b>\nopen %s · high %s\nlow %s · close %s\n%s", kindGun = "gun", kindKnife = "knife", kindAsk = "%s: knife or gun? (script thinks: %s)", kindBtnKnife = "Knife", kindBtnGun = "Gun", ordUnsure = "Order: checking whether it is a knife or a gun… [%s]", chartFew = "History is collected since %s — the more updates, the richer the chart",  blCount = "%d items", autoDecline = "Auto-decline", tolerance = "Allow ±1%", fillOver = "Top up past target", adSent = "Sent to chat: Let's trade!", adFail = "Could not write to chat: %s", tiers = "Profit by item value (tiers)", tierUpTo = "up to", tiersOn = "Enable tiers", tierCount = "%d tiers", tierOff = "off", tierAdd = "+ Tier", tierHint = "Based on the value of what they give. Above the last tier — its percent. Orders with their own profit come first.", mirrorEmpty = "Clear mine if they clear", junkDecline = "Decline junk (no value)", giftAccept = "Accept gifts", idleDecline = "Decline if nothing changes for 20 s", cheapGodly = "Small items → 1 cheapest godly", cheapNeed = "Small items: %s needs %s or more, they give %s", cheapOk = "Small items → %s x1", cheapDoing = "Adding %s x1 for small items…", idleWait = "Nothing changed for 20 s — declining in %d s", giftDoing = "Gift: they accepted, you give nothing — accepting (try %d)", junkWait = "Only unpriced items — declining in %d s", emptyDecline = "Empty trade: show items, then decline", nudgeWait = "They offer nothing — showing items in %d s", nudging = "Showing them items…", blockedReq = "Declined request from %s (80 s block)", blockedTrade = "%s is blocked for 80 s — declining", emptyWait = "Still empty — declining in %d s", emptyCleared = "They removed everything — removing mine", overTag = " (over target)", autoAccept = "Auto-accept", accepting = "Accepting trade (+%d%%), method %d", autoRequest = "Accept requests", chatAds = "Chat analysis", gives = "gives", wants = "wants", forYou = "for you", items = "items", anyOffers = "any offers", asksAdd = "asks to add", requestAccepted = "Trade request accepted", accepted = "Trade accepted: +%d%%",
           search = "Search…", marked = "Marked", catMark = "Mark the whole category", catUnmark = "Unmark the whole category", ordAddProfit = "+ Variant: profit %", ordProfitVar = "Profit +%d%%", ordProfitVarSub = "auto-offer aims for this profit", all = "All",
           cats = { sets = "Sets", uniques = "Uniques", ancients = "Ancients", vintages = "Vintages",
                    chromas = "Chromas", godlies = "Godlies", legendaries = "Legendaries", rares = "Rares",
                    uncommons = "Uncommons", commons = "Commons", pets = "Pets", misc = "Misc" }, declined = "Declined: %s", declineFail = "Decline button not found", sugAuto = "Target %s: adding ~%s: %s",
           sugPick = "Target %s: choose ~%s: %s (several options)", sugAdd = "Target %s: add ~%s: %s",
           sugOk = "Target %s reached", sugRemove = "Target %s: remove ~%s", sugRemoving = "Target %s: removing extra (~%s)", sugNone = "Target %s: nothing fits (~%s)",
           sugWait = "Target %s: waiting for their items" },
}
local function T(k) return (L[S.lang] or L.ru)[k] end

local notified = {}
local function notify(text)
    -- одно и то же сообщение не дублируем, пока прошлое ещё на экране (6 с)
    if os.clock() - (notified[text] or -1e9) < 6 then return end
    notified[text] = os.clock()
    pcall(function() StarterGui:SetCore("SendNotification", { Title = "Auto Trade", Text = text, Duration = 6 }) end)
end

------------------------------------------------------------------
-- Цены
------------------------------------------------------------------
local function norm(s) return (s or ""):lower():gsub("[%s%p]", "") end
-- lower() в Luau не трогает кириллицу («ОТКАЗ» так и остаётся заглавными) — переводим сами
env.TV_low = function(str)
    str = (str or ""):lower()
    if not str:find("[\208\209]") then return str end
    local out = {}
    for _, c in utf8.codes(str) do
        if c >= 1040 and c <= 1071 then c = c + 32 elseif c == 1025 then c = 1105 end
        table.insert(out, utf8.char(c))
    end
    return table.concat(out)
end
-- объект реально на экране: он и все родители видимы, окно включено
env.TV_vis = function(g)
    if not (g and g:IsA("GuiObject")) or g.AbsoluteSize.X < 4 then return false end
    local o = g
    while o and not o:IsA("ScreenGui") do
        if o:IsA("GuiObject") and not o.Visible then return false end
        o = o.Parent
    end
    return o ~= nil and o.Enabled
end
-- номер картинки из ссылки: «...?width=250&height=250&assetId=123» — нужен assetId, а не первое число (250)
env.TV_imgId = function(img)
    img = tostring(img or "")
    local id = img:match("[?&][Aa]sset[Ii]d=(%d+)") or img:match("[?&][Ii]d=(%d+)") or img:match("rbxassetid://(%d+)")
    if id then return id end
    local best = nil
    for run in img:gmatch("%d+") do if not best or #run > #best then best = run end end
    return best
end
-- текст кнопки: имя + Text + все ВИДИМЫЕ надписи внутри (скрытая «Please wait (2)…» внутри «Принять» не мешает)
env.TV_btnText = function(b)
    local parts = { b.Name, b:IsA("TextButton") and b.Text or "" }
    local own = b:IsA("TextButton") and b.Text ~= ""
    for _, l in ipairs(b:GetDescendants()) do
        if (l:IsA("TextLabel") or l:IsA("TextButton")) and l.Text ~= "" and env.TV_vis(l) then table.insert(parts, l.Text); own = true end
    end
    -- у MM2 кнопка бывает пустой («ActionButton»), а «ПРИНЯТЬ»/«ОТКАЗ» — отдельная надпись поверх неё:
    -- берём видимые надписи рядом, центр которых лежит на кнопке
    if not own and b.Parent then
        local scope = b.Parent.Parent or b.Parent
        local p0, sz = b.AbsolutePosition, b.AbsoluteSize
        for _, l in ipairs(scope:GetDescendants()) do
            if (l:IsA("TextLabel") or l:IsA("TextButton")) and l ~= b and l.Text ~= "" and not l:IsDescendantOf(b) then
                local c = l.AbsolutePosition + l.AbsoluteSize / 2
                if c.X >= p0.X and c.X <= p0.X + sz.X and c.Y >= p0.Y and c.Y <= p0.Y + sz.Y and env.TV_vis(l) then
                    table.insert(parts, l.Text)
                end
            end
        end
    end
    return env.TV_low(table.concat(parts, " "))
end

local valueMap, valueCount = {}, 0
local itemList = {}    -- все предметы { name, price, key } для раздела нежелательных
local itemsByCat = {}  -- категория -> список предметов
local catOrder = {}    -- порядок категорий как на сайте
local function loadValues()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(VALUES_URL .. "?t=" .. os.time()))
    end)
    if not ok or type(res) ~= "table" then warn("[TV] не загрузил цены:", res) return false end
    -- не показываем и не считаем: заглушки сайта и то, что нельзя передать
    local SKIP = { ["Black Luger"] = true, ["Nik's Scythe"] = true, ["Default Knife"] = true, ["Default Gun"] = true,
        ["Small Set (107)"] = true, ["Small Set (103)"] = true, ["Full Chroma Set"] = true, ["Chroma Weapon Set"] = true } -- наборы «всего подряд»
    local map, n = {}, 0
    for k, v in pairs(res.values or res) do
        if tonumber(v) and not SKIP[k] and tonumber(v) < 1000000 then map[norm(k)] = tonumber(v); n += 1 end
    end
    valueMap, valueCount = map, n
    -- одно игровое название — несколько разных предметов с разной ценой («CandyCorn» 2017 и «Candy Corn» 2019/2026,
    -- godly и vintage «Laser»): по названию цену не угадать
    local ambig, firstV = {}, {}
    for k, v in pairs(res.values or res) do
        local nk, nv = norm(k), tonumber(v)
        if nv and not k:find(" Set", 1, true) then -- сеты в инвентаре не лежат («Sun Set» ≠ «Sunset»)
            if firstV[nk] and firstV[nk] ~= nv then ambig[nk] = true end
            firstV[nk] = firstV[nk] or nv
        end
    end
    for _, names in pairs(res.cat_values or {}) do
        for name, cv in pairs(names) do
            for _, key in ipairs(name:find(" Set", 1, true) and {} or { norm(name), norm((name:gsub("%s*%b()$", ""))) }) do
                if map[key] and tonumber(cv) ~= map[key] then ambig[key] = true end
            end
        end
    end
    env.TV_ambig = ambig
    env.TV_catVals = res.cat_values or {}
    local primCat = {}
    for cat, names in pairs(res.categories or {}) do
        for _, name in ipairs(names) do
            local cv = (res.cat_values or {})[cat]
            if not (cv and cv[name] ~= nil) and map[norm(name)] then primCat[norm(name)] = primCat[norm(name)] or cat end
        end
    end
    env.TV_primCat = primCat
    env.TV_setItems = res.set_items or {} -- из каких предметов состоит каждый сет
    local arr = {}
    for k, v in pairs(res.values or res) do
        if map[norm(k)] and not SKIP[k] then table.insert(arr, { name = k, price = tonumber(v), key = norm(k) }) end
    end
    -- в списках только предметы с ценой (без цены = уникальные с владельцем и т.п., их не передать)
    local seen = {}
    for _, it in ipairs(arr) do seen[it.key] = it end
    local byCat = {}
    local catVals = res.cat_values or {}
    local byName = {}
    for _, it in ipairs(arr) do byName[it.name] = it end
    for cat, names in pairs(res.categories or {}) do
        local lst, inCat = {}, {}
        for _, name in ipairs(names) do
            -- сначала точное название («Rainbow (Gun)» и «Rainbow Gun» — разные предметы)
            local it = byName[name] or seen[norm(name)]
            local cv = catVals[cat] and catVals[cat][name]
            if cv ~= nil then
                -- то же название, но другая категория: своя цена (или текст вроде «x2 T1 Uncommons») и своя картинка
                it = { name = name, price = tonumber(cv), vtext = (not tonumber(cv)) and tostring(cv) or nil,
                    key = norm(name), cat = cat,
                    img = cat .. "_" .. ((name:find(" Set", 1, true) and "set" or "") .. norm(name)) }
            end
            if it and cat == "pets" and not it.cat then
                -- у питомца своя картинка (у ножа «Reindeer» и питомца «Reindeer» одно название)
                it = { name = it.name, price = it.price, key = it.key, cat = "pets", primary = true, img = "pets_" .. it.key }
            end
            if it and not SKIP[name] and not inCat[it] then inCat[it] = true; table.insert(lst, it) end
        end
        -- дорогие сверху; предметы с ценой текстом («x2 T1 Commons») — после
        table.sort(lst, function(a, b)
            if (a.price ~= nil) ~= (b.price ~= nil) then return a.price ~= nil end
            return (a.price or 0) > (b.price or 0)
        end)
        byCat[cat] = lst
    end
    env.TV_changes = res.changes or {}
    env.TV_globalKinds = res.img_kinds or {} -- общие для всех: номер картинки -> "knife"/"gun"
    env.TV_info = res.info or {}
    env.TV_hist = res.history or {}
    -- «Все» = только предметы из категорий сайта (без моих вспомогательных названий вроде «C. X» / «Latte»)
    local listed, inAny = {}, {}
    for _, lst in pairs(byCat) do for _, it in ipairs(lst) do inAny[it] = true end end
    local petKeys = {}
    for _, it in ipairs(byCat.pets or {}) do if it.primary then petKeys[it.key] = it end end
    for _, it in ipairs(arr) do
        if petKeys[it.key] then table.insert(listed, petKeys[it.key])
        elseif inAny[it] or not res.categories then table.insert(listed, it) end
    end
    for _, lst in pairs(byCat) do for _, it in ipairs(lst) do if it.cat and not it.primary then table.insert(listed, it) end end end
    table.sort(listed, function(a, b) return (a.price or -1) > (b.price or -1) end)
    table.sort(arr, function(a, b) return (a.price or -1) > (b.price or -1) end)
    itemList, itemsByCat, catOrder = listed, byCat, res.category_order or {}
    local names = {}
    for _, it in ipairs(arr) do if it.price then names[it.key] = names[it.key] or it.name end end
    env.TV_names = names
    return true
end

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
-- надпись; bold = цифры/заголовки, иначе обычный вес
local function label(parent, props, bold)
    local t = new("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = C.text, TextSize = 14, RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    }, parent)
    for k, v in pairs(props or {}) do t[k] = v end
    themed(function() t.Font = bold and fontBold() or fontReg() end)
    return t
end
local function hex(c)
    return ("#%02X%02X%02X"):format(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function tween(o, t, props, style)
    TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end
local function hover(btn, normal, hot)
    on(btn.MouseEnter, function() tween(btn, 0.15, { BackgroundColor3 = hot }) end)
    on(btn.MouseLeave, function() tween(btn, 0.15, { BackgroundColor3 = normal }) end)
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

local ui = new("ScreenGui", { Name = "TVOverlayUI", ResetOnSpawn = false, DisplayOrder = 1000, IgnoreGuiInset = true, AutoLocalize = false }, PlayerGui)

-- общий масштаб: под высоту экрана (720p = 1) и ручная поправка из настроек
local function sf()
    local h = ui.AbsoluteSize.Y
    local base = h > 0 and math.clamp(h / 720, 0.8, 1.8) or 1
    return base * (S.uiScale or 1)
end

------------------------------------------------------------------
-- Плашка над трейдом:  ТЫ 1 500 | ВИН 62% ▬▬▬ | ОН 2 400 (+900)
------------------------------------------------------------------
local hud = new("Frame", {
    AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), Visible = false,
    BackgroundColor3 = C.bg, BackgroundTransparency = 0.08,
}, ui)
corner(hud, 14)
stroke(hud)
pad(hud, 16, 10)
list(hud, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)
local hudScale = new("UIScale", {}, hud)
local topRow = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 1 }, hud)
list(topRow, Enum.FillDirection.Horizontal, 18, nil, Enum.VerticalAlignment.Center)

local function sideBlock(order, align)
    local b = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = order }, topRow)
    list(b, Enum.FillDirection.Vertical, 1, align)
    local cap = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextColor3 = C.muted, LayoutOrder = 1 })
    local val = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 2 }, true)
    local note = label(b, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextColor3 = C.muted, LayoutOrder = 3, Visible = false })
    return cap, val, note
end
local youCap, youVal, youNote = sideBlock(1, Enum.HorizontalAlignment.Left)

local mid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 40), LayoutOrder = 2 }, topRow)
local winLabel = label(mid, { Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Center }, true)
local statusLabel = label(mid, { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.muted })
local track = new("Frame", { BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.9, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 21), BorderSizePixel = 0 }, mid)
corner(track, 3)
local fill = new("Frame", { BackgroundColor3 = C.good, Size = UDim2.fromScale(0.5, 1), BorderSizePixel = 0 }, track)
corner(fill, 3)
local fillGrad = new("UIGradient", {}, fill)
new("Frame", { BackgroundColor3 = C.text, BackgroundTransparency = 0.55, BorderSizePixel = 0, Size = UDim2.new(0, 2, 1, 6), Position = UDim2.new(0.5, -1, 0, -3) }, track)

local themCap, themVal, themNote = sideBlock(3, Enum.HorizontalAlignment.Right)

-- строка автооффера под плашкой
local sugLine = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.2, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 2, Visible = false }, hud)
corner(sugLine, 8)
pad(sugLine, 10, 4)
local sugText = label(sugLine, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 13 })

makeDraggable(hud, hud, nil, function()
    local abs = ui.AbsoluteSize
    S.hudX, S.hudY = hud.AbsolutePosition.X / abs.X, hud.AbsolutePosition.Y / abs.Y
    hud.Position = UDim2.fromScale(S.hudX, S.hudY)
    saveSettings()
end)
local function placeHud()
    if S.hudX then
        hud.AnchorPoint, hud.Position = Vector2.zero, UDim2.fromScale(S.hudX, S.hudY)
    else
        hud.AnchorPoint, hud.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.09)
    end
end
placeHud()

local X = {} -- ссылки на элементы интерфейса (в одной таблице: в Luau не больше 200 локальных)

------------------------------------------------------------------
-- Кнопка ⚙️
------------------------------------------------------------------
local gear = new("TextButton", {
    Size = UDim2.fromOffset(46, 46), Position = UDim2.fromScale(S.iconX, S.iconY),
    BackgroundColor3 = rgb(255, 255, 255), Text = "", AutoButtonColor = false,
}, ui)
corner(gear, 14)
local gearRing = stroke(gear, rgb(255, 255, 255), 0.75, 1.5)
do
    -- фон — градиент акцента; надпись отдельным объектом, иначе градиент перекрасит и её
    local g = new("UIGradient", { Rotation = 45 }, gear)
    themed(function() g.Color = ColorSequence.new(accent():Lerp(rgb(255, 255, 255), 0.12), accent():Lerp(rgb(0, 0, 0), 0.4)) end)
    X.gearText = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "AT", TextColor3 = rgb(255, 255, 255),
        TextSize = 19, Font = Enum.Font.GothamBlack }, gear)
    X.gearImg = new("ImageLabel", { Size = UDim2.fromScale(0.8, 0.8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit }, gear)
end
local gearScale = new("UIScale", {}, gear)
on(gear.MouseEnter, function() tween(gearScale, 0.15, { Scale = sf() * 1.08 }) end)
on(gear.MouseLeave, function() tween(gearScale, 0.15, { Scale = sf() }) end)

------------------------------------------------------------------
-- Окно настроек
------------------------------------------------------------------
local panel = new("Frame", {
    Size = UDim2.fromOffset(440, 0), AutomaticSize = Enum.AutomaticSize.Y,
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.08), Visible = false,
    BackgroundColor3 = C.bg, BackgroundTransparency = 0.04,
}, ui)
corner(panel, 18)
stroke(panel)
pad(panel, 16, 16)
list(panel, Enum.FillDirection.Vertical, 6)
local panelScale = new("UIScale", {}, panel)

-- шапка: логотип, название, закрыть
local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 0 }, panel)
local logo = new("TextLabel", {
    Size = UDim2.fromOffset(38, 38), BackgroundColor3 = accent(), Text = "", TextColor3 = rgb(255, 255, 255),
    TextSize = 15, Font = Enum.Font.GothamBold,
}, head)
X.logoText = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "AT", TextColor3 = rgb(255, 255, 255),
    TextSize = 16, Font = Enum.Font.GothamBlack }, logo)
X.logoImg = new("ImageLabel", { Size = UDim2.fromScale(0.82, 0.82), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit }, logo)
corner(logo, 11)
local logoGrad = new("UIGradient", { Rotation = 45 }, logo)
themed(function()
    logo.BackgroundColor3 = rgb(255, 255, 255)
    logoGrad.Color = ColorSequence.new(accent(), accent():Lerp(rgb(0, 0, 0), 0.35))
end)
local title = label(head, { Size = UDim2.new(1, -96, 0, 20), Position = UDim2.fromOffset(50, 1), TextSize = 17 }, true)
local subtitle = label(head, { Size = UDim2.new(1, -96, 0, 14), Position = UDim2.fromOffset(50, 22), TextSize = 12, TextColor3 = C.muted })
local closeBtn = new("TextButton", {
    Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
    BackgroundColor3 = C.card, Text = "", AutoButtonColor = false,
}, head)
corner(closeBtn, 16)
stroke(closeBtn)
local crossBars = {}
for _, rot in ipairs({ 45, -45 }) do -- крестик из двух полосок
    local bar = new("Frame", {
        BackgroundColor3 = C.muted, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(13, 2), Rotation = rot,
    }, closeBtn)
    corner(bar, 1)
    table.insert(crossBars, bar)
end
on(closeBtn.MouseEnter, function()
    tween(closeBtn, 0.15, { BackgroundColor3 = C.bad })
    for _, b in ipairs(crossBars) do tween(b, 0.15, { BackgroundColor3 = rgb(255, 255, 255) }) end
end)
on(closeBtn.MouseLeave, function()
    tween(closeBtn, 0.15, { BackgroundColor3 = C.card })
    for _, b in ipairs(crossBars) do tween(b, 0.15, { BackgroundColor3 = C.muted }) end
end)
makeDraggable(title, panel)
makeDraggable(logo, panel)

-- вкладки: Основное | Трейд
local tabBar = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card, BackgroundTransparency = 0.3, LayoutOrder = 1 }, panel)
corner(tabBar, 10)
stroke(tabBar)
local tabKnob = new("Frame", { Size = UDim2.new(1 / 5, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = accent() }, tabBar)
corner(tabKnob, 8)
local tabMainBtn = new("TextButton", { Size = UDim2.fromScale(1 / 5, 1), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 14, ZIndex = 2 }, tabBar)
local tabTradeBtn = new("TextButton", { Size = UDim2.fromScale(1 / 5, 1), Position = UDim2.fromScale(1 / 5, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 14, ZIndex = 2 }, tabBar)
themed(function() tabMainBtn.Font, tabTradeBtn.Font = fontBold(), fontBold() end)

-- ряды настроек на «карточках» (по одной на вкладку)
local function makeBody(visible)
    local b = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Visible = visible }, panel)
    corner(b, 12)
    stroke(b)
    list(b, Enum.FillDirection.Vertical, 0, Enum.HorizontalAlignment.Center)
    new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }, b)
    return b
end
local bodyMain, bodyTrade = makeBody(true), makeBody(false)
local body = bodyMain
local rowCounts = {}
local curTab = "main"

local function row()
    local rowCount = (rowCounts[body] or 0) + 1
    rowCounts[body] = rowCount
    local sep
    if rowCount > 1 then
        sep = new("Frame", { BackgroundColor3 = C.line, BackgroundTransparency = 0.94, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 1), LayoutOrder = rowCount * 2 - 1 }, body)
    end
    local r = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = rowCount * 2 }, body)
    pad(r, 12, 0)
    local name = label(r, { Size = UDim2.new(0.5, 0, 1, 0), TextSize = 14 })
    return r, name, sep
end
local function control(parent, w, h)
    local f = new("Frame", {
        Size = UDim2.fromOffset(w, h or 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2,
    }, parent)
    corner(f, 9)
    stroke(f)
    return f
end
local function flatBtn(parent, text, size, pos)
    local b = new("TextButton", {
        Size = size, Position = pos, BackgroundColor3 = C.bg, BackgroundTransparency = 1,
        Text = text, TextColor3 = C.text, TextSize = 16, AutoButtonColor = false,
    }, parent)
    themed(function() b.Font = fontBold() end)
    on(b.MouseEnter, function() tween(b, 0.12, { BackgroundTransparency = 0.6 }) end)
    on(b.MouseLeave, function() tween(b, 0.12, { BackgroundTransparency = 1 }) end)
    corner(b, 8)
    return b
end

-- переключатель: возвращает кнопку и функцию отрисовки состояния
local function makeToggle(r)
    local t = new("TextButton", {
        Size = UDim2.fromOffset(46, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = rgb(60, 62, 74), Text = "", AutoButtonColor = false,
    }, r)
    corner(t, 13)
    local k = new("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = rgb(255, 255, 255) }, t)
    corner(k, 10)
    return t, function(state)
        tween(t, 0.2, { BackgroundColor3 = state and accent() or rgb(60, 62, 74) })
        tween(k, 0.2, { Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
    end
end

-- главный переключатель
local rOn, lOn = row()
lOn.Size = UDim2.new(0.75, 0, 1, 0)
local onToggle, drawOn = makeToggle(rOn)
-- все функции разом: выключить / включить
do
    local r, l = row()
    l.Size = UDim2.new(0.45, 0, 1, 0)
    X.allLabel = l
    local box = control(r, 190)
    X.allOff = flatBtn(box, "", UDim2.new(0.5, -2, 1, 0), UDim2.fromOffset(0, 0))
    X.allOn = flatBtn(box, "", UDim2.new(0.5, -2, 1, 0), UDim2.new(0.5, 2, 0, 0))
    X.allOff.TextSize, X.allOn.TextSize = 13, 13
end

-- размер текста:  − 16 +
local rSize, lSize = row()
local stepper = control(rSize, 108)
local minus = flatBtn(stepper, "−", UDim2.fromOffset(32, 30), UDim2.fromOffset(0, 0))
local sizeVal = label(stepper, { Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(32, 0), TextXAlignment = Enum.TextXAlignment.Center }, true)
local plus = flatBtn(stepper, "+", UDim2.fromOffset(32, 30), UDim2.new(1, -32, 0, 0))

-- масштаб интерфейса:  − 100% +
local rScale, lScale = row()
local scStepper = control(rScale, 108)
local scMinus = flatBtn(scStepper, "−", UDim2.fromOffset(32, 30), UDim2.fromOffset(0, 0))
local scaleVal = label(scStepper, { Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(32, 0), TextXAlignment = Enum.TextXAlignment.Center }, true)
local scPlus = flatBtn(scStepper, "+", UDim2.fromOffset(32, 30), UDim2.new(1, -32, 0, 0))

-- акцент: кружки
local rTheme, lTheme = row()
local dots = {}
for i, col in ipairs(ACCENTS) do
    local b = new("TextButton", {
        Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -27 * (#ACCENTS - i), 0.5, 0), BackgroundColor3 = col, Text = "", AutoButtonColor = false,
    }, rTheme)
    corner(b, 10)
    local ring = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 2, Color = rgb(255, 255, 255) }, b)
    local sc = new("UIScale", {}, b)
    dots[i] = { ring = ring, scale = sc }
    on(b.Activated, function() S.theme = i; saveSettings(); env.TV_refresh() end)
end

-- шрифт:  ‹ Gotham ›
local rFont, lFont = row()
local fontBox = control(rFont, 140)
local fontPrev = flatBtn(fontBox, "<", UDim2.fromOffset(28, 30), UDim2.fromOffset(0, 0))
local fontName = label(fontBox, { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(28, 0), TextXAlignment = Enum.TextXAlignment.Center }, true)
local fontNext = flatBtn(fontBox, ">", UDim2.fromOffset(28, 30), UDim2.new(1, -28, 0, 0))

-- язык: RU | EN
local rLang, lLang = row()
local seg = control(rLang, 100)
local segKnob = new("Frame", { Size = UDim2.new(0.5, -4, 1, -4), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = accent() }, seg)
corner(segKnob, 7)
local ruBtn = new("TextButton", { Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, Text = "RU", TextColor3 = C.text, TextSize = 13, ZIndex = 2 }, seg)
local enBtn = new("TextButton", { Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1, Text = "EN", TextColor3 = C.text, TextSize = 13, ZIndex = 2 }, seg)
themed(function() ruBtn.Font, enBtn.Font = fontBold(), fontBold() end)

-- показывать разницу
local rDiff, lDiff = row()
lDiff.Size = UDim2.new(0.75, 0, 1, 0)
local toggle, drawDiff = makeToggle(rDiff)

-- ссылки на элементы настроек (в одной таблице: в Luau не больше 200 локальных на уровень)

-- строка состояния автопринятия под плашкой
X.accLine = label(hud, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 12, TextColor3 = C.muted, LayoutOrder = 3, Visible = false })
-- что скрипт видит в ячейках предметов с двумя видами (нож/пистолет с одним названием)
X.kindLine = label(hud, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 11, TextColor3 = C.muted, LayoutOrder = 4,
    Visible = false, TextWrapped = false })
-- «это нож или пистолет?» — один раз нажать, скрипт запоминает картинку навсегда
X.kindAsk = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = 5, Visible = false }, hud)
list(X.kindAsk, Enum.FillDirection.Horizontal, 6)
X.kindAskText = label(X.kindAsk, { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextSize = 12, LayoutOrder = 1 })
X.kindBtns = {}
for i, kind in ipairs({ "knife", "gun" }) do
    local b = new("TextButton", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), BackgroundColor3 = C.card, Text = "",
        TextColor3 = C.text, TextSize = 12, AutoButtonColor = false, LayoutOrder = 1 + i }, X.kindAsk)
    corner(b, 7)
    stroke(b, accent(), 0.4)
    pad(b, 10, 0)
    themed(function() b.Font = fontBold() end)
    X.kindBtns[kind] = b
end

-- «Таблица цен» (как на сайте) — последний ряд вкладки «Основное»
do
    local r, l = row()
    X.valuesLabel = l
    X.valuesOpen = new("TextButton", {
        Size = UDim2.fromOffset(96, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
    }, r)
    corner(X.valuesOpen, 9)
    stroke(X.valuesOpen)
    themed(function() X.valuesOpen.Font = fontBold() end)
    r, l = row()
    X.statsLabel = l
    X.statsOpen = new("TextButton", {
        Size = UDim2.fromOffset(96, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
    }, r)
    corner(X.statsOpen, 9)
    stroke(X.statsOpen)
    themed(function() X.statsOpen.Font = fontBold() end)
    r, l = row()
    X.histLabel = l
    X.histOpen = new("TextButton", {
        Size = UDim2.fromOffset(96, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
    }, r)
    corner(X.histOpen, 9)
    stroke(X.histOpen)
    themed(function() X.histOpen.Font = fontBold() end)
end

body = bodyTrade
-- автооффер: вкл/выкл и цель прибыли
local rAuto, lAuto = row()
lAuto.Size = UDim2.new(0.75, 0, 1, 0)
local autoToggle, drawAuto = makeToggle(rAuto)
local rTarget, lTarget, sepTarget = row()
local tStepper = control(rTarget, 108)
local tMinus = flatBtn(tStepper, "−", UDim2.fromOffset(32, 30), UDim2.fromOffset(0, 0))
local targetVal = new("TextBox", {
    Size = UDim2.new(1, -64, 1, 0), Position = UDim2.fromOffset(32, 0), BackgroundTransparency = 1,
    TextColor3 = C.text, TextSize = 14, ClearTextOnFocus = true, Text = "", PlaceholderText = "%",
    PlaceholderColor3 = C.muted,
}, tStepper)
themed(function() targetVal.Font = fontBold() end)
local tPlus = flatBtn(tStepper, "+", UDim2.fromOffset(32, 30), UDim2.new(1, -32, 0, 0))
-- ступени прибыли: чем дороже то, что даёт он, тем меньше процент
do
    local r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    l.Size = UDim2.new(0.55, 0, 1, 0)
    X.tierLabel = l
    -- сами ступени — в отдельном окне (на телефоне настройки в две колонки, список туда не помещается)
    X.tierOpen = new("TextButton", {
        Size = UDim2.fromOffset(110, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
    }, r)
    corner(X.tierOpen, 9)
    stroke(X.tierOpen)
    themed(function() X.tierOpen.Font = fontBold() end)
end

-- подсветка и авто-добавление — независимые переключатели
local rHl, lHl, sepHl = row()
lHl.Size = UDim2.new(0.75, 0, 1, 0)
local hlToggle, drawHl = makeToggle(rHl)
local rAdd, lAdd, sepAdd = row()
lAdd.Size = UDim2.new(0.75, 0, 1, 0)
local addToggle, drawAdd = makeToggle(rAdd)
local rTol, lTol, sepTol = row()
lTol.Size = UDim2.new(0.75, 0, 1, 0)
local tolToggle, drawTol = makeToggle(rTol)
do
    local r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.fillLabel = l
    X.fillToggle, X.drawFill = makeToggle(r)
    -- дальше — вкладка «Принятие»: отказы, подарки, запросы, автопринятие
    X.tabTrade2Btn = new("TextButton", { Size = UDim2.fromScale(1 / 5, 1), Position = UDim2.fromScale(2 / 5, 0), BackgroundTransparency = 1,
        Text = "", TextColor3 = C.text, TextSize = 14, ZIndex = 2 }, tabBar)
    themed(function() X.tabTrade2Btn.Font = fontBold() end)
    X.bodyTrade2 = makeBody(false)
    body = X.bodyTrade2
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.mirrorLabel = l
    X.mirrorToggle, X.drawMirror = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.emptyLabel = l
    X.emptyToggle, X.drawEmpty = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.junkLabel = l
    X.junkToggle, X.drawJunk = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.giftLabel = l
    X.giftToggle, X.drawGift = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.idleLabel = l
    X.idleToggle, X.drawIdle = makeToggle(r)
end

-- вход в раздел нежелательных предметов
local rBl, lBl = row()
lBl.Size = UDim2.new(0.6, 0, 1, 0)
local blOpen = new("TextButton", {
    Size = UDim2.fromOffset(96, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
    BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
}, rBl)
corner(blOpen, 9)
stroke(blOpen)
themed(function() blOpen.Font = fontBold() end)
body = bodyTrade
do
    local r, l = row()
    l.Size = UDim2.new(0.6, 0, 1, 0)
    X.ordLabel = l
    X.ordOpen = new("TextButton", {
        Size = UDim2.fromOffset(96, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
    }, r)
    corner(X.ordOpen, 9)
    stroke(X.ordOpen)
    themed(function() X.ordOpen.Font = fontBold() end)
end
-- «Не отдавать»: свои предметы, которые скрипт никогда не кладёт в трейд
do
    local r, l = row()
    l.Size = UDim2.new(0.6, 0, 1, 0)
    X.keepLabel = l
    X.keepOpen = new("TextButton", {
        Size = UDim2.fromOffset(96, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "", TextColor3 = C.text, TextSize = 13, AutoButtonColor = false,
    }, r)
    corner(X.keepOpen, 9)
    stroke(X.keepOpen)
    themed(function() X.keepOpen.Font = fontBold() end)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.cheapLabel = l
    X.cheapToggle, X.drawCheap = makeToggle(r)
end

-- сброс позиции плашки (последний ряд вкладки «Трейд»)
-- автопринятие (ссылки в одной таблице: в Luau не больше 200 локальных на уровень)
body = X.bodyTrade2
do
    local r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.reqLabel = l
    X.reqToggle, X.drawReq = makeToggle(r)
end
do
    local r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.accLabel = l
    X.accToggle, X.drawAcc = makeToggle(r)
end

body = bodyTrade
local rReset = row()
local resetBtn = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 32), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
    BackgroundColor3 = C.card, BackgroundTransparency = 0.3,
    Text = "", TextColor3 = C.text, TextSize = 14, AutoButtonColor = false, ZIndex = 2,
}, rReset)
corner(resetBtn, 11)
local resetStroke = stroke(resetBtn, accent(), 0.5)
themed(function() resetBtn.Font = fontBold(); resetBtn.TextColor3 = accent(); resetStroke.Color = accent() end)
hover(resetBtn, C.card, rgb(35, 38, 50))
local footer = label(panel, { Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 3 })

-- вкладка «Игрок»
X.tabGameBtn = new("TextButton", { Size = UDim2.fromScale(1 / 5, 1), Position = UDim2.fromScale(3 / 5, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 14, ZIndex = 2 }, tabBar)
themed(function() X.tabGameBtn.Font = fontBold() end)
X.bodyGame = makeBody(false)
body = X.bodyGame
do
    local r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.afkLabel = l
    X.afkToggle, X.drawAfk = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.flingLabel = l
    X.flingToggle, X.drawFling = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.adLabel = l
    X.adToggle, X.drawAd = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.outLabel = l
    X.outToggle, X.drawOut = makeToggle(r)
end

-- вкладка «Чат»
X.tabChatBtn = new("TextButton", { Size = UDim2.fromScale(1 / 5, 1), Position = UDim2.fromScale(4 / 5, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 14, ZIndex = 2 }, tabBar)
themed(function() X.tabChatBtn.Font = fontBold() end)
X.bodyChat = makeBody(false)
body = X.bodyChat
do
    local r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.chatLabel = l
    X.chatToggle, X.drawChat = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.chatTradeLabel = l
    X.chatTradeToggle, X.drawChatTrade = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.chatReqLabel = l
    X.chatReqToggle, X.drawChatReq = makeToggle(r)
    r, l = row()
    l.Size = UDim2.new(0.75, 0, 1, 0)
    X.declMsgLabel = l
    X.declMsgToggle, X.drawDeclMsg = makeToggle(r)
end

------------------------------------------------------------------
-- Раздел «Нежелательные предметы»: слева категории как на сайте, справа список
------------------------------------------------------------------
local blPage -- (остальное окно внутри блока: в Luau не больше 200 локальных на уровень)
;(function()
local PAGE_W, PAGE_H, SIDE_W = 620, 470, 160
blPage = new("Frame", {
    Size = UDim2.fromOffset(PAGE_W, PAGE_H), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Visible = false, BackgroundColor3 = C.bg, BackgroundTransparency = 0.04,
}, ui)
corner(blPage, 18)
stroke(blPage)
pad(blPage, 16, 16)
local blScale = new("UIScale", {}, blPage)
local function fitScale() -- на маленьком экране окно уменьшается
    local abs = ui.AbsoluteSize
    return math.min(sf(), (abs.X - 24) / PAGE_W, (abs.Y - 24) / PAGE_H)
end

local blHead = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) }, blPage)
local backBtn = new("TextButton", {
    Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.card, Text = "<", TextColor3 = C.text, TextSize = 18, AutoButtonColor = false,
}, blHead)
corner(backBtn, 16)
stroke(backBtn)
themed(function() backBtn.Font = fontBold() end)
hover(backBtn, C.card, rgb(40, 43, 56))
local blTitle = label(blHead, { Size = UDim2.new(1, -260, 0, 18), Position = UDim2.fromOffset(44, 0), TextSize = 16 }, true)
local blSub = label(blHead, { Size = UDim2.new(1, -260, 0, 14), Position = UDim2.fromOffset(44, 19), TextSize = 12, TextColor3 = C.muted })
makeDraggable(blTitle, blPage)

-- автоотклонение — справа в шапке
local declBox = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.fromOffset(210, 34),
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0) }, blHead)
corner(declBox, 10)
stroke(declBox)
pad(declBox, 10, 0)
local lDecl = label(declBox, { Size = UDim2.new(1, -54, 1, 0), TextSize = 13 })
local declToggle, drawDecl = makeToggle(declBox)

-- левая колонка: категории
local side = new("ScrollingFrame", {
    Size = UDim2.new(0, SIDE_W, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundColor3 = C.card, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, blPage)
corner(side, 12)
stroke(side)
pad(side, 6, 6)
list(side, Enum.FillDirection.Vertical, 2)

-- правая часть: поиск и список
local right = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -SIDE_W - 12, 1, -46), Position = UDim2.fromOffset(SIDE_W + 12, 46) }, blPage)
local searchBox = new("TextBox", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.card, BackgroundTransparency = 0.3,
    Text = "", PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 14, ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, right)
corner(searchBox, 10)
stroke(searchBox)
pad(searchBox, 12, 0)
themed(function() searchBox.Font = fontReg() end)

local scroll = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -42), Position = UDim2.fromOffset(0, 42), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, right)
list(scroll, Enum.FillDirection.Vertical, 4)
themed(function() scroll.ScrollBarImageColor3 = accent() end)

local curCat = "godlies"
local mode = "bl" -- "bl" = нежелательные с галочками, "keep" = не отдавать (тоже галочки), "values" = таблица цен как на сайте
local function marks()
    S.keep = S.keep or {}
    return mode == "keep" and S.keep or S.blacklist
end
local function rowKey(it) return (it.cat and not it.primary) and (it.cat .. ":" .. it.key) or it.key end
-- ключи отметок предметов сета (как у строк этих предметов в списке)
local function setMemberKeys(it)
    local mem = (env.TV_setItems or {})[it.name]
    if not mem then return nil end
    local keys = {}
    for _, m in ipairs(mem) do
        local k = norm(m[2])
        local pc = (env.TV_primCat or {})[k]
        table.insert(keys, (pc == nil or pc == m[1] or m[1] == "pets") and k or (m[1] .. ":" .. k))
    end
    return keys
end
-- сет отмечен сам или отмечены все его предметы
local function setAllMarked(it, m)
    local keys = setMemberKeys(it)
    if not keys or #keys == 0 then return false end
    for _, k in ipairs(keys) do if not m[k] then return false end end
    return true
end
-- в трейде видно только название: отмечен хоть один предмет с таким названием — значит, отмечено
env.TV_markSet = function(tbl)
    local set = {}
    for k, name in pairs(tbl or {}) do
        set[norm(tostring(name))] = name
        if not k:find(":", 1, true) then set[k] = name end
    end
    return set
end
local function blCount()
    local n = 0
    for _ in pairs(marks()) do n += 1 end
    return n
end
local renderList, renderSide
local STAB_COLORS = { ["Stable"] = C.muted, ["Doing Well"] = C.good, ["Fluctuating"] = C.fair, ["Underpaid For"] = C.bad, ["Overpaid For"] = C.good }

local function itemRow(it, order)
    local on_ = mode ~= "values" and (marks()[rowKey(it)] ~= nil or setAllMarked(it, marks()))
    local info = mode == "values" and (env.TV_info or {})[it.name] or nil
    local r = new("TextButton", {
        Size = UDim2.new(1, -6, 0, info and 54 or 40), BackgroundColor3 = C.card, BackgroundTransparency = on_ and 0.1 or 0.6,
        ClipsDescendants = true, Text = "", AutoButtonColor = false, LayoutOrder = order,
    }, scroll)
    corner(r, 9)
    pad(r, 6, 0)
    -- картинка предмета (если удалось достать из игры)
    local pic = new("ImageLabel", { Size = UDim2.fromOffset(info and 44 or 32, info and 44 or 32), Position = UDim2.fromOffset(0, info and 5 or 4), BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.4, ScaleType = Enum.ScaleType.Fit, Image = "" }, r)
    pic.Image = env.TV_image and env.TV_image(it.name, function(asset) if pic.Parent then pic.Image = asset end end, it.img) or ""
    corner(pic, 7)
    -- надписи строк создаются напрямую (не через label), чтобы не копить подписки на тему
    local nameX = info and 54 or 42
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -168 - nameX, 0, info and 30 or 40), Position = UDim2.fromOffset(nameX, info and 4 or 0), Text = it.name,
        TextColor3 = C.text, TextSize = 14, Font = fontBold(), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd }, r)
    local rightPad = mode ~= "values" and 30 or 4
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(it.vtext and 120 or 70, info and 30 or 40), AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -rightPad, 0, info and 4 or 0), TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = info and C.text or C.muted, TextSize = it.vtext and 11 or (info and 14 or 12), Font = info and fontBold() or fontReg(),
        Text = it.price and env.TV_fmt(it.price) or it.vtext or "-" }, r)
    -- строка деталей как на сайте: диапазон · спрос · редкость · стабильность
    if info then
        local parts = {}
        if info.r then table.insert(parts, T("rangeL") .. " " .. info.r) end
        if info.d then table.insert(parts, T("demandL") .. " " .. info.d) end
        if info.y then table.insert(parts, T("rarityL") .. " " .. info.y) end
        local stabName = info.s and ((L[S.lang] or L.ru).stab or {})[info.s] or info.s
        local line = table.concat(parts, "  ·  ")
        if stabName then
            line = line .. (line ~= "" and "  ·  " or "") .. ('<font color="%s">%s</font>'):format(hex(STAB_COLORS[info.s] or C.muted), stabName)
        end
        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -nameX, 0, 18), Position = UDim2.fromOffset(nameX, 31),
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.muted, TextSize = 12, Font = fontReg(), RichText = true,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = line }, r)
    end
    -- стрелка изменения цены (как «Change in Value» на сайте)
    local ch = (not it.cat or it.primary) and (env.TV_changes or {})[it.name] or nil -- стрелки — только у «своего» предмета
    if ch and ch ~= 0 then
        local up = ch > 0
        local arrow = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -rightPad - 74, 0, info and 19 or 20), BackgroundTransparency = 1 }, r)
        for _, side in ipairs({ -1, 1 }) do -- галочка из двух полосок: ^ или v
            corner(new("Frame", { Size = UDim2.fromOffset(8, 2), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, side * 3, 0.5, 0), Rotation = (up and 45 or -45) * side,
                BackgroundColor3 = up and C.good or C.bad, BorderSizePixel = 0 }, arrow), 1)
        end
        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(44, info and 30 or 40), AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -rightPad - 88, 0, info and 4 or 0), TextXAlignment = Enum.TextXAlignment.Right, TextSize = 11,
            Font = fontReg(), TextColor3 = up and C.good or C.bad, Text = (up and "+" or "-") .. env.TV_fmt(math.abs(ch)) }, r)
    end
    if mode == "values" then
        on(r.Activated, function() if env.TV_showChart then env.TV_showChart(it, (it.cat and not it.primary) and { hist = {} } or nil) end end)
    end
    if mode == "values" then return end
    local box = new("Frame", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0),
        BackgroundColor3 = on_ and accent() or C.bg, BackgroundTransparency = on_ and 0 or 0.3 }, r)
    corner(box, 6)
    stroke(box, on_ and accent() or C.line, on_ and 0 or 0.8)
    if on_ then
        corner(new("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = rgb(255, 255, 255) }, box), 3)
    end
    on(r.Activated, function()
        local m, rk = marks(), rowKey(it)
        local keys = setMemberKeys(it)
        if keys then
            -- сет: отмечаем / снимаем сразу все его предметы
            local now = not (m[rk] ~= nil or setAllMarked(it, m))
            m[rk] = now and it.name or nil
            for i, k in ipairs(keys) do m[k] = now and ((env.TV_setItems[it.name][i] or {})[2] or k) or nil end
        elseif m[rk] then m[rk] = nil else m[rk] = it.name end
        saveSettings()
        renderList()
        renderSide()
    end)
end

-- свои предметы: то, что скрипт видел в трейдах, + открытый инвентарь MM2
if S.myInvV ~= 2 then S.myInv, S.myInvV = {}, 2 end
if type(S.tiers) ~= "table" then S.tiers = { { 100, 20 }, { 300, 15 }, { 1000, 10 }, { 3000, 5 } } end
-- цель прибыли для оффера ценой v: по ступеням (если включены), иначе общая
env.TV_pct = function(v)
    local t = S.tiers
    if not (S.tiersOn and t and #t > 0) then return S.target end
    for _, e in ipairs(t) do if (v or 0) <= e[1] then return e[2] end end
    return t[#t][2]
end
if S.adV ~= 1 then S.chatAdvert, S.adV = true, 1 end -- «Давай обменяемся» включено по умолчанию
if S.tradeLogV ~= 3 then S.tradeLog, S.tradePending, S.tradeLogV = {}, {}, 3 end -- раньше в историю попадали несостоявшиеся трейды -- первая версия собирала лишнее — начинаем заново
local INV_SKIP = { "shop", "store", "crate", "box", "preview", "reward", "spin", "unbox", "craft", "battle", "pass", "code", "gift", "trade", "offer", "season", "event", "quest" }
local function scanMyInv()
    S.myInv = S.myInv or {}
    local added = false
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" and d.Visible and not d:IsDescendantOf(ui) then
            local k = norm(d.Text)
            if valueMap[k] and not S.myInv[k] then
                -- вверх по родителям: всё видно, есть «inventory», нет магазина/ящиков/трейда
                local a, inInv, ok = d.Parent, false, true
                while a and a ~= PlayerGui do
                    if a:IsA("ScreenGui") then ok = ok and a.Enabled; break end
                    if a:IsA("GuiObject") and not a.Visible then ok = false; break end
                    local n = a.Name:lower()
                    for _, w in ipairs(INV_SKIP) do if n:find(w, 1, true) then ok = false; break end end
                    if not ok then break end
                    if n:find("inventory", 1, true) then inInv = true end
                    a = a.Parent
                end
                if ok and inInv and d.AbsoluteSize.X > 4 then S.myInv[k] = d.Text; added = true end
            end
        end
    end
    if added then saveSettings() end
end
-- (окно инвентаря MM2 больше не читаем: там бывают чужие предметы — «Мой инвентарь» берётся из трейда)
local function myInvList()
    local lst = {}
    for _, it in ipairs(itemList) do if (S.myInv or {})[it.key] then table.insert(lst, it) end end
    return lst
end

local function sourceList()
    if curCat == "inv" then
        return myInvList()
    elseif curCat == "marked" then
        local lst = {}
        local m = marks()
        for _, it in ipairs(itemList) do if m[rowKey(it)] or setAllMarked(it, m) then table.insert(lst, it) end end
        return lst
    elseif curCat == "all" then
        return itemList
    end
    return itemsByCat[curCat] or {}
end

renderList = function()
    for _, c in ipairs(scroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local q = norm(searchBox.Text)
    local shown = 0
    for _, it in ipairs(sourceList()) do
        if q == "" or it.key:find(q, 1, true) then
            shown += 1
            itemRow(it, shown)
        end
    end
    -- отметить / снять всю категорию одной кнопкой
    if mode ~= "values" and q == "" and itemsByCat[curCat] and #itemsByCat[curCat] > 0 then
        local m, all = marks(), true
        for _, it in ipairs(itemsByCat[curCat]) do if not m[rowKey(it)] then all = false; break end end
        local b = new("TextButton", { Size = UDim2.new(1, -6, 0, 32), BackgroundColor3 = accent(), BackgroundTransparency = all and 0.7 or 0.2,
            Text = all and T("catUnmark") or T("catMark"), TextColor3 = all and C.text or C.bg, TextSize = 13, Font = fontBold(),
            AutoButtonColor = false, LayoutOrder = -1 }, scroll)
        corner(b, 8)
        on(b.Activated, function()
            for _, it in ipairs(itemsByCat[curCat]) do
                if all then m[rowKey(it)] = nil else m[rowKey(it)] = it.name end
            end
            saveSettings(); renderList(); renderSide()
        end)
    end
    if curCat == "inv" and q == "" and shown > 0 then
        local b = new("TextButton", { Size = UDim2.new(1, -6, 0, 30), BackgroundColor3 = C.card, BackgroundTransparency = 0.5, Text = T("invClear"),
            TextColor3 = C.muted, TextSize = 13, Font = fontReg(), AutoButtonColor = false, LayoutOrder = 0 }, scroll)
        corner(b, 8)
        on(b.Activated, function() S.myInv = {}; saveSettings(); renderList(); renderSide() end)
    end
    if shown == 0 and curCat == "inv" and q == "" then
        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 60), Text = T("invHint"), TextWrapped = true,
            TextColor3 = C.muted, TextSize = 13, Font = fontReg(), LayoutOrder = 1 }, scroll)
    end
    blSub.Text = mode == "values" and ("Supreme Values · " .. #itemList) or mode == "keep" and (T("blCount"):format(blCount()) .. " · " .. T("keepHint"))
        or T("blCount"):format(blCount())
end

renderSide = function()
    for _, c in ipairs(side:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local entries = mode ~= "values" and { { "marked", T("marked") .. " (" .. blCount() .. ")" }, { "all", T("all") } } or { { "all", T("all") } }
    if mode == "keep" then table.insert(entries, 2, { "inv", T("myInv") .. " (" .. #myInvList() .. ")" }) end
    for _, cat in ipairs(catOrder) do
        if itemsByCat[cat] then table.insert(entries, { cat, ((L[S.lang] or L.ru).cats or {})[cat] or cat }) end
    end
    for i, e in ipairs(entries) do
        local active = e[1] == curCat
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = accent(), BackgroundTransparency = active and 0.75 or 1,
            Text = e[2], TextColor3 = active and accent():Lerp(rgb(255, 255, 255), 0.4) or C.text, TextSize = 14,
            Font = active and fontBold() or fontReg(), TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, LayoutOrder = i,
        }, side)
        corner(b, 8)
        pad(b, 10, 0)
        on(b.Activated, function()
            curCat = e[1]
            searchBox.Text = ""
            renderSide()
            renderList()
        end)
    end
end

local function refreshBl()
    blTitle.Text = mode == "bl" and T("bl") or mode == "keep" and T("keepTitle") or T("valuesTitle")
    declBox.Visible = mode == "bl"
    lDecl.Text = T("autoDecline")
    searchBox.PlaceholderText = T("search")
    drawDecl(S.autoDecline)
end

on(searchBox:GetPropertyChangedSignal("Text"), function() if blPage.Visible then renderList() end end)
on(declToggle.Activated, function() S.autoDecline = not S.autoDecline; saveSettings(); refreshBl() end)
on(backBtn.Activated, function()
    blPage.Visible = false
    panel.Visible = true
    env.TV_refresh()
end)
local function openPage(m)
    mode = m
    if mode == "values" and curCat == "marked" then curCat = "godlies" end
    if mode == "keep" then curCat = "inv" elseif curCat == "inv" then curCat = "godlies" end
    panel.Visible = false
    refreshBl()
    renderSide()
    renderList()
    blPage.AnchorPoint, blPage.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    blPage.Visible = true
    local target = fitScale()
    blScale.Scale = target * 0.94
    tween(blScale, 0.25, { Scale = target }, Enum.EasingStyle.Back)
end
on(blOpen.Activated, function() openPage("bl") end)
on(X.keepOpen.Activated, function() openPage("keep") end)
on(X.valuesOpen.Activated, function() openPage("values") end)
end)() -- отдельная функция: у неё свой лимит 200 локальных

local function refresh()
    for _, fn in ipairs(onTheme) do fn() end
    local a = accent()
    title.Text, subtitle.Text = "Auto Trade", T("settings")
    lSize.Text, lTheme.Text, lFont.Text, lLang.Text, lDiff.Text = T("size"), T("theme"), T("font"), T("lang"), T("diff")
    resetBtn.Text = T("reset")
    footer.Text = "Supreme Values · " .. (valueCount > 0 and T("loaded"):format(valueCount) or "…")
    sizeVal.Text = tostring(S.textSize)
    lScale.Text = T("scale")
    scaleVal.Text = ("%d%%"):format(math.floor((S.uiScale or 1) * 100 + 0.5))
    gearScale.Scale = sf()
    hudScale.Scale = sf()
    if panel.Visible and env.TV_fitPanel then panelScale.Scale = env.TV_fitPanel() end
    fontName.Text = (FONTS[S.font] or FONTS[1])[1]
    for i, d in ipairs(dots) do
        d.ring.Transparency = (i == S.theme) and 0 or 1
        tween(d.scale, 0.15, { Scale = (i == S.theme) and 1.15 or 1 })
    end
    segKnob.BackgroundColor3 = a
    tween(segKnob, 0.2, { Position = S.lang == "ru" and UDim2.fromOffset(2, 2) or UDim2.new(0.5, 2, 0, 2) })
    drawDiff(S.showDiff)
    drawAuto(S.autoOffer)
    lAuto.Text, lTarget.Text = T("auto"), T("target")
    if not targetVal:IsFocused() then targetVal.Text = ("+%d%%"):format(S.target) end
    lHl.Text, lAdd.Text, lBl.Text, lTol.Text = T("highlight"), T("autoAdd"), T("bl"), T("tolerance")
    drawTol(S.tolerance)
    X.fillLabel.Text = T("fillOver")
    X.tierLabel.Text = T("tiers")
    X.tierOpen.Text = (S.tiersOn and T("tierCount"):format(#S.tiers) or T("tierOff")) .. "  >"
    if X.renderTiers then X.renderTiers() end
    X.drawFill(S.fillOver)
    X.mirrorLabel.Text, X.emptyLabel.Text = T("mirrorEmpty"), T("emptyDecline")
    X.drawMirror(S.mirrorEmpty)
    X.drawEmpty(S.emptyDecline)
    X.junkLabel.Text = T("junkDecline")
    X.drawJunk(S.junkDecline)
    X.giftLabel.Text = T("giftAccept")
    X.drawGift(S.giftAccept)
    X.idleLabel.Text = T("idleDecline")
    X.drawIdle(S.idleDecline)
    X.accLabel.Text = T("autoAccept")
    X.reqLabel.Text = T("autoRequest")
    X.chatLabel.Text = T("chatAds")
    X.drawChat(S.chatAds)
    X.drawReq(S.autoRequest)
    X.drawAcc(S.autoAccept)
    drawHl(S.highlight)
    drawAdd(S.autoAdd)
    local blN = 0
    for _ in pairs(S.blacklist) do blN += 1 end
    blOpen.Text = T("blCount"):format(blN) .. "  >"
    X.ordLabel.Text = T("orders")
    X.ordOpen.Text = tostring(#(S.orders or {})) .. "  >"
    X.keepLabel.Text = T("keep")
    local keepN = 0
    for _ in pairs(S.keep or {}) do keepN += 1 end
    X.keepOpen.Text = T("blCount"):format(keepN) .. "  >"
    X.cheapLabel.Text = T("cheapGodly")
    X.drawCheap(S.cheapGodly)
    lOn.Text = T("enabled")
    X.allLabel.Text = T("allLabel")
    X.allOff.Text, X.allOn.Text = T("allOff"), T("allOn")
    -- какая из двух сейчас действует: всё выключено / всё включено — подсвечиваем
    local nOn, nAll = 0, 0
    for _, k in ipairs(X.ALL_KEYS or {}) do nAll += 1; if S[k] then nOn += 1 end end
    X.allOff.TextColor3 = (nAll > 0 and nOn == 0) and a or C.text
    X.allOn.TextColor3 = (nAll > 0 and nOn == nAll - (S.chatInTrade and 0 or 1)) and a or C.text
    tabMainBtn.Text, tabTradeBtn.Text, X.tabGameBtn.Text = T("tabMain"), T("tabTrade"), T("tabGame")
    X.afkLabel.Text, X.flingLabel.Text = T("antiAfk"), T("antiFling")
    X.drawAfk(S.antiAfk)
    X.drawFling(S.antiFling)
    X.adLabel.Text = T("chatAdvert")
    X.drawAd(S.chatAdvert)
    X.outLabel.Text = T("outreach")
    X.drawOut(S.outreach)
    tabKnob.BackgroundColor3 = a
    if curTab == "trade2" then curTab = "trade" elseif curTab == "chat" then curTab = "game" end -- разделы объединены
    local tabIndex = ({ main = 0, trade = 1, game = 2 })[curTab] or 0
    tween(tabKnob, 0.2, { Position = UDim2.new(tabIndex / 3, 3, 0, 3) })
    bodyMain.Visible, bodyTrade.Visible, X.bodyTrade2.Visible = curTab == "main", curTab == "trade", false
    X.tabTrade2Btn.Text = T("tabTrade2")
    X.bodyGame.Visible, X.bodyChat.Visible = curTab == "game", false
    X.tabChatBtn.Text = T("tabChat")
    X.valuesLabel.Text = T("valuesTitle")
    X.valuesOpen.Text = T("openValues") .. "  >"
    X.statsLabel.Text = T("invStats")
    X.statsOpen.Text = T("openValues") .. "  >"
    X.histLabel.Text = T("histTrades")
    X.histOpen.Text = T("openValues") .. "  >"
    X.chatTradeLabel.Text = T("chatInTrade")
    X.drawChatTrade(S.chatInTrade)
    X.chatReqLabel.Text = T("chatRequests")
    X.drawChatReq(S.chatRequests)
    X.declMsgLabel.Text = T("declineMsg")
    X.drawDeclMsg(S.declineMsg)
    drawOn(S.enabled)
    gearRing.Color = S.enabled and a or C.muted
    -- размеры текста в плашке
    youVal.TextSize, themVal.TextSize = S.textSize + 4, S.textSize + 4
    for _, t in ipairs({ youCap, themCap, youNote, themNote, statusLabel }) do t.TextSize = math.max(9, S.textSize - 5) end
    winLabel.TextSize = math.max(11, S.textSize - 1)
    youCap.Text, themCap.Text = T("you"), T("them")
end
env.TV_refresh = refresh

local function change(fn) return function() fn(); saveSettings(); refresh() end end
do
    local W = 400
    local page = new("Frame", { Size = UDim2.fromOffset(W, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Visible = false, BackgroundColor3 = C.bg, BackgroundTransparency = 0.04 }, ui)
    corner(page, 18)
    stroke(page)
    pad(page, 16, 14)
    list(page, Enum.FillDirection.Vertical, 10)
    X.tierPage, X.tierScale = page, new("UIScale", {}, page)
    local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 1 }, page)
    local back = new("TextButton", { Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.card, Text = "<", TextColor3 = C.text,
        TextSize = 18, Font = Enum.Font.GothamBold, AutoButtonColor = false }, head)
    corner(back, 16)
    stroke(back)
    X.tierTitle = label(head, { Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(44, 0), TextSize = 16 }, true)
    local card = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 2 }, page)
    corner(card, 12)
    stroke(card)
    pad(card, 12, 0)
    X.tierOnLbl = label(card, { Size = UDim2.new(1, -56, 1, 0), TextSize = 14 })
    X.tierToggle, X.drawTier = makeToggle(card)
    X.tierBox = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3 }, page)
    corner(X.tierBox, 12)
    stroke(X.tierBox)
    pad(X.tierBox, 12, 10)
    list(X.tierBox, Enum.FillDirection.Vertical, 6)
    on(back.Activated, function() page.Visible = false; panel.Visible = true; env.TV_refresh() end)
    on(X.tierOpen.Activated, function()
        X.tierSig = nil
        panel.Visible = false
        refresh()
        page.Visible = true
        local abs = ui.AbsoluteSize
        local target = math.min(sf(), (abs.X - 24) / W, (abs.Y - 24) / math.max(200, page.AbsoluteSize.Y / math.max(0.01, X.tierScale.Scale)))
        X.tierScale.Scale = target * 0.94
        tween(X.tierScale, 0.25, { Scale = target }, Enum.EasingStyle.Back)
    end)
end
X.renderTiers = function()
    local box = X.tierBox
    X.tierTitle.Text = T("tiers")
    X.tierOnLbl.Text = T("tiersOn")
    X.drawTier(S.tiersOn)
    box.BackgroundTransparency = S.tiersOn and 0.3 or 0.7
    local parts = { S.lang }
    for _, e in ipairs(S.tiers) do table.insert(parts, e[1] .. ":" .. e[2]) end
    local sig = table.concat(parts, ",")
    if sig == X.tierSig then return end
    for _, c in ipairs(box:GetChildren()) do if c:IsA("TextBox") and c:IsFocused() then return end end
    X.tierSig = sig
    for _, c in ipairs(box:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local function save()
        table.sort(S.tiers, function(a, b) return a[1] < b[1] end)
        saveSettings()
        refresh()
    end
    local function txt(parent, text, w, order)
        return new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0, w, 1, 0), AutomaticSize = w == 0 and Enum.AutomaticSize.X or nil,
            Text = text, TextColor3 = C.muted, TextSize = 13, Font = fontReg(), LayoutOrder = order }, parent)
    end
    local function numBox(parent, val, w, order, onSet)
        local f = new("Frame", { Size = UDim2.fromOffset(w, 30), BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, LayoutOrder = order }, parent)
        corner(f, 8)
        stroke(f)
        local b = new("TextBox", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(val), TextColor3 = C.text,
            TextSize = 13, Font = fontBold(), ClearTextOnFocus = false }, f)
        on(b.FocusLost, function()
            local n = tonumber((b.Text:gsub("[^%d%.]", "")))
            if n then onSet(math.floor(n + 0.5)) end
            X.tierSig = nil
            save()
        end)
        return b
    end
    for i, e in ipairs(S.tiers) do
        local line = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = i }, box)
        list(line, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
        txt(line, T("tierUpTo"), 0, 1)
        numBox(line, e[1], 90, 2, function(n) e[1] = math.max(1, n) end)
        txt(line, "value  →", 0, 3)
        numBox(line, e[2], 56, 4, function(n) e[2] = math.clamp(n, 0, 500) end)
        txt(line, "%", 0, 5)
        local del = new("TextButton", { Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, Text = "×",
            TextColor3 = C.bad, TextSize = 16, Font = fontBold(), AutoButtonColor = false, LayoutOrder = 6 }, line)
        corner(del, 8)
        stroke(del)
        on(del.Activated, function() table.remove(S.tiers, i); save() end)
    end
    local bottom = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 100 }, box)
    list(bottom, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local add = new("TextButton", { Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.bg, BackgroundTransparency = 0.2,
        Text = T("tierAdd"), TextColor3 = C.text, TextSize = 13, Font = fontBold(), AutoButtonColor = false, LayoutOrder = 1 }, bottom)
    corner(add, 8)
    stroke(add, accent(), 0.4)
    pad(add, 10, 0)
    on(add.Activated, function()
        local last = S.tiers[#S.tiers]
        table.insert(S.tiers, last and { last[1] * 3, math.max(0, last[2] - 5) } or { 100, S.target })
        save()
    end)
    local hint = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = T("tierHint"),
        TextColor3 = C.muted, TextSize = 11, Font = fontReg(), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 101 }, box)
    hint.Size = UDim2.new(1, 0, 0, 0)
end
on(X.tierToggle.Activated, change(function() S.tiersOn = not S.tiersOn end))
-- «Всё выкл.» / «Всё вкл.»: все автоматические функции (главный «Скрипт включён» не трогаем)
X.ALL_KEYS = { "autoOffer", "autoAdd", "highlight", "fillOver", "ordersOn", "cheapGodly", "mirrorEmpty", "emptyDecline",
    "junkDecline", "giftAccept", "autoDecline", "idleDecline", "autoRequest", "autoAccept", "antiAfk", "antiFling",
    "chatAds", "chatInTrade", "chatRequests", "declineMsg" }
on(X.allOff.Activated, change(function()
    for _, k in ipairs(X.ALL_KEYS) do S[k] = false end
    S.chatInTrade = false
    notify(T("allOffDone"))
end))
on(X.allOn.Activated, change(function()
    for _, k in ipairs(X.ALL_KEYS) do S[k] = true end
    S.chatInTrade = false -- карточки чата во время трейда только мешают
    notify(T("allOnDone"))
end))
on(tabMainBtn.Activated, function() curTab = "main"; refresh() end)
on(tabTradeBtn.Activated, function() curTab = "trade"; refresh() end)
on(X.tabTrade2Btn.Activated, function() curTab = "trade2"; refresh() end)
on(X.tabGameBtn.Activated, function() curTab = "game"; refresh() end)
on(X.tabChatBtn.Activated, function() curTab = "chat"; refresh() end)
on(X.chatTradeToggle.Activated, change(function() S.chatInTrade = not S.chatInTrade end))
on(X.chatReqToggle.Activated, change(function() S.chatRequests = not S.chatRequests end))
on(X.declMsgToggle.Activated, change(function() S.declineMsg = not S.declineMsg end))
on(minus.Activated, change(function() S.textSize = math.max(10, S.textSize - 2) end))
on(plus.Activated, change(function() S.textSize = math.min(30, S.textSize + 2) end))
on(scMinus.Activated, change(function() S.uiScale = math.max(0.6, math.floor((S.uiScale or 1) * 10 - 1 + 0.5) / 10) end))
on(scPlus.Activated, change(function() S.uiScale = math.min(2, math.floor((S.uiScale or 1) * 10 + 1 + 0.5) / 10) end))
-- окно игры поменяло размер -> пересчитать масштаб
on(ui:GetPropertyChangedSignal("AbsoluteSize"), function() env.TV_refresh() end)
on(fontPrev.Activated, change(function() S.font = (S.font - 2) % #FONTS + 1 end))
on(fontNext.Activated, change(function() S.font = S.font % #FONTS + 1 end))
on(ruBtn.Activated, change(function() S.lang = "ru" end))
on(enBtn.Activated, change(function() S.lang = "en" end))
on(toggle.Activated, change(function() S.showDiff = not S.showDiff end))
on(autoToggle.Activated, change(function() S.autoOffer = not S.autoOffer end))
on(onToggle.Activated, change(function() S.enabled = not S.enabled end))
on(hlToggle.Activated, change(function() S.highlight = not S.highlight end))
on(addToggle.Activated, change(function() S.autoAdd = not S.autoAdd end))
on(tolToggle.Activated, change(function() S.tolerance = not S.tolerance end))
on(X.fillToggle.Activated, change(function() S.fillOver = not S.fillOver end))
on(X.mirrorToggle.Activated, change(function() S.mirrorEmpty = not S.mirrorEmpty end))
on(X.emptyToggle.Activated, change(function() S.emptyDecline = not S.emptyDecline end))
on(X.junkToggle.Activated, change(function() S.junkDecline = not S.junkDecline end))
on(X.giftToggle.Activated, change(function() S.giftAccept = not S.giftAccept end))
on(X.idleToggle.Activated, change(function() S.idleDecline = not S.idleDecline end))
on(X.cheapToggle.Activated, change(function() S.cheapGodly = not S.cheapGodly end))
on(X.accToggle.Activated, change(function() S.autoAccept = not S.autoAccept end))
on(X.reqToggle.Activated, change(function() S.autoRequest = not S.autoRequest end))
on(X.chatToggle.Activated, change(function() S.chatAds = not S.chatAds end))
on(X.afkToggle.Activated, change(function() S.antiAfk = not S.antiAfk end))
on(X.flingToggle.Activated, change(function() S.antiFling = not S.antiFling end))
on(X.outToggle.Activated, change(function() S.outreach = not S.outreach; env.TV_outLast = os.clock() - 80 end))
on(X.adToggle.Activated, change(function() S.chatAdvert = not S.chatAdvert; env.TV_adLast = os.clock() - 140 end))
-- «Давай обменяемся!» в чат раз в минуту, пока не идёт трейд
task.spawn(function()
    while ui.Parent do
        task.wait(5)
        if S.enabled and S.chatAdvert and env.TV_sayChat and os.clock() - (env.TV_adLast or 0) >= 150
           and os.clock() - (env.TV_tradeSeen or -1e9) >= 60 then
            env.TV_adLast = os.clock()
            local ok, err = env.TV_sayChat(T("chatAdvertMsg"))
            if ok then notify(T("adSent")) else notify(T("adFail"):format(tostring(err):sub(1, 80))) end
        end
    end
end)

------------------------------------------------------------------
-- Анти-АФК и анти-флинг
------------------------------------------------------------------
;(function()
    local LP = Players.LocalPlayer
    -- анти-АФК: Roblox кикает через 20 минут бездействия — имитируем нажатие
    on(LP.Idled, function()
        if not (S.enabled and S.antiAfk) then return end
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)

    -- анти-флинг: чужие персонажи у нас не сталкиваются с нами, резкий отброс гасим
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
        local flatSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
        if flatSpeed > 120 or w.Magnitude > 40 or v.Y > 150 then
            hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            if lastSafe then hrp.CFrame = lastSafe end
        elseif hum.FloorMaterial ~= Enum.Material.Air and os.clock() - lastSafeAt > 0.5 then
            lastSafe, lastSafeAt = hrp.CFrame, os.clock() -- стоим на земле — запоминаем место
        end
    end)
end)() -- отдельная функция: у неё свой лимит 200 локальных
on(tMinus.Activated, change(function() S.target = math.max(0, S.target - 5) end))
on(tPlus.Activated, change(function() S.target = math.min(500, S.target + 5) end))
on(targetVal.FocusLost, change(function()
    local n = tonumber((targetVal.Text:gsub("[^%d%.]", "")))
    if n then S.target = math.clamp(math.floor(n + 0.5), 0, 500) end
end))
on(resetBtn.Activated, change(function() S.hudX, S.hudY = nil, nil; placeHud() end))

local function showPanel(v)
    if v then
        refresh()
        if env.TV_layout then env.TV_layout() end
        panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        panel.Visible = true
        task.defer(function()
            local target = env.TV_fitPanel and env.TV_fitPanel() or sf()
            panelScale.Scale = target * 0.92
            tween(panelScale, 0.25, { Scale = target }, Enum.EasingStyle.Back)
        end)
    else
        panel.Visible = false
    end
end
on(closeBtn.Activated, function() showPanel(false) end)
makeDraggable(gear, gear, function()
    if blPage.Visible or (X.ordPage and X.ordPage.Visible) or (X.ordPicker and X.ordPicker.Visible) then
        blPage.Visible = false
        if X.ordPage then X.ordPage.Visible = false end
        if X.ordPicker then X.ordPicker.Visible = false end
    else
        showPanel(not panel.Visible)
    end
end, function()
    local abs = ui.AbsoluteSize
    S.iconX, S.iconY = gear.AbsolutePosition.X / abs.X, gear.AbsolutePosition.Y / abs.Y
    gear.Position = UDim2.fromScale(S.iconX, S.iconY)
    saveSettings()
end)
-- окно настроек целиком на экране: уменьшаем, если не помещается по высоте/ширине
env.TV_fitPanel = function()
    local abs = ui.AbsoluteSize
    local cur = math.max(panelScale.Scale, 0.01)
    local h = panel.AbsoluteSize.Y / cur
    local w = panel.Size.X.Offset + 32
    if h < 50 or abs.Y < 50 then return sf() end
    return math.min(sf(), (abs.Y - 16) / h, (abs.X - 16) / w)
end
-- телефон боком (широко и низко): строки настроек в две колонки — «таблицей», окно шире и ниже
env.TV_layout = function()
    local abs = ui.AbsoluteSize
    local wide = abs.Y < 620 and abs.X > abs.Y * 1.3
    if env.TV_wide == wide then return end
    env.TV_wide = wide
    panel.Size = UDim2.fromOffset(wide and 700 or 440, 0)
    -- вкладки не растягиваем на всю ширину: компактная полоса по центру
    tabBar.Size = wide and UDim2.fromOffset(360, 36) or UDim2.new(1, 0, 0, 36)
    local pl = panel:FindFirstChildOfClass("UIListLayout")
    if pl then pl.HorizontalAlignment = Enum.HorizontalAlignment.Center end
    for _, b in ipairs({ bodyMain, bodyTrade, X.bodyTrade2, X.bodyGame, X.bodyChat }) do
        local ll = b:FindFirstChildOfClass("UIListLayout") or env.TV_lists and env.TV_lists[b]
        env.TV_lists = env.TV_lists or {}
        env.TV_lists[b] = ll
        local gl = b:FindFirstChild("TVGrid")
        if not gl then
            gl = new("UIGridLayout", { Name = "TVGrid", CellSize = UDim2.new(0.5, -6, 0, 44), CellPadding = UDim2.fromOffset(4, 0),
                SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center })
        end
        if ll then ll.Parent = (not wide) and b or nil end
        gl.Parent = wide and b or nil
        -- в таблице разделители не нужны
        for _, c in ipairs(b:GetChildren()) do
            if c:IsA("GuiObject") and c.LayoutOrder % 2 == 1 and c.Size.Y.Offset <= 1 then
                if wide then c:SetAttribute("TVWasVisible", c.Visible); c.Visible = false
                elseif c:GetAttribute("TVWasVisible") ~= nil then c.Visible = c:GetAttribute("TVWasVisible") end
            end
        end
    end
end
on(ui:GetPropertyChangedSignal("AbsoluteSize"), function()
    if env.TV_layout then env.TV_layout() end
    if panel.Visible then panelScale.Scale = env.TV_fitPanel() end
end)

-- меньше переключателей: второстепенные работают сами (включены), строки с ними не показываем
do
    if S.simpleV ~= 1 then
        for _, k in ipairs({ "highlight", "autoAdd", "tolerance", "fillOver", "cheapGodly", "mirrorEmpty", "emptyDecline",
            "junkDecline", "giftAccept", "idleDecline", "declineMsg" }) do S[k] = true end
        S.chatInTrade, S.simpleV = false, 1
        saveSettings()
    end
    for _, lbl in ipairs({ lSize, lHl, lAdd, lTol, X.fillLabel, X.cheapLabel, X.mirrorLabel, X.emptyLabel, X.junkLabel, X.giftLabel,
        X.idleLabel, X.chatTradeLabel, X.declMsgLabel }) do
        if lbl and lbl.Parent then lbl.Parent.Visible = false end
    end
    -- разделы объединены: строки «Принятия» — в «Трейд», «Чата» — в «Прочее» (порядок сохраняем, сдвигая номера)
    for _, mv in ipairs({ { X.bodyTrade2, bodyTrade }, { X.bodyChat, X.bodyGame } }) do
        for _, c in ipairs(mv[1]:GetChildren()) do
            if c:IsA("GuiObject") then c.LayoutOrder += 1000; c.Parent = mv[2] end
        end
    end
    rReset.LayoutOrder = 5000 -- «Вернуть плашку на место» — последней строкой
    X.tabTrade2Btn.Visible, X.tabChatBtn.Visible = false, false
    tabKnob.Size = UDim2.new(1 / 3, -6, 1, -6)
    for i, b in ipairs({ tabMainBtn, tabTradeBtn, X.tabGameBtn }) do
        b.Size, b.Position = UDim2.fromScale(1 / 3, 1), UDim2.fromScale((i - 1) / 3, 0)
    end
    -- разделители: только между видимыми строками
    for _, b in ipairs({ bodyMain, bodyTrade, X.bodyTrade2, X.bodyGame, X.bodyChat }) do
        local items = {}
        for _, c in ipairs(b:GetChildren()) do if c:IsA("GuiObject") then table.insert(items, c) end end
        table.sort(items, function(x, y) return x.LayoutOrder < y.LayoutOrder end)
        local seenRow = false
        for i, c in ipairs(items) do
            if c.LayoutOrder % 2 == 1 then -- разделитель
                local nextRow = items[i + 1]
                c.Visible = seenRow and nextRow ~= nil and nextRow.Visible
            elseif c.Visible then
                seenRow = true
            end
        end
    end
end
refresh()

------------------------------------------------------------------
-- Чтение окна трейда
------------------------------------------------------------------
local function findTradeGui()
    -- окон трейда может быть несколько (для телефона и для ПК); берём то, где оффер реально на экране
    local first
    for _, g in ipairs(PlayerGui:GetChildren()) do
        if g ~= ui and g.Name ~= "TVHighlightUI" and g:IsA("ScreenGui") and g.Enabled and g.Name:lower():find("trade") then
            first = first or g
            for _, d in ipairs(g:GetDescendants()) do
                if (d.Name == "YourOffer" or d.Name == "MyOffer") and env.TV_vis(d) then return g end
            end
        end
    end
    return first
end

-- редкость по цвету полоски с названием (как в MM2): розовая — годли, фиолетовая — древние, красная — легендарки…
env.TV_rarityCat = function(lbl)
    local col
    local o = lbl
    for _ = 1, 3 do
        if not o or not o:IsA("GuiObject") then break end
        local g = o:FindFirstChildOfClass("UIGradient")
        if g then col = g.Color.Keypoints[1].Value; break end
        if o.BackgroundTransparency < 0.6 then col = o.BackgroundColor3; break end
        o = o.Parent
    end
    if not col then return nil end
    local h, sat, v = col:ToHSV()
    h = h * 360
    if sat < 0.25 or v < 0.2 then return "commons" end
    if h >= 345 or h < 15 then return "legendaries" end
    if h >= 285 and h < 345 then return "godlies" end
    if h >= 250 and h < 285 then return "ancients" end
    if h >= 180 and h < 250 then return "rares" end
    if h >= 75 and h < 180 then return "uncommons" end
    if h >= 35 and h < 75 then return "vintages" end
    return nil
end
-- ячейка предмета, в которой лежит надпись (поднимаемся до элемента сетки / оффера)
env.TV_cellOf = function(lbl)
    local o = lbl
    for _ = 1, 6 do
        local par = o.Parent
        if not par or par:IsA("ScreenGui") then break end
        if par.Name == "Container" or par:FindFirstChildWhichIsA("UIGridLayout") or par:FindFirstChildWhichIsA("UIListLayout") or par:IsA("ScrollingFrame") then return o end
        o = par
    end
    return lbl.Parent or lbl
end
-- категория предмета: по картинке из базы MM2 (точно), иначе по цвету полоски
env.TV_cellCat = function(cell, lbl)
    for _, im in ipairs(cell:GetDescendants()) do
        if (im:IsA("ImageLabel") or im:IsA("ImageButton")) and im.Image ~= "" then
            local id = env.TV_imgId(im.Image)
            local c = id and (env.TV_imgCat or {})[id]
            if c then return c, true end
        end
    end
    return lbl and env.TV_rarityCat(lbl) or nil, false
end
-- одно название — разные предметы: значение по категории (если её удалось узнать по цвету)
env.TV_catPrice = function(key, name, cat)
    local cv = cat and (env.TV_catVals or {})[cat]
    if not cv then return nil end
    for nm, v in pairs(cv) do
        if norm(nm) == key or norm((nm:gsub("%s*%b()$", ""))) == key then return tonumber(v) or 0 end
    end
    return nil
end
local function readItem(frame)
    local price, amount, name = nil, 1, nil
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            local n = d.Text:match("^[xX]%s*(%d+)$")
            if n then amount = tonumber(n)
            elseif not price and valueMap[norm(d.Text)] then
                local k = norm(d.Text)
                price, name = valueMap[k], d.Text
                -- хрома: та же подпись, но картинка хромы из базы MM2 (или ты сам отметил её как хрому)
                if not k:find("^chroma") and valueMap["chroma" .. k] then
                    for _, im in ipairs(frame:GetDescendants()) do
                        if (im:IsA("ImageLabel") or im:IsA("ImageButton")) and im.Image ~= "" then
                            local id = env.TV_imgId(im.Image)
                            if id and ((env.TV_chromaImg or {})[id] or (S.imgChroma or {})[id]) then
                                price, name = valueMap["chroma" .. k], "Chroma " .. d.Text
                                break
                            end
                        end
                    end
                end
                if (env.TV_ambig or {})[k] then
                    -- «Waves» годли (240) и «Waves» редкий (x2 T1 Rares): смотрим цвет полоски
                    local cat = env.TV_cellCat(frame, d)
                    if cat and cat ~= (env.TV_primCat or {})[k] then
                        local cp = env.TV_catPrice(k, d.Text, cat)
                        if cp then price = cp end
                    end
                end
            end
        end
    end
    return price, amount, name
end
env.TV_keptCell = function(cell)
    for _, l in ipairs(cell:GetDescendants()) do
        if l:IsA("TextLabel") and l.Text ~= "" and valueMap[norm(l.Text)] then return env.TV_isMarked(S.keep, l) ~= nil end
    end
    return false
end
-- отмечен ли предмет (с учётом категории, если её видно по цвету)
env.TV_isMarked = function(tbl, lbl)
    local k = norm(lbl.Text)
    local cat = (env.TV_ambig or {})[k] and env.TV_cellCat(env.TV_cellOf(lbl), lbl) or nil
    for rk, name in pairs(tbl or {}) do
        local c, key = rk:match("^(%a+):(.+)$")
        if not key then key, c = rk, (env.TV_primCat or {})[rk] end
        if key == k or norm(tostring(name)) == k then
            if not cat or not c or c == cat then return name end
        end
    end
    return nil
end

local function sumOffer(offer)
    local total, unknown = 0, 0
    for _, item in ipairs(offer:GetDescendants()) do
        if (item:IsA("Frame") or item:IsA("ImageLabel") or item:IsA("ImageButton"))
           and item.Parent.Name == "Container" and env.TV_vis(item) then
            local price, amount = readItem(item)
            if price then
                total += price * amount
            elseif item:FindFirstChildWhichIsA("TextLabel", true) then
                unknown += 1
            end
        end
    end
    return total, unknown
end

local function findOffer(root, names)
    -- видимый вариант важнее скрытого (у MM2 внутри окна бывает две раскладки)
    local first
    for _, d in ipairs(root:GetDescendants()) do
        for _, n in ipairs(names) do
            if d.Name == n then
                if env.TV_vis(d) then return d end
                first = first or d
            end
        end
    end
    return first
end

local function fmt(n)
    local s = tostring(math.floor(n)); local r
    repeat s, r = s:gsub("^(%d+)(%d%d%d)", "%1 %2") until r == 0
    return s
end
env.TV_fmt = fmt

------------------------------------------------------------------
-- Автооффер: подбор своих предметов под цель профита
------------------------------------------------------------------
-- слой подсветки: отступ сверху как у окна трейда, чтобы рамки совпадали с предметами
local hlGui = new("ScreenGui", { Name = "TVHighlightUI", ResetOnSpawn = false, DisplayOrder = 999, AutoLocalize = false }, PlayerGui)
local hlPool = {}
local function getHighlight(i)
    if hlPool[i] then return hlPool[i] end
    local f = new("Frame", { BackgroundTransparency = 1, Visible = false }, hlGui)
    corner(f, 8)
    local st = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 3 }, f)
    local badge = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 4, 0, -8), Size = UDim2.fromOffset(30, 20),
        TextColor3 = rgb(255, 255, 255), TextSize = 13, Font = Enum.Font.GothamBold,
    }, f)
    corner(badge, 10)
    hlPool[i] = { frame = f, stroke = st, badge = badge }
    return hlPool[i]
end
local function hideHighlights(from)
    for i = from or 1, #hlPool do hlPool[i].frame.Visible = false end
end

-- видна ли ячейка на самом деле (все родители видимы, есть размер)
local function isShown(g)
    if g.AbsoluteSize.X < 20 or g.AbsoluteSize.Y < 20 then return false end
    local o = g
    while o and not o:IsA("ScreenGui") do
        if o:IsA("GuiObject") and not o.Visible then return false end
        o = o.Parent
    end
    return o ~= nil and o.Enabled
end

-- картинки предметов: из базы MM2 и из всего, что скрипт увидел в окне трейда
local imageCache = {}
local dbChroma = {} -- картинки хромы из базы (отдельно, чтобы не перепутать с обычными)
local function harvestImage(cell, name)
    if not name or imageCache[norm(name)] then return end
    -- картинка предмета обычно самая крупная внутри ячейки (фон самой ячейки не берём)
    local img, best = nil, 0
    for _, d in ipairs(cell:GetDescendants()) do
        if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image ~= "" and d.Image:find("%d") then
            local area = d.AbsoluteSize.X * d.AbsoluteSize.Y
            if area > best then img, best = d.Image, area end
        end
    end
    if img then imageCache[norm(name)] = img end
end
task.spawn(function()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local sync = rs:FindFirstChild("Database") and rs.Database:FindFirstChild("Sync")
        -- картинка -> категория по базе MM2: редкость оружия, питомцы — из своего модуля
        local RAR = { godly = "godlies", ancient = "ancients", legendary = "legendaries", rare = "rares", uncommon = "uncommons",
            common = "commons", vintage = "vintages", unique = "uniques", classic = "commons" }
        env.TV_imgCat = env.TV_imgCat or {}
        for _, m in ipairs(sync and sync:GetChildren() or {}) do
            if m:IsA("ModuleScript") then
                local isPetMod = m.Name:lower():find("pet") ~= nil
                pcall(function()
                    local function visit(t, depth)
                        for _, v in pairs(t) do
                            if type(v) == "table" then
                                if v.Image ~= nil then
                                    local cid = env.TV_imgId(tostring(v.Image))
                                    if cid then
                                        local chroma = v.Chroma or v.IsChroma or v.chroma
                                        local r = RAR[tostring(v.Rarity or ""):lower()]
                                        local cat = isPetMod and "pets" or (chroma and "chromas") or r
                                        if cat and not env.TV_imgCat[cid] then env.TV_imgCat[cid] = cat end
                                    end
                                elseif depth < 2 then
                                    visit(v, depth + 1)
                                end
                            end
                        end
                    end
                    visit(require(m), 0)
                end)
            end
        end
        local mod = sync and sync:FindFirstChild("Item")
        if not mod then return end
        env.TV_dbCount = 0
        local flat = {}
        for id, data in pairs(require(mod)) do
            if type(data) == "table" and data.Image == nil then
                -- раздел (например, «Weapons» / «Pets»): записи внутри
                for id2, d2 in pairs(data) do if type(d2) == "table" then table.insert(flat, { id2, d2 }) end end
            else
                table.insert(flat, { id, data })
            end
        end
        for _, pair in ipairs(flat) do
            local id, data = pair[1], pair[2]
            env.TV_dbCount += 1
            if type(data) == "table" and data.Image then
                local img = tostring(data.Image)
                if tonumber(img) then img = "rbxassetid://" .. img end
                -- по картинке ячейки можно узнать тип (нож/пистолет) и редкость: «Latte» бывает и тем и другим
                local digits = env.TV_imgId(img)
                if digits then
                    -- тип ищем в любом текстовом поле записи («Gun»/«Knife»), иначе — в её ключе
                    local kind = ""
                    for _, fv in pairs(data) do
                        if type(fv) == "string" then
                            local lv = fv:lower()
                            if lv == "gun" or lv == "knife" or lv == "pistol" or lv == "revolver" then kind = lv; break end
                        end
                    end
                    if kind == "" then
                        local idl = tostring(id):lower()
                        if idl:find("gun") or idl:find("pistol") then kind = "gun" elseif idl:find("knife") then kind = "knife" end
                    end
                    env.TV_dbImg = env.TV_dbImg or {}
                    env.TV_dbImg[digits] = { kind = kind, rarity = tostring(data.Rarity or ""):lower() }
                    -- для отладки ножа/пистолета: какие записи с этим именем есть в базе и что в них
                    if data.ItemName then
                        local fields = {}
                        for fk, fv in pairs(data) do
                            if (type(fv) == "string" or type(fv) == "number" or type(fv) == "boolean") and fk ~= "Image" and fk ~= "ItemName" and #fields < 5 then
                                table.insert(fields, tostring(fk) .. "=" .. tostring(fv):sub(1, 10))
                            end
                        end
                        local nk = norm(tostring(data.ItemName))
                        env.TV_dbByName = env.TV_dbByName or {}
                        env.TV_dbByName[nk] = env.TV_dbByName[nk] or {}
                        table.insert(env.TV_dbByName[nk], tostring(id):sub(1, 16) .. " img" .. digits .. " " .. table.concat(fields, ","))
                    end
                end
                if data.ItemName then
                    -- у хромы в базе то же имя, что у обычного предмета: различаем по флагу/id
                    local isChroma = data.Chroma or data.IsChroma or data.chroma
                        or tostring(id):lower():find("chroma") or tostring(data.ItemName):lower():find("^chroma")
                    local name = tostring(data.ItemName):gsub("^[Cc]hroma ", "")
                    local key = norm((isChroma and "Chroma " or "") .. name)
                    if isChroma then
                        -- картинки хромы: в трейде у хромы то же название, что у обычного («Slasher»), отличие — картинка
                        local cid = env.TV_imgId(img)
                        if cid then env.TV_chromaImg = env.TV_chromaImg or {}; env.TV_chromaImg[cid] = true end
                        dbChroma[key] = dbChroma[key] or img
                    else
                        imageCache[key] = imageCache[key] or img
                    end
                end
            end
        end
    end)
end)

-- тип предмета в ячейке: "gun" / "knife" / nil (пока не знаем). «Latte» бывает и ножом, и пистолетом —
-- различаем по картинке: 1) база MM2; 2) название этой картинки в Roblox (спрашиваем один раз, ответ запоминаем)
env.TV_imgName = env.TV_imgName or {}
-- все картинки ячейки (номера), от крупной к мелкой: крупная обычно фон редкости, сам предмет — другая
env.TV_cellImgs = function(cell)
    local list, seen = {}, {}
    for _, d in ipairs(cell:GetDescendants()) do
        if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image:find("%d") then
            local digits = env.TV_imgId(d.Image)
            if digits and #digits >= 5 and not seen[digits] then
                seen[digits] = true
                table.insert(list, { digits, d.AbsoluteSize.X * d.AbsoluteSize.Y })
            end
        end
    end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    local out = {}
    for _, e in ipairs(list) do table.insert(out, e[1]) end
    return out
end
env.TV_kindOf = function(str)
    str = (str or ""):lower()
    if str:find("knife") or str:find("нож") then return "knife" end
    if str:find("gun") or str:find("pistol") or str:find("revolver") or str:find("пистолет") then return "gun" end
end
env.TV_imgNameOf = function(digits)
    local nm = env.TV_imgName[digits]
    if nm == nil then
        env.TV_imgName[digits] = false -- спрашиваем у Roblox один раз
        task.spawn(function()
            local ok, inf = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(tonumber(digits), Enum.InfoType.Asset)
            end)
            env.TV_imgName[digits] = (ok and type(inf) == "table" and tostring(inf.Name or "")) or ""
        end)
        return nil
    end
    return nm or nil
end
-- сколько раз картинка / имя встречаются во всём окне трейда: общее для многих ячеек (фон, иконка, шаблон) — не про предмет
env.TV_freq = function(cell)
    local g = cell:FindFirstAncestorWhichIsA("ScreenGui")
    if g and (env.TV_freqG ~= g or os.clock() - (env.TV_freqAt or 0) > 1) then
        local imgs, names = {}, {}
        for _, d in ipairs(g:GetDescendants()) do
            if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                local dg = env.TV_imgId(d.Image)
                if dg then imgs[dg] = (imgs[dg] or 0) + 1 end
            end
            names[d.Name] = (names[d.Name] or 0) + 1
        end
        env.TV_freqG, env.TV_freqAt, env.TV_freqImg, env.TV_freqName = g, os.clock(), imgs, names
    end
    return env.TV_freqImg or {}, env.TV_freqName or {}
end
env.TV_cellKind = function(cell)
    local fImg, fName = env.TV_freq(cell)
    local imgs = {}
    for _, d in ipairs(env.TV_cellImgs(cell)) do
        if (fImg[d] or 0) <= 6 then table.insert(imgs, d) end -- картинка самого предмета (а не общий фон/значок)
    end
    local k
    -- 0) то, что ты сам показал кнопками «Нож / Пистолет» (запоминается навсегда)
    S.imgKinds = S.imgKinds or {}
    for d in pairs(S.imgKinds) do if #d < 5 then S.imgKinds[d] = nil end end -- «250» и т.п. — это был размер, а не картинка
    for _, d in ipairs(imgs) do
        local kk = S.imgKinds[d] or (env.TV_globalKinds or {})[d]
        if kk then
            env.TV_kindDiag = cell.Name .. ": " .. d .. " → " .. kk .. " (запомнено)"
            env.TV_kindTaught = true
            return kk
        end
    end
    env.TV_kindTaught = false
    -- 1) имя ячейки и её атрибуты («LatteGun», ItemType = "Knife») — если имя не общее для всех ячеек
    local parts = {}
    if (fName[cell.Name] or 0) <= 6 then table.insert(parts, cell.Name) end
    for an, av in pairs(cell:GetAttributes()) do table.insert(parts, tostring(an) .. "=" .. tostring(av)) end
    k = env.TV_kindOf(table.concat(parts, " "))
    -- 2) база MM2 по любой картинке ячейки; 3) название картинки в Roblox — только если там прямо написано
    for _, d in ipairs(imgs) do
        if k then break end
        local info = (env.TV_dbImg or {})[d]
        k = info and env.TV_kindOf(info.kind) or nil
    end
    local diag = {}
    for _, d in ipairs(imgs) do
        local nm = env.TV_imgNameOf(d)
        if not k and nm then k = env.TV_kindOf(nm) end
        local info = (env.TV_dbImg or {})[d]
        table.insert(diag, d .. "=" .. (nm and ("«" .. nm .. "»") or "…") .. (info and ("/база " .. (info.kind ~= "" and info.kind or "?")) or ""))
        if #diag >= 3 then break end
    end
    env.TV_kindDiag = cell.Name .. ": " .. table.concat(diag, ", ") .. " → " .. (k or "?")
    return k
end

-- свои предметы в окне трейда: ячейки в сетке/списке вне обоих офферов (в том числе скрытые)
local function scanInventory(tg, mine, theirs)
    local items = {}
    for _, d in ipairs(tg:GetDescendants()) do
        if (d:IsA("Frame") or d:IsA("ImageButton") or d:IsA("ImageLabel") or d:IsA("TextButton"))
           and d.Visible
           and not d:IsDescendantOf(mine) and not d:IsDescendantOf(theirs)
           and d.Parent and (d.Parent:FindFirstChildWhichIsA("UIGridLayout") or d.Parent:FindFirstChildWhichIsA("UIListLayout")) then
            local price, amount, name = readItem(d)
            if price and price > 0 then
                table.insert(items, { frame = d, price = price, amount = amount, name = name, kept = env.TV_keptCell(d) })
            end
        end
    end
    -- убираем «контейнеры»: если внутри кандидата есть другой кандидат, это не ячейка предмета
    local cells, seenNow = {}, {}
    for _, it in ipairs(items) do
        local isContainer = false
        for _, other in ipairs(items) do
            if other ~= it and other.frame:IsDescendantOf(it.frame) then isContainer = true; break end
        end
        if not isContainer then
            harvestImage(it.frame, it.name)
            if isShown(it.frame) then table.insert(seenNow, it) end -- для «Мой инвентарь» и статистики
            if not it.kept then table.insert(cells, it) end
        end
    end
    if #seenNow > 0 and env.TV_invSnapshot then pcall(env.TV_invSnapshot, seenNow, mine) end
    -- у MM2 два варианта окна трейда; скрытый может хранить старый инвентарь (уже отданные предметы).
    -- Если что-то видно на экране — берём только видимое.
    local shownCells = {}
    for _, it in ipairs(cells) do if isShown(it.frame) then table.insert(shownCells, it) end end
    if #shownCells > 0 then return shownCells end
    return cells
end

-- набираем предметы, не превышая нужную сумму. По возможности: разные предметы (не стопки одинаковых)
-- и не то, что положил он сам (avoid = ключи его предметов). Не набирается — возвращаемся к обычному набору.
local function pickItems(items, need, avoid)
    avoid = avoid or {}
    table.sort(items, function(a, b) return a.price > b.price end)
    local function greedy(distinct, skipAvoid)
        local picks, sum = {}, 0
        for _, it in ipairs(items) do
            if not (skipAvoid and avoid[norm(it.name)]) and not (distinct and #picks >= 4) then
                local n = 0
                while n < (distinct and 1 or it.amount) and sum + it.price <= need do
                    sum += it.price; n += 1
                end
                if n > 0 then table.insert(picks, { item = it, count = n }) end
            end
        end
        return picks, sum
    end
    local slack = math.max(1, need * 0.03)
    local bestP, bestS = greedy(true, true)          -- разные, без его предметов
    for _, mode in ipairs({ { false, true }, { true, false }, { false, false } }) do
        local p2, s2 = greedy(mode[1], mode[2])
        if s2 > bestS + slack then bestP, bestS = p2, s2 end -- заметно точнее — берём
    end
    return bestP, bestS
end

-- нажать на кнопку/ячейку так же, как это делает игрок.
-- способы: 1 — вызвать обработчики кнопки, 2 — firesignal, 3 — виртуальный клик мышью в центр.
-- method = nil: пробуем по порядку до первого сработавшего; число: только этот способ.
local GuiService = game:GetService("GuiService")
-- полноэкранный выбор предметов MM2 (вкладки «Оружие/Питомцы» и кнопка «<»): закрыть, чтобы была видна кнопка «Принять»
env.TV_findBack = function(tg)
    local tabs = false
    for _, d in ipairs(tg:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and isShown(d) then
            local t = env.TV_low(d.Text):gsub("^%s+", ""):gsub("%s+$", "")
            if t == "weapons" or t == "оружие" then tabs = true; break end
        end
    end
    if not tabs then return nil end
    local ARROWS = { ["<"] = true, ["‹"] = true, ["←"] = true, ["<<"] = true }
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("GuiButton") and isShown(d) then
            local n = d.Name:lower()
            if n == "back" or n:find("^back") or n:find("return") then return d end
        end
        -- «<» — надпись (в кнопке, на кнопке или поверх неё)
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and ARROWS[(d.Text:gsub("%s", ""))] and isShown(d) then
            if d:IsA("GuiButton") then return d end
            local b = d:FindFirstAncestorWhichIsA("GuiButton")
            if b then return b end
            local c = d.AbsolutePosition + d.AbsoluteSize / 2
            for _, x in ipairs((d.Parent and d.Parent.Parent or tg):GetDescendants()) do
                if x:IsA("GuiButton") and isShown(x) then
                    local p0, sz = x.AbsolutePosition, x.AbsoluteSize
                    if c.X >= p0.X and c.X <= p0.X + sz.X and c.Y >= p0.Y and c.Y <= p0.Y + sz.Y then return x end
                end
            end
        end
    end
end

-- кнопки, которые скрипт не нажимает НИКОГДА: «Торговые запросы: выключить/включить», приглашения и т.п.
-- только видимые надписи (не внутреннее имя: кнопка «Принять» в списке запросов может называться «AcceptRequest»)
env.TV_FORBIDDEN = { "выключ", "включ", "disable", "enable", "toggle", "приглас", "invite" }
-- строка «Запросы на обмен: [ползунок] выключено/включено» — все её кнопки в чёрном списке навсегда
env.TV_noClick = env.TV_noClick or setmetatable({}, { __mode = "k" })
env.TV_scanToggles = function()
    for _, l in ipairs(PlayerGui:GetDescendants()) do
        if (l:IsA("TextLabel") or l:IsA("TextButton")) and l.Text ~= "" then
            local t = env.TV_low(l.Text)
            if t:find("запросы на обмен") or t:find("торговые запросы") or t:find("trade request") or t:find("trading requests") then
                local row = l.Parent
                for _ = 1, 2 do
                    if row and row.Parent and not row.Parent:IsA("ScreenGui") and #row:GetChildren() < 4 then row = row.Parent end
                end
                local ly, lh = l.AbsolutePosition.Y + l.AbsoluteSize.Y / 2, math.max(14, l.AbsoluteSize.Y)
                for _, bt in ipairs(row and row:GetDescendants() or {}) do
                    -- только кнопки этой же строки (по высоте), остальное в панели не трогаем
                    if bt:IsA("GuiButton") and math.abs(bt.AbsolutePosition.Y + bt.AbsoluteSize.Y / 2 - ly) <= lh then env.TV_noClick[bt] = true end
                end
                if l:IsA("GuiButton") then env.TV_noClick[l] = true end
            end
        end
    end
end
env.TV_forbidden = function(b)
    if env.TV_noClick[b] then return true end
    local t = env.TV_btnText(b):sub(#env.TV_low(b.Name) + 2)
    for _, w in ipairs(env.TV_FORBIDDEN) do if t:find(w, 1, true) then return true end end
    -- надписи рядом в той же строке («выключено» справа от ползунка)
    local p0, sz = b.AbsolutePosition, b.AbsoluteSize
    local scope = b.Parent and (b.Parent.Parent or b.Parent)
    for _, l in ipairs(scope and scope:GetDescendants() or {}) do
        if (l:IsA("TextLabel") or l:IsA("TextButton")) and l ~= b and l.Text ~= "" and l.Visible then
            local c = l.AbsolutePosition + l.AbsoluteSize / 2
            if math.abs(c.Y - (p0.Y + sz.Y / 2)) <= math.max(12, sz.Y / 2) and c.X >= p0.X - 260 and c.X <= p0.X + sz.X + 260 then
                local lt = env.TV_low(l.Text)
                for _, w in ipairs(env.TV_FORBIDDEN) do if lt:find(w, 1, true) then return true end end
                if lt:find("запросы на обмен") or lt:find("trade request") then return true end
            end
        end
    end
    return false
end
task.spawn(function()
    while true do
        pcall(env.TV_scanToggles)
        task.wait(4)
    end
end)
local function clickCell(cell, tg, method)
    local btn = cell:IsA("GuiButton") and cell or cell:FindFirstChildWhichIsA("GuiButton", true) or cell
    if btn:IsA("GuiButton") and env.TV_forbidden(btn) then return nil end
    local SIGNALS = { "MouseButton1Click", "Activated", "MouseButton1Down" }
    local function viaConnections()
        if not getconnections then return false end
        for _, sigName in ipairs(SIGNALS) do
            local ok, found = pcall(getconnections, btn[sigName])
            if ok and found and #found > 0 then
                for _, c in ipairs(found) do
                    if not pcall(function() c:Fire() end) then pcall(function() c.Function() end) end
                end
                return true
            end
        end
        return false
    end
    local function viaFiresignal()
        if not firesignal then return false end
        for _, sigName in ipairs(SIGNALS) do
            if pcall(firesignal, btn[sigName]) then return true end
        end
        return false
    end
    local function viaMouse()
        if not env.TV_vis(btn) then return false end
        local p0, sz0 = btn.AbsolutePosition, btn.AbsoluteSize
        -- что окажется под курсором: если там переключатель запросов и т.п. — мышью не жмём
        local ins = GuiService:GetGuiInset()
        for _, dy in ipairs({ 0, ins.Y, -ins.Y }) do -- с отступом верхней панели и без: куда бы ни попал щелчок
            local okP, under = pcall(function() return PlayerGui:GetGuiObjectsAtPosition(p0.X + sz0.X / 2, p0.Y + sz0.Y / 2 + dy) end)
            -- только то, во что реально попадёт щелчок (самый верхний), а не панели позади окна трейда
            local top = okP and under and under[1]
            if top and not top:IsDescendantOf(ui) then
                local b = top:IsA("GuiButton") and top or top:FindFirstAncestorWhichIsA("GuiButton")
                if b and b ~= btn and env.TV_forbidden(b) then return false end
            end
        end
        return (pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local p, sz = btn.AbsolutePosition, btn.AbsoluteSize
            local inset = (tg and tg.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
            local x, y = p.X + sz.X / 2 + inset.X, p.Y + sz.Y / 2 + inset.Y
            vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end))
    end
    -- 4) все обработчики кнопки и вложенных кнопок (в т.ч. нажатие пальцем) — для «Отказа»
    local function viaAll()
        if not getconnections then return false end
        local targets = { btn }
        for _, d in ipairs(btn:GetDescendants()) do
            if d:IsA("GuiButton") and not env.TV_forbidden(d) then table.insert(targets, d) end
        end
        local fired = false
        for _, b in ipairs(targets) do
            for _, sigName in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up", "TouchTap" }) do
                local ok, found = pcall(getconnections, b[sigName])
                if ok and found then
                    for _, c in ipairs(found) do
                        fired = true
                        if not pcall(function() c:Fire() end) then pcall(function() c.Function() end) end
                    end
                end
            end
        end
        return fired
    end
    -- 5) «сырое» нажатие: обработчики InputBegan/InputEnded ТОЛЬКО самой кнопки (не родителей: родительские блоки
    --    вроде верхней панели могут сами решать, куда «нажали», — так задевался переключатель «Запросы на обмен»)
    local function viaInput()
        if not getconnections then return false end
        local p, sz = btn.AbsolutePosition, btn.AbsoluteSize
        local pos = Vector3.new(p.X + sz.X / 2, p.Y + sz.Y / 2, 0)
        local fired = false
        local o = btn
        for _ = 1, 1 do
            if not (o and o:IsA("GuiObject")) then break end
            for _, kind in ipairs({ Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch }) do
                for _, ev in ipairs({ { "InputBegan", Enum.UserInputState.Begin }, { "InputEnded", Enum.UserInputState.End } }) do
                    local ok, found = pcall(getconnections, o[ev[1]])
                    if ok and found then
                        local input = { UserInputType = kind, UserInputState = ev[2], Position = pos, Delta = Vector3.zero, KeyCode = Enum.KeyCode.Unknown }
                        for _, c in ipairs(found) do
                            fired = true
                            pcall(function() c.Function(input, false) end)
                        end
                    end
                end
            end
            o = o.Parent
        end
        return fired
    end
    local ways = { viaConnections, viaFiresignal, viaMouse, viaAll, viaInput }
    if method then return ways[method]() and method or nil end
    for i, way in ipairs(ways) do
        if way() then return i end
    end
    return nil
end

-- кнопка «Добавить предметы» (открывает инвентарь в окне трейда)
local function findAddButton(tg)
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("GuiButton") and isShown(d) then
            local all = env.TV_btnText(d)
            if all:find("add item") or all:find("additem") or all:find("добавить") then return d end
        end
    end
end

local auto = { busy = false, lastTh = -1, stableSince = 0, doneFor = -1, declined = false,
               accSig = "", accSince = 0, accTries = 0, accDone = false, accLast = 0 }
function auto.closePicker(tg)
    local b = env.TV_findBack(tg)
    if b then clickCell(b, tg); return true end
    return false
end

-- кнопка «Принять» (не «Отменить/Unaccept»)
function auto.findAccept(tg)
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("GuiButton") and isShown(d) then
            local all = env.TV_btnText(d)
            local isAccept = all:find("accept") or all:find("принят") or all:find("sure") or all:find("уверен") or all:find("confirm") or all:find("подтверд")
            -- «Please wait (2) before accepting» — это отсчёт, а не кнопка
            if all:find("wait") or all:find("подожд") or all:find("%(%d+%)") then isAccept = false end
            if isAccept and not (all:find("unaccept") or all:find("отмен") or all:find("cancel") or all:find("не прин")) then
                return d
            end
        end
    end
end

-- автопринятие входящего запроса на трейд.
-- В MM2 запросы копятся под кнопкой «+» с красным «!» — сначала открываем этот список, потом жмём «Принять».
auto.reqLast, auto.reqOpenLast = 0, 0
auto.REQ_WORDS = { "trade", "обмен", "торг", "wants", "хочет", "request", "запрос", "invite" }
-- имена всех родителей кнопки + тексты рядом с ней (в списке запросов рядом только ник)
function auto.reqContext(d, g)
    local parts = { g.Name }
    local o = d.Parent
    while o and o ~= g do table.insert(parts, o.Name); o = o.Parent end
    local box = d.Parent and d.Parent.Parent or d.Parent
    if box then
        for _, t in ipairs(box:GetDescendants()) do
            if t:IsA("TextLabel") then table.insert(parts, t.Text) end
        end
    end
    return table.concat(parts, " "):lower()
end
function auto.hasReqWord(ctx)
    for _, w in ipairs(auto.REQ_WORDS) do if ctx:find(w, 1, true) then return true end end
    return false
end
-- красный «!» (непрочитанные запросы): метка «!» на экране игры и кнопка рядом с ней
-- у кнопки есть надпись из букв («выключить», «Пригласить»…) — значит это не «+» со списком запросов
function auto.hasWords(b)
    local texts = { b:IsA("TextButton") and b.Text or "" }
    for _, l in ipairs(b:GetDescendants()) do
        if (l:IsA("TextLabel") or l:IsA("TextButton")) and l.Visible then table.insert(texts, l.Text) end
    end
    -- и надписи поверх кнопки (у переключателя «Запросы на обмен: ВКЛЮЧЕНО» текст лежит сверху, а не внутри)
    local p0, sz = b.AbsolutePosition, b.AbsoluteSize
    local scope = b.Parent and (b.Parent.Parent or b.Parent)
    for _, l in ipairs(scope and scope:GetDescendants() or {}) do
        if (l:IsA("TextLabel") or l:IsA("TextButton")) and l ~= b and l.Visible and l.Text ~= "" then
            local c = l.AbsolutePosition + l.AbsoluteSize / 2
            if c.X >= p0.X - 4 and c.X <= p0.X + sz.X + 4 and c.Y >= p0.Y - 4 and c.Y <= p0.Y + sz.Y + 4 then table.insert(texts, l.Text) end
        end
    end
    local t = env.TV_low(table.concat(texts, " "))
    -- переключатели запросов, приглашения и т.п. — никогда (по надписям, не по имени кнопки)
    for _, w in ipairs({ "запрос", "request", "включ", "выключ", "enabl", "disabl", " on", " off", "invite", "приглас" }) do
        if t:find(w, 1, true) then return true end
    end
    local own = env.TV_low(table.concat(texts, " "))
    return own:find("%a") ~= nil or own:find("[89]") ~= nil
end
-- вкладка инвентаря в окне трейда: "weapons" (Оружие) или "pets" (Питомцы)
function auto.openTab(tg, which)
    local words = which == "pets" and { pets = true, ["питомцы"] = true } or { weapons = true, ["оружие"] = true }
    for _, d in ipairs(tg:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and isShown(d) then
            local t = env.TV_low(d.Text):gsub("^%s+", ""):gsub("%s+$", "")
            if words[t] then
                local b = d:IsA("GuiButton") and d or d:FindFirstAncestorWhichIsA("GuiButton")
                if not b and d.Parent then
                    local c = d.AbsolutePosition + d.AbsoluteSize / 2
                    for _, x in ipairs(d.Parent:GetDescendants()) do
                        if x:IsA("GuiButton") and isShown(x) then
                            local p0, sz = x.AbsolutePosition, x.AbsoluteSize
                            if c.X >= p0.X and c.X <= p0.X + sz.X and c.Y >= p0.Y and c.Y <= p0.Y + sz.Y then b = x; break end
                        end
                    end
                end
                if b then clickCell(b, tg); return true end
            end
        end
    end
    return false
end

function auto.findBadge()
    local roots = { PlayerGui }
    pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
    for _, root in ipairs(roots) do
        local okD, desc = pcall(function() return root:GetDescendants() end)
        for _, t in ipairs(okD and desc or {}) do
            if t:IsA("TextLabel") and t.Text:match("^%s*!%s*$") and not t:IsDescendantOf(ui) and isShown(t) then
                -- «!» внутри кнопки
                local btn = t:FindFirstAncestorWhichIsA("GuiButton")
                -- или кнопка рядом (бейдж лежит поверх «+»)
                if not btn then
                    local c = t.AbsolutePosition + t.AbsoluteSize / 2
                    local best, bestD = nil, 45 -- «+» под «!» вплотную; дальше — уже другие кнопки
                    local scope = t.Parent and t.Parent.Parent or t.Parent
                    for _, b in ipairs(scope and scope:GetDescendants() or {}) do
                        if b:IsA("GuiButton") and isShown(b) and not env.TV_forbidden(b) then
                            local d = ((b.AbsolutePosition + b.AbsoluteSize / 2) - c).Magnitude
                            if d < bestD then best, bestD = b, d end
                        end
                    end
                    btn = best
                end
                if btn and not env.TV_forbidden(btn) then
                    local g = btn:FindFirstAncestorWhichIsA("ScreenGui")
                    return { btn, g }
                end
            end
        end
    end
end

function auto.tryAcceptRequest()
    if not (S.enabled and S.autoRequest) or os.clock() - auto.reqLast < 1 then return end
    local badge -- кнопка с красным «!» (непрочитанные запросы)
    for _, g in ipairs(PlayerGui:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled and g ~= ui and g ~= hlGui then
            local offer = g:FindFirstChild("YourOffer", true)
            if not (offer and offer:IsA("GuiObject") and isShown(offer)) then
                for _, d in ipairs(g:GetDescendants()) do
                    if d:IsA("GuiButton") and isShown(d) then
                        local txt = env.TV_btnText(d)
                        if (txt:find("accept") or txt:find("принят")) and not (txt:find("decline") or txt:find("отклон")) then
                            local ctx = auto.reqContext(d, g)
                            local blockedName
                            for name, untilT in pairs(auto.blocked or {}) do
                                if untilT > os.clock() and ctx:find(name, 1, true) then blockedName = name; break end
                            end
                            if blockedName then
                                -- запрос от того, кто в блоке: ищем рядом «Отклонить» и жмём её
                                local box = d.Parent
                                for _, b in ipairs(box and box:GetDescendants() or {}) do
                                    if b:IsA("GuiButton") and b ~= d and isShown(b) then
                                        local bt = env.TV_btnText(b)
                                        if bt:find("decline") or bt:find("отклон") or bt:find("отказ") or bt:find("deny") or bt:find("reject") then
                                            auto.reqLast = os.clock()
                                            clickCell(b, g)
                                            notify(T("blockedReq"):format(blockedName))
                                            return
                                        end
                                    end
                                end
                            elseif auto.hasReqWord(ctx) then
                                auto.reqLast, auto.badgeOpens = os.clock(), 0
                                clickCell(d, g)
                                notify(T("requestAccepted"))
                                return
                            end
                        end
                    end
                end
            end
        end
    end
    -- кнопки «Принять» на экране нет, но есть красный «!» — открываем список запросов
    badge = auto.findBadge()
    -- «!» висит, а принимать нечего (например, это приглашение в друзья) — после 2 открытий пауза 20 с
    if (auto.badgeOpens or 0) >= 2 then
        if os.clock() - auto.reqOpenLast < 20 then return end
        auto.badgeOpens = 0
    end
    if badge and os.clock() - auto.reqOpenLast > 1.5 then
        auto.reqOpenLast = os.clock()
        auto.badgeOpens = (auto.badgeOpens or 0) + 1
        clickCell(badge[1], badge[2])
        -- временная диагностика: один раз снять кнопки открытого списка и отправить на ПК разработчику
        if not auto.dumped then auto.dumped = true; task.delay(2.5, auto.debugDump) end
    end
end

-- временная диагностика списка запросов: видимые кнопки -> POST на ПК (если там запущен приёмник)
function auto.debugDump()
    pcall(function()
        local out = {}
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("GuiButton") and not d:IsDescendantOf(ui) and isShown(d) then
                local texts = {}
                for _, t in ipairs(d:GetDescendants()) do
                    if (t:IsA("TextLabel") or t:IsA("TextButton")) and t.Text ~= "" then table.insert(texts, t.Text) end
                end
                local near = {}
                for _, t in ipairs(d.Parent and d.Parent:GetDescendants() or {}) do
                    if t:IsA("TextLabel") and t.Text ~= "" and #near < 4 then table.insert(near, t.Text) end
                end
                table.insert(out, table.concat({ d:GetFullName(), d.ClassName, d:IsA("TextButton") and d.Text or "",
                    table.concat(texts, "/"), "near=" .. table.concat(near, "/"),
                    "img=" .. (d:IsA("ImageButton") and d.Image or "") }, " | "))
            end
        end
        local req = request or http_request or (syn and syn.request)
        if not req then return end
        for _, host in ipairs({ "10.0.2.2", "192.168.1.100", "127.0.0.1" }) do
            local ok, res = pcall(req, { Url = "http://" .. host .. ":8799/", Method = "POST", Body = table.concat(out, "\n") })
            if ok and res and (res.StatusCode == 200 or res.Success) then break end
        end
    end)
end

-- соперник ничего не предлагает: убрать своё (если он всё убрал) и через 7 с отклонить
-- блок на 80 секунд для тех, с кем скрипт уже отклонил трейд
auto.blocked = {}
function auto.block(name)
    if name and name ~= "" then auto.blocked[name:lower()] = os.clock() + 80 end
end
function auto.isBlocked(name)
    local t = name and auto.blocked[name:lower()]
    return t ~= nil and t > os.clock()
end

function auto.handleEmpty(tg, mine, theirs, my, th)
    if th > 0 then auto.emptySince, auto.hadTheirs, auto.nudged, auto.nudgeDone, auto.junkSig = nil, true, false, nil, nil; return false end
    -- считаем и предметы без цены: «пусто» — когда в его оффере вообще ничего нет
    local _, thUnk = sumOffer(theirs)
    if thUnk > 0 then
        auto.emptySince = nil
        if not S.junkDecline then return false end
        -- что лежит у него сейчас (изменилось — отсчёт заново, как и отсчёт MM2)
        local parts = {}
        for _, d in ipairs(theirs:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then table.insert(parts, d.Text) end
        end
        local sig = table.concat(parts, "|")
        if sig ~= auto.junkSig then auto.junkSig, auto.junkSince = sig, os.clock() end
        local left = 11 - (os.clock() - auto.junkSince) -- 6 с отсчёт MM2 + 5 с
        sugLine.Visible = true
        hideHighlights()
        if left > 0 then sugText.Text = T("junkWait"):format(math.ceil(left)); return true end
        if os.clock() - (auto.declLast or 0) < 1.5 or (auto.declTries or 0) >= 9 then return true end
        local btn = auto.findDecline(tg)
        if not btn then auto.noDecline(tg); return true end
        auto.declLast = os.clock()
        auto.declTries = (auto.declTries or 0) + 1
        if auto.declTries == 1 then auto.pendingBlock = auto.partner end
        auto.pressDecline(btn, tg, auto.declTries)
        return true
    end
    auto.emptySince = auto.emptySince or os.clock()

    -- он всё убрал — убираю и я (один раз, кликами по своим предметам)
    if S.mirrorEmpty and auto.hadTheirs and my > 0 and not auto.busy then
        auto.hadTheirs = false
        auto.busy = true
        sugLine.Visible = true
        sugText.Text = T("emptyCleared")
        task.spawn(function()
            pcall(function()
                for _ = 1, 40 do -- не больше 40 нажатий (4 ячейки по большим стопкам)
                    if not S.enabled then break end
                    local cell
                    for key in pairs(auto.readOffer(mine)) do
                        cell = auto.myCell(mine, key)
                        if cell then break end
                    end
                    if not cell then break end -- мой оффер пуст
                    clickCell(cell, tg)
                    task.wait(0.35)
                end
            end)
            auto.busy = false
        end)
        return true
    end

    if not S.emptyDecline then return false end
    sugLine.Visible = true
    hideHighlights()
    -- 1) 12 с пусто — кладём случайный предмет на 2 с и убираем (показать, что ты на месте)
    if not auto.nudged then
        local left = 12 - (os.clock() - auto.emptySince)
        if left > 0 then sugText.Text = T("nudgeWait"):format(math.ceil(left)); return true end
        if auto.busy then return true end
        auto.nudged, auto.busy = true, true
        sugText.Text = T("nudging")
        task.spawn(function()
            pcall(function()
                local inv = scanInventory(tg, mine, theirs)
                -- один случайный предмет
                local pool = {}
                for _, it in ipairs(inv) do table.insert(pool, it) end
                local picks = {}
                for _ = 1, math.min(1, #pool) do
                    table.insert(picks, table.remove(pool, math.random(1, #pool)))
                end
                local anyHidden = false
                for _, it in ipairs(picks) do if not isShown(it.frame) then anyHidden = true end end
                if anyHidden then
                    local addBtn = findAddButton(tg)
                    if addBtn then clickCell(addBtn, tg); task.wait(0.8) end
                end
                local added = {}
                for _, it in ipairs(picks) do
                    if it.frame.Parent and isShown(it.frame) then
                        clickCell(it.frame, tg)
                        added[norm(it.name)] = (added[norm(it.name)] or 0) + 1
                        task.wait(0.3)
                    end
                end
                task.wait(2) -- держим предмет 2 секунды
                -- убираем только то, что положили сами
                local have = auto.readOffer(mine)
                for key, n in pairs(added) do
                    for _ = 1, n do
                        local cell = have[key] and auto.myCell(mine, key)
                        if not cell then break end
                        clickCell(cell, tg)
                        task.wait(0.3)
                    end
                end
            end)
            auto.busy = false
            auto.nudgeDone = os.clock()
        end)
        return true
    end
    if auto.busy or not auto.nudgeDone then return true end
    -- 2) ещё 8 с пусто — отказ (повторяем разными способами нажатия) и блок на 80 секунд
    local left = 8 - (os.clock() - auto.nudgeDone)
    if left > 0 then sugText.Text = T("emptyWait"):format(math.ceil(left)); return true end
    if os.clock() - (auto.declLast or 0) < 1.5 or (auto.declTries or 0) >= 9 then return true end
    local btn = auto.findDecline(tg)
    if not btn then auto.noDecline(tg); return true end
    auto.declLast = os.clock()
    auto.declTries = (auto.declTries or 0) + 1
    if auto.declTries == 1 then auto.pendingBlock = auto.partner end -- в блок — когда трейд реально закроется
    auto.pressDecline(btn, tg, auto.declTries)
    return true
end

-- подарок: соперник положил предметы и принял, а у тебя пусто — принимаем сразу
function auto.tryGift(tg, theirs, my, myUnk)
    if not (S.enabled and S.giftAccept) or my > 0 or myUnk > 0 then return false end
    local th, thUnk = sumOffer(theirs)
    if th <= 0 and thUnk <= 0 then return false end
    -- «Другой игрок принял это предложение» / «The other player accepted»
    local accepted = false
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            local t = env.TV_low(d.Text)
            if (t:find("принял") or t:find("accepted")) and isShown(d) then accepted = true; break end
        end
    end
    if not accepted then return false end
    sugLine.Visible = true
    hideHighlights()
    if os.clock() - (auto.giftLast or 0) < 1.2 or (auto.giftTries or 0) >= 12 then return true end
    local btn = auto.findAccept(tg)
    if not btn then return true end
    auto.giftLast = os.clock()
    auto.giftTries = (auto.giftTries or 0) + 1
    sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.good), T("giftDoing"):format(auto.giftTries))
    clickCell(btn, tg, (auto.giftTries - 1) % 3 + 1)
    return true
end

-- трейд с тем, кто в блоке: сразу отказ
function auto.handleBlocked(tg)
    if not (S.autoRequest and auto.partner and auto.isBlocked(auto.partner)) then return false end
    sugLine.Visible = true
    sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.bad), T("blockedTrade"):format(auto.partner))
    hideHighlights()
    if os.clock() - (auto.declLast or 0) < 1.5 or (auto.declTries or 0) >= 9 then return true end
    local btn = auto.findDecline(tg)
    if btn then
        auto.declLast = os.clock()
        auto.declTries = (auto.declTries or 0) + 1
        auto.pressDecline(btn, tg, auto.declTries)
    else
        auto.noDecline(tg)
    end
    return true
end

-- принять трейд, когда он выгоден по цели и обе стороны какое-то время ничего не меняют
function auto.setAcc(key, ...)
    local acc = (L[S.lang] or L.ru).acc or {}
    X.accLine.Visible = S.autoAccept and key ~= "off"
    X.accLine.Text = select("#", ...) > 0 and (acc[key] or key):format(...) or (acc[key] or key)
end
function auto.tryAccept(tg, theirs, my, th, myUnk)
    if not (S.autoAccept and S.enabled) then auto.setAcc("off"); return end
    -- «сдался» не навсегда: через 10 с пробуем снова (трейд могли отменить и начать заново)
    if auto.accDone and os.clock() - (auto.accDoneAt or 0) > 10 then auto.accDone, auto.accTries = false, 0 end
    if auto.accDone then auto.setAcc("gaveup"); return end
    if auto.busy then auto.setAcc("busy"); return end
    if th <= 0 then auto.setAcc("wait"); return end
    if myUnk > 0 then auto.setAcc("unk"); return end
    if S.autoDecline and auto.findUnwanted(theirs) and not select(2, auto.junkSplit(theirs)) then auto.setAcc("bad"); return end
    local profit = my > 0 and (th - my) / my * 100 or math.huge
    -- тот же запас, что у подсказки «Цель достигнута»: перебор до ~1 value (или 2%) считается целью
    local strict = S.tiersOn and not auto.ordProfit -- ступени: процент — жёсткий минимум, без допусков
    local maxMine = th / (1 + ((auto.ordProfit or env.TV_pct(th)) - ((S.tolerance and not strict) and 1 or 0)) / 100)
    if S.fillOver and auto.fillTh == th and auto.fillMy then
        maxMine = math.max(maxMine, auto.fillMy) -- скрипт сам добил сверх цели: такой оффер тоже принимаем
    end
    if my > maxMine + (strict and 0.05 or math.max(1, maxMine * 0.02)) then
        auto.accSig = ""
        auto.setAcc("low", profit == math.huge and 999 or math.floor(profit + 0.5))
        return
    end
    local sig = my .. "|" .. th
    if sig ~= auto.accSig then
        -- трейд изменился: всё сначала
        auto.accSig, auto.accSince, auto.accTries, auto.accDone = sig, os.clock(), 0, false
        auto.setAcc("hold", 2)
        return
    end
    if os.clock() - auto.accSince < 2 then auto.setAcc("hold", math.max(1, math.ceil(2 - (os.clock() - auto.accSince)))); return end
    if os.clock() - auto.accLast < 1.5 then return end
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then
            local t = env.TV_low(d.Text)
            if (t:find("wait") or t:find("подожд")) and isShown(d) then auto.setAcc("countdown"); return end
        end
    end
    -- открыт полноэкранный выбор предметов: сначала закрываем его, принимаем на следующем шаге
    if auto.closePicker(tg) then auto.accLast = os.clock(); auto.setAcc("hold", 1); return end
    local btn = auto.findAccept(tg)
    if not btn then
        -- подсказка для отладки: окно и видимые кнопки, которые скрипт видит
        local seen = {}
        for _, d in ipairs(tg:GetDescendants()) do
            if d:IsA("GuiButton") and env.TV_vis(d) and #seen < 6 then
                local t = env.TV_btnText(d):gsub("%s+", " ")
                table.insert(seen, t:sub(1, 22))
            end
        end
        auto.setAcc("nobtn", tg.Name .. ": " .. table.concat(seen, " | "))
        return
    end
    -- надпись на кнопке сменилась («Принять» -> «Вы уверены?» или обратно после отмены) — новый этап, попытки заново
    local lbl = btn:FindFirstChildWhichIsA("TextLabel", true)
    local btnText = (btn:IsA("TextButton") and btn.Text or "") .. "|" .. (lbl and lbl.Text or "")
    if btnText ~= auto.accBtnText then auto.accBtnText, auto.accTries = btnText, 0 end
    auto.accLast = os.clock()
    auto.accTries += 1
    -- если кнопка после нажатия не изменилась, следующая попытка — другим способом
    local ACC_WAYS = { 1, 3, 5, 2, 4 }
    -- способ по кругу; не сработал — следующий (а не снова первый: на «Вы уверены?» он не помогает)
    local used
    for k = 0, #ACC_WAYS - 1 do
        local method = ACC_WAYS[(auto.accTries - 1 + k) % #ACC_WAYS + 1]
        used = clickCell(btn, tg, method)
        if used then break end
    end
    if auto.accTries >= 9 then auto.accDone, auto.accDoneAt = true, os.clock() end -- не долбим кнопку бесконечно
    notify(T("accepting"):format(profit == math.huge and 999 or math.floor(profit + 0.5), used or 0))
    auto.setAcc("click", used or 0, auto.accTries)
end
;(function()
-- картинки с сайта: лежат в репозитории, качаются один раз и хранятся в папке Delta
local IMG_BASE = VALUES_URL:gsub("values%.json$", "img/")
local IMG_DIR = "TradeValues_img2" -- v2: составные картинки сетов (новая папка = скачать заново)
local canFiles = writefile and readfile and isfile and getcustomasset
if canFiles then pcall(function() if not isfolder(IMG_DIR) then makefolder(IMG_DIR) end end) end
local imgMissing, imgWaiters, imgQueue, imgWorkers = {}, {}, {}, 0
local function imgKey(name) return (name:find(" Set", 1, true) and "set" or "") .. norm(name) end
local function siteImageWorker()
    imgWorkers += 1
    while #imgQueue > 0 do
        local key = table.remove(imgQueue, 1)
        local path = IMG_DIR .. "/" .. key .. ".png"
        local ok, data = pcall(function() return game:HttpGet(IMG_BASE .. key .. ".png") end)
        local asset
        if ok and type(data) == "string" and data:sub(2, 4) == "PNG" then
            pcall(writefile, path, data)
            local ok2, a = pcall(getcustomasset, path)
            if ok2 then asset = a end
        end
        if not asset then imgMissing[key] = true end
        for _, cb in ipairs(imgWaiters[key] or {}) do if asset then pcall(cb, asset) end end
        imgWaiters[key] = nil
    end
    imgWorkers -= 1
end
-- вернуть картинку сразу (если уже скачана) или скачать и отдать в cb
local function siteImage(name, cb, keyOverride)
    if not canFiles then return nil end
    local key = keyOverride or imgKey(name)
    if imgMissing[key] then return nil end
    local path = IMG_DIR .. "/" .. key .. ".png"
    local okF, exists = pcall(isfile, path)
    if okF and exists then
        local ok, a = pcall(getcustomasset, path)
        if ok then return a end
    end
    if cb then
        if not imgWaiters[key] then
            imgWaiters[key] = {}
            table.insert(imgQueue, key)
            if imgWorkers < 4 then task.spawn(siteImageWorker) end
        end
        table.insert(imgWaiters[key], cb)
    end
    return nil
end

env.TV_image = function(name, cb, key)
    if key and not imgMissing[key] then
        local own = siteImage(name, cb, key) -- своя картинка категории; если её нет — обычная
        if own then return own end
        if canFiles then return "" end
    end
    local site = siteImage(name, cb)
    if site then return site end
    if canFiles and not imgMissing[imgKey(name)] then return "" end -- ждём картинку с сайта
    if name:find(" Set") then return "" end -- у сетов своей картинки нет (и «Sun Set» не путаем с «Sunset»)
    local key = norm(name:gsub("^C%. ", "Chroma "))
    local img = imageCache[key] or dbChroma[key]
    if not img then -- хрома без своей картинки -> картинка обычного предмета
        local base = name:gsub("^Chroma ", ""):gsub("^C%. ", "")
        img = imageCache[norm(base)]
    end
    return img or ""
end

-- значок Auto Trade (белый знак; фон — градиент акцента). Пока не скачался — буквы «AT»
local function setLogo(a)
    if not a or a == "" then return end
    X.gearImg.Image, X.logoImg.Image = a, a
    X.gearText.Visible, X.logoText.Visible = false, false
end
pcall(function() setLogo(env.TV_image("", function(a) pcall(setLogo, a) end, "autotradelogo")) end)
end)() -- отдельная функция: у неё свой лимит 200 локальных

-- кнопка «Отклонить» в окне трейда (Text у кнопок остаётся английским даже при переводе игры)
local function findDeclineButton(tg)
    -- только реально видимая кнопка (у MM2 два варианта окна трейда, один из них скрыт); из нескольких — самая крупная
    local best, bestArea = nil, 0
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("GuiButton") and isShown(d) then
            local all = env.TV_btnText(d)
            if all:find("decline") or all:find("отклон") or all:find("отказ") then
                local area = d.AbsoluteSize.X * d.AbsoluteSize.Y
                if area > bestArea then best, bestArea = d, area end
            end
        end
    end
    return best
end
auto.findDecline = findDeclineButton -- нужна обработке пустого трейда, объявленной выше

-- что видит скрипт: окно и первые видимые кнопки (для строки статуса)
function auto.btnDiag(tg)
    local seen = {}
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("GuiButton") and env.TV_vis(d) and #seen < 6 then
            table.insert(seen, (env.TV_btnText(d):gsub("%s+", " ")):sub(1, 22))
        end
    end
    return tg.Name .. ": " .. table.concat(seen, " | ")
end
-- нажать «Отказ»: способы нажатия по очереди, в строке статуса — что происходит
auto.DECL_WAYS = { 4, 3, 5, 1, 2 }
function auto.pressDecline(btn, tg, tries)
    -- «Отказ» можно жать сколько угодно — каждый раз пробуем все способы: по кнопке и по надписи поверх неё
    local targets = { btn }
    local scope = btn.Parent and (btn.Parent.Parent or btn.Parent)
    if scope then
        local p0, sz = btn.AbsolutePosition, btn.AbsoluteSize
        for _, d in ipairs(scope:GetDescendants()) do
            if d:IsA("GuiButton") and d ~= btn and env.TV_vis(d) then
                local c = d.AbsolutePosition + d.AbsoluteSize / 2
                if c.X >= p0.X and c.X <= p0.X + sz.X and c.Y >= p0.Y and c.Y <= p0.Y + sz.Y then table.insert(targets, d) end
            end
        end
    end
    local fired = {}
    for _, t in ipairs(targets) do
        for _, m in ipairs(auto.DECL_WAYS) do
            if m ~= 3 and clickCell(t, tg, m) then fired[m] = true end
        end
    end
    -- мышью — только если ничего другое не сработало и кнопка ещё на экране (иначе щелчок уйдёт в лобби: магазин, коробки)
    if not next(fired) and tries % 2 == 1 then
        task.delay(0.15, function() if env.TV_vis(btn) then clickCell(btn, tg, 3) end end)
        fired[3] = true
    end
    local list = {}
    for m in pairs(fired) do table.insert(list, tostring(m)) end
    table.sort(list)
    X.accLine.Visible = true
    X.accLine.Text = T("declPress"):format(#targets, tries, #list > 0 and table.concat(list, ",") or "—")
end
function auto.noDecline(tg)
    X.accLine.Visible = true
    X.accLine.Text = T("declNoBtn"):format(auto.btnDiag(tg))
end

-- есть ли в предложении соперника нежелательный предмет; возвращает его название
local function findUnwanted(theirs)
    for _, d in ipairs(theirs:GetDescendants()) do
        -- только то, что видно: в окне трейда остаются скрытые ячейки от прошлого трейда
        if d:IsA("TextLabel") and d.Text ~= "" and env.TV_vis(d) then
            local hit = env.TV_isMarked(S.blacklist, d)
            if hit then return hit end
        end
    end
end
auto.findUnwanted = findUnwanted -- нужна автопринятию, которое объявлено выше
-- его оффер: сколько стоят отмеченные «нежелательные» и есть ли хоть один нормальный предмет (с ценой и не отмеченный)
function auto.junkSplit(theirs)
    local junk, good = 0, false
    for _, item in ipairs(theirs:GetDescendants()) do
        if (item:IsA("Frame") or item:IsA("ImageLabel") or item:IsA("ImageButton")) and item.Parent.Name == "Container" and env.TV_vis(item) then
            local price, amount = readItem(item)
            local marked = false
            for _, l in ipairs(item:GetDescendants()) do
                if l:IsA("TextLabel") and l.Text ~= "" and valueMap[norm(l.Text)] then marked = env.TV_isMarked(S.blacklist, l) ~= nil; break end
            end
            if marked then junk += (price or 0) * (amount or 1)
            elseif price and price > 0 then good = true end
        end
    end
    return junk, good
end

-- все нежелательные предметы в оффере соперника (для сообщения в чат)
function auto.allUnwanted(theirs)
    local list, seen = {}, {}
    for _, d in ipairs(theirs:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" and env.TV_vis(d) then
            local hit = env.TV_isMarked(S.blacklist, d)
            if hit and not seen[hit] then seen[hit] = true; table.insert(list, hit) end
        end
    end
    return list
end

-- написать в общий чат от своего имени (новый чат TextChatService или старый)
env.TV_sayChat = function(msg) return auto.sayChat(msg) end
function auto.sayChat(msg)
    local err = "no chat"
    local tcs = game:GetService("TextChatService")
    local tried = {}
    local function try(ch)
        if not (ch and ch:IsA("TextChannel")) or tried[ch] then return false end
        tried[ch] = true
        local ok, e = pcall(function() ch:SendAsync(msg) end)
        if ok then return true end
        err = tostring(e)
        return false
    end
    -- канал, в который пишет строка чата игрока (в MM2 может быть свой), потом общий, потом любой
    local bar = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")
    if bar and try(bar.TargetTextChannel) then return true end
    local chans = tcs:FindFirstChild("TextChannels")
    if chans then
        if try(chans:FindFirstChild("RBXGeneral")) then return true end
        for _, ch in ipairs(chans:GetChildren()) do
            if not ch.Name:find("RBXWhisper") and not ch.Name:find("RBXSystem") and try(ch) then return true end
        end
    end
    local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
    if ev and ev:FindFirstChild("SayMessageRequest") then
        local ok, e = pcall(function() ev.SayMessageRequest:FireServer(msg, "All") end)
        if ok then return true end
        err = tostring(e)
    end
    return false, err
end

-- отказ от трейда с нежелательным предметом: повторяем разными способами нажатия, пока окно не закроется
local function autoDecline(tg, theirs)
    if not S.autoDecline then return false end
    local bad = findUnwanted(theirs)
    if not bad then auto.declMsgSent = false; return false end
    -- есть нормальный предмет — не отказываем: мусор просто не считаем (даём столько, сколько стоит нормальное)
    local _, good = auto.junkSplit(theirs)
    if good then auto.declMsgSent = false; return false end -- убрал ненужное — отсчёт заново, если положит снова
    if os.clock() - (auto.declLast or 0) < 1.5 then return true end
    -- один раз за трейд: сразу, как он положил ненужное, объясняем в чате (до нажатия «Отказ»)
    if not auto.declMsgSent then
        auto.declMsgSent, auto.declMsgAt = true, os.clock()
        if S.declineMsg then auto.sayChat("No thanks, I don't need: " .. table.concat(auto.allUnwanted(theirs), ", ")) end
    end
    -- даём ему 8 с прочитать и убрать предмет; не убрал — отказ
    local wait = 8 - (os.clock() - (auto.declMsgAt or 0))
    if wait > 0 then
        sugLine.Visible = true
        hideHighlights()
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.bad), T("declWait"):format(bad, math.ceil(wait)))
        return true
    end
    if (auto.declTries or 0) >= 9 then return true end -- 9 попыток без результата — больше не долбим
    local btn = findDeclineButton(tg)
    if not btn then
        if not auto.declined then notify(T("declineFail")); auto.declined = true end
        auto.noDecline(tg)
        return true
    end
    auto.declLast = os.clock()
    auto.declTries = (auto.declTries or 0) + 1
    if auto.declTries == 1 then auto.pendingBlock = auto.partner end -- в блок — когда трейд реально закроется
    auto.pressDecline(btn, tg, auto.declTries)
    sugLine.Visible = true
    sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.bad), T("declTry"):format(bad, auto.declTries))
    if not auto.declined then notify(T("declined"):format(bad)); auto.declined = true end
    return true
end

-- ник соперника: в окне трейда подпись вида «(Nick)»
function auto.partnerName(tg)
    for _, d in ipairs(tg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible then
            local n = d.Text:match("^%s*%((.-)%)%s*$")
            if n and #n >= 3 and not n:find(" ") then return n end
        end
    end
end

-- что лежит в моём оффере: { key = {cells = {...}, count = n, name = ...} }
function auto.readOffer(offer)
    local res = {}
    for _, item in ipairs(offer:GetDescendants()) do
        if (item:IsA("Frame") or item:IsA("ImageLabel") or item:IsA("ImageButton"))
           and item.Parent.Name == "Container" and env.TV_vis(item) then
            local price, amount, name = readItem(item)
            if price and name then
                local key = norm(name)
                local e = res[key] or { cells = {}, count = 0, name = name, price = price }
                e.count += amount
                table.insert(e.cells, item)
                res[key] = e
            end
        end
    end
    return res
end

-- свежая видимая ячейка предмета в моём оффере: после каждого нажатия MM2 перерисовывает стопку,
-- старая ячейка пропадает — поэтому перед каждым кликом ищем заново
function auto.myCell(mine, key)
    local e = auto.readOffer(mine)[key]
    for _, c in ipairs(e and e.cells or {}) do
        if c.Parent and isShown(c) then return c end
    end
end

-- просьба соперника из чата: привести мой оффер к списку предметов, которые он просит
function auto.handlePartnerRequest(tg, mine, theirs, my, th)
    local req = auto.partnerReq
    -- заявки работают сами по себе; «Выполнять просьбы из чата» отключает только просьбы из чата
    if not (req and (S.chatRequests or req.kind == "order") and os.clock() - req.t < 90) then return false end
    if req.partner ~= auto.partner then return false end
    -- просьба уже выполнена: больше ничего не трогаем. Поменял оффер сам — просьбу забываем.
    if req.applied then
        if auto.busy then return true end
        if req.kind == "order" then
            -- заявка: оффер держим ровно таким, как в варианте; сбился — кладём заново (не больше 3 раз)
            local have, want, same = auto.readOffer(mine), {}, true
            for _, it in ipairs(req.items) do want[it.key] = (want[it.key] or 0) + it.count end
            for k, n in pairs(want) do if not (have[k] and have[k].count == n) then same = false end end
            for k in pairs(have) do if not want[k] then same = false end end
            if not same and (req.redo or 0) < 3 and os.clock() - (req.doneAt or 0) > 2.5 then
                req.redo, req.applied, auto.reqDoneId = (req.redo or 0) + 1, false, nil
            end
            sugLine.Visible = true
            if same then
                sugText.Text = ('<font color="%s">%s</font> · %s'):format(hex(C.good), T("reqDone"), req.orderName or "")
                auto.fillTh, auto.fillMy = th, my -- для автопринятия: это и есть договорённость
            end
            return true
        end
        if req.myAfter == nil then req.myAfter = my end
        if math.abs(my - req.myAfter) > 0.01 then auto.partnerReq = nil; return false end
        sugLine.Visible = true
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.good), T("reqDone"))
        auto.fillTh, auto.fillMy = th, my -- для автопринятия: это и есть договорённость
        return true
    end
    sugLine.Visible = true
    local have = auto.readOffer(mine)
    local isOrder = req.kind == "order"
    local kind = isOrder and "exact" or (req.kind or "exact")
    -- exact: ровно этот список (лишнее убрать); total: довести до количества; extra: добавить сверху
    local want, wantList = {}, {}
    for _, it in ipairs(req.items) do
        local base = kind == "extra" and (have[it.key] and have[it.key].count or 0) or 0
        want[it.key] = math.max(want[it.key] or 0, base) + it.count
        table.insert(wantList, (kind == "extra" and "+" or "") .. it.name .. (it.count > 1 and (" x" .. it.count) or ""))
    end
    local listText = table.concat(wantList, ", ")
    -- сколько я буду отдавать после выполнения просьбы — не больше, чем даёт он
    local after = 0
    for key, e in pairs(have) do
        local n = e.count
        if want[key] then n = kind == "exact" and want[key] or math.max(n, want[key]) elseif kind == "exact" then n = 0 end
        after += n * e.price
    end
    for key, n in pairs(want) do
        if not have[key] then after += n * (valueMap[key] or 0) end
    end
    if not isOrder and after > th + math.max(1, th * 0.02) then -- просит больше, чем даёт: не делаем
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.bad), T("reqTooMuch"):format(listText))
        return true
    end
    local adds, removes, addText, remText = {}, {}, {}, {}
    for key, n in pairs(want) do
        local diff = n - (have[key] and have[key].count or 0)
        if diff > 0 then
            table.insert(adds, { key = key, count = diff })
            table.insert(addText, ((env.TV_names or {})[key] or key) .. (diff > 1 and (" x" .. diff) or ""))
        end
    end
    for key, e in pairs(have) do
        local extra = kind == "exact" and e.count - (want[key] or 0) or 0 -- убираем только при «только / just»
        if extra > 0 then
            table.insert(removes, { key = key, count = extra })
            table.insert(remText, e.name .. (extra > 1 and (" x" .. extra) or ""))
        end
    end
    if #adds == 0 and #removes == 0 then
        req.applied, req.myAfter = true, my -- уже совпадает с просьбой
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.good), T("reqDone"))
        auto.fillTh, auto.fillMy = th, my
        return true
    end
    local parts = { isOrder and T("ordApplied"):format(listText, req.orderName or "?") or T("reqPlan"):format(listText) }
    if #addText > 0 then table.insert(parts, T("reqAdd"):format(table.concat(addText, ", "))) end
    if #remText > 0 then table.insert(parts, T("reqRemove"):format(table.concat(remText, ", "))) end
    sugText.Text = table.concat(parts, " · ")
    if not (S.autoAdd and not auto.busy and auto.reqDoneId ~= req.id) then return true end

    auto.busy, auto.reqDoneId = true, req.id
    req.applied, req.myAfter, req.doneAt = true, nil, os.clock() -- снимок оффера сделаем, когда скрипт закончит
    sugText.Text = T("reqDoing"):format(listText) .. (isOrder and (" · " .. (req.orderName or "")) or "")
    task.spawn(function()
        pcall(function()
            -- сначала убираем лишнее (клик по предмету в своём оффере убирает его)
            for _, rm in ipairs(removes) do
                for _ = 1, rm.count do
                    local cell = auto.myCell(mine, rm.key)
                    if not cell then break end
                    clickCell(cell, tg)
                    task.wait(0.35)
                end
            end
            -- потом докладываем недостающее из инвентаря
            local inv = scanInventory(tg, mine, theirs)
            local anyHidden = false
            for _, a in ipairs(adds) do
                for _, it in ipairs(inv) do
                    if norm(it.name) == a.key and not isShown(it.frame) then anyHidden = true end
                end
            end
            if anyHidden then
                local addBtn = findAddButton(tg)
                if addBtn then clickCell(addBtn, tg); task.wait(0.8) end
            end
            for _, a in ipairs(adds) do
                local function find()
                    for _, it in ipairs(scanInventory(tg, mine, theirs)) do
                        if norm(it.name) == a.key and it.frame.Parent and isShown(it.frame) then return it end
                    end
                end
                -- нет на открытой вкладке (например, открыты «Питомцы») — смотрим «Оружие», потом «Питомцы»
                local found = find()
                if not found and auto.openTab(tg, "weapons") then task.wait(0.6); found = find() end
                if not found and auto.openTab(tg, "pets") then task.wait(0.6); found = find() end
                for _ = 1, math.min(a.count, found and found.amount or 0) do
                    local it = find()
                    if not it then break end
                    clickCell(it.frame, tg)
                    task.wait(0.35)
                end
            end
        end)
        auto.busy = false
    end)
    return true
end

-- «Заявки»: если соперник кладёт предмет, на который есть заявка, кладём один из её включённых вариантов
auto.ord = {}
-- в игре нет приписок сайта: «Latte (Gun)» там просто «Latte» — ключ без скобок
function auto.gameKey(name, key)
    local base = norm(((name or ""):gsub("%s*%b()$", "")))
    if base ~= "" and base ~= key then return base end
    return key
end
-- true — точно подходит, "maybe" — по названию да, а нож это или пистолет — не понять
function auto.orderMatches(o, their)
    if their[o.target] then return true end
    local e = their[auto.gameKey(o.name, o.target)]
    if not e then return false end
    local suf = ((o.name or ""):match("%((%a+)%)%s*$") or ""):lower()
    if suf ~= "gun" and suf ~= "knife" then return true end
    -- тип каждой ячейки; две ячейки с одним названием, но разными картинками: если одну знаем, вторая — другая
    local kinds, imgs, known, diags, taught = {}, {}, false, {}, {}
    for i, c in ipairs(e.cells) do
        kinds[i] = env.TV_cellKind(c)
        taught[i] = env.TV_kindTaught
        local fImg = env.TV_freq(c)
        local own = {}
        for _, d in ipairs(env.TV_cellImgs(c)) do if (fImg[d] or 0) <= 6 then table.insert(own, d) end end
        imgs[i] = table.concat(own, ",")
        table.insert(diags, env.TV_kindDiag)
    end
    for i in ipairs(e.cells) do
        if not taught[i] then
            for j in ipairs(e.cells) do
                -- те же названия, другие картинки: если про одну ты показал, вторая — другой вид
                if taught[j] and imgs[j] ~= imgs[i] then kinds[i] = kinds[j] == "gun" and "knife" or "gun"; break end
                if not kinds[i] and kinds[j] and imgs[j] ~= imgs[i] then kinds[i] = kinds[j] == "gun" and "knife" or "gun"; break end
            end
        end
    end
    X.kindLine.Text = table.concat(diags, "\n")
    X.kindLine.Visible = true
    -- спросить про первую ячейку, которую ты ещё не показывал
    for i, c in ipairs(e.cells) do
        if not taught[i] and imgs[i] ~= "" then
            auto.kindAskImgs = imgs[i]
            X.kindAskText.Text = T("kindAsk"):format(e.name, kinds[i] == "gun" and T("kindGun") or kinds[i] == "knife" and T("kindKnife") or "?")
            X.kindBtns.knife.Text, X.kindBtns.gun.Text = T("kindBtnKnife"), T("kindBtnGun")
            X.kindAsk.Visible = true
            break
        end
    end
    for i in ipairs(e.cells) do
        if kinds[i] then
            known = true
            if kinds[i] == suf then return true end
        end
    end
    return (not known) and "maybe" or false
end
function auto.handleOrders(theirs)
    auto.ordProfit, auto.ordProfitName = nil, nil
    if not (S.enabled and S.ordersOn) then return end
    local their = auto.readOffer(theirs)
    -- все заявки, чьи предметы лежат у него (нож и пистолет Latte — две разные заявки)
    local matched, unsure = {}, false
    auto.ordProfit, auto.ordProfitName = nil, nil
    for _, o in ipairs(S.orders or {}) do
        -- старая «своя прибыль за предмет» — теперь это обычный вариант заявки
        if (o.profit or 0) > 0 then
            o.offers = o.offers or {}
            table.insert(o.offers, 1, { on = true, profit = o.profit })
            o.profit = nil
            saveSettings()
        end
        local m = auto.orderMatches(o, their)
        if m then
            local en = {}
            for i, v in ipairs(o.offers or {}) do if v.on and (#(v.items or {}) > 0 or (v.profit or 0) > 0) then table.insert(en, i) end end
            if #en > 0 then
                if m == true then table.insert(matched, { o = o, en = en }) else unsure = true end
            end
        end
    end
    -- нож/пистолет пока не понятен — ничего не кладём (лучше, чем не то)
    auto.ordUnsure = unsure and (env.TV_kindDiag or "?") or nil

    local st = auto.ord
    st.picks, st.lost = st.picks or {}, st.lost or {}
    local now = {}
    for _, m in ipairs(matched) do now[m.o.target] = true end
    -- заявка пропала из его оффера: запоминаем момент (вернёт быстро — сменим вариант)
    for target in pairs(st.picks) do
        if not now[target] and not st.lost[target] then st.lost[target] = os.clock() end
    end
    if #matched == 0 or auto.ordUnsure then
        if auto.partnerReq and auto.partnerReq.kind == "order" then
            -- заявка была выполнена, а теперь не подходит (он убрал/сменил предмет) — её предметы надо забрать
            if auto.partnerReq.applied then auto.ordCleanup = auto.partnerReq.items end
            auto.partnerReq = nil
        end
        st.sig = nil
        return
    end
    auto.ordCleanup = nil
    -- вариант для каждой заявки
    local sigParts = {}
    for _, m in ipairs(matched) do
        local o, en, idx = m.o, m.en, st.picks[m.o.target]
        local lostAt = st.lost[o.target]
        if not idx or not table.find(en, idx) then
            idx = en[math.random(1, #en)]                                  -- новая заявка: вариант наугад из включённых
        elseif lostAt and os.clock() - lostAt < 8 and #en > 1 then
            local others = {}                                              -- убрал и быстро вернул: другой вариант
            for _, i in ipairs(en) do if i ~= idx then table.insert(others, i) end end
            idx = others[math.random(1, #others)]
        end
        st.picks[o.target], st.lost[o.target], m.idx = idx, nil, idx
        table.insert(sigParts, o.target .. ":" .. idx)
    end
    table.sort(sigParts)
    local sig = table.concat(sigParts, "|")
    -- выпал вариант «% прибыли»: автооффер наберёт с этим процентом (самый большой из выпавших)
    for _, m in ipairs(matched) do
        local pf = m.o.offers[m.idx].profit
        if pf and pf > 0 and (not auto.ordProfit or pf > auto.ordProfit) then auto.ordProfit, auto.ordProfitName = pf, m.o.name end
    end
    if sig == st.sig then return end
    st.sig = sig
    -- складываем варианты всех заявок; в трейде 4 ячейки — больше 4 разных предметов: оставляем 4 самых дорогих
    local byKey, names = {}, {}
    for _, m in ipairs(matched) do
        for _, it in ipairs(m.o.offers[m.idx].items or {}) do
            local gk = auto.gameKey(it.name, it.key)
            if not valueMap[gk] then gk = it.key end
            local e = byKey[gk]
            if not e then
                e = { key = gk, name = it.name, count = 0, price = valueMap[it.key] or valueMap[gk] or 0 }
                byKey[gk] = e
            end
            e.count += it.count
        end
        local seenKind
        local cellsOf = their[m.o.target] or their[auto.gameKey(m.o.name, m.o.target)] or { cells = {} }
        for _, c in ipairs(cellsOf.cells) do seenKind = seenKind or env.TV_cellKind(c) end
        table.insert(names, m.o.name .. " [" .. (seenKind == "gun" and T("kindGun") or seenKind == "knife" and T("kindKnife") or "?") .. "]")
    end
    local items = {}
    for _, e in pairs(byKey) do table.insert(items, e) end
    table.sort(items, function(a, b) return a.price * a.count > b.price * b.count end)
    while #items > 4 do table.remove(items) end
    if #items == 0 then
        -- выпали только варианты «% прибыли»: класть нечего, набирает автооффер
        if auto.partnerReq and auto.partnerReq.kind == "order" then auto.partnerReq = nil end
        return
    end
    auto.reqSeq = (auto.reqSeq or 0) + 1
    auto.partnerReq = { partner = auto.partner, items = items, kind = "order", t = os.clock() + 1e6, id = auto.reqSeq,
        orderName = table.concat(names, " + ") }
end

for kind, b in pairs(X.kindBtns) do
    on(b.Activated, function()
        if not auto.kindAskImgs then return end
        S.imgKinds = S.imgKinds or {}
        for d in auto.kindAskImgs:gmatch("%d+") do S.imgKinds[d] = kind end
        saveSettings()
        auto.kindAskImgs = nil
        X.kindAsk.Visible = false
        auto.ord.sig = nil -- пересобрать заявки с новым знанием
    end)
end

-- он кладёт только мелочь (винтажи, легендарки, редкие, необычные, обычные) — в ответ ровно 1 самый дешёвый годли,
-- и только если он даёт хотя бы вдвое больше его цены
auto.LOW_CATS = { "vintages", "legendaries", "rares", "uncommons", "commons" }
auto.HIGH_CATS = { "godlies", "ancients", "chromas", "uniques", "sets" }
function auto.catSets()
    if auto.catSrc == itemsByCat then return auto.lowSet, auto.godSet end
    local low, high, god = {}, {}, {}
    -- «Arctic (Knife)» на сайте = «Arctic» в игре: считаем и название без скобок
    local function put(set, it)
        set[it.key] = true
        set[norm((it.name:gsub("%s*%b()$", "")))] = true
    end
    for _, c in ipairs(auto.LOW_CATS) do for _, it in ipairs(itemsByCat[c] or {}) do put(low, it) end end
    for _, c in ipairs(auto.HIGH_CATS) do for _, it in ipairs(itemsByCat[c] or {}) do put(high, it) end end
    for _, it in ipairs(itemsByCat.godlies or {}) do if not low[it.key] then god[it.key] = true end end
    for k in pairs(high) do low[k] = nil end -- одинаковые названия (Laser) считаем дорогими
    auto.catSrc, auto.lowSet, auto.godSet = itemsByCat, low, god
    return low, god
end
function auto.handleCheap(tg, mine, theirs, my, th)
    if not (S.cheapGodly and th > 0) then return false end
    if (auto.partnerReq and auto.partnerReq.kind == "order") or auto.ordProfit then return false end -- есть заявка — она главнее
    local low, god = auto.catSets()
    local their = auto.readOffer(theirs)
    local any = false
    for key in pairs(their) do
        if not low[key] then return false end
        any = true
    end
    if not any then return false end
    -- самый дешёвый годли из моего инвентаря (без «Не отдавать»)
    local g
    for _, it in ipairs(scanInventory(tg, mine, theirs)) do
        if god[norm(it.name)] and (not g or it.price < g.price) then g = it end
    end
    if not g then
        -- в инвентаре годли не осталось, но один уже лежит в моём оффере — тоже годится
        for key, e in pairs(auto.readOffer(mine)) do if god[key] then g = { name = e.name, price = e.price, frame = e.cells[1] } end end
    end
    if not g then return false end
    sugLine.Visible = true
    hideHighlights()
    local mineNow = auto.readOffer(mine)
    -- в моём оффере уже лежит ровно один годли (из инвентаря он пропал — не ищем «новый» самый дешёвый)
    local only, cnt = nil, 0
    for key, e in pairs(mineNow) do cnt += 1; only = { key = key, e = e } end
    if cnt == 1 and only.e.count == 1 and god[only.key] and only.e.price * 2 <= th then
        g = { name = only.e.name, price = only.e.price, frame = only.e.cells[1] }
    end
    local gKey = norm(g.name)
    if th < g.price * 2 then
        sugText.Text = T("cheapNeed"):format(g.name, fmt(g.price * 2), fmt(th))
        return true
    end
    -- уже ровно один этот годли — готово (автопринятие дальше по обычным правилам)
    local onlyG = mineNow[gKey] and mineNow[gKey].count == 1
    for key in pairs(mineNow) do if key ~= gKey then onlyG = false end end
    if onlyG then
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.good), T("cheapOk"):format(g.name))
        auto.fillTh, auto.fillMy = th, my
        return true
    end
    sugText.Text = T("cheapDoing"):format(g.name)
    if not S.autoAdd or auto.busy then return true end
    if th ~= auto.lastTh then auto.lastTh, auto.stableSince = th, os.clock() end
    if os.clock() - (auto.stableSince or 0) < 1.5 or os.clock() - (auto.cheapLast or 0) < 3 then return true end
    auto.busy, auto.cheapLast = true, os.clock()
    task.spawn(function()
        pcall(function()
            -- убираем всё, кроме одного этого годли
            for _ = 1, 40 do
                local cell
                for key, e in pairs(auto.readOffer(mine)) do
                    if key ~= gKey or e.count > 1 then cell = auto.myCell(mine, key); if cell then break end end
                end
                if not cell then break end
                clickCell(cell, tg)
                task.wait(0.35)
            end
            -- кладём его, если ещё нет
            if not auto.readOffer(mine)[gKey] then
                if not isShown(g.frame) then
                    local addBtn = findAddButton(tg)
                    if addBtn then clickCell(addBtn, tg); task.wait(0.8) end
                    for _, it in ipairs(scanInventory(tg, mine, theirs)) do
                        if norm(it.name) == gKey then g = it; break end
                    end
                end
                if g.frame.Parent and isShown(g.frame) then clickCell(g.frame, tg); task.wait(0.35) end
                task.wait(0.3)
                auto.closePicker(tg)
            end
        end)
        auto.busy = false
    end)
    return true
end

-- трейд «завис»: 20 с ничего не меняется (он что-то положил, скрипт ответил, а он молчит) — отказ, чтобы не терять время
function auto.handleIdle(tg, mine, theirs, my, th)
    if not S.idleDecline or th <= 0 then auto.idleSig = nil; return false end
    local parts = { tostring(my), tostring(th) }
    for k, e in pairs(auto.readOffer(mine)) do table.insert(parts, "m" .. k .. e.count) end
    for k, e in pairs(auto.readOffer(theirs)) do table.insert(parts, "t" .. k .. e.count) end
    table.sort(parts)
    local sig = table.concat(parts, "|")
    if sig ~= auto.idleSig or auto.busy then
        auto.idleSig, auto.idleSince, auto.idleTries = sig, os.clock(), 0
        return false
    end
    local left = 20 - (os.clock() - auto.idleSince)
    if left > 10 then return false end -- последние 10 с показываем отсчёт
    sugLine.Visible = true
    hideHighlights()
    if left > 0 then sugText.Text = T("idleWait"):format(math.ceil(left)); return true end
    if os.clock() - (auto.declLast or 0) < 1.5 or (auto.idleTries or 0) >= 9 then return true end
    local btn = auto.findDecline(tg)
    if not btn then auto.noDecline(tg); return true end
    auto.declLast = os.clock()
    auto.idleTries = (auto.idleTries or 0) + 1
    auto.pressDecline(btn, tg, auto.idleTries)
    return true
end

-- я отдаю больше цели: убрать из своего оффера как можно меньше, но не меньше лишнего
-- (последний предмет целиком не убираем — пустой оффер он всё равно не примет)
function auto.removeExcess(tg, mine, excess, th, my)
    if th ~= auto.lastTh then auto.lastTh, auto.stableSince = th, os.clock() end
    if auto.busy or os.clock() - (auto.stableSince or 0) < 1.5 then return false end
    local sig = th .. ":" .. my
    -- та же ситуация: повтор через 3 с, до 3 раз (ячейки могли перерисоваться)
    if auto.remFor == sig and (os.clock() - (auto.remAt or 0) < 3 or (auto.remTries or 0) >= 3) then return false end
    if auto.remFor ~= sig then auto.remTries = 0 end
    local units, total = {}, 0
    for _, e in pairs(auto.readOffer(mine)) do total += e.price * e.count; table.insert(units, e) end
    -- вариант 1: k штук одного предмета
    local best, bestSum
    for _, e in ipairs(units) do
        local k = math.ceil(excess / e.price - 1e-9)
        if k <= e.count and (not bestSum or k * e.price < bestSum) then best, bestSum = { [e] = k }, k * e.price end
    end
    -- вариант 2: от дорогих, не перебирая, и один дешёвый сверху
    table.sort(units, function(a, b) return a.price > b.price end)
    local plan, sum = {}, 0
    for _, e in ipairs(units) do
        local k = math.max(0, math.min(e.count, math.floor((excess - sum) / e.price + 1e-9)))
        if k > 0 then plan[e] = k; sum += k * e.price end
    end
    if sum < excess - 1e-9 then
        for i = #units, 1, -1 do
            local e = units[i]
            if (plan[e] or 0) < e.count then plan[e] = (plan[e] or 0) + 1; sum += e.price; break end
        end
    end
    if sum >= excess - 1e-9 and (not bestSum or sum < bestSum) then best, bestSum = plan, sum end
    if not best or bestSum >= total - 1e-9 then
        -- точно не убрать — убираем самые дорогие, пока не уложимся, но хотя бы один предмет оставляем
        best, bestSum = {}, 0
        local left = 0
        for _, e in ipairs(units) do left += e.count end
        for _, e in ipairs(units) do
            for _ = 1, e.count do
                if bestSum >= excess - 1e-9 or left <= 1 then break end
                best[e] = (best[e] or 0) + 1
                bestSum += e.price
                left -= 1
            end
        end
        if bestSum <= 0 then return false end
    end
    auto.remFor, auto.busy, auto.remAt = sig, true, os.clock()
    auto.remTries = (auto.remTries or 0) + 1
    task.spawn(function()
        pcall(function()
            for e, k in pairs(best) do
                local key = norm(e.name)
                for _ = 1, k do
                    if not (S.enabled and S.autoOffer and S.autoAdd) then break end
                    -- после каждого нажатия стопка меняется — берём ячейку заново
                    local cell = auto.myCell(mine, key)
                    if not cell then break end
                    clickCell(cell, tg)
                    task.wait(0.35)
                end
            end
        end)
        auto.busy = false
    end)
    return true
end

local function updateAutoOffer(tg, mine, theirs, my, th)
    auto.handleOrders(theirs)
    -- заявка больше не подходит: убираем из своего оффера то, что она положила
    if auto.ordCleanup and not auto.busy then
        local items = auto.ordCleanup
        auto.ordCleanup, auto.busy = nil, true
        sugLine.Visible = true
        sugText.Text = T("ordGone")
        hideHighlights()
        task.spawn(function()
            pcall(function()
                for _, it in ipairs(items) do
                    for _ = 1, it.count do
                        local cell = auto.myCell(mine, it.key)
                        if not cell then break end
                        clickCell(cell, tg)
                        task.wait(0.35)
                    end
                end
            end)
            auto.busy = false
        end)
        return
    end
    if auto.ordUnsure then
        sugLine.Visible = true
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.fair), T("ordUnsure"):format(auto.ordUnsure))
        hideHighlights()
        return
    end
    if auto.handlePartnerRequest(tg, mine, theirs, my, th) then hideHighlights(); return end
    if S.autoOffer and auto.handleCheap(tg, mine, theirs, my, th) then return end
    if not S.autoOffer then sugLine.Visible = false; hideHighlights(); return end
    sugLine.Visible = true
    local pctT = auto.ordProfit or env.TV_pct(th) -- своя прибыль из заявки за его предмет — важнее общей (иначе ступень по цене его оффера)
    local tgt = ("+%d%%"):format(pctT) .. (auto.ordProfit and T("ordProfitTag") or "")
    if th <= 0 then sugText.Text = T("sugWait"):format(tgt); hideHighlights(); return end

    local maxMine = th / (1 + pctT / 100)  -- столько можно отдать, чтобы остаться в цели
    local need = maxMine - my
    -- оффер уже добит сверх цели самим скриптом — это и есть результат, «убери» не пишем
    if S.fillOver and auto.fillTh == th and auto.fillMy and my <= auto.fillMy + 0.5 and my >= maxMine then
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.good), T("sugOk"):format(tgt .. T("overTag")))
        hideHighlights(); return
    end
    local strict = S.tiersOn and not auto.ordProfit -- ступени: не отдаём больше, чем позволяет ступень
    if need < -(strict and 0.05 or math.max(1, maxMine * 0.02)) then
        sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.bad), T("sugRemove"):format(tgt, fmt(-need)))
        if S.autoAdd and (auto.busy or auto.removeExcess(tg, mine, -need, th, my)) then
            sugText.Text = T("sugRemoving"):format(tgt, fmt(-need))
        end
        hideHighlights(); return
    end

    local items = scanInventory(tg, mine, theirs)
    local avoid = {}
    for k in pairs(auto.readOffer(theirs)) do avoid[k] = true end
    for k in pairs(auto.rerollAvoid or {}) do avoid[k] = true end -- не то, что ему уже не понравилось
    local picks, sum = pickItems(items, need, avoid)
    -- допуск ±1%: если с ослабленной на 1% целью можно добить точнее, берём этот вариант
    local tolUsed = false
    if S.tolerance and not strict then
        local needTol = th / (1 + (pctT - 1) / 100) - my
        local picks2, sum2 = pickItems(items, needTol, avoid)
        if sum2 > sum then picks, sum, need, tolUsed = picks2, sum2, needTol, true end
    end
    if tolUsed then tgt = tgt .. " (±1%)" end

    -- добивать сверх цели: точно не попасть, а не хватает хотя бы 1 — кладём самый дешёвый подходящий предмет,
    -- если трейд от этого не уходит в минус (отдаёшь не больше, чем получаешь)
    if S.fillOver and need - sum >= 1 then
        local rest = need - sum
        local used = {}
        for _, pk in ipairs(picks) do used[pk.item] = pk.count end
        local best
        for _, it in ipairs(items) do
            if (used[it] or 0) < it.amount and it.price >= rest and my + sum + it.price <= (strict and maxMine or th) then
                if not best or it.price < best.price then best = it end
            end
        end
        if best then
            local merged = false
            for _, pk in ipairs(picks) do
                if pk.item == best then pk.count += 1; merged = true end
            end
            if not merged then table.insert(picks, { item = best, count = 1 }) end
            sum += best.price
            need = sum
            tgt = tgt .. T("overTag")
            -- автопринятию: в этом трейде прибыль будет ниже цели — и это нормально
            auto.fillTh, auto.fillMy = th, my + sum
        end
    end

    if #picks == 0 then
        if need <= math.max(1, maxMine * 0.05) then
            sugText.Text = ('<font color="%s">%s</font>'):format(hex(C.good), T("sugOk"):format(tgt))
        else
            sugText.Text = T("sugNone"):format(tgt, fmt(need))
        end
        hideHighlights(); return
    end

    local names = {}
    for i, pk in ipairs(picks) do
        if i <= 4 then table.insert(names, pk.item.name .. (pk.count > 1 and (" x" .. pk.count) or "")) end
    end
    if #picks > 4 then table.insert(names, "...") end
    local listText = table.concat(names, ", ")
    sugText.Text = T("sugAdd"):format(tgt, fmt(sum), listText)

    -- авто-добавление: когда соперник 1.5 с ничего не меняет и вариант однозначный
    if S.autoAdd then
        if th ~= auto.lastTh then auto.lastTh, auto.stableSince, auto.addTries = th, os.clock(), 0 end
        if auto.busy then
            sugText.Text = T("sugAuto"):format(tgt, fmt(sum), listText)
            hideHighlights(); return
        end
        -- попытка не удалась (ячейки перерисовались и т.п.) — через 3 с пробуем снова, до 3 раз
        local retry = auto.doneFor == th and os.clock() - (auto.doneAt or 0) > 3 and (auto.addTries or 0) < 3
        if (auto.doneFor ~= th or retry) and os.clock() - auto.stableSince > 1.5 then
            auto.busy, auto.doneFor, auto.doneAt = true, th, os.clock()
            auto.addTries = (auto.addTries or 0) + 1
            sugText.Text = T("sugAuto"):format(tgt, fmt(sum), listText)
            hideHighlights()
            task.spawn(function()
              pcall(function()
                -- инвентарь закрыт? открываем «Добавить предметы»
                local anyHidden = false
                for _, pk in ipairs(picks) do if not isShown(pk.item.frame) then anyHidden = true end end
                if anyHidden then
                    local addBtn = findAddButton(tg)
                    if addBtn then clickCell(addBtn, tg); task.wait(0.8) end
                    -- теперь инвентарь на экране: набираем заново только из того, что реально есть
                    local again = pickItems(scanInventory(tg, mine, theirs), need, avoid)
                    if #again > 0 then picks = again end
                end
                for _, pk in ipairs(picks) do
                    local key = norm(pk.item.name)
                    for _ = 1, pk.count do
                        if not (S.enabled and S.autoOffer and S.autoAdd) then break end
                        -- ячейка могла перерисоваться — ищем свежую по названию
                        local f = pk.item.frame
                        if not (f.Parent and isShown(f)) then
                            f = nil
                            for _, it in ipairs(scanInventory(tg, mine, theirs)) do
                                if norm(it.name) == key and isShown(it.frame) then f = it.frame; break end
                            end
                        end
                        if not f then break end
                        clickCell(f, tg)
                        task.wait(0.35)
                    end
                end
                task.wait(0.3)
                auto.closePicker(tg)
              end)
                auto.busy = false
            end)
            return
        end
    end

    if not S.highlight then hideHighlights(); return end
    hlGui.IgnoreGuiInset = tg.IgnoreGuiInset
    local a = accent()
    local pulse = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(os.clock() * 5))
    local shownCount = 0
    for _, pk in ipairs(picks) do
        local f = pk.item.frame
        if isShown(f) then -- скрытые ячейки не обводим, иначе рамки встают криво
            shownCount += 1
            local h = getHighlight(shownCount)
            h.frame.Position = UDim2.fromOffset(f.AbsolutePosition.X, f.AbsolutePosition.Y)
            h.frame.Size = UDim2.fromOffset(f.AbsoluteSize.X, f.AbsoluteSize.Y)
            h.stroke.Color, h.stroke.Transparency = a, pulse
            h.badge.BackgroundColor3 = a
            h.badge.Text = "x" .. pk.count
            h.frame.Visible = true
        end
    end
    hideHighlights(shownCount + 1)
end

local function setNote(note, unk)
    note.Visible = unk > 0
    note.Text = unk > 0 and T("noPrice"):format(unk) or ""
end

------------------------------------------------------------------
-- Запуск и цикл обновления
------------------------------------------------------------------
task.spawn(function()
    if loadValues() then notify(T("loaded"):format(valueCount)) else notify(T("failed")) end
end)

-- кнопка ⚙️ всегда в пределах экрана (место могло сохраниться с другого размера окна)
local function clampGear()
    local abs, p = ui.AbsoluteSize, gear.AbsolutePosition
    if abs.X < 50 then return end
    local bad = S.iconX ~= S.iconX or S.iconY ~= S.iconY -- NaN
        or p.X < 0 or p.Y < 0 or p.X > abs.X - 40 or p.Y > abs.Y - 40
    if bad then
        S.iconX, S.iconY = 0.02, 0.35
        gear.AnchorPoint, gear.Position = Vector2.zero, UDim2.fromScale(S.iconX, S.iconY)
        saveSettings()
    end
end

local acc, wasOpen, errShown = 0, false, false
local function tick()
    -- сторож: «занят» дольше 10 с — значит, что-то оборвалось; снимаем, чтобы скрипт не завис
    if auto.busy then
        auto.busySince = auto.busySince or os.clock()
        if os.clock() - auto.busySince > 10 then auto.busy, auto.busySince = false, nil end
    else
        auto.busySince = nil
    end
    auto.tryAcceptRequest()
    local tg = S.enabled and findTradeGui() or nil
    if X.chatFeed then
        X.chatFeed.Visible = S.enabled and S.chatAds and (not tg or S.chatInTrade)
    end
    if not tg then
        -- трейд закрылся: обе стороны недавно приняли и отказ не жали — значит, состоялся; пишем в историю
        local sn = auto.lastSnap
        auto.lastSnap = nil
        -- состоялся: был второй этап («Вы уверены?»), после него я принял, отказ не жали, и обе стороны что-то дают
        if sn and sn.stage2At and sn.meAt and sn.meAt > sn.stage2At and os.clock() - sn.meAt < 6
           and (auto.declTries or 0) == 0 and (auto.idleTries or 0) == 0 and ((sn.my or 0) > 0 or (sn.th or 0) > 0) then
            local function list(o)
                local out = {}
                for _, e in pairs(o or {}) do table.insert(out, { e.name, e.count, e.price }) end
                table.sort(out, function(a, b) return a[2] * a[3] > b[2] * b[3] end)
                return out
            end
            -- пока только «на проверке»: в историю попадёт, когда инвентарь покажет, что отданное ушло / полученное пришло
            local pre = {}
            for k, e in pairs(S.invItems or {}) do pre[k] = e[2] end
            S.tradePending = S.tradePending or {}
            table.insert(S.tradePending, { t = os.time(), p = sn.partner or "?", my = sn.my or 0, th = sn.th or 0,
                gave = list(sn.gave), got = list(sn.got), pre = pre })
            while #S.tradePending > 10 do table.remove(S.tradePending, 1) end
            saveSettings()
        end
        clampGear()
        hud.Visible, wasOpen, gear.Visible = false, false, true
        hideHighlights()
        auto.lastTh, auto.doneFor, auto.declined = -1, -1, false
        auto.declTries, auto.declLast, auto.declMsgSent = 0, 0, false
        auto.emptySince, auto.hadTheirs, auto.nudged, auto.nudgeDone = nil, false, false, nil
        auto.junkSig, auto.junkSince = nil, nil
        auto.giftTries, auto.giftLast = 0, 0
        auto.ord, auto.remFor, auto.idleSig, auto.kindNotified, auto.ordProfit, auto.ordCleanup = {}, nil, nil, nil, nil, nil
        auto.tabEmptyDone, auto.addTries = nil, 0
        auto.theirHist, auto.lastMine, auto.rerollAvoid, auto.reroll = nil, nil, nil, false
        env.TV_inTrade = false
        if env.TV_out and env.TV_out.tradeAt then env.TV_out = nil end
        -- трейд закрылся после нашего отказа — теперь этот человек в блоке на 80 секунд (на следующие трейды)
        if auto.pendingBlock then auto.block(auto.pendingBlock); auto.pendingBlock = nil end
        auto.accSig, auto.accTries, auto.accDone = "", 0, false
        auto.fillTh, auto.fillMy = nil, nil
        auto.partner, auto.partnerReq = nil, nil
        X.accLine.Visible = false
        X.kindLine.Visible = false
        X.kindAsk.Visible = false
        return
    end
    env.TV_tradeSeen = os.clock() -- окно трейда открыто (для рекламы в чате: пишем через 60 с после трейда)
    gear.Visible = panel.Visible or blPage.Visible or (X.ordPage and X.ordPage.Visible) or (X.ordPicker and X.ordPicker.Visible) or false -- во время трейда кнопка не мешает
    if not wasOpen then
        wasOpen = true
        task.spawn(loadValues) -- свежие цены на каждый трейд
        hud.Visible = true
        hudScale.Scale = sf() * 0.9
        tween(hudScale, 0.25, { Scale = sf() }, Enum.EasingStyle.Back)
    end

    auto.partner = auto.partnerName(tg)
    local mine   = findOffer(tg, { "YourOffer", "MyOffer" })
    local theirs = findOffer(tg, { "TheirOffer", "OtherOffer" })
    if not (mine and theirs) then
        youVal.Text, themVal.Text, winLabel.Text, statusLabel.Text = "—", "—", "", T("noOffers")
        sugLine.Visible = false
        hideHighlights()
        return
    end

    local my, myUnk = sumOffer(mine)
    local th, thUnk = sumOffer(theirs)
    if S.autoDecline then
        local junk, good = auto.junkSplit(theirs)
        if good and junk > 0 then th = math.max(0, th - junk) end -- мусор рядом с нормальным предметом — не считаем
    end
    local diff, total = th - my, my + th
    local share = total > 0 and th / total or 0.5
    local pct = math.floor(share * 100 + 0.5)
    local col, status
    if total == 0 then col, status = C.muted, T("empty")
    elseif math.abs(pct - 50) <= 5 then col, status = C.fair, T("fair")
    elseif pct > 50 then col, status = C.good, T("good")
    else col, status = C.bad, T("bad") end

    youVal.Text = fmt(my)
    local ds = ""
    if S.showDiff and total > 0 and diff ~= 0 then
        ds = (' <font color="%s" size="%d">%s%s</font>'):format(hex(diff > 0 and C.good or C.bad), math.max(10, S.textSize - 2), diff > 0 and "+" or "−", fmt(math.abs(diff)))
    end
    themVal.Text = fmt(th) .. ds
    setNote(youNote, myUnk)
    setNote(themNote, thUnk)

    winLabel.Text = ('<font color="%s">%s %d%%</font>'):format(hex(col), T("win"), pct)
    statusLabel.Text = status
    statusLabel.TextColor3 = col
    tween(fill, 0.3, { Size = UDim2.fromScale(math.clamp(share, 0.03, 1), 1) })
    fillGrad.Color = ColorSequence.new(col:Lerp(C.text, 0.3), col)

    -- снимок трейда для истории: кто, что даю, что получаю; видел ли «вы приняли» / «другой игрок принял»
    do
        local meAcc, themAcc, stage2 = false, false, false
        for _, d in ipairs(tg:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.Visible then
                local t = env.TV_low(d.Text)
                if t:find("уверен") or t:find("are you sure") or t:find("confirm") or t:find("подтверд") then stage2 = true end
                if t:find("вы приняли") or t:find("you accepted") or t:find("you have accepted") then meAcc = true end
                if t:find("другой игрок принял") or t:find("other player has accepted") or t:find("other player accepted") then themAcc = true end
            end
        end
        local snap = auto.lastSnap or {}
        snap.partner, snap.my, snap.th = auto.partner, my, th
        snap.gave, snap.got = auto.readOffer(mine), auto.readOffer(theirs)
        if stage2 and not snap.stage2At then snap.stage2At = os.clock() end
        if meAcc then snap.meAt = os.clock() end
        if themAcc then snap.themAt = os.clock() end
        auto.lastSnap = snap
    end
    -- открыта вкладка «Питомцы» (видны только питомцы) — возвращаемся на «Оружие»
    if not auto.busy and os.clock() - (auto.tabCheck or 0) > 2 then
        auto.tabCheck = os.clock()
        local pets = {}
        for _, it in ipairs(itemsByCat.pets or {}) do pets[it.key] = true end
        local shown, petN = 0, 0
        for _, it in ipairs(scanInventory(tg, mine, theirs)) do
            if isShown(it.frame) then
                shown += 1
                if pets[norm(it.name)] then petN += 1 end
            end
        end
        -- только питомцы — на «Оружие»; пусто (пустые «Питомцы») — тоже, но один раз за трейд:
        -- каждое нажатие вкладки перерисовывает ячейки, и скрипт не успевал положить предметы
        if shown > 0 and petN == shown then auto.openTab(tg, "weapons")
        elseif shown == 0 and not auto.tabEmptyDone then auto.tabEmptyDone = true; auto.openTab(tg, "weapons") end
    end
    if auto.tryGift(tg, theirs, my, myUnk) then return end
    if auto.handleBlocked(tg) then return end
    if autoDecline(tg, theirs) then return end
    if env.TV_outreachTick and env.TV_outreachTick(tg, mine, theirs, my, th) then return end
    if auto.handleEmpty(tg, mine, theirs, my, th) then return end
    env.TV_inTrade, env.TV_lastTradeAt = true, os.clock()
    -- он убрал предмет и вернул тот же (до 20 с) — значит, мой оффер ему не понравился: соберём другой набор
    do
        local parts = {}
        for k, e in pairs(auto.readOffer(theirs)) do table.insert(parts, k .. "=" .. e.count) end
        table.sort(parts)
        local sig = table.concat(parts, ",")
        local h = auto.theirHist or {}
        auto.theirHist = h
        if #h == 0 or h[#h].sig ~= sig then
            local prev = h[#h - 1]
            if sig ~= "" and prev and prev.sig == sig and os.clock() - prev.t < 20 and next(auto.readOffer(mine)) ~= nil or
               (sig ~= "" and prev and prev.sig == sig and os.clock() - prev.t < 20 and auto.lastMine and next(auto.lastMine) ~= nil) then
                auto.reroll = true
                auto.rerollAvoid = auto.rerollAvoid or {}
                for k in pairs(auto.lastMine or {}) do auto.rerollAvoid[k] = true end
                for k in pairs(auto.readOffer(mine)) do auto.rerollAvoid[k] = true end
            end
            table.insert(h, { sig = sig, t = os.clock() })
            while #h > 4 do table.remove(h, 1) end
        end
        -- что я предлагал, пока у него что-то лежало (он мог всё убрать, а скрипт — убрать моё следом)
        local mineNow = auto.readOffer(mine)
        if sig ~= "" and next(mineNow) ~= nil then auto.lastMine = mineNow end
    end
    if auto.reroll and S.autoOffer and S.autoAdd and not auto.busy then
        auto.reroll, auto.busy = false, true
        auto.doneFor, auto.remFor, auto.addTries = -1, nil, 0
        sugLine.Visible = true
        sugText.Text = T("rerolling")
        hideHighlights()
        task.spawn(function()
            pcall(function()
                for _ = 1, 40 do
                    local cell
                    for key in pairs(auto.readOffer(mine)) do cell = auto.myCell(mine, key); if cell then break end end
                    if not cell then break end
                    clickCell(cell, tg)
                    task.wait(0.35)
                end
            end)
            auto.busy = false
            auto.stableSince = os.clock() - 1 -- новый набор — почти сразу
        end)
        return
    end
    updateAutoOffer(tg, mine, theirs, my, th) -- заявки и автооффер работают и во время отсчёта «20 с ничего не меняется»
    if auto.handleIdle(tg, mine, theirs, my, th) then return end
    auto.tryAccept(tg, theirs, my, th, myUnk)
end

on(RunService.Heartbeat, function(dt)
    acc += dt; if acc < 0.25 then return end; acc = 0
    local ok, err = pcall(tick)
    if not ok and not errShown then -- показать ошибку один раз, чтобы было что прислать
        errShown = true
        notify("Ошибка: " .. tostring(err):sub(1, 150))
    end
end)

------------------------------------------------------------------
-- Анализ чата: находим предметы в сообщениях и показываем, выгодно ли это тебе
------------------------------------------------------------------
;(function()
    local LP = Players.LocalPlayer
    local feed = new("Frame", {
        Position = UDim2.new(0, 12, 0.42, 0), Size = UDim2.fromOffset(340, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, ui)
    list(feed, Enum.FillDirection.Vertical, 6)
    local feedScale = new("UIScale", {}, feed)
    local order = 0
    X.chatFeed = feed
    -- карточки — под окном чата Roblox (если его размер известен), иначе слева под ним
    local function placeFeed()
        feedScale.Scale = sf()
        local ok, pos, size = pcall(function()
            local cfg = game:GetService("TextChatService"):FindFirstChildOfClass("ChatWindowConfiguration")
            return cfg.AbsolutePosition, cfg.AbsoluteSize
        end)
        if ok and pos and size and size.Y > 0 then
            feed.AnchorPoint = Vector2.zero
            feed.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 8)
        else
            feed.AnchorPoint = Vector2.zero
            feed.Position = UDim2.new(0, 12, 0.42, 0)
        end
    end
    X.placeFeed = placeFeed

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
        return norm(ok and low or str)
    end

    -- [chatparse begin] — разбор сообщений чата (этот кусок проверяется отдельными тестами)
    -- числа словами (для «three seer», «три сира»)
    local NUMWORDS = {}
    for w, n in pairs({ one = 1, two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9, ten = 10,
        a = 1, an = 1, ["один"] = 1, ["одну"] = 1, ["одного"] = 1, ["два"] = 2, ["две"] = 2, ["три"] = 3, ["четыре"] = 4,
        ["пять"] = 5, ["шесть"] = 6, ["семь"] = 7, ["восемь"] = 8, ["девять"] = 9, ["десять"] = 10 }) do
        NUMWORDS[cnorm(w)] = n
    end
    -- сленг MM2 -> ключ предмета
    local ALIAS = {}
    for k, v in pairs({
        harv = "harvester", harvy = "harvester", harvs = "harvester", gs = "gingerscope", gscope = "gingerscope", ginger = "gingerscope",
        ta = "travelersaxe", travaxe = "travelersaxe", travsaxe = "travelersaxe", travsgun = "travelersgun", tg = "travelersgun", travgun = "travelersgun",
        va = "vampiresaxe", vampaxe = "vampiresaxe", vg = "vampiresgun", vgun = "vampiresgun", vampgun = "vampiresgun",
        cele = "celestial", celes = "celestial", celly = "celestial", icep = "icepiercer", icepierc = "icepiercer",
        ib = "icebreaker", iw = "icewing", bw = "batwing", es = "elderwoodscythe", ewscythe = "elderwoodscythe",
        hs = "hallowscythe", swa = "swirlyaxe", lc = "logchopper", logchop = "logchopper",
        corr = "corrupt", corru = "corrupt", const = "constellation", constel = "constellation", consti = "constellation",
        ab = "alienbeam", alien = "alienbeam", rg = "raygun", ray = "raygun", xs = "xenoshot", xk = "xenoknife",
        hw = "heartwand", sd = "snowdagger", sc = "snowcannon", bz = "blizzard", bliz = "blizzard",
        ds = "darkshot", dsw = "darksword", tr = "turkey", sak = "sakura", blos = "blossom",
        sr = "sunrise", ev = "evergun", evg = "evergreen", bb = "bauble", rb = "rainbow", rbg = "rainbowgun",
        nik = "niksscythe", nikscythe = "niksscythe", fw = "flowerwood", fwg = "flowerwoodgun", wg = "watergun",
        bor = "borealis", aus = "australis", orn = "ornament", rl = "redluger", gl = "greenluger",
        cf = "candleflame", db = "darkbringer", lb = "lightbringer", ewb = "elderwoodblade", ewr = "elderwoodrevolver",
        nb = "nightblade", pb = "plasmabeam", pbl = "plasmablade", plasma = "plasmablade", sg = "swirlygun",
        ba2 = "battleaxeii", gem = "gemstone", og = "oldglory", ve = "vampiresedge", vamp = "vampiresedge",
        cc = "cookiecane", dsh = "deathshard", cw = "clockwork", e1 = "eternal", e2 = "eternalii", e3 = "eternaliii", e4 = "eternaliv",
        ["харв"] = "harvester", ["харва"] = "harvester", ["харвы"] = "harvester", ["харвик"] = "harvester", ["харвестер"] = "harvester",
        ["гс"] = "gingerscope", ["корап"] = "corrupt", ["коррапт"] = "corrupt", ["корапт"] = "corrupt",
        ["сир"] = "seer", ["сира"] = "seer", ["сиры"] = "seer", ["сиров"] = "seer", ["провидец"] = "seer", ["провидца"] = "seer",
        ["акула"] = "shark", ["акулу"] = "shark", ["шарк"] = "shark", ["вечный"] = "eternal", ["етернал"] = "eternal",
        ["плазма"] = "plasmablade", ["целестиал"] = "celestial", ["айспирсер"] = "icepiercer",
    }) do ALIAS[cnorm(k)] = v end

    -- слова-маркеры: к какой стороне относятся предметы дальше в сообщении
    local MARK = {}
    local function marks(kind, list) for _, w in ipairs(list) do MARK[cnorm(w)] = kind end end
    marks("give", { "my", "mine", "giving", "selling", "sell", "trading", "offering", "have", "got", "h",
        "мой", "моя", "мои", "моё", "мое", "моего", "мою", "отдам", "отдаю", "даю", "продаю", "меняю" })
    marks("want", { "for", "lf", "wf", "want", "wants", "need", "needs", "your", "ur", "yours", "gimme",
        "хочу", "ищу", "на", "нужен", "нужна", "нужно", "нужны", "надо", "твой", "твоя", "твои", "твоё", "твое", "твою", "за", "дай",
        "por", "pour", "für", "fur", "per", "voor", "za", "için", "busco", "suche", "cherche", "cerco", "szukam" })
    marks("add", { "add", "adds", "plus", "+", "добавь", "докинь", "накинь", "плюс", "сверху", "доплати" })
    -- «только / just» — просьба точная: лишнее убрать
    local EXACT = {}
    for _, w in ipairs({ "just", "only", "только", "лишь", "просто", "instead", "вместо" }) do EXACT[cnorm(w)] = true end
    -- «за что-нибудь / for anything» — хочет любое предложение
    local ANY = {}
    for _, w in ipairs({ "anything", "offers", "ofs", "anyth", "чтонибудь", "чтото", "любое", "любой", "предложения" }) do ANY[cnorm(w)] = true end

    -- обычные слова, которые не надо угадывать как предметы
    local STOP = {}
    for _, w in ipairs({ "trade", "trading", "trades", "selling", "sell", "buying", "buy", "offer", "offers", "giving",
        "give", "need", "want", "have", "with", "your", "mine", "adds", "add", "plus", "and", "for", "anyone", "pls",
        "please", "godly", "godlies", "ancient", "chroma", "value", "values", "upgrade", "downgrade", "overpay",
        "just", "only", "just", "more", "less", "some", "that", "this", "them", "these", "those", "what", "okay",
        "трейд", "обмен", "меняю", "продаю", "куплю", "ищу", "отдам", "даю", "кто", "есть", "или", "годли", "только", "давай" }) do
        STOP[cnorm(w)] = true
    end
    for k in pairs(NUMWORDS) do STOP[k] = true end -- «three» — число, а не предмет «Tree»
    for k in pairs(MARK) do STOP[k] = true end

    -- русские (и другие) названия из перевода самой игры
    local localNames = {}
    task.spawn(function()
        while #itemList == 0 do task.wait(1) end
        local ok, tr = pcall(function()
            return game:GetService("LocalizationService"):GetTranslatorForPlayerAsync(LP)
        end)
        if not ok or not tr then return end
        for _, it in ipairs(itemList) do
            if it.price then
                local okT, t = pcall(function() return tr:Translate(game, it.name) end)
                if okT and t and t ~= it.name then localNames[cnorm(t)] = it.key end
            end
        end
    end)

    -- расстояние Левенштейна (для опечаток)
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

    -- ключ фразы -> ключ предмета (точно, сленг, перевод, мн. число, начало слова, опечатка)
    local function resolve(key, single)
        if #key < 2 then return nil end
        if valueMap[key] and #key >= 3 then return key end
        if ALIAS[key] and valueMap[ALIAS[key]] then return ALIAS[key] end
        if localNames[key] then return localNames[key] end
        if not single or #key < 4 or STOP[key] then return nil end
        -- множественное число: «seers», «harvs», «evergreens»
        if key:sub(-1) == "s" then
            local k1 = key:sub(1, -2)
            if valueMap[k1] then return k1 end
            if ALIAS[k1] and valueMap[ALIAS[k1]] then return ALIAS[k1] end
        end
        -- слово с окончанием: «харвестера» -> «харвестер»
        for lk, ek in pairs(localNames) do
            if #lk >= 5 and key:sub(1, #lk) == lk and #key - #lk <= 4 then return ek end
        end
        -- начало названия, если подходит ровно один предмет
        local hit, hits = nil, 0
        for k in pairs(valueMap) do
            if k:sub(1, #key) == key then hit, hits = k, hits + 1; if hits > 1 then break end end
        end
        if hits == 1 then return hit end
        if hits > 1 then return nil end -- «swirly» = несколько предметов: не угадываем
        -- опечатка: 1 ошибка для коротких слов, 2 для длинных
        if #key >= 5 and key:match("^[%a%d]+$") then
            local maxD = #key >= 6 and 2 or 1
            local best, bestD, ties = nil, maxD + 1, 0
            for k in pairs(valueMap) do
                local d = lev(key, k, maxD)
                if d < bestD then best, bestD, ties = k, d, 1 elseif d == bestD then ties += 1 end
            end
            if best and bestD <= maxD and ties == 1 then return best end
        end
        return nil
    end

    -- число из слова: «3», «3x», «x3», «*3», «3шт», «three»
    local function numOf(w)
        if not w then return nil end
        local lw = lowerAll(w)
        local n = lw:match("^(%d+)$") or lw:match("^(%d+)[xх%*]$") or lw:match("^[xх%*×](%d+)$") or lw:match("^(%d+)шт%.?$")
        if n then return tonumber(n) end
        return NUMWORDS[cnorm(w)]
    end

    -- разбор сообщения: { gives = {...}, wants = {...}, loose = {...}, adds = {...}, exact = bool, any = bool }
    -- каждый предмет: { name, price, count, key }
    local function parseChat(text)
        local low = lowerAll(text)
        -- «w/f», «+», «,», «&» — отдельными словами
        low = low:gsub("w/f", " wf "):gsub("[%+]", " + "):gsub("[,;&/]", " ")
        local words = {}
        for w in low:gmatch("%S+") do table.insert(words, w) end
        local res = { gives = {}, wants = {}, loose = {}, adds = {}, exact = false, any = false }
        local side = nil -- nil = сторона не указана
        local i = 1
        while i <= #words do
            local w = words[i]
            local cw = cnorm(w)
            if w == "+" then side = "add"; i += 1; continue end
            if cw == "give" and cnorm(words[i + 1] or "") == "me" then side = "want"; i += 2; continue end
            if EXACT[cw] then res.exact = true end
            if ANY[cw] then res.any = true end
            if MARK[cw] then side = MARK[cw]; i += 1; continue end
            local matched = false
            for len = math.min(4, #words - i + 1), 1, -1 do
                -- в название из нескольких слов не берём «+», числа и слова-маркеры («harv + 2» — это не предмет)
                local clean = true
                for j = i + 1, i + len - 1 do
                    local cj = cnorm(words[j])
                    if cj == "" or MARK[cj] or numOf(words[j]) then clean = false; break end
                end
                local itemKey = clean and resolve(cnorm(table.concat(words, " ", i, i + len - 1)), len == 1) or nil
                if itemKey then
                    -- «c harv» / «chroma harv» / «хрома харв» -> хрома-версия
                    local prev = words[i - 1] and cnorm(words[i - 1])
                    if (prev == "c" or prev == "chroma" or prev == "chr" or prev == "хрома" or prev == "хром")
                        and valueMap["chroma" .. itemKey] then
                        itemKey = "chroma" .. itemKey
                    end
                    -- количество: перед словом или сразу после него
                    -- число перед словом важнее («3x seer, 2 shark»: 2 относится к shark)
                    local before = numOf(words[i - 1])
                    local after, skipAfter = nil, false
                    if not before then
                        after = numOf(words[i + len])
                        skipAfter = after ~= nil
                        if not after and words[i + len] == "x" then after = numOf(words[i + len + 1]); skipAfter = after ~= nil end
                    end
                    local count = math.clamp(before or after or 1, 1, 99)
                    local it = { name = (env.TV_names or {})[itemKey] or itemKey, price = valueMap[itemKey], count = count, key = itemKey }
                    local bucket = side == "give" and res.gives or side == "want" and res.wants or side == "add" and res.adds or res.loose
                    table.insert(bucket, it)
                    i += len + (skipAfter and (words[i + len] == "x" and 2 or 1) or 0)
                    matched = true
                    break
                end
            end
            if not matched then i += 1 end
        end
        return res
    end
    local function sumOf(list)
        local s = 0
        for _, it in ipairs(list) do s += it.price * it.count end
        return s
    end
    -- [chatparse end]

    local function listText(found)
        local parts = {}
        for _, it in ipairs(found) do
            table.insert(parts, ("%s%s <font color=\"%s\">%s</font>"):format((it.name:gsub("<", "&lt;")), it.count > 1 and (" x" .. it.count) or "", hex(C.muted), fmt(it.price * it.count)))
        end
        return table.concat(parts, ", ")
    end

    local function showCard(who, body)
        order += 1
        local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, LayoutOrder = -order }, feed)
        corner(card, 10)
        local st = stroke(card, accent(), 0.5)
        pad(card, 10, 7)
        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.text,
            TextSize = math.max(12, S.textSize - 2), Font = fontReg(),
            Text = ("<b>%s</b>\n%s"):format((who:gsub("<", "&lt;")), body) }, card)
        -- не больше 4 карточек
        local cards = {}
        for _, c in ipairs(feed:GetChildren()) do if c:IsA("Frame") then table.insert(cards, c) end end
        table.sort(cards, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
        for k = 1, #cards - 4 do cards[k]:Destroy() end
        task.delay(25, function() if card.Parent then card:Destroy() end end)
        st.Color = accent()
    end

    local function analyse(player, text)
        if not S.enabled or player == LP or not text or text == "" then return end
        local okP, r = pcall(parseChat, text)
        if not okP or not r then return end
        -- сообщение соперника по трейду: запоминаем его просьбу (работает и без «Анализа чата»)
        if S.chatRequests and player and auto.partner and (player.Name == auto.partner or player.DisplayName == auto.partner) then
            local kind, items
            if #r.adds > 0 then kind, items = "extra", r.adds                      -- «добавь сира»: сверху
            elseif #r.wants > 0 then kind, items = r.exact and "exact" or "total", r.wants
            elseif #r.loose > 0 and #r.gives == 0 then kind, items = r.exact and "exact" or "total", r.loose
            end
            if kind then
                auto.reqSeq = (auto.reqSeq or 0) + 1
                auto.partnerReq = { partner = auto.partner, items = items, kind = kind, t = os.clock(), id = auto.reqSeq }
            end
        end
        if not S.chatAds or not player then return end -- без отправителя (системные сообщения) — не разбираем
        -- без признаков трейда дешёвые «предметы» — это просто слова («grind», «prism», «sub»): не показываем
        local hasMarkers = #r.gives > 0 or #r.wants > 0 or #r.adds > 0 or r.any
        if not hasMarkers then
            local kept = {}
            for _, it in ipairs(r.loose) do
                if it.price >= 10 or it.count > 1 then table.insert(kept, it) end
            end
            r.loose = kept
        end
        local maxPrice = 0
        for _, list_ in ipairs({ r.gives, r.wants, r.adds, r.loose }) do
            for _, it in ipairs(list_) do maxPrice = math.max(maxPrice, it.price) end
        end
        if maxPrice < 10 then return end
        placeFeed()
        local gives, wants = {}, r.wants
        for _, it in ipairs(r.gives) do table.insert(gives, it) end
        -- предметы без пометки: если он чего-то хочет — значит, это то, что он даёт
        local loose = r.loose
        if #loose > 0 and (#wants > 0 or r.any) then
            for _, it in ipairs(loose) do table.insert(gives, it) end
            loose = {}
        end
        if #gives == 0 and #wants == 0 and #loose == 0 and #r.adds == 0 then return end

        local who = player and player.DisplayName or "?"
        local lines = {}
        if #gives > 0 then table.insert(lines, ("%s: %s"):format(T("gives"), listText(gives))) end
        if #wants > 0 then table.insert(lines, ("%s: %s"):format(T("wants"), listText(wants)))
        elseif r.any and #gives > 0 then table.insert(lines, ("%s: %s"):format(T("wants"), T("anyOffers"))) end
        if #r.adds > 0 then table.insert(lines, ("%s: %s"):format(T("asksAdd"), listText(r.adds))) end
        if #loose > 0 then table.insert(lines, ("%s: %s = <b>%s</b>"):format(T("items"), listText(loose), fmt(sumOf(loose)))) end
        if #gives > 0 and #wants > 0 then
            local diff = sumOf(gives) - sumOf(wants) -- если согласиться: получаешь «даёт», отдаёшь «хочет»
            local col = diff > 0 and C.good or (diff < 0 and C.bad or C.fair)
            local status = diff > 0 and T("good") or (diff < 0 and T("bad") or T("fair"))
            table.insert(lines, ('%s: <font color="%s"><b>%s%s · %s</b></font>'):format(
                T("forYou"), hex(col), diff >= 0 and "+" or "-", fmt(math.abs(diff)), status))
        elseif #gives > 0 then
            table.insert(lines, ("= <b>%s</b>"):format(fmt(sumOf(gives))))
        elseif #wants > 0 then
            table.insert(lines, ("= <b>%s</b>"):format(fmt(sumOf(wants))))
        end
        showCard(who, table.concat(lines, "\n"))
    end

    -- новый чат (TextChatService) и старый (Player.Chatted)
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
end)() -- отдельная функция: у неё свой лимит 200 локальных

------------------------------------------------------------------
-- Окно «Заявки»: слева заявки (на какой предмет), справа варианты (что отдаёшь), выбор предметов
------------------------------------------------------------------
;(function()
    local W, H, SIDE = 640, 480, 200
    local page = new("Frame", { Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Visible = false, BackgroundColor3 = C.bg, BackgroundTransparency = 0.04 }, ui)
    corner(page, 18)
    stroke(page)
    pad(page, 16, 16)
    local pscale = new("UIScale", {}, page)
    X.ordPage = page

    local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) }, page)
    local back = new("TextButton", { Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.card, Text = "<", TextColor3 = C.text,
        TextSize = 18, Font = Enum.Font.GothamBold, AutoButtonColor = false }, head)
    corner(back, 16)
    stroke(back)
    local title = label(head, { Size = UDim2.new(1, -260, 0, 18), Position = UDim2.fromOffset(44, 0), TextSize = 16 }, true)
    local sub = label(head, { Size = UDim2.new(1, -260, 0, 14), Position = UDim2.fromOffset(44, 19), TextSize = 12, TextColor3 = C.muted })
    makeDraggable(title, page)
    local onBox = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.fromOffset(210, 34),
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0) }, head)
    corner(onBox, 10)
    stroke(onBox)
    pad(onBox, 10, 0)
    local onLbl = label(onBox, { Size = UDim2.new(1, -54, 1, 0), TextSize = 13 })
    local onTg, drawOnTg = makeToggle(onBox)

    local function scrollBox(parent, size, pos)
        local sc = new("ScrollingFrame", { Size = size, Position = pos, BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, parent)
        list(sc, Enum.FillDirection.Vertical, 4)
        themed(function() sc.ScrollBarImageColor3 = accent() end)
        return sc
    end
    local function btn(parent, text, size, pos, color)
        local b = new("TextButton", { Size = size, Position = pos, BackgroundColor3 = color or C.card, BackgroundTransparency = 0.2,
            Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false }, parent)
        corner(b, 9)
        stroke(b)
        return b
    end
    local function clear(sc) for _, c in ipairs(sc:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
    local function pic(parent, name, size, pos)
        local im = new("ImageLabel", { Size = UDim2.fromOffset(size, size), Position = pos, BackgroundColor3 = C.bg,
            BackgroundTransparency = 0.4, ScaleType = Enum.ScaleType.Fit, Image = "" }, parent)
        corner(im, 7)
        im.Image = env.TV_image and env.TV_image(name, function(a) if im.Parent then im.Image = a end end) or ""
        return im
    end

    -- левая колонка: «+ Новая заявка» и список заявок
    local left = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(0, SIDE, 1, -46),
        Position = UDim2.fromOffset(0, 46) }, page)
    corner(left, 12)
    stroke(left)
    local newBtn = btn(left, "", UDim2.new(1, -12, 0, 34), UDim2.fromOffset(6, 6))
    local side = scrollBox(left, UDim2.new(1, -12, 1, -52), UDim2.fromOffset(6, 46))

    -- правая часть: выбранная заявка
    local right = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -SIDE - 12, 1, -46), Position = UDim2.fromOffset(SIDE + 12, 46) }, page)
    local rTitle = label(right, { Size = UDim2.new(1, -60, 0, 22), Position = UDim2.fromOffset(52, 2), TextSize = 16 }, true)
    local rSub = label(right, { Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(52, 24), TextSize = 12, TextColor3 = C.muted })
    local rPic = new("ImageLabel", { Size = UDim2.fromOffset(44, 44), BackgroundColor3 = C.bg, BackgroundTransparency = 0.4,
        ScaleType = Enum.ScaleType.Fit, Image = "" }, right)
    corner(rPic, 8)
    local vars = scrollBox(right, UDim2.new(1, 0, 1, -100), UDim2.fromOffset(0, 52))
    local addVar = btn(right, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0, 0, 1, -40))
    local delOrd = btn(right, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0.5, 4, 1, -40))

    -- выбор предметов — отдельное окно: слева категории, справа поиск и список, внизу сумма и кнопки
    local picker = new("Frame", { Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Visible = false, BackgroundColor3 = C.bg, BackgroundTransparency = 0.04 }, ui)
    corner(picker, 18)
    stroke(picker)
    pad(picker, 16, 16)
    local pkScale = new("UIScale", {}, picker)
    X.ordPicker = picker
    local pkHead = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34) }, picker)
    local pBack = new("TextButton", { Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.card, Text = "<", TextColor3 = C.text,
        TextSize = 18, Font = Enum.Font.GothamBold, AutoButtonColor = false }, pkHead)
    corner(pBack, 16)
    stroke(pBack)
    local pHint = label(pkHead, { Size = UDim2.new(1, -44, 0, 34), Position = UDim2.fromOffset(44, 0), TextSize = 15, TextWrapped = true }, true)
    makeDraggable(pHint, picker)
    local pSideBox = new("Frame", { BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Size = UDim2.new(0, 160, 1, -46),
        Position = UDim2.fromOffset(0, 46) }, picker)
    corner(pSideBox, 12)
    stroke(pSideBox)
    local pSide = scrollBox(pSideBox, UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6))
    local pRight = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -172, 1, -46), Position = UDim2.fromOffset(172, 46) }, picker)
    local pSearch = new("TextBox", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.card, BackgroundTransparency = 0.3, Text = "",
        PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 14, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham }, pRight)
    corner(pSearch, 9)
    pad(pSearch, 10, 0)
    local pList = scrollBox(pRight, UDim2.new(1, 0, 1, -122), UDim2.fromOffset(0, 40))
    local pSum = label(pRight, { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 1, -78), TextSize = 12, TextWrapped = true, TextColor3 = C.muted })
    local pSave = btn(pRight, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0, 0, 1, -40), C.good)
    local pCancel = btn(pRight, "", UDim2.new(0.5, -4, 0, 36), UDim2.new(0.5, 4, 1, -40))
    local pCat = "godlies"

    local sel, pickMode, draft = nil, nil, {}
    local renderSide, renderRight, renderPicker

    local function orderValue(o) return valueMap[o.target] or 0 end
    local function offerText(v)
        local parts, sum = {}, 0
        for _, it in ipairs(v.items or {}) do
            table.insert(parts, it.name .. (it.count > 1 and (" x" .. it.count) or ""))
            sum += (valueMap[it.key] or 0) * it.count
        end
        return table.concat(parts, ", "), sum
    end
    local function save() saveSettings(); env.TV_refresh() end

    renderSide = function()
        clear(side)
        for i, o in ipairs(S.orders) do
            local on_ = 0
            for _, v in ipairs(o.offers or {}) do if v.on then on_ += 1 end end
            local r = new("TextButton", { Size = UDim2.new(1, -4, 0, 42), BackgroundColor3 = accent(), BackgroundTransparency = sel == i and 0.75 or 1,
                Text = "", AutoButtonColor = false, LayoutOrder = i }, side)
            corner(r, 8)
            pic(r, o.name, 34, UDim2.fromOffset(4, 4))
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -48, 0, 20), Position = UDim2.fromOffset(44, 3),
                Text = o.name, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd }, r)
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -48, 0, 16), Position = UDim2.fromOffset(44, 22),
                Text = ("%d / %d"):format(on_, #(o.offers or {})), TextColor3 = C.muted, TextSize = 11, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left }, r)
            on(r.Activated, function() sel = i; renderSide(); renderRight() end)
        end
        sub.Text = T("ordersSub"):format(#S.orders)
    end

    renderRight = function()
        clear(vars)
        local o = sel and S.orders[sel]
        rPic.Visible, addVar.Visible, delOrd.Visible = o ~= nil, o ~= nil, o ~= nil
        if not o then rTitle.Text, rSub.Text = "", T("ordEmpty"); return end
        rTitle.Text = o.name
        rSub.Text = env.TV_fmt(orderValue(o))
        rPic.Image = env.TV_image and env.TV_image(o.name, function(a) if rPic.Parent then rPic.Image = a end end) or ""
        if #(o.offers or {}) == 0 then
            label(vars, { Size = UDim2.new(1, 0, 0, 30), Text = T("ordNoVars"), TextColor3 = C.muted, TextSize = 13, LayoutOrder = 1 })
        end
        for i, v in ipairs(o.offers or {}) do
          if (v.profit or 0) > 0 then
            -- вариант «% прибыли»
            local card = new("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundColor3 = C.card, BackgroundTransparency = v.on and 0.1 or 0.6,
                LayoutOrder = i }, vars)
            corner(card, 10)
            pad(card, 10, 0)
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -220, 0, 22), Position = UDim2.fromOffset(0, 6), Text = T("ordProfitVar"):format(v.profit),
                TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, card)
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -220, 0, 18), Position = UDim2.fromOffset(0, 28), Text = T("ordProfitVarSub"),
                TextColor3 = C.muted, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
            local box = new("Frame", { Size = UDim2.fromOffset(110, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -84, 0.5, 0),
                BackgroundColor3 = C.bg, BackgroundTransparency = 0.2 }, card)
            corner(box, 9)
            local minus = btn(box, "−", UDim2.fromOffset(30, 30), UDim2.fromOffset(0, 0))
            local plus = btn(box, "+", UDim2.fromOffset(30, 30), UDim2.new(1, -30, 0, 0))
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(30, 0), Text = "+" .. v.profit .. "%",
                TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold }, box)
            on(minus.Activated, function() v.profit = math.max(5, v.profit - 5); save(); renderRight() end)
            on(plus.Activated, function() v.profit = math.min(500, v.profit + 5); save(); renderRight() end)
            local tg_, draw = makeToggle(card)
            tg_.Position = UDim2.new(1, -36, 0.5, 0)
            draw(v.on)
            on(tg_.Activated, function() v.on = not v.on; save(); renderSide(); renderRight() end)
            local del = btn(card, "", UDim2.fromOffset(28, 28), UDim2.new(1, -28, 0.5, -14))
            for _, rot in ipairs({ 45, -45 }) do
                corner(new("Frame", { BackgroundColor3 = C.muted, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), Rotation = rot }, del), 1)
            end
            on(del.Activated, function() table.remove(o.offers, i); save(); renderSide(); renderRight() end)
          else
            local txt, sum = offerText(v)
            local card = new("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundColor3 = C.card, BackgroundTransparency = v.on and 0.1 or 0.6,
                LayoutOrder = i }, vars)
            corner(card, 10)
            pad(card, 10, 0)
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -96, 0, 22), Position = UDim2.fromOffset(0, 6), Text = txt,
                TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd }, card)
            local diff = orderValue(o) - sum
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -96, 0, 18), Position = UDim2.fromOffset(0, 28), RichText = true,
                Text = T("ordGive"):format(env.TV_fmt(sum), env.TV_fmt(orderValue(o))) .. (' <font color="%s">(%s%s)</font>'):format(
                    hex(diff >= 0 and C.good or C.bad), diff >= 0 and "+" or "-", env.TV_fmt(math.abs(diff))),
                TextColor3 = C.muted, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }, card)
            local tg_, draw = makeToggle(card)
            tg_.Position = UDim2.new(1, -36, 0.5, 0)
            draw(v.on)
            on(tg_.Activated, function() v.on = not v.on; save(); renderSide(); renderRight() end)
            local del = btn(card, "", UDim2.fromOffset(28, 28), UDim2.new(1, -28, 0.5, -14))
            for _, rot in ipairs({ 45, -45 }) do
                corner(new("Frame", { BackgroundColor3 = C.muted, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), Rotation = rot }, del), 1)
            end
            on(del.Activated, function() table.remove(o.offers, i); save(); renderSide(); renderRight() end)
          end
        end
        -- добавить вариант «% прибыли» (по умолчанию +50%)
        local addP = btn(vars, T("ordAddProfit"), UDim2.new(1, -6, 0, 34), UDim2.new())
        addP.LayoutOrder = 9999
        on(addP.Activated, function()
            o.offers = o.offers or {}
            table.insert(o.offers, { on = true, profit = 50 })
            save(); renderSide(); renderRight()
        end)
    end

    local function closePicker()
        picker.Visible = false
        page.Visible = true
    end
    local function renderPSide()
        clear(pSide)
        local entries = { { "all", T("all") } }
        for _, cat in ipairs(catOrder) do
            if itemsByCat[cat] then table.insert(entries, { cat, ((L[S.lang] or L.ru).cats or {})[cat] or cat }) end
        end
        for i, e in ipairs(entries) do
            local active = e[1] == pCat
            local b = new("TextButton", { Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = accent(), BackgroundTransparency = active and 0.75 or 1,
                Text = e[2], TextColor3 = active and accent():Lerp(rgb(255, 255, 255), 0.4) or C.text, TextSize = 13,
                Font = active and Enum.Font.GothamBold or Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, LayoutOrder = i }, pSide)
            corner(b, 8)
            pad(b, 10, 0)
            on(b.Activated, function() pCat = e[1]; pSearch.Text = ""; renderPSide(); renderPicker() end)
        end
    end

    renderPicker = function()
        clear(pList)
        local q = norm(pSearch.Text)
        local shown = 0
        local source = (pCat == "all" or q ~= "") and itemList or (itemsByCat[pCat] or {}) -- поиск — по всем предметам
        for _, it in ipairs(source) do
            if it.price and (q == "" or it.key:find(q, 1, true)) then
                shown += 1
                if shown > 3000 then break end
                local n = draft[it.key] and draft[it.key].count or 0
                local r = new("TextButton", { Size = UDim2.new(1, -6, 0, 40), BackgroundColor3 = C.card, BackgroundTransparency = n > 0 and 0.1 or 0.6,
                    Text = "", AutoButtonColor = false, LayoutOrder = shown }, pList)
                corner(r, 9)
                pic(r, it.name, 32, UDim2.fromOffset(4, 4))
                new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(44, 0), Text = it.name,
                    TextColor3 = C.text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd }, r)
                new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(60, 40), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -70, 0, 0), Text = env.TV_fmt(it.price), TextColor3 = C.muted, TextSize = 12, Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right }, r)
                if n > 0 then
                    new("TextLabel", { Size = UDim2.fromOffset(30, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -36, 0.5, 0),
                        BackgroundColor3 = accent(), Text = "x" .. n, TextColor3 = rgb(255, 255, 255), TextSize = 12, Font = Enum.Font.GothamBold }, r)
                    local minus = btn(r, "-", UDim2.fromOffset(28, 28), UDim2.new(1, -32, 0.5, -14))
                    on(minus.Activated, function()
                        local d = draft[it.key]
                        if d then d.count -= 1; if d.count <= 0 then draft[it.key] = nil end end
                        renderPicker()
                    end)
                end
                on(r.Activated, function()
                    if pickMode == "target" then
                        for i, o in ipairs(S.orders) do if o.target == it.key then sel = i end end
                        if not (sel and S.orders[sel] and S.orders[sel].target == it.key) then
                            table.insert(S.orders, { target = it.key, name = it.name, offers = {} })
                            sel = #S.orders
                        end
                        closePicker()
                        save(); renderSide(); renderRight()
                    else
                        local d = draft[it.key] or { key = it.key, name = it.name, count = 0 }
                        d.count += 1
                        draft[it.key] = d
                        renderPicker()
                    end
                end)
            end
        end
        if pickMode == "offer" then
            local parts, sum = {}, 0
            for _, d in pairs(draft) do
                table.insert(parts, d.name .. (d.count > 1 and (" x" .. d.count) or ""))
                sum += (valueMap[d.key] or 0) * d.count
            end
            pSum.Text = #parts > 0 and (table.concat(parts, ", ") .. " = " .. env.TV_fmt(sum)) or ""
        end
    end

    local function openPicker(mode)
        pickMode, draft = mode, {}
        pSearch.Text = ""
        local o = sel and S.orders[sel]
        pHint.Text = mode == "target" and T("ordPickTarget") or T("ordPickOffer"):format(o and o.name or "?")
        pSave.Visible, pSum.Visible = mode == "offer", mode == "offer"
        pkScale.Scale = pscale.Scale
        page.Visible = false
        picker.Visible = true
        renderPSide()
        renderPicker()
    end

    local function refreshTexts()
        title.Text = T("orders")
        onLbl.Text = T("ordersOn")
        drawOnTg(S.ordersOn)
        newBtn.Text = T("ordNew")
        addVar.Text, delOrd.Text = T("ordAddVar"), T("ordDel")
        pSave.Text, pCancel.Text = T("ordSave"), T("ordCancel")
        pSearch.PlaceholderText = T("search")
    end

    on(pSearch:GetPropertyChangedSignal("Text"), function() if picker.Visible then renderPicker() end end)
    on(newBtn.Activated, function() openPicker("target") end)
    on(addVar.Activated, function() if sel then openPicker("offer") end end)
    on(pCancel.Activated, closePicker)
    on(pBack.Activated, closePicker)
    on(pSave.Activated, function()
        local o = sel and S.orders[sel]
        if o then
            local items = {}
            for _, d in pairs(draft) do table.insert(items, { key = d.key, name = d.name, count = d.count }) end
            if #items > 0 then table.insert(o.offers, { on = true, items = items }) end
        end
        closePicker()
        save(); renderSide(); renderRight()
    end)
    on(delOrd.Activated, function()
        if sel then table.remove(S.orders, sel); sel = nil; save(); renderSide(); renderRight() end
    end)
    on(onTg.Activated, function() S.ordersOn = not S.ordersOn; saveSettings(); refreshTexts() end)
    on(back.Activated, function() page.Visible = false; panel.Visible = true; env.TV_refresh() end)
    on(X.ordOpen.Activated, function()
        S.orders = S.orders or {}
        panel.Visible = false
        picker.Visible = false
        refreshTexts(); renderSide(); renderRight()
        page.Visible = true
        local abs = ui.AbsoluteSize
        local target = math.min(sf(), (abs.X - 24) / W, (abs.Y - 24) / H)
        pscale.Scale = target * 0.94
        tween(pscale, 0.25, { Scale = target }, Enum.EasingStyle.Back)
    end)
end)() -- отдельная функция: у неё свой лимит 200 локальных

------------------------------------------------------------------
-- График цены: нажатие на предмет в «Таблице цен» (и стоимость инвентаря)
------------------------------------------------------------------
;(function()
    local CW, CH = 480, 210
    local win = new("Frame", { Size = UDim2.fromOffset(CW + 32, CH + 164), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Visible = false, BackgroundColor3 = C.bg, BackgroundTransparency = 0.02, ZIndex = 20 }, ui)
    corner(win, 16)
    stroke(win)
    pad(win, 16, 14)
    local wscale = new("UIScale", {}, win)
    local cTitle = label(win, { Size = UDim2.new(1, -150, 0, 20), TextSize = 16, ZIndex = 21 }, true)
    local cSub = label(win, { Size = UDim2.new(1, -40, 0, 16), Position = UDim2.fromOffset(0, 23), TextSize = 12, TextColor3 = C.muted, ZIndex = 21 })
    local cNote = label(win, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -30), TextSize = 11, TextWrapped = true,
        TextColor3 = C.muted, ZIndex = 21 })
    local close = new("TextButton", { Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, -4),
        BackgroundColor3 = C.card, Text = "", AutoButtonColor = false, ZIndex = 21 }, win)
    corner(close, 14)
    for _, rot in ipairs({ 45, -45 }) do
        corner(new("Frame", { BackgroundColor3 = C.muted, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 22,
            Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), Rotation = rot }, close), 1)
    end
    -- переключатель «Линия / Свечи»
    local seg = new("Frame", { Size = UDim2.fromOffset(112, 26), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -36, 0, -3),
        BackgroundColor3 = C.card, ZIndex = 21 }, win)
    corner(seg, 8)
    stroke(seg)
    local segKnob = new("Frame", { Size = UDim2.new(0.5, -4, 1, -4), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = accent(), ZIndex = 22 }, seg)
    corner(segKnob, 6)
    local bLine = new("TextButton", { Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, Text = "", TextColor3 = C.text, TextSize = 11, ZIndex = 23 }, seg)
    local bCandle = new("TextButton", { Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1, Text = "",
        TextColor3 = C.text, TextSize = 11, ZIndex = 23 }, seg)
    themed(function() bLine.Font, bCandle.Font = fontBold(), fontBold() end)
    local canvas = new("Frame", { Size = UDim2.fromOffset(CW, CH), Position = UDim2.fromOffset(0, 80), BackgroundColor3 = C.card,
        BackgroundTransparency = 0.4, ClipsDescendants = true, ZIndex = 21 }, win)
    corner(canvas, 10)
    -- список предметов под графиком (для статистики инвентаря)
    local LISTH = 200
    local listF = new("ScrollingFrame", { Size = UDim2.fromOffset(CW, LISTH), Position = UDim2.fromOffset(0, 80 + CH + 8), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, ZIndex = 21 }, win)
    list(listF, Enum.FillDirection.Vertical, 4)
    themed(function() listF.ScrollBarImageColor3 = accent() end)
    -- период (1Д / 7Д / 30Д / Всё) и масштаб по цене (− / +); колесо мыши над графиком — тоже период
    local RANGES = { { "1Д", 86400 }, { "7Д", 7 * 86400 }, { "30Д", 30 * 86400 }, { "Всё", 0 } }
    local vZoom = 1
    local chips = new("Frame", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, ZIndex = 21 }, win)
    list(chips, Enum.FillDirection.Horizontal, 6)
    local chipBtns = {}
    local function chip(text, order, w)
        local b = new("TextButton", { Size = UDim2.fromOffset(w or 44, 24), BackgroundColor3 = C.card, Text = text, TextColor3 = C.text,
            TextSize = 11, AutoButtonColor = false, LayoutOrder = order, ZIndex = 22 }, chips)
        corner(b, 7)
        stroke(b)
        themed(function() b.Font = fontBold() end)
        return b
    end
    for i, r in ipairs(RANGES) do chipBtns[i] = chip(r[1], i) end
    new("Frame", { Size = UDim2.fromOffset(18, 1), BackgroundTransparency = 1, LayoutOrder = 10 }, chips)
    local zOut = chip("−", 11, 28)
    local zIn = chip("+", 12, 28)
    local zLabel = label(chips, { Size = UDim2.fromOffset(60, 24), TextSize = 11, TextColor3 = C.muted, LayoutOrder = 13, ZIndex = 22 })
    makeDraggable(cTitle, win)
    on(close.Activated, function() win.Visible = false end)

    local function dateStr(t, f)
        local ok, s = pcall(function() return DateTime.fromUnixTimestamp(t):FormatLocalTime(f or "DD.MM", "ru-ru") end)
        return ok and s or ""
    end
    local function seg_(x1, y1, x2, y2, col, th)
        local dx, dy = x2 - x1, y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.5 then len = 0.5 end
        return new("Frame", { Size = UDim2.fromOffset(len + th, th), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2), Rotation = math.deg(math.atan2(dy, dx)),
            BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 22 }, canvas)
    end
    local function txt(text, x, y, ax)
        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(90, 14), AnchorPoint = Vector2.new(ax or 0, 0.5),
            Position = UDim2.fromOffset(x, y), Text = text, TextColor3 = C.muted, TextSize = 10, Font = Enum.Font.RobotoMono,
            TextXAlignment = (ax == 1 and Enum.TextXAlignment.Right) or (ax == 0.5 and Enum.TextXAlignment.Center) or Enum.TextXAlignment.Left,
            ZIndex = 23 }, canvas)
    end
    local function delta(d, base)
        local pct = base > 0 and d / base * 100 or 0
        local col = d > 0 and C.good or d < 0 and C.bad or C.muted
        return ('<font color="%s">%s%s (%s%.1f%%)</font>'):format(hex(col), d >= 0 and "+" or "−", env.TV_fmt(math.abs(d)),
            pct >= 0 and "+" or "−", math.abs(pct))
    end

    local last -- что показано сейчас (для перерисовки при смене вида)
    local function draw(it, custom)
        for _, c in ipairs(canvas:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        local candles = S.chartMode == "candles"
        tween(segKnob, 0.2, { Position = candles and UDim2.new(0.5, 2, 0, 2) or UDim2.fromOffset(2, 2) })
        segKnob.BackgroundColor3 = accent()
        bLine.Text, bCandle.Text = T("chartLine"), T("chartCandles")
        local hist = {}
        local src = custom and custom.hist or (env.TV_hist or {})[it.name] or {}
        for _, pnt in ipairs(src) do
            local t, v = tonumber(pnt[1]), tonumber(pnt[2])
            if t and v then table.insert(hist, { t, v }) end
        end
        table.sort(hist, function(a, b) return a[1] < b[1] end)
        local now = os.time()
        if #hist == 0 and it and it.price then hist = { { now - 86400, it.price } } end
        if #hist == 0 then return false end
        local cur = hist[#hist][2]
        table.insert(hist, { now, cur }) -- до сегодняшнего дня цена держится
        -- выбранный период: точка на его начало + всё, что внутри
        local range = S.chartRange or 0
        if range > 0 and now - range > hist[1][1] then
            local start, v0 = now - range, hist[1][2]
            for _, pnt in ipairs(hist) do if pnt[1] <= start then v0 = pnt[2] else break end end
            local vis = { { start, v0 } }
            for _, pnt in ipairs(hist) do if pnt[1] > start then table.insert(vis, pnt) end end
            hist = vis
        end
        local first = hist[1][2]
        local points = #hist - 1
        for i, r in ipairs(RANGES) do
            local active = (r[2] == range)
            chipBtns[i].BackgroundColor3 = active and accent() or C.card
            chipBtns[i].TextColor3 = active and C.bg or C.text
        end
        zLabel.Text = vZoom ~= 1 and ("×" .. (vZoom >= 1 and tostring(vZoom) or ("1/" .. tostring(1 / vZoom)))) or ""
        local tMin, tMax, vMin, vMax = hist[1][1], now, math.huge, -math.huge
        for _, pnt in ipairs(hist) do vMin, vMax = math.min(vMin, pnt[2]), math.max(vMax, pnt[2]) end
        if vMax - vMin < 1 then vMin, vMax = vMin - 1, vMax + 1 end
        -- масштаб по цене: + приближает к середине, − отдаляет
        local mid, half = (vMin + vMax) / 2, (vMax - vMin) / 2 / vZoom
        vMin, vMax = mid - half, mid + half
        local padV = (vMax - vMin) * 0.15
        vMin, vMax = math.max(0, vMin - padV), vMax + padV
        if tMax - tMin < 3600 then tMin = tMax - 3600 end
        local L_, R_, T_, B_ = 52, 14, 14, 26
        local function px(t) return L_ + (t - tMin) / (tMax - tMin) * (CW - L_ - R_) end
        local function py(v) return T_ + (1 - (v - vMin) / (vMax - vMin)) * (CH - T_ - B_) end
        -- сетка: 4 линии цены и 5 отметок времени
        for k = 0, 3 do
            local v = vMin + (vMax - vMin) * k / 3
            seg_(L_, py(v), CW - R_, py(v), C.line, 1).BackgroundTransparency = 0.9
            txt(env.TV_fmt(v), L_ - 6, py(v), 1)
        end
        local span = tMax - tMin
        local fx = span > 2 * 86400 and "DD.MM" or "DD.MM HH:mm"
        for k = 0, 4 do
            local t = tMin + span * k / 4
            seg_(px(t), T_, px(t), CH - B_, C.line, 1).BackgroundTransparency = 0.95
            txt(dateStr(t, fx), px(t), CH - 11, k == 0 and 0 or k == 4 and 1 or 0.5)
        end
        local col = cur > first and C.good or cur < first and C.bad or accent()
        local tip = new("TextLabel", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.05, AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0), Text = "", RichText = true, TextColor3 = C.text, TextSize = 11, Font = Enum.Font.RobotoMono,
            Visible = false, ZIndex = 30 }, canvas)
        corner(tip, 6)
        pad(tip, 6, 4)
        local function hover(hit, text, x, y)
            local function show()
                tip.Text = text
                tip.Position = UDim2.fromOffset(math.clamp(x + 10, 2, CW - 170), math.clamp(y - 50, 2, CH - 56))
                tip.Visible = true
            end
            on(hit.MouseEnter, show)
            on(hit.Activated, show)
            on(hit.MouseLeave, function() tip.Visible = false end)
        end

        if candles then
            -- свечи: период подбираем так, чтобы их было не больше ~36
            local size = 3600
            for _, sz in ipairs({ 3600, 3 * 3600, 6 * 3600, 12 * 3600, 86400, 2 * 86400, 7 * 86400, 30 * 86400 }) do
                size = sz
                if span / sz <= 36 then break end
            end
            local function valueAt(t) -- цена на момент t (последняя точка не позже t)
                local v = hist[1][2]
                for _, pnt in ipairs(hist) do if pnt[1] <= t then v = pnt[2] else break end end
                return v
            end
            local b0 = math.floor(hist[1][1] / size) * size
            local bucket = b0
            while bucket <= tMax do
                local open, close = valueAt(bucket), valueAt(bucket + size - 1)
                if bucket < hist[1][1] then open = hist[1][2] end
                local hi, lo = math.max(open, close), math.min(open, close)
                for _, pnt in ipairs(hist) do
                    if pnt[1] >= bucket and pnt[1] < bucket + size then hi, lo = math.max(hi, pnt[2]), math.min(lo, pnt[2]) end
                end
                local x1, x2 = px(math.max(bucket, tMin)), px(math.min(bucket + size, tMax))
                local cx, w = (x1 + x2) / 2, math.max(3, (x2 - x1) * 0.62)
                local ccol = close > open and C.good or close < open and C.bad or C.muted
                seg_(cx, py(hi), cx, py(lo), ccol, 1)
                local top, bot = py(math.max(open, close)), py(math.min(open, close))
                local body = new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.fromOffset(cx, top), Size = UDim2.fromOffset(w, math.max(2, bot - top)),
                    BackgroundColor3 = ccol, BorderSizePixel = 0, ZIndex = 23 }, canvas)
                corner(body, 2)
                hover(body, T("candleTip"):format(dateStr(bucket, size >= 86400 and "DD.MM.YYYY" or "DD.MM HH:mm"),
                    env.TV_fmt(open), env.TV_fmt(hi), env.TV_fmt(lo), env.TV_fmt(close), delta(close - open, open)), cx, top)
                bucket += size
            end
        else
            -- линия: заливка под ступеньками и точки с подсказкой
            for k = 1, #hist - 1 do
                local a, b = hist[k], hist[k + 1]
                local x1, x2, y = px(a[1]), px(b[1]), py(a[2])
                new("Frame", { Position = UDim2.fromOffset(x1, y), Size = UDim2.fromOffset(math.max(1, x2 - x1), math.max(0, CH - B_ - y)),
                    BackgroundColor3 = col, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 21 }, canvas)
                seg_(x1, y, x2, y, col, 2)
                if b[2] ~= a[2] then seg_(x2, y, x2, py(b[2]), col, 2) end
            end
            for k = 1, points do
                local pnt = hist[k]
                local x, y = px(pnt[1]), py(pnt[2])
                local hit = new("TextButton", { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y),
                    BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 24 }, canvas)
                corner(new("Frame", { Size = UDim2.fromOffset(7, 7), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                    BackgroundColor3 = col, ZIndex = 25 }, hit), 4)
                local prev = hist[k - 1]
                hover(hit, ("<b>%s</b>%s\n%s"):format(env.TV_fmt(pnt[2]), prev and ("  " .. delta(pnt[2] - prev[2], prev[2])) or "",
                    dateStr(pnt[1], "DD.MM.YYYY HH:mm")), x, y)
            end
        end
        -- текущая цена справа
        local badge = new("TextLabel", { BackgroundColor3 = col, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16),
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(CW - 2, math.clamp(py(cur), 10, CH - B_ - 8)), Text = env.TV_fmt(cur),
            TextColor3 = C.bg, TextSize = 10, Font = Enum.Font.RobotoMono, ZIndex = 26 }, canvas)
        corner(badge, 5)
        pad(badge, 5, 0)

        -- предметы инвентаря: картинка, название xN, цена за штуку и всего
        for _, c in ipairs(listF:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        local items = custom and custom.items
        local trades = custom and custom.trades
        listF.Visible = (items ~= nil and #items > 0) or trades ~= nil
        -- окно «только список» (история трейдов): без графика, список на всю высоту
        local only = custom and custom.listOnly
        canvas.Visible, chips.Visible = not only, not only
        if only then
            listF.Position, listF.Size = UDim2.fromOffset(0, 48), UDim2.fromOffset(CW, CH + LISTH + 40)
            win.Size = UDim2.fromOffset(CW + 32, CH + LISTH + 128)
        else
            listF.Position, listF.Size = UDim2.fromOffset(0, 80 + CH + 8), UDim2.fromOffset(CW, LISTH)
            win.Size = UDim2.fromOffset(CW + 32, CH + 164 + (listF.Visible and (LISTH + 8) or 0))
        end
        local function header(text, order)
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 22), Text = text, TextColor3 = C.text, TextSize = 13,
                Font = fontBold(), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order, ZIndex = 22 }, listF)
        end
        if trades then
            -- история трейдов: когда, с кем, что отдал и что получил, прибыль
            if not only then header(T("histTrades"), 0) end
            if #trades == 0 then
                new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 30), Text = T("histNone"), TextWrapped = true,
                    TextColor3 = C.muted, TextSize = 12, Font = fontReg(), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 22 }, listF)
            end
            local function names(lst)
                local out = {}
                for _, x in ipairs(lst or {}) do table.insert(out, x[1] .. (x[2] > 1 and (" ×" .. x[2]) or "")) end
                return #out > 0 and table.concat(out, ", ") or "—"
            end
            for i, tr in ipairs(trades) do
                local d = tr.th - tr.my
                local pct = tr.my > 0 and math.floor(d / tr.my * 100 + 0.5) or nil
                local col = d > 0 and C.good or d < 0 and C.bad or C.muted
                local r = new("Frame", { Size = UDim2.new(1, -6, 0, 86), BackgroundColor3 = C.card, BackgroundTransparency = 0.4, LayoutOrder = i, ZIndex = 21 }, listF)
                corner(r, 8)
                pad(r, 10, 0)
                new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), RichText = true,
                    Text = ("<b>%s</b>  ·  %s  ·  %s → %s  <font color=\"%s\">%s%s%s</font>"):format((tr.pending and "⏳ " or "") .. tr.p, dateStr(tr.t, "DD.MM HH:mm"),
                        env.TV_fmt(tr.my), env.TV_fmt(tr.th), hex(col), d >= 0 and "+" or "−", env.TV_fmt(math.abs(d)),
                        pct and (" (" .. (pct >= 0 and "+" or "") .. pct .. "%)") or ""),
                    TextColor3 = C.text, TextSize = 12, Font = fontReg(), TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 22 }, r)
                new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 26),
                    Text = T("histGave") .. ": " .. names(tr.gave) .. "   ·   " .. T("histGot") .. ": " .. names(tr.got),
                    TextColor3 = C.muted, TextSize = 11, Font = fontReg(), TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 22 }, r)
                -- картинки: что отдал → что получил
                local strip = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 50), ZIndex = 22 }, r)
                list(strip, Enum.FillDirection.Horizontal, 4)
                local order = 0
                local function icon(x)
                    order += 1
                    local f = new("Frame", { Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, LayoutOrder = order, ZIndex = 22 }, strip)
                    corner(f, 6)
                    local im = new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = "", ZIndex = 23 }, f)
                    im.Image = env.TV_image and env.TV_image(x[1], function(a) if im.Parent then im.Image = a end end) or ""
                    if x[2] > 1 then
                        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 12), Position = UDim2.fromOffset(1, 20), Text = "×" .. x[2],
                            TextColor3 = C.text, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 24 }, f)
                    end
                end
                for k, x in ipairs(tr.gave or {}) do if k <= 4 then icon(x) end end
                order += 1
                new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(22, 32), Text = "→", TextColor3 = C.muted, TextSize = 16,
                    Font = Enum.Font.GothamBold, LayoutOrder = order, ZIndex = 22 }, strip)
                for k, x in ipairs(tr.got or {}) do if k <= 4 then icon(x) end end
            end
            if items and #items > 0 then header(T("histItems"), 500) end
        end
        for i, e in ipairs(items or {}) do
            local r = new("Frame", { Size = UDim2.new(1, -6, 0, 34), BackgroundColor3 = C.card, BackgroundTransparency = 0.4, LayoutOrder = 500 + i, ZIndex = 21 }, listF)
            corner(r, 8)
            local pic = new("ImageLabel", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(4, 3), BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit, Image = "", ZIndex = 22 }, r)
            pic.Image = env.TV_image and env.TV_image(e.name, function(a) if pic.Parent then pic.Image = a end end) or ""
            -- последнее изменение цены (как стрелки в «Таблице цен»): выросла — зелёным, упала — красным
            local ch = (env.TV_changes or {})[e.name]
            local chTxt = ""
            if ch and ch ~= 0 and e.price > 0 then
                local before = e.price - ch
                local pct = before > 0 and math.floor(math.abs(ch) / before * 100 + 0.5) or nil
                chTxt = ('<font color="%s">%s%s%s</font>   '):format(hex(ch > 0 and C.good or C.bad), ch > 0 and "+" or "−",
                    env.TV_fmt(math.abs(ch)), pct and (" (" .. (ch > 0 and "+" or "−") .. pct .. "%)") or "")
            end
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -300, 1, 0), Position = UDim2.fromOffset(40, 0),
                Text = e.name .. (e.count > 1 and ("  ×" .. e.count) or ""), TextColor3 = C.text, TextSize = 13, Font = fontBold(),
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 22 }, r)
            new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(250, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0),
                Text = chTxt .. (e.count > 1 and (env.TV_fmt(e.price) .. " × " .. e.count .. " = ") or "") .. "<b>" .. env.TV_fmt(e.total) .. "</b>",
                RichText = true, TextColor3 = C.muted, TextSize = 12, Font = Enum.Font.RobotoMono, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 22 }, r)
        end

        cTitle.Text = custom and custom.title or T("chartTitle"):format(it.name, env.TV_fmt(it.price or cur))
        cSub.Text = T("chartSince"):format(delta(cur - first, first), dateStr(hist[1][1], "DD.MM.YYYY"), points)
        cNote.Text = custom and custom.note or (points <= 2 and T("chartFew"):format(dateStr(hist[1][1])) or "")
        if only then cSub.Text = custom.sub or "" end
        return true
    end

    env.TV_showChart = function(it, custom)
        last, vZoom = { it, custom }, 1
        if not draw(it, custom) then return end
        win.Visible = true
        local abs = ui.AbsoluteSize
        wscale.Scale = math.min(sf(), (abs.X - 24) / (CW + 32), (abs.Y - 24) / win.Size.Y.Offset)
    end
    local function redraw() if last then draw(last[1], last[2]) end end
    for i, r in ipairs(RANGES) do
        on(chipBtns[i].Activated, function() S.chartRange = r[2]; saveSettings(); redraw() end)
    end
    on(zIn.Activated, function() vZoom = math.min(16, vZoom * 2); redraw() end)
    on(zOut.Activated, function() vZoom = math.max(1 / 4, vZoom / 2); redraw() end)
    -- колесо мыши над графиком: вверх — короче период (ближе), вниз — длиннее
    on(canvas.InputChanged, function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        local idx = 4
        for i, r in ipairs(RANGES) do if r[2] == (S.chartRange or 0) then idx = i end end
        idx = math.clamp(idx + (inp.Position.Z > 0 and -1 or 1), 1, #RANGES)
        S.chartRange = RANGES[idx][2]
        redraw()
    end)
    local function setMode(m)
        S.chartMode = m
        saveSettings()
        if last then draw(last[1], last[2]) end
    end
    on(bLine.Activated, function() setMode("line") end)
    on(bCandle.Activated, function() setMode("candles") end)
end)() -- отдельная функция: у неё свой лимит 200 локальных

------------------------------------------------------------------
-- «Мой инвентарь» (что есть сейчас) и история стоимости инвентаря
------------------------------------------------------------------
;(function()
    local snapAt = 0
    env.TV_invSnapshot = function(seen, mine)
        if os.clock() - snapAt < 2 then return end
        snapAt = os.clock()
        local pets = {}
        for _, it in ipairs(itemsByCat.pets or {}) do pets[it.key] = true end
        local snap, petCount, total = {}, 0, 0
        for _, it in ipairs(seen) do
            local k = norm(it.name)
            snap[k] = it.name
            if pets[k] then petCount += 1 end
            total += (it.price or 0) * (it.amount or 1)
        end
        local offerEmpty = true
        for k, e in pairs(mine and auto.readOffer(mine) or {}) do snap[k] = e.name; offerEmpty = false end
        -- открыта вкладка питомцев — заменяем только питомцев, оружие не трогаем (и наоборот)
        local isPets = petCount * 2 > #seen
        local old, new = S.myInv or {}, {}
        for k, n in pairs(old) do if (pets[k] == true) ~= isPets then new[k] = n end end
        for k, n in pairs(snap) do new[k] = n end
        local changed = false
        for k in pairs(new) do if not old[k] then changed = true; break end end
        if not changed then for k in pairs(old) do if not new[k] then changed = true; break end end end
        if changed then S.myInv = new end
        -- стоимость оружия: пишем, когда мой оффер пуст (иначе часть предметов «в трейде»)
        if not isPets then
            -- что именно лежит в инвентаре (для списка в статистике): название и количество, вместе с тем, что уже в моём оффере
            local items, sig = {}, {}
            for _, it in ipairs(seen) do
                local k = norm(it.name)
                local e = items[k] or { it.name, 0 }
                e[2] += it.amount or 1
                items[k] = e
            end
            for k, e in pairs(mine and auto.readOffer(mine) or {}) do
                local x = items[k] or { e.name, 0 }
                x[2] += e.count
                items[k] = x
            end
            for k, e in pairs(items) do table.insert(sig, k .. "=" .. e[2]) end
            table.sort(sig)
            sig = table.concat(sig, ",")
            -- трейды «на проверке»: инвентарь изменился так, как должен был — значит, трейд состоялся
            if S.tradePending and #S.tradePending > 0 then
                for _, tr in ipairs(S.tradePending) do
                    local ok = false
                    for _, x in ipairs(tr.got or {}) do
                        local k = norm(x[1])
                        if ((items[k] and items[k][2]) or 0) > ((tr.pre or {})[k] or 0) then ok = true end
                    end
                    for _, x in ipairs(tr.gave or {}) do
                        local k = norm(x[1])
                        if ((items[k] and items[k][2]) or 0) < ((tr.pre or {})[k] or 0) then ok = true end
                    end
                    if ok then
                        tr.pre = nil
                        S.tradeLog = S.tradeLog or {}
                        table.insert(S.tradeLog, 1, tr)
                        while #S.tradeLog > 100 do table.remove(S.tradeLog) end
                    end
                end
                table.sort(S.tradeLog or {}, function(a, b) return a.t > b.t end)
                S.tradePending, changed = {}, true -- не подтвердилось — трейда не было
            end
            if sig ~= S.invItemsSig then S.invItems, S.invItemsSig, changed = items, sig, true end
        end
        if not isPets and offerEmpty and total > 0 then
            S.invHist = S.invHist or {}
            local h, now = S.invHist, os.time()
            local last = h[#h]
            if not last or (last[2] ~= total and now - last[1] >= 30) or now - last[1] >= 3600 then
                table.insert(h, { now, total })
                while #h > 300 do table.remove(h, 1) end
                changed = true
            end
        end
        if changed then saveSettings() end
    end

    -- ячейка предмета: лежит в сетке/списке и внутри ровно одно название предмета (ряд с несколькими — не ячейка)
    local function isCell(d, noSize)
        if not ((d:IsA("Frame") or d:IsA("ImageButton") or d:IsA("ImageLabel") or d:IsA("TextButton")) and d.Name ~= "TVPrice") then return false end
        local par = d.Parent
        if not (par and (par:IsA("ScrollingFrame") or par:FindFirstChildWhichIsA("UIGridLayout") or par:FindFirstChildWhichIsA("UIListLayout"))) then return false end
        if not noSize and (d.AbsoluteSize.X < 40 or d.AbsoluteSize.Y < 40) then return false end
        -- раздел («Хэллоуин» с одним предметом) — не ячейка: внутри него своя сетка/прокрутка
        if d:FindFirstChildWhichIsA("UIGridLayout", true) or d:FindFirstChildWhichIsA("ScrollingFrame", true) then return false end
        local n = 0
        for _, l in ipairs(d:GetDescendants()) do
            if l:IsA("TextLabel") and l.Name ~= "TVPrice" and l.Text ~= "" and valueMap[norm(l.Text)] then
                n += 1
                if n > 1 then return false end
            end
        end
        return n == 1
    end
    -- инвентарь MM2 (кнопка INVENTORY): пока он открыт, раз в 3 с записываем, что там лежит и сколько стоит
    local SKIP = { "shop", "store", "crate", "box", "preview", "reward", "spin", "unbox", "craft", "battle", "pass", "trade", "offer", "event" }
    task.spawn(function()
        while ui.Parent do
            task.wait(3)
            pcall(function()
                if not S.enabled then return end
                local roots = {}
                for _, g in ipairs(PlayerGui:GetChildren()) do
                    if g:IsA("ScreenGui") and g.Enabled and g ~= ui and g ~= hlGui and not g.Name:lower():find("trade") then
                        for _, d in ipairs(g:GetDescendants()) do
                            if d:IsA("GuiObject") and d.Name:lower():find("inventory") and env.TV_vis(d) then
                                local path, ok = d:GetFullName():lower(), true
                                for _, w in ipairs(SKIP) do if path:find(w, 1, true) then ok = false; break end end
                                if ok then table.insert(roots, d) end
                            end
                        end
                    end
                end
                -- профиль другого игрока выглядит так же — его не записываем
                local others = {}
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= Players.LocalPlayer then table.insert(others, pl.Name:lower()); table.insert(others, pl.DisplayName:lower()) end
                end
                -- все вкладки («Сезон 1», «Классический», «Праздник»), в том числе скрытые; по каждой сетке — сумма,
                -- по одинаковым сеткам (у MM2 две раскладки окна) — максимум, чтобы не посчитать дважды
                local best = {}
                for _, r in ipairs(roots) do
                    local foreign = false
                    for _, l in ipairs(r:GetDescendants()) do
                        if l:IsA("TextLabel") and l.Text ~= "" and env.TV_vis(l) then
                            local t = l.Text:lower()
                            for _, nm in ipairs(others) do if #nm >= 3 and t:find(nm, 1, true) then foreign = true; break end end
                        end
                        if foreign then break end
                    end
                    if not foreign then
                        local perGrid = {}
                        for _, d in ipairs(r:GetDescendants()) do
                            if isCell(d, true) then
                                local price, amount, name = readItem(d)
                                if price and price > 0 and name then
                                    local g = perGrid[d.Parent] or {}
                                    perGrid[d.Parent] = g
                                    local k = norm(name)
                                    g[k] = g[k] or { name = name, price = price, amount = 0 }
                                    g[k].amount += amount or 1
                                end
                            end
                        end
                        for _, g in pairs(perGrid) do
                            for k, e in pairs(g) do
                                if not best[k] or e.amount > best[k].amount then best[k] = e end
                            end
                        end
                    end
                end
                local seen = {}
                for _, e in pairs(best) do table.insert(seen, { price = e.price, amount = e.amount, name = e.name }) end
                if #seen > 0 then env.TV_invSnapshot(seen, nil) end
            end)
        end
    end)

    -- «Общая цена инвентаря» в окне профиля (и инвентаря): рисуем в своём слое поверх игры,
    -- окно находим по видимым ячейкам или по статистике профиля («Устранения», «Победы», «Выживание»)
    local STAT_WORDS = { "устранени", "eliminations", "kills", "выживани", "survivals", "победы", "wins" }
    local totalLbls = {}
    local function sumWindow(win)
        local perGrid = {}
        for _, d in ipairs(win:GetDescendants()) do
            if isCell(d, true) then
                local price, amount, name = readItem(d)
                if price and price > 0 and name then
                    local grid = perGrid[d.Parent] or {}
                    perGrid[d.Parent] = grid
                    local k = norm(name)
                    grid[k] = grid[k] or { price = price, amount = 0 }
                    grid[k].amount += amount or 1
                end
            end
        end
        local best = {}
        for _, grid in pairs(perGrid) do
            for k, e in pairs(grid) do if not best[k] or e.amount > best[k].amount then best[k] = e end end
        end
        local total, n, top = 0, 0, 0
        for _, e in pairs(best) do total += e.price * e.amount; n += e.amount; if e.price > top then top = e.price end end
        return total, n, top
    end
    local function notFull(o, scr) return o.AbsoluteSize.X < scr.X * 0.9 and o.AbsoluteSize.Y < scr.Y * 0.9 end
    local function showTotals(g)
        -- старые плашки из прошлых версий, вставленные в окна игры, — убираем
        for _, l in ipairs(g:GetDescendants()) do if l.Name == "TVTotal" then l:Destroy() end end
        local scr = ui.AbsoluteSize
        local inset = g.IgnoreGuiInset and 0 or GuiService:GetGuiInset().Y
        local wins = {}
        -- окно профиля: наименьший блок, где есть и статистика игрока, и его ячейки оружия
        -- (размер не важен: на телефоне/BlueStacks окно во весь экран)
        local function hasStat(o)
            for _, l in ipairs(o:GetDescendants()) do
                if l:IsA("TextLabel") and l.Text ~= "" then
                    local t = env.TV_low(l.Text)
                    for _, w in ipairs(STAT_WORDS) do if t:find(w, 1, true) then return true end end
                end
            end
            return false
        end
        local function hasCells(o)
            local n = 0
            for _, d in ipairs(o:GetDescendants()) do
                if isCell(d, true) then n += 1; if n >= 1 then return true end end
            end
            return false
        end
        -- 1) по видимым ячейкам
        local seenWin = {}
        for _, d in ipairs(g:GetDescendants()) do
            if d:IsA("GuiObject") and d.Name ~= "TVPrice" and isCell(d) and env.TV_vis(d) and not seenWin[d.Parent] then
                seenWin[d.Parent] = true
                local o = d.Parent
                for _ = 1, 8 do
                    if not o or o == g or not o:IsA("GuiObject") then o = nil; break end
                    if hasStat(o) then break end
                    o = o.Parent
                end
                if o and o ~= g and o:IsA("GuiObject") and not wins[o] then wins[o] = {} end
            end
        end
        -- 2) по статистике профиля: окно вокруг неё, в котором лежат (пусть скрытые) ячейки предметов
        for _, l in ipairs(g:GetDescendants()) do
            if l:IsA("TextLabel") and l.Text ~= "" and env.TV_vis(l) then
                local t = env.TV_low(l.Text)
                local hit = false
                for _, w in ipairs(STAT_WORDS) do if t:find(w, 1, true) then hit = true; break end end
                if hit then
                    local win, o = nil, l.Parent
                    for _ = 1, 8 do
                        if not o or o == g or not o:IsA("GuiObject") then break end
                        if hasCells(o) then win = o; break end
                        o = o.Parent
                    end
                    if win then
                        local e = wins[win] or {}
                        wins[win] = e
                        -- нижний край блока статистики: под ним пустое место
                        local bottom = l.AbsolutePosition.Y + l.AbsoluteSize.Y
                        if not e.statBottom or bottom > e.statBottom then e.statBottom = bottom end
                    end
                end
            end
        end
        local used = {}
        for win, e in pairs(wins) do
            local total, n, top = sumWindow(win)
            -- чей это профиль: ник игрока в окне — запоминаем его самое дорогое оружие (для авто-предложений)
            if top > 0 then
                for _, l in ipairs(win:GetDescendants()) do
                    if l:IsA("TextLabel") and l.Text ~= "" and env.TV_vis(l) then
                        local nm = l.Text:gsub("'s Weapons$", ""):gsub("^%s+", ""):gsub("%s+$", "")
                        local pl = Players:FindFirstChild(nm)
                        if pl and pl ~= Players.LocalPlayer then
                            S.bestByPlayer = S.bestByPlayer or {}
                            if S.bestByPlayer[pl.Name:lower()] ~= top then S.bestByPlayer[pl.Name:lower()] = top; saveSettings() end
                            break
                        end
                    end
                end
            end
            if total > 0 and (e.statBottom or n >= 3) then -- карточка в списке игроков с одним «предметом» — не окно инвентаря
                local lbl = totalLbls[win]
                if not lbl then
                    lbl = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, TextColor3 = C.text, TextSize = 22, Font = Enum.Font.GothamBold,
                        RichText = true, ZIndex = 60, Text = "" }, ui)
                    corner(lbl, 10)
                    pad(lbl, 16, 0)
                    stroke(lbl, accent(), 0.4)
                    totalLbls[win] = lbl
                end
                local wp, ws = win.AbsolutePosition, win.AbsoluteSize
                local cx = wp.X + ws.X / 2
                local y
                if e.statBottom then
                    -- вкладка «Профиль»: в пустое место под статистикой
                    y = e.statBottom + (wp.Y + ws.Y - e.statBottom) * 0.35
                elseif wp.Y > 50 then
                    y = wp.Y - 46 -- над окном
                else
                    y = wp.Y + 6
                end
                lbl.Position = UDim2.fromOffset(cx, y + inset)
                lbl.Text = ('%s: <font color="%s">%s</font>  ·  %d'):format(T("invTotal"), hex(accent()), env.TV_fmt(total), n)
                lbl.Visible = false -- плашку «Общая цена инвентаря» не показываем (по просьбе); лучшее оружие игрока запоминаем
                used[win] = true
            end
        end
        for win, lbl in pairs(totalLbls) do
            if not used[win] then
                if not (win.Parent and env.TV_vis(win)) then lbl:Destroy(); totalLbls[win] = nil else lbl.Visible = false end
            end
        end
    end

    -- цены прямо на ячейках предметов в экранах MM2 (профиль игрока, инвентарь, «Оружие»): плашка в углу ячейки
    task.spawn(function()
        while ui.Parent do
            task.wait(1.5)
            pcall(function()
                for _, g in ipairs(PlayerGui:GetChildren()) do
                    if g:IsA("ScreenGui") and g.Enabled and g ~= ui and g ~= hlGui and not g.Name:lower():find("trade") then
                        pcall(showTotals, g)
                        for _, d in ipairs(g:GetDescendants()) do
                            local cell = d:IsA("GuiObject") and d.Name ~= "TVPrice" and isCell(d)
                            if cell or (d:IsA("GuiObject") and d:FindFirstChild("TVPrice")) then
                                local badge = d:FindFirstChild("TVPrice")
                                local price, _, iname = nil, nil, nil
                                if cell and S.enabled and env.TV_vis(d) then price, _, iname = readItem(d) end
                                if iname and (env.TV_ambig or {})[norm(iname)] then
                                    -- несколько предметов с этим названием: цену пишем, только если категория известна по картинке
                                    local _, sure = env.TV_cellCat(d, nil)
                                    if not sure then price = nil end
                                end
                                if price and price > 0 then
                                    if not badge then
                                        badge = new("TextLabel", { Name = "TVPrice", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 18),
                                            Position = UDim2.fromOffset(4, 4), BackgroundColor3 = C.bg, BackgroundTransparency = 0.15,
                                            TextColor3 = accent(), TextSize = 13, Font = Enum.Font.GothamBold, ZIndex = (d.ZIndex or 1) + 10, Text = "" }, d)
                                        corner(badge, 6)
                                        pad(badge, 5, 0)
                                    end
                                    local txt = env.TV_fmt(price)
                                    if badge.Text ~= txt then badge.Text = txt end
                                    -- размер — доля самой ячейки (у окон MM2 свой масштаб, пиксели там мелкие), текст заполняет плашку
                                    if not badge.TextScaled then
                                        badge.AutomaticSize = Enum.AutomaticSize.None
                                        badge.Size, badge.Position = UDim2.fromScale(0.5, 0.18), UDim2.fromScale(0.03, 0.03)
                                        badge.TextScaled = true
                                        local pd = badge:FindFirstChildOfClass("UIPadding")
                                        if pd then pd.PaddingLeft, pd.PaddingRight = UDim.new(0.06, 0), UDim.new(0.06, 0) end
                                    end
                                    badge.TextColor3, badge.Visible = accent(), true
                                elseif badge then
                                    badge.Visible = false
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    local function change(h, secs)
        local now, cur = os.time(), h[#h][2]
        local base = h[1][2]
        for _, pnt in ipairs(h) do if pnt[1] <= now - secs then base = pnt[2] end end
        local d = cur - base
        local pct = base > 0 and d / base * 100 or 0
        local col = d > 0 and C.good or d < 0 and C.bad or C.muted
        return ('<font color="%s">%s%s (%s%d%%)</font>'):format(hex(col), d >= 0 and "+" or "-", env.TV_fmt(math.abs(d)),
            pct >= 0 and "+" or "-", math.floor(math.abs(pct) + 0.5))
    end
    -- отдельное окно: история трейдов
    on(X.histOpen.Activated, function()
        local log = S.tradeLog or {}
        local sum = 0
        for _, tr in ipairs(log) do sum += (tr.th or 0) - (tr.my or 0) end
        -- «на проверке» показываем сразу (с ⏳): подтвердятся или пропадут при следующем просмотре инвентаря
        local all = {}
        for _, tr in ipairs(S.tradePending or {}) do
            local c = table.clone(tr)
            c.pending = true
            table.insert(all, c)
        end
        for _, tr in ipairs(log) do table.insert(all, tr) end
        table.sort(all, function(a, b) return (a.t or 0) > (b.t or 0) end)
        env.TV_showChart(nil, { hist = { { os.time(), 0 } }, title = T("histTrades"), listOnly = true, trades = all,
            sub = (#log > 0) and T("histSum"):format(#log, (sum >= 0 and "+" or "−") .. env.TV_fmt(math.abs(sum))) or "",
            note = (#(S.tradePending or {}) > 0) and T("histPending"):format(#S.tradePending) or "" })
    end)
    on(X.statsOpen.Activated, function()
        local h = S.invHist or {}
        if #h == 0 and next(S.invItems or {}) == nil then notify(T("invEmpty")); return end
        if #h == 0 then h = { { os.time(), 0 } } end
        -- список предметов: по сегодняшним ценам, самые дорогие сверху
        local items = {}
        local src = S.invItems
        if not src or next(src) == nil then
            src = {}
            for k, nm in pairs(S.myInv or {}) do src[k] = { nm, 1 } end
        end
        for k, e in pairs(src) do
            local price = valueMap[k] or 0
            table.insert(items, { name = e[1], count = e[2], price = price, total = price * e[2] })
        end
        table.sort(items, function(x, y) return x.total > y.total end)
        env.TV_showChart(nil, { hist = h, title = T("invTitle"):format(env.TV_fmt(h[#h][2])),
            note = T("invNote"):format(change(h, 86400), change(h, 7 * 86400), #h), items = items })
    end)
end)() -- отдельная функция: у неё свой лимит 200 локальных

------------------------------------------------------------------
-- Авто-предложения: раз в 90 с запрос следующему игроку из списка «Нажмите на игрока для обмена»
------------------------------------------------------------------
;(function()
    local sent = {}
    local HINT = { "нажмите на игрока", "click a player", "click on a player" }
    -- текст кнопки целиком (для «Обмен», «^»)
    local function exactBtn(root, words)
        for _, b in ipairs(root:GetDescendants()) do
            if b:IsA("GuiButton") and env.TV_vis(b) and not env.TV_forbidden(b) then
                local t = env.TV_btnText(b):sub(#env.TV_low(b.Name) + 2):gsub("^%s+", ""):gsub("%s+$", "")
                for _, w in ipairs(words) do if t == w then return b end end
            end
        end
    end
    -- список игроков (сверху справа): ScreenGui с подсказкой «Нажмите на игрока для обмена»
    local function listGui()
        for _, g in ipairs(PlayerGui:GetChildren()) do
            if g:IsA("ScreenGui") and g.Enabled and g ~= ui and g ~= hlGui then
                for _, h in ipairs(g:GetDescendants()) do
                    if h:IsA("TextLabel") and env.TV_vis(h) then
                        local t = env.TV_low(h.Text)
                        for _, w in ipairs(HINT) do if t:find(w, 1, true) then return g, h end end
                    end
                end
            end
        end
    end
    local function entries(g)
        local names = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= Players.LocalPlayer then names[pl.Name:lower()] = pl.Name; names[pl.DisplayName:lower()] = pl.Name end
        end
        if not g then
            -- без подсказки: ищем во всех окнах игры то, где больше всего ников (список игроков после «+»)
            local best, bestN
            for _, gg in ipairs(PlayerGui:GetChildren()) do
                if gg:IsA("ScreenGui") and gg.Enabled and gg ~= ui and gg ~= hlGui then
                    local lst = entries(gg)
                    if #lst > 0 and (not bestN or #lst > bestN) then best, bestN = { lst, gg }, #lst end
                end
            end
            if best then return best[1], best[2] end
            return {}, nil
        end
        local out = {}
        for _, l in ipairs(g:GetDescendants()) do
            if (l:IsA("TextLabel") or l:IsA("TextButton")) and env.TV_vis(l) then
                -- «[ELITE] Alinka_676766» — без приставки в скобках; себя в списке нет (names без LocalPlayer)
                local key = l.Text:gsub("^%s*%b[]%s*", ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
                local nm = names[key]
                if nm then table.insert(out, { nm, l }) end
            end
        end
        table.sort(out, function(a, b) return a[2].AbsolutePosition.Y < b[2].AbsolutePosition.Y end)
        return out, g
    end
    -- кнопка «+» рядом с числом игроков на сервере (вверху справа)
    local function plusButton()
        local scr = ui.AbsoluteSize
        local count = tostring(#Players:GetPlayers())
        for _, g in ipairs(PlayerGui:GetChildren()) do
            if g:IsA("ScreenGui") and g.Enabled and g ~= ui and g ~= hlGui then
                for _, l in ipairs(g:GetDescendants()) do
                    if (l:IsA("TextLabel") or l:IsA("TextButton")) and env.TV_vis(l) and l.Text:gsub("%s", "") == count
                       and l.AbsolutePosition.Y < scr.Y * 0.25 and l.AbsolutePosition.X > scr.X * 0.5 then
                        local c = l.AbsolutePosition + l.AbsoluteSize / 2
                        local best, bestD
                        for _, b in ipairs(g:GetDescendants()) do
                            if b:IsA("GuiButton") and env.TV_vis(b) and not env.TV_forbidden(b) then
                                local bc = b.AbsolutePosition + b.AbsoluteSize / 2
                                local dx, dy = c.X - bc.X, math.abs(c.Y - bc.Y)
                                -- «+» левее числа, на той же высоте; кнопка с надписью «+» — в приоритете
                                local t = env.TV_btnText(b):sub(#env.TV_low(b.Name) + 2):gsub("%s", "")
                                if dy < 40 and dx > 5 and dx < 160 then
                                    local d = dx - (t == "+" and 1000 or 0)
                                    if not bestD or d < bestD then best, bestD = b, d end
                                end
                            end
                        end
                        if best then return best, g end
                    end
                end
            end
        end
    end
    local lastWhy, lastWhyAt = nil, 0
    local function why(key, ...)
        if key == lastWhy and os.clock() - lastWhyAt < 60 then return end
        lastWhy, lastWhyAt = key, os.clock()
        notify(T(key):format(...))
    end
    local function rowButton(l)
        local b = l:FindFirstAncestorWhichIsA("GuiButton")
        if b then return b end
        local c = l.AbsolutePosition + l.AbsoluteSize / 2
        for _, x in ipairs((l.Parent and l.Parent.Parent or l.Parent):GetDescendants()) do
            if x:IsA("GuiButton") and env.TV_vis(x) then
                local p0, sz = x.AbsolutePosition, x.AbsoluteSize
                if c.X >= p0.X and c.X <= p0.X + sz.X and c.Y >= p0.Y and c.Y <= p0.Y + sz.Y then return x end
            end
        end
        return l -- сама надпись (clickCell найдёт кнопку внутри или нажмёт мышью)
    end
    task.spawn(function()
        while ui.Parent do
            task.wait(3)
            pcall(function()
                if not (S.enabled and S.outreach) or os.clock() - (env.TV_tradeSeen or -1e9) < 3 then return end
                -- ждём ответа прошлому игроку до 30 с
                if os.clock() - (env.TV_outLast or -1e9) < 30 then return end
                local list, g = entries(listGui())
                if #list == 0 then
                    -- список игроков закрыт — открываем кнопкой «+» возле числа игроков
                    local plus, pg = plusButton()
                    if not plus then why("outNoPlus"); return end
                    clickCell(plus, pg)
                    task.wait(1)
                    list, g = entries(nil)
                    if #list == 0 then
                        -- может, свёрнут — раскрываем «^»
                        local lg = listGui()
                        local arrow = lg and exactBtn(lg, { "^", "˄", "v", "˅", "▲", "▼" })
                        if arrow then clickCell(arrow, lg); task.wait(0.8); list, g = entries(nil) end
                    end
                    if #list == 0 then why("outNoList"); return end
                end
                local anyLeft = false
                for _, e in ipairs(list) do
                    local nm, l = e[1], e[2]
                    if os.clock() - (sent[nm] or -1e9) > 600 and not auto.isBlocked(nm) then
                        anyLeft = true
                        local row = rowButton(l)
                        if row:IsA("GuiButton") and env.TV_forbidden(row) then continue end
                        clickCell(row, g) -- открывается окошко «Профиль / Обмен»
                        task.wait(0.8)
                        local tradeBtn
                        for _, gg in ipairs(PlayerGui:GetChildren()) do
                            if gg:IsA("ScreenGui") and gg.Enabled and gg ~= ui then
                                tradeBtn = exactBtn(gg, { "обмен", "trade", "обменяться" })
                                if tradeBtn then break end
                            end
                        end
                        sent[nm], env.TV_outLast = os.clock(), os.clock()
                        if tradeBtn then
                            env.TV_out = { name = nm, at = os.clock() }
                            clickCell(tradeBtn, g)
                            notify(T("outSent"):format(nm))
                        else
                            -- окошко не появилось — закрываем, если открыто, и пробуем следующего через 3 с
                            local x = exactBtn(g, { "x", "х", "✕" })
                            if x then clickCell(x, g) end
                            env.TV_outLast = os.clock() - 27
                            why("outNoTradeBtn", nm)
                        end
                        return
                    end
                end
                if not anyLeft then why("outAllSent") end
            end)
        end
    end)

    -- трейд с тем, кому мы сами предложили: сразу кладём на его самое дорогое оружие минус цель прибыли;
    -- 10 с ничего не кладёт — отказ; положил — дальше обычный автооффер и автопринятие
    env.TV_outreachTick = function(tg, mine, theirs, my, th)
        local o = env.TV_out
        if not (S.outreach and o and auto.partner and auto.partner:lower() == o.name:lower() and os.clock() - o.at < 120) then return false end
        o.tradeAt = o.tradeAt or os.clock()
        if not o.offered and S.autoAdd and not auto.busy then
            o.offered = true
            local top = (S.bestByPlayer or {})[o.name:lower()]
            local need = top and (top / (1 + env.TV_pct(top) / 100) - my) or 0
            if need >= 1 then
                auto.busy = true
                task.spawn(function()
                    pcall(function()
                        local addBtn = findAddButton(tg)
                        local picks = pickItems(scanInventory(tg, mine, theirs), need, {})
                        local anyHidden = false
                        for _, pk in ipairs(picks) do if not isShown(pk.item.frame) then anyHidden = true end end
                        if anyHidden and addBtn then clickCell(addBtn, tg); task.wait(0.8); picks = pickItems(scanInventory(tg, mine, theirs), need, {}) end
                        for _, pk in ipairs(picks) do
                            for _ = 1, pk.count do
                                if not (pk.item.frame.Parent and isShown(pk.item.frame)) then break end
                                clickCell(pk.item.frame, tg)
                                task.wait(0.35)
                            end
                        end
                        task.wait(0.3)
                        auto.closePicker(tg)
                    end)
                    auto.busy = false
                end)
            end
        end
        if th > 0 then return false end -- он что-то положил: обычный автооффер и автопринятие
        local left = 10 - (os.clock() - o.tradeAt)
        sugLine.Visible = true
        hideHighlights()
        sugText.Text = T("outWait"):format(o.name, math.max(0, math.ceil(left)))
        if left > 0 then return true end
        if os.clock() - (auto.declLast or 0) < 1.5 or (auto.declTries or 0) >= 9 then return true end
        local btn = auto.findDecline(tg)
        if not btn then return true end
        auto.declLast = os.clock()
        auto.declTries = (auto.declTries or 0) + 1
        auto.pressDecline(btn, tg, auto.declTries)
        return true
    end
end)() -- отдельная функция: у неё свой лимит 200 локальных

local function cleanup()
    for _, c in ipairs(conns) do c:Disconnect() end
    if ui then ui:Destroy() end
    if hlGui then hlGui:Destroy() end
end
if env.TV_inst == INST then env.TV_cleanup = cleanup end
task.spawn(function()
    while env.TV_inst == INST do task.wait(1) end
    pcall(cleanup) -- запустили новую копию — эта закрывается
end)
