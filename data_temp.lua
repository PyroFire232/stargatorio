
--[[ -- unused old animation test
local t=table.deepcopy(data.raw["car"]["car"])
t.name="stargate"
t.icon="__stargate__/graphics/stargate/stargate_icon.png"
t.order="z"

local anim_sgc={
	filename = "__stargate__/graphics/stargate/gateanim.png",

	frame_count = 1,
	direction_count=26,
	height = 113,
	width = 116,
	line_length = 13,
	priority = "high",
	scale=0.5,
	shift = {0,0},
}

t.guns=nil

t.animation=anim

local r=table.deepcopy(data.raw.recipe.car)
r.result="stargate"
r.name="stargate"
r.enabled=true


local i=table.deepcopy(data.raw["item-with-entity-data"].car)
i.place_result="stargate"
i.name="stargate"

data:extend{t,r,i}
]]



local src={"land-mine","land-mine"}
local t=table.deepcopy(data.raw[src[1]][src[2]])
t.name="stargate-sensor"
t.icons={{icon="__stargate__/graphics/stargate/gate_sgu.png",icon_size=250,scale=0.15}}

local anim={
	filename = "__stargate__/graphics/stargate/gate_sgu.png",

	frame_count = 1,
	height = 250,
	width = 250,
	priority = "high",
	shift = {0,0},
	scale=0.0001,
}
t.collision_mask={}
t.collision_box={{-1.55,-1.55},{1.55,1.55}}
t.picture_safe=anim
t.picture_set=anim
t.flags={"not-on-map","not-deconstructable",
"not-flammable","no-automated-item-removal","no-automated-item-insertion","no-copy-paste","not-selectable-in-game",
"not-upgradable","hide-alt-info","hidden","placeable-off-grid","not-rotatable"
}
t.force_die_on_attack=false
t.trigger_force="all"
t.order="z"
t.timeout=5
t.trigger_radius=3
t.dying_explosion=nil
t.action={ type="direct",ignore_collision_condition=true,action_delivery={
	type="instant",target_effects={
		{type="create-sticker",sticker=t.name.."_sticker",trigger_created_entity=true}
	},
}}

local stick={type="sticker",name=t.name.."_sticker",animation={filename="__stargate__/graphics/stargate/gate_sgu.png",width=1,height=1},duration_in_ticks=1}
data:extend{t,stick}
