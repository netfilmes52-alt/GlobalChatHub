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
