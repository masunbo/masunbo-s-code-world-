贝壳物联智能开关，更新修正tmr.alarm问题
代码部分
8266纯粹是个坑，搞了3周，陷了无数次。写在2020疫情之后，武汉加油，中国加油！！！下面随便聊个坑：
nodemcu-build官网 的固件代码部分已经更新，特别是tmr.alarm计时（钟表）函数，原来的结构多简单，现在生生的代码编译不过去，只能用18年12月以前的固件。可是那些封装好的有些不是你需要的，好尴尬。现在使用了动态tmr函数重新修改封装。----------2020.4.5

固件下载nodemcu站点

共init.lua config.lua两个文件，烧录固件看附件。
1老版固件
包含以下模块：
file , GPIO , HTTP , MQTT , net , node , PWM , SJSON , timer , UART , WIFI

2新版固件
包含以下模块：
file,gpio,http,mqtt,net,node,pcm,pwm,rtcfifo,rtcmem,rtctime,sjson,tmr,uart,wifi,tls

代码部分

--------------------------------------file （init.lua）

print("set up wifi mode------------masunbo001 wulianwang")

wifi.setmode(wifi.STATIONAP)

station_cfg={}

--here SSID and PassWord should be modified according your wireless router

station_cfg.ssid="X-HU"                ------------yourself

station_cfg.pwd="chenpeng"         ------------yourself

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

            if  TcpSocketList == sck then

                TcpSocketList = nil

                print(i.."-Disconnect")

            end

        end

    end)

end)

uart.on("data",0,function(data)

    for i=0,5 do

        if  TcpSocketList ~= nil then 

            TcpSocketList:send(data)

        end

    end

end, 0)

-------------------------------------------file （config.lua）

--use sjson
_G.cjson = sjson
--modify DEVICEID INPUTID APIKEY
DEVICEID = "xxxxxxxxxxxxx" --yourself
APIKEY = "xxxxxxxxxxxxx"  --yourself
INPUTID = "xxxxxxxxxxxxx" --yourself
host = host or "www.bigiot.net"
port = port or 8181
LED = 3
--LED1 = 4
isConnect = false

gpio.mode(LED,gpio.OUTPUT)
--gpio.mode(LED1,gpio.OUTPUT)



----------------------------------------------

local _Me = {}

autoTime = 5000

hadCloseRoter = false

count = 1

function watch()
mytimer2 = tmr.create()
mytimer2:alarm(autoTime, tmr.ALARM_AUTO, function ()


print("lianjie "..count,"ci")

count = count+1

if wifi.sta.getip() == nil then

autoTime = 20000
mytimer1 = tmr.create()
mytimer1:stop()

if hadCloseRoter == false then
mytimer2:stop()


hadCloseRoter = true

print("dog watch Time set 4s once")

watch()

end

else

if hadCloseRoter then

print("check had close wifi link, now need auto link service,and dog watch time set 1s once")

isConnect = false

hadCloseRoter = false

autoTime = 5000

mytimer1:stop()

mytimer2:stop()

cu = nil

watch()

run()

end

end

end)

end

watch()



function run()

local cu = net.createConnection(net.TCP)

cu:on("receive", function(cu, c)

print("masunbo,received\n")

print(c)
isConnect = true
-------------------------------------------------------
r = cjson.decode(c)
    if r.M == "say" then
      if r.C == "offOn" then   
          gpio.write(LED, gpio.LOW)
          tmr.delay(1850000) 
          gpio.write(LED, gpio.HIGH)  
          ok, offOned = pcall(cjson.encode, {M="say",ID=r.ID,C="ON OFF"})
          cu:send( offOned.."\n" )
      end
      if r.C == "play" then   
        gpio.write(LED, gpio.LOW) 
        ok, played = pcall(cjson.encode, {M="say",ID=r.ID,C="LED turn on!"})
        cu:send( played.."\n" )
      end
      if r.C == "stop" then  
        gpio.write(LED, gpio.HIGH)
        ok, stoped = pcall(cjson.encode, {M="say",ID=r.ID,C="LED turn off!"})
        cu:send( stoped.."\n" ) 
      end    
     --if r.C == "pause" then   
     --   gpio.write(LED1, gpio.LOW)
     --   ok, pauseed = pcall(cjson.encode, {M="say",ID=r.ID,C="LED turn on!"})
     --   cu:send( pauseed.."\n" )      
     -- end        
    end
  end)




---------------------------------------------------------------------------
cu:on('disconnection',function(scu)
    cu = nil
    isConnect = false
    print("beike,disconnection")
    mytimer1:stop()
    mytimer6 = tmr.create()
    mytimer6:alarm(10000, tmr.ALARM_SINGLE, run)
    end)

  cu:connect(port, host)
  ok, s = pcall(cjson.encode, {M="checkin",ID=DEVICEID,K=APIKEY})
  if ok then
    print(s)
  else
    print("failed to encode!")
  end

  if isConnect then
  cu:send(s.."\n")
  end
  mytimer1 = tmr.create()
  mytimer1:alarm(12000, tmr.ALARM_AUTO,function()
  if isConnect then
     print("auto send headPackge")
     cu:send(s.."\n")
  else
     print("not connected ...")
  end
  end)
end
run() 
