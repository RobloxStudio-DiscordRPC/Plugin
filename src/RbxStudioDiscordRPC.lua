local http = game:GetService("HttpService")
local toolbar = plugin:CreateToolbar("Roblox Studio Discord rich presence")
local button = toolbar:CreateButton("Open", "Open", "")

-- Remember to set enable HTTP Requests in game settings!
local HttpService = game:GetService("HttpService")
 
local function request()
	local response = HttpService:RequestAsync(
		{
			Url = "http://localhost:8000/",  -- This website helps debug HTTP requests
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"  -- When sending JSON, set this!
			},
			Body = HttpService:JSONEncode({hello = "world"})
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

button.Click:Connect(function()
    -- Remember to wrap the function in a 'pcall' to prevent the script from breaking if the request fails
    local success, message = pcall(request)
    if not success then
        print("Http Request failed:", message)
    end
end)