local mod = require 'core/mods'

local devices={}

mod.hook.register("script_pre_init", "midimod", function()
  -- process incoming midi
  if #midi.devices<2 then
  	do return end
  end
  for _,dev in pairs(midi.devices) do
  	table.insert(devices,dev.name)
    print("connected to "..dev.name)
    local m=midi.connect(dev.port)
    m.event=function(data)
      local d=midi.to_msg(data)
      print("midi mod: "..d.type)
    end
  end

  local param_names_dev={"mmfromch"}
  local param_names={"mmto","mmenabled"}
  local reload_parameters=function(v,ch)
	for i=1,#devices do
	  	for _,param_name in ipairs(param_names_dev) do
  			if i==v then 
  				params:show(i..param_name)
  			else
  				params:hide(i..param_name)
  			end
  		end
	  	for _,param_name in ipairs(param_names) do
  			for ch2=1,8 do
	  			if i==v and ch==ch2 then 
	  				params:show(i..ch..param_name)
	  			else
	  				params:hide(i..ch..param_name)
	  			end
	  		end
  		end
  	end
  end
  params:add_group("MIDIMOD",1+(#devices*17))
  params:add{type="option",id="mmfrom",name="from",options=devices,default=1,action=funciton(v)
  	reload_parameters(v,params:get(v.."mmfromch"))
  end}
  for i,device in ipairs(devices) do
  	  local other_devices={}
	  for i,other_device in ipairs(devices) do
	  	if i~=j then
	  		table.insert(other_devices,other_device)
	  	end
	  end
	  params:add{type="option",id=i.."mmfromch",name="channel",options={1,2,3,4,5,6,7,8},default=1,action=function(v)
	  	reload_parameters(i,v)
	  end}
	  for ch=1,8 do
		  params:add{type="option",id=i..ch.."mmto",name="to",options=other_devices,default=1}
		  params:add{type="option",id=i..ch.."mmenabled",name="enabled",options={"false,true"},default=1}
	   end
  end
  reload_parameters(1,1)
end





-- -- utility to clone function
-- local function clone_function(fn)
--   local dumped=string.dump(fn)
--   local cloned=load(dumped)
--   local i=1
--   while true do
--     local name=debug.getupvalue(fn,i)
--     if not name then
--       break
--     end
--     debug.upvaluejoin(cloned,i,fn,i)
--     i=i+1
--   end
--   return cloned
-- end

-- local function osc_in(path, args, from)
-- 	print("midipal osc from " .. from[1] .. " port " .. from[2])
-- end

-- mod.hook.register("script_pre_init", "midimod", function()
--   -- process incoming midi
--   for _,dev in pairs(midi.devices) do
--     print("connected to "..dev.name)
--     local m=midi.connect(dev.port)
--     m.event=function(data)
--       local d=midi.to_msg(data)
--       print("midi mod: "..d.type)
--     end
--   end

--   -- process incoming osc
--   if osc.event~=nil then
--   	-- clone ther current osc in
--   	osc.event2=clone_function(osc.event)
--   	osc.event=function(path, args, from)
--   		osc.event2(path,args,from)
--   		osc_in(path, args, from)
--   	end
--   else
--   	osc.event=function(path, args, from)
--   		osc_in(path, args, from)
--   	end
--   end


--   -- available engine commands
--   for k,v in ipairs(engine.commands) do
--   	print(v.name..' '..v.fmt)
--   end

--   -- available parameters
--   for k,v in params.params do 
--   	if v.id then 
--   		print(v.id)
--   	end
--   end

--   -- define clock to periodically send out current parameters
--   clock.run(function()
--   	while true do
--   		print("send out parameters")
--   		clock.sleep(1)
--   	end
--   end)
-- end)