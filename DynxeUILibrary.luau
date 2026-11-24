-- DynxeUILibrary.luau
-- ModuleScript para StarterPlayerScripts/ReplicatedStorage.
-- A biblioteca cria somente a interface; passe callbacks para ligar as ações ao jogo.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}

local base = {
	background = Color3.fromRGB(18, 19, 23),
	sidebar = Color3.fromRGB(12, 14, 17),
	panel = Color3.fromRGB(27, 28, 33),
	card = Color3.fromRGB(32, 33, 39),
	field = Color3.fromRGB(22, 23, 28),
	line = Color3.fromRGB(43, 45, 52),
	text = Color3.fromRGB(225, 228, 234),
	muted = Color3.fromRGB(137, 141, 152),
	blue = Color3.fromRGB(81, 200, 178),
	green = Color3.fromRGB(79, 198, 121),
}

local themes = {
	Menta = base,
	Oceano = {background = Color3.fromHex("101927"), sidebar = Color3.fromHex("0C1420"), panel = Color3.fromHex("1C2B40"), card = Color3.fromHex("21334A"), field = Color3.fromHex("152236"), line = Color3.fromHex("384F68"), blue = Color3.fromHex("79BCFF")},
	Ametista = {background = Color3.fromHex("201A29"), sidebar = Color3.fromHex("16121D"), panel = Color3.fromHex("30263D"), card = Color3.fromHex("392E45"), field = Color3.fromHex("261E30"), line = Color3.fromHex("53425F"), blue = Color3.fromHex("D1A1FF")},
}
function Library:CreateWindow(options)
	options = options or {}
	local C = table.clone(base)
	local bindingsByObject = setmetatable({}, {__mode = "k"})
	local function applyTheme(name)
		assert(themes[name], "Tema desconhecido: " .. tostring(name))
		for key, fallback in base do C[key] = themes[name][key] or fallback end
		for object, properties in bindingsByObject do
			for property, role in properties do object[property] = C[role] end
		end
	end
	applyTheme(options.Theme or "Menta")
	local function paint(object, property, role)
		local properties = bindingsByObject[object] or {}
		bindingsByObject[object] = properties
		properties[property] = role
		object[property] = C[role]
	end
local function make(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props) do
		object[key] = value
		if typeof(value) == "Color3" then
			for role, color in C do
				if color == value then paint(object, key, role) break end
			end
		end
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	make("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color)
	make("UIStroke", {Color = color or C.line, Thickness = 1}, parent)
end

local function label(parent, text, size, color, bold)
	return make("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextColor3 = color or C.text,
		TextSize = size, Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

local function button(parent, text, size)
	local b = make("TextButton", {
		BackgroundColor3 = C.field, BorderSizePixel = 0, Text = text,
		TextColor3 = C.text, TextSize = size or 14, Font = Enum.Font.GothamMedium,
		AutoButtonColor = false,
	}, parent)
	corner(b, 6)
	return b
end

local function animate(object, properties)
	TweenService:Create(object, TweenInfo.new(0.16, Enum.EasingStyle.Quad), properties):Play()
end

local function safeCall(callback, ...)
	if callback then
		local ok, err = pcall(callback, ...)
		if not ok then warn("DynxeUILibrary callback: " .. tostring(err)) end
	end
end

local player = Players.LocalPlayer
	assert(player, "DynxeUILibrary deve ser usada em um LocalScript")
	local gui = make("ScreenGui", {
		Name = options.Name or "DynxeUI", ResetOnSpawn = false,
		IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))

	local root = make("CanvasGroup", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(620, 636),
		BackgroundColor3 = C.background, BorderSizePixel = 0, ClipsDescendants = true,
	}, gui)
	corner(root, 13)
	stroke(root, C.line)
	local scale = make("UIScale", {Scale = 1}, root)
	local connections = {}
	local function listen(signal, callback)
		table.insert(connections, signal:Connect(callback))
	end
	local function place(center)
		local screen = gui.AbsoluteSize
		local half = root.AbsoluteSize / 2
		local x = math.clamp(center.X, half.X, math.max(half.X, screen.X - half.X))
		local y = math.clamp(center.Y, half.Y, math.max(half.Y, screen.Y - half.Y))
		root.Position = UDim2.fromOffset(x, y)
	end
	local progress = make("NumberValue", {Value = 0}, gui)
	local fitScale = 1
	local function renderTransition()
		scale.Scale = fitScale * (0.76 + 0.24 * progress.Value)
		root.GroupTransparency = 1 - progress.Value
	end
	progress.Changed:Connect(renderTransition)
	local function resize()
		local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		fitScale = math.max(0.01, math.min(options.Scale or 0.8, (view.X - 24) / 620, (view.Y - 24) / 636))
		renderTransition()
		if root.Position.X.Scale == 0 then place(Vector2.new(root.Position.X.Offset, root.Position.Y.Offset)) end
	end
	resize()
	local cameraConnection
	local function watchCamera()
		if cameraConnection then cameraConnection:Disconnect() end
		if workspace.CurrentCamera then
			cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
		end
		resize()
	end
	listen(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	gui.Destroying:Connect(function()
		if cameraConnection then cameraConnection:Disconnect() end
		for _, connection in connections do connection:Disconnect() end
	end)
	watchCamera()

	local side = make("Frame", {
		Size = UDim2.new(0, 65, 1, 0), BackgroundColor3 = C.sidebar,
		BorderSizePixel = 0,
	}, root)
	local rail = make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 1, -30),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = C.blue,
	}, side)
	make("UIListLayout", {
		Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, rail)

	local header = make("Frame", {
		Position = UDim2.fromOffset(65, 0), Size = UDim2.new(1, -65, 0, 77),
		BackgroundColor3 = C.panel, BorderSizePixel = 0,
	}, root)
	local title = label(header, options.Title or "Dynxe LT2", 19, C.text, true)
	title.Position = UDim2.fromOffset(23, 16)
	title.Size = UDim2.new(1, -130, 0, 25)
	local subtitle = label(header, options.Subtitle or "Ferry has Departed", 11, C.muted)
	subtitle.Position = UDim2.fromOffset(23, 42)
	subtitle.Size = UDim2.new(1, -140, 0, 18)
	local currentTitle = label(header, "", 13, C.blue, true)
	currentTitle.TextXAlignment = Enum.TextXAlignment.Right
	currentTitle.Position = UDim2.new(1, -175, 0, 24)
	currentTitle.Size = UDim2.fromOffset(103, 22)

	local dragArea = make("Frame", {Name = "Arrastar", Active = true, BackgroundTransparency = 1, Size = UDim2.new(1,-62,1,0), ZIndex = 2}, header)
	local pointer, grab
	dragArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pointer = input
			grab = Vector2.new(input.Position.X, input.Position.Y) - root.AbsolutePosition - root.AbsoluteSize / 2
		end
	end)
	listen(UserInputService.InputChanged, function(input)
		if pointer and (input == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			place(Vector2.new(input.Position.X, input.Position.Y) - grab)
		end
	end)
	listen(UserInputService.InputEnded, function(input)
		if pointer == input then pointer = nil end
	end)

	local window = {Gui = gui, Root = root, _selected = nil}
	local toggleBinding = {key = options.ToggleKey or Enum.KeyCode.RightShift}
	local bindings = {}
	local capturing
	listen(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard or UserInputService:GetFocusedTextBox() then return end
		if capturing then
			if input.KeyCode ~= Enum.KeyCode.Escape then capturing.key = input.KeyCode end
			capturing.display.Text = capturing.key.Name
			capturing = nil
		elseif input.KeyCode == toggleBinding.key then
			window:SetVisible(not window.Visible)
		elseif not processed then
			for _, binding in bindings do
				if binding.key == input.KeyCode then safeCall(binding.callback) end
			end
		end
	end)
	local pages = make("Frame", {
		Position = UDim2.fromOffset(65, 77), Size = UDim2.new(1, -65, 1, -77),
		BackgroundTransparency = 1, ClipsDescendants = true,
	}, root)


	local close = button(header, "×", 25)
	close.Name = "Fechar"
	close.ZIndex = 3
	close.Size = UDim2.fromOffset(44,44)
	close.Position = UDim2.new(1,-56,0,16)
	local launcher = make("ScreenGui", {Name = gui.Name .. "Launcher", ResetOnSpawn = false, DisplayOrder = gui.DisplayOrder + 1}, gui.Parent)
	gui.Destroying:Connect(function() launcher:Destroy() end)
	local reopen = button(launcher, "Abrir painel", 15)
	reopen.Name = "Reabrir"
	reopen.Size = UDim2.fromOffset(116,44)
	reopen.Position = UDim2.new(1,-132,0.5,-22)
	reopen.Visible = false
	local transition
	function window:SetTheme(name) applyTheme(name) end
	function window:SetVisible(visible)
		if self.Visible == visible then return end
		self.Visible = visible
		if visible then gui.Enabled = true end
		pointer = nil
		if capturing then
			capturing.display.Text = capturing.key.Name
			capturing = nil
		end
		if transition then transition:Cancel() end
		root.Visible = true
		reopen.Visible = not visible
		local tween = TweenService:Create(progress,
			TweenInfo.new(visible and 0.46 or 0.23, Enum.EasingStyle.Quart, visible and Enum.EasingDirection.Out or Enum.EasingDirection.In),
			{Value = visible and 1 or 0})
		transition = tween
		tween.Completed:Once(function(state)
			if transition ~= tween or state ~= Enum.PlaybackState.Completed then return end
			root.Visible = visible
			gui.Enabled = visible
			transition = nil
		end)
		tween:Play()
	end
	close.Activated:Connect(function() window:SetVisible(false) end)
	reopen.Activated:Connect(function() window:SetVisible(true) end)
	-- Inicie a entrada depois que o exemplo construir as abas e os controles.
	game:GetService("RunService").PreRender:Once(function()
		if gui.Parent and window.Visible == nil then window:SetVisible(true) end
	end)
	function window:Destroy() gui:Destroy() end

	local tabCount = 0
	local pageTransition
	function window:CreateTab(name, icon)
		tabCount += 1
		local index = tabCount
		local source = tostring(icon or "")
		local image
		if source:match("^%d+$") then
			image = "rbxassetid://" .. source
		elseif source:match("^rbxassetid://%d+$") or source:match("^rbxasset://") then
			image = source
		end
		local nav = button(rail, image and "" or (icon or "□"), 25)
		if image then
			make("ImageLabel", {
				Name = "Icon", Image = image, BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(24, 24), ScaleType = Enum.ScaleType.Fit,
			}, nav)
		end
		nav.Name = name .. "TabButton"
		nav.LayoutOrder = index
		nav.Size = UDim2.fromOffset(43, 43)
		nav.BackgroundTransparency = 1
		local page = make("ScrollingFrame", {
			Name = name .. "Page", Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.blue,
			CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, pages)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 17), PaddingRight = UDim.new(0, 17),
			PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 20),
		}, page)
		make("UIListLayout", {Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder}, page)
		local tab = {Page = page}
		local function selectTab()
			local previous = window._selected
			if previous and previous.page == page then return end
			if pageTransition then pageTransition:Cancel() end
			if previous then
				window._selected.page.Visible = false
				paint(window._selected.nav, "TextColor3", "text")
				animate(window._selected.nav, {BackgroundTransparency = 1})
			end
			page.Position = UDim2.fromOffset(0, 0)
			if previous then
				local direction = index > previous.index and 1 or -1
				page.Position = UDim2.fromOffset(48 * direction, 0)
				pageTransition = TweenService:Create(page, TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)})
				pageTransition:Play()
			end
			page.Visible = true
			currentTitle.Text = string.upper(name)
			paint(nav, "TextColor3", "blue")
			paint(nav, "BackgroundColor3", "card")
			animate(nav, {BackgroundTransparency = 0})
			window._selected = {page = page, nav = nav, index = index}
		end
		nav.Activated:Connect(selectTab)
		if not window._selected then selectTab() end
		function tab:Select() selectTab() end

		function tab:AddSection(text)
			local item = label(page, string.upper(text), 12, C.blue, true)
			item.Size = UDim2.new(1, 0, 0, 19)
			return item
		end

		function tab:AddShopGrid(items, onSelect)
			local gridFrame = make("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, page)
			local grid = make("UIGridLayout", {
				CellSize = UDim2.new(0.25, -7, 0, 132), CellPadding = UDim2.fromOffset(7, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, gridFrame)
			for index, item in ipairs(items) do
				local card = button(gridFrame, "", 12)
				card.Name = item.Name or "Item"
				card.LayoutOrder = index
				paint(card, "BackgroundColor3", "card")
				stroke(card)
				local thumb = make("Frame", {
					Position = UDim2.fromOffset(9, 9), Size = UDim2.new(1, -18, 0, 77),
					BackgroundColor3 = C.panel, BorderSizePixel = 0,
				}, card)
				corner(thumb, 5)
				local source = item.Model
				local clone = source and (source:IsA("Model") or source:IsA("BasePart")) and source:Clone()
				if clone then
					local viewport = make("ViewportFrame", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
						Ambient = Color3.fromRGB(170, 180, 190), LightDirection = Vector3.new(-1,-1,-1),
					}, thumb)
					local model = make("Model", {}, viewport)
					for _, descendant in clone:GetDescendants() do
						if descendant:IsA("BaseScript") then descendant:Destroy() end
					end
					clone.Parent = model
					model:PivotTo(CFrame.identity)
					local bounds, size = model:GetBoundingBox()
					local camera = make("Camera", {FieldOfView = 35}, viewport)
					viewport.CurrentCamera = camera
					local function fit()
						local pixels = viewport.AbsoluteSize
						local aspect = math.min(1, pixels.X / math.max(1, pixels.Y))
						local angle = math.atan(math.tan(math.rad(17.5)) * math.max(0.01, aspect))
						local distance = math.max(0.2, size.Magnitude / (2 * math.sin(angle)))
						camera.CFrame = CFrame.lookAt(bounds.Position + Vector3.new(1,0.65,-1).Unit * distance, bounds.Position)
					end
					viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
					fit()
				elseif item.Image then
					make("ImageLabel", {
						Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
						Image = item.Image, ScaleType = Enum.ScaleType.Fit,
					}, thumb)
				else
					local iconLabel = label(thumb, item.Icon or "◇", 44, C.text, true)
					iconLabel.Size = UDim2.fromScale(1, 1)
					iconLabel.TextXAlignment = Enum.TextXAlignment.Center
				end
				local nameLabel = label(card, item.Name or "Item", 12, C.text, true)
				nameLabel.Position = UDim2.fromOffset(9, 86)
				nameLabel.Size = UDim2.new(1, -18, 0, 20)
				nameLabel.TextXAlignment = Enum.TextXAlignment.Center
				local price = label(card, "$" .. tostring(item.Price or 0), 12, C.green, true)
				price.Position = UDim2.fromOffset(9, 107)
				price.Size = UDim2.new(1, -18, 0, 18)
				price.TextXAlignment = Enum.TextXAlignment.Center
				card.MouseButton1Click:Connect(function() safeCall(onSelect, item) end)
			end
			return gridFrame
		end

		function tab:AddSlider(text, minValue, maxValue, initial, onChange)
			minValue, maxValue = minValue or 1, maxValue or 10
			assert(maxValue > minValue, "maxValue deve ser maior que minValue")
			local value = math.clamp(initial or minValue, minValue, maxValue)
			local holder = make("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, page)
			local caption = label(holder, text, 13, C.text)
			caption.Size = UDim2.new(1, -45, 0, 20)
			local number = label(holder, tostring(value), 13, C.blue, true)
			number.Position = UDim2.new(1, -42, 0, 0)
			number.Size = UDim2.fromOffset(42, 20)
			number.TextXAlignment = Enum.TextXAlignment.Right
			local track = make("Frame", {Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = C.line, BorderSizePixel = 0}, holder)
			corner(track, 3)
			local fill = make("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.blue, BorderSizePixel = 0}, track)
			corner(fill, 3)
			local hit = button(holder, "", 1)
			hit.BackgroundTransparency = 1
			hit.Position = UDim2.fromOffset(0, 20)
			hit.Size = UDim2.new(1, 0, 0, 25)
			local dragging = false
			local function set(nextValue)
				value = math.clamp(math.round(nextValue), minValue, maxValue)
				number.Text = tostring(value)
				fill.Size = UDim2.fromScale((value - minValue) / (maxValue - minValue), 1)
				safeCall(onChange, value)
			end
			local function fromInput(input)
				local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				set(minValue + ratio * (maxValue - minValue))
			end
			hit.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					fromInput(input)
				end
			end)
			listen(UserInputService.InputChanged, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromInput(input) end
			end)
			listen(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
			end)
			set(value)
			return {Frame = holder, Get = function() return value end, Set = set}
		end

		function tab:AddButton(text, rightText, callback)
			local row = button(page, "", 13)
			row.Size = UDim2.new(1, 0, 0, 43)
			stroke(row)
			local left = label(row, text, 13, C.text)
			left.Name = "Caption"
			left.Position = UDim2.fromOffset(13, 0)
			left.Size = UDim2.new(1, -140, 1, 0)
			local right = label(row, rightText or "", 13, C.text, true)
			right.Name = "Amount"
			right.Position = UDim2.new(1, -130, 0, 0)
			right.Size = UDim2.new(0, 116, 1, 0)
			right.TextXAlignment = Enum.TextXAlignment.Right
			row.MouseButton1Click:Connect(function() safeCall(callback) end)
			return row
		end

		function tab:AddToggle(text, initial, callback)
			local enabled = initial == true
			local row = button(page, "", 13)
			row.Size = UDim2.new(1, 0, 0, 43)
			stroke(row)
			local caption = label(row, text, 13, C.text)
			caption.Position = UDim2.fromOffset(13, 0)
			caption.Size = UDim2.new(1, -72, 1, 0)
			local pill = make("Frame", {Position = UDim2.new(1, -55, 0.5, -9), Size = UDim2.fromOffset(42, 18), BorderSizePixel = 0}, row)
			corner(pill, 9)
			local dot = make("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C.text, BorderSizePixel = 0}, pill)
			corner(dot, 6)
			local function set(state)
				enabled = state == true
				paint(pill, "BackgroundColor3", enabled and "blue" or "line")
				animate(dot, {Position = UDim2.fromOffset(enabled and 27 or 3, 3)})
				safeCall(callback, enabled)
			end
			paint(pill, "BackgroundColor3", enabled and "blue" or "line")
			dot.Position = UDim2.fromOffset(enabled and 27 or 3, 3)
			row.Activated:Connect(function() set(not enabled) end)
			return {Frame = row, Get = function() return enabled end, Set = set}
		end

		local function control(text)
			local row = make("Frame", {Size = UDim2.new(1,0,0,43), BackgroundColor3 = C.card, BorderSizePixel = 0}, page)
			corner(row,6)
			local caption = label(row,text,14,C.text)
			caption.Position = UDim2.fromOffset(12,0)
			caption.Size = UDim2.new(0.5,-16,0,43)
			return row
		end
		local function align(field)
			field.Position = UDim2.new(0.5,0,0,5)
			field.Size = UDim2.new(0.5,-6,0,33)
		end
		function tab:AddTextbox(text, initial, callback)
			local row = control(text)
			local box = make("TextBox", {Text = initial or "", PlaceholderText = "Digite aqui", ClearTextOnFocus = false,
				TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = C.text, BackgroundColor3 = C.field, ClipsDescendants = true}, row)
			align(box)
			corner(box,5)
			box.FocusLost:Connect(function() safeCall(callback,box.Text) end)
			return box
		end
		local function keyField(text, binding)
			local field = button(control(text), binding.key.Name)
			align(field)
			binding.display = field
			field.Activated:Connect(function()
				if capturing then capturing.display.Text = capturing.key.Name end
				capturing = binding
				field.Text = "Pressione uma tecla"
			end)
			return field
		end
		function tab:AddWindowKeybind(text)
			return keyField(text, toggleBinding)
		end
		function tab:AddKeybind(text, key, callback)
			local binding = {key = key, callback = callback}
			table.insert(bindings, binding)
			return keyField(text, binding)
		end
		function tab:AddDropdown(text, choices, initial, callback)
			local row = control(text)
			local field = button(row, initial or choices[1] or "Selecionar")
			align(field)
			local list = make("Frame", {Position = UDim2.fromOffset(10,49), Size = UDim2.new(1,-20,0,#choices*42), BackgroundTransparency = 1, Visible = true},row)
			row.ClipsDescendants = true
			local expanded = false
			make("UIListLayout",{Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder},list)
			local function expand(open)
				expanded = open
				animate(row, {Size = UDim2.new(1,0,0,open and (51 + #choices*42) or 43)})
			end
			field.Activated:Connect(function() expand(not expanded) end)
			for i, choice in ipairs(choices) do
				local option = button(list,choice)
				option.LayoutOrder = i
				option.Size = UDim2.new(1,0,0,34)
				option.Activated:Connect(function()
					field.Text = choice
					expand(false)
					safeCall(callback,choice)
				end)
			end
			return field
		end
		return tab
	end

	return window
end

return Library
