--https://github.com/RafaelDeJongh/cap_resources/tree/master/sound/stargate
--sounds

local sgPath="__stargate__/sound/stargate/"

local GateSounds={
["sgc"]={ sounds={
	["open"]="gate_open.ogg",
	["shutdown"]="gate_shutdown.ogg",
	["dial_fail"]={"dial_fail.ogg","dial_fail_sg1.wav"},


	["chevron_incoming"]={"chevron_incoming/chevron_incoming.ogg","chevron_incoming/chevron_incoming_2.ogg","chevron_incoming/chevron_incoming_3.ogg",
		"chevron_incoming/chevron_incoming_4.ogg","chevron_incoming/chevron_incoming_5.ogg","chevron_incoming/chevron_incoming_6.ogg","chevron_incoming/chevron_incoming_7.ogg",},


	["roll"]="ring_usual_start.wav",

	["dhd"]={"dhd/press.ogg","dhd/press_2.ogg","dhd/press_3.ogg","dhd/press_4.ogg","dhd/press_5.ogg","dhd/press_6.ogg","dhd/press_7.ogg"},
	["dhd_dial"]={"chevron_lock_dhd.ogg","dhd/dhd_usual_dial.wav"},
	["dhd_cancel"]="chevron.ogg",
	["dhd_roll"]="gate_roll.ogg",
	["dhd_chevron"]="chevron.ogg",

	--unused: {"chevron/chev_usual_1.ogg","chevron/chev_usual_2.ogg","chevron/chev_usual_3.ogg","chevron/chev_usual_4.ogg","chevron/chev_usual_5.ogg","chevron/chev_usual_6.ogg","chevron/chev_usual_7.ogg"},

}},
["atlantis"]={ sounds={
	["open"]={"gate_open_atlantis.wav","open.wav"},
	["shutdown"]={"close.wav"},
	["dial_fail"]={"dial_fail.wav"},

	["chevron"]={"chevron.wav"},
	["chevron_incoming"]={"chevron_incoming.wav"},

	["dhd"]="dhd_press.wav",
	["dhd_dial"]="lock_incoming.wav",
	["dhd_cancel"]="chevron_incoming.wav",
	["dhd_roll"]="gate_roll.wav",
	["dhd_chevron"]="chevron.wav",

	["roll"]="roll.wav",
}},
["sgu"]={ sounds={
	--["open"]="gate_open.wav",
	["shutdown"]="gate_close.wav",
	["dial_fail"]="dial_fail.wav",

	["chevron"]="chevron.wav",
	["chevron_incoming"]="chevron.wav",

	["gate_roll_5s"]="fast_gate_roll.wav",
	["roll"]="gate_roll.wav",

	["start_roll"]="gate_start_roll.wav",
	--["steam"]="steam.wav",

	["dhd_cancel"]="chevron.wav",
	["dhd_dial"]="gate_start_roll.wav",
	["dhd_roll"]="gate_roll.wav",
	["dhd_chevron"]="chevron.wav",
}},
}
GateSounds.sgc.sounds.chevron=table.deepcopy(GateSounds.sgc.sounds.chevron_incoming)

local function ExtendGateSound(k,i,v) local t={type="sound",name="stargate_"..k.."_"..i}
	if(type(v)=="table")then t.variations={} for x,e in pairs(v)do table.insert(t.variations,{filename=sgPath..k.."/"..e}) end else t.filename=sgPath..k.."/"..v end
	data:extend{t}
end

for k,v in pairs(GateSounds)do for i,e in pairs(v.sounds)do ExtendGateSound(k,i,e) end end
	
--["wormhole_loop"]="wormhole_loop.ogg",
data:extend(
{


{ type = "sound",
	name = "stargate_damaged",
	variations = {
		{filename="__stargate__/sound/orlin/gate_flicker.ogg"},
		{filename="__stargate__/sound/orlin/gate_flicker2.ogg"},
		{filename="__stargate__/sound/orlin/gate_flicker3.ogg"},
	},
},


{ type = "sound",
	name = "stargate_teleport",
	variations = {
		{filename="__stargate__/sound/teleport/teleport.ogg"},
		{filename="__stargate__/sound/teleport/teleport_2.ogg"},
		{filename="__stargate__/sound/teleport/teleport_3.ogg"},
		{filename="__stargate__/sound/teleport/teleport_4.ogg"},
		{filename="__stargate__/sound/teleport/teleport_5.ogg"},
		{filename="__stargate__/sound/teleport/teleport_6.ogg"},
		{filename="__stargate__/sound/teleport/teleport_7.ogg"},
		{filename="__stargate__/sound/teleport/teleport_8.ogg"},
	},
},

})