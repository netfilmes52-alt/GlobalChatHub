-- ╔═══════════════════════════════════════════════════════╗
-- ║       GlobalChat Hub v3.0 — CORE                     ║
-- ║   Firebase • HTTP • Variáveis • Sons • Cores         ║
-- ╚═══════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════
-- CONFIGURAÇÕES GLOBAIS
-- ═══════════════════════════════════════════════════════
-- Compatibilidade total com Delta e outros executors
do
    local _wait  = (type(task)=="table" and type(task.wait)=="function")  and task.wait  or wait
    local _spawn = (type(task)=="table" and type(task.spawn)=="function") and task.spawn or
                   (type(spawn)=="function" and spawn) or
                   function(f) coroutine.resume(coroutine.create(f)) end
    local _delay = (type(task)=="table" and type(task.delay)=="function") and task.delay or
                   (type(delay)=="function" and delay) or
                   function(t,f) _spawn(function() _wait(t) f() end) end
    local _defer = (type(task)=="table" and type(task.defer)=="function") and task.defer or _spawn
    task = { wait=_wait, spawn=_spawn, delay=_delay, defer=_defer }
end

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
    httpReq({Url=fbURL(p), Method="DELETE"})
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
}

-- ═══════════════════════════════════════════════════════
-- RESPONSIVIDADE
-- ═══════════════════════════════════════════════════════
local mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
GCH.mobile   = mobile
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
