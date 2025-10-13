local mchttpserver = require("mchttp-server")

local app = mchttpserver.new(80)

local directory = "/cchttp/server"

app:listen("/echo","GET",function(pack)
    return {body=pack.body,contentType="text/plain"}
end)

app:listen("/post","POST",function(pack)
    print("MSG:",pack.body)
end)

app:listen("/", "GET", function(pack)
    print("Got message: ", pack.body)
    local handle = fs.open(directory.."/".."index.ccml", "r")
    local data = handle.readAll()
    handle.close()
    return {body=data,contentType="text/plain"}
end)

app:run()
