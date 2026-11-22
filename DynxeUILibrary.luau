-- DynxeUILibrary.luau
-- ModuleScript para StarterPlayerScripts/ReplicatedStorage.
-- A biblioteca cria somente a interface; passe callbacks para ligar as ações ao jogo.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}

local C = {
	background = Color3.fromRGB(18, 19, 23),
	sidebar = Color3.fromRGB(12, 14, 17),
	panel = Color3.fromRGB(27, 28, 33),
	card = Color3.fromRGB(32, 33, 39),
	field = Color3.fromRGB(22, 23, 28),
	line = Color3.fromRGB(43, 45, 52),
	text = Color3.fromRGB(225, 228, 234),
	muted = Color3.fromRGB(137, 141, 152),
	blue = Color3.fromRGB(91, 111, 241),
	green = Color3.fromRGB(79, 198, 121),
}

local function make(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props) do object[key] = value end
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

function Library:CreateWindow(options)
	options = options or {}
	local player = Players.LocalPlayer
	assert(player, "DynxeUILibrary deve ser usada em um LocalScript")
	local gui = make("ScreenGui", {
		Name = options.Name or "DynxeUI", ResetOnSpawn = false,
		IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))

	local root = make("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 900),
		BackgroundColor3 = C.background, BorderSizePixel = 0, ClipsDescendants = true,
	}, gui)
	corner(root, 13)
	stroke(root, Color3.fromRGB(37, 39, 46))
	local scale = make("UIScale", {Scale = 1}, root)
	local function resize()
		local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.min(1, (view.X - 24) / 760, (view.Y - 24) / 900)
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
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()

	local side = make("Frame", {
		Size = UDim2.new(0, 65, 1, 0), BackgroundColor3 = C.sidebar,
		BorderSizePixel = 0,
	}, root)
	local rail = make("Frame", {
		Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 1, -30),
		BackgroundTransparency = 1,
	}, side)
	make("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center}, rail)

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
	currentTitle.Position = UDim2.new(1, -120, 0, 24)
	currentTitle.Size = UDim2.fromOffset(103, 22)

	local pages = make("Frame", {
		Position = UDim2.fromOffset(65, 77), Size = UDim2.new(1, -65, 1, -77),
		BackgroundTransparency = 1, ClipsDescendants = true,
	}, root)

	local window = {Gui = gui, Root = root, _selected = nil}
	function window:SetVisible(visible) gui.Enabled = visible end
	function window:Destroy() gui:Destroy() end

	function window:CreateTab(name, icon)
		local nav = button(rail, icon or "□", 25)
		nav.Name = name .. "TabButton"
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
		make("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, page)
		local tab = {Page = page}
		local function selectTab()
			if window._selected then
				window._selected.page.Visible = false
				animate(window._selected.nav, {BackgroundTransparency = 1, TextColor3 = C.text})
			end
			page.Visible = true
			currentTitle.Text = string.upper(name)
			animate(nav, {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(31, 41, 88), TextColor3 = C.blue})
			window._selected = {page = page, nav = nav}
		end
		nav.MouseButton1Click:Connect(selectTab)
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
				CellSize = UDim2.new(0.25, -7, 0, 170), CellPadding = UDim2.fromOffset(7, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, gridFrame)
			for index, item in ipairs(items) do
				local card = button(gridFrame, "", 12)
				card.Name = item.Name or "Item"
				card.LayoutOrder = index
				card.BackgroundColor3 = C.card
				stroke(card)
				local thumb = make("Frame", {
					Position = UDim2.fromOffset(9, 9), Size = UDim2.new(1, -18, 0, 101),
					BackgroundColor3 = Color3.fromRGB(39, 41, 48), BorderSizePixel = 0,
				}, card)
				corner(thumb, 5)
				if item.Image then
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
				nameLabel.Position = UDim2.fromOffset(9, 116)
				nameLabel.Size = UDim2.new(1, -18, 0, 20)
				nameLabel.TextXAlignment = Enum.TextXAlignment.Center
				local price = label(card, "$" .. tostring(item.Price or 0), 12, C.green, true)
				price.Position = UDim2.fromOffset(9, 139)
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
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromInput(input) end
			end)
			UserInputService.InputEnded:Connect(function(input)
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
			left.Position = UDim2.fromOffset(13, 0)
			left.Size = UDim2.new(1, -140, 1, 0)
			local right = label(row, rightText or "", 13, C.text, true)
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
				animate(pill, {BackgroundColor3 = enabled and C.blue or C.line})
				animate(dot, {Position = UDim2.fromOffset(enabled and 27 or 3, 3)})
				safeCall(callback, enabled)
			end
			pill.BackgroundColor3 = enabled and C.blue or C.line
			dot.Position = UDim2.fromOffset(enabled and 27 or 3, 3)
			row.MouseButton1Click:Connect(function() set(not enabled) end)
			return {Frame = row, Get = function() return enabled end, Set = set}
		end

		return tab
	end

	return window
end

return Library
