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
