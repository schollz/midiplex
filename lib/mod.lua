local mod = require 'core/mods'


-- utility to clone function
local function clone_function(fn)
  local dumped=string.dump(fn)
  local cloned=load(dumped)
  local i=1
  while true do
    local name=debug.getupvalue(fn,i)
    if not name then
      break
    end
    debug.upvaluejoin(cloned,i,fn,i)
    i=i+1
  end
  return cloned
end

local function osc_in(path, args, from)
	print("midipal osc from " .. from[1] .. " port " .. from[2])
end

mod.hook.register("script_post_init", "midimod", function()
  -- process incoming midi
  for _,dev in pairs(midi.devices) do
    print("connected to "..dev.name)
    local m=midi.connect(dev.port)
    m.event=function(data)
      local d=midi.to_msg(data)
      print("midi mod: "..d.type)
    end
  end

  -- process incoming osc
  if osc.event~=nil then
  	-- clone ther current osc in
  	osc.event2=clone_function(osc.event)
  	osc.event=function(path, args, from)
  		osc.event2(path,args,from)
  		osc_in(path, args, from)
  	end
  else
  	osc.event=function(path, args, from)
  		osc_in(path, args, from)
  	end
  end


  -- available engine commands
  for k,v in ipairs(engine.commands) do
  	print(v.name..' '..v.fmt)
  end

  -- available parameters
  for k,v in params.params do 
  	if v.id then 
  		print(v.id)
  	end
  end

  -- define clock to periodically send out current parameters
  clock.run(function()
  	while true do
  		print("send out parameters")
  		clock.sleep(1)
  	end
  end)
end)