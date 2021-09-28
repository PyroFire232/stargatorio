require("data_fonts")
require("sound/sound")

require("data_temp") -- random stuff


local sgSource={"container","wooden-chest"}
local function MakeStargate(name,img,ings,techimg,techreq,cost)
	local t=table.deepcopy(data.raw[sgSource[1]][sgSource[2]])
	t.name=name
	t.icon=nil
	t.icons={{icon=img,icon_size=250,scale=64/250}}
	t.icon_mipmaps=nil
	t.max_health=1000
	t.order="z"
	t.collision_box={{-2,-2},{2,2}}
	t.selection_box={{-2,-2},{2,2}}
	if(settings.startup["stargate_placeable_in_space"].value)then
		t.se_allow_in_space=true
	end
	t.minable={mining_time=2,result=t.name}
	t.inventory_size=0

	t.localised_description={"entity-description."..name}

	local anim={filename=img,height=250,width=250,priority="high",scale=0.55,shift={0,0}}
	t.picture={layers={anim}}
	t.fast_replaceable_group="stargate"
	t.corpse=nil


	local rcp=table.deepcopy(data.raw.recipe[sgSource[2]])
	rcp.result=t.name
	rcp.name=t.name
	rcp.enabled=false
	rcp.icons=table.deepcopy(t.icons)
	rcp.icon=nil
	rcp.icon_mipmaps=nil
	rcp.ingredients=ings
	--rcp.ingredients={{"rocket-control-unit",50},{"low-density-structure",50},{"steel-plate",100},{"battery",50},{"radar",9},{"fusion-reactor-equipment",9}}


	local item=table.deepcopy(data.raw.item[sgSource[2]])
	item.name=t.name
	item.place_result=t.name
	item.icons=table.deepcopy(t.icons)
	item.icon=nil
	item.icon_mipmaps=nil

	local tech={name=t.name,type="technology",icons={{icon_size=250,icon=techimg,scale=128/250}},
		order="a-d-b",
		prerequisites=techreq,
		unit=cost, --,
		effects={ {type="unlock-recipe",recipe=t.name} },
	}

	data:extend{t,rcp,item,tech}
end

--[[ Stargates ]]--

MakeStargate("stargate_sgu","__stargate__/graphics/stargate/gate_sgu.png",{{"small-lamp",9},{"big-electric-pole",9},{"electronic-circuit",9},{"iron-gear-wheel",100},{"concrete",100},{"copper-cable",200}},
	"__stargate__/graphics/stargate/gateroom_sgu.jpg",{"electric-energy-distribution-1","concrete","logistics"},{time=15,count=800,ingredients={
	{"automation-science-pack",1},{"logistic-science-pack",1},
} })
MakeStargate("stargate_sgc","__stargate__/graphics/stargate/gate_sgc.png",{{"stargate_sgu",1},{"refined-concrete",100},{"substation",9},{"advanced-circuit",9},{"battery",100},{"low-density-structure",20}},
	"__stargate__/graphics/stargate/gateroom_sgc.jpg",{"stargate_sgu","circuit-network","low-density-structure","logistics-2","electric-energy-distribution-2"},{time=15,count=800,ingredients={
	{"automation-science-pack",1},{"logistic-science-pack",1},{"chemical-science-pack",1},
} })
MakeStargate("stargate_atlantis","__stargate__/graphics/stargate/gate_atlantis.png",{{"stargate_sgc",1},{"express-transport-belt",100},{"express-underground-belt",50},{"express-splitter",50},{"electric-engine-unit",9},{"rocket-control-unit",9},},
	"__stargate__/graphics/stargate/gateroom_atlantis.jpg",{"stargate_sgc","tank","rocket-silo","logistics-3"},{time=15,count=800,ingredients={
	{"automation-science-pack",1},{"logistic-science-pack",1},{"chemical-science-pack",1},{"utility-science-pack",1},
} })

--[[ Stargate Technologies ]]--


--[[ DHD Prototype ]]--

local rcp=table.deepcopy(data.raw.recipe["constant-combinator"])
local item=table.deepcopy(data.raw.item["constant-combinator"])
local ent=table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

ent.name="stargate-dhd"
ent.minable.result=ent.name
item.name=ent.name
item.place_result=ent.name
rcp.result=item.name
rcp.name=ent.name
rcp.enabled=false
local anim={layers={{
	filename = "__stargate__/graphics/stargate/dhd.png",
	frame_count = 1,
	height = 128,
	width = 128,
	priority = "high",
	shift = {0,0},
	scale=0.3,
}}}
item.icon=nil
item.icon_size=nil
item.icons={{icon="__stargate__/graphics/stargate/dhd.png",icon_size=128,scale=0.5}}
ent.sprites={east=table.deepcopy(anim),west=table.deepcopy(anim),north=table.deepcopy(anim),south=table.deepcopy(anim)}

data:extend{rcp,item,ent}
local rsilo=data.raw.technology["stargate_sgc"]
if(rsilo.effects)then table.insert(rsilo.effects,{type="unlock-recipe",recipe=rcp.name}) end

local sprite={
	name="stargate-pond",
	filename="__stargate__/graphics/stargate/simple_pond.png",
	type="sprite",
	width=554,height=554,
	scale=0.25
}
data:extend{sprite}