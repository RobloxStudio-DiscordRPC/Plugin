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
applyFormatsBtn.ClickableWhenViewportHidden = true

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
		LARGE: string
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
	CLASS: ScriptClassnames|nil
}|{}

type RequestBody = {
	PROJECT: string|nil,
	EDITING: EditingParams,
	FORMATS: Formats|nil,
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

local function serializeTable(
	val: {[any]: any},
	name: string|nil,
	skipnewlines: boolean|nil,
	depth: number|nil
): string
    skipnewlines = skipnewlines or false
    depth = depth or 0 :: number

    local tmp = string.rep("\t", depth)

    if name then tmp ..= name .. " = " end

    if type(val) == "table" then
        tmp ..= "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp ..= string.rep("\t", depth) .. "}"
    elseif type(val) == "number" then
        tmp ..= tostring(val)
    elseif type(val) == "string" then
        tmp ..= string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp ..= (val and "true" or "false")
    else
        tmp ..= "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

local function applyFormats()
	local f: ModuleScript = workspace:FindFirstChild("RSDRPC-FORMATS")
	if not f then
		warn("RSDRPC: Couldn't find formats configuration.")
		local config = Instance.new("ModuleScript")
		config.Parent = workspace
		config.Name = "RSDRPC-FORMATS"
		config.Archivable = false
		config.Source ..= "--This is the configuration for Roblox Studio Discord RPC\n\n"
		config.Source ..= "return "..serializeTable(formats)
		plugin:OpenScript(config, 3)
		print("RSDRPC: Opened formats configuration.")
		return
	end

	if not f:IsA("ModuleScript") then
		return warn("RSDRPC: Formats configuration is not a ModuleScript")
	end

	formats = require(f)
end

applyFormats()
applyFormatsBtn.Click:Connect(applyFormats)

refresh()
refreshBtn.Click:Connect(refresh)
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(refresh)

local function refreshSelection()
	if StudioService.ActiveScript then return end

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

local function quit()
	-- tell rpc to set to idle
	print("go idle")
	request("!IDLE")
end

plugin.Unloading:Connect(quit)
plugin.Deactivation:Connect(quit)
plugin.Destroying:Connect(quit)