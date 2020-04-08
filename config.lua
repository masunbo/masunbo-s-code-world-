--use sjson
_G.cjson = sjson
--modify DEVICEID INPUTID APIKEY
DEVICEID = "17327"
APIKEY = "e820e4cef"
INPUTID = "15472"
host = host or "www.bigiot.net"
port = port or 8181
LED = 3
--LED1 = 4
isConnect = false

gpio.mode(LED,gpio.OUTPUT)
--gpio.mode(LED1,gpio.OUTPUT)

if 
  gpio.read(LED) == 0
  then
  gpio.write(LED, gpio.HIGH)
  --else
  --gpio.write(LED, gpio.LOW)
  end
  
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
