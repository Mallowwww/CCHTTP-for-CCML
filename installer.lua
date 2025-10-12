-- Based on MCHTTP by HHOY
local githubPage = "https://raw.githubusercontent.com/Mallowwww/CCHTTP-for-CCML/refs/heads/main/"
local files = {
    "client/mchttp.lua",
    "client/craftium.lua",
    "client/browser.lua",
    "client/dnsapi.lua",
    "dns/dns.lua",
    "dns/lookup",
    "server/mchttp-server.lua",
    "server/server.lua"
}
local categories = {
    "Client": [
        "client/mchttp.lua",
        "client/craftium.lua",
        "client/browser.lua",
        "client/dnsapi.lua"
    ], "DNS": [
        "dns/dns.lua",
        "dns/lookup"
    ], "Server": [
        "server/mchttp-server.lua",
        "server/server.lua"
    ], "All": files,
    "Quit": []
}
print("Installing CCHTTP v0.0.1...")
print("Available distrobutions:")
local n = 1
for i,a in ipairs(categories) do
    print(n,i)
    n = n + 1
end
write("Write number to install: ")
local ans = nil
while true do
    ans = tonumber(read())
    if not ans or ans < 1 or ans > 5 then
        write("Please select a valid number: ")
    else
        if ans == 5 then return end
        break
    end
end
for i,j in pairs(categories[ans]) do
    local req = http.get(githubPage..j)
    local data = req.readAll()
    local handle = fs.open(files[ans],"w")
    handle.write(data)
    handle.close()
end
print("Success !")
