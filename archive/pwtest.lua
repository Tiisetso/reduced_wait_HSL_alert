function get_num_values(json_text, search_term)
  local arrivals = {}
  local pattern = '"' .. search_term .. '"%s*:%s*"?(%d+)"?'
  for num in json_text:gmatch(pattern) do
    table.insert(arrivals, num)
  end
  return arrivals
end


wifi.setmode(wifi.STATION)

local red, green, blue = 5, 6, 7
gpio.mode(red, gpio.OUTPUT)
gpio.mode(green, gpio.OUTPUT)
gpio.mode(blue, gpio.OUTPUT)

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
    gpio.write(red, gpio.LOW)
    gpio.write(green, gpio.HIGH)
    gpio.write(blue, gpio.HIGH)
    return
  end

  t:unregister()
  print("Connected! IP address:", ip)
  gpio.write(red, gpio.HIGH)
  gpio.write(green, gpio.HIGH)
  gpio.write(blue, gpio.LOW)

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
        variables = { stopId = "HSL:1112126" }
    })
    q = nil --added
    collectgarbage() --added
    print("heap:", node.heap()) --debug print heap size

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
            print(#data) -- debug print see length of data
            print("heap:", node.heap()) --debug print heap size
            print("Status:",code)
            print("Response:",data)
            get_num_values(data, "realtimeArrival")
        end
        end
    )
    end,
    function()
    print("NTP sync failed")
    end)
    collectgarbage() --added
end)