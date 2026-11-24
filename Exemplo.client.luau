-- LocalScript em StarterPlayer > StarterPlayerScripts.
-- Coloque DynxeUILibrary em ReplicatedStorage como ModuleScript e pressione Play.
-- Para habilitar Salvar/Carregar na aba Preferências, use um Script em
-- ServerScriptService com a linha abaixo (o DataStore roda no servidor):
-- require(game:GetService("ReplicatedStorage"):WaitForChild("DynxeUILibrary")):StartSaveManager()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = require(ReplicatedStorage:WaitForChild("DynxeUILibrary"))

local window = Library:CreateWindow({
	Name = "ExemploDynxe",
	Title = "Oficina de avisos",
	Subtitle = "Monte um aviso e veja a prévia",
	Theme = "Aurora",
	Language = "pt",
	ToggleKey = Enum.KeyCode.RightShift,
	Anonymous = false,
	-- LogoImage = "rbxassetid://ID_DA_SUA_IMAGEM",
})

local editor = window:CreateTab("Editor", "✎")
local catalog = window:CreateTab("Catálogo", "◇")
local shortcuts = window:CreateTab("Atalhos", "⌘")

editor:AddSection("Conteúdo do aviso")
local category = "Lembrete"
editor:AddDropdown("Categoria", {"Lembrete", "Conquista", "Inventário"}, category, function(choice)
	category = choice
end)
local message = editor:AddTextbox("Mensagem", "O evento começa em breve!")
local duration = editor:AddSlider("Duração em segundos", 1, 10, 4)
local prefix = editor:AddToggle("Incluir categoria no título", true)

local function preview()
	local body = message.Text
	if not body:match("%S") then body = "Digite uma mensagem no editor." end
	window:Notify(prefix.Get() and category or "Aviso", body, duration.Get())
end

editor:AddButton("Mostrar prévia", "Testar", preview)
editor:AddButton("Restaurar duração", "4 segundos", function()
	duration.Set(4)
end)

catalog:AddSection("Escolha um item para usar no aviso")
catalog:AddShopGrid({
	{Name = "Cristal", Price = 25, Icon = "◇"},
	{Name = "Estrela", Price = 50, Icon = "★"},
	{Name = "Chave", Price = 15, Icon = "⚿"},
}, function(item)
	-- A vitrine só preenche a mensagem do editor. Os preços são ilustrativos.
	message.Text = string.format("%s custa %d moedas.", item.Name, item.Price)
	editor:Select()
	preview()
end)

shortcuts:AddSection("Teclado")
shortcuts:AddWindowKeybind("Abrir ou fechar o painel")
shortcuts:AddKeybind("Mostrar prévia", Enum.KeyCode.P, preview)

-- A busca e a aba Preferências são criadas pela biblioteca. Em Preferências,
-- o jogador troca tema/idioma e salva ou carrega suas preferências do painel.
-- Clique no avatar para alternar o modo anônimo.
editor:Select()
