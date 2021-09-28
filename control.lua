require("lib/lib")
stargate={}

-- todo; add remote interface


stargate.names={"stargate_sgu","stargate_sgc","stargate_atlantis"}
function stargate.GetGate(e)
	for k,v in pairs(global.stargates)do
		if(v.ent==e)then return v end
	end
end

function stargate.GetGateByCode(e)
	for k,v in pairs(global.stargates)do
		if(v.code==e)then return v end
	end
end

function stargate.UniqueCode()
	local code=""
	for i=1,5,1 do code=code..string.char(64+math.random(1,5)) end
	return code
end

stargate.GateSounds={}
for k,v in pairs{"sgc","atlantis","sgu"}do
	stargate.GateSounds["stargate_"..v]={
		["open"]="stargate_"..v.."_open",
		["shutdown"]="stargate_"..v.."_shutdown",
		["dial_fail"]="stargate_"..v.."_dial_fail",
		["chevron"]="stargate_"..v.."_chevron",
		["chevron_incoming"]="stargate_"..v.."_chevron_incoming",
		["roll"]="stargate_"..v.."_roll",
		["dhd"]="stargate_"..v.."_dhd",
		["dhd_cancel"]="stargate_"..v.."_dhd_cancel",
		["dhd_dial"]="stargate_"..v.."_dhd_dial",
		["dhd_roll"]="stargate_"..v.."_dhd_roll",
		["dhd_chevron"]="stargate_"..v.."_dhd_chevron",
	}
end
stargate.GateSounds.stargate_sgu.start_roll="stargate_sgu_start_roll"
--stargate.GateSounds.stargate_sgu.steam="stargate_sgu_steam"
stargate.GateSounds.stargate_sgu.dhd="stargate_atlantis_dhd"
stargate.GateSounds.stargate_sgu.open="stargate_sgc_open" -- doesn't line up with the puddle sprite

function stargate.play_gate_sound(gate,snd,ply)
	local n=gate.ent.name
	local st=stargate.GateSounds[n] if(not st[snd])then return end
	if(ply)then else gate.ent.surface.play_sound{path=st[snd],position=gate.ent.position,volume=0.25} end
end



function stargate.OnStargateBuilt(e,ev)
	if(stargate.GetGate(e))then return end
	if(e.surface.count_entities_filtered{position=e.position,name=stargate.names,radius=32}>1)then
		surfaces.EmitText(e.surface,e.position,"Too close to another Stargate")
		if(ev.player_index)then game.players[ev.player_index].mine_entity(e,true) else
			local itm=e.surface.create_entity{name="item-on-ground",position=e.position,stack={name=e.minable.result,count=1}} itm.order_deconstruction(e.force) e.destroy()
		end
		return
	end

	local idx=#global.stargates+1
	local t={ent=e,index=idx}
	t.outbelts={} t.inbelts={}
	t.name=game.backer_names[math.random(#game.backer_names)]
	t.code=stargate.UniqueCode()

	for k,v in pairs(global.stargates)do
		if(v.name==t.name)then t.name=""
			for i=1,7,1 do t.name=t.name .. string.char(math.random(65,90)) end
		end
	end
	global.stargates[idx]=t
	global.belts[e.surface.index]=global.belts[e.surface.index] or {}

	-- hook_positions()
	local square=vector.square(vector(e.position),vector(5,5))
	for x=square[1][1],square[2][1] do
		global.belts[e.surface.index][x]=global.belts[e.surface.index][x] or {}
		for y=square[1][2],square[2][2] do
			local edgex=(x==square[1][1] and 1 or (x==square[2][1] and -1 or false))
			local edgey=(y==square[1][2] and 1 or (y==square[2][2] and -1 or false))
			if( (edgex or edgey) and not (edgex and edgey) )then
				local belt={dir=0,gate=t}
				if(edgex==1)then belt.dir=2 elseif(edgex==-1)then belt.dir=6 elseif(edgey==1)then belt.dir=4 elseif(edgey==-1)then belt.dir=0 end
				belt.indir=belt.dir belt.outdir=(belt.dir+4)%8
				global.belts[e.surface.index][x][y]=belt
				local ef=e.surface.find_entities_filtered{position={x,y},radius=1,type="transport-belt"}
				for key,val in pairs(ef)do
					if(isvalid(val) and (val.direction==belt.dir or val.direction==belt.outdir))then stargate.CheckBelt(val) end
				end
			end
		end
	end

	return t
end
function stargate.OnStargateDestroy(e,ev)
	local v=stargate.GetGate(e)
	if(v)then

		local square=vector.square(vector(e.position),vector(5,5)) -- unhook belts

	for x=square[1][1],square[2][1] do
		if(global.belts[e.surface.index][x])then
			for y=square[1][2],square[2][2] do
				local edgex=(x==square[1][1] and 1 or (x==square[2][1] and -1 or false))
				local edgey=(y==square[1][2] and 1 or (y==square[2][2] and -1 or false))
				if( (edgex or edgey) and not (edgex and edgey) )then
					global.belts[e.surface.index][x][y]=nil
				end
			end
			if(table_size(global.belts[e.surface.index][x])==0)then
				global.belts[e.surface.index][x]=nil
			end
		end
	end
		if(table_size(global.belts[e.surface.index])==0)then
			global.belts[e.surface.index]=nil
		end

		if(v.isopen)then stargate.Shutdown(v) end global.stargates[v.index]=nil
		for k,x in pairs(global.players)do if(x==v)then stargate.CloseGui(game.players[k]) end end
	end
end

for _,sgName in pairs(stargate.names)do
cache.ent(sgName,{
create=function(e,ev)
	stargate.OnStargateBuilt(e,ev)
end,
destroy=function(e,ev)
	stargate.OnStargateDestroy(e,ev)
end,
mined=function(e,ev)
	stargate.OnStargateDestroy(e,ev)
end,
--[[died=function(e,ev)
	stargate.OnStargateDestroy(e,ev)
end,]]
clone=function(e,ev)
	local gate=stargate.GetGate(ev.source) if(not gate)then return end
	local newgate=stargate.OnStargateBuilt(ev.destination,ev)
	newgate.name=gate.name
	newgate.code=gate.code

	stargate.OnStargateDestroy(ev.source,ev)
end,
gui_opened=function(e,ev)
	local ply=game.players[ev.player_index]
	ply.opened=defines.gui_type.none
	local gate=stargate.GetGate(e)
	if(gate)then
	global.players[ply.index]=gate
	stargate.OpenMenu(ply,e,gate)
	end
end,

})
end

function stargate.OnDestroyBelt(e,ev)
	local f=e.surface
	local pos=e.position
	if(not global.belts[f.index])then return end
	if(not global.belts[f.index][pos.x])then return end
	if(not global.belts[f.index][pos.x][pos.y])then return end

	local belt=global.belts[f.index][pos.x][pos.y]
	local gate=belt.gate
	local vdir=(belt.direction==belt.outdir and 1 or (belt.direction==belt.indir and -1 or false))
	local vbelts=(vdir==1 and gate.outbelts or gate.inbelts)

	relpos=pos-vector(gate.ent.position)
	if(vbelts[relpos.x])then vbelts[relpos.x][relpos.y]=nil end

	--global.belts[f.index][pos.x][pos.y]=nil
	global.beltcache[e.unit_number]=nil
end

function stargate.CheckBelt(e)
	if(global.beltcache[e.unit_number])then stargate.OnDestroyBelt(e) end
	local f=e.surface
	local pos=vector(e.position)
	if(not global.belts[f.index])then return end
	if(not global.belts[f.index][pos.x])then return end
	if(not global.belts[f.index][pos.x][pos.y])then return end
	local belt=global.belts[f.index][pos.x][pos.y]
	if(not belt)then return end
	local vdir=(e.direction==belt.outdir and 1 or (e.direction==belt.indir and -1 or false))
	if(not vdir)then return end
	local gate=belt.gate

	relpos=pos-vector(gate.ent.position)
	local vbelts=(vdir==1 and gate.outbelts or gate.inbelts)
	vbelts[relpos.x]=vbelts[relpos.x] or {}
	vbelts[relpos.x][relpos.y]=e
	global.beltcache[e.unit_number]=e
end
cache.type("transport-belt",{
create=function(e)
	stargate.CheckBelt(e)
end,
rotate=function(e)
	stargate.CheckBelt(e)
end,
destroy=function(e)
	stargate.OnDestroyBelt(e)
end,
mined=function(e)
	stargate.OnDestroyBelt(e)
end,
})

function stargate.CheckDHD(e)
	--if(global.beltcache[e.unit_number])then stargate.OnDestroyDHD(e) end
	local f=e.surface
	local pos=vector(e.position)
	if(not global.belts[f.index])then return end
	if(not global.belts[f.index][pos.x])then return end
	if(not global.belts[f.index][pos.x][pos.y])then return end
	local belt=global.belts[f.index][pos.x][pos.y]
	local vdir=(e.direction==belt.outdir and 1 or (e.direction==belt.indir and -1 or false))
	if(not vdir)then return end
	local gate=belt.gate
	gate.dhd=e

	--global.beltcache[e.unit_number]=e
end
function stargate.OnDestroyDHD(e,ev)
	local f=e.surface
	local pos=e.position
	if(not global.belts[f.index])then return end
	if(not global.belts[f.index][pos.x])then return end
	if(not global.belts[f.index][pos.x][pos.y])then return end

	local belt=global.belts[f.index][pos.x][pos.y]
	local gate=belt.gate
	gate.dhd=nil

	--global.beltcache[e.unit_number]=nil
end
cache.ent("stargate-dhd",{
create=function(e)
	stargate.CheckDHD(e)
end,
rotate=function(e)
	stargate.CheckDHD(e)
end,
destroy=function(e)
	stargate.OnDestroyDHD(e)
end,
mined=function(e)
	stargate.OnDestroyDHD(e)
end,
})


function stargate.BeltLogistics()
	for idx,gate in pairs(global.stargates)do if(gate.isopen and not gate.dialing and gate.ent.name~="stargate_sgu")then local vgate=global.stargates[gate.isopen]
		for x,xtbl in pairs(gate.inbelts)do for y,belt in pairs(xtbl)do if(isvalid(belt))then local ax,ay=math.abs(x),math.abs(y)
			local inver=(settings.global.stargate_flip_belts.value and -1 or 1) local inverx=x*(ax>ay and inver or 1) local invery=y*(ay>ax and inver or 1)
			if(vgate.outbelts[inverx] and vgate.outbelts[inverx][invery] and isvalid(vgate.outbelts[inverx][invery]))then
				local vbelt=vgate.outbelts[inverx][invery] if(vbelt.get_max_transport_line_index()==belt.get_max_transport_line_index())then
					for i=1,belt.get_max_transport_line_index(),1 do local line=belt.get_transport_line(i) local oline=vbelt.get_transport_line(i)
						for key,val in pairs(line.get_contents())do if(not oline.can_insert_at_back())then break end
							oline.insert_at_back{name=key,count=1} line.remove_item{name=key,count=1}

							--[[ this drove me mad after about 5 minutes
							if((gate.next_sound or 0)<=game.tick and (vgate.next_sound or 0)<=game.tick)then
								gate.next_sound=game.tick+math.random(5,15)
								vgate.next_sound=game.tick+math.random(5,15)
								gate.ent.surface.play_sound{path="stargate_teleport",position=gate.ent.position,volume=0.25}
								vgate.ent.surface.play_sound{path="stargate_teleport",position=vgate.ent.position,volume=0.25}
							end
							]]
						end
					end
				end
			end
		end end end
	end end
end
events.on_tick(1,0,"logibelt",stargate.BeltLogistics)


stargate.CombinatorLogic={}
function stargate.CombinatorLogic.stargate_sgc(gate,tick)
	local red=gate.dhd.get_merged_signal({type="virtual",name="signal-red"})
	if(red>0)then
		if(gate.isopen)then stargate.Shutdown(gate) end
		gate.dht=nil
	elseif(not gate.isopen and not gate.dialing)then gate.dht=gate.dht or {}
		local dbg=(gate.dhd.get_merged_signal({type="virtual",name="signal-Z"}))>0
		if(gate.dht.rolllock and gate.dht.rolllock<game.tick and (gate.dht.input or 0)<game.tick)then gate.dht.rolllock=nil
			stargate.play_gate_sound(gate,"dhd_chevron") --gate.ent.surface.play_sound{path="stargate_chevron",position=gate.ent.position,volume=0.25}
		end
		if(gate.dht.rolling and gate.dht.rolling<game.tick and (gate.dht.input or 0)<game.tick)then gate.dht.rolling=nil end
		local od=gate.dhd.get_merged_signal({type="virtual",name="signal-green"})
		if(od>0 and not gate.dht.open_dial)then
			if(dbg)then game.print("Stargate Chevron Ring released") end
			gate.dht.open_dial=true
			stargate.play_gate_sound(gate,"dhd_dial") --gate.ent.surface.play_sound{path="stargate_chevron",position=gate.ent.position,volume=0.25}
		elseif(gate.dht.open_dial)then
			if(od==0)then
				if((gate.dht.input or 0)<game.tick)then
					local chevrons={} for i,e in pairs(stargate.Chevrons)do chevrons[e]=gate.dhd.get_merged_signal({type="virtual",name="signal-"..e}) end
					local c,x=0 for i,e in pairs(chevrons)do if(e>0)then c=c+1 x=i end end
					if(c==1)then
						gate.dht.chevrons=gate.dht.chevrons or {}
						table.insert(gate.dht.chevrons,x)
						if(dbg)then game.print("Stargate Chevron Locked: "..x) end
	
					if(table_size(gate.dht.chevrons)>5)then
							gate.dht=nil
							stargate.play_gate_sound(gate,"dial_fail") --gate.ent.surface.play_sound{path="stargate_dial_fail",position=gate.ent.position,volume=0.25}
							--game.print("failed due to too many chevrons")
							if(dbg)then game.print("Stargate Signal-Dialing Failed: Gate received too many chevrons (needs 5, got 6)") end
						elseif((gate.dht.input or 0)<game.tick and (gate.dht.rolling or 0)>game.tick)then
							gate.dht=nil
							stargate.play_gate_sound(gate,"dial_fail") --gate.ent.surface.play_sound{path="stargate_dial_fail",position=gate.ent.position,volume=0.25}
							if(dbg)then game.print("Stargate Signal-Dialing Failed: Entering next chevron too fast (needs 260tick delay)") end
						else
							gate.dht.rolling=game.tick+(180+80) --3*60
							gate.dht.rolllock=game.tick+180
							gate.dht.input=game.tick+10
							stargate.play_gate_sound(gate,"dhd_roll") --gate.ent.surface.play_sound{path="stargate_gate_roll",position=gate.ent.position,volume=0.25}
						end
								
					elseif(c>1)then
						gate.dht=nil
						stargate.play_gate_sound(gate,"dial_fail") --gate.ent.surface.play_sound{path="stargate_dial_fail",position=gate.ent.position,volume=0.25}
						if(dbg)then game.print("Stargate Signal-Dialing Failed: input more than one chevron at once") end
					end
				end
			elseif(gate.dht.chevrons and table_size(gate.dht.chevrons)==5)then
				local s="" for k,v in ipairs(gate.dht.chevrons)do s=s..v end
				local vgate=stargate.GetGateByCode(s)
				if(not vgate)then
					gate.dht=nil
					stargate.play_gate_sound(gate,"dial_fail") --gate.ent.surface.play_sound{path="stargate_dial_fail",position=gate.ent.position,volume=0.25}
					if(dbg)then game.print("Stargate Signal-Dialing Failed: Could not find target Stargate") end
				elseif(vgate and (vgate.isopen or vgate.dialing))then
					gate.dht=nil
					stargate.play_gate_sound(gate,"dial_fail") --gate.ent.surface.play_sound{path="stargate_dial_fail",position=gate.ent.position,volume=0.25}
					if(dbg)then game.print("Stargate Signal-Dialing Failed: Destination Gate is already open") end
				else
					gate.dht.start_dial=game.tick+180
					stargate.OpenGate(gate,vgate)
					gate.dht=nil
				end
			end
		end
	end
end


stargate.fastdial_fail_time=60*4
function stargate.CombinatorLogic.stargate_atlantis(gate,tick)
	local GetSignal=gate.dhd.get_merged_signal
	if((gate.dial_fail or 0)>game.tick)then return end

	local red=(GetSignal{type="virtual",name="signal-red"})>0
	if(red)then if(gate.isopen)then stargate.Shutdown(gate) end gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
	elseif(not gate.isopen and not gate.dialing)then local dht=gate.dht
		local dbg=(GetSignal{type="virtual",name="signal-Z"})>0
		local green=(GetSignal{type="virtual",name="signal-green"})>0
		if(gate.dht and not gate.dht.fastdial)then gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time return end
		if(not dht or not dht.open_dial)then
			if(green)then
				gate.dht=gate.dht or {fastdial=true,open_dial=true,open_tick=game.tick+4} dht=gate.dht
				if(dbg)then game.print("Stargate Chevron Ring released") end
				stargate.play_gate_sound(gate,"dhd_dial")

				local ticks={} local tv=0 gate.dht.ticks=ticks gate.dht.tick=1
				local cb=gate.dhd.get_or_create_control_behavior()
				for i=1,6,1 do local rng=math.random(5,10) tv=tv+rng ticks[i]={tick=game.tick+tv,rng=rng} cb.set_signal(i,{signal={type="virtual",name="signal-"..i},count=rng}) end
			end
		else
			if(dht.open_tick<game.tick)then if(not dht.close_combo)then dht.close_combo=true
					local cb=gate.dhd.get_or_create_control_behavior()
					for i=1,6,1 do cb.set_signal(i,{signal={type="virtual",name="signal-"..i},count=0}) end
			end end
			if(dht.tick<6)then
				local tv=dht.ticks[dht.tick]
				local chevrons={} for i,e in pairs(stargate.Chevrons)do chevrons[e]=gate.dhd.get_merged_signal({type="virtual",name="signal-"..e}) end
				local c,x=0 for i,e in pairs(chevrons)do if(e>0)then c=c+1 x=i end end
				if(game.tick==dht.ticks[dht.tick].tick)then dht.tick=dht.tick+1
					if(green)then
						gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
						stargate.play_gate_sound(gate,"dial_fail")
						if(dbg)then game.print("Stargate Signal-Dialing Failed: Unstable Dial Tone") end
					elseif(c==1)then
						gate.dht.chevrons=gate.dht.chevrons or {}
						table.insert(gate.dht.chevrons,x)
						if(dbg)then game.print("Stargate Chevron Locked: "..x) end
					elseif(c>1)then
						gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
						stargate.play_gate_sound(gate,"dial_fail")
						if(dbg)then game.print("Stargate Signal-Dialing Failed: input more than one chevron at once") end
					else
						gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
						stargate.play_gate_sound(gate,"dial_fail")
						if(dbg)then game.print("Stargate Signal-Dialing Failed: No chevron input") end
					end
				elseif(c>0)then
					gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
					stargate.play_gate_sound(gate,"dial_fail")
					if(dbg)then game.print("Stargate Signal-Dialing Failed: Chevron input not timed correctly") end
				end

			elseif(dht.tick==6)then
				if(green and game.tick~=dht.ticks[dht.tick])then
					gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
					stargate.play_gate_sound(gate,"dial_fail")
					if(dbg)then game.print("Stargate Signal-Dialing Failed: Dial Tone not timed correctly") end
				elseif(green and game.tick==dht.ticks[dht.tick])then
					local s="" for k,v in ipairs(gate.dht.chevrons)do s=s..v end
					local vgate=stargate.GetGateByCode(s)
					if(not vgate)then
						gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
						stargate.play_gate_sound(gate,"dial_fail")
						if(dbg)then game.print("Stargate Signal-Dialing Failed: Could not find target Stargate") end
					elseif(vgate and (vgate.isopen or vgate.dialing))then
						gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
						stargate.play_gate_sound(gate,"dial_fail")
						if(dbg)then game.print("Stargate Signal-Dialing Failed: Destination Gate is already open") end
					else
						--gate.dht.start_dial=game.tick+180
						stargate.OpenGate(gate,vgate)
						gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
					end
				elseif(game.tick > dht.ticks[dht.tick].tick)then
					gate.dht=nil gate.dial_fail=game.tick+stargate.fastdial_fail_time
					stargate.play_gate_sound(gate,"dial_fail")
					if(dbg)then game.print("Stargate Signal-Dialing Failed: No Dial Tone input") end
				end
			end
		end
	end
end

function stargate.CodeToNumber(code)
	local nums={A=0,B=0,C=0,D=0,E=0}
	for i=1,5,1 do local s=code:sub(i,i) nums[s]=nums[s]+(2^i) end
	return nums
end
function stargate.NumberToCode(nums)
	local codes={}
	local code=""
	for key,n in pairs(nums)do local vn=n for i=5,1,-1 do if(vn>=(2^i))then codes[i]=key vn=vn-(2^i) end end end
	game.print(serpent.block(codes))
	for i=1,5,1 do code=code..codes[i] end
	return code
end

stargate.Chevrons={"A","B","C","D","E"}
function stargate.DHDTick(tick)
	for idx,gate in pairs(global.stargates)do
		if(gate.dhd)then
			if(stargate.CombinatorLogic[gate.ent.name])then stargate.CombinatorLogic[gate.ent.name](gate,tick) else stargate.CombinatorLogic.stargate_sgc(gate,tick) end
		end
	end
end
events.on_tick(1,0,"dhd",stargate.DHDTick)

events.on_event(defines.events.on_pre_surface_deleted,function(ev)
	if(global.belts[ev.surface_index])then global.belts[ev.surface_index]=nil end
	for k,v in pairs(global.stargates)do
		if(not isvalid(v.ent))then global.stargates[k]=nil
		elseif(v.ent.surface.index==ev.surface_index)then
			stargate.OnStargateDestroy(v.ent,ev)
			v.ent.destroy()
		end
	end
	for k,v in pairs(game.surfaces[ev.surface_index].find_entities_filtered{type="transport-belt"})do v.destroy{raise_destroy=true} end
end)

events.on_init(function()
	global.stargates={} global.players={} global.tprecent={}
	global.menus={}
	global.belts={}
	global.beltcache={}
	global.sensors={}
	global.sensorgates={}
end)


events.on_config(function(ev)
	global.stargates=global.stargates or {}
	for k,v in pairs(global.stargates)do v.inbelts=v.inbelts or {} v.outbelts=v.outbelts or {} if(not v.code)then v.code=stargate.UniqueCode() end end
	global.players=global.players or {}
	global.tprecent=global.tprecent or {}
	global.menus=global.menus or {}
	global.belts=global.belts or {}
	global.beltcache=global.beltcache or {}
	global.sensors=global.sensors or {}
	global.sensorgates=global.sensorgates or {}
end)

events.on_load(function()
	if(global.stargates)then for k,v in pairs(global.stargates)do stargate.LoadSprites(v) end end -- Reset sprites

end)

local guis={}
guis.stargate_dial={}
function guis.stargate_dial.click(ev)
	local menu=global.menus[ev.player_index]
	if(menu and menu.gate)then
		stargate.play_gate_sound(menu.gate,"dhd_dial") --menu.gate.ent.surface.play_sound{path="stargate_chevron_lock_dhd",menu.gate.ent.position}

		local code=menu.dialcode if(code and #code==5)then
			local tgate
			for k,v in pairs(global.stargates)do
				if(v.ent~=menu.gate.ent)then
					local good=true for i=1,5,1 do if(v.code:sub(i,i)~=code[i])then good=false break end end
					if(good)then tgate=v break end
				end
			end
			if(tgate)then
				stargate.OpenGate(menu.gate,tgate)
			else
				stargate.play_gate_sound(menu.gate,"dial_fail") --menu.gate.ent.surface.play_sound{path="stargate_dial_fail",position=menu.gate.ent.position}
			end
		end
	end
	stargate.CloseGui(game.players[ev.player_index],ev)

end
guis.stargate_close={}
function guis.stargate_close.click(ev)
	stargate.CloseGui(game.players[ev.player_index],ev)
end
guis.stargate_save={}
function guis.stargate_save.click(ev)
	local ply=game.players[ev.player_index]
	local g=ply.gui.screen.stargate_frame if(not g)then return end
	g=g.stargate_canvas if(not g)then return end
	g=g.stargate_nmflow if(not g)then return end
	g=g.stargate_name if(not g)then return end
	local txt=g.text if(not txt or txt=="")then return end
	local gate=global.players[ev.player_index] if(not gate)then return end
	gate.name=txt
end

guis.stargate_shutdown={}
function guis.stargate_shutdown.click(ev)
	local gate=global.players[ev.player_index]
	if(gate)then
		stargate.Shutdown(gate)
	end
	stargate.CloseGui(game.players[ev.player_index],ev)
end


guis.stargate_rename={}
function guis.stargate_rename.click(ev)
	local ply=game.players[ev.player_index]
	local em=ev.element
	local menu=global.menus[ply.index]
	local gate=menu.gate
	if(menu.rntxt.visible)then -- update name
		local val=menu.rntxt.text
		if(val~="")then menu.gate.name=val else menu.rntxt.text=menu.gate.name end
		menu.title.caption=menu.rntxt.text
	end
	menu.rntxt.visible=not menu.rntxt.visible
	menu.title.visible=not menu.rntxt.visible
end

guis.stargate_search_btn={}
function guis.stargate_search_btn.click(ev)
	local ply=game.players[ev.player_index]
	local em=ev.element
	local menu=global.menus[ply.index]
	if(menu.searchbox.visible)then -- Disable searching
	end
	menu.searchbox.visible=not menu.searchbox.visible
end

guis.stargate_cancelbtn={}
function guis.stargate_cancelbtn.click(ev)
	stargate.CloseGui(game.players[ev.player_index],ev)
end

guis.stargate_search_txt={}
function guis.stargate_search_txt.text_changed(ev)
	local ply=game.players[ev.player_index]
	local em=ev.element
	local menu=global.menus[ply.index]
	stargate.PopulateGrid(ply,menu,em.text)
	
end

function stargate.UpdateMenuDialcode(ply,menu,code)
	menu.dialcode=menu.dialcode or {}
	if(code and #menu.dialcode<5)then table.insert(menu.dialcode,code) end
	local str="" for i=1,5,1 do str=str..(menu.dialcode[i] or "_") if(i<5)then str=str.." " end end
	menu.dialtext.caption=str
	stargate.PopulateGrid(ply,menu,menu.searchbox.text)
	if(code)then
		stargate.play_gate_sound(stargate.GetGate(menu.ent),"dhd") --menu.gate.ent.surface.play_sound{path="stargate_dhd",menu.ent.position}
	else
		stargate.play_gate_sound(stargate.GetGate(menu.ent),"dhd_cancel") --menu.gate.ent.surface.play_sound{path="stargate_chevron",menu.ent.position}
	end
end

guis.stargate_dialz={} function guis.stargate_dialz.click(ev) local ply=game.players[ev.player_index] local em=ev.element local menu=global.menus[ev.player_index]
	menu.dialcode={}
	stargate.UpdateMenuDialcode(ply,menu)
end

--[[
cache.vptrn("stargate_key_",{
	click=function(em,ev) local key=em.name:sub(-1) stargate.UpdateMenuDialcode(game.players[ev.player_index],global.menus[ev.player_index],key) end
})

]]

guis.stargate_key_A={} function guis.stargate_key_A.click(ev) local ply=game.players[ev.player_index] local em=ev.element local menu=global.menus[ev.player_index]
	stargate.UpdateMenuDialcode(ply,menu,"A")
end
guis.stargate_key_B={} function guis.stargate_key_B.click(ev) local ply=game.players[ev.player_index] local em=ev.element local menu=global.menus[ev.player_index]
	stargate.UpdateMenuDialcode(ply,menu,"B")
end
guis.stargate_key_C={} function guis.stargate_key_C.click(ev) local ply=game.players[ev.player_index] local em=ev.element local menu=global.menus[ev.player_index]
	stargate.UpdateMenuDialcode(ply,menu,"C")
end
guis.stargate_key_D={} function guis.stargate_key_D.click(ev) local ply=game.players[ev.player_index] local em=ev.element local menu=global.menus[ev.player_index]
	stargate.UpdateMenuDialcode(ply,menu,"D")
end
guis.stargate_key_E={} function guis.stargate_key_E.click(ev) local ply=game.players[ev.player_index] local em=ev.element local menu=global.menus[ev.player_index]
	stargate.UpdateMenuDialcode(ply,menu,"E")
end


guis.stargate_dial_buttons={}
function guis.stargate_dial_buttons.click(ev)
	local ply=game.players[ev.player_index]
	local em=ev.element
	local menu=global.menus[ply.index]
	local gate=menu.gate

	if(not gate or gate.isopen)then return end
	local evn=ev.element.name
	local tgt=tonumber(evn:sub((evn:len()-("stargate_lb_"):len())*-1))

	local tgate=global.stargates[tgt]
	if(not tgate or tgate.isopen)then
		stargate.play_gate_sound(menu.gate,"dial_fail")  --game.print("Unable to connect stargates")
		return
	end

	stargate.OpenGate(gate,tgate)

	stargate.CloseGui(game.players[ev.player_index],ev)
end

events.on_event(defines.events.on_gui_click,function(ev)
	local nm=ev.element.name local g=guis[nm] if(nm:find("stargate_lb_"))then g=guis["stargate_dial_buttons"] end
	if(g and g.click)then g.click(ev) end

end)

events.on_event(defines.events.on_gui_selection_state_changed,function(ev) local nm=ev.element.name local g=guis[nm] if(g and g.selection_changed)then g.selection_changed(ev) end end)
events.on_event(defines.events.on_gui_text_changed,function(ev) local nm=ev.element.name local g=guis[nm] if(g and g.text_changed)then g.text_changed(ev) end end)
events.on_event(defines.events.on_gui_confirmed,function(ev) local nm=ev.element.name local g=guis[nm] if(g and g.confirmed)then g.confirmed(ev) end end)

events.on_event(defines.events.on_entity_damaged,function(ev) if(table.HasValue(stargate.names,ev.entity.name))then local gate=stargate.GetGate(ev.entity)
	if(gate and gate.isopen and math.random(1,4)==1)then
		gate.ent.surface.play_sound{path="stargate_damaged",position=gate.ent.position}
		local vg=global.stargates[gate.isopen]
		vg.ent.surface.play_sound{path="stargate_damaged",position=vg.ent.position}
	end
end end)
events.on_event(defines.events.on_gui_closed,function(ev) if(global.players[ev.player_index])then stargate.CloseGui(game.players[ev.player_index]) end end)

-- defines.events.on_player_display_scale_changed defines.events.on_player_display_resolution_changed
--[[
  [defines.events.on_chart_tag_modified] = on_chart_tag_modified,
  [defines.events.on_chart_tag_removed] = on_chart_tag_removed,
  [defines.events.on_chart_tag_added] = on_chart_tag_added,
  [defines.events.on_trigger_created_entity] = on_trigger_created_entity,
]]

function stargate.OpenRenameMenu(ply,gate)
	
end

stargate.MenuSize=100
stargate.MenuFrameSize=400

function stargate.PopulateGrid(ply,menu,search) local gate=menu.gate local dcode=menu.dialcode
	local g=menu.grid
	g.clear()
	local z=stargate.MenuSize
	local pos=gate.ent.position
	local area=vector.square(pos,vector(stargate.MenuSize,stargate.MenuSize))
	ply.force.chart(gate.ent.surface,area) -- make the camera visible
	local gates={}
	for k,v in pairs(global.stargates)do
		if(v and isvalid(v.ent))then
			local hascode=true
			if(#dcode~=0)then for i=1,#dcode,1 do if(v.code:sub(i,i)~=dcode[i])then hascode=false break end end end
			if(hascode and (not search or (search and v.name:lower():find(search:lower(),1,true))) and not v.isopen)then gates[v.index]=v.name end
		end
	end
	local has=false
	local zSize=stargate.MenuFrameSize+stargate.MenuSize-24
	for k,n in StringPairs(gates)do local v=global.stargates[k] -- make clickable dial button with camera
		if(k~=gate.index)then has=true
			local btn={}
			btn.frame=g.add{type="button",name="stargate_lb_" .. v.index}
			btn.frame.style.height=stargate.MenuSize+8 --+32+8
			btn.frame.style.natural_width=zSize
			btn.frame.style.horizontally_squashable=true
			btn.frame.style.horizontally_stretchable=true
			btn.frame.style.minimal_width=200
			btn.frame.style.left_padding=0 g.style.right_padding=0


			btn.flow=btn.frame.add{type="flow",direction="horizontal",ignored_by_interaction=true}

			btn.codeflow=btn.flow.add{type="flow",direction="vertical",ignored_by_interaction=true}
			btn.codeflow.style.vertical_align="center"
			btn.codeflow.style.natural_width=zSize-stargate.MenuSize+24+2+20
			btn.codeflow.style.horizontally_squashable=true
			btn.codeflow.style.horizontally_stretchable=true

			btn.lbl=btn.codeflow.add{type="label",caption=v.name}
			btn.lbl.style.horizontally_stretchable=true
			btn.lbl.style.font="default-dialog-button"
			btn.lbl.style.font_color={r=1,g=1,b=1,a=1}
			btn.lbl.style.maximal_width=zSize
			btn.lbl.style.natural_width=zSize-stargate.MenuSize
			btn.lbl.style.horizontal_align="center"
			btn.lbl.style.left_margin=2

			btn.code=btn.codeflow.add{type="label",ignored_by_interaction=true}
			btn.code.style.vertical_align="center"
			btn.code.style.font="stargate_sg1_glyphs"
			btn.code.style.font_color={r=0,g=0,b=0,a=1}
			btn.code.style.left_margin=4
			local s=""
			for i=1,v.code:len(),1 do s=s..v.code:sub(i,i) if(i<v.code:len())then s=s.." " end end
			btn.code.caption=s

			btn.minimap=btn.flow.add{type="flow",direction="vertical",ignored_by_interaction=true}
			btn.minimap.style.horizontal_align="center"
			btn.minimap.style.left_margin=20

			btn.map=btn.minimap.add{type="minimap",surface_index=v.ent.surface.index,zoom=2,force=v.ent.force.name,position=v.ent.position,ignored_by_interaction=true}
			btn.map.style.height=stargate.MenuSize btn.map.style.width=stargate.MenuSize
			btn.map.style.horizontally_stretchable=true btn.map.style.vertically_stretchable=true



		end
	end
	if(not has)then menu.grid.add{type="label",caption="Nothing Found"} end
end
function stargate.OpenMenu(ply,e,gate)

	local menu={}
	menu.gate=gate
	menu.ply=ply
	menu.ent=e
	if(isvalid(ply.gui.screen.stargate_frame))then stargate.CloseGui(ply) end

	local fx=ply.gui.screen.stargate_frame or ply.gui.screen.add{name="stargate_frame",type="frame",direction="vertical",ignored_by_interaction=false}
	local z=stargate.MenuSize

	fx.auto_center=true
	fx.style.minimal_width=400
	menu.frame=fx

	-- util.register_gui

	if(not gate.isopen)then
		local fflow=menu.frame.stargate_nmflow or menu.frame.add{name="stargate_nmflow",type="flow",direction="horizontal"}
		fflow.style.vertical_align="center"
		menu.toolbar=fflow
		menu.title=fflow.add{name="stargate_title",type="label",style="heading_1_label",drag_target=menu.frame,caption=gate.name,drag_target=menu.frame}
		menu.rntxt=fflow.add{name="stargate_rename_txt",type="textfield",visible=false,text=gate.name}
		menu.rename=fflow.add{name="stargate_rename",type="sprite-button",sprite="utility/rename_icon_small_black",style="tool_button",visible=(e.force==ply.force)} --small_slot_button

		menu.dragbar=fflow.add{type="empty-widget",direction="horizontal",style="draggable_space_header"}
		menu.dragbar.drag_target=menu.frame
		menu.dragbar.style.horizontally_stretchable=true menu.dragbar.style.vertically_stretchable=true

		menu.searchbox=fflow.add{name="stargate_search_txt",type="textfield",visible=false}
		menu.searchbtn=fflow.add{name="stargate_search_btn",type="sprite-button",style="tool_button",sprite="utility/search_icon",tooltip={"gui.search-with-focus",{"search"}}}

		menu.canvas=menu.frame.stargate_canvas or menu.frame.add{name="stargate_canvas",type="flow",direction="vertical"}

		menu.dialflow=menu.canvas.add{type="flow",direction="horizontal"}
		menu.dialflow.style.horizontal_align="center"
		menu.dialtext=menu.dialflow.add{type="label",name="stargate_diallabel",caption="_ _ _ _ _"}
		menu.dialtext.style.font="stargate_sg1_glyphs"
		menu.dialcode={}


		menu.dialflow.style.vertical_align="center"

		menu.dialz=menu.dialflow.stargate_dialz or menu.dialflow.add{name="stargate_dialz",type="button",caption="Clear"}
		menu.dialz.style.horizontally_stretchable=true
		menu.dialz.style.horizontally_squashable=true
		menu.dialz.style.natural_width=25
		menu.dialz.style.left_margin=10

		menu.dial=menu.dialflow.stargate_dial or menu.dialflow.add{name="stargate_dial",type="button",caption="Dial",style="confirm_button"}
		menu.dial.style.horizontally_stretchable=true
		menu.dial.style.horizontally_squashable=true
		menu.dial.style.natural_width=100
		menu.dial.style.left_margin=0
		menu.dial.style.natural_height=menu.dialz.style.natural_height
		menu.dial.style.minimal_height=menu.dialz.style.minimal_height
		menu.dial.style.height=28

		menu.gatekeyflow=menu.canvas.add{type="flow",direction="horizontal"}
		menu.gatekeyflow.style.vertical_align="center"
		menu.btns={}
		for i=1,5,1 do local key=menu.gatekeyflow.add{name="stargate_key_"..string.char(64+i),type="button",caption=string.char(64+i)} key.style.font="stargate_sg1_glyphs" end


		--[[menu.dialtext=menu.canvas.add{type="label",name="stargate_diallabel1",caption="abcdefghijklmnopqrstuvwxyz"}
		menu.dialtext.style.font="stargate_sg1_glyphs"
		menu.dialtext=menu.canvas.add{type="label",name="stargate_diallabel2",caption="ABCDEFGHIJKLMNOPQRSTUVWXYZ"}
		menu.dialtext.style.font="stargate_sg1_glyphs"]]

		menu.body=menu.canvas.add{name="stargate_body",type="frame",style="inside_deep_frame"}
		menu.scroll=menu.body.add{name="stargate_scroll",type="scroll-pane",direction="vertical"}
		menu.scroll.style.maximal_height=ply.display_resolution.height*0.5

		menu.grid=menu.scroll.add{name="stargate_grid",type="table",column_count=1}
		menu.grid.style.horizontal_spacing=4 menu.grid.style.vertical_spacing=4
		stargate.PopulateGrid(ply,menu)


		--[[local txt=fflow.stargate_nmlbl or fflow.add{name="stargate_nmlbl",type="label",caption="This Gate    "}
		local txt=fflow.stargate_name or fflow.add{name="stargate_name",type="textfield",text=gate.name}
		local txt=fflow.stargate_save or fflow.add{name="stargate_save",type="button",caption="Save"} --,style="confirm_button"}
		]]

		--[[local fflow=f.stargate_flow or f.add{name="stargate_flow",type="flow",direction="horizontal"}
		local txt=fflow.stargate_nmlbl or fflow.add{name="stargate_nmlbl",type="label",caption="Destination"}
		local txt=fflow.stargate_number or fflow.add{name="stargate_number",type="textfield"}

		]]

		--[[
		local fsc=f.stargate_dialsc or f.add{name="stargate_dialsc",type="scroll-pane",vertical_scroll_policy="always",style="featured_technology_description_scroll_pane"}
		local fflow=fsc.stargate_dialflow or fsc.add{name="stargate_dialflow",type="flow",direction="vertical"}
		for k,v in pairs(global.stargates)do if(v.ent~=e)then
			fflow.add{name="stargate_lb_"..v.index,type="button",caption=v.name}
		end end
		]]

	else

		fx.caption=gate.name
		local fflow=fx.stargate_shflow or fx.add{name="stargate_shflow",type="flow",direction="horizontal"}
		local txt=fflow.stargate_cancelbtn or fflow.add{name="stargate_cancelbtn",type="button",
			caption="Cancel"
		}
		local txt=fflow.stargate_shutdown or fflow.add{name="stargate_shutdown",type="button",style="red_button",
			caption="                                Shutdown                                "
		}

	end

	--local fflow=f.stargate_dialflow or f.add{name="stargate_dialflow",type="flow",direction="vertical"}
	--local txt=fflow.stargate_close or fflow.add{name="stargate_close",type="button",caption="                                                       Close                                                       "}--,style="red_back_button"}

	ply.opened=menu.frame
	global.menus[ply.index]=menu
end
function stargate.CloseGui(ply)
	local fx=ply.gui.screen.stargate_frame
	if(fx)then fx.destroy() global.players[ply.index]=nil global.menus[ply.index]=nil end
end



stargate.teleDir={[0]={0,-1},[1]={1,-1},[2]={1,0},[3]={1,1},[4]={0,1},[5]={-1,1},[6]={-1,0},[7]={-1,-1}}

function stargate.TeleportLogic(ply,e,tent)
	local w=ply.walking_state
	local ox=tent.position
	local x=e.position
	local mp=2 if(not ply.character)then mp=3 end
	if(not w.walking)then local cp=ply.position local xd,yd=(x.x-cp.x),(x.y-cp.y) entity.safeteleport(ply,tent.surface,vector(ox.x+xd*mp,ox.y+yd*mp))
	else local td=stargate.teleDir[w.direction] entity.safeteleport(ply,tent.surface,vector(ox.x+td[1]*mp,ox.y+td[2]*mp)) end
	players.playsound("stargate_teleport",e.surface,e.position) players.playsound("stargate_teleport",tent.surface,tent.position)
end


events.on_event(defines.events.on_player_changed_position,function(ev) local ply=game.players[ev.player_index] if(not ply.driving)then
	if((global.tprecent[ev.player_index] or 0)>game.tick)then return end
	local f=ply.surface
	-- perhaps i can just check floored positions against the belt table ???

	local ents=f.find_entities_filtered{area=vector.square(ply.position,vector(2,2)),name=stargate.names}
	for k,v in pairs(ents)do
		if(table.HasValue(stargate.names,v.name))then
			local gate=stargate.GetGate(v)
			if(gate and gate.isopen and not gate.dialing)then
				global.tprecent[ev.player_index]=game.tick+10 local tgate=global.stargates[gate.isopen].ent
				stargate.TeleportLogic(ply,v,tgate)
				v.surface.play_sound{path="stargate_teleport",position=v.position}
				tgate.surface.play_sound{path="stargate_teleport",position=tgate.position}
				
			end
		end
	end
end end)

--[[ Todo landmine teleporter

function stargate.DoTeleport(ply,gate,tgate) if(not ply.driving)then
	if((global.tprecent[ply.index] or 0)>game.tick)then return end
	if(gate and gate.isopen)then
		global.tprecent[ply.index]=game.tick+30
		stargate.TeleportLogic(ply,gate.ent,global.stargates[gate.isopen].ent)
	end
end end

--events.on_event(defines.events.on_player_changed_position,function(ev) end)

events.on_event(defines.events.on_trigger_created_entity,function(ev)
	local e=ev.entity game.print("sticker " .. e.name) if(isvalid(e))then if(e.name=="stargate-sensor_sticker")then game.print("sticky")
		local tgt=e.sticked_to if(isvalid(tgt))then
	local gate=global.sensors[ev.source.unit_number]
	if(gate and gate.isopen)then game.print("mine-teleport") stargate.DoTeleport(tgt.player,gate,global.stargates[gate.isopen]) end
end end end end)

]]

events.on_tick(1,0,"gate_puddles",function() global.tick=game.tick
	for k,v in pairs(global.stargates)do
		if(v.sprite and rendering.is_valid(v.sprite))then
			rendering.set_orientation(v.sprite,(rendering.get_orientation(v.sprite)+(v.spritedir or 0.001))%1)
			rendering.set_x_scale(v.sprite,0.825+(0.5-math.sin((v.spritescale or 0.1)))*0.05)
			rendering.set_y_scale(v.sprite,0.825+(0.5-math.sin((v.spritescale or 0.1)))*0.05)
			v.spritescale=((v.spritescale or math.random())+math.sqrt(v.spritebounce or 0.1)*0.02)
		end
	end
end)



function stargate.cancel_nth_tick(name,tick)

end
function stargate.on_nth_tick(name,tick,func)
	
end

function stargate.DoOpen(gate,istgt)

end

function stargate.FinishOpenGate(gate,tgate,vtick)
	if(not gate.dialing or not tgate.dialing or gate.dialing~=vtick or tgate.dialing~=vtick)then return end
	gate.dialing=false
	tgate.dialing=false
	for k,v in pairs(gate.ent.surface.find_entities_filtered{type={"character","car"},area=vector.square(gate.ent.position,vector(5,5))})do v.die(gate.ent.force,gate.ent) end
	for k,v in pairs(tgate.ent.surface.find_entities_filtered{type={"character","car"},area=vector.square(tgate.ent.position,vector(5,5))})do v.die(tgate.ent.force,tgate.ent) end
	local sprite={
		surface=gate.ent.surface,
		position=gate.ent.position,
		target=gate.ent,
		sprite="stargate-pond",
		render_layer="lower-object",
		
	}
	gate.sprite=rendering.draw_sprite(sprite)

	local sprite={
		surface=tgate.ent.surface,
		position=tgate.ent.position,
		target=tgate.ent,
		sprite="stargate-pond",
		render_layer="lower-object",
	}
	tgate.sprite=rendering.draw_sprite(sprite)


end

function stargate.PreFinishOpenGate(gate,tgate,vtick)
	if(not gate.dialing or not tgate.dialing or gate.dialing~=vtick or tgate.dialing~=vtick)then return end
	stargate.play_gate_sound(gate,"open") --gate.ent.surface.play_sound{path="stargate_open",position=gate.ent.position}
	stargate.play_gate_sound(tgate,"open") --tgate.ent.surface.play_sound{path="stargate_open",position=tgate.ent.position}

	gate.light=gate.light or rendering.draw_light{
		sprite="utility/light_medium",
		surface=gate.ent.surface,
		target=gate.ent,
		intensity=0.35,
		scale=4,
		minimum_darkness=-1,
		color={r=0.85,g=1,b=1,a=1},
	}

	tgate.light=tgate.light or rendering.draw_light{
		sprite="utility/light_medium",
		surface=tgate.ent.surface,
		target=tgate.ent,
		intensity=0.35,
		scale=4,
		minimum_darkness=-1,
		color={r=0.85,g=1,b=1,a=1},
	}

	if(not gate.sensor or not isvalid(global.sensorgates[gate.sensor]))then
		local sen=gate.ent.surface.create_entity{name="stargate-sensor",position=gate.ent.position,force=gate.ent.force}
		global.sensors[sen.unit_number]=gate
		global.sensorgates[gate.index]=sen
		gate.sensor=sen
	end
	if(not tgate.sensor or not isvalid(global.sensorgates[tgate.sensor]))then
		local sen=gate.ent.surface.create_entity{name="stargate-sensor",position=tgate.ent.position,force=tgate.ent.force}
		global.sensors[sen.unit_number]=tgate
		global.sensorgates[tgate.index]=sen
		tgate.sensor=sen
	end
end

function stargate.LockChevron(gate,tgate,i,vtick)
	if(not gate.dialing or not tgate.dialing or gate.dialing~=vtick or tgate.dialing~=vtick)then return end
	local vi=(10-i)
	stargate.play_gate_sound(gate,"chevron") --tgate.ent.surface.play_sound{path="stargate_chevrons_incoming",position=tgate.ent.position}
	stargate.play_gate_sound(tgate,"chevron_incoming") --gate.ent.surface.play_sound{path="stargate_chevrons_incoming",position=gate.ent.position}

		tgate.lights[i]=tgate.lights[i] or rendering.draw_light{
			sprite="item/small-lamp",
			surface=tgate.ent.surface,
			target=tgate.ent,
			target_offset=vector.SnapOrientation(vector(0,-2),i/9),
			intensity=64,
			scale=0.25,
			minimum_darkness=-1,
			color={r=0,g=1,b=1,a=1},
		}
		tgate.lamps[i]=tgate.lamps[i] or rendering.draw_sprite{
			sprite="item/small-lamp",
			surface=tgate.ent.surface,
			target=tgate.ent,
			target_offset=vector.SnapOrientation(vector(0,-2),i/9),
			x_scale=0.2,y_scale=0.2,
			tint={r=0,g=1,b=1,a=1},
		}


		gate.lights[i]=gate.lights[i] or rendering.draw_light{
			sprite="item/small-lamp",
			surface=gate.ent.surface,
			target=gate.ent,
			target_offset=vector.SnapOrientation(vector(0,-2),i/9),
			intensity=64,
			scale=0.25,
			minimum_darkness=-1,
			color={r=0,g=1,b=1,a=1},
		}
		gate.lamps[i]=gate.lamps[i] or rendering.draw_sprite{
			sprite="item/small-lamp",
			surface=gate.ent.surface,
			target=gate.ent,
			target_offset=vector.SnapOrientation(vector(0,-2),i/9),
			x_scale=0.2,y_scale=0.2,
			tint={r=0,g=1,b=1,a=1},
		}
end

function stargate.OpenGate(gate,tgate)
	global.tick=game.tick

	gate.isopen=tgate.index
	tgate.isopen=gate.index
	local vtick=game.tick
	gate.dialing=vtick
	tgate.dialing=vtick


	if(gate.lights)then for k,v in pairs(gate.lights)do rendering.destroy(v) end gate.lights={} end
	if(gate.lamps)then for k,v in pairs(gate.lamps)do rendering.destroy(v) end gate.lamps={} end
	if(tgate.lights)then for k,v in pairs(tgate.lights)do rendering.destroy(v) end tgate.lights={} end
	if(tgate.lamps)then for k,v in pairs(tgate.lamps)do rendering.destroy(v) end tgate.lamps={} end
	gate.lights=gate.lights or {} gate.lamps=gate.lamps or {}
	tgate.lights=tgate.lights or {} tgate.lamps=tgate.lamps or {}
	if(gate.light)then rendering.destroy(gate.light) gate.light=nil end
	if(tgate.light)then rendering.destroy(tgate.light) tgate.light=nil end

	gate.spritedir=math.max(math.random()+0.1,0.1)*0.00025
	tgate.spritedir=math.max(math.random()+0.1,0.1)*0.00025*-1
	gate.spritescale=math.random()
	tgate.spritescale=math.random()
	gate.spritebounce=math.random()
	tgate.spritebounce=math.random()

	-- fx now

	stargate.play_gate_sound(gate,"start_roll")
	stargate.play_gate_sound(tgate,"start_roll")

	stargate.play_gate_sound(gate,"roll") --gate.ent.surface.play_sound{path="stargate_gate_roll",volume_modifier=0.5}
	stargate.play_gate_sound(tgate,"roll") --tgate.ent.surface.play_sound{path="stargate_gate_roll",volume_modifier=0.5}

	local tmr=60*5
	local chevint=tmr/9

	script.on_nth_tick(vtick+10*chevint+90,function()
		stargate.FinishOpenGate(gate,tgate,vtick)
	end)

	script.on_nth_tick(vtick+10*chevint,function()
		stargate.PreFinishOpenGate(gate,tgate,vtick)
	end)


	for i=1,9,1 do local vi=(10-i)
		script.on_nth_tick(vtick+vi*chevint,function()
			stargate.LockChevron(gate,tgate,i,vtick)
		end)
	end
end

function stargate.LoadSprites(gate) local gtick=(global.tick or 0)
	if(gate.dialing)then
		local tmr=60*5
		local chevint=tmr/9 -- prev 25
		
		local tgate=global.stargates[gate.isopen]
		local vtick=gate.dialing
		local xtick=gate.dialing+10*chevint+90
		if(xtick>gtick)then
			script.on_nth_tick(xtick,function()
				stargate.FinishOpenGate(gate,tgate,vtick)
			end)
		end
		local xtick=gate.dialing+10*chevint
		if(xtick>gtick)then
			script.on_nth_tick(xtick,function()
				stargate.PreFinishOpenGate(gate,tgate,vtick)
			end)
		end
		for i=1,9,1 do local vi=(10-i)
			local xtick=gate.dialing+chevint*25
			if(xtick>gtick)then
			script.on_nth_tick(xtick,function()
				stargate.LockChevron(gate,tgate,i,vtick)
			end)
			end
		end
	end
end


function stargate.Shutdown(gate)
	local tgate=global.stargates[gate.isopen]
	gate.isopen=false
	tgate.isopen=false

	if(gate.dialing)then
	stargate.play_gate_sound(gate,"dial_fail") --tgate.ent.surface.play_sound{path="stargate_shutdown",position=tgate.ent.position}
	stargate.play_gate_sound(tgate,"dial_fail") --gate.ent.surface.play_sound{path="stargate_shutdown",position=gate.ent.position}
	else
	rendering.destroy(tgate.sprite)
	rendering.destroy(gate.sprite)
	stargate.play_gate_sound(gate,"shutdown") --tgate.ent.surface.play_sound{path="stargate_shutdown",position=tgate.ent.position}
	stargate.play_gate_sound(tgate,"shutdown") --gate.ent.surface.play_sound{path="stargate_shutdown",position=gate.ent.position}
	end
	gate.dialing=false
	tgate.dialing=false

	if(gate.lights)then for k,v in pairs(gate.lights)do rendering.destroy(v) end gate.lights={} end
	if(gate.lamps)then for k,v in pairs(gate.lamps)do rendering.destroy(v) end gate.lamps={} end
	if(tgate.lights)then for k,v in pairs(tgate.lights)do rendering.destroy(v) end tgate.lights={} end
	if(tgate.lamps)then for k,v in pairs(tgate.lamps)do rendering.destroy(v) end tgate.lamps={} end
	if(gate.light)then rendering.destroy(gate.light) gate.light=nil end
	if(tgate.light)then rendering.destroy(tgate.light) tgate.light=nil end

	if(gate.sensor)then
		if(isvalid(gate.sensor))then local sen=gate.sensor
			global.sensors[sen.unit_number]=nil
			global.sensorgates[gate.index]=nil
			sen.destroy()
			gate.sensor=nil
		end
	end



end


lib.lua()