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
