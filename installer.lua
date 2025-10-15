-- Based on MCHTTP by HHOY
local githubPage = "https://raw.githubusercontent.com/Mallowwww/CCHTTP-for-CCML/refs/heads/main/"
local directory = "/cchttp/"
local files = {
    "client/cchttp.lua",
    "client/craftium.lua",
    "client/browser.lua",
    "client/dnsapi.lua",
    "client/error.ccml",
    "dns/dns.lua",
    "dns/lookup",
    "server/cchttp-server.lua",
    "server/server.lua",
    "server/index.ccml"
}
local categoryNames = {"Client", "DNS", "Server", "All", "Quit"}
local categories = {
    Client = {
        "client/cchttp.lua",
        "client/craftium.lua",
        "client/browser.lua",
        "client/dnsapi.lua",
        "client/error.ccml"
    }, DNS = {
        "dns/dns.lua",
        "dns/lookup"
    }, Server = {
        "server/cchttp-server.lua",
        "server/server.lua",
        "server/index.ccml"
    }, All = files,
    Quit = {}
}
print("Installing CCHTTP v0.0.1...")
print("Available distrobutions:")
for i,a in pairs(categoryNames) do
    print("    ", i, a)
end
write("Write number to install: ")
local ans = nil
while true do
    ans = tonumber(read())
    if not ans or ans < 1 or ans > 5 then
        write("Please select a valid number: ")
    else
        if categoryNames[ans] == "Quit" then 
            print("Exiting...")
            return 
        end
        break
    end
end
shell.run("rm "..directory)
print("Installing "..categoryNames[ans].."...")
for i,j in pairs(categories[categoryNames[ans]]) do
    print(i, j, ans)
    local req = http.get(githubPage..j)
    local data = req.readAll()
    local handle = fs.open(directory..j,"w")
    handle.write(data)
    handle.close()
end
print("Success !")
if categoryNames[ans] == "Client" or categoryNames[ans] == "All" then
    print("Checking if Basalt is installed...")
    local result = pcall(function() temp = require("basalt") end)
    if not result then
        print("Installing Basalt...")
        shell.run("wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -r")
    end
    if not pcall(function() temp = require("basalt") end) then
        term.setTextColor(Colors.red)
        print("ERROR - Could not install Basalt")
        term.setTextColor(Colors.white)
    end
end
print("Done !")