# 🐇 Happy Rabbit Garden / 快乐兔园

2D pixel-style casual breeding game, developed with Godot 4.7.
2D像素风格休闲养成游戏，用Godot 4.7开发。

## Project Introduction / 项目简介

Raise cute lop-eared rabbits in a fenced area, feed them, give them water, pet and interact with them, shave their fur regularly to earn coins, collect poop for income, complete growth tasks to unlock more items, and use coins to buy more rabbits, food, toys, and automatic facilities.
在围栏里饲养可爱的垂耳兔，给它们喂食、喂水、抚摸互动，定期剃毛获得金币，收集便便换取收入，完成成长任务解锁更多物品，用金币购买更多兔子、食物、玩具和自动设施。

## Core Features / 核心功能 ✨

### Implemented / 已实现
- ✅ Complete Godot project framework / 完整的Godot项目框架
- ✅ GameManager singleton for game state management / GameManager单例管理游戏状态
- ✅ SaveManager save system (5 save slots) / SaveManager存档系统（5个存档位）
- ✅ Rabbit AI behavior (wandering, sitting, sleeping, happy) / 兔子AI行为（闲逛、坐着、睡觉、开心）
- ✅ Main scene UI framework (top bar, action bar, info panel) / 主场景UI框架（顶部栏、操作栏、信息面板）
- ✅ Interaction system (feed, drink, pet, shave) / 交互系统（喂食、喂水、抚摸、剃毛）
- ✅ Click to select rabbit, show attribute progress bars / 点击选中兔子，显示属性进度条
- ✅ **Shop System / 商店系统** (5 categories / 5大分类)
  - 🥕 Food / 食物：Carrot / 胡萝卜、Fresh Vegetables / 新鲜蔬菜、Apple Slices / 苹果片、Premium Rabbit Food / 高级兔粮、Carrot Cake / 胡萝卜蛋糕、Water / 清水
  - ⚽ Toys / 玩具：Grass Carrot / 草萝卜
  - 💊 Medicine / 药品：Vitamin Tablets / 维生素片、Herbal Ointment / 草药膏、Magic Spring Water / 神奇泉水
  - 🏠 Facilities / 设施：Wooden House / 小木屋、Auto Feeder / 自动喂食器、Water Fountain / 自动饮水器、Grass Mat / 青草垫、Golden Bowl / 黄金食盆、Auto Toilet / 自动马桶
  - 🐇 Rabbits / 兔子：White Lop / 白色垂耳兔、Brown Lop / 棕色垂耳兔、Fence Expansion / 围栏扩建
- ✅ **Inventory System / 背包系统** (categorized storage and item use / 分类存放和使用物品)
- ✅ **Growth Task System / 成长任务系统** (staircase style, 12 tasks, gradually unlock new items / 阶梯式，12个任务，逐步解锁新物品)
- ✅ **Poop System / 便便系统**
  - Each rabbit generates poop every 20~30 seconds, max 3 per rabbit, max 15 total / 每只兔子每隔20~30秒生成便便，每只最多3个，全场最多15个
  - 0.5% chance for golden poop (more valuable) / 0.5%概率生成金色便便（更值钱）
  - Click poop to collect, earn coins and items / 点击便便收集，获得金币和物品
- ✅ **Automatic Facility System / 自动设施系统**
  - Auto Feeder 🍽️: Consumes food to automatically feed all rabbits / 消耗食物自动喂饱所有兔子
  - Water Fountain 🥤: Consumes water to automatically relieve thirst / 消耗清水自动缓解口渴
  - Wooden House 🏠: Continuously increases happiness / 持续增加快乐值
  - Grass Mat 🟩: Accelerates fur growth / 加速毛生长
  - Golden Bowl 🥣: Happiness + hunger double boost / 快乐+饱食双加成
  - Auto Toilet 🚽: Automatically collects all poop every 30 seconds / 每30秒自动收集所有便便
- ✅ **Storage System / 物资存放系统**: Double-click facilities to open storage interface / 双击设施可打开存放界面
- ✅ **Multiple Rabbit Breeds / 多种兔子品种**: Grey, White, Brown Lop / 灰色、白色、棕色垂耳兔
- ✅ Random rabbit names and fur color system / 兔子随机名字和毛发颜色系统
- ✅ AudioManager audio manager / AudioManager音频管理器
- ✅ InventoryManager inventory and facility manager / InventoryManager背包和设施管理器
- ✅ ItemData item data manager / ItemData物品数据管理器
- ✅ UnlockTaskManager growth task manager / UnlockTaskManager成长任务管理器

## Growth Tasks / 成长任务 🌱

There are 12 staircase tasks in total. Complete them in order, and each one unlocks a new item.
共12个阶梯任务，按顺序完成，每完成一个解锁一个新物品：

| # | Task Name / 任务名称 | Goal / 目标 | Unlocked Item / 解锁物品 |
|---|--------------------|------------|------------------------|
| 1 | Feed the Rabbit Carrot / 喂兔兔吃胡萝卜 | Feed 1 time / 喂食1次 | 🥬 Fresh Vegetables / 新鲜蔬菜 |
| 2 | Pet the Little Head / 摸摸小脑袋 | Pet 5 times / 抚摸5次 | 🍎 Apple Slices / 苹果片 |
| 3 | Time to Drink / 喝水啦 | Drink 3 times / 喂水3次 | 💊 Vitamin Tablets / 维生素片 |
| 4 | Fur Trim / 剪毛毛 | Shave 1 time / 剃毛1次 | 🌾 Premium Rabbit Food / 高级兔粮 |
| 5 | Diligent Poop Cleaner / 勤劳铲屎官 | Clean 5 poop / 打扫便便5次 | 🥕 Grass Carrot / 草萝卜 |
| 6 | Small Savings / 小有积蓄 | Accumulate 500 coins / 累计500金币 | 🏠 Wooden House / 小木屋 |
| 7 | Rabbit Buddy / 兔子伙伴 | Have 2 rabbits / 拥有2只兔子 | 🌿 Herbal Ointment / 草药膏 |
| 8 | Skilled Breeder / 熟练饲养员 | Feed 15 times total / 累计喂食15次 | 🥤 Water Fountain / 自动饮水器 |
| 9 | Settle Down / 安家落户 | Place 1 facility / 放置1个设施 | 🟩 Grass Mat / 青草垫 |
| 10 | Fluffy Collector / 毛茸收藏家 | Shave 5 times total / 累计剃毛5次 | 🎂 Carrot Cake / 胡萝卜蛋糕 |
| 11 | Big Rabbit Family / 兔子大家庭 | Have 5 rabbits at once / 同时拥有5只兔子 | 🍽️ Auto Feeder / 自动喂食器 |
| 12 | Rabbit Tycoon / 兔园大亨 | Accumulate 1000 coins / 累计1000金币 | 🚽 Auto Toilet / 自动马桶 |

## Game Mechanics / 游戏机制 🎮

### Rabbit Attributes / 兔子属性
| Attribute / 属性 | Description / 说明 | Change / 变化 |
|----------------|------------------|-------------|
| 🍖 Hunger / 饱食度 | How hungry the rabbit is / 兔子的饥饿程度 | Decreases over time, increases with feeding / 随时间下降，喂食增加 |
| 💧 Thirst / 口渴度 | How thirsty the rabbit is / 兔子的口渴程度 | Decreases over time, increases with water / 随时间下降，喂水增加 |
| 😊 Happiness / 快乐值 | Rabbit's mood / 兔子的心情 | Decreases over time, increases with petting/toys / 随时间下降，抚摸/玩具增加 |
| ✂️ Fur Length / 毛长度 | Can be shaved for coins / 可以剃毛赚钱 | Grows over time, resets when shaved / 随时间增长，剃毛重置 |
| ❤️ Health / 健康值 | Affected by other attributes / 受其他属性影响 | Recovers when overall status is good / 综合状态良好时恢复 |

### Shaving Quality / 剃毛品质
- Normal quality: Happiness < 50 / 普通品质：快乐值 < 50
- Good quality: Happiness 50-70 / 良好品质：快乐值 50-70
- Excellent quality: Happiness 70-90 / 优秀品质：快乐值 70-90
- Perfect quality: Happiness > 90 💰 / 完美品质：快乐值 > 90 💰

### Facility Effects / 设施效果
| Facility / 设施 | Icon / 图标 | Effect / 效果 | Price / 价格 | Purchase Limit / 限购 |
|---------------|-----------|-------------|-------------|---------------------|
| Wooden House / 小木屋 | 🏠 | Happiness +5/min / 快乐值 +5/分钟 | 200 coins / 200金币 | - |
| Auto Feeder / 自动喂食器 | 🍽️ | Hunger +20/min (consumes food) / 饱食度 +20/分钟（消耗食物） | 500 coins / 500金币 | 1 / 1个 |
| Water Fountain / 自动饮水器 | 🥤 | Thirst +25/min (consumes water) / 口渴度 +25/分钟（消耗清水） | 400 coins / 400金币 | 1 / 1个 |
| Grass Mat / 青草垫 | 🟩 | Accelerates fur growth / 毛生长加速 | 150 coins / 150金币 | - |
| Golden Bowl / 黄金食盆 | 🥣 | Happiness + hunger double boost / 快乐+饱食双加成 | 800 coins / 800金币 | - |
| Auto Toilet / 自动马桶 | 🚽 | Automatically collects all poop every 30s / 每30秒自动收集所有便便 | 1000 coins / 1000金币 | 1 / 1个 |

### Food Effects / 食物效果
| Food / 食物 | Icon / 图标 | Hunger / 饱食 | Happiness / 快乐 | Price / 价格 |
|-----------|-----------|-------------|----------------|-------------|
| Carrot / 胡萝卜 | 🥕 | +70 | +10 | 30 coins / 30金币 |
| Fresh Vegetables / 新鲜蔬菜 | 🥬 | +50 | +5 | 15 coins / 15金币 |
| Apple Slices / 苹果片 | 🍎 | +40 | - | 25 coins / 25金币 |
| Premium Rabbit Food / 高级兔粮 | 🌾 | +100 | +20 | 50 coins / 50金币 |
| Carrot Cake / 胡萝卜蛋糕 | 🎂 | +100 | +50 | 100 coins / 100金币 |
| Water / 清水 | 💧 | - | - | 10 coins / 10金币 |

### Poop Rewards / 便便收益
| Type / 类型 | Icon / 图标 | Price / 价格 | Chance / 概率 |
|-----------|-----------|-------------|--------------|
| Normal Poop / 普通便便 | 💩 | 2 coins / 2金币 | 99.5% |
| Golden Poop / 金色便便 | ✨💩 | Higher / 更高 | 0.5% |

## Project Structure / 项目结构 📁

```
happy-rabbit3/
├── project.godot          # Godot project config / Godot项目配置
├── icon.svg               # Game icon / 游戏图标
├── README.md              # Project description / 项目说明
├── scenes/
│   ├── main.tscn          # Main scene / 主场景
│   └── rabbit.tscn        # Rabbit scene / 兔子场景
├── scripts/
│   ├── game_manager.gd    # Game manager singleton / 游戏管理器单例
│   ├── save_manager.gd    # Save manager / 存档管理器
│   ├── audio_manager.gd   # Audio manager / 音频管理器
│   ├── inventory_manager.gd # Inventory and facility manager / 背包和设施管理器
│   ├── item_data.gd       # Item data manager / 物品数据管理
│   ├── task_manager.gd    # Task system (achievements/progress/daily/newbie) / 任务系统（成就/进度/日常/新手）
│   ├── unlock_task_manager.gd # Growth task manager / 成长任务管理器
│   ├── rabbit.gd          # Rabbit class / 兔子类
│   └── main.gd            # Main scene logic / 主场景逻辑
├── assets/
│   ├── sprites/
│   │   └── rabbits/       # Rabbit sprites / 兔子精灵图
│   ├── audio/             # Sound effects and BGM / 音效和BGM
│   └── ui/
│       └── theme.tres     # UI theme / UI主题
└── data/                  # Game data / 游戏数据
```

## System Requirements / 运行要求 🖥️

- Godot Engine 4.7 or higher / Godot Engine 4.7 或更高版本
- Graphics card supporting Vulkan or OpenGL / 支持Vulkan或OpenGL的显卡

## How to Play / 使用说明 📖

1. Open the project with Godot 4.7 / 用Godot 4.7打开项目
2. Click the run button (F5) to start the game / 点击运行按钮（F5）开始游戏
3. Start with 3 rabbits: Luo Xiaocao, Luo Dazhuang, Luo Erbai / 初始有3只兔子：萝小草、萝大壮、萝二白
4. **Basic Operations / 基础操作**:
   - Click a rabbit to select it and view detailed attributes / 点击兔子选中，查看详细属性
   - Use the bottom buttons to interact with rabbits / 使用底部按钮与兔子互动：
     - 🥕 Feed: increases hunger / 喂食：增加饱食度
     - 💧 Drink: increases thirst / 喂水：增加口渴度
     - 🤚 Pet: increases happiness, earns 10 coins / 抚摸：增加快乐值，获得10金币
     - ✂️ Shave: can shave when fur length ≥80 to earn coins / 剃毛：毛长≥80时可剃毛获得金币
   - Click 💩 in the fence to collect poop and earn coins / 点击围栏里的 💩 收集便便，获得金币
5. **Top Bar / 顶部栏**:
   - 🏪 Shop: Buy food, toys, medicine, facilities or new rabbits / 商店：购买食物、玩具、药品、设施或新兔子
   - 🎒 Inventory: View and use items / 背包：查看和使用物品
   - 🌱 Growth: View growth task progress, claim rewards / 成长：查看成长任务进度，领取奖励
   - 💾 Save: Save/load game / 存档：保存/加载游戏
6. **Growth Tasks / 成长任务**:
   - Tasks unlock in order, complete the previous one to proceed / 任务按顺序解锁，完成上一个才能进行下一个
   - Claim rewards in the Growth panel after completing tasks / 完成任务后在成长面板领取奖励
   - Each task unlocks a new shop item / 每个任务解锁一种新的商店物品
7. **Facility System / 设施系统**:
   - Purchased facilities are automatically placed in the fence / 购买设施后会自动放置在围栏内
   - Drag to move facility positions / 可以拖拽移动设施位置
   - **Double-click** feeders/fountains/houses to store items / **双击**喂食器/饮水器/木屋可以存放物资
   - Auto Toilet automatically collects all poop every 30 seconds / 自动马桶会每30秒自动收集所有便便
8. **Automatic Facilities / 自动设施**:
   - After adding items, facilities work automatically / 放入物资后，设施会自动工作
   - Boost all rabbits' attributes every 3 seconds / 每3秒给所有兔子增加属性
   - Re-add items when supplies run out / 消耗完物资需要重新添加
9. **Fence Expansion / 围栏扩建**:
   - Initially maximum 3 rabbits / 初始最多养3只兔子
   - Buy fence expansion in the shop's "Rabbit" tab, +1 slot each time / 在商店「兔子」标签页购买围栏扩建，每次增加1个名额

## Shaving Income / 剃毛收益 💰

| Quality / 品质 | Happiness Requirement / 快乐值要求 | Base Reward / 基础收益 | White Lop / 白色垂耳兔 |
|-------------|---------------------------------|---------------------|---------------------|
| Normal / 普通 | < 50 | 15 coins / 15金币 | 22 coins / 22金币 |
| Good / 良好 | 50-70 | 25 coins / 25金币 | 37 coins / 37金币 |
| Excellent / 优秀 | 70-90 | 40 coins / 40金币 | 60 coins / 60金币 |
| Perfect / 完美 | > 90 | 60 coins / 60金币 | 90 coins / 90金币 |

Tip: White Lop rabbits have more valuable fur!
提示：白色垂耳兔的毛价值更高！

## Development Plan / 开发计划 📅

### Phase 1: Foundation / 阶段一：基础框架 ✅
- [x] Project structure and configuration / 项目结构和配置
- [x] GameManager and SaveManager / GameManager和SaveManager
- [x] Rabbit base class and AI / 兔子基础类和AI
- [x] Main scene UI / 主场景UI

### Phase 2: Core Gameplay / 阶段二：核心玩法 ✅
- [x] Shop system (5 categories) / 商店系统（5大分类）
- [x] Inventory system / 背包系统
- [x] Automatic facility system / 自动设施系统
- [x] Storage system / 物资存放系统
- [x] Multiple rabbit breeds / 多种兔子品种
- [x] Fence expansion / 围栏扩建
- [x] Food variety expansion / 食物种类扩展
- [x] Toy and medicine system / 玩具和药品系统
- [x] Poop collection system / 便便收集系统
- [x] Growth task system (12 staircase tasks) / 成长任务系统（12个阶梯任务）
- [x] Auto Toilet / 自动马桶

### Phase 3: Visual Optimization / 阶段三：视觉优化 🎨
- [ ] Pixel animation improvement / 像素动画完善
- [ ] More visual effects / 更多视觉特效
- [ ] Sound effects and BGM improvement / 音效和BGM完善
- [ ] Particle effects / 粒子效果
- [ ] Rabbit animation states / 兔子动画状态

### Phase 4: Content Expansion / 阶段四：内容扩展 🌟
- [ ] Achievement system / 成就系统
- [ ] Daily tasks / 日常任务
- [ ] More decorations / 更多装饰品
- [ ] Visitor NPCs / 访客NPC
- [ ] Rabbit breeding system / 兔子繁殖系统
- [ ] Special events and festivals / 特殊活动和节日

## Technical Features / 技术特点 🔧

- **Singleton Pattern / 单例模式**: GameManager, SaveManager, AudioManager, InventoryManager, TaskManager, UnlockTaskManager are globally accessible / GameManager、SaveManager、AudioManager、InventoryManager、TaskManager、UnlockTaskManager全局可访问
- **Signal System / 信号系统**: Godot signals handle UI updates and interaction events / Godot信号处理UI更新和交互事件
- **Item Data Management / 物品数据管理**: ItemData centrally manages all item configurations / ItemData统一管理所有物品配置
- **Facility Manager / 设施管理器**: InventoryManager handles inventory and placed facilities / InventoryManager处理背包和放置设施
- **AI State Machine / AI状态机**: Rabbits automatically switch behaviors based on state / 兔子根据状态自动切换行为
- **Responsive UI / 响应式UI**: Real-time attribute display when selecting rabbits / 选中兔子实时更新属性显示
- **Timer System / 定时器系统**: Facility effects and auto-feeding trigger on timers / 设施效果和自动喂食定时触发
- **Staircase Task System / 阶梯任务系统**: Linear task chain, gradually unlock new items, guide players through complete gameplay / 线性任务链，逐步解锁新物品，引导玩家体验完整玩法

## License / 许可证 📄

MIT License - Free for learning and commercial projects
MIT License - 免费用于学习和商业项目

---

Happy rabbit raising! 🐇💕
祝你养兔愉快！🐇💕
