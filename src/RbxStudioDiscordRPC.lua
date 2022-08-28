local toolbar = plugin:CreateToolbar("Roblox Studio Discord rich presence")
local button = toolbar:CreateButton("Open", "Open", "")
button.ClickableWhenViewportHidden = true

local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")
local MarketplaceService = game:GetService("MarketplaceService")
local place = MarketplaceService:GetProductInfo(game.PlaceId)

local function request()
	local curr = StudioService.ActiveScript
	local response = HttpService:RequestAsync(
		{
			Url = "http://localhost:8000/rbxstudioDiscRPC",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode({
				PROJECT = place.Name,
				EDITING =  if curr then {
					NAME = curr.Name,
					TYPE = curr.ClassName,
				} else nil,
			})
		}
	)
 
	-- Inspect the response table
	if response.Success then
		print("Status code:", response.StatusCode, response.StatusMessage)
		print("Response body:\n", response.Body)
	else
		print("The request failed:", response.StatusCode, response.StatusMessage)
	end
end

local function onClick()
	local success, message = pcall(request)
    if not success then
        print("Http Request failed:", message)
    end
end

onClick()
button.Click:Connect(onClick)
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(onClick)