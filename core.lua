-- ╔═══════════════════════════════════════════════════════╗
-- ║       GlobalChat Hub v3.1 — CORE  (corrigido)        ║
-- ╚═══════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════
-- COMPATIBILIDADE task.* (Delta mobile safe)
-- ═══════════════════════════════════════════════════════
if type(task) ~= "table" then task = {} end
if type(task.wait)  ~= "function" then task.wait  = (type(wait)  == "function") and wait  or function(t) local e=os.clock()+(t or 0) while os.clock()<e do end end end
if type(task.spawn) ~= "function" then task.spawn = (type(spawn) == "function") and spawn or function(f,...) local a={...} local co=coroutine.create(function() f(table.unpack(a)) end) coroutine.resume(co) return co end end
if type(task.delay) ~= "function" then task.delay = (type(delay) == "function") and delay or function(t,f,...) local a={...} task.spawn(function() task.wait(t) f(table.unpack(a)) end) end end
if type(task.defer) ~= "function" then task.defer = task.spawn end
if not table.unpack then table.unpack = unpack end

GCH = GCH or {}
local G = GCH

GCH.FB         = "https://scriptroblox-adede-default-rtdb.firebaseio.com"
GCH.POLL       = 3
GCH.MAX_MSG    = 50
GCH.ROOM_TTL   = 30
GCH.OWNER_NAME = "marceloeduafr10"
GCH.OWNER_ID   = 4620525187
GCH.VER        = "v3.1"

-- ═══════════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════════
local function getSvc(n) local ok,s=pcall(game.GetService,game,n) return ok and s or nil end

GCH.Players  = getSvc("Players")  or game:GetService("Players")
GCH.UIS      = getSvc("UserInputService")
GCH.TweenSvc = getSvc("TweenService")
GCH.HttpSvc  = getSvc("HttpService")
GCH.SoundSvc = getSvc("SoundService")
GCH.TelSvc   = getSvc("TeleportService")  -- pode ser nil

local Players  = GCH.Players
local UIS      = GCH.UIS
local TweenSvc = GCH.TweenSvc
local HttpSvc  = GCH.HttpSvc
local SoundSvc = GCH.SoundSvc

-- ═══════════════════════════════════════════════════════
-- JOGADOR LOCAL
-- ═══════════════════════════════════════════════════════
local _plr = Players.LocalPlayer
if not _plr then
    local t0=tick()
    repeat task.wait(0.05) _plr=Players.LocalPlayer until _plr or (tick()-t0>10)
end
if not _plr then error("[GCH] LocalPlayer não encontrado") end

GCH.ME         = _plr
GCH.MY_NAME    = _plr.Name
GCH.MY_ID      = _plr.UserId
GCH.IS_OWNER   = (GCH.MY_NAME==GCH.OWNER_NAME or GCH.MY_ID==GCH.OWNER_ID)
GCH.MY_IP      = "..."
GCH.MY_AGE     = 0
GCH.MY_DISPLAY = _plr.Name
GCH.MY_STATUS  = "online"
GCH.MY_GAME    = tostring(game.PlaceId)

-- ═══════════════════════════════════════════════════════
-- HTTP — detecção robusta para Delta mobile
-- ═══════════════════════════════════════════════════════
local httpFn, httpNome = nil, "nenhuma"
for _, c in ipairs({
    {n="request",      f=function() return type(request)      =="function" and request      or nil end},
    {n="syn.request",  f=function() return syn  and type(syn.request)  =="function" and syn.request  or nil end},
    {n="http.request", f=function() return http and type(http.request) =="function" and http.request or nil end},
    {n="http_request", f=function() return type(http_request) =="function" and http_request or nil end},
    {n="fluxus",       f=function() return fluxus and type(fluxus.request)=="function" and fluxus.request or nil end},
}) do
    local ok,r=pcall(c.f) if ok and r then httpFn=r; httpNome=c.n; break end
end

local usandoHttpService = false
if not httpFn then
    if pcall(function() HttpSvc:GetAsync(GCH.FB.."/.json",true) end) then
        usandoHttpService=true; httpNome="HttpService"
    end
end

local function httpReq(opts)
    local method = (opts.Method or "GET"):upper()
    -- DELETE não suportado no Delta mobile → emula com PUT null
    if method == "DELETE" then
        opts = { Url=opts.Url, Method="PUT",
                 Headers={["Content-Type"]="application/json"}, Body="null" }
    end
    if usandoHttpService then
        local ok,res=pcall(function()
            if (opts.Method or "GET")=="GET" then return HttpSvc:GetAsync(opts.Url,true)
            else return HttpSvc:PostAsync(opts.Url, opts.Body or "null", Enum.HttpContentType.ApplicationJson) end
        end)
        return ok and {Success=true,StatusCode=200,Body=tostring(res)} or nil
    end
    if not httpFn then return nil end
    local ok,res=pcall(httpFn,opts)
    return ok and res or nil
end
GCH.httpReq  = httpReq
GCH.httpNome = httpNome

-- ═══════════════════════════════════════════════════════
-- FIREBASE
-- ═══════════════════════════════════════════════════════
local function fbURL(p) return GCH.FB.."/"..p..".json" end

local function fbGet(path, query)
    local url=fbURL(path)
    if query then url=url.."?"..query end
    local r=httpReq({Url=url,Method="GET"})
    if not r then return nil end
    local body=r.Body or r.body or ""
    if body=="null" or body=="" then return {} end
    local ok,d=pcall(HttpSvc.JSONDecode,HttpSvc,body)
    return ok and d or nil
end

local function fbSet(p,d)
    httpReq({Url=fbURL(p),Method="PUT",
        Headers={["Content-Type"]="application/json"},Body=HttpSvc:JSONEncode(d)})
end

local function fbPost(p,d)
    local r=httpReq({Url=fbURL(p),Method="POST",
        Headers={["Content-Type"]="application/json"},Body=HttpSvc:JSONEncode(d)})
    if r then local ok,v=pcall(HttpSvc.JSONDecode,HttpSvc,r.Body or "") return ok and v or nil end
end

local function fbPatch(p,d)
    httpReq({Url=fbURL(p),Method="PATCH",
        Headers={["Content-Type"]="application/json"},Body=HttpSvc:JSONEncode(d)})
end

-- DELETE: emulado com PUT null (compatível com Delta mobile)
local function fbDelete(p)
    httpReq({Url=fbURL(p),Method="PUT",
        Headers={["Content-Type"]="application/json"},Body="null"})
end

GCH.fbGet=fbGet; GCH.fbSet=fbSet; GCH.fbPost=fbPost
GCH.fbPatch=fbPatch; GCH.fbDelete=fbDelete

-- ═══════════════════════════════════════════════════════
-- IP (background)
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    local ok,r=pcall(httpReq,{Url="https://api.ipify.org?format=json",Method="GET"})
    if ok and r then
        local ok2,d=pcall(HttpSvc.JSONDecode,HttpSvc,r.Body or "")
        if ok2 and d and d.ip then GCH.MY_IP=d.ip end
    end
end)

-- ═══════════════════════════════════════════════════════
-- BAN CHECK
-- ═══════════════════════════════════════════════════════
GCH.IS_BANNED = false
GCH.BAN_DATA  = nil

task.spawn(function()
    task.wait(1.5)
    local ok,ban=pcall(fbGet,"bans/"..GCH.MY_NAME)
    if ok and ban and type(ban)=="table" and ban.banned then
        local exp=ban.expiry or 0
        if exp==0 or os.time()<exp then
            GCH.IS_BANNED=true; GCH.BAN_DATA=ban
        else
            pcall(fbPatch,"bans/"..GCH.MY_NAME,{banned=false})
        end
    end
end)

-- checkBan: chamado pela ui.lua após splash screen
-- Aguarda o ban check assíncrono terminar e chama o callback correto
function GCH.checkBan(onBanned, onOk)
    task.spawn(function()
        -- Espera o ban check terminar (máximo 4s)
        local t0=tick()
        while not GCH.BAN_DATA and not GCH.IS_BANNED and (tick()-t0)<4 do
            -- Se ainda está carregando, espera mais um pouco
            local rawBan=fbGet("bans/"..GCH.MY_NAME)
            if rawBan and type(rawBan)=="table" and rawBan.banned then
                local exp=rawBan.expiry or 0
                if exp==0 or os.time()<exp then
                    GCH.IS_BANNED=true; GCH.BAN_DATA=rawBan
                end
            end
            break
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
        pcall(fbPatch,"users/"..GCH.MY_NAME,{
            online=GCH.MY_STATUS~="invisivel", status=GCH.MY_STATUS,
            lastSeen=os.time(), ip=GCH.MY_IP, gameId=GCH.MY_GAME,
            gameName=tostring(game.Name), displayName=GCH.MY_DISPLAY,
            age=GCH.MY_AGE, userId=GCH.MY_ID,
        })
    end)
end

pcall(function()
    GCH.ME.AncestryChanged:Connect(function()
        pcall(fbPatch,"users/"..GCH.MY_NAME,{online=false,lastSeen=os.time(),status="offline"})
    end)
end)

-- ═══════════════════════════════════════════════════════
-- TRADUÇÃO
-- ═══════════════════════════════════════════════════════
function GCH.translateText(text,lang,cb)
    lang=lang or "pt"
    task.spawn(function()
        local url="https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
            ..lang.."&dt=t&q="..HttpSvc:UrlEncode(text)
        local ok,r=pcall(httpReq,{Url=url,Method="GET"})
        if ok and r and r.Body then
            local ok2,d=pcall(HttpSvc.JSONDecode,HttpSvc,r.Body)
            if ok2 and d and d[1] and d[1][1] and d[1][1][1] then cb(d[1][1][1]); return end
        end
        cb("[Tradução indisponível]")
    end)
end

-- ═══════════════════════════════════════════════════════
-- SOM
-- ═══════════════════════════════════════════════════════
local notifSnd
if SoundSvc then
    notifSnd=Instance.new("Sound")
    notifSnd.SoundId="rbxassetid://9125402595"; notifSnd.Volume=0.3
    notifSnd.RollOffMaxDistance=0; notifSnd.Parent=SoundSvc
end
function GCH.playNotif()
    if notifSnd then pcall(function() notifSnd:Stop(); notifSnd:Play() end) end
end

-- ═══════════════════════════════════════════════════════
-- CORES  (C.orange adicionado!)
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
    orange= Color3.fromRGB(255,155,30),  -- ← CORRIGIDO: estava faltando
}

-- ═══════════════════════════════════════════════════════
-- RESPONSIVIDADE
-- ═══════════════════════════════════════════════════════
local mobile = UIS and (UIS.TouchEnabled and not UIS.KeyboardEnabled) or false
GCH.mobile = mobile
GCH.MOBILE = mobile   -- ← CORRIGIDO: ui/chat/friends usavam G.MOBILE (maiúsculo)
GCH.FSZ    = mobile and 15 or 13
GCH.TFSZ   = mobile and 12 or 10
GCH.BTH    = mobile and 42 or 32
GCH.INH    = mobile and 50 or 40
GCH.TITH   = mobile and 56 or 48
GCH.TABH   = mobile and 44 or 34
GCH.PW     = mobile and 0  or 580
GCH.PH     = mobile and 0  or 530
GCH.SW     = mobile and 0.97 or 0
GCH.SH     = mobile and 0.92 or 0

-- ═══════════════════════════════════════════════════════
-- UI HELPERS (funções internas)
-- ═══════════════════════════════════════════════════════
local C   = GCH.C
local FSZ = GCH.FSZ

function GCH.R(p,r)
    local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 10); return c
end

function GCH.S(p,col,t)
    local s=Instance.new("UIStroke",p)
    s.Color=col or C.acc; s.Thickness=t or 1.5
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end

function GCH.F(parent,size,pos,color,alpha)
    local f=Instance.new("Frame",parent)
    f.Size=size; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=color or C.bg
    f.BackgroundTransparency=alpha or 0; f.BorderSizePixel=0; return f
end

function GCH.L(parent,text,size,pos,col,sz,font,xa)
    local l=Instance.new("TextLabel",parent)
    l.Text=text; l.Size=size; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.TextColor3=col or C.white
    l.TextSize=sz or FSZ; l.Font=font or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left; l.TextWrapped=true; return l
end

function GCH.B(parent,text,size,pos,bg,fg,sz,font)
    local b=Instance.new("TextButton",parent)
    b.Text=text; b.Size=size; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or C.acc; b.TextColor3=fg or C.white
    b.TextSize=sz or FSZ; b.Font=font or Enum.Font.GothamBold
    b.BorderSizePixel=0; b.AutoButtonColor=false
    GCH.R(b,9)
    local orig=bg or C.acc
    if TweenSvc then
        b.MouseEnter:Connect(function()
            TweenSvc:Create(b,TweenInfo.new(0.12),{BackgroundColor3=Color3.new(
                math.min(1,orig.R+0.12),math.min(1,orig.G+0.12),math.min(1,orig.B+0.12))}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenSvc:Create(b,TweenInfo.new(0.12),{BackgroundColor3=orig}):Play()
        end)
    end
    return b
end

function GCH.I(parent,placeholder,size,pos)
    local f=GCH.F(parent,size,pos,Color3.fromRGB(17,12,34))
    GCH.R(f,10); GCH.S(f,C.acc2,1)
    local i=Instance.new("TextBox",f)
    i.PlaceholderText=placeholder or ""; i.PlaceholderColor3=C.gray; i.Text=""
    i.Size=UDim2.new(1,-14,1,-4); i.Position=UDim2.new(0,7,0,2)
    i.BackgroundTransparency=1; i.TextColor3=C.white; i.TextSize=FSZ
    i.Font=Enum.Font.Gotham; i.TextXAlignment=Enum.TextXAlignment.Left
    i.ClearTextOnFocus=false; return f,i
end

function GCH.SC(parent,size,pos)
    local sf=Instance.new("ScrollingFrame",parent)
    sf.Size=size or UDim2.new(1,0,1,0); sf.Position=pos or UDim2.new(0,0,0,0)
    sf.BackgroundTransparency=1; sf.ScrollBarThickness=3
    sf.ScrollBarImageColor3=C.acc; sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y; sf.BorderSizePixel=0
    local layout=Instance.new("UIListLayout",sf)
    layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,2)
    local pad=Instance.new("UIPadding",sf)
    pad.PaddingLeft=UDim.new(0,7); pad.PaddingRight=UDim.new(0,7)
    pad.PaddingTop=UDim.new(0,5);  pad.PaddingBottom=UDim.new(0,5)
    return sf
end

function GCH.scrollEnd(sf)
    task.defer(function()
        sf.CanvasPosition=Vector2.new(0,
            math.max(0,sf.AbsoluteCanvasSize.Y-sf.AbsoluteSize.Y+30))
    end)
end

function GCH.tw(obj,t,props)
    if TweenSvc then
        TweenSvc:Create(obj,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props):Play()
    end
end

-- ═══════════════════════════════════════════════════════
-- ALIASES mk* — CORREÇÃO PRINCIPAL!
-- ui.lua, chat.lua, friends.lua, private.lua, admin.lua
-- usam G.mkFrame / G.mkLabel / etc, mas as funções
-- foram definidas como G.F / G.L / etc. Agora mapeamos.
-- ═══════════════════════════════════════════════════════
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
local SG=Instance.new("ScreenGui")
SG.Name="GlobalChatHubV3"; SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true; SG.DisplayOrder=999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(SG) end end)
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=GCH.ME:WaitForChild("PlayerGui")
end
GCH.SG=SG

print(("[GlobalChat Hub %s] ✅ Core OK | HTTP:%s | Admin:%s"):format(
    GCH.VER, httpNome, tostring(GCH.IS_OWNER)))
