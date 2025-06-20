-- Library version
local VERSION = "1.0.0"

local VERSION_URL = "https://raw.githubusercontent.com/Loscope/Assembly-Libraries/refs/heads/main/discord_lib_ver"
local REPO_URL = "https://raw.githubusercontent.com/Loscope/Assembly-Libraries/refs/heads/main/discord.lua"

local webhooks = {}

local notificationSent = false

local function checkVersion()
    print("Checking version at " .. os.date("%H:%M:%S WEST", os.time()))
    http.get(VERSION_URL, function(body)
        if not body then
            print("Failed to check Discord.lua version: No response from GitHub at " .. os.date("%H:%M:%S WEST", os.time()))
            return
        end

        local latestVersion = body:match("^%s*(.-)%s*$")
        if not latestVersion then
            print("Failed to parse latest version from GitHub at " .. os.date("%H:%M:%S WEST", os.time()))
            return
        end

        if latestVersion == VERSION then
            print("Discord.lua is up-to-date. Version: " .. VERSION .. " at " .. os.date("%H:%M:%S WEST", os.time()))
            return
        end

        if not notificationSent then
            notificationSent = true
            print("Discord.lua version mismatch! Local version: " .. VERSION .. ", Latest version: " .. latestVersion .. " at " .. os.date("%H:%M:%S WEST", os.time()))

            for _, webhook in ipairs(webhooks) do
                local embed = DiscordEmbed.new()
                embed:set_title("Update Available")
                embed:set_description("A new version of Discord.lua is available: " .. latestVersion .. ". Please update manually at " .. REPO_URL)
                embed:set_color(255, 165, 0)

                webhook:set_content("@everyone")
                webhook:add_embed(embed)
                webhook:send(function(success, response)
                    if success then
                        print("Update notification sent to Discord webhook successfully at " .. os.date("%H:%M:%S WEST", os.time()))
                    else
                        print("Failed to send update notification to Discord webhook: " .. response)
                    end
                end)
            end

            if #webhooks == 0 then
                print("No webhooks created to send update notification.")
            end
        end
    end)
end

checkVersion()

-- function to escape JSON strings
local function escapeJsonString(str)
    if not str then return "" end
    str = str:gsub('\\', '\\\\')
    str = str:gsub('"', '\\"')
    str = str:gsub('\n', '\\n')
    str = str:gsub('\r', '\\r')
    str = str:gsub('\t', '\\t')
    for i = 0, 31 do
        str = str:gsub(string.char(i), '')
    end
    return str
end

-- discordEmbed table definition
local DiscordEmbed = {}
DiscordEmbed.__index = DiscordEmbed

function DiscordEmbed.new()
    local self = setmetatable({}, DiscordEmbed)
    self.title = nil
    self.description = nil
    self.url = nil
    self.timestamp = nil
    self.color = nil
    self.footer = nil
    self.image = nil
    self.thumbnail = nil
    self.video = nil
    self.provider = nil
    self.author = nil
    self.fields = {}
    return self
end

function DiscordEmbed:set_title(title)
    self.title = title
end

function DiscordEmbed:set_description(description)
    self.description = description
end

function DiscordEmbed:set_url(url)
    self.url = url
end

function DiscordEmbed:set_color(...)
    local args = {...}
    local color
    if #args == 1 then
        color = args[1]
    elseif #args == 3 then
        local red, green, blue = args[1], args[2], args[3]
        if red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255 then
            error("RGB values must be between 0 and 255")
        end
        color = (red * 256 * 256) + (green * 256) + blue
    else
        error("set_color expects 1 integer or 3 RGB values (red, green, blue)")
    end
    if color and (color < 0 or color > 16777215) then
        error("Color must be an integer between 0 and 16777215")
    end
    self.color = color
end

function DiscordEmbed:add_field(name, value, inline)
    table.insert(self.fields, {name = name, value = value, inline = inline or false})
end

function DiscordEmbed:to_json()
    local json = '{'
    if self.title then
        json = json .. '"title": "' .. escapeJsonString(self.title) .. '",'
    end
    if self.description then
        json = json .. '"description": "' .. escapeJsonString(self.description) .. '",'
    end
    if self.url then
        json = json .. '"url": "' .. escapeJsonString(self.url) .. '",'
    end
    if self.color then
        json = json .. '"color": ' .. tostring(self.color) .. ','
    end
    if #self.fields > 0 then
        json = json .. '"fields": ['
        for i, field in ipairs(self.fields) do
            json = json .. '{ "name": "' .. escapeJsonString(field.name) .. '", "value": "' .. escapeJsonString(field.value) .. '", "inline": ' .. tostring(field.inline) .. ' }'
            if i < #self.fields then json = json .. ',' end
        end
        json = json .. '],'
    end
    if json:sub(-1) == ',' then
        json = json:sub(1, -2)
    end
    json = json .. '}'
    return json
end

-- discordWebhook table definition
local DiscordWebhook = {}
DiscordWebhook.__index = DiscordWebhook

function DiscordWebhook.new(url)
    local self = setmetatable({}, DiscordWebhook)
    self.url = url
    self.content = nil
    self.username = nil
    self.avatar_url = nil
    self.tts = false
    self.embeds = {}
    self.wait = false
    table.insert(webhooks, self)
   -- print("Webhook created at " .. os.date("%H:%M:%S WEST", os.time()) .. " with URL: " .. (url or "No URL")) -- debug shit
    return self
end

function DiscordWebhook:set_content(content)
    self.content = content
end

function DiscordWebhook:set_username(username)
    self.username = username
end

function DiscordWebhook:set_avatar_url(avatar_url)
    self.avatar_url = avatar_url
end

function DiscordWebhook:add_embed(embed)
    table.insert(self.embeds, embed)
end

function DiscordWebhook:send(callback)
    local payload = '{'
    if self.content then payload = payload .. '"content": "' .. escapeJsonString(self.content) .. '",' end
    if self.username then payload = payload .. '"username": "' .. escapeJsonString(self.username) .. '",' end
    if self.avatar_url then payload = payload .. '"avatar_url": "' .. escapeJsonString(self.avatar_url) .. '",' end
    if self.tts then payload = payload .. '"tts": ' .. tostring(self.tts) .. ',' end
    if #self.embeds > 0 then
        payload = payload .. '"embeds": ['
        for i, embed in ipairs(self.embeds) do
            payload = payload .. embed:to_json()
            if i < #self.embeds then payload = payload .. ',' end
        end
        payload = payload .. ']'
    end
    if payload:sub(-1) == ',' then payload = payload:sub(1, -2) end
    payload = payload .. '}'
   -- print("Sending payload: " .. payload .. " at " .. os.date("%H:%M:%S WEST", os.time())) --Debug Shit
    local requestUrl = self.url .. (self.wait and "?wait=true" or "")
    http.post(
        requestUrl,
        {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "LoscopeLib/1.0"
        },
        payload,
        function(success, body)
            if success then
              --  print("Webhook sent successfully at " .. os.date("%H:%M:%S WEST", os.time()) .. " with response: " .. (body or "No response body")) -- debug shit
            else
               -- print("Failed to send webhook at " .. os.date("%H:%M:%S WEST", os.time()) .. ": " .. (body or "No response")) -- debug shit
            end
            if callback then callback(success, body) end
            self.embeds = {}
            self.content = nil
        end
    )
end

return { DiscordWebhook = DiscordWebhook, DiscordEmbed = DiscordEmbed, checkVersion = checkVersion }
