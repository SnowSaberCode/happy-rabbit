extends Node
# 商品数据管理

# 商品类型
enum ItemType {
	FOOD,       # 食物（消耗品，直接使用）
	TOY,        # 玩具（消耗品，增加快乐）
	MEDICINE,   # 药品（消耗品，恢复健康）
	FURNITURE,  # 设施（可放置在笼子里，永久效果）
	MATERIAL    # 材料（收集品，用于合成或出售）
}

# 所有商品数据
var all_items: Dictionary = {
	# ========== 食物 ==========
	"carrot": {
		"id": "carrot",
		"name": "高级胡萝卜",
		"type": ItemType.FOOD,
		"price": 30,
		"hunger_add": 70,
		"happiness_add": 10,
		"description": "恢复70饱食度，兔子最爱吃！",
		"icon": "🥕"
	},
	"water": {
		"id": "water",
		"name": "清水",
		"type": ItemType.FOOD,
		"price": 10,
		"thirst_add": 60,
		"description": "恢复60口渴度",
		"icon": "💧"
	},
	"vegetable": {
		"id": "vegetable",
		"name": "新鲜蔬菜",
		"type": ItemType.FOOD,
		"price": 15,
		"hunger_add": 50,
		"happiness_add": 5,
		"description": "恢复50饱食度",
		"icon": "🥬"
	},
	"apple": {
		"id": "apple",
		"name": "苹果片",
		"type": ItemType.FOOD,
		"price": 25,
		"hunger_add": 40,
		"happiness_add": 15,
		"fur_boost": true,
		"description": "恢复40饱食度，加速毛生长",
		"icon": "🍎"
	},
	"rabbit_food": {
		"id": "rabbit_food",
		"name": "高级兔粮",
		"type": ItemType.FOOD,
		"price": 50,
		"hunger_add": 100,
		"happiness_add": 20,
		"description": "完全恢复饱食度，超级营养！",
		"icon": "🌾"
	},
	"carrot_cake": {
		"id": "carrot_cake",
		"name": "胡萝卜蛋糕",
		"type": ItemType.FOOD,
		"price": 100,
		"hunger_add": 100,
		"happiness_add": 50,
		"description": "豪华点心！全属性大幅提升",
		"icon": "🎂"
	},

	# ========== 玩具 ==========
	# "ball": {
	# 	"id": "ball",
	# 	"name": "小皮球",
	# 	"type": ItemType.TOY,
	# 	"price": 40,
	# 	"happiness_add": 40,
	# 	"description": "和兔子玩球，大幅增加快乐值",
	# 	"icon": "⚽"
	# },
	# "yarn": {
	# 	"id": "yarn",
	# 	"name": "毛线球",
	# 	"type": ItemType.TOY,
	# 	"price": 35,
	# 	"happiness_add": 35,
	# 	"description": "兔子最爱玩的毛线球",
	# 	"icon": "🧶"
	# },
	# "carrot_toy": {
	# 	"id": "carrot_toy",
	# 	"name": "胡萝卜玩具",
	# 	"type": ItemType.TOY,
	# 	"price": 60,
	# 	"happiness_add": 60,
	# 	"description": "超级可爱的胡萝卜造型玩具！",
	# 	"icon": "🥕"
	# },
	# "tunnel": {
	# 	"id": "tunnel",
	# 	"name": "兔子隧道",
	# 	"type": ItemType.TOY,
	# 	"price": 120,
	# 	"happiness_add": 80,
	# 	"description": "让兔子钻来钻去，超级开心！",
	# 	"icon": "🕳️"
	# },
	"grass_carrot": {
		"id": "grass_carrot",
		"name": "草萝卜",
		"type": ItemType.TOY,
		"price": 25,
		"happiness_add": 30,
		"description": "可以放在小木屋的草编萝卜，持续增加快乐值",
		"icon": "🥕",
		"storable": true
	},

	# ========== 药品 ==========
	"vitamin": {
		"id": "vitamin",
		"name": "维生素片",
		"type": ItemType.MEDICINE,
		"price": 80,
		"health_add": 30,
		"description": "补充维生素，恢复30健康值",
		"icon": "💊"
	},
	"herb_medicine": {
		"id": "herb_medicine",
		"name": "草药膏",
		"type": ItemType.MEDICINE,
		"price": 150,
		"health_add": 60,
		"happiness_add": 10,
		"description": "天然草药，恢复60健康值",
		"icon": "🌿"
	},
	"magic_water": {
		"id": "magic_water",
		"name": "神奇泉水",
		"type": ItemType.MEDICINE,
		"price": 300,
		"health_add": 100,
		"happiness_add": 50,
		"hunger_add": 50,
		"description": "传说中的泉水，全属性大提升！",
		"icon": "✨"
	},

	# ========== 设施 ==========
	"wooden_house": {
		"id": "wooden_house",
		"name": "小木屋",
		"type": ItemType.FURNITURE,
		"price": 200,
		"happiness_bonus": 5,  # 每分钟额外增加快乐
		"description": "持续增加快乐值",
		"icon": "🏠",
		"big_icon": "🏠",
		"placeable": true
	},
	"auto_feeder": {
		"id": "auto_feeder",
		"name": "自动喂食器",
		"type": ItemType.FURNITURE,
		"price": 500,
		"hunger_bonus": 20,  # 每分钟自动恢复
		"description": "需要消耗背包食物，饱食度+20/分钟",
		"icon": "🍽️",
		"big_icon": "🍽️",
		"placeable": true
	},
	"water_fountain": {
		"id": "water_fountain",
		"name": "自动饮水器",
		"type": ItemType.FURNITURE,
		"price": 400,
		"thirst_bonus": 25,  # 每分钟自动恢复
		"description": "需要消耗清水，口渴度+25/分钟",
		"icon": "🥤",
		"big_icon": "🥤",
		"placeable": true
	},
	"grass_mat": {
		"id": "grass_mat",
		"name": "青草垫",
		"type": ItemType.FURNITURE,
		"price": 150,
		"fur_bonus": 2,  # 每分钟毛生长加速
		"description": "限时60秒，极速加速毛生长",
		"icon": "🟩",
		"big_icon": "🟩",
		"placeable": true
	},
	"golden_bowl": {
		"id": "golden_bowl",
		"name": "黄金食盆",
		"type": ItemType.FURNITURE,
		"price": 800,
		"happiness_bonus": 15,
		"hunger_bonus": 15,
		"description": "需要消耗食物，快乐+15，饱食+15/分钟",
		"icon": "🥣",
		"big_icon": "🥣",
		"placeable": true
	},
	"auto_toilet": {
		"id": "auto_toilet",
		"name": "自动马桶",
		"type": ItemType.FURNITURE,
		"price": 1000,
		"auto_collect_poop": true,
		"description": "自动收集便便，每30秒自动清理围栏内所有便便并获得金币",
		"icon": "🚽",
		"big_icon": "🚽",
		"placeable": true
	},

	# ========== 材料 ==========
	"rabbit_poop": {
		"id": "rabbit_poop",
		"name": "兔便便",
		"type": ItemType.MATERIAL,
		"price": 2,
		"description": "兔子的便便，可以收集卖钱，以后还能合成肥料",
		"icon": "💩"
	},
	"golden_poop": {
		"id": "golden_poop",
		"name": "金色便便",
		"type": ItemType.MATERIAL,
		"price": 20,
		"description": "✨ 闪闪发光的稀有便便，价值不菲！",
		"icon": "💩"
	}
}

# 根据类型筛选商品
func get_items_by_type(item_type: int) -> Array:
	var result = []
	for item in all_items.values():
		if item.type == item_type:
			result.append(item)
	return result

# 获取单个商品，不存在则返回空字典
func get_item(item_id: String) -> Dictionary:
	if all_items.has(item_id):
		return all_items[item_id]
	return {}
