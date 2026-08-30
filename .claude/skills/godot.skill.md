---
name: godot
description: Godot 4.x 游戏开发专用技能 - 快速创建GDScript、场景节点和实现游戏功能
---

# Godot 4.x 游戏开发技能

## 快速操作

### 创建脚本
- 优先使用 `extends Node` 或具体节点类型
- Autoload 单例不要使用 `class_name`
- 使用 `@onready` 获取节点引用

### 信号连接
```gdscript
# 连接信号
node.signal_name.connect(_on_signal_handler)

# 带参数绑定
node.signal_name.connect(_on_handler.bind(arg1, arg2))
```

## 常用代码模板

### Tween 动画
```gdscript
var tween = create_tween()
tween.tween_property(node, "position", target_pos, 0.5)
tween.tween_property(node, "modulate:a", 0, 0.3)
tween.finished.connect(func(): node.queue_free())
```

### Timer 延迟
```gdscript
await get_tree().create_timer(1.0).timeout
# 延迟执行的代码
```

### 场景实例化
```gdscript
var scene = preload("res://scenes/object.tscn")
var instance = scene.instantiate()
add_child(instance)
instance.position = Vector2(x, y)
```

## 养兔子游戏专用

### Rabbit 状态
- 饱食度 (hunger): 0-100，随时间减少
- 口渴度 (thirst): 0-100，随时间减少
- 快乐值 (happiness): 0-100，抚摸增加
- 毛长度 (fur_length): 0-100，达到80可剃毛
- 健康值 (health): 受其他属性影响

### AI 状态机
```gdscript
enum AIState { IDLE, WANDERING, SITTING, SLEEPING, HAPPY }

func set_state(new_state):
    current_state = new_state
    match new_state:
        AIState.IDLE:
            state_timer = randf_range(1, 3)
```

### 动画精灵
- 使用 `AnimatedSprite2D` + `SpriteFrames`
- 动画: idle, walk, sit, sleep, happy

## 场景结构最佳实践

```
project/
├── scenes/
│   ├── main.tscn          # 主场景 (CanvasLayer/Node2D)
│   └── rabbit.tscn        # 兔子场景 (CharacterBody2D)
├── scripts/
│   ├── game_manager.gd    # Autoload 全局管理
│   ├── save_manager.gd    # Autoload 存档管理
│   └── rabbit.gd          # 兔子逻辑
└── assets/
    ├── sprites/
    └── ui/
```

## Godot 4.x API 变更注意

| 旧API | 新API |
|-------|-------|
| `FileAccess.remove()` | `DirAccess.remove_absolute()` |
| `Rect2.clamp()` | 手动 `clamp(x, min, max)` |
| `yield()` | `await signal` |
| `$` 路径不变 | - |

## 常见问题修复

1. **"Class hides an autoload singleton"**
   - Autoload脚本不要使用 `class_name`
   - 直接通过名字访问全局单例

2. **"Tween was killed unexpectedly"**
   - 检查tween是否为null或is_valid()

3. **节点找不到**
   - 使用 `get_node_or_null()` 安全获取
   - 在 `_ready()` 中获取节点引用
