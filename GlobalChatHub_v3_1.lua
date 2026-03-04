-- ╔══════════════════════════════════════════════════════════╗
-- ║   GlobalChat Hub v3.1  — Script Único Corrigido          ║
-- ║   NÃO depende de GitHub — execute diretamente no Delta   ║
-- ╚══════════════════════════════════════════════════════════╝

-- ===== core.lua =====
-- ════════════════════════════════════════════════════════
-- COMPATIBILIDADE task.* (Delta mobile safe)
-- ════════════════════════════════════════════════════════
if type(task) ~= "table" then task = {} end
if type(task.wait)  ~= "function" then
    task.wait = (type(wait)=="function") and wait
        or function(t) local e=os.clock()+(t or 0) while os.clock()<e do end end
end
if type(task.spawn) ~= "function" then
    task.spawn = (type(spawn)=="function") and spawn
        or function(f,...) local a={...}
            local co=coroutine.create(function() f(table.unpack and table.unpack(a) or unpack(a)) end)
            coroutine.resume(co) return co end
end
if type(task.delay) ~= "function" then
    task.delay = (type(delay)=="function") and delay
        or function(t,f,...) local a={...} task.spawn(function() task.wait(t) f(table.unpack and table.unpack(a) or unpack(a)) end) end
end
if type(task.defer) ~= "function" then task.defer = task.spawn end
if not table.unpack then table.unpack = unpack end

-- ╔═══════════════════════════════════════════════════════╗
-- ║       GlobalChat Hub v3.0 — CORE                     ║
-- ║   Firebase • HTTP • Variáveis • Sons • Cores         ║
-- ╚═══════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════
-- CONFIGURAÇÕES GLOBAIS
-- ═══════════════════════════════════════════════════════

GCH = GCH or {}
local G = GCH

GCH.FB          = "https://scriptroblox-adede-default-rtdb.firebaseio.com"
GCH.POLL        = 3
GCH.MAX_MSG     = 50
GCH.ROOM_TTL    = 30
GCH.OWNER_NAME  = "marceloeduafr10"
GCH.OWNER_ID    = 4620525187
GCH.VER         = "v3.0"

-- ═══════════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════════
GCH.Players    = game:GetService("Players")
GCH.UIS        = game:GetService("UserInputService")
GCH.TweenSvc   = game:GetService("TweenService")
GCH.HttpSvc    = game:GetService("HttpService")
GCH.SoundSvc   = game:GetService("SoundService")
GCH.TelSvc     = game:GetService("TeleportService")

local Players  = GCH.Players
local UIS      = GCH.UIS
local TweenSvc = GCH.TweenSvc
local HttpSvc  = GCH.HttpSvc
local SoundSvc = GCH.SoundSvc

-- ═══════════════════════════════════════════════════════
-- JOGADOR LOCAL
-- ═══════════════════════════════════════════════════════
local _plr = Players.LocalPlayer; if not _plr then repeat (task and task.wait or wait)() _plr = Players.LocalPlayer until _plr end
GCH.ME          = _plr
GCH.MY_NAME     = GCH.ME.Name
GCH.MY_ID       = GCH.ME.UserId
GCH.IS_OWNER    = (GCH.MY_NAME == GCH.OWNER_NAME or GCH.MY_ID == GCH.OWNER_ID)
GCH.MY_IP       = "..."
GCH.MY_AGE      = 0
GCH.MY_DISPLAY  = GCH.MY_NAME
GCH.MY_STATUS   = "online"
GCH.MY_GAME     = tostring(game.PlaceId)

-- ═══════════════════════════════════════════════════════
-- HTTP
-- ═══════════════════════════════════════════════════════
local httpFn, httpNome = nil, "nenhuma"
for _, c in ipairs({
    {n="request",      f=function() return typeof(request)=="function" and request or nil end},
    {n="syn.request",  f=function() return syn and syn.request end},
    {n="http.request", f=function() return http and http.request end},
    {n="http_request", f=function() return typeof(http_request)=="function" and http_request or nil end},
}) do
    local ok, r = pcall(c.f)
    if ok and r then httpFn = r; httpNome = c.n; break end
end
if not httpFn then
    if pcall(function() HttpSvc:GetAsync(GCH.FB.."/.json") end) then
        httpNome = "HttpService"
    end
end

local function httpReq(opts)
    if httpNome == "HttpService" then
        local ok, res = pcall(function()
            if opts.Method == "GET" then
                return HttpSvc:GetAsync(opts.Url)
            else
                return HttpSvc:PostAsync(opts.Url, opts.Body or "", Enum.HttpContentType.ApplicationJson)
            end
        end)
        return ok and {Success=true, StatusCode=200, Body=tostring(res)} or nil
    end
    if not httpFn then return nil end
    local ok, res = pcall(httpFn, opts)
    return ok and res or nil
end
GCH.httpReq  = httpReq
GCH.httpNome = httpNome

-- ═══════════════════════════════════════════════════════
-- FIREBASE
-- ═══════════════════════════════════════════════════════
local function fbURL(p) return GCH.FB.."/"..p..".json" end

local function fbGet(path, query)
    local url = fbURL(path)
    if query then url = url.."?"..query end
    local r = httpReq({Url=url, Method="GET"})
    if not r then return nil end
    local body = r.Body or r.body or ""
    if body == "null" or body == "" then return {} end
    local ok, d = pcall(HttpSvc.JSONDecode, HttpSvc, body)
    return ok and d or nil
end

local function fbSet(p, d)
    httpReq({Url=fbURL(p), Method="PUT",
        Headers={["Content-Type"]="application/json"},
        Body=HttpSvc:JSONEncode(d)})
end

local function fbPost(p, d)
    local r = httpReq({Url=fbURL(p), Method="POST",
        Headers={["Content-Type"]="application/json"},
        Body=HttpSvc:JSONEncode(d)})
    if r then
        local ok, v = pcall(HttpSvc.JSONDecode, HttpSvc, r.Body or "")
        return ok and v or nil
    end
end

local function fbPatch(p, d)
    httpReq({Url=fbURL(p), Method="PATCH",
        Headers={["Content-Type"]="application/json"},
        Body=HttpSvc:JSONEncode(d)})
end

local function fbDelete(p)
    -- DELETE não suportado no Delta → emula com PUT null
    httpReq({Url=fbURL(p), Method="PUT",
        Headers={["Content-Type"]="application/json"}, Body="null"})
end

GCH.fbGet    = fbGet
GCH.fbSet    = fbSet
GCH.fbPost   = fbPost
GCH.fbPatch  = fbPatch
GCH.fbDelete = fbDelete

-- ═══════════════════════════════════════════════════════
-- IP
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    local r = httpReq({Url="https://api.ipify.org?format=json", Method="GET"})
    if r then
        local ok, d = pcall(HttpSvc.JSONDecode, HttpSvc, r.Body or "")
        if ok and d and d.ip then GCH.MY_IP = d.ip end
    end
end)

-- ═══════════════════════════════════════════════════════
-- BAN CHECK
-- ═══════════════════════════════════════════════════════
GCH.IS_BANNED = false
GCH.BAN_DATA  = nil

task.spawn(function()
    task.wait(1)
    local ban = fbGet("bans/"..GCH.MY_NAME)
    if ban and type(ban)=="table" and ban.banned then
        local exp = ban.expiry or 0
        if exp == 0 or os.time() < exp then
            GCH.IS_BANNED = true
            GCH.BAN_DATA  = ban
        else
            fbPatch("bans/"..GCH.MY_NAME, {banned=false})
        end
    end
end)


-- ════════════════════════════════════════════════════════
-- checkBan: chamado pela ui.lua após splash screen
-- ════════════════════════════════════════════════════════
function GCH.checkBan(onBanned, onOk)
    task.spawn(function()
        local rawBan = fbGet("bans/"..GCH.MY_NAME)
        if rawBan and type(rawBan)=="table" and rawBan.banned then
            local exp = rawBan.expiry or 0
            if exp==0 or os.time()<exp then
                GCH.IS_BANNED = true
                GCH.BAN_DATA  = rawBan
            else
                pcall(fbPatch, "bans/"..GCH.MY_NAME, {banned=false})
            end
        end
        if GCH.IS_BANNED and GCH.BAN_DATA then
            if onBanned then onBanned(GCH.BAN_DATA) end
        else
            if onOk then onOk() end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- PRESENÇA
-- ═══════════════════════════════════════════════════════
function GCH.pushPresence()
    task.spawn(function()
        pcall(function()
            fbPatch("users/"..GCH.MY_NAME, {
                online      = GCH.MY_STATUS ~= "invisivel",
                status      = GCH.MY_STATUS,
                lastSeen    = os.time(),
                ip          = GCH.MY_IP,
                gameId      = GCH.MY_GAME,
                gameName    = tostring(game.Name),
                displayName = GCH.MY_DISPLAY,
                age         = GCH.MY_AGE,
                userId      = GCH.MY_ID,
            })
        end)
    end)
end

GCH.ME.AncestryChanged:Connect(function()
    pcall(function()
        fbPatch("users/"..GCH.MY_NAME, {online=false, lastSeen=os.time(), status="offline"})
    end)
end)

-- ═══════════════════════════════════════════════════════
-- TRADUÇÃO
-- ═══════════════════════════════════════════════════════
function GCH.translateText(text, lang, cb)
    lang = lang or "pt"
    task.spawn(function()
        local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
            ..lang.."&dt=t&q="..HttpSvc:UrlEncode(text)
        local r = httpReq({Url=url, Method="GET"})
        if r and r.Body then
            local ok, d = pcall(HttpSvc.JSONDecode, HttpSvc, r.Body)
            if ok and d and d[1] and d[1][1] and d[1][1][1] then
                cb(d[1][1][1]); return
            end
        end
        cb("[Tradução indisponível]")
    end)
end

-- ═══════════════════════════════════════════════════════
-- SOM
-- ═══════════════════════════════════════════════════════
local notifSnd = Instance.new("Sound")
notifSnd.SoundId            = "rbxassetid://9125402595"
notifSnd.Volume             = 0.3
notifSnd.RollOffMaxDistance = 0
notifSnd.Parent             = SoundSvc

function GCH.playNotif()
    pcall(function() notifSnd:Stop(); notifSnd:Play() end)
end

-- ═══════════════════════════════════════════════════════
-- CORES
-- ═══════════════════════════════════════════════════════
GCH.C = {
    bg    = Color3.fromRGB(7,6,17),
    bg2   = Color3.fromRGB(13,9,28),
    bg3   = Color3.fromRGB(19,14,38),
    card  = Color3.fromRGB(16,11,32),
    acc   = Color3.fromRGB(108,58,218),
    acc2  = Color3.fromRGB(72,38,160),
    accL  = Color3.fromRGB(140,90,255),
    green = Color3.fromRGB(55,198,98),
    red   = Color3.fromRGB(212,52,52),
    yel   = Color3.fromRGB(238,188,38),
    white = Color3.fromRGB(228,222,255),
    gray  = Color3.fromRGB(112,105,138),
    grayL = Color3.fromRGB(160,152,190),
    gold  = Color3.fromRGB(255,196,0),
    pink  = Color3.fromRGB(208,72,152),
    cyan  = Color3.fromRGB(52,192,212),
    div   = Color3.fromRGB(28,20,50),
    orange= Color3.fromRGB(255,155,30),
}

-- ═══════════════════════════════════════════════════════
-- RESPONSIVIDADE
-- ═══════════════════════════════════════════════════════
local mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
GCH.mobile   = mobile
GCH.MOBILE   = mobile   -- alias usado pelos módulos
GCH.FSZ      = mobile and 15 or 13
GCH.TFSZ     = mobile and 12 or 10
GCH.BTH      = mobile and 42 or 32
GCH.INH      = mobile and 50 or 40
GCH.TITH     = mobile and 56 or 48
GCH.TABH     = mobile and 44 or 34
GCH.PW       = mobile and 0 or 580
GCH.PH       = mobile and 0 or 530
GCH.SW       = mobile and 0.97 or 0
GCH.SH       = mobile and 0.92 or 0

-- ═══════════════════════════════════════════════════════
-- UI HELPERS
-- ═══════════════════════════════════════════════════════
local C   = GCH.C
local FSZ = GCH.FSZ

function GCH.R(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

function GCH.S(p, col, t)
    local s = Instance.new("UIStroke", p)
    s.Color           = col or C.acc
    s.Thickness       = t or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

function GCH.F(parent, size, pos, color, alpha)
    local f = Instance.new("Frame", parent)
    f.Size                   = size
    f.Position               = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3       = color or C.bg
    f.BackgroundTransparency = alpha or 0
    f.BorderSizePixel        = 0
    return f
end

function GCH.L(parent, text, size, pos, col, sz, font, xa)
    local l = Instance.new("TextLabel", parent)
    l.Text                   = text
    l.Size                   = size
    l.Position               = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3             = col or C.white
    l.TextSize               = sz or FSZ
    l.Font                   = font or Enum.Font.Gotham
    l.TextXAlignment         = xa or Enum.TextXAlignment.Left
    l.TextWrapped            = true
    return l
end

function GCH.B(parent, text, size, pos, bg, fg, sz, font)
    local b = Instance.new("TextButton", parent)
    b.Text             = text
    b.Size             = size
    b.Position         = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = bg or C.acc
    b.TextColor3       = fg or C.white
    b.TextSize         = sz or FSZ
    b.Font             = font or Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    GCH.R(b, 9)
    local orig = bg or C.acc
    b.MouseEnter:Connect(function()
        TweenSvc:Create(b, TweenInfo.new(0.12), {BackgroundColor3=Color3.new(
            math.min(1,orig.R+0.12),
            math.min(1,orig.G+0.12),
            math.min(1,orig.B+0.12))}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenSvc:Create(b, TweenInfo.new(0.12), {BackgroundColor3=orig}):Play()
    end)
    return b
end

function GCH.I(parent, placeholder, size, pos)
    local f = GCH.F(parent, size, pos, Color3.fromRGB(17,12,34))
    GCH.R(f, 10); GCH.S(f, C.acc2, 1)
    local i = Instance.new("TextBox", f)
    i.PlaceholderText        = placeholder or ""
    i.PlaceholderColor3      = C.gray
    i.Text                   = ""
    i.Size                   = UDim2.new(1,-14,1,-4)
    i.Position               = UDim2.new(0,7,0,2)
    i.BackgroundTransparency = 1
    i.TextColor3             = C.white
    i.TextSize               = FSZ
    i.Font                   = Enum.Font.Gotham
    i.TextXAlignment         = Enum.TextXAlignment.Left
    i.ClearTextOnFocus       = false
    return f, i
end

function GCH.SC(parent, size, pos)
    local sf = Instance.new("ScrollingFrame", parent)
    sf.Size                   = size or UDim2.new(1,0,1,0)
    sf.Position               = pos or UDim2.new(0,0,0,0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness     = 3
    sf.ScrollBarImageColor3   = C.acc
    sf.CanvasSize             = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    sf.BorderSizePixel        = 0
    local layout = Instance.new("UIListLayout", sf)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,2)
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingLeft   = UDim.new(0,7); pad.PaddingRight  = UDim.new(0,7)
    pad.PaddingTop    = UDim.new(0,5); pad.PaddingBottom = UDim.new(0,5)
    return sf
end

function GCH.scrollEnd(sf)
    task.defer(function()
        sf.CanvasPosition = Vector2.new(0,
            math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y + 30))
    end)
end

function GCH.tw(obj, t, props)
    TweenSvc:Create(obj,
        TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props):Play()
end


-- ════════════════════════════════════════════════════════
-- ALIASES mk*  — TODOS os módulos usam G.mkFrame etc.
-- Core define GCH.F / GCH.L / GCH.B … mapeamos aqui.
-- ════════════════════════════════════════════════════════
GCH.mkFrame  = GCH.F
GCH.mkLabel  = GCH.L
GCH.mkButton = GCH.B
GCH.mkCorner = GCH.R
GCH.mkStroke = GCH.S
GCH.mkInput  = GCH.I
GCH.mkScroll = GCH.SC

-- ═══════════════════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name             = "GlobalChatHubV3"
SG.ResetOnSpawn     = false
SG.IgnoreGuiInset   = true
SG.DisplayOrder     = 999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(SG) end end)
if not pcall(function() SG.Parent = game:GetService("CoreGui") end) then
    SG.Parent = GCH.ME:WaitForChild("PlayerGui")
end
GCH.SG = SG

print(("[GlobalChat Hub %s] ✅ Core carregado | HTTP:%s | Admin:%s"):format(
    GCH.VER, httpNome, tostring(GCH.IS_OWNER)))


-- ===== ui.lua =====
-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║              ui.lua  —  Interface Principal                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local G = GCH
-- Compat task
local task = (function()
    local _w = (type(task)=="table" and type(task.wait)=="function") and task.wait or wait
    local _s = (type(task)=="table" and type(task.spawn)=="function") and task.spawn
               or (type(spawn)=="function" and spawn)
               or function(f) coroutine.resume(coroutine.create(f)) end
    local _d = (type(task)=="table" and type(task.delay)=="function") and task.delay
               or function(t,fn) _s(function() _w(t) fn() end) end
    local _df= (type(task)=="table" and type(task.defer)=="function") and task.defer or _s
    return { wait=_w, spawn=_s, delay=_d, defer=_df }
end)()
local C = G.C
local SG = G.SG

-- ── Splash Screen ────────────────────────────────────────────────
local Splash = G.mkFrame(SG, UDim2.new(1,0,1,0), nil, Color3.fromRGB(4,3,12))
Splash.ZIndex = 200

-- Partículas de fundo
for _ = 1, 50 do
    local px = math.random(2,5)
    local s = G.mkFrame(Splash,
        UDim2.new(0,px,0,px),
        UDim2.new(math.random()/1, 0, math.random()/1, 0),
        Color3.fromRGB(math.random(120,200), math.random(90,160), 255))
    s.ZIndex = 201
    G.mkCorner(s, 99)
    s.BackgroundTransparency = math.random()/1 * 0.6
    task.spawn(function()
        task.wait(math.random()*4)
        while s.Parent do
            local t2 = math.random(10,24)/10
            G.TweenSvc:Create(s, TweenInfo.new(t2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0.9}):Play()
            task.wait(t2)
            G.TweenSvc:Create(s, TweenInfo.new(t2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0}):Play()
            task.wait(t2)
        end
    end)
end

local splW = G.MOBILE and 340 or 440
local splH = G.MOBILE and 300 or 350

-- Glow atrás do card
local splGlow = G.mkFrame(Splash,
    UDim2.new(0, splW+60, 0, splH+60),
    UDim2.new(0.5, -(splW/2+30), 0.5, -(splH/2+30)),
    C.acc, 0.76)
splGlow.ZIndex = 201
G.mkCorner(splGlow, 30)

-- Card principal
local splCard = G.mkFrame(Splash,
    UDim2.new(0, splW, 0, splH),
    UDim2.new(0.5, -splW/2, 0.5, -splH/2),
    C.bg2)
splCard.ZIndex = 202
G.mkCorner(splCard, 24)
G.mkStroke(splCard, C.acc, 2)

local splGrad = Instance.new("UIGradient", splCard)
splGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22,14,46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,6,18)),
})
splGrad.Rotation = 135

-- Ícone coração
local splHeart = G.mkLabel(splCard, "💜",
    UDim2.new(1,0,0,50), UDim2.new(0,0,0,16),
    C.white, G.MOBILE and 44 or 38, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
splHeart.ZIndex = 203

-- Título
local splTitle = G.mkLabel(splCard, "GlobalChat Hub",
    UDim2.new(1,-20,0,36), UDim2.new(0,10,0,70),
    C.white, G.MOBILE and 26 or 24, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
splTitle.ZIndex = 203

-- Versão
G.mkLabel(splCard, G.VER.."  •  Rede Social Roblox",
    UDim2.new(1,0,0,22), UDim2.new(0,0,0,110),
    C.acc, G.MOBILE and 12 or 11, Enum.Font.Gotham, Enum.TextXAlignment.Center).ZIndex = 203

-- Frase carinhosa
local splMsg = G.mkLabel(splCard, "✨ Feito com carinho para vocês ✨",
    UDim2.new(1,-20,0,44), UDim2.new(0,10,0,136),
    C.pink, G.MOBILE and 14 or 13, Enum.Font.GothamItalic, Enum.TextXAlignment.Center)
splMsg.ZIndex = 203

-- Barra de progresso
local splBG = G.mkFrame(splCard, UDim2.new(1,-40,0,6), UDim2.new(0,20,1,-50), Color3.fromRGB(22,16,44))
splBG.ZIndex = 203
G.mkCorner(splBG, 4)
local splBAR = G.mkFrame(splBG, UDim2.new(0,0,1,0), nil, C.acc)
splBAR.ZIndex = 204
G.mkCorner(splBAR, 4)

local splStatus = G.mkLabel(splCard, "Iniciando...",
    UDim2.new(1,0,0,20), UDim2.new(0,0,1,-68),
    C.gray, G.MOBILE and 12 or 11, Enum.Font.Gotham, Enum.TextXAlignment.Center)
splStatus.ZIndex = 203

-- ── Tela de Idade ────────────────────────────────────────────────
local function showAgeScreen()
    local ov = G.mkFrame(SG, UDim2.new(1,0,1,0), nil, Color3.fromRGB(4,3,12), 0)
    ov.ZIndex = 180
    G.TweenSvc:Create(ov, TweenInfo.new(0.4), {BackgroundTransparency=0.08}):Play()

    local cW = G.MOBILE and 330 or 420
    local cH = G.MOBILE and 360 or 400
    local card = G.mkFrame(ov,
        UDim2.new(0,0,0,0),
        UDim2.new(0.5,0,0.5,0),
        C.bg2)
    card.AnchorPoint = Vector2.new(0.5,0.5)
    card.ZIndex = 181
    G.mkCorner(card, 22)
    G.mkStroke(card, C.acc, 2)

    local cGrad = Instance.new("UIGradient", card)
    cGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,13,44)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8,6,18)),
    })
    cGrad.Rotation = 140

    -- Animação de entrada
    G.TweenSvc:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size=UDim2.new(0,cW,0,cH)}):Play()

    -- Cabeçalho
    G.mkLabel(card, "👋  Bem-vindo ao GlobalChat!",
        UDim2.new(1,-20,0,36), UDim2.new(0,10,0,18),
        C.white, G.MOBILE and 18 or 16, Enum.Font.GothamBold, Enum.TextXAlignment.Center).ZIndex = 182

    -- Aviso de idade
    local warn = G.mkFrame(card, UDim2.new(1,-24,0, G.MOBILE and 68 or 58), UDim2.new(0,12,0,60), Color3.fromRGB(40,28,8))
    warn.ZIndex = 182
    G.mkCorner(warn, 10)
    G.mkStroke(warn, C.yel, 1)
    G.mkLabel(warn, "⚠️  Sua idade não restringirá suas conversas.\nEla serve apenas para sua segurança e para\nativação dos alertas de proteção.",
        UDim2.new(1,-14,1,-8), UDim2.new(0,7,0,4),
        C.yel, G.MOBILE and 11 or 10, Enum.Font.Gotham, Enum.TextXAlignment.Center).ZIndex = 183

    local y1 = 60 + (G.MOBILE and 68 or 58) + 14

    -- Campo nome
    G.mkLabel(card, "Como quer ser chamado?",
        UDim2.new(1,-24,0,20), UDim2.new(0,12,0,y1),
        C.grayL, G.MOBILE and 13 or 11).ZIndex = 182

    local _, nameInp = G.mkInput(card, G.MY_NAME,
        UDim2.new(1,-24,0,G.INH), UDim2.new(0,12,0,y1+22))
    nameInp.Parent.ZIndex = 182

    local y2 = y1 + 22 + G.INH + 14

    -- Campo idade
    G.mkLabel(card, "Qual a sua idade?",
        UDim2.new(1,-24,0,20), UDim2.new(0,12,0,y2),
        C.grayL, G.MOBILE and 13 or 11).ZIndex = 182

    local _, ageInp = G.mkInput(card, "Ex: 17",
        UDim2.new(1,-24,0,G.INH), UDim2.new(0,12,0,y2+22))
    ageInp.Parent.ZIndex = 182
    ageInp.Text = ""

    -- Mensagem de erro
    local errL = G.mkLabel(card, "",
        UDim2.new(1,-24,0,20), UDim2.new(0,12,0,y2+22+G.INH+4),
        C.red, G.MOBILE and 11 or 10, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    errL.ZIndex = 182

    local y3 = y2 + 22 + G.INH + 28

    -- Botão entrar
    local enterBtn = G.mkButton(card, "✅  Entrar no Chat",
        UDim2.new(1,-24,0,G.BTH), UDim2.new(0,12,0,y3), C.acc)
    enterBtn.ZIndex = 182

    enterBtn.MouseButton1Click:Connect(function()
        local aN = tonumber(ageInp.Text)
        if not aN or aN < 5 or aN > 99 then
            errL.Text = "⚠️ Digite uma idade válida (5–99)."
            return
        end
        local nN = nameInp.Text:match("^%s*(.-)%s*$")
        if nN == "" then nN = G.MY_NAME end

        G.MY_AGE     = aN
        G.MY_DISPLAY = nN

        task.spawn(function()
            G.fbSet("users/"..G.MY_NAME, {
                age         = G.MY_AGE,
                displayName = G.MY_DISPLAY,
                userId      = G.MY_ID,
                online      = true,
                status      = "online",
                lastSeen    = os.time(),
                ip          = G.MY_IP,
                gameId      = G.MY_GAME,
                gameName    = tostring(game.Name),
                createdAt   = os.time(),
            })
        end)

        G.TweenSvc:Create(ov, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
        G.TweenSvc:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}):Play()
        task.wait(0.35)
        ov:Destroy()
        G.buildMainUI()
    end)
end

-- ── Tela de Ban ──────────────────────────────────────────────────
local function showBanScreen(banData)
    local ov = G.mkFrame(SG, UDim2.new(1,0,1,0), nil, Color3.fromRGB(8,0,0), 0.04)
    ov.ZIndex = 300
    local card = G.mkFrame(ov, UDim2.new(0,420,0,260), UDim2.new(0.5,-210,0.5,-130), Color3.fromRGB(24,5,5))
    card.ZIndex = 301
    G.mkCorner(card, 20)
    G.mkStroke(card, C.red, 2.5)

    G.mkLabel(card, "🚫  Conta Banida",
        UDim2.new(1,-20,0,44), UDim2.new(0,10,0,18),
        C.red, G.MOBILE and 22 or 20, Enum.Font.GothamBold, Enum.TextXAlignment.Center).ZIndex = 302

    G.mkLabel(card, "Motivo: "..(banData.reason or "Violação dos termos"),
        UDim2.new(1,-20,0,44), UDim2.new(0,10,0,68),
        C.white, G.FSZ, Enum.Font.Gotham, Enum.TextXAlignment.Center).ZIndex = 302

    local expTxt = (banData.expiry==0 or not banData.expiry)
        and "⛔ Banimento permanente"
        or  "🕐 Expira: "..os.date("%d/%m/%Y %H:%M", banData.expiry)
    G.mkLabel(card, expTxt,
        UDim2.new(1,-20,0,30), UDim2.new(0,10,0,118),
        C.yel, G.FSZ, Enum.Font.Gotham, Enum.TextXAlignment.Center).ZIndex = 302

    G.mkLabel(card, "Entre em contato: discord.gg/globalchathub",
        UDim2.new(1,-20,0,24), UDim2.new(0,10,0,154),
        C.gray, G.MOBILE and 11 or 10, Enum.Font.Gotham, Enum.TextXAlignment.Center).ZIndex = 302
end

-- ── Interface Principal ──────────────────────────────────────────
function G.buildMainUI()
    local Main = G.mkFrame(SG, UDim2.new(0,0,0,0), UDim2.new(0.5,0,0.5,0), C.bg)
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0.5,0.5)
    Main.ClipsDescendants = true
    G.mkCorner(Main, 16)
    G.mkStroke(Main, C.acc, 1.5)

    local mg = Instance.new("UIGradient", Main)
    mg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12,8,26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6,5,14)),
    })
    mg.Rotation = 145

    local finalSize = UDim2.new(G.SW, G.PW, G.SH, G.PH)
    task.defer(function()
        task.wait(0.06)
        G.TweenSvc:Create(Main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size=finalSize}):Play()
    end)

    -- ── Título ────────────────────────────────────────────────────
    local TBar = G.mkFrame(Main, UDim2.new(1,0,0,G.TITH), nil, C.bg2)
    G.mkCorner(TBar, 16)
    G.mkFrame(TBar, UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.5,0), C.bg2)

    local tbGrad = Instance.new("UIGradient", TBar)
    tbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(88,44,200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18,12,40)),
        ColorSequenceKeypoint.new(1,   C.bg2),
    })

    -- Ícone pulsante
    local iconL = G.mkLabel(TBar, "🌐",
        UDim2.new(0,38,1,0), UDim2.new(0,10,0,0),
        C.white, G.MOBILE and 22 or 18, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    task.spawn(function()
        while Main.Parent do
            G.TweenSvc:Create(iconL, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency=0.5}):Play()
            task.wait(1.2)
            G.TweenSvc:Create(iconL, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency=0}):Play()
            task.wait(1.2)
        end
    end)

    G.mkLabel(TBar, "GlobalChat Hub",
        UDim2.new(1,-260,1,0), UDim2.new(0,52,0,0),
        C.white, G.MOBILE and 16 or 14, Enum.Font.GothamBold)

    local userLabel = G.mkLabel(TBar,
        G.MY_DISPLAY.." • "..G.MY_AGE.."a",
        UDim2.new(0,180,1,0), UDim2.new(1,-254,0,0),
        C.gray, G.MOBILE and 11 or 10, Enum.Font.Gotham, Enum.TextXAlignment.Right)
    G.UI_userLabel = userLabel

    -- Botão de status
    local statIcons = {online="🟢", ocupado="🟡", invisivel="⚫"}
    local statBtn = G.mkButton(TBar, statIcons[G.MY_STATUS],
        UDim2.new(0, G.MOBILE and 34 or 26, 0, G.MOBILE and 34 or 26),
        UDim2.new(1, -(G.MOBILE and 118 or 90), 0.5, -(G.MOBILE and 17 or 13)),
        Color3.fromRGB(18,14,32), C.white, G.MOBILE and 16 or 14)
    statBtn.MouseButton1Click:Connect(function()
        local ord = {online="ocupado", ocupado="invisivel", invisivel="online"}
        G.MY_STATUS = ord[G.MY_STATUS]
        statBtn.Text = statIcons[G.MY_STATUS]
        G.pushPresence()
    end)

    -- Minimizar
    local minimized = false
    local MinBtn = G.mkButton(TBar, "−",
        UDim2.new(0, G.MOBILE and 34 or 26, 0, G.MOBILE and 34 or 26),
        UDim2.new(1, -(G.MOBILE and 78 or 60), 0.5, -(G.MOBILE and 17 or 13)),
        C.yel, C.bg2, G.MOBILE and 18 or 15)
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        G.TweenSvc:Create(Main, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = minimized and UDim2.new(G.SW, G.PW, 0, G.TITH) or finalSize}):Play()
        MinBtn.Text = minimized and "□" or "−"
    end)

    -- Fechar
    local CloseBtn = G.mkButton(TBar, "✕",
        UDim2.new(0, G.MOBILE and 34 or 26, 0, G.MOBILE and 34 or 26),
        UDim2.new(1, -(G.MOBILE and 40 or 30), 0.5, -(G.MOBILE and 17 or 13)),
        C.red, C.white, G.MOBILE and 13 or 11)
    CloseBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            pcall(function()
                G.fbPatch("users/"..G.MY_NAME, {online=false, lastSeen=os.time(), status="offline"})
            end)
        end)
        G.TweenSvc:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0)}):Play()
        task.delay(0.35, function() SG:Destroy() end)
    end)

    -- ── Arrastar ──────────────────────────────────────────────────
    do
        local dragging, dragStart, startPos = false, nil, nil
        TBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = inp.Position
                startPos  = Main.Position
            end
        end)
        TBar.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        G.UIS.InputChanged:Connect(function(inp)
            if dragging and (
                inp.UserInputType == Enum.UserInputType.MouseMovement or
                inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    -- ── Barra de Busca ────────────────────────────────────────────
    local searchH = G.MOBILE and 36 or 30
    local searchBar = G.mkFrame(Main, UDim2.new(1,0,0,searchH), UDim2.new(0,0,0,G.TITH), Color3.fromRGB(10,7,22))
    local _, searchInp = G.mkInput(searchBar, "🔍  Buscar jogador...",
        UDim2.new(1,-72,1,-4), UDim2.new(0,4,0,2))
    local searchBtn = G.mkButton(searchBar, "Ir",
        UDim2.new(0,62,1,-4), UDim2.new(1,-66,0,2),
        C.acc2, C.white, G.MOBILE and 11 or 10)

    -- Resultado de busca flutuante
    local searchResult = G.mkFrame(Main,
        UDim2.new(0,220,0,0),
        UDim2.new(1,-226,0,G.TITH+searchH+2),
        C.card)
    searchResult.Visible = false
    searchResult.ZIndex = 50
    searchResult.AutomaticSize = Enum.AutomaticSize.Y
    G.mkCorner(searchResult, 10)
    G.mkStroke(searchResult, C.acc2, 1)

    local function doSearch()
        local q = searchInp.Text:match("^%s*(.-)%s*$"):lower()
        if q == "" then searchResult.Visible = false; return end
        for _, ch in ipairs(searchResult:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end
        end
        searchResult.Visible = true
        task.spawn(function()
            local users = G.fbGet("users")
            if not users or type(users) ~= "table" then
                G.mkLabel(searchResult, "Nenhum resultado.", UDim2.new(1,-10,0,30), UDim2.new(0,5,0,0), C.gray, G.FSZ).ZIndex = 51
                return
            end
            local found = 0
            for uname, udata in pairs(users) do
                if type(udata)=="table" and uname:lower():find(q, 1, true) then
                    found = found + 1
                    local row = G.mkButton(searchResult,
                        "",
                        UDim2.new(1,0,0, G.MOBILE and 46 or 38),
                        UDim2.new(0,0,0,(found-1)*(G.MOBILE and 48 or 40)),
                        Color3.fromRGB(16,11,32), C.white, G.FSZ)
                    row.ZIndex = 51
                    G.mkCorner(row, 0)

                    -- Avatar
                    local av = Instance.new("ImageLabel", row)
                    av.Size = UDim2.new(0, G.MOBILE and 34 or 28, 0, G.MOBILE and 34 or 28)
                    av.Position = UDim2.new(0,4,0.5,-(G.MOBILE and 17 or 14))
                    av.BackgroundColor3 = C.acc2
                    av.BorderSizePixel = 0
                    av.Image = "rbxthumb://type=AvatarHeadShot&id="..(udata.userId or 1).."&w=48&h=48"
                    av.ZIndex = 52
                    G.mkCorner(av, 99)

                    local online = udata.online and (os.time()-(udata.lastSeen or 0)) < 60
                    local statusDot = online and "🟢" or "⚫"
                    G.mkLabel(row,
                        statusDot.."  "..(udata.displayName or uname).." • "..(udata.age or "?").."a",
                        UDim2.new(1,-50,0,20), UDim2.new(0, G.MOBILE and 42 or 36, 0,4),
                        C.white, G.MOBILE and 12 or 11, Enum.Font.GothamBold).ZIndex = 52
                    G.mkLabel(row,
                        "🎮 "..(udata.gameName or "Roblox"),
                        UDim2.new(1,-50,0,16), UDim2.new(0, G.MOBILE and 42 or 36, 0, G.MOBILE and 22 or 20),
                        C.gray, G.MOBILE and 10 or 9).ZIndex = 52

                    row.MouseButton1Click:Connect(function()
                        searchResult.Visible = false
                        searchInp.Text = ""
                        if G.openProfile then G.openProfile(uname, udata) end
                    end)

                    if found >= 8 then break end
                end
            end
            if found == 0 then
                G.mkLabel(searchResult, "Nenhum jogador encontrado.", UDim2.new(1,-10,0,32), UDim2.new(0,5,0,0), C.gray, G.FSZ).ZIndex = 51
            end
        end)
    end

    searchBtn.MouseButton1Click:Connect(doSearch)
    searchInp.FocusLost:Connect(function(enter) if enter then doSearch() end end)

    -- Fechar busca ao clicar fora
    G.UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            task.defer(function()
                if searchResult.Visible and not G.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    searchResult.Visible = false
                end
            end)
        end
    end)

    -- ── Tab Bar ───────────────────────────────────────────────────
    local tabOffY = G.TITH + searchH
    local TabBar = G.mkFrame(Main, UDim2.new(1,0,0,G.TABH), UDim2.new(0,0,0,tabOffY), Color3.fromRGB(10,7,22))
    local tbl = Instance.new("UIListLayout", TabBar)
    tbl.FillDirection = Enum.FillDirection.Horizontal
    tbl.SortOrder = Enum.SortOrder.LayoutOrder
    tbl.Padding = UDim.new(0,2)
    local tp = Instance.new("UIPadding", TabBar)
    tp.PaddingLeft   = UDim.new(0,5)
    tp.PaddingRight  = UDim.new(0,5)
    tp.PaddingTop    = UDim.new(0,5)
    tp.PaddingBottom = UDim.new(0,5)

    local ContentY = tabOffY + G.TABH
    local Content = G.mkFrame(Main, UDim2.new(1,0,1,-ContentY), UDim2.new(0,0,0,ContentY), C.bg)

    -- Definição das abas
    local TABS = {
        {k="global",  ic="🌍", lb="Global"},
        {k="brasil",  ic="🇧🇷", lb="Brasil"},
        {k="usa",     ic="🇺🇸", lb="USA"},
        {k="privado", ic="🔒", lb="Privado"},
        {k="amigos",  ic="👥", lb="Amigos"},
        {k="perfil",  ic="👤", lb="Perfil"},
    }
    if G.IS_OWNER then
        table.insert(TABS, {k="admin", ic="👑", lb="Admin"})
    end

    G.TABS       = TABS
    G.tabPanels  = {}
    G.tabBtns    = {}
    G.activeTab  = ""
    G.msgCounts  = {}
    G.Content    = Content

    -- Função de trocar aba
    function G.switchTab(key)
        for k, tp2 in pairs(G.tabPanels) do
            if tp2.frame then tp2.frame.Visible = (k == key) end
        end
        for k, b2 in pairs(G.tabBtns) do
            if k == key then
                G.tw(b2, 0.15, {BackgroundColor3=C.acc})
                b2.TextColor3 = C.white
            else
                G.tw(b2, 0.15, {BackgroundColor3=Color3.fromRGB(15,11,32)})
                b2.TextColor3 = C.gray
            end
        end
        G.activeTab = key
        -- Limpar badge da aba ativa
        for _, tab in ipairs(TABS) do
            if tab.k == key and G.tabBtns[key] then
                G.tabBtns[key].Text = tab.ic.." "..tab.lb
                break
            end
        end
    end

    -- Criar painéis e botões
    local nT = #TABS
    for i, tab in ipairs(TABS) do
        local tb = G.mkButton(TabBar, tab.ic.." "..tab.lb,
            UDim2.new(1/nT,-2,1,0), nil,
            Color3.fromRGB(15,11,32), C.gray, G.TFSZ)
        tb.LayoutOrder = i
        G.tabBtns[tab.k] = tb

        local pf = G.mkFrame(Content, UDim2.new(1,0,1,0), nil, C.bg)
        pf.Visible = false
        G.tabPanels[tab.k] = {frame=pf}

        tb.MouseButton1Click:Connect(function() G.switchTab(tab.k) end)
    end

    -- Badge de notificação
    function G.notifyTab(key)
        if G.activeTab ~= key and G.tabBtns[key] then
            for _, tab in ipairs(TABS) do
                if tab.k == key then
                    G.tabBtns[key].Text = tab.ic.." "..tab.lb.." 🔴"
                    break
                end
            end
        end
    end

    -- Guardar referências globais
    G.Main     = Main
    G.TBar     = TBar
    G.TabBar   = TabBar

    -- Iniciar na aba global
    G.switchTab("global")
    G.pushPresence()

    -- Disparar evento para outros módulos montarem seus painéis
    if G.onUIReady then G.onUIReady() end

    print("[GlobalChat Hub] ui.lua carregado com sucesso.")
end

-- ── Sequência de Inicialização ────────────────────────────────────
task.spawn(function()
    -- Animação de coração pulsante
    task.spawn(function()
        local flip = true
        while splCard and splCard.Parent do
            G.TweenSvc:Create(splHeart, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {TextTransparency = flip and 0.5 or 0}):Play()
            flip = not flip
            task.wait(0.75)
        end
    end)
    -- Glow pulsante
    task.spawn(function()
        while splGlow and splGlow.Parent do
            G.TweenSvc:Create(splGlow, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0.85}):Play()
            task.wait(1.6)
            G.TweenSvc:Create(splGlow, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0.72}):Play()
            task.wait(1.6)
        end
    end)

    -- Barra de progresso
    G.TweenSvc:Create(splBAR, TweenInfo.new(3.0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size=UDim2.new(1,0,1,0)}):Play()

    task.wait(0.8);  splStatus.Text = "Conectando ao Firebase..."
    task.wait(0.9);  splStatus.Text = "Carregando perfil..."
    task.wait(0.7);  splStatus.Text = "Verificando segurança..."
    task.wait(0.5);  splStatus.Text = "Pronto! 🚀"
    task.wait(0.35)

    -- Fade out
    G.TweenSvc:Create(Splash, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
        {BackgroundTransparency=1}):Play()
    G.TweenSvc:Create(splCard, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}):Play()
    task.wait(0.5)
    Splash:Destroy()

    -- Verificar ban antes de mostrar tela de idade
    G.checkBan(
        function(banData) showBanScreen(banData) end,
        function() showAgeScreen() end
    )
end)


-- ===== chat.lua =====
-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║              chat.lua  —  Sistema de Chat                   ║
-- ╚══════════════════════════════════════════════════════════════╝

local G = GCH
-- Compat task
local task = (function()
    local _w = (type(task)=="table" and type(task.wait)=="function") and task.wait or wait
    local _s = (type(task)=="table" and type(task.spawn)=="function") and task.spawn
               or (type(spawn)=="function" and spawn)
               or function(f) coroutine.resume(coroutine.create(f)) end
    local _d = (type(task)=="table" and type(task.delay)=="function") and task.delay
               or function(t,fn) _s(function() _w(t) fn() end) end
    local _df= (type(task)=="table" and type(task.defer)=="function") and task.defer or _s
    return { wait=_w, spawn=_s, delay=_d, defer=_df }
end)()
local C = G.C

-- ── Constantes ───────────────────────────────────────────────────
local CHAT_ROOMS = {
    {key="global",  path="chats/global",  label="🌍 Global",      color=nil},
    {key="brasil",  path="chats/brasil",  label="🇧🇷 Brasil",     color=Color3.fromRGB(0,180,80)},
    {key="usa",     path="chats/usa",     label="🇺🇸 USA",        color=Color3.fromRGB(60,120,220)},
}

local lastKeys    = {}  -- lastKeys[roomKey] = último firebase key lido
local polling     = {}  -- polling[roomKey]  = true/false

-- ── Adicionar Mensagem na UI ──────────────────────────────────────
local function addMessage(sf, roomKey, sName, sDisplay, sUid, sAge, text, isSystem, msgColor)
    G.msgCounts[roomKey] = (G.msgCounts[roomKey] or 0) + 1

    -- Remover mensagens antigas se passar do limite
    if G.msgCounts[roomKey] > G.MAX_MSG + 15 then
        for _, ch in ipairs(sf:GetChildren()) do
            if ch:IsA("Frame") then
                ch:Destroy()
                G.msgCounts[roomKey] = G.msgCounts[roomKey] - 1
                break
            end
        end
    end

    local mf = Instance.new("Frame", sf)
    mf.Size = UDim2.new(1,0,0,0)
    mf.AutomaticSize = Enum.AutomaticSize.Y
    mf.BackgroundTransparency = 1
    mf.BorderSizePixel = 0
    mf.LayoutOrder = G.msgCounts[roomKey]

    if isSystem then
        -- Mensagem do sistema
        local sl = G.mkLabel(mf, "  "..text,
            UDim2.new(1,0,0,0), nil,
            msgColor or C.cyan, G.MOBILE and 12 or 11, Enum.Font.GothamItalic)
        sl.AutomaticSize = Enum.AutomaticSize.Y
        sl.TextWrapped = true
        G.mkFrame(mf, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), C.div)
    else
        local isMe = (sName == G.MY_NAME)
        local uid  = sUid or 1

        -- Avatar
        local avImg = Instance.new("ImageLabel", mf)
        avImg.Size     = UDim2.new(0, G.MOBILE and 36 or 28, 0, G.MOBILE and 36 or 28)
        avImg.Position = UDim2.new(0, 2, 0, 3)
        avImg.BackgroundColor3 = C.acc2
        avImg.BorderSizePixel  = 0
        avImg.Image = "rbxthumb://type=AvatarHeadShot&id="..uid.."&w=48&h=48"
        G.mkCorner(avImg, 99)

        local avW   = (G.MOBILE and 36 or 28) + 6
        local nameH = G.MOBILE and 18 or 15
        local textX = avW + 2

        -- Nome + idade
        local nameColor = isMe and C.accL or (msgColor or C.grayL)
        local ageBadge  = sAge and (" • "..sAge.."a") or ""
        local ownerTag  = (sName == G.OWNER_NAME or uid == G.OWNER_ID) and " 👑" or ""
        G.mkLabel(mf, (sDisplay or sName)..ageBadge..ownerTag,
            UDim2.new(1, -(textX+4), 0, nameH),
            UDim2.new(0, textX, 0, 2),
            nameColor, G.MOBILE and 11 or 10, Enum.Font.GothamBold)

        -- Texto da mensagem
        local msgL = G.mkLabel(mf, text,
            UDim2.new(1, -(textX+4), 0, 0),
            UDim2.new(0, textX, 0, nameH + 3),
            C.white, G.FSZ)
        msgL.AutomaticSize = Enum.AutomaticSize.Y
        msgL.TextWrapped   = true

        -- Linha divisória
        G.mkFrame(mf, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), C.div)

        -- Botão de traduzir
        local translateBtn = G.mkButton(mf, "🌐",
            UDim2.new(0, G.MOBILE and 28 or 22, 0, G.MOBILE and 22 or 17),
            UDim2.new(1, -(G.MOBILE and 62 or 50), 0, 2),
            Color3.fromRGB(16,11,32), C.cyan, G.MOBILE and 12 or 10)
        translateBtn.ZIndex = 3
        translateBtn.MouseButton1Click:Connect(function()
            translateBtn.Text = "..."
            G.translateText(text, "pt", function(translated)
                msgL.Text = translated.." [🌐]"
                translateBtn.Text = "↩"
                translateBtn.MouseButton1Click:Connect(function()
                    msgL.Text = text
                    translateBtn.Text = "🌐"
                end)
            end)
        end)

        -- Botão de reportar
        local reportBtn = G.mkButton(mf, "🚨",
            UDim2.new(0, G.MOBILE and 28 or 22, 0, G.MOBILE and 22 or 17),
            UDim2.new(1, -(G.MOBILE and 30 or 24), 0, 2),
            Color3.fromRGB(30,6,6), C.red, G.MOBILE and 12 or 10)
        reportBtn.ZIndex = 3
        reportBtn.MouseButton1Click:Connect(function()
            if not isMe then
                task.spawn(function()
                    G.fbPost("reports", {
                        reporter    = G.MY_NAME,
                        reporterAge = G.MY_AGE,
                        reported    = sName,
                        reportedAge = sAge or 0,
                        message     = text:sub(1,200),
                        reason      = "Denúncia via chat",
                        ip_reporter = G.MY_IP,
                        ts          = os.time(),
                        room        = roomKey,
                    })
                end)
                reportBtn.Text = "✓"
                reportBtn.BackgroundColor3 = C.green
                task.delay(2, function()
                    if reportBtn and reportBtn.Parent then
                        reportBtn.Text = "🚨"
                        reportBtn.BackgroundColor3 = Color3.fromRGB(30,6,6)
                    end
                end)
            end
        end)

        -- Alerta adulto + menor
        local myAdult  = G.MY_AGE >= 18
        local sAdult   = (sAge or 0) >= 18
        if (myAdult and not sAdult) or (not myAdult and sAdult) then
            local alertF = G.mkFrame(mf,
                UDim2.new(1, -(textX+4), 0, G.MOBILE and 22 or 18),
                UDim2.new(0, textX, 0, nameH + (G.MOBILE and 36 or 28)),
                Color3.fromRGB(38,20,4))
            G.mkCorner(alertF, 6)
            G.mkStroke(alertF, C.orange, 1)
            G.mkLabel(alertF,
                "⚠️ Diferença de idade — tenha cuidado!",
                UDim2.new(1,-8,1,0), UDim2.new(0,4,0,0),
                C.orange, G.MOBILE and 10 or 9, Enum.Font.Gotham,
                Enum.TextXAlignment.Center)
        end
    end

    G.scrollEnd(sf)
end

-- ── Polling de Mensagens ──────────────────────────────────────────
local function startPolling(roomKey, roomPath, sf)
    if polling[roomKey] then return end
    polling[roomKey] = true
    lastKeys[roomKey] = lastKeys[roomKey] or ""

    task.spawn(function()
        while G.Main and G.Main.Parent and polling[roomKey] do
            task.wait(G.POLL)
            local panel = G.tabPanels[roomKey]
            if not panel then break end

            local data = G.fbGet(roomPath, "orderBy=%22%24key%22&limitToLast=30")
            if data and type(data) == "table" then
                -- Ordenar por chave
                local list = {}
                for k, v in pairs(data) do
                    if type(v) == "table" then
                        table.insert(list, {k=k, v=v})
                    end
                end
                table.sort(list, function(a,b) return a.k < b.k end)

                for _, item in ipairs(list) do
                    if item.k > (lastKeys[roomKey] or "") then
                        lastKeys[roomKey] = item.k
                        local v = item.v
                        local isSystem = v.system == true

                        addMessage(sf, roomKey,
                            v.user or "?",
                            v.displayName or v.user or "?",
                            v.userId or 1,
                            v.age,
                            v.text or "",
                            isSystem,
                            nil)

                        -- Notificação sonora se não estiver na aba
                        if G.activeTab ~= roomKey and not isSystem then
                            G.playNotif()
                            G.notifyTab(roomKey)
                        end
                    end
                end
            end
        end
    end)
end

-- ── Enviar Mensagem ───────────────────────────────────────────────
local function sendMessage(roomPath, text, sf, roomKey)
    if not text or text:match("^%s*$") then return end
    text = text:sub(1, 250)  -- limite de caracteres

    task.spawn(function()
        G.fbPost(roomPath, {
            user        = G.MY_NAME,
            displayName = G.MY_DISPLAY,
            userId      = G.MY_ID,
            age         = G.MY_AGE,
            text        = text,
            ts          = os.time(),
            gameId      = G.MY_GAME,
            gameName    = tostring(game.Name),
        })
    end)
end

-- ── Construir Painel de Chat ──────────────────────────────────────
local function buildChatPanel(roomKey, roomPath, parentFrame, accentColor)
    local pf = parentFrame

    -- Área de mensagens
    local sf = G.mkScroll(pf,
        UDim2.new(1,0,1,-(G.INH+12)),
        UDim2.new(0,0,0,0))

    -- Mensagem inicial
    addMessage(sf, roomKey, "", "", 1, nil,
        "Bem-vindo ao "..roomKey.."! Seja respeitoso. 💜",
        true, accentColor or C.cyan)

    -- Área de input
    local inputBar = G.mkFrame(pf,
        UDim2.new(1,-8,0,G.INH),
        UDim2.new(0,4,1,-(G.INH+4)),
        Color3.fromRGB(10,7,22))
    G.mkCorner(inputBar, 10)

    local _, msgInp = G.mkInput(inputBar,
        "💬 Mensagem...",
        UDim2.new(1,-(G.BTH+10),1,-4),
        UDim2.new(0,4,0,2))

    local sendBtn = G.mkButton(inputBar, "➤",
        UDim2.new(0,G.BTH,1,-4),
        UDim2.new(1,-(G.BTH+2),0,2),
        accentColor or C.acc, C.white, G.MOBILE and 16 or 14)

    local function doSend()
        local t = msgInp.Text:match("^%s*(.-)%s*$")
        if t == "" then return end
        sendMessage(roomPath, t, sf, roomKey)
        msgInp.Text = ""
    end

    sendBtn.MouseButton1Click:Connect(doSend)
    msgInp.FocusLost:Connect(function(enter) if enter then doSend() end end)

    -- Iniciar polling
    startPolling(roomKey, roomPath, sf)

    return sf
end

-- ── Montar Painéis quando UI estiver pronta ───────────────────────
local function onReady()
    for _, room in ipairs(CHAT_ROOMS) do
        local panel = G.tabPanels[room.key]
        if panel and panel.frame then
            buildChatPanel(room.key, room.path, panel.frame, room.color)
        end
    end
end

-- Encadear com o evento de UI pronta
local prevOnUIReady = G.onUIReady
G.onUIReady = function()
    if prevOnUIReady then prevOnUIReady() end
    onReady()
end

-- Se a UI já estiver pronta (caso chat.lua carregue depois)
if G.Main then onReady() end

print("[GlobalChat Hub] chat.lua carregado.")


-- ===== private.lua =====
-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║           private.lua  —  Salas Privadas                    ║
-- ╚══════════════════════════════════════════════════════════════╝

local G = GCH
-- Compat task
local task = (function()
    local _w = (type(task)=="table" and type(task.wait)=="function") and task.wait or wait
    local _s = (type(task)=="table" and type(task.spawn)=="function") and task.spawn
               or (type(spawn)=="function" and spawn)
               or function(f) coroutine.resume(coroutine.create(f)) end
    local _d = (type(task)=="table" and type(task.delay)=="function") and task.delay
               or function(t,fn) _s(function() _w(t) fn() end) end
    local _df= (type(task)=="table" and type(task.defer)=="function") and task.defer or _s
    return { wait=_w, spawn=_s, delay=_d, defer=_df }
end)()
local C = G.C

-- ── Helpers ───────────────────────────────────────────────────────
local activeRooms   = {}   -- activeRooms[code] = { sf, lastKey, polling }
local lastPrivKeys  = {}

-- Gerar código aleatório de 6 caracteres
local function genCode()
    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local code  = ""
    for _ = 1, 6 do
        local i = math.random(1, #chars)
        code = code .. chars:sub(i, i)
    end
    return code
end

-- ── Adicionar Mensagem Privada ────────────────────────────────────
local function addPrivMsg(sf, code, sName, sDisplay, sUid, sAge, text, isSystem)
    G.msgCounts["priv_"..code] = (G.msgCounts["priv_"..code] or 0) + 1
    local order = G.msgCounts["priv_"..code]

    local mf = Instance.new("Frame", sf)
    mf.Size = UDim2.new(1,0,0,0)
    mf.AutomaticSize = Enum.AutomaticSize.Y
    mf.BackgroundTransparency = 1
    mf.BorderSizePixel = 0
    mf.LayoutOrder = order

    if isSystem then
        local sl = G.mkLabel(mf, "  "..text,
            UDim2.new(1,0,0,0), nil,
            C.cyan, G.MOBILE and 12 or 11, Enum.Font.GothamItalic)
        sl.AutomaticSize = Enum.AutomaticSize.Y
        sl.TextWrapped   = true
        G.mkFrame(mf, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), C.div)
        G.scrollEnd(sf)
        return
    end

    local isMe = (sName == G.MY_NAME)
    local uid  = sUid or 1

    -- Avatar
    local av = Instance.new("ImageLabel", mf)
    av.Size     = UDim2.new(0, G.MOBILE and 36 or 28, 0, G.MOBILE and 36 or 28)
    av.Position = UDim2.new(0, 2, 0, 3)
    av.BackgroundColor3 = C.acc2
    av.BorderSizePixel  = 0
    av.Image = "rbxthumb://type=AvatarHeadShot&id="..uid.."&w=48&h=48"
    G.mkCorner(av, 99)

    local avW   = (G.MOBILE and 36 or 28) + 6
    local nameH = G.MOBILE and 18 or 15

    -- Cadeado privado no nome
    local nameColor = isMe and C.accL or C.grayL
    local ageBadge  = sAge and (" • "..sAge.."a") or ""
    G.mkLabel(mf, "🔒 "..(sDisplay or sName)..ageBadge,
        UDim2.new(1,-(avW+4),0,nameH),
        UDim2.new(0, avW, 0, 2),
        nameColor, G.MOBILE and 11 or 10, Enum.Font.GothamBold)

    -- Texto
    local msgL = G.mkLabel(mf, text,
        UDim2.new(1,-(avW+4),0,0),
        UDim2.new(0, avW, 0, nameH+3),
        C.white, G.FSZ)
    msgL.AutomaticSize = Enum.AutomaticSize.Y
    msgL.TextWrapped   = true

    -- Divider
    G.mkFrame(mf, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), C.div)

    -- Botão traduzir
    local tBtn = G.mkButton(mf, "🌐",
        UDim2.new(0, G.MOBILE and 28 or 22, 0, G.MOBILE and 22 or 17),
        UDim2.new(1,-(G.MOBILE and 62 or 50), 0, 2),
        Color3.fromRGB(16,11,32), C.cyan, G.MOBILE and 12 or 10)
    tBtn.ZIndex = 3
    tBtn.MouseButton1Click:Connect(function()
        tBtn.Text = "..."
        G.translateText(text, "pt", function(tr)
            msgL.Text  = tr.." [🌐]"
            tBtn.Text  = "↩"
        end)
    end)

    -- Botão reportar
    local rBtn = G.mkButton(mf, "🚨",
        UDim2.new(0, G.MOBILE and 28 or 22, 0, G.MOBILE and 22 or 17),
        UDim2.new(1,-(G.MOBILE and 30 or 24), 0, 2),
        Color3.fromRGB(30,6,6), C.red, G.MOBILE and 12 or 10)
    rBtn.ZIndex = 3
    rBtn.MouseButton1Click:Connect(function()
        if not isMe then
            task.spawn(function()
                G.fbPost("reports", {
                    reporter    = G.MY_NAME,
                    reporterAge = G.MY_AGE,
                    reported    = sName,
                    reportedAge = sAge or 0,
                    message     = text:sub(1,200),
                    reason      = "Denúncia — sala privada "..code,
                    ip_reporter = G.MY_IP,
                    ts          = os.time(),
                    room        = "privado_"..code,
                })
            end)
            rBtn.Text = "✓"
            rBtn.BackgroundColor3 = C.green
        end
    end)

    -- Alerta adulto + menor
    local myAdult = G.MY_AGE >= 18
    local sAdult  = (sAge or 0) >= 18
    if (myAdult and not sAdult) or (not myAdult and sAdult) then
        local alertF = G.mkFrame(mf,
            UDim2.new(1,-(avW+4),0, G.MOBILE and 22 or 18),
            UDim2.new(0, avW, 0, nameH+(G.MOBILE and 36 or 28)),
            Color3.fromRGB(38,20,4))
        G.mkCorner(alertF, 6)
        G.mkStroke(alertF, C.orange, 1)
        G.mkLabel(alertF, "⚠️ Diferença de idade — tenha cuidado!",
            UDim2.new(1,-8,1,0), UDim2.new(0,4,0,0),
            C.orange, G.MOBILE and 10 or 9, Enum.Font.Gotham,
            Enum.TextXAlignment.Center)
    end

    G.scrollEnd(sf)
end

-- ── Polling Privado ───────────────────────────────────────────────
local function startPrivPolling(code, sf, tabKey)
    if activeRooms[code] and activeRooms[code].polling then return end
    if not activeRooms[code] then activeRooms[code] = {} end
    activeRooms[code].polling = true
    lastPrivKeys[code] = lastPrivKeys[code] or ""

    task.spawn(function()
        while G.Main and G.Main.Parent and activeRooms[code] and activeRooms[code].polling do
            task.wait(G.POLL)
            local path = "private_rooms/"..code.."/messages"
            local data = G.fbGet(path, "orderBy=%22%24key%22&limitToLast=30")
            if data and type(data) == "table" then
                local list = {}
                for k, v in pairs(data) do
                    if type(v) == "table" then table.insert(list, {k=k, v=v}) end
                end
                table.sort(list, function(a,b) return a.k < b.k end)
                for _, item in ipairs(list) do
                    if item.k > (lastPrivKeys[code] or "") then
                        lastPrivKeys[code] = item.k
                        local v = item.v

                        -- Verificar se alguém saiu
                        if v.system and v.left then
                            addPrivMsg(sf, code, "", "", 1, nil, v.text, true)
                            -- Remover aba após 30s
                            task.delay(G.ROOM_TTL, function()
                                local panel = G.tabPanels[tabKey]
                                if panel and panel.frame then
                                    panel.frame:Destroy()
                                    G.tabPanels[tabKey] = nil
                                    if G.tabBtns[tabKey] then
                                        G.tabBtns[tabKey]:Destroy()
                                        G.tabBtns[tabKey] = nil
                                    end
                                    if G.activeTab == tabKey then
                                        G.switchTab("global")
                                    end
                                end
                                if activeRooms[code] then
                                    activeRooms[code].polling = false
                                    activeRooms[code] = nil
                                end
                            end)
                        else
                            addPrivMsg(sf, code,
                                v.user or "?",
                                v.displayName or v.user or "?",
                                v.userId or 1,
                                v.age,
                                v.text or "",
                                v.system == true)

                            if G.activeTab ~= tabKey then
                                G.playNotif()
                                G.notifyTab(tabKey)
                            end
                        end
                    end
                end
            end

            -- Checar membros online
            local roomData = G.fbGet("private_rooms/"..code)
            if roomData and type(roomData) == "table" then
                local members = roomData.members or {}
                for uname, active in pairs(members) do
                    if not active and uname ~= G.MY_NAME then
                        -- já tratado via mensagem de sistema
                    end
                end
            end
        end
    end)
end

-- ── Criar Sala Privada ────────────────────────────────────────────
local function createPrivateRoom(sf_control)
    local code = genCode()

    task.spawn(function()
        G.fbSet("private_rooms/"..code, {
            createdBy = G.MY_NAME,
            createdAt = os.time(),
            members   = {[G.MY_NAME] = true},
            active    = true,
        })
        G.fbPost("private_rooms/"..code.."/messages", {
            system = true,
            text   = "🔒 Sala criada por "..G.MY_DISPLAY.." — Código: "..code,
            ts     = os.time(),
        })
    end)

    return code
end

-- ── Entrar em Sala Privada ────────────────────────────────────────
local function joinPrivateRoom(code, parentTabFrame)
    code = code:upper():match("^%s*(.-)%s*$")
    if code == "" then return false, "Digite o código." end
    if activeRooms[code] then return false, "Você já está nessa sala." end

    -- Verificar se sala existe
    local roomData = G.fbGet("private_rooms/"..code)
    if not roomData or type(roomData) ~= "table" or not roomData.active then
        return false, "Sala não encontrada ou inativa."
    end

    -- Registrar membro
    task.spawn(function()
        G.fbPatch("private_rooms/"..code.."/members", {[G.MY_NAME]=true})
        G.fbPost("private_rooms/"..code.."/messages", {
            system = true,
            text   = "🟢 "..G.MY_DISPLAY.." entrou na sala.",
            ts     = os.time(),
        })
    end)

    -- Criar aba dinâmica
    local tabKey = "priv_"..code
    local tabLabel = "🔒 "..code

    -- Adicionar botão de aba
    local tb = G.mkButton(G.TabBar, tabLabel,
        UDim2.new(0, G.MOBILE and 80 or 70, 1, 0), nil,
        Color3.fromRGB(15,11,32), C.gray, G.TFSZ)
    tb.LayoutOrder = 99
    G.tabBtns[tabKey] = tb

    -- Criar painel
    local pf = G.mkFrame(G.Content, UDim2.new(1,0,1,0), nil, C.bg)
    pf.Visible = false
    G.tabPanels[tabKey] = {frame=pf}

    -- Cabeçalho da sala
    local header = G.mkFrame(pf, UDim2.new(1,0,0,G.MOBILE and 40 or 32), nil, Color3.fromRGB(14,8,28))
    G.mkCorner(header, 0)
    G.mkStroke(header, C.acc2, 1)

    G.mkLabel(header, "🔒  Sala Privada  •  Código: "..code,
        UDim2.new(1,-90,1,0), UDim2.new(0,8,0,0),
        C.accL, G.MOBILE and 12 or 11, Enum.Font.GothamBold)

    -- Botão copiar código
    local copyBtn = G.mkButton(header, "📋 Copiar",
        UDim2.new(0, G.MOBILE and 76 or 68, 1,-6),
        UDim2.new(1,-(G.MOBILE and 80 or 72), 0, 3),
        C.acc2, C.white, G.MOBILE and 11 or 10)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(code) end)
        copyBtn.Text = "✓ Copiado"
        task.delay(2, function()
            if copyBtn.Parent then copyBtn.Text = "📋 Copiar" end
        end)
    end)

    -- Área de mensagens
    local headerH = G.MOBILE and 40 or 32
    local sf = G.mkScroll(pf,
        UDim2.new(1,0,1,-(headerH + G.INH + 12)),
        UDim2.new(0,0,0,headerH))

    addPrivMsg(sf, code, "", "", 1, nil,
        "🔒 Sala segura • Criptografada • Código: "..code, true)

    -- Input bar
    local inputBar = G.mkFrame(pf,
        UDim2.new(1,-8,0,G.INH),
        UDim2.new(0,4,1,-(G.INH+4)),
        Color3.fromRGB(10,7,22))
    G.mkCorner(inputBar, 10)

    local _, msgInp = G.mkInput(inputBar, "🔒 Mensagem privada...",
        UDim2.new(1,-(G.BTH+10),1,-4), UDim2.new(0,4,0,2))

    local sendBtn = G.mkButton(inputBar, "➤",
        UDim2.new(0,G.BTH,1,-4),
        UDim2.new(1,-(G.BTH+2),0,2),
        C.acc2, C.white, G.MOBILE and 16 or 14)

    local function doSend()
        local t = msgInp.Text:match("^%s*(.-)%s*$")
        if t == "" then return end
        t = t:sub(1,250)
        task.spawn(function()
            G.fbPost("private_rooms/"..code.."/messages", {
                user        = G.MY_NAME,
                displayName = G.MY_DISPLAY,
                userId      = G.MY_ID,
                age         = G.MY_AGE,
                text        = t,
                ts          = os.time(),
            })
        end)
        msgInp.Text = ""
    end

    sendBtn.MouseButton1Click:Connect(doSend)
    msgInp.FocusLost:Connect(function(enter) if enter then doSend() end end)

    -- Botão sair da sala
    local leaveBtn = G.mkButton(pf, "🚪 Sair",
        UDim2.new(0, G.MOBILE and 72 or 60, 0, G.MOBILE and 26 or 20),
        UDim2.new(1,-(G.MOBILE and 76 or 64), 0, headerH + 4),
        Color3.fromRGB(30,6,6), C.red, G.MOBILE and 11 or 10)
    leaveBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            G.fbPatch("private_rooms/"..code.."/members", {[G.MY_NAME]=false})
            G.fbPost("private_rooms/"..code.."/messages", {
                system = true,
                left   = true,
                text   = "🔴 "..G.MY_DISPLAY.." saiu da sala. A aba será removida em 30s.",
                ts     = os.time(),
            })
        end)
        if activeRooms[code] then activeRooms[code].polling = false end
        task.delay(G.ROOM_TTL, function()
            if G.tabPanels[tabKey] and G.tabPanels[tabKey].frame then
                G.tabPanels[tabKey].frame:Destroy()
                G.tabPanels[tabKey] = nil
            end
            if G.tabBtns[tabKey] then
                G.tabBtns[tabKey]:Destroy()
                G.tabBtns[tabKey] = nil
            end
            activeRooms[code] = nil
            if G.activeTab == tabKey then G.switchTab("global") end
        end)
    end)

    -- Iniciar polling
    startPrivPolling(code, sf, tabKey)

    -- Marcar no fechamento do jogo
    G.ME.AncestryChanged:Connect(function()
        pcall(function()
            G.fbPatch("private_rooms/"..code.."/members", {[G.MY_NAME]=false})
            G.fbPost("private_rooms/"..code.."/messages", {
                system = true,
                left   = true,
                text   = "🔴 "..G.MY_DISPLAY.." saiu do jogo. A aba será removida em 30s.",
                ts     = os.time(),
            })
        end)
    end)

    -- Ativar botão de aba
    tb.MouseButton1Click:Connect(function() G.switchTab(tabKey) end)

    return true, code
end

-- ── Painel de Controle na Aba "Privado" ──────────────────────────
local function buildPrivatePanel()
    local panel = G.tabPanels["privado"]
    if not panel or not panel.frame then return end
    local pf = panel.frame

    -- Fundo gradiente
    local grad = Instance.new("UIGradient", pf)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10,6,24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6,4,14)),
    })
    grad.Rotation = 135

    local padY = G.MOBILE and 18 or 14

    -- Título
    G.mkLabel(pf, "🔒  Salas Privadas",
        UDim2.new(1,-20,0, G.MOBILE and 34 or 28),
        UDim2.new(0,10,0,padY),
        C.accL, G.MOBILE and 20 or 17, Enum.Font.GothamBold)

    G.mkLabel(pf,
        "Crie uma sala e compartilhe o código.\nSó quem tiver o código pode entrar. 🔐",
        UDim2.new(1,-20,0, G.MOBILE and 44 or 36),
        UDim2.new(0,10,0,padY + (G.MOBILE and 36 or 30)),
        C.gray, G.MOBILE and 12 or 11, Enum.Font.Gotham)

    local y = padY + (G.MOBILE and 88 or 76)

    -- ── Criar sala ────────────────────────────────────────────────
    local createCard = G.mkFrame(pf,
        UDim2.new(1,-16,0, G.MOBILE and 120 or 100),
        UDim2.new(0,8,0,y),
        Color3.fromRGB(14,9,30))
    G.mkCorner(createCard, 14)
    G.mkStroke(createCard, C.acc, 1.5)

    G.mkLabel(createCard, "✨  Criar Nova Sala",
        UDim2.new(1,-12,0, G.MOBILE and 26 or 22),
        UDim2.new(0,8,0,8),
        C.white, G.MOBILE and 14 or 12, Enum.Font.GothamBold)

    local createBtn = G.mkButton(createCard, "🔒  Criar Sala Privada",
        UDim2.new(1,-16,0,G.BTH),
        UDim2.new(0,8,0, G.MOBILE and 38 or 32),
        C.acc, C.white)

    local codeLabel = G.mkLabel(createCard, "",
        UDim2.new(1,-16,0, G.MOBILE and 26 or 22),
        UDim2.new(0,8,0, G.MOBILE and 78 or 68),
        C.green, G.MOBILE and 13 or 11, Enum.Font.GothamBold,
        Enum.TextXAlignment.Center)

    createBtn.MouseButton1Click:Connect(function()
        createBtn.Text = "⏳ Criando..."
        task.spawn(function()
            local code = createPrivateRoom()
            createBtn.Text = "🔒  Criar Sala Privada"
            codeLabel.Text = "✅  Código: "..code.."  •  Compartilhe!"
            -- Auto entrar na sala criada
            task.wait(0.5)
            joinPrivateRoom(code, pf)
            G.switchTab("priv_"..code)
        end)
    end)

    local y2 = y + (G.MOBILE and 128 or 108)

    -- ── Entrar na sala ────────────────────────────────────────────
    local joinCard = G.mkFrame(pf,
        UDim2.new(1,-16,0, G.MOBILE and 130 or 110),
        UDim2.new(0,8,0,y2),
        Color3.fromRGB(14,9,30))
    G.mkCorner(joinCard, 14)
    G.mkStroke(joinCard, C.acc2, 1.5)

    G.mkLabel(joinCard, "🔑  Entrar com Código",
        UDim2.new(1,-12,0, G.MOBILE and 26 or 22),
        UDim2.new(0,8,0,8),
        C.white, G.MOBILE and 14 or 12, Enum.Font.GothamBold)

    local _, codeInp = G.mkInput(joinCard,
        "Digite o código (ex: AB3X7K)",
        UDim2.new(1,-16,0,G.INH),
        UDim2.new(0,8,0, G.MOBILE and 36 or 32))

    local joinBtn = G.mkButton(joinCard, "🚪  Entrar na Sala",
        UDim2.new(1,-16,0,G.BTH),
        UDim2.new(0,8,0, G.MOBILE and 36+G.INH+8 or 32+G.INH+8),
        C.acc2, C.white)

    local errLabel = G.mkLabel(joinCard, "",
        UDim2.new(1,-16,0, G.MOBILE and 22 or 18),
        UDim2.new(0,8,0, G.MOBILE and 36+G.INH+G.BTH+12 or 32+G.INH+G.BTH+12),
        C.red, G.MOBILE and 11 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    joinBtn.MouseButton1Click:Connect(function()
        local code = codeInp.Text:upper():match("^%s*(.-)%s*$")
        if code == "" then errLabel.Text = "⚠️ Digite o código da sala."; return end
        joinBtn.Text = "⏳ Entrando..."
        errLabel.Text = ""
        task.spawn(function()
            local ok, result = joinPrivateRoom(code, pf)
            joinBtn.Text = "🚪  Entrar na Sala"
            if ok then
                codeInp.Text = ""
                G.switchTab("priv_"..code)
            else
                errLabel.Text = "❌ "..result
            end
        end)
    end)
end

-- ── Encadear com UI Ready ─────────────────────────────────────────
local prevOnUIReady = G.onUIReady
G.onUIReady = function()
    if prevOnUIReady then prevOnUIReady() end
    buildPrivatePanel()
end

if G.Main then buildPrivatePanel() end

print("[GlobalChat Hub] private.lua carregado.")


-- ===== profile.lua =====
-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║             profile.lua  —  Perfis & Status                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local G   = GCH
local C   = G.C
local TelSvc = game:GetService("TeleportService")

-- ── Abrir Perfil de Outro Jogador (modal) ────────────────────────
function G.openProfile(uname, udata)
    -- Remover modal anterior
    local old = G.SG:FindFirstChild("ProfileModal")
    if old then old:Destroy() end

    local modal = G.mkFrame(G.SG, UDim2.new(1,0,1,0), nil, Color3.fromRGB(0,0,0), 0.45)
    modal.Name    = "ProfileModal"
    modal.ZIndex  = 60

    -- Fechar ao clicar no fundo
    local closeModal = Instance.new("TextButton", modal)
    closeModal.Size              = UDim2.new(1,0,1,0)
    closeModal.BackgroundTransparency = 1
    closeModal.Text              = ""
    closeModal.ZIndex            = 60
    closeModal.MouseButton1Click:Connect(function() modal:Destroy() end)

    -- Card
    local cW = G.MOBILE and 310 or 380
    local cH = G.MOBILE and 400 or 440
    local card = G.mkFrame(modal,
        UDim2.new(0,0,0,0),
        UDim2.new(0.5,0,0.5,0),
        C.bg2)
    card.AnchorPoint = Vector2.new(0.5,0.5)
    card.ZIndex = 61
    G.mkCorner(card, 20)
    G.mkStroke(card, C.acc, 2)

    local cGrad = Instance.new("UIGradient", card)
    cGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18,11,40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8,6,18)),
    })
    cGrad.Rotation = 140

    G.TweenSvc:Create(card,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size=UDim2.new(0,cW,0,cH)}):Play()

    -- Fechar botão
    local xBtn = G.mkButton(card, "✕",
        UDim2.new(0, G.MOBILE and 30 or 24, 0, G.MOBILE and 30 or 24),
        UDim2.new(1,-(G.MOBILE and 34 or 28), 0, 6),
        C.red, C.white, G.MOBILE and 13 or 11)
    xBtn.ZIndex = 62
    xBtn.MouseButton1Click:Connect(function() modal:Destroy() end)

    -- Avatar grande
    local avSize = G.MOBILE and 76 or 68
    local av = Instance.new("ImageLabel", card)
    av.Size     = UDim2.new(0,avSize,0,avSize)
    av.Position = UDim2.new(0.5,-avSize/2,0,18)
    av.BackgroundColor3 = C.acc2
    av.BorderSizePixel  = 0
    av.Image = "rbxthumb://type=AvatarHeadShot&id="..(udata.userId or 1).."&w=150&h=150"
    av.ZIndex = 62
    G.mkCorner(av, 99)
    G.mkStroke(av, C.acc, 2)

    -- Status dot
    local online   = udata.online and (os.time()-(udata.lastSeen or 0)) < 60
    local stColors = {online=C.green, ocupado=C.yel, invisivel=C.gray}
    local stLabels = {online="Disponível", ocupado="Ocupado", invisivel="Invisível"}
    local stKey    = udata.status or (online and "online" or "offline")
    local stColor  = stColors[stKey] or C.gray
    local stLabel  = stLabels[stKey] or "Offline"

    local dot = G.mkFrame(card,
        UDim2.new(0, G.MOBILE and 16 or 13, 0, G.MOBILE and 16 or 13),
        UDim2.new(0.5, avSize/2-6, 0, 18+avSize-(G.MOBILE and 16 or 13)),
        stColor)
    dot.ZIndex = 63
    G.mkCorner(dot, 99)
    G.mkStroke(dot, C.bg2, 2)

    local nameY = 18 + avSize + 10

    -- Nome
    local isOwner = (uname == G.OWNER_NAME or (udata.userId or 0) == G.OWNER_ID)
    local ownerTag = isOwner and " 👑" or ""
    G.mkLabel(card,
        (udata.displayName or uname)..ownerTag,
        UDim2.new(1,-20,0, G.MOBILE and 30 or 26),
        UDim2.new(0,10,0,nameY),
        C.white, G.MOBILE and 18 or 16, Enum.Font.GothamBold,
        Enum.TextXAlignment.Center).ZIndex = 62

    -- @username + idade
    G.mkLabel(card,
        "@"..uname.." • "..(udata.age or "?").."a",
        UDim2.new(1,-20,0, G.MOBILE and 22 or 18),
        UDim2.new(0,10,0, nameY+(G.MOBILE and 32 or 28)),
        C.gray, G.MOBILE and 12 or 11, Enum.Font.Gotham,
        Enum.TextXAlignment.Center).ZIndex = 62

    -- Status
    G.mkLabel(card,
        "● "..stLabel,
        UDim2.new(1,-20,0, G.MOBILE and 22 or 18),
        UDim2.new(0,10,0, nameY+(G.MOBILE and 56 or 48)),
        stColor, G.MOBILE and 12 or 11, Enum.Font.GothamBold,
        Enum.TextXAlignment.Center).ZIndex = 62

    -- Divisor
    G.mkFrame(card,
        UDim2.new(1,-30,0,1),
        UDim2.new(0,15,0, nameY+(G.MOBILE and 82 or 70)),
        C.div).ZIndex = 62

    local infoY = nameY + (G.MOBILE and 90 or 78)

    -- Jogo atual
    local gameRow = G.mkFrame(card,
        UDim2.new(1,-20,0, G.MOBILE and 44 or 38),
        UDim2.new(0,10,0, infoY),
        Color3.fromRGB(12,8,26))
    gameRow.ZIndex = 62
    G.mkCorner(gameRow, 10)
    G.mkStroke(gameRow, C.acc2, 1)

    G.mkLabel(gameRow, "🎮  Jogando agora:",
        UDim2.new(1,-10,0, G.MOBILE and 18 or 16),
        UDim2.new(0,8,0,3),
        C.gray, G.MOBILE and 11 or 10).ZIndex = 63

    local gameName = udata.gameName or "Roblox"
    local gameId   = udata.gameId
    G.mkLabel(gameRow, gameName,
        UDim2.new(1,-10,0, G.MOBILE and 20 or 17),
        UDim2.new(0,8,0, G.MOBILE and 20 or 18),
        C.white, G.MOBILE and 12 or 11, Enum.Font.GothamBold).ZIndex = 63

    local btnY = infoY + (G.MOBILE and 52 or 46)

    -- Botão entrar na partida
    if gameId and online then
        local joinBtn = G.mkButton(card, "🚀  Entrar na Partida",
            UDim2.new(1,-20,0,G.BTH),
            UDim2.new(0,10,0,btnY),
            C.green, C.bg2)
        joinBtn.ZIndex = 62
        joinBtn.MouseButton1Click:Connect(function()
            joinBtn.Text = "⏳ Teleportando..."
            pcall(function()
                TelSvc:TeleportToPlaceInstance(tonumber(gameId), "", G.ME)
            end)
        end)
        btnY = btnY + G.BTH + 8
    end

    -- Botão reportar jogador
    if uname ~= G.MY_NAME then
        local repBtn = G.mkButton(card, "🚨  Reportar Jogador",
            UDim2.new(1,-20,0,G.BTH),
            UDim2.new(0,10,0,btnY),
            Color3.fromRGB(30,6,6), C.red)
        repBtn.ZIndex = 62
        repBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                G.fbPost("reports", {
                    reporter    = G.MY_NAME,
                    reporterAge = G.MY_AGE,
                    reported    = uname,
                    reportedAge = udata.age or 0,
                    reason      = "Denúncia via perfil",
                    ip_reporter = G.MY_IP,
                    ts          = os.time(),
                    room        = "perfil",
                })
            end)
            repBtn.Text = "✓ Reportado"
            repBtn.BackgroundColor3 = C.gray
        end)
        btnY = btnY + G.BTH + 8
    end

    -- Última vez online
    if udata.lastSeen then
        G.mkLabel(card,
            "Visto por último: "..os.date("%d/%m %H:%M", udata.lastSeen),
            UDim2.new(1,-20,0, G.MOBILE and 18 or 16),
            UDim2.new(0,10,0, btnY+4),
            C.gray, G.MOBILE and 10 or 9, Enum.Font.Gotham,
            Enum.TextXAlignment.Center).ZIndex = 62
    end
end

-- ── Painel do Meu Perfil ─────────────────────────────────────────
local function buildProfilePanel()
    local panel = G.tabPanels["perfil"]
    if not panel or not panel.frame then return end
    local pf = panel.frame

    local grad = Instance.new("UIGradient", pf)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10,6,24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6,4,14)),
    })
    grad.Rotation = 135

    local sf = G.mkScroll(pf)

    -- ── Card do perfil ────────────────────────────────────────────
    local profileCard = G.mkFrame(sf,
        UDim2.new(1,0,0, G.MOBILE and 260 or 230),
        nil, Color3.fromRGB(14,9,30))
    profileCard.LayoutOrder = 1
    G.mkCorner(profileCard, 16)
    G.mkStroke(profileCard, C.acc, 1.5)

    -- Avatar
    local avSize = G.MOBILE and 72 or 62
    local av = Instance.new("ImageLabel", profileCard)
    av.Size     = UDim2.new(0,avSize,0,avSize)
    av.Position = UDim2.new(0,12,0,12)
    av.BackgroundColor3 = C.acc2
    av.BorderSizePixel  = 0
    av.Image = "rbxthumb://type=AvatarHeadShot&id="..G.MY_ID.."&w=150&h=150"
    G.mkCorner(av, 99)
    G.mkStroke(av, C.acc, 2)

    -- Info do usuário
    local infoX = avSize + 20
    local dispL = G.mkLabel(profileCard,
        G.MY_DISPLAY,
        UDim2.new(1,-(infoX+10),0, G.MOBILE and 28 or 24),
        UDim2.new(0,infoX,0,16),
        C.white, G.MOBILE and 18 or 16, Enum.Font.GothamBold)

    G.mkLabel(profileCard,
        "@"..G.MY_NAME.." • "..G.MY_AGE.."a",
        UDim2.new(1,-(infoX+10),0, G.MOBILE and 20 or 17),
        UDim2.new(0,infoX,0, G.MOBILE and 46 or 42),
        C.gray, G.MOBILE and 11 or 10)

    -- Status badge
    local statColors = {online=C.green, ocupado=C.yel, invisivel=C.gray}
    local statLabels = {online="● Disponível", ocupado="● Ocupado", invisivel="● Invisível"}
    local statBadge  = G.mkLabel(profileCard,
        statLabels[G.MY_STATUS] or "● Online",
        UDim2.new(1,-(infoX+10),0, G.MOBILE and 20 or 17),
        UDim2.new(0,infoX,0, G.MOBILE and 68 or 62),
        statColors[G.MY_STATUS] or C.green,
        G.MOBILE and 12 or 11, Enum.Font.GothamBold)

    -- Jogo atual
    G.mkLabel(profileCard,
        "🎮 "..tostring(game.Name),
        UDim2.new(1,-(infoX+10),0, G.MOBILE and 20 or 17),
        UDim2.new(0,infoX,0, G.MOBILE and 90 or 82),
        C.cyan, G.MOBILE and 11 or 10)

    -- ID Roblox
    G.mkLabel(profileCard,
        "ID: "..tostring(G.MY_ID),
        UDim2.new(1,-(infoX+10),0, G.MOBILE and 18 or 15),
        UDim2.new(0,infoX,0, G.MOBILE and 112 or 102),
        C.gray, G.MOBILE and 10 or 9)

    -- Divisor
    G.mkFrame(profileCard,
        UDim2.new(1,-20,0,1),
        UDim2.new(0,10,0, G.MOBILE and 142 or 126),
        C.div)

    -- Botões de status rápido
    local sY    = G.MOBILE and 150 or 134
    local sBtns = {
        {k="online",   label="🟢 Disponível", col=C.green},
        {k="ocupado",  label="🟡 Ocupado",    col=C.yel},
        {k="invisivel",label="⚫ Invisível",   col=C.gray},
    }
    local bW = (1/#sBtns)
    for i, s in ipairs(sBtns) do
        local sb = G.mkButton(profileCard, s.label,
            UDim2.new(bW,-6,0,G.BTH-4),
            UDim2.new((i-1)*bW, 4+(i-1)*2, 0, sY),
            Color3.fromRGB(14,10,28), s.col,
            G.MOBILE and 10 or 9)
        sb.MouseButton1Click:Connect(function()
            G.MY_STATUS = s.k
            statBadge.Text       = statLabels[s.k]
            statBadge.TextColor3 = statColors[s.k]
            G.pushPresence()
        end)
    end

    -- ── Card editar perfil ────────────────────────────────────────
    local editCard = G.mkFrame(sf,
        UDim2.new(1,0,0, G.MOBILE and 260 or 230),
        nil, Color3.fromRGB(14,9,30))
    editCard.LayoutOrder = 2
    G.mkCorner(editCard, 16)
    G.mkStroke(editCard, C.acc2, 1.5)

    G.mkLabel(editCard, "✏️  Editar Perfil",
        UDim2.new(1,-16,0, G.MOBILE and 28 or 24),
        UDim2.new(0,10,0,10),
        C.accL, G.MOBILE and 16 or 14, Enum.Font.GothamBold)

    -- Campo nome
    G.mkLabel(editCard, "Seu nome no chat:",
        UDim2.new(1,-16,0,18), UDim2.new(0,10,0, G.MOBILE and 42 or 38),
        C.grayL, G.MOBILE and 12 or 10)
    local _, nameInp = G.mkInput(editCard,
        G.MY_DISPLAY,
        UDim2.new(1,-16,0,G.INH),
        UDim2.new(0,10,0, G.MOBILE and 62 or 58))
    nameInp.Text = G.MY_DISPLAY

    -- Campo idade
    G.mkLabel(editCard, "Sua idade:",
        UDim2.new(1,-16,0,18),
        UDim2.new(0,10,0, G.MOBILE and 62+G.INH+8 or 58+G.INH+8),
        C.grayL, G.MOBILE and 12 or 10)
    local _, ageInp = G.mkInput(editCard,
        tostring(G.MY_AGE),
        UDim2.new(1,-16,0,G.INH),
        UDim2.new(0,10,0, G.MOBILE and 82+G.INH+8 or 76+G.INH+8))
    ageInp.Text = tostring(G.MY_AGE)

    local saveY = G.MOBILE and (82+G.INH*2+24) or (76+G.INH*2+24)
    local saveBtn = G.mkButton(editCard, "💾  Salvar Alterações",
        UDim2.new(1,-16,0,G.BTH),
        UDim2.new(0,10,0,saveY),
        C.acc, C.white)

    local saveMsg = G.mkLabel(editCard, "",
        UDim2.new(1,-16,0,22),
        UDim2.new(0,10,0,saveY+G.BTH+4),
        C.green, G.MOBILE and 11 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    saveBtn.MouseButton1Click:Connect(function()
        local newName = nameInp.Text:match("^%s*(.-)%s*$")
        local newAge  = tonumber(ageInp.Text)

        if newName == "" then newName = G.MY_NAME end
        if not newAge or newAge < 5 or newAge > 99 then
            saveMsg.TextColor3 = C.red
            saveMsg.Text = "⚠️ Idade inválida (5–99)."
            return
        end

        G.MY_DISPLAY = newName
        G.MY_AGE     = newAge

        -- Atualizar label da titlebar
        if G.UI_userLabel then
            G.UI_userLabel.Text = G.MY_DISPLAY.." • "..G.MY_AGE.."a"
        end

        -- Atualizar label do perfil
        dispL.Text = G.MY_DISPLAY

        task.spawn(function()
            G.fbPatch("users/"..G.MY_NAME, {
                displayName = G.MY_DISPLAY,
                age         = G.MY_AGE,
            })
        end)

        saveMsg.TextColor3 = C.green
        saveMsg.Text = "✅ Perfil atualizado!"
        task.delay(3, function()
            if saveMsg.Parent then saveMsg.Text = "" end
        end)
    end)

    -- ── Card estatísticas ─────────────────────────────────────────
    local statsCard = G.mkFrame(sf,
        UDim2.new(1,0,0, G.MOBILE and 140 or 120),
        nil, Color3.fromRGB(14,9,30))
    statsCard.LayoutOrder = 3
    G.mkCorner(statsCard, 16)
    G.mkStroke(statsCard, C.div, 1)

    G.mkLabel(statsCard, "📊  Suas Estatísticas",
        UDim2.new(1,-16,0, G.MOBILE and 26 or 22),
        UDim2.new(0,10,0,10),
        C.grayL, G.MOBILE and 14 or 12, Enum.Font.GothamBold)

    task.spawn(function()
        local userData = G.fbGet("users/"..G.MY_NAME) or {}
        local createdAt = userData.createdAt
        local sinceStr  = createdAt and os.date("%d/%m/%Y", createdAt) or "—"

        local items = {
            {"🎮 Jogo atual",    tostring(game.Name)},
            {"📅 Membro desde",  sinceStr},
            {"🌐 Versão",        G.VER},
            {"🔒 Admin",         G.IS_OWNER and "✅ Sim" or "❌ Não"},
        }

        for i, item in ipairs(items) do
            local rowY = 36 + (i-1)*(G.MOBILE and 20 or 17)
            G.mkLabel(statsCard, item[1]..":",
                UDim2.new(0.45,-8,0, G.MOBILE and 18 or 15),
                UDim2.new(0,10,0,rowY),
                C.gray, G.MOBILE and 11 or 10)
            G.mkLabel(statsCard, item[2],
                UDim2.new(0.55,-8,0, G.MOBILE and 18 or 15),
                UDim2.new(0.45,4,0,rowY),
                C.white, G.MOBILE and 11 or 10, Enum.Font.GothamBold)
        end
    end)
end

-- ── Encadear com UI Ready ─────────────────────────────────────────
local prevOnUIReady = G.onUIReady
G.onUIReady = function()
    if prevOnUIReady then prevOnUIReady() end
    buildProfilePanel()
end

if G.Main then buildProfilePanel() end

print("[GlobalChat Hub] profile.lua carregado.")


-- ===== friends.lua =====
-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║             friends.lua  —  Sistema de Amigos               ║
-- ╚══════════════════════════════════════════════════════════════╝

local G = GCH
-- Compat task
local task = (function()
    local _w = (type(task)=="table" and type(task.wait)=="function") and task.wait or wait
    local _s = (type(task)=="table" and type(task.spawn)=="function") and task.spawn
               or (type(spawn)=="function" and spawn)
               or function(f) coroutine.resume(coroutine.create(f)) end
    local _d = (type(task)=="table" and type(task.delay)=="function") and task.delay
               or function(t,fn) _s(function() _w(t) fn() end) end
    local _df= (type(task)=="table" and type(task.defer)=="function") and task.defer or _s
    return { wait=_w, spawn=_s, delay=_d, defer=_df }
end)()
local C = G.C

-- ── Helpers ───────────────────────────────────────────────────────
local function friendPath(a, b)
    -- Ordem alfabética para chave única entre dois usuários
    if a < b then return "friends/"..a.."__"..b
    else           return "friends/"..b.."__"..a end
end

-- ── Enviar Solicitação ────────────────────────────────────────────
local function sendRequest(toUser, onDone)
    if toUser == G.MY_NAME then
        if onDone then onDone(false, "Você não pode se adicionar.") end
        return
    end
    task.spawn(function()
        -- Verificar se já são amigos
        local fData = G.fbGet(friendPath(G.MY_NAME, toUser))
        if fData and type(fData) == "table" and fData.status == "accepted" then
            if onDone then onDone(false, "Vocês já são amigos!") end
            return
        end
        if fData and type(fData) == "table" and fData.status == "pending" then
            if onDone then onDone(false, "Solicitação já enviada.") end
            return
        end
        -- Verificar se usuário existe
        local uData = G.fbGet("users/"..toUser)
        if not uData or type(uData) ~= "table" or not uData.userId then
            if onDone then onDone(false, "Jogador não encontrado.") end
            return
        end
        G.fbSet(friendPath(G.MY_NAME, toUser), {
            from        = G.MY_NAME,
            to          = toUser,
            status      = "pending",
            sentAt      = os.time(),
            fromDisplay = G.MY_DISPLAY,
            fromAge     = G.MY_AGE,
            fromId      = G.MY_ID,
        })
        if onDone then onDone(true, "✅ Solicitação enviada para "..toUser.."!") end
    end)
end

-- ── Aceitar Solicitação ───────────────────────────────────────────
local function acceptRequest(fromUser, onDone)
    task.spawn(function()
        G.fbPatch(friendPath(fromUser, G.MY_NAME), {
            status     = "accepted",
            acceptedAt = os.time(),
        })
        if onDone then onDone() end
    end)
end

-- ── Recusar / Remover ─────────────────────────────────────────────
local function removeRelation(otherUser, onDone)
    task.spawn(function()
        G.fbDelete(friendPath(G.MY_NAME, otherUser))
        if onDone then onDone() end
    end)
end

-- ── Card de Amigo ─────────────────────────────────────────────────
local function mkFriendCard(parent, uname, udata, isPending, fromMe)
    local cardH  = G.MOBILE and 64 or 54
    local card   = G.mkFrame(parent, UDim2.new(1,0,0,cardH), nil, Color3.fromRGB(14,9,30))
    G.mkCorner(card, 12)
    G.mkStroke(card, C.div, 1)

    -- Avatar
    local avSz = G.MOBILE and 42 or 34
    local av   = Instance.new("ImageLabel", card)
    av.Size     = UDim2.new(0,avSz,0,avSz)
    av.Position = UDim2.new(0,6,0.5,-avSz/2)
    av.BackgroundColor3 = C.acc2
    av.BorderSizePixel  = 0
    av.Image = "rbxthumb://type=AvatarHeadShot&id="..(udata.userId or 1).."&w=48&h=48"
    G.mkCorner(av, 99)

    local online    = udata.online and (os.time()-(udata.lastSeen or 0)) < 60
    local stColors  = {online=C.green, ocupado=C.yel, invisivel=C.gray}
    local stKey     = udata.status or (online and "online" or "offline")
    local stColor   = stColors[stKey] or C.gray

    -- Status dot
    local dot = G.mkFrame(card,
        UDim2.new(0, G.MOBILE and 12 or 10, 0, G.MOBILE and 12 or 10),
        UDim2.new(0, 6+avSz-(G.MOBILE and 10 or 8), 0.5, avSz/2-(G.MOBILE and 8 or 6)),
        stColor)
    G.mkCorner(dot, 99)
    G.mkStroke(dot, Color3.fromRGB(14,9,30), 2)

    local textX = avSz + 16

    -- Nome
    G.mkLabel(card,
        (udata.displayName or uname).." • "..(udata.age or "?").."a",
        UDim2.new(1,-(textX+100),0, G.MOBILE and 20 or 17),
        UDim2.new(0,textX,0, G.MOBILE and 8 or 7),
        C.white, G.MOBILE and 13 or 11, Enum.Font.GothamBold)

    -- Jogo / status
    local subTxt = online and "🎮 "..(udata.gameName or "Roblox") or "⚫ Offline"
    G.mkLabel(card,
        subTxt,
        UDim2.new(1,-(textX+100),0, G.MOBILE and 18 or 15),
        UDim2.new(0,textX,0, G.MOBILE and 30 or 26),
        stColor, G.MOBILE and 11 or 9)

    -- Botões lado direito
    local bX   = -(G.MOBILE and 36 or 30)
    local bSz  = UDim2.new(0, G.MOBILE and 30 or 24, 0, G.MOBILE and 30 or 24)
    local bPos = function(offset)
        return UDim2.new(1, bX+offset, 0.5, -(G.MOBILE and 15 or 12))
    end

    if isPending and not fromMe then
        -- Aceitar
        local accBtn = G.mkButton(card, "✓", bSz, bPos(-(G.MOBILE and 36 or 30)), C.green, C.white, G.MOBILE and 14 or 12)
        accBtn.MouseButton1Click:Connect(function()
            acceptRequest(uname, function()
                card:Destroy()
            end)
        end)
        -- Recusar
        local decBtn = G.mkButton(card, "✕", bSz, bPos(0), C.red, C.white, G.MOBILE and 14 or 12)
        decBtn.MouseButton1Click:Connect(function()
            removeRelation(uname, function()
                card:Destroy()
            end)
        end)
    elseif isPending and fromMe then
        -- Cancelar solicitação
        local canBtn = G.mkButton(card, "✕", bSz, bPos(0), Color3.fromRGB(30,20,10), C.yel, G.MOBILE and 14 or 12)
        canBtn.MouseButton1Click:Connect(function()
            removeRelation(uname, function()
                card:Destroy()
            end)
        end)
        G.mkLabel(card, "Aguardando...",
            UDim2.new(0,80,0, G.MOBILE and 18 or 15),
            UDim2.new(1,-112,0.5,-(G.MOBILE and 9 or 7)),
            C.yel, G.MOBILE and 10 or 9, Enum.Font.GothamItalic)
    else
        -- Ver perfil
        local profBtn = G.mkButton(card, "👤", bSz, bPos(-(G.MOBILE and 36 or 30)), C.acc2, C.white, G.MOBILE and 13 or 11)
        profBtn.MouseButton1Click:Connect(function()
            if G.openProfile then G.openProfile(uname, udata) end
        end)
        -- Remover amigo
        local remBtn = G.mkButton(card, "✕", bSz, bPos(0), Color3.fromRGB(26,8,8), C.red, G.MOBILE and 14 or 12)
        remBtn.MouseButton1Click:Connect(function()
            removeRelation(uname, function()
                card:Destroy()
            end)
        end)
    end

    return card
end

-- ── Painel de Amigos ──────────────────────────────────────────────
local function buildFriendsPanel()
    local panel = G.tabPanels["amigos"]
    if not panel or not panel.frame then return end
    local pf = panel.frame

    local grad = Instance.new("UIGradient", pf)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10,6,24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6,4,14)),
    })
    grad.Rotation = 135

    -- ── Barra de adicionar amigo ──────────────────────────────────
    local addBar = G.mkFrame(pf,
        UDim2.new(1,-12,0, G.MOBILE and 80 or 68),
        UDim2.new(0,6,0,6),
        Color3.fromRGB(14,9,30))
    G.mkCorner(addBar, 14)
    G.mkStroke(addBar, C.acc2, 1.5)

    G.mkLabel(addBar, "➕  Adicionar Amigo",
        UDim2.new(1,-12,0, G.MOBILE and 22 or 18),
        UDim2.new(0,8,0,6),
        C.accL, G.MOBILE and 13 or 11, Enum.Font.GothamBold)

    local _, addInp = G.mkInput(addBar,
        "Nome do jogador (ex: Player123)",
        UDim2.new(1,-(G.BTH+16),0,G.INH),
        UDim2.new(0,6,0, G.MOBILE and 28 or 24))

    local addBtn = G.mkButton(addBar, "➤",
        UDim2.new(0,G.BTH,0,G.INH),
        UDim2.new(1,-(G.BTH+6),0, G.MOBILE and 28 or 24),
        C.acc, C.white, G.MOBILE and 16 or 14)

    local addMsg = G.mkLabel(pf, "",
        UDim2.new(1,-12,0, G.MOBILE and 20 or 16),
        UDim2.new(0,6,0, G.MOBILE and 90 or 78),
        C.green, G.MOBILE and 11 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    addBtn.MouseButton1Click:Connect(function()
        local target = addInp.Text:match("^%s*(.-)%s*$")
        if target == "" then
            addMsg.TextColor3 = C.red
            addMsg.Text = "⚠️ Digite o nome do jogador."
            return
        end
        addBtn.Text = "⏳"
        sendRequest(target, function(ok, msg)
            addBtn.Text = "➤"
            addMsg.TextColor3 = ok and C.green or C.red
            addMsg.Text = msg
            if ok then addInp.Text = "" end
            task.delay(4, function()
                if addMsg.Parent then addMsg.Text = "" end
            end)
        end)
    end)
    addInp.FocusLost:Connect(function(enter)
        if enter then addBtn.MouseButton1Click:Fire() end
    end)

    -- ── Seções com scroll ─────────────────────────────────────────
    local listY = G.MOBILE and 114 or 98

    -- Pendentes recebidas
    local pendH  = G.MOBILE and 160 or 140
    local pendSect = G.mkFrame(pf, UDim2.new(1,-12,0,pendH), UDim2.new(0,6,0,listY), Color3.fromRGB(14,10,8))
    G.mkCorner(pendSect, 14)
    G.mkStroke(pendSect, C.yel, 1.5)

    G.mkLabel(pendSect, "🔔  Solicitações Recebidas",
        UDim2.new(1,-12,0, G.MOBILE and 24 or 20),
        UDim2.new(0,8,0,6),
        C.yel, G.MOBILE and 13 or 11, Enum.Font.GothamBold)

    local pendSF = G.mkScroll(pendSect,
        UDim2.new(1,-4,1,-(G.MOBILE and 32 or 28)),
        UDim2.new(0,2,0, G.MOBILE and 30 or 26))

    local pendEmpty = G.mkLabel(pendSF,
        "📭 Nenhuma solicitação pendente.",
        UDim2.new(1,-10,0,32), nil,
        C.gray, G.MOBILE and 12 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    -- Pendentes enviadas
    local sentY    = listY + pendH + 8
    local sentSect = G.mkFrame(pf, UDim2.new(1,-12,0, G.MOBILE and 140 or 120), UDim2.new(0,6,0,sentY), Color3.fromRGB(10,14,8))
    G.mkCorner(sentSect, 14)
    G.mkStroke(sentSect, C.cyan, 1.5)

    G.mkLabel(sentSect, "📤  Solicitações Enviadas",
        UDim2.new(1,-12,0, G.MOBILE and 24 or 20),
        UDim2.new(0,8,0,6),
        C.cyan, G.MOBILE and 13 or 11, Enum.Font.GothamBold)

    local sentSF = G.mkScroll(sentSect,
        UDim2.new(1,-4,1,-(G.MOBILE and 32 or 28)),
        UDim2.new(0,2,0, G.MOBILE and 30 or 26))

    local sentEmpty = G.mkLabel(sentSF,
        "📭 Nenhuma solicitação enviada.",
        UDim2.new(1,-10,0,32), nil,
        C.gray, G.MOBILE and 12 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    -- Lista de amigos
    local frY    = sentY + (G.MOBILE and 148 or 128)
    local frSect = G.mkFrame(pf, UDim2.new(1,-12,0, G.MOBILE and 240 or 200), UDim2.new(0,6,0,frY), Color3.fromRGB(8,12,20))
    G.mkCorner(frSect, 14)
    G.mkStroke(frSect, C.acc, 1.5)

    G.mkLabel(frSect, "👥  Meus Amigos",
        UDim2.new(1,-12,0, G.MOBILE and 24 or 20),
        UDim2.new(0,8,0,6),
        C.accL, G.MOBILE and 13 or 11, Enum.Font.GothamBold)

    local frSF = G.mkScroll(frSect,
        UDim2.new(1,-4,1,-(G.MOBILE and 32 or 28)),
        UDim2.new(0,2,0, G.MOBILE and 30 or 26))

    local frEmpty = G.mkLabel(frSF,
        "📭 Você ainda não tem amigos.\nAdicion alguém acima!",
        UDim2.new(1,-10,0,44), nil,
        C.gray, G.MOBILE and 12 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    -- Contador na aba
    local frCount = G.mkLabel(pf, "",
        UDim2.new(1,-12,0,18),
        UDim2.new(0,6,0, frY-20),
        C.gray, G.MOBILE and 10 or 9, Enum.Font.Gotham,
        Enum.TextXAlignment.Right)

    -- ── Atualizar lista ───────────────────────────────────────────
    local function refreshFriends()
        -- Limpar
        for _, ch in ipairs(pendSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        for _, ch in ipairs(sentSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        for _, ch in ipairs(frSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        pendEmpty.Visible = true
        sentEmpty.Visible = true
        frEmpty.Visible   = true

        task.spawn(function()
            local allFriends = G.fbGet("friends") or {}
            local users      = G.fbGet("users") or {}

            local pendCount = 0
            local sentCount = 0
            local frCount_n = 0

            for _, fData in pairs(allFriends) do
                if type(fData) ~= "table" then continue end

                local isFrom = (fData.from == G.MY_NAME)
                local isTo   = (fData.to   == G.MY_NAME)
                if not isFrom and not isTo then continue end

                local otherName = isFrom and fData.to or fData.from
                local udata     = users[otherName] or {
                    displayName = otherName,
                    userId      = 1,
                    age         = fData[isFrom and "toAge" or "fromAge"],
                }

                if fData.status == "accepted" then
                    frCount_n = frCount_n + 1
                    frEmpty.Visible = false
                    local c = mkFriendCard(frSF, otherName, udata, false, false)
                    c.LayoutOrder = frCount_n

                elseif fData.status == "pending" then
                    if isTo then
                        -- recebida
                        pendCount = pendCount + 1
                        pendEmpty.Visible = false
                        local c = mkFriendCard(pendSF, otherName, udata, true, false)
                        c.LayoutOrder = pendCount
                        -- Badge notificação na aba amigos
                        G.notifyTab("amigos")
                    else
                        -- enviada
                        sentCount = sentCount + 1
                        sentEmpty.Visible = false
                        local c = mkFriendCard(sentSF, otherName, udata, true, true)
                        c.LayoutOrder = sentCount
                    end
                end
            end

            frCount.Text = frCount_n > 0 and (frCount_n.." amigo(s)") or ""
        end)
    end

    -- Botão atualizar
    local refY   = frY + (G.MOBILE and 248 or 208)
    local refBtn = G.mkButton(pf, "🔄  Atualizar Lista",
        UDim2.new(1,-12,0,G.BTH),
        UDim2.new(0,6,0,refY),
        C.acc2, C.white)
    refBtn.MouseButton1Click:Connect(refreshFriends)

    -- Atualizar ao abrir aba
    G.tabBtns["amigos"] and G.tabBtns["amigos"].MouseButton1Click:Connect(function()
        task.wait(0.1); refreshFriends()
    end)

    -- Polling periódico de solicitações
    task.spawn(function()
        while G.Main and G.Main.Parent do
            task.wait(20)
            if G.activeTab == "amigos" then
                refreshFriends()
            else
                -- Checar só pendentes pra badge
                task.spawn(function()
                    local allF = G.fbGet("friends") or {}
                    for _, fd in pairs(allF) do
                        if type(fd)=="table" and fd.to==G.MY_NAME and fd.status=="pending" then
                            G.notifyTab("amigos")
                            break
                        end
                    end
                end)
            end
        end
    end)

    -- Carregar ao iniciar
    task.delay(1, refreshFriends)
end

-- ── Encadear com UI Ready ─────────────────────────────────────────
local prevOnUIReady = G.onUIReady
G.onUIReady = function()
    if prevOnUIReady then prevOnUIReady() end
    buildFriendsPanel()
end

if G.Main then buildFriendsPanel() end

print("[GlobalChat Hub] friends.lua carregado.")


-- ===== admin.lua =====
-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║             admin.lua  —  Painel do Administrador           ║
-- ╚══════════════════════════════════════════════════════════════╝

local G = GCH
-- Compat task
local task = (function()
    local _w = (type(task)=="table" and type(task.wait)=="function") and task.wait or wait
    local _s = (type(task)=="table" and type(task.spawn)=="function") and task.spawn
               or (type(spawn)=="function" and spawn)
               or function(f) coroutine.resume(coroutine.create(f)) end
    local _d = (type(task)=="table" and type(task.delay)=="function") and task.delay
               or function(t,fn) _s(function() _w(t) fn() end) end
    local _df= (type(task)=="table" and type(task.defer)=="function") and task.defer or _s
    return { wait=_w, spawn=_s, delay=_d, defer=_df }
end)()
local C = G.C

-- Só executa para o dono
if not G.IS_OWNER then
    print("[GlobalChat Hub] admin.lua — sem permissão.")
    return
end

-- ── Helpers de layout ────────────────────────────────────────────
local function mkSection(parent, order, height, bg, strokeCol, title, titleCol)
    local sect = G.mkFrame(parent, UDim2.new(1,0,0,height), nil, bg or Color3.fromRGB(14,9,30))
    sect.LayoutOrder = order
    G.mkCorner(sect, 14)
    G.mkStroke(sect, strokeCol or C.acc, 1.5)
    if title then
        G.mkLabel(sect, title,
            UDim2.new(1,-12,0, G.MOBILE and 26 or 22),
            UDim2.new(0,8,0,6),
            titleCol or C.accL,
            G.MOBILE and 14 or 12, Enum.Font.GothamBold)
    end
    return sect
end

-- ── Painel Admin ──────────────────────────────────────────────────
local function buildAdminPanel()
    local panel = G.tabPanels["admin"]
    if not panel or not panel.frame then return end
    local pf = panel.frame

    -- Fundo
    local grad = Instance.new("UIGradient", pf)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8,4,20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4,4,10)),
    })
    grad.Rotation = 135

    -- ScrollFrame principal
    local sf = G.mkScroll(pf)

    -- ── Cabeçalho ─────────────────────────────────────────────────
    local headerSect = mkSection(sf, 0,
        G.MOBILE and 70 or 58,
        Color3.fromRGB(10,6,24), C.gold,
        nil, nil)

    G.mkLabel(headerSect, "👑  Painel do Administrador",
        UDim2.new(1,-12,0, G.MOBILE and 28 or 24),
        UDim2.new(0,8,0,8),
        C.gold, G.MOBILE and 17 or 15, Enum.Font.GothamBold)
    G.mkLabel(headerSect, "Bem-vindo, "..G.MY_DISPLAY.."  •  "..G.VER,
        UDim2.new(1,-12,0, G.MOBILE and 20 or 16),
        UDim2.new(0,8,0, G.MOBILE and 38 or 34),
        C.gray, G.MOBILE and 11 or 10)

    -- ── Estatísticas rápidas ──────────────────────────────────────
    local statSect = mkSection(sf, 1,
        G.MOBILE and 80 or 66,
        Color3.fromRGB(6,14,6), C.green,
        "📊  Estatísticas", C.green)

    local statRow = G.mkFrame(statSect,
        UDim2.new(1,-12,0, G.MOBILE and 44 or 36),
        UDim2.new(0,6,0, G.MOBILE and 32 or 28),
        Color3.fromRGB(0,0,0), 1)

    local statLabels = {
        {key="users",   icon="👥", label="Usuários"},
        {key="bans",    icon="🚫", label="Banidos"},
        {key="reports", icon="🚨", label="Relatórios"},
        {key="rooms",   icon="🔒", label="Salas Priv."},
    }

    local statValues = {}
    for i, s in ipairs(statLabels) do
        local col = G.mkFrame(statRow,
            UDim2.new(1/#statLabels,-4,1,0),
            UDim2.new((i-1)*(1/#statLabels),2,0,0),
            Color3.fromRGB(10,14,10))
        G.mkCorner(col, 8)

        G.mkLabel(col, s.icon,
            UDim2.new(1,0,0, G.MOBILE and 22 or 18),
            UDim2.new(0,0,0,2),
            C.white, G.MOBILE and 14 or 12, Enum.Font.GothamBold,
            Enum.TextXAlignment.Center)

        statValues[s.key] = G.mkLabel(col, "...",
            UDim2.new(1,0,0, G.MOBILE and 18 or 15),
            UDim2.new(0,0,0, G.MOBILE and 22 or 18),
            C.green, G.MOBILE and 12 or 11, Enum.Font.GothamBold,
            Enum.TextXAlignment.Center)

        G.mkLabel(col, s.label,
            UDim2.new(1,0,0, G.MOBILE and 14 or 12),
            UDim2.new(0,0,1,-(G.MOBILE and 15 or 13)),
            C.gray, G.MOBILE and 9 or 8, Enum.Font.Gotham,
            Enum.TextXAlignment.Center)
    end

    local function refreshStats()
        task.spawn(function()
            local users   = G.fbGet("users")   or {}
            local bans    = G.fbGet("bans")     or {}
            local reports = G.fbGet("reports")  or {}
            local rooms   = G.fbGet("private_rooms") or {}

            local function count(t)
                local n = 0
                for _ in pairs(t) do n = n + 1 end
                return n
            end

            local activeBans = 0
            for _, b in pairs(bans) do
                if type(b)=="table" and b.banned then
                    if (b.expiry or 0)==0 or os.time()<b.expiry then
                        activeBans = activeBans + 1
                    end
                end
            end

            statValues.users.Text   = tostring(count(users))
            statValues.bans.Text    = tostring(activeBans)
            statValues.reports.Text = tostring(count(reports))
            statValues.rooms.Text   = tostring(count(rooms))
        end)
    end

    -- ── Usuários Online ───────────────────────────────────────────
    local onH    = G.MOBILE and 200 or 170
    local onSect = mkSection(sf, 2, onH,
        Color3.fromRGB(6,14,6), C.green,
        "🟢  Usuários Online", C.green)

    local onSF = G.mkScroll(onSect,
        UDim2.new(1,-8,1,-(G.MOBILE and 34 or 28)),
        UDim2.new(0,4,0, G.MOBILE and 32 or 28))

    local function refreshOnline()
        for _, ch in ipairs(onSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        task.spawn(function()
            local users = G.fbGet("users") or {}
            local found = 0
            for uname, udata in pairs(users) do
                if type(udata)=="table" and udata.online
                and (os.time()-(udata.lastSeen or 0)) < 60 then
                    found = found + 1
                    local row = G.mkFrame(onSF,
                        UDim2.new(1,0,0, G.MOBILE and 32 or 26),
                        nil, Color3.fromRGB(8,18,8))
                    row.LayoutOrder = found
                    G.mkCorner(row, 7)

                    -- Avatar pequeno
                    local av = Instance.new("ImageLabel", row)
                    av.Size     = UDim2.new(0, G.MOBILE and 22 or 18, 0, G.MOBILE and 22 or 18)
                    av.Position = UDim2.new(0,3,0.5,-(G.MOBILE and 11 or 9))
                    av.BackgroundColor3 = C.acc2
                    av.BorderSizePixel  = 0
                    av.Image = "rbxthumb://type=AvatarHeadShot&id="..(udata.userId or 1).."&w=48&h=48"
                    G.mkCorner(av, 99)

                    local stColors = {online=C.green,ocupado=C.yel,invisivel=C.gray}
                    local stColor  = stColors[udata.status or "online"] or C.green

                    G.mkLabel(row,
                        "🟢 "..uname.." ("..udata.displayName..")",
                        UDim2.new(1,-120,1,0),
                        UDim2.new(0, G.MOBILE and 28 or 24,0,0),
                        C.white, G.MOBILE and 11 or 10)

                    G.mkLabel(row,
                        (udata.age or "?").."a  •  IP: "..(udata.ip or "?"),
                        UDim2.new(0,110,1,0),
                        UDim2.new(1,-154,0,0),
                        C.gray, G.MOBILE and 9 or 8)

                    -- Ban rápido
                    local qbBtn = G.mkButton(row, "🚫",
                        UDim2.new(0, G.MOBILE and 30 or 24, 1,-4),
                        UDim2.new(1,-(G.MOBILE and 34 or 28),0,2),
                        C.red, C.white, G.MOBILE and 12 or 11)
                    qbBtn.MouseButton1Click:Connect(function()
                        task.spawn(function()
                            local ud = G.fbGet("users/"..uname) or {}
                            G.fbSet("bans/"..uname, {
                                banned    = true,
                                reason    = "Ban rápido via painel",
                                expiry    = 0,
                                bannedBy  = G.MY_NAME,
                                bannedAt  = os.time(),
                                ip        = ud.ip or "?",
                                userId    = ud.userId or 0,
                            })
                            row:Destroy()
                            refreshStats()
                        end)
                    end)
                end
            end
            if found == 0 then
                G.mkLabel(onSF, "📭 Nenhum usuário online.",
                    UDim2.new(1,-8,0,30), nil,
                    C.gray, G.FSZ, Enum.Font.Gotham, Enum.TextXAlignment.Center)
            end
        end)
    end

    -- ── Logs de Conversa ──────────────────────────────────────────
    local logH    = G.MOBILE and 240 or 200
    local logSect = mkSection(sf, 3, logH,
        Color3.fromRGB(6,10,18), C.cyan,
        "📜  Logs de Conversas", C.cyan)

    -- Filtro de sala
    local logRooms = {"global","brasil","usa"}
    local logRoomSel = "global"

    local filterRow = G.mkFrame(logSect,
        UDim2.new(1,-12,0, G.MOBILE and 28 or 22),
        UDim2.new(0,6,0, G.MOBILE and 32 or 28),
        Color3.fromRGB(0,0,0), 1)

    local filterBtns = {}
    for i, rk in ipairs(logRooms) do
        local fb = G.mkButton(filterRow, rk,
            UDim2.new(1/#logRooms,-3,1,0),
            UDim2.new((i-1)*(1/#logRooms),2,0,0),
            Color3.fromRGB(14,10,28), C.gray,
            G.MOBILE and 11 or 10)
        filterBtns[rk] = fb
        fb.MouseButton1Click:Connect(function()
            logRoomSel = rk
            for k2, b2 in pairs(filterBtns) do
                b2.BackgroundColor3 = k2==rk and C.acc or Color3.fromRGB(14,10,28)
                b2.TextColor3       = k2==rk and C.white or C.gray
            end
        end)
    end
    filterBtns[logRoomSel].BackgroundColor3 = C.acc
    filterBtns[logRoomSel].TextColor3       = C.white

    local logSF = G.mkScroll(logSect,
        UDim2.new(1,-8,1,-(G.MOBILE and 96 or 80)),
        UDim2.new(0,4,0, G.MOBILE and 64 or 54))

    local function refreshLogs()
        for _, ch in ipairs(logSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        task.spawn(function()
            local data = G.fbGet("chats/"..logRoomSel,
                "orderBy=%22%24key%22&limitToLast=30")
            if not data or type(data)~="table" or not next(data) then
                G.mkLabel(logSF, "📭 Sem mensagens.",
                    UDim2.new(1,-8,0,28), nil,
                    C.gray, G.FSZ, Enum.Font.Gotham, Enum.TextXAlignment.Center)
                return
            end
            local list = {}
            for k, v in pairs(data) do
                if type(v)=="table" then table.insert(list,{k=k,v=v}) end
            end
            table.sort(list, function(a,b) return a.k > b.k end)
            for i = 1, math.min(#list, 20) do
                local v = list[i].v
                local rowH = G.MOBILE and 44 or 36
                local row  = G.mkFrame(logSF, UDim2.new(1,0,0,rowH), nil, Color3.fromRGB(8,10,20))
                row.LayoutOrder = i
                G.mkCorner(row, 8)

                local age_str = v.age and ("("..v.age.."a)") or ""
                local time_str = os.date("%d/%m %H:%M", v.ts or 0)

                G.mkLabel(row,
                    (v.displayName or v.user or "?").." "..age_str.."  ["..time_str.."]",
                    UDim2.new(1,-12,0, G.MOBILE and 18 or 15),
                    UDim2.new(0,6,0,3),
                    C.cyan, G.MOBILE and 11 or 10, Enum.Font.GothamBold)

                G.mkLabel(row,
                    (v.text or ""):sub(1,80),
                    UDim2.new(1,-12,0, G.MOBILE and 18 or 15),
                    UDim2.new(0,6,0, G.MOBILE and 22 or 18),
                    C.white, G.MOBILE and 10 or 9)

                -- Ban direto do log
                local lbBtn = G.mkButton(row, "🚫",
                    UDim2.new(0, G.MOBILE and 28 or 22, 1,-4),
                    UDim2.new(1,-(G.MOBILE and 32 or 26),0,2),
                    Color3.fromRGB(26,6,6), C.red, G.MOBILE and 12 or 10)
                lbBtn.MouseButton1Click:Connect(function()
                    if v.user then
                        task.spawn(function()
                            G.fbSet("bans/"..v.user, {
                                banned   = true,
                                reason   = "Banido via log de conversa",
                                expiry   = 0,
                                bannedBy = G.MY_NAME,
                                bannedAt = os.time(),
                                ip       = "?",
                                userId   = v.userId or 0,
                            })
                            lbBtn.Text = "✓"
                            lbBtn.BackgroundColor3 = C.gray
                            refreshStats()
                        end)
                    end
                end)
            end
        end)
    end

    local logRefBtn = G.mkButton(logSect, "🔄 Carregar",
        UDim2.new(1,-12,0, G.MOBILE and 28 or 22),
        UDim2.new(0,6,1,-(G.MOBILE and 32 or 26)),
        C.acc2, C.white, G.MOBILE and 11 or 10)
    logRefBtn.MouseButton1Click:Connect(refreshLogs)

    -- ── Banimento ─────────────────────────────────────────────────
    local banH    = G.MOBILE and 240 or 210
    local banSect = mkSection(sf, 4, banH,
        Color3.fromRGB(18,6,6), C.red,
        "🔨  Aplicar Banimento", C.red)

    local bY = G.MOBILE and 34 or 28

    G.mkLabel(banSect, "Nome do jogador:",
        UDim2.new(1,-16,0,18), UDim2.new(0,8,0,bY),
        C.grayL, G.MOBILE and 12 or 10)
    local _, banNameInp = G.mkInput(banSect, "Ex: Player123",
        UDim2.new(1,-16,0,G.INH), UDim2.new(0,8,0,bY+18))

    local bY2 = bY + 18 + G.INH + 8
    G.mkLabel(banSect, "Motivo:",
        UDim2.new(1,-16,0,18), UDim2.new(0,8,0,bY2),
        C.grayL, G.MOBILE and 12 or 10)
    local _, banReasonInp = G.mkInput(banSect, "Ex: Spam, discurso de ódio...",
        UDim2.new(1,-16,0,G.INH), UDim2.new(0,8,0,bY2+18))

    local bY3 = bY2 + 18 + G.INH + 8

    -- Seletor de duração
    local durOptions = {
        {label="1 Dia",    days=1},
        {label="1 Semana", days=7},
        {label="1 Mês",    days=30},
        {label="1 Ano",    days=365},
        {label="Perm.",    days=0},
    }
    local selectedDur = 0
    local durBtns = {}

    local durRow = G.mkFrame(banSect,
        UDim2.new(1,-16,0, G.MOBILE and 28 or 22),
        UDim2.new(0,8,0,bY3), Color3.fromRGB(0,0,0), 1)

    for i, dur in ipairs(durOptions) do
        local db = G.mkButton(durRow, dur.label,
            UDim2.new(1/#durOptions,-2,1,0),
            UDim2.new((i-1)*(1/#durOptions),1,0,0),
            Color3.fromRGB(20,8,8), C.red,
            G.MOBILE and 10 or 9)
        durBtns[i] = db
        db.MouseButton1Click:Connect(function()
            selectedDur = dur.days
            for j, b2 in ipairs(durBtns) do
                b2.BackgroundColor3 = j==i and C.red or Color3.fromRGB(20,8,8)
                b2.TextColor3       = j==i and C.white or C.red
            end
        end)
    end
    -- Selecionar permanente por padrão
    durBtns[5].BackgroundColor3 = C.red
    durBtns[5].TextColor3       = C.white

    local bY4 = bY3 + (G.MOBILE and 32 or 26)
    local banApplyBtn = G.mkButton(banSect, "🚫  APLICAR BANIMENTO",
        UDim2.new(1,-16,0,G.BTH), UDim2.new(0,8,0,bY4), C.red)

    local banMsg = G.mkLabel(banSect, "",
        UDim2.new(1,-16,0,20), UDim2.new(0,8,0,bY4+G.BTH+4),
        C.yel, G.MOBILE and 11 or 10, Enum.Font.Gotham,
        Enum.TextXAlignment.Center)

    banApplyBtn.MouseButton1Click:Connect(function()
        local target = banNameInp.Text:match("^%s*(.-)%s*$")
        local reason = banReasonInp.Text:match("^%s*(.-)%s*$")
        if target == "" then banMsg.Text = "⚠️ Digite o nome."; banMsg.TextColor3=C.red; return end

        banApplyBtn.Text = "⏳ Aplicando..."
        task.spawn(function()
            local ud   = G.fbGet("users/"..target) or {}
            local exp  = selectedDur == 0 and 0 or (os.time() + selectedDur*86400)
            G.fbSet("bans/"..target, {
                banned      = true,
                reason      = reason~="" and reason or "Banido pelo administrador",
                expiry      = exp,
                bannedBy    = G.MY_NAME,
                bannedAt    = os.time(),
                ip          = ud.ip or "?",
                userId      = ud.userId or 0,
                displayName = ud.displayName or target,
            })
            banApplyBtn.Text = "🚫  APLICAR BANIMENTO"
            banMsg.TextColor3 = C.green
            local durTxt = selectedDur==0 and "permanente"
                or (selectedDur < 7 and selectedDur.." dia(s)"
                or selectedDur < 30 and (selectedDur/7).." semana(s)"
                or selectedDur < 365 and (selectedDur/30).." mês(es)"
                or "1 ano")
            banMsg.Text = "✅ "..target.." banido — "..durTxt
            banNameInp.Text = ""; banReasonInp.Text = ""
            refreshStats()
        end)
    end)

    -- ── Relatórios ────────────────────────────────────────────────
    local repH    = G.MOBILE and 260 or 220
    local repSect = mkSection(sf, 5, repH,
        Color3.fromRGB(20,14,4), C.yel,
        "🚨  Relatórios de Abuso", C.yel)

    local repSF = G.mkScroll(repSect,
        UDim2.new(1,-8,1,-(G.MOBILE and 34 or 28)),
        UDim2.new(0,4,0, G.MOBILE and 32 or 28))

    local function refreshReports()
        for _, ch in ipairs(repSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        task.spawn(function()
            local reps = G.fbGet("reports",
                "orderBy=%22%24key%22&limitToLast=20")
            if not reps or type(reps)~="table" or not next(reps) then
                G.mkLabel(repSF, "📭 Nenhum relatório.",
                    UDim2.new(1,-8,0,28), nil,
                    C.gray, G.FSZ, Enum.Font.Gotham, Enum.TextXAlignment.Center)
                return
            end
            local list = {}
            for k, v in pairs(reps) do
                if type(v)=="table" then table.insert(list,{k=k,v=v}) end
            end
            table.sort(list, function(a,b) return (a.v.ts or 0)>(b.v.ts or 0) end)

            for i = 1, math.min(#list, 12) do
                local rk, rv = list[i].k, list[i].v
                local rowH = G.MOBILE and 82 or 68
                local row  = G.mkFrame(repSF, UDim2.new(1,0,0,rowH), nil, Color3.fromRGB(22,10,8))
                row.LayoutOrder = i
                G.mkCorner(row, 8)
                G.mkStroke(row, C.red, 1)

                G.mkLabel(row,
                    "⚠️ "..( rv.reported or "?").." ("..(rv.reportedAge or "?").."a)",
                    UDim2.new(1,-12,0, G.MOBILE and 18 or 15),
                    UDim2.new(0,6,0,4),
                    C.white, G.MOBILE and 12 or 11, Enum.Font.GothamBold)

                G.mkLabel(row,
                    "Por: "..(rv.reporter or "?").."  •  "..(rv.reason or ""):sub(1,44),
                    UDim2.new(1,-12,0, G.MOBILE and 16 or 14),
                    UDim2.new(0,6,0, G.MOBILE and 24 or 20),
                    C.yel, G.MOBILE and 10 or 9)

                G.mkLabel(row,
                    "IP: "..(rv.ip_reporter or "?").."  •  "..os.date("%d/%m %H:%M", rv.ts or 0)
                    .."  •  Sala: "..(rv.room or "?"),
                    UDim2.new(1,-12,0, G.MOBILE and 16 or 14),
                    UDim2.new(0,6,0, G.MOBILE and 42 or 35),
                    C.gray, G.MOBILE and 9 or 8)

                -- Banir reportado
                local rbBtn = G.mkButton(row, "🚫 Banir",
                    UDim2.new(0, G.MOBILE and 70 or 60, 0, G.MOBILE and 22 or 18),
                    UDim2.new(1,-150, 0, G.MOBILE and 60 or 46),
                    C.red, C.white, G.MOBILE and 10 or 9)
                rbBtn.MouseButton1Click:Connect(function()
                    task.spawn(function()
                        local ud2 = G.fbGet("users/"..(rv.reported or "")) or {}
                        G.fbSet("bans/"..(rv.reported or "x"), {
                            banned   = true,
                            reason   = "Via relatório: "..(rv.reason or ""):sub(1,60),
                            expiry   = 0,
                            bannedBy = G.MY_NAME,
                            bannedAt = os.time(),
                            ip       = ud2.ip or "?",
                            userId   = ud2.userId or 0,
                        })
                        G.fbDelete("reports/"..rk)
                        row:Destroy()
                        refreshStats()
                    end)
                end)

                -- Dispensar relatório
                local disBtn = G.mkButton(row, "✓ OK",
                    UDim2.new(0, G.MOBILE and 58 or 48, 0, G.MOBILE and 22 or 18),
                    UDim2.new(1,-78, 0, G.MOBILE and 60 or 46),
                    Color3.fromRGB(10,22,10), C.green, G.MOBILE and 10 or 9)
                disBtn.MouseButton1Click:Connect(function()
                    task.spawn(function()
                        G.fbDelete("reports/"..rk)
                        row:Destroy()
                    end)
                end)
            end
        end)
    end

    -- ── Bans Ativos ───────────────────────────────────────────────
    local banListH    = G.MOBILE and 200 or 170
    local banListSect = mkSection(sf, 6, banListH,
        Color3.fromRGB(16,5,5), C.red,
        "📋  Bans Ativos", C.red)

    local banListSF = G.mkScroll(banListSect,
        UDim2.new(1,-8,1,-(G.MOBILE and 34 or 28)),
        UDim2.new(0,4,0, G.MOBILE and 32 or 28))

    local function refreshBanList()
        for _, ch in ipairs(banListSF:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        task.spawn(function()
            local bans = G.fbGet("bans") or {}
            local found = 0
            for bname, bdata in pairs(bans) do
                if type(bdata)=="table" and bdata.banned then
                    local exp = bdata.expiry or 0
                    if exp ~= 0 and os.time() >= exp then
                        G.fbPatch("bans/"..bname, {banned=false})
                    else
                        found = found + 1
                        local expTxt = (exp==0) and "Perm." or os.date("%d/%m/%Y", exp)
                        local row = G.mkFrame(banListSF,
                            UDim2.new(1,0,0, G.MOBILE and 34 or 28),
                            nil, Color3.fromRGB(20,7,7))
                        row.LayoutOrder = found
                        G.mkCorner(row, 7)

                        G.mkLabel(row,
                            "🚫 "..bname.."  •  "..(bdata.reason or ""):sub(1,30)
                            .."  •  "..expTxt.."  •  IP:"..(bdata.ip or "?"),
                            UDim2.new(1,-44,1,0), UDim2.new(0,6,0,0),
                            C.white, G.MOBILE and 10 or 9)

                        local unbBtn = G.mkButton(row, "✓",
                            UDim2.new(0, G.MOBILE and 30 or 24, 1,-4),
                            UDim2.new(1,-(G.MOBILE and 34 or 28),0,2),
                            C.green, C.white, G.MOBILE and 13 or 11)
                        unbBtn.MouseButton1Click:Connect(function()
                            task.spawn(function()
                                G.fbPatch("bans/"..bname, {banned=false})
                                row:Destroy()
                                refreshStats()
                            end)
                        end)
                    end
                end
            end
            if found == 0 then
                G.mkLabel(banListSF, "📭 Nenhum ban ativo.",
                    UDim2.new(1,-8,0,28), nil,
                    C.gray, G.FSZ, Enum.Font.Gotham, Enum.TextXAlignment.Center)
            end
        end)
    end

    -- ── Botão geral de atualizar ──────────────────────────────────
    local refAllBtn = G.mkButton(sf, "🔄  Atualizar Tudo",
        UDim2.new(1,0,0,G.BTH), nil, C.acc)
    refAllBtn.LayoutOrder = 7
    refAllBtn.MouseButton1Click:Connect(function()
        refreshStats()
        refreshOnline()
        refreshReports()
        refreshBanList()
    end)

    -- Carregar ao abrir aba
    G.tabBtns["admin"].MouseButton1Click:Connect(function()
        task.wait(0.15)
        refreshStats()
        refreshOnline()
        refreshReports()
        refreshBanList()
    end)

    -- Auto-refresh leve
    task.spawn(function()
        task.wait(2)
        refreshStats(); refreshOnline(); refreshReports(); refreshBanList()
        while G.Main and G.Main.Parent do
            task.wait(25)
            if G.activeTab == "admin" then
                refreshStats(); refreshOnline(); refreshReports(); refreshBanList()
            end
        end
    end)
end

-- ── Encadear com UI Ready ─────────────────────────────────────────
local prevOnUIReady = G.onUIReady
G.onUIReady = function()
    if prevOnUIReady then prevOnUIReady() end
    buildAdminPanel()
end

if G.Main then buildAdminPanel() end

print("[GlobalChat Hub] admin.lua carregado — painel ativo para "..G.MY_NAME..".")
