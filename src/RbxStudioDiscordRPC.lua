--!strict
local function DecID2ImgID(id: number): string
	return string.format("rbxthumb://type=Asset&id=%s&w=420&h=420",tostring(id))
end

local toolbar = plugin:CreateToolbar("RSDRPC")
local refreshBtn = toolbar:CreateButton(
	"Refresh",
	"Keep rich presence update with right now.",
	DecID2ImgID(10768446856)
)
local applyFormatsBtn = toolbar:CreateButton(
	"ApplyFormats",
	"Apply the formats module script.",
	DecID2ImgID(10768490718),
	"Apply formats"
)

refreshBtn.ClickableWhenViewportHidden = true

local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")
local Selection = game:GetService("Selection")

type ActivitySettings = {
	SCRIPT: string,
	GUI: string,
	BUILD: string,
	DEFAULT: string|nil
}
type Formats = {
	DETAILS: string,
	STATE: ActivitySettings,
	ASSETS: {
		SMALL: string,
		BIG: string
	}
}

local formats: Formats = {
	DETAILS     = "Working on {}",
	STATE       = {
		SCRIPT  = "Editing script: {}",
		GUI     = "Designing GUI",
		BUILD   = "Building",
		DEFAULT = "Editing: {}",
	},
	ASSETS      = {
		SMALL   = "{}",
		LARGE   = "Roblox Studio",
	},
}

type EditionType = "SCRIPT"|"GUI"|"BUILD"
type ScriptClassnames = "Script"|"LocalScript"|"ModuleScript"
type EditingParams = {
	NAME: string,
	TYPE: EditionType,
	CLASS: ScriptClassnames
}|{}

type RequestBody = {
	PROJECT: string|nil,
	EDITING: EditingParams,
	FORMATS: Formats,
}|string

local function request(body: RequestBody)
	local isStr = type(body) == "string"
	if not isStr then
		if not body.PROJECT then body.PROJECT = game:GetFullName() end
		if not body.FORMATS then body.FORMATS = formats end
	end

	local success, message = pcall(function()
		local response = HttpService:RequestAsync(
			{
				Url = "http://localhost:8000/rbxstudioDiscRPC",
				Method = "POST",
				Headers = {
					["Content-Type"] = if isStr then "text/plain" else "application/json"
				},
				Body = if isStr then body else HttpService:JSONEncode(body)
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

local function refresh()
	local curr = StudioService.ActiveScript
	request({
		EDITING   = if curr then {
			NAME  = curr.Name,
			TYPE  = "SCRIPT",
			CLASS = curr.ClassName
		} else {},
	})
end

refresh()
refreshBtn.Click:Connect(refresh)
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(refresh)

local function refreshSelection()
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

Selection.SelectionChanged:Connect(refreshSelection)

local function applyFormats()
	local f: ModuleScript = workspace:FindFirstChild("RSDRPC-FORMATS")
	if not f then return warn() end
	if not f:IsA("ModuleScript") then return warn() end

	formats = require(f)
end

applyFormatsBtn.Click:Connect(applyFormats)

local function quit()
	-- tell rpc to set to idle
	print("go idle")
	request("!IDLE")
end

plugin.Unloading:Connect(quit)
plugin.Deactivation:Connect(quit)
plugin.Destroying:Connect(quit)