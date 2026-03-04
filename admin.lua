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
