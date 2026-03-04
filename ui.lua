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
