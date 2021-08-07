local mod = require 'core/mods'

mod.hook.register("script_pre_init", "midimod", function()
    print("running midiplex")
  -- process incoming midi
  if #midi.devices<2 then
      do return end
  end
  local devices_other={}
    local devices={}
    local ms={}
  for i,dev in pairs(midi.devices) do
      table.insert(devices,dev.name)
    print("connected to "..dev.name)
    ms[i]=midi.connect(dev.port)
    ms[i].event=function(data)
      local d=midi.to_msg(data)
      if d.type=="note_on" then
          print(i,dev.name,d.type,d.ch)
          if params:get(i..d.ch.."mmenabled")==2 then
              local toch=params:get(i..d.ch.."mmtoch")
              local todevice=devices_other[i][params:get(i..d.ch.."mmto")]
              print("midi mod: "..d.type.." "..dev.name.." ch"..d.ch.."->"..devices[todevice].." ch"..toch)
              ms[todevice]:note_on(d.note,d.vel,toch)
          end
        elseif d.type=="note_off" then
          if params:get(i..d.ch.."mmenabled")==2 then
              local toch=params:get(i..d.ch.."mmtoch")
              local todevice=devices_other[i][params:get(i..d.ch.."mmto")]
              print("midi mod: "..d.type.." "..dev.name.." ch"..d.ch.."->"..devices[todevice].." ch"..toch)
              ms[todevice]:note_off(d.note,d.vel,toch)
          end
        end
    end
  end

  local param_names_dev={"mmfromch"}
  local param_names={"mmto","mmenabled","mmtoch"}
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
                      params:hide(i..ch2..param_name)
                  end
              end
          end
      end
       _menu.rebuild_params()
  end
  params:add_group("MIDIMOD",1+(#devices*(3*8+1)))
  params:add{type="option",id="mmfrom",name="from device",options=devices,default=1,action=function(v)
      reload_parameters(v,params:get(v.."mmfromch"))
  end}
  for i,device in ipairs(devices) do
      local other_devices_name={}
      local other_devices_idx={}
      for j,other_device in ipairs(devices) do
          if i~=j then
              table.insert(other_devices_name,other_device)
              table.insert(other_devices_idx,j)
          end
      end
      devices_other[i]=other_devices_idx
      params:add{type="option",id=i.."mmfromch",name="from channel",options={1,2,3,4,5,6,7,8},default=1,action=function(v)
          reload_parameters(i,v)
      end}
      for ch=1,8 do
          params:add{type="option",id=i..ch.."mmto",name="to device",options=other_devices_name,default=1}
          params:add{type="option",id=i..ch.."mmtoch",name="to channel",options={1,2,3,4,5,6,7,8},default=1}
          params:add{type="option",id=i..ch.."mmenabled",name="enabled",options={"false","true"},default=1}
       end
  end
  reload_parameters(1,1)
end)