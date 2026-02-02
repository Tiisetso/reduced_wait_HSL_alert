local P     = require("parse")
local http  = require("http")
local sjson = require("sjson")
local tmr   = tmr

local _payload = (function()
  local q = ""
  if file.open("query.gql", "r") then
    q = file.read()
    file.close()
  end
  return sjson.encode({
    query     = q,
    variables = { stopId = "HSL:1100125" },
  })
end)()

local M = {}

-- Load secrets (optional). Generate and upload with `make upload-secrets`.
local ok, secrets = pcall(require, "secrets")
local KEY = ok and secrets.DIGITRANSIT_KEY or nil
if not KEY then
  print("Warning: Digitransit key not found. Create .env and run 'make upload-secrets' to upload secrets.lua.")
end

function M.fetch()
  collectgarbage()
  collectgarbage()
  
  tmr.create():alarm(200, tmr.ALARM_SINGLE, function()
    local headers = "Content-Type: application/json\r\n"
    if KEY then headers = headers .. "Digitransit-Subscription-Key: " .. KEY .. "\r\n" end

    http.post(
      "https://api.digitransit.fi/routing/v2/hsl/gtfs/v1",
      headers,
      _payload,
      function(code, data)
        if code < 0 then
          print("HTTP request failed", code)
        else
          print("Status:", code)
          P.arrival_display(data)
        end
		collectgarbage()
      end
    )
  end)
end

return M
