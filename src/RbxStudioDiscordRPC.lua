local toolbar = plugin:CreateToolbar("Roblox Studio Discord rich presence")
local button = toolbar:CreateButton("Open", "Open", "")
button.ClickableWhenViewportHidden = true

local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")
local MarketplaceService = game:GetService("MarketplaceService")
local place = MarketplaceService:GetProductInfo(game.PlaceId)
local Selection = game:GetService("Selection")

type EditionType = "SCRIPT"|"GUI"|"BUILD"
type ScriptClassnames = "Script"|"LocalScript"|"ModuleScript"

type RequestBody = {
	PROJECT: string|nil,
	EDITING: {
		NAME: string,
		TYPE: EditionType,
		CLASS: ScriptClassnames|nil
	}|{}
}

local function request(body: RequestBody)
	if not body.PROJECT then body.PROJECT = place.Name end

	local success, message = pcall(function()
		local response = HttpService:RequestAsync(
			{
				Url = "http://localhost:8000/rbxstudioDiscRPC",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = HttpService:JSONEncode(body)
			}
		)

		-- Inspect the response table
		if response.Success then
			print("Status code:", response.StatusCode, response.StatusMessage)
			print("Response body:\n", response.Body)
		else
			print("The request failed:", response.StatusCode, response.StatusMessage)
		end
	end)

	if not success then
        print("Http Request failed:", message)
    end
end

local function onClick()
	local curr = StudioService.ActiveScript
	request({
		EDITING   = if curr then {
			NAME  = curr.Name,
			TYPE  = "SCRIPT",
			CLASS = curr.ClassName
		} else {},
	})
end

--onClick()
button.Click:Connect(onClick)
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(onClick)

local function somethingSelected()
	local selected = Selection:Get()
	if #selected == 0 then return end

	local recentlySelected = selected[#selected]
	local editionType: EditionType

	if recentlySelected:IsA("GuiObject") then
		editionType = "GUI"
	elseif recentlySelected:IsA("PVInstance") then
		editionType = "BUILD"
	else return request({EDITING = {}}) end

	request({
		EDITING = {
			NAME = recentlySelected.Name,
			TYPE = editionType
		}
	})
end

Selection.SelectionChanged:Connect(somethingSelected)