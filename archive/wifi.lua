require("led")
local P = require("parse")

wifi.setmode(wifi.STATION)

wifi.sta.config{
  ssid = "Hive Stud",
  pwd  = "shifterambiancefinlesskilt",
  auto = true
}
wifi.sta.connect()

tmr.create():alarm(1000, tmr.ALARM_AUTO, function(t)
  local ip = wifi.sta.getip()
  if not ip then
    print("Waiting for IP…")
    led(512, 1023, 1023)
    return
end

t:unregister()
led(512, 1023, 512)
  print("Connected! IP address:", ip)

sntp.sync("pool.ntp.org",
function(sec,usec,server)
  rtctime.set(sec,usec)

  local q = ""
  if file.open("query.gql","r") then
	q = file.read()
	file.close()
  end

  local payload = sjson.encode({
	query     = q,
	variables = { stopId = "HSL:1100125" }
  })
  collectgarbage()

  local ok, secrets = pcall(require, "secrets")
  local KEY = ok and secrets.DIGITRANSIT_KEY or nil
  if not KEY then
    print("Warning: Digitransit key not found. Create .env and run 'make upload-secrets' to upload secrets.lua.")
  end
  local headers = "Content-Type: application/json\r\n"
  if KEY then headers = headers .. "Digitransit-Subscription-Key: " .. KEY .. "\r\n" end

  http.post(
	"https://api.digitransit.fi/routing/v2/hsl/gtfs/v1",
	headers,
	payload,
	function(code,data)
	  if code < 0 then
		print("HTTP request failed")
	  else
		print("Status:",code)
		print("Response:",data)
		P.arrival_display(data)
	  end
	end
  )
end,
function()
  print("NTP sync failed")
end)

end)