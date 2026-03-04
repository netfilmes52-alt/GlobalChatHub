-- ╔══════════════════════════════════════════════════════════════╗
-- ║         G L O B A L  C H A T  H U B  •  v3.0               ║
-- ║             profile.lua  —  Perfis & Status                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local G   = shared.GCH
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
