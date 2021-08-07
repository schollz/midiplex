local mod=require 'core/mods'

mod.hook.register("script_pre_init","midimod",function()
  print("running midiplex")
  -- process incoming midi
  if #midi.devices<2 then
    do return end
  end
  local devices_other={}
  local devices={}
  local ms={}
  local i_=0
  for _,dev in pairs(midi.devices) do
    i_=i_+1
    local i=i_
    print("connected to "..dev.name)
    table.insert(devices,dev.name)
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
  local param_names={"mmenabled","mmto","mmtoch"}
  local param_names_crow={"mmenabledcrow","mmtocrow","crowa","crowd","crows"}
  local reload_parameters=function(v,ch)
    for i=1,#devices do
      for _,param_name in ipairs(param_names_dev) do
        if i==v then
          params:show(i..param_name)
        else
          params:hide(i..param_name)
        end
      end
      for pi,param_name in ipairs(param_names) do
        for ch2=1,8 do
          if i==v and ch==ch2 then
            params:show(i..ch..param_name)
            if pi>1 and params:get(i..ch..param_names[1])==1 then
              params:hide(i..ch..param_name)
            end
          else
            params:hide(i..ch2..param_name)
          end
        end
      end
    end
    _menu.rebuild_params()
  end
  params:add_group("MIDIPLEX",1+(#devices*(8*8+1)))
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
      params:add{type="option",id=i..ch.."mmenabled",name="midi thru",options={"disabled","enabled"},default=1,action=function(v)
        reload_parameters(i,params:get(i.."mmfromch"))
      end}
      params:add{type="option",id=i..ch.."mmto",name="to device",options=other_devices_name,default=1}
      params:add{type="option",id=i..ch.."mmtoch",name="to channel",options={1,2,3,4,5,6,7,8},default=1}
      params:add{type="option",id=i..ch.."mmenabledcrow",name="crow thru",options={"disabled","enabled"},default=1,action=function(v)
        reload_parameters(i,params:get(i.."mmfromch"))
      end}
      params:add{type="option",id=i..ch.."mmtocrow",name="to crow",options={1,3},default=1}
      params:add_control(i..ch.."crowa","attack",controlspec.new(0,10,"lin",0.01,0.1,"s",0.01/10))
      params:add_control(i..ch.."crows","sustain",controlspec.new(0,10,"lin",0.1,10,"v",0.1/10))
      params:add_control(i..ch.."crowd","decay",controlspec.new(0,10,"lin",0.01,0.5,"s",0.01/10))
    end
  end
  reload_parameters(1,1)
end
