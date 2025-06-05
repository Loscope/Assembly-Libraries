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
        -- single argument: treat as decimal color value
        color = args[1]
    elseif #args == 3 then
        -- three arguments: treat as RGB (red, green, blue)
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
    if self.content then
        payload = payload .. '"content": "' .. escapeJsonString(self.content) .. '",'
    end
    if self.username then
        payload = payload .. '"username": "' .. escapeJsonString(self.username) .. '",'
    end
    if self.avatar_url then
        payload = payload .. '"avatar_url": "' .. escapeJsonString(self.avatar_url) .. '",'
    end
    if self.tts then
        payload = payload .. '"tts": ' .. tostring(self.tts) .. ','
    end
    if #self.embeds > 0 then
        payload = payload .. '"embeds": ['
        for i, embed in ipairs(self.embeds) do
            payload = payload .. embed:to_json()
            if i < #self.embeds then payload = payload .. ',' end
        end
        payload = payload .. '],'
    end
    if payload:sub(-1) == ',' then
        payload = payload:sub(1, -2)
    end
    payload = payload .. '}'
    print("Sending payload: " .. payload)
    local requestUrl = self.url .. (self.wait and "?wait=true" or "")
    http.post(
        requestUrl,
        {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "LoscopeLib/1.0"
        },
        payload,
        function(body)
            if body == "" or body:find('"id":') then
                callback(true, body)
            else
                callback(false, body)
            end
        end
    )
end

-- to export both tables
return { DiscordWebhook = DiscordWebhook, DiscordEmbed = DiscordEmbed }