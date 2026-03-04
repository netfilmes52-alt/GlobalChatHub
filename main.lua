--[[
    GlobalChat Hub v3.0 - Loader Robusto
    github.com/netfilmes52-alt/GlobalChatHub
]]

local BASE = "https://raw.githubusercontent.com/netfilmes52-alt/GlobalChatHub/main/"
local modules = {"core.lua","ui.lua","chat.lua","private.lua","profile.lua","friends.lua","admin.lua"}

local function showError(title, msg, hint)
    pcall(function()
        local old = game:GetService("CoreGui"):FindFirstChild("GCH_ERR")
        if old then old:Destroy() end
    end)
    local SG = Instance.new("ScreenGui")
    SG.Name = "GCH_ERR"; SG.ResetOnSpawn = false; SG.DisplayOrder = 9999
    pcall(function() SG.Parent = game:GetService("CoreGui") end)
    if not SG.Parent then SG.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

    local bg = Instance.new("Frame",SG)
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.new(0,0,0); bg.BackgroundTransparency=0.35; bg.BorderSizePixel=0; bg.ZIndex=1

    local card = Instance.new("Frame",bg)
    card.Size=UDim2.new(0.92,0,0,420); card.Position=UDim2.new(0.04,0,0.5,-210)
    card.BackgroundColor3=Color3.fromRGB(14,4,4); card.BorderSizePixel=0; card.ZIndex=2
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,16)
    local st=Instance.new("UIStroke",card); st.Color=Color3.fromRGB(220,50,50); st.Thickness=2

    local tl=Instance.new("TextLabel",card)
    tl.Size=UDim2.new(1,-16,0,40); tl.Position=UDim2.new(0,8,0,8); tl.BackgroundTransparency=1
    tl.Text="❌  "..title; tl.TextColor3=Color3.fromRGB(255,70,70); tl.TextSize=16
    tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.TextWrapped=true; tl.ZIndex=3

    if hint then
        local hl=Instance.new("TextLabel",card)
        hl.Size=UDim2.new(1,-16,0,26); hl.Position=UDim2.new(0,8,0,52); hl.BackgroundTransparency=1
        hl.Text="📍 "..hint; hl.TextColor3=Color3.fromRGB(255,200,50); hl.TextSize=12
        hl.Font=Enum.Font.Gotham; hl.TextXAlignment=Enum.TextXAlignment.Left; hl.ZIndex=3
    end

    local eb=Instance.new("Frame",card)
    eb.Size=UDim2.new(1,-16,0,210); eb.Position=UDim2.new(0,8,0,84)
    eb.BackgroundColor3=Color3.fromRGB(4,2,2); eb.BorderSizePixel=0; eb.ZIndex=3
    Instance.new("UICorner",eb).CornerRadius=UDim.new(0,8)

    local el=Instance.new("TextLabel",eb)
    el.Size=UDim2.new(1,-10,1,-8); el.Position=UDim2.new(0,5,0,4); el.BackgroundTransparency=1
    el.Text=tostring(msg); el.TextColor3=Color3.fromRGB(255,160,160); el.TextSize=11
    el.Font=Enum.Font.Code; el.TextXAlignment=Enum.TextXAlignment.Left
    el.TextYAlignment=Enum.TextYAlignment.Top; el.TextWrapped=true; el.ZIndex=4

    local cb=Instance.new("TextButton",card)
    cb.Size=UDim2.new(0.48,-6,0,46); cb.Position=UDim2.new(0,8,0,306)
    cb.BackgroundColor3=Color3.fromRGB(50,30,130); cb.TextColor3=Color3.white
    cb.Text="📋  Copiar Erro"; cb.TextSize=14; cb.Font=Enum.Font.GothamBold; cb.BorderSizePixel=0; cb.ZIndex=3
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,10)
    cb.MouseButton1Click:Connect(function()
        local full="=== GCH ERRO ===\n"..title.."\n"
        if hint then full=full.."LOCAL: "..hint.."\n" end
        full=full.."ERRO: "..tostring(msg)
        pcall(function() setclipboard(full) end)
        cb.Text="✅  Copiado!"; cb.BackgroundColor3=Color3.fromRGB(20,100,20)
    end)

    local xb=Instance.new("TextButton",card)
    xb.Size=UDim2.new(0.48,-6,0,46); xb.Position=UDim2.new(0.52,-2,0,306)
    xb.BackgroundColor3=Color3.fromRGB(140,20,20); xb.TextColor3=Color3.white
    xb.Text="✕  Fechar"; xb.TextSize=14; xb.Font=Enum.Font.GothamBold; xb.BorderSizePixel=0; xb.ZIndex=3
    Instance.new("UICorner",xb).CornerRadius=UDim.new(0,10)
    xb.MouseButton1Click:Connect(function() SG:Destroy() end)

    local fl=Instance.new("TextLabel",card)
    fl.Size=UDim2.new(1,-16,0,28); fl.Position=UDim2.new(0,8,0,362); fl.BackgroundTransparency=1
    fl.Text="Copie o erro e mande para o desenvolvedor."; fl.TextColor3=Color3.fromRGB(90,70,70)
    fl.TextSize=11; fl.Font=Enum.Font.GothamItalic; fl.TextXAlignment=Enum.TextXAlignment.Center; fl.ZIndex=3
end

-- Bloco de compatibilidade injetado no topo do script combinado
local COMPAT = [=[
-- == COMPATIBILIDADE TOTAL ==
local _rawwait = (typeof ~= nil and typeof(wait) == "function" and wait) or function(t) 
    local e = os.clock() + (t or 0)
    while os.clock() < e do end
end

if not task then
    task = {}
end

if not task.wait then
    task.wait = function(t) return _rawwait(t) end
end

if not task.spawn then
    task.spawn = function(fn, ...)
        local args = {...}
        local co = coroutine.create(function() fn(table.unpack(args)) end)
        coroutine.resume(co)
        return co
    end
end

if not task.defer then
    task.defer = function(fn, ...)
        local args = {...}
        local co = coroutine.create(function() _rawwait() fn(table.unpack(args)) end)
        coroutine.resume(co)
        return co
    end
end

if not task.delay then
    task.delay = function(t, fn, ...)
        local args = {...}
        local co = coroutine.create(function() _rawwait(t) fn(table.unpack(args)) end)
        coroutine.resume(co)
        return co
    end
end

if not table.unpack then table.unpack = unpack end

]=]

-- Baixar e juntar tudo
local combined = COMPAT
local lineOffset = 0
for _ in COMPAT:gmatch("\n") do lineOffset = lineOffset + 1 end

local lineMap = {}
for _, mod in ipairs(modules) do
    local ok, result = pcall(function() return game:HttpGet(BASE..mod, true) end)
    if not ok then showError("Falha ao baixar: "..mod, result, nil); return end
    local lc = 0
    for _ in result:gmatch("\n") do lc = lc + 1 end
    lineMap[mod] = {s=lineOffset+1, e=lineOffset+lc+2}
    lineOffset = lineOffset + lc + 2
    combined = combined .. "-- ===== "..mod.." =====\n" .. result .. "\n"
end

local ok, err = pcall(function() loadstring(combined)() end)
if not ok then
    local errStr = tostring(err)
    local errLine = tonumber(errStr:match(":(%d+):"))
    local modName = "desconhecido"
    if errLine then
        for mod, range in pairs(lineMap) do
            if errLine >= range.s and errLine <= range.e then
                modName = mod; break
            end
        end
    end
    local hint = errLine and ("Módulo: "..modName.." | Linha: "..errLine) or nil
    showError("Erro em: "..modName, errStr, hint)
    warn("[GCH] "..errStr)
end
