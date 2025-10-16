# CCHTTP
This is a fork of MCHTTP by HHOY made to work with the CCML language.
The goal of this fork is to make a fully-featured internet that runs entirely in-game using a custom markup language based on XML.
Check out the [CCHTTP Wiki](https://github.com/Mallowwww/CCHTTP-for-CCML/wiki) for help setting it up!
# CCML
CCML is a markup language built off of Basalt2's XML parser. On its own, it works just like Basalt2, letting you create pages with XML elements.
```xml
<label text="This is a label !"/>
<label y="3" text="This is another label !">
```
The main addition to Basalt2 that CCML provides is the ability to add environment variables in-code. In an `<env/>` tag, you can place a table who's elements will be added to the environment, including things like functions. As well, the default environment has access to `cchttp`, `dns`, `http`, `getElement()` (for getting an element with a given id), some of the `os` module, among some other helpful variables. Putting these together, it becomes possible to make a fully featured web application that's fully sandboxed.
```xml
<env>{
    func = function(self)
        if not cchttp or not dns then return end
        local addr, error = dns.lookup("example.com", 5) -- In-game website with a "/echo" endpoint
        if not addr then return end
        local result = cchttp.request(
            addr, 80, "This was sent to the server", "/echo", "GET", 5
        )
        if result and result.body then
            getElement("changeme"):setText(result.body)
        end
    end
}</env>
<label id="changeme" text="This is a label" />
<button text="Click me" y="3" onClick="func" />
```
# Server
The `cchttp-server.lua` module lets you define endpoints with custom functions to respond to them.
```lua
local cchttpserver = require("cchttp-server")
local app = cchttpserver.new(80)
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
```
Server listeners also support wildcards, letting you make traversable filesystems:
```lua
app:listen("/*", "GET", function(pack)
    print("Wildcard hit! ", pack.body)
    if pack.path[-1] == "/" then pack.path = string.sub(pack.path, 1, #pack.path) end
    local location = directory.."/"..pack.path.."/index.ccml", "r"
    local status = 200
    if not fs.exists(location) then status = 404 end
    local handle = nil
    if status == 404 then
        handle = fs.open(directory.."/404.ccml", "r")
    else
        handle = fs.open(location, "r")
    end
    local data = nil
    if handle then
        data = handle.readAll()
        handle.close()
    else
        data = ""
    end
    return {body=data,contentType="text/plain", status = status}
end)
```
# DNS
`dns.lua` runs a DNS server that can allow websites to have human-readable names. It keeps all of its values in a table in `/cchttp/dns/lookup`, so adding values here makes them available to users.
# Client
There exists a browser in the client folder known as CCSurf. It gives the bare minimum so users can effectively view and interact with websites. It can retrieve CCML from the filesystem, `cchttp`, and even `http`. You can also bookmark a URL, meaning you will automatically travel to that website on start. 
<br>
There's no requirement that you use CCSurf; browsers can be made using the `craftium.lua` module. run `craftium.startInstance(data, frame, cchttp, http)` with `data` as the website text and `frame` as the Basalt2 frame you want it to use, and it will create that website with the proper environment.
