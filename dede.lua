--[[ 
Auto Rejoin XENO - The Forge Edition (CORRIGIDO V6) 
- Sistema de configuração persistente entre mundos 
- Auto-execute 100% funcional 
- Detecção automática inteligente 
- Reduzidos delays para maior confiabilidade em TPs rápidos 
- Injeção early em Mundo 1 para evitar falhas 
- Correções para consistência na GUI e injeção 
- URL atualizada conforme solicitado 
- Aumentado threshold de rejoin para 5 min (300s) para evitar "rejoin antigo" 
- Mais debug para rastrear salvamento de tempo 
]] 

local Players = game:GetService("Players") 
local TeleportService = game:GetService("TeleportService") 
local CoreGui = game:GetService("CoreGui") 
local HttpService = game:GetService("HttpService") 
local LocalPlayer = Players.LocalPlayer 

-- Configurações 
local CONFIG_FILE = "XenoForgeConfig.json" 
local SCRIPT_URL = "https://pastefy.app/2HaiDt8V/raw" -- URL atualizada 

-- IDs dos Mundos (CONFIGURADOS!) 
local MUNDO_1_ID = 76558904092080 
local MUNDO_2_ID = 129009554587176 

-- === FUNÇÕES DE CONFIGURAÇÃO PERSISTENTE === 
local function SaveConfig(data) 
    -- Carrega config existente e mescla com novos dados 
    local existing = {} 
    if isfile(CONFIG_FILE) then 
        pcall(function() 
            existing = HttpService:JSONDecode(readfile(CONFIG_FILE)) 
        end) 
    end 
    -- Mescla os dados 
    for k, v in pairs(data) do 
        existing[k] = v 
    end 
    -- Salva 
    local success = pcall(function() 
        writefile(CONFIG_FILE, HttpService:JSONEncode(existing)) 
    end) 
    print("💾 [DEBUG] Salvando config:", HttpService:JSONEncode(existing), "Sucesso:", success) 
    return success 
end 

local function LoadConfig() 
    if isfile(CONFIG_FILE) then 
        local success, data = pcall(function() 
            return HttpService:JSONDecode(readfile(CONFIG_FILE)) 
        end) 
        if success then 
            print("📂 [DEBUG] Config carregada:", HttpService:JSONEncode(data)) 
            return data 
        end 
    end 
    print("⚠️ [DEBUG] Nenhuma config encontrada ou erro no load") 
    return {} 
end 

-- === SISTEMA DE AUTO-EXECUTE === 
local queue_on_teleport = (queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or function() end) 

local function InjectScript() 
    local code = string.format([[ 
        -- XENO AUTO-EXECUTE INJECTION 
        repeat task.wait() until game:IsLoaded() 
        task.wait(0.5) -- Delay reduzido para carregamento rápido 
        
        local success, result = pcall(function() 
            -- Verifica se o arquivo de config existe 
            if not isfile("XenoForgeConfig.json") then 
                return false 
            end 
            
            -- Lê a configuração 
            local HttpService = game:GetService("HttpService") 
            local configData = readfile("XenoForgeConfig.json") 
            local config = HttpService:JSONDecode(configData) 
            
            -- Verifica se está ativado 
            if not config or not config.IsEnabled then 
                return false 
            end 
            
            -- EXECUTA O SCRIPT 
            task.wait(0.5) 
            local scriptCode = game:HttpGet("%s", true) 
            loadstring(scriptCode)() 
            return true 
        end) 
        
        -- Notificação de status 
        if success and result then 
            game:GetService("StarterGui"):SetCore("SendNotification", { 
                Title = "✅ Xeno Loop", 
                Text = "Script executado automaticamente!", 
                Duration = 5 
            }) 
        elseif not success then 
            game:GetService("StarterGui"):SetCore("SendNotification", { 
                Title = "❌ Xeno Loop", 
                Text = "Erro: " .. tostring(result), 
                Duration = 8 
            }) 
        end 
    ]], SCRIPT_URL) 
    
    -- Tenta múltiplas injeções para garantir 
    pcall(function() 
        queue_on_teleport(code) 
    end) 
    
    -- Backup: salva também em arquivo no autoexec para executors que usam pasta autoexec 
    if not isfolder("autoexec") then 
        makefolder("autoexec") 
    end 
    pcall(function() 
        writefile("autoexec/XenoAutoExec.lua", code) 
    end) 
end 

-- === EARLY INJECTION PARA MUNDO 1 === 
-- Executa injeção imediata se detectado rejoin recente no Mundo 1 (antes da GUI) 
local earlyConfig = LoadConfig() 
local placeId = game.PlaceId 
local earlyWorld = 0 
if placeId == MUNDO_1_ID then 
    earlyWorld = 1 
elseif placeId == MUNDO_2_ID then 
    earlyWorld = 2 
end 

if earlyConfig.IsEnabled and earlyConfig.LastRejoinTime then 
    local timeSinceRejoin = os.time() - earlyConfig.LastRejoinTime 
    if timeSinceRejoin < 300 and earlyWorld == 1 then  -- Aumentado para 300s (5 min)
        -- Injeção early para TP rápido 
        InjectScript() 
        -- Notificação minimal 
        game:GetService("StarterGui"):SetCore("SendNotification", { 
            Title = "🔄 Xeno Loop", 
            Text = "Preparando para Mundo 2...", 
            Duration = 10 
        }) 
    end 
end 

-- === GUI === 
if _G.AutoRejoinGUI then 
    pcall(function() 
        _G.AutoRejoinGUI:Destroy() 
    end) 
end 

local ScreenGui = Instance.new("ScreenGui") 
ScreenGui.Name = "XenoForgeRejoin" 
ScreenGui.ResetOnSpawn = false 
ScreenGui.Parent = CoreGui 
_G.AutoRejoinGUI = ScreenGui 

local MainFrame = Instance.new("Frame") 
MainFrame.Size = UDim2.new(0, 320, 0, 280) 
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -140) 
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25) 
MainFrame.BorderSizePixel = 0 
MainFrame.Parent = ScreenGui 
MainFrame.Active = true 
MainFrame.Draggable = true 

local UICorner = Instance.new("UICorner") 
UICorner.CornerRadius = UDim.new(0, 10) 
UICorner.Parent = MainFrame 

local Title = Instance.new("TextLabel") 
Title.Text = "🔄 Xeno Forge Auto Rejoin" 
Title.Size = UDim2.new(1, 0, 0, 40) 
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
Title.TextColor3 = Color3.fromRGB(255, 255, 255) 
Title.Font = Enum.Font.GothamBold 
Title.TextSize = 16 
Title.Parent = MainFrame 

local TitleCorner = Instance.new("UICorner") 
TitleCorner.CornerRadius = UDim.new(0, 10) 
TitleCorner.Parent = Title 

-- Indicador de Mundo Atual 
local WorldBox = Instance.new("Frame") 
WorldBox.Size = UDim2.new(0.9, 0, 0, 50) 
WorldBox.Position = UDim2.new(0.05, 0, 0.17, 0) 
WorldBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
WorldBox.Parent = MainFrame 

local WorldCorner = Instance.new("UICorner") 
WorldCorner.CornerRadius = UDim.new(0, 8) 
WorldCorner.Parent = WorldBox 

local WorldTitle = Instance.new("TextLabel") 
WorldTitle.Text = "🌍 Mundo Atual" 
WorldTitle.Size = UDim2.new(1, 0, 0, 20) 
WorldTitle.Position = UDim2.new(0, 0, 0, 3) 
WorldTitle.BackgroundTransparency = 1 
WorldTitle.TextColor3 = Color3.fromRGB(200, 200, 200) 
WorldTitle.Font = Enum.Font.GothamBold 
WorldTitle.TextSize = 11 
WorldTitle.Parent = WorldBox 

local WorldLabel = Instance.new("TextLabel") 
WorldLabel.Text = "Detectando..." 
WorldLabel.Size = UDim2.new(1, 0, 0, 25) 
WorldLabel.Position = UDim2.new(0, 0, 0, 23) 
WorldLabel.BackgroundTransparency = 1 
WorldLabel.TextColor3 = Color3.fromRGB(150, 255, 150) 
WorldLabel.Font = Enum.Font.GothamBold 
WorldLabel.TextSize = 14 
WorldLabel.Parent = WorldBox 

-- Status 
local StatusLabel = Instance.new("TextLabel") 
StatusLabel.Text = "Status: Iniciando..." 
StatusLabel.Size = UDim2.new(0.9, 0, 0, 50) 
StatusLabel.Position = UDim2.new(0.05, 0, 0.38, 0) 
StatusLabel.BackgroundTransparency = 1 
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200) 
StatusLabel.TextWrapped = true 
StatusLabel.Font = Enum.Font.Gotham 
StatusLabel.TextSize = 11 
StatusLabel.Parent = MainFrame 

-- Input de Tempo 
local TimeLabel = Instance.new("TextLabel") 
TimeLabel.Text = "⏱️ Tempo (minutos):" 
TimeLabel.Size = UDim2.new(0.9, 0, 0, 20) 
TimeLabel.Position = UDim2.new(0.05, 0, 0.56, 0) 
TimeLabel.BackgroundTransparency = 1 
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200) 
TimeLabel.Font = Enum.Font.Gotham 
TimeLabel.TextSize = 11 
TimeLabel.TextXAlignment = Enum.TextXAlignment.Left 
TimeLabel.Parent = MainFrame 

local TimeInput = Instance.new("TextBox") 
TimeInput.PlaceholderText = "40" 
TimeInput.Size = UDim2.new(0.35, 0, 0, 35) 
TimeInput.Position = UDim2.new(0.05, 0, 0.64, 0) 
TimeInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50) 
TimeInput.TextColor3 = Color3.fromRGB(255, 255, 255) 
TimeInput.Text = "40" 
TimeInput.Font = Enum.Font.GothamBold 
TimeInput.TextSize = 16 
TimeInput.Parent = MainFrame 

local InputCorner = Instance.new("UICorner") 
InputCorner.CornerRadius = UDim.new(0, 6) 
InputCorner.Parent = TimeInput 

local ToggleButton = Instance.new("TextButton") 
ToggleButton.Text = "▶ ATIVAR LOOP" 
ToggleButton.Size = UDim2.new(0.55, 0, 0, 35) 
ToggleButton.Position = UDim2.new(0.42, 0, 0.64, 0) 
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) 
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
ToggleButton.Font = Enum.Font.GothamBold 
ToggleButton.TextSize = 13 
ToggleButton.Parent = MainFrame 

local BtnCorner = Instance.new("UICorner") 
BtnCorner.CornerRadius = UDim.new(0, 6) 
BtnCorner.Parent = ToggleButton 

-- Botão de Teste 
local TestButton = Instance.new("TextButton") 
TestButton.Text = "🧪 Testar Rejoin Agora" 
TestButton.Size = UDim2.new(0.9, 0, 0, 30) 
TestButton.Position = UDim2.new(0.05, 0, 0.80, 0) 
TestButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0) 
TestButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
TestButton.Font = Enum.Font.Gotham 
TestButton.TextSize = 12 
TestButton.Parent = MainFrame 

local TestCorner = Instance.new("UICorner") 
TestCorner.CornerRadius = UDim.new(0, 6) 
TestCorner.Parent = TestButton 

local InfoLabel = Instance.new("TextLabel") 
InfoLabel.Text = "💡 Ative no Mundo 2 para loop automático" 
InfoLabel.Size = UDim2.new(0.9, 0, 0, 25) 
InfoLabel.Position = UDim2.new(0.05, 0, 0.91, 0) 
InfoLabel.BackgroundTransparency = 1 
InfoLabel.TextColor3 = Color3.fromRGB(150, 200, 255) 
InfoLabel.Font = Enum.Font.Gotham 
InfoLabel.TextSize = 9 
InfoLabel.Parent = MainFrame 

-- Botão de Diagnóstico 
local DiagButton = Instance.new("TextButton") 
DiagButton.Text = "🔍" 
DiagButton.Size = UDim2.new(0, 30, 0, 30) 
DiagButton.Position = UDim2.new(0.88, 0, 0.05, 0) 
DiagButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60) 
DiagButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
DiagButton.Font = Enum.Font.GothamBold 
DiagButton.TextSize = 16 
DiagButton.Parent = MainFrame 

local DiagCorner = Instance.new("UICorner") 
DiagCorner.CornerRadius = UDim.new(0, 8) 
DiagCorner.Parent = DiagButton 

-- === VARIÁVEIS === 
local isEnabled = false 
local countdownTask = nil 
local currentWorld = nil 

-- === FUNÇÕES AUXILIARES === 
local function DetectWorld() 
    local placeId = game.PlaceId 
    if placeId == MUNDO_1_ID then 
        currentWorld = 1 
        WorldLabel.Text = "⚠️ MUNDO 1" 
        WorldLabel.TextColor3 = Color3.fromRGB(255, 200, 0) 
        return 1 
    elseif placeId == MUNDO_2_ID then 
        currentWorld = 2 
        WorldLabel.Text = "✅ MUNDO 2" 
        WorldLabel.TextColor3 = Color3.fromRGB(150, 255, 150) 
        return 2 
    else 
        currentWorld = 0 
        WorldLabel.Text = "❓ DESCONHECIDO (" .. placeId .. ")" 
        WorldLabel.TextColor3 = Color3.fromRGB(255, 100, 100) 
        return 0 
    end 
end 

-- === LÓGICA DE REJOIN === 
local function PerformRejoin() 
    StatusLabel.Text = "🔄 Preparando rejoin..." 
    -- Salva estado antes de sair 
    SaveConfig({ 
        IsEnabled = true, 
        LastRejoinTime = os.time(), 
        RejoinFromWorld = currentWorld 
    }) 
    -- Injeta script 
    InjectScript() 
    task.wait(1) 
    StatusLabel.Text = "📤 Saindo do servidor..." 
    -- SEMPRE volta pro Mundo 1 (comportamento natural do jogo) 
    local success = pcall(function() 
        TeleportService:Teleport(MUNDO_1_ID, LocalPlayer) 
    end) 
    if not success then 
        task.wait(1) 
        TeleportService:Teleport(MUNDO_1_ID, LocalPlayer) 
    end 
end 

local function StartTimer(minutes) 
    if countdownTask then 
        task.cancel(countdownTask) 
    end 
    isEnabled = true 
    ToggleButton.Text = "⏸ PARAR LOOP" 
    ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0) 
    -- Salva configuração 
    SaveConfig({ 
        IsEnabled = true, 
        TimeMinutes = minutes, 
        StartTime = os.time() 
    }) 
    countdownTask = task.spawn(function() 
        local seconds = minutes * 60 
        while seconds > 0 and isEnabled do 
            local mins = math.floor(seconds / 60) 
            local secs = seconds % 60 
            StatusLabel.Text = string.format("⏳ Rejoin em: %02d:%02d", mins, secs) 
            -- Re-injeta a cada 15 segundos 
            if seconds % 15 == 0 then 
                InjectScript() 
            end 
            task.wait(1) 
            seconds = seconds - 1 
        end 
        if isEnabled then 
            PerformRejoin() 
        end 
    end) 
end 

local function StopTimer() 
    isEnabled = false 
    if countdownTask then 
        task.cancel(countdownTask) 
    end 
    StatusLabel.Text = "⏹ Loop pausado" 
    ToggleButton.Text = "▶ ATIVAR LOOP" 
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0) 
    SaveConfig({ IsEnabled = false }) 
end 

-- === EVENTOS DOS BOTÕES === 
ToggleButton.MouseButton1Click:Connect(function() 
    if isEnabled then 
        StopTimer() 
    else 
        local minutes = tonumber(TimeInput.Text) 
        if not minutes or minutes < 1 then 
            StatusLabel.Text = "❌ Digite um tempo válido!" 
            return 
        end 
        if currentWorld ~= 2 then 
            StatusLabel.Text = "⚠️ Aviso: Você não está no Mundo 2!\nMas o loop vai funcionar..." 
            task.wait(3) 
        end 
        StartTimer(minutes) 
    end 
end) 

TestButton.MouseButton1Click:Connect(function() 
    if isEnabled then 
        StatusLabel.Text = "⚠️ Desative o loop antes de testar!" 
        return 
    end 
    StatusLabel.Text = "🧪 Testando rejoin em 3s..." 
    -- Salva config de teste 
    SaveConfig({ 
        IsEnabled = true, 
        TimeMinutes = tonumber(TimeInput.Text) or 40, 
        TestMode = true 
    }) 
    task.wait(3) 
    PerformRejoin() 
end) 

-- Botão de Diagnóstico 
DiagButton.MouseButton1Click:Connect(function() 
    local config = LoadConfig() 
    local queueSupport = queue_on_teleport ~= nil and queue_on_teleport ~= function() end 
    local diagText = string.format([[ 
🔍 DIAGNÓSTICO XENO LOOP 
📊 Status Atual: 
• Loop Ativo: %s 
• Mundo Atual: %d 
• PlaceID: %d 

⚙️ Configuração: 
• Config Existe: %s 
• IsEnabled: %s 
• Tempo: %s min 
• LastRejoinTime: %s 

🔧 Sistema: 
• queue_on_teleport: %s 
• Arquivo AutoExec: %s 
• Executor: %s 

📝 Último Rejoin: 
• Há %s segundos 
• Mundo Origem: %s 
    ]], 
    tostring(isEnabled), 
    currentWorld or 0, 
    game.PlaceId, 
    isfile(CONFIG_FILE) and "✅" or "❌", 
    config.IsEnabled ~= nil and tostring(config.IsEnabled) or "N/A", 
    config.TimeMinutes or "N/A", 
    config.LastRejoinTime and os.date("%H:%M:%S", config.LastRejoinTime) or "N/A", 
    queueSupport and "✅ Suportado" or "❌ Não suportado", 
    isfile("autoexec/XenoAutoExec.lua") and "✅ Existe" or "❌ Não existe", 
    identifyexecutor and identifyexecutor() or "Desconhecido", 
    config.LastRejoinTime and tostring(os.time() - config.LastRejoinTime) or "N/A", 
    config.RejoinFromWorld or "N/A" 
    ) 
    print(diagText) 
    game:GetService("StarterGui"):SetCore("SendNotification", { 
        Title = "🔍 Diagnóstico", 
        Text = "Informações enviadas para o console (F9)!", 
        Duration = 5 
    }) 
    StatusLabel.Text = "🔍 Diagnóstico completo!\nVeja o console (F9 ou Output)" 
end) 

-- === AUTO-START INTELIGENTE === 
task.spawn(function() 
    task.wait(0.5) -- Delay reduzido 
    -- Detecta mundo atual 
    local mundo = DetectWorld() 
    -- Carrega configuração 
    local config = LoadConfig() 
    -- Verifica se há pasta e arquivo de auto-exec salvo 
    if not isfolder("autoexec") then 
        makefolder("autoexec") 
    end 
    local hasAutoExecFile = isfile("autoexec/XenoAutoExec.lua") 
    StatusLabel.Text = "✅ Script carregado!" 
    
    -- DEBUG: Mostra info da config 
    if config.IsEnabled then 
        print("🔍 [DEBUG] Config encontrada:") 
        print(" - IsEnabled:", config.IsEnabled) 
        print(" - LastRejoinTime:", config.LastRejoinTime) 
        print(" - TimeMinutes:", config.TimeMinutes) 
        print(" - Mundo atual:", mundo) 
    end 
    
    -- Verifica se voltou de um rejoin 
    if config.IsEnabled and config.LastRejoinTime then 
        local timeSinceRejoin = os.time() - config.LastRejoinTime 
        print("🔍 [DEBUG] Tempo desde último rejoin:", timeSinceRejoin, "segundos") 
        -- Se foi há menos de 5 minutos, é um rejoin 
        if timeSinceRejoin < 300 then 
            StatusLabel.Text = "🔄 Retornando de rejoin..." 
            game:GetService("StarterGui"):SetCore("SendNotification", { 
                Title = "🔄 Xeno Detectou Rejoin!", 
                Text = "Aguardando mundo correto...", 
                Duration = 5 
            }) 
            -- Se está no Mundo 1, aguarda TP pro Mundo 2 
            if mundo == 1 then 
                StatusLabel.Text = "⏳ Aguardando TP automático Mundo 1→2..." 
                -- Injeção já feita early, mas re-injeta por segurança 
                InjectScript() 
                local waited = 0 
                local maxWait = 15 -- Reduzido para evitar delays longos 
                while game.PlaceId == MUNDO_1_ID and waited < maxWait do 
                    task.wait(1) 
                    waited = waited + 1 
                    StatusLabel.Text = string.format("⏳ Aguardando TP (%d/%ds)...", waited, maxWait) 
                end 
                -- Atualiza detecção 
                mundo = DetectWorld() 
            end 
            -- Se chegou no Mundo 2, reativa o loop 
            if mundo == 2 then 
                StatusLabel.Text = "✅ De volta ao Mundo 2!" 
                task.wait(1) 
                local minutes = config.TimeMinutes or 40 
                TimeInput.Text = tostring(minutes) 
                print("✅ [DEBUG] Reativando timer com", minutes, "minutos") 
                StartTimer(minutes) 
                game:GetService("StarterGui"):SetCore("SendNotification", { 
                    Title = "✅ Loop Reativado!", 
                    Text = "Rejoin em " .. minutes .. " minutos", 
                    Duration = 5 
                }) 
            else 
                StatusLabel.Text = "⚠️ Não chegou ao Mundo 2\nReative manualmente" 
                game:GetService("StarterGui"):SetCore("SendNotification", { 
                    Title = "⚠️ Erro no Auto-Start", 
                    Text = "Reative o loop manualmente", 
                    Duration = 8 
                }) 
            end 
        else 
            StatusLabel.Text = "👋 Pronto para usar!" 
            print("ℹ️ [DEBUG] Rejoin muito antigo, não reativando") 
        end 
    else 
        StatusLabel.Text = "👋 Configure e ative o loop!" 
        print("ℹ️ [DEBUG] Nenhuma config ativa encontrada") 
    end 
    
    -- Limpa flag de teste 
    if config.TestMode then 
        SaveConfig({ TestMode = false }) 
    end 
    
    -- Mostra aviso se auto-exec não foi salvo 
    if config.IsEnabled and not hasAutoExecFile then 
        task.wait(2) 
        game:GetService("StarterGui"):SetCore("SendNotification", { 
            Title = "⚠️ Aviso", 
            Text = "Auto-exec pode falhar. Use um executor com queue_on_teleport.", 
            Duration = 10 
        }) 
    end 
end) 

-- Notificação inicial 
game:GetService("StarterGui"):SetCore("SendNotification", { 
    Title = "🔄 Xeno Forge Loop", 
    Text = "Carregado! Mundo: " .. (currentWorld or "?"), 
    Duration = 5 
})
