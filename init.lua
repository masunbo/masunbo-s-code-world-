--init.lua
print("set up wifi mode------------masunbo001 wulianwang")

wifi.setmode(wifi.STATIONAP)

station_cfg={}
--here SSID and PassWord should be modified according your wireless router
station_cfg.ssid="X-HU"
station_cfg.pwd="chenpeng"
station_cfg.save=true
wifi.sta.config(station_cfg)
wifi.sta.autoconnect(1)

APcfg={}
APcfg.ssid="ESP8266001"
APcfg.pwd="masunbo080412"
wifi.ap.config(APcfg)
str=nil
ssidTemp=nil
str=wifi.ap.getmac()
ssidTemp=string.format("%s%s%s",string.sub(str,10,11),string.sub(str,13,14),string.sub(str,16,17))
collectgarbage()

print("Soft AP started")
print("Heep:(bytes)"..node.heap())
print("MAC:"..wifi.ap.getmac())
print("\r\nIP:"..wifi.ap.getip())

print("------------Ready to start soft ap-------------")

-----------------------------------------------------
mytimer = tmr.create()
mytimer:alarm(3000, tmr.ALARM_AUTO, function ()
if wifi.sta.getip()== nil then
print("IP unavaiable, Waiting...")
else
mytimer:stop()
print("Config done, IP is "..wifi.sta.getip())
dofile("config.lua")
end
end)


TCPSever=net.createServer(net.TCP,28800) --creat TCP system
 
TcpClientCnt = 0  
TcpSocketList={}  
 
TCPSever:listen(8080,function(socket) 
 
    if  TcpClientCnt == 5 then  
        if  TcpSocketList[0] ~= nil then 
            TcpSocketList[0]:close()     
            TcpSocketList[0] = nil   
        end    
    end
 
    TcpSocketList[TcpClientCnt] = socket 
 
    print(TcpClientCnt.."-Connect")
 
    TcpClientCnt = TcpClientCnt + 1
 
    if  TcpClientCnt == 5 then 
        TcpClientCnt = 0
    end
 
    socket:on("receive",function(socket,data) 
          uart.write(0,data) 
    end) 
 
 
    socket:on("disconnection",function(sck,c) 
        for i=0,5 do                
            if  TcpSocketList[i] == sck then 
                TcpSocketList[i] = nil
                print(i.."-Disconnect") 
            end
        end
    end)
 
end)
 

uart.on("data",0,function(data) 
 
    for i=0,5 do 
        if  TcpSocketList[i] ~= nil then  
            TcpSocketList[i]:send(data)
        end
    end
 
end, 0)





 

-------------------------------------------------
