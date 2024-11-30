import { GameObject, EnemyPlane, BulletItem } from '../model/GameModels'

@Entry
@Component
struct Index {
  // 游戏状态
  @State private isGameStarted: boolean = false
  @State private score: number = 0
  @State private isGameOver: boolean = false

  // 玩家飞机位置
  @State private playerX: number = 0
  @State private playerY: number = 0

  // 敌机和子弹数组
  @State private enemies: EnemyPlane[] = []
  @State private bullets: BulletItem[] = []

  // 游戏循环定时器
  private gameTimer: number = 0
  private readonly GAME_INTERVAL: number = 50 // 降低更新频率
  
  // 游戏参数
  private readonly PLAYER_SIZE: number = 50
  private readonly ENEMY_SIZE: number = 40
  private readonly BULLET_SIZE: number = 6
  private readonly ENEMY_SPEED: number = 5 // 增加移动速度
  private readonly BULLET_SPEED: number = 5
  private readonly ENEMY_SPAWN_INTERVAL: number = 2000 // 增加生成间隔到2秒
  private readonly BULLET_INTERVAL: number = 200  // 每200ms发射一颗子弹 (1000ms/5=200ms)

  private lastEnemySpawnTime: number = 0
  private lastBulletTime: number = 0

  // 修改移动相关的属性
  private readonly PLAYER_SPEED: number = 15
  private moveTimer: number = 0
  private targetX: number = 0
  private targetY: number = 0
  private isMoving: boolean = false
  private gameAreaWidth: number = 0
  private gameAreaHeight: number = 0

  // 添加计时器相关属性
  @State private gameTime: number = 0  // 游戏时间（毫秒）
  private gameTimeTimer: number = 0    // 计时器ID
  private readonly TIME_UPDATE_INTERVAL: number = 10  // 计时器更新间隔（毫秒）
  private readonly INITIAL_ENEMY_SPAWN_INTERVAL: number = 2000  // 初始敌机生成间隔
  private readonly MIN_ENEMY_SPAWN_INTERVAL: number = 500  // 最小敌机生成间隔

  aboutToAppear() {
    // 设置游戏区域尺寸
    this.gameAreaWidth = 750
    this.gameAreaHeight = 1000
    
    // 初始化飞机位置
    this.initializePlayerPosition()
  }

  build() {
    Stack() {
      if (!this.isGameStarted) {
        // 开始界面
        Column() {
          Text('飞机大战')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 50 })
          
          Button('开始游戏')
            .width(200)
            .height(50)
            .fontSize(25)
            .onClick(() => {
              this.startGame()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Stack() {
          // 游戏区域背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#F1F3F5')

          // 敌机
          ForEach(this.enemies, (enemy: EnemyPlane) => {
            Image($r('app.media.img_enemy_aircraft1'))
              .width(this.ENEMY_SIZE)
              .height(this.ENEMY_SIZE)
              .position({
                x: `${enemy.x}vp`,
                y: `${enemy.y}vp`
              })
          })

          // 玩家飞机
          Image($r('app.media.img_player_aircraft1'))
            .width(this.PLAYER_SIZE)
            .height(this.PLAYER_SIZE)
            .position({
              x: `${this.playerX}vp`,
              y: `${this.playerY}vp`
            })

          // 子弹
          ForEach(this.bullets, (bullet: BulletItem) => {
            Column() {
              // 子弹主体
              Circle()
                .width(this.BULLET_SIZE)
                .height(this.BULLET_SIZE)
                .fill(Color.Black)
              
              // 子弹尾部
              Circle()
                .width(this.BULLET_SIZE * 0.6)
                .height(this.BULLET_SIZE * 0.6)
                .fill(Color.Black)
                .margin({ top: -2 })
            }
            .position({
              x: `${bullet.x}vp`,
              y: `${bullet.y}vp`
            })
          })

          // 修改计时器和得分显示部分
          Row() {
            Column() {
              Text(`时间: ${(this.gameTime / 1000).toFixed(3)}s`)
                .fontSize(24)
                .fontColor(Color.Black)
                .margin({ bottom: 5 })
                .textAlign(TextAlign.Start)  // 左对齐
              
              Text(`得分: ${this.score}`)
                .fontSize(24)
                .fontColor(Color.Black)
                .textAlign(TextAlign.Start)  // 左对齐
            }
            .backgroundColor('rgba(255, 255, 255, 0.3)')  // 使用更透明的背景
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .borderRadius(15)
            .alignItems(HorizontalAlign.Start)  // 子元素左对齐
            .margin({ left: 20, top: 20 })
          }
          .alignItems(VerticalAlign.Top)  // 修改这里，使用 VerticalAlign 代替 ItemAlign
          .width('100%')
          .position({ x: 0, y: 0 })
        }
        .width('100%')
        .height('100%')
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down || event.type === TouchType.Move) {
            let touch = event.touches[0]
            this.targetX = touch.x - this.PLAYER_SIZE / 2
            this.targetY = touch.y - this.PLAYER_SIZE / 2

            // 确保目标位置在游戏区域内
            this.targetX = Math.max(0, Math.min(this.targetX, this.gameAreaWidth - this.PLAYER_SIZE))
            this.targetY = Math.max(0, Math.min(this.targetY, this.gameAreaHeight - this.PLAYER_SIZE))

            if (!this.isMoving) {
              this.startMoving()
            }
          }
        })
      }

      // 游戏结束界面
      if (this.isGameOver) {
        // 游戏结束界面
        Column() {
          Text('游戏结束')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
          Text(`最终得分: ${this.score}`)
            .fontSize(30)
            .margin({ top: 20 })
          Button('重新开始')
            .width(200)
            .height(50)
            .margin({ top: 40 })
            .onClick(() => {
              this.resetGame()
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#88000000')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  // 游戏初始化
  private startGame() {
    this.isGameStarted = true
    this.score = 0
    this.isGameOver = false
    this.enemies = []
    this.bullets = []
    this.gameTime = 0  // 重置游戏时间
    
    this.initializePlayerPosition()
    this.startGameLoop()
    this.startGameTimer()  // 启动计时器
  }

  // 修改初始化飞机位置的方法
  private initializePlayerPosition() {
    // 计算飞机的初始位置（屏幕底部中间）
    this.playerX = (this.gameAreaWidth - this.PLAYER_SIZE) / 2  // 居中
    this.playerY = this.gameAreaHeight * 0.75  // 在屏幕3/4处
    
    // 同步目标位置
    this.targetX = this.playerX
    this.targetY = this.playerY
  }

  // 修改发射子弹的方法
  private fireBullet() {
    // 从飞机顶部中心发射子弹
    const bulletX = this.playerX + (this.PLAYER_SIZE - this.BULLET_SIZE) / 2
    const bulletY = this.playerY  // 从飞机当前位置发射
    
    this.bullets.push(new BulletItem(
      bulletX,
      bulletY,
      this.BULLET_SIZE,
      this.BULLET_SIZE
    ))
  }

  // 重置游戏状态
  private resetGame() {
    this.score = 0
    this.isGameOver = false
    this.enemies = []
    this.bullets = []
    
    // 使用初始化方法重置飞机位置
    this.initializePlayerPosition()
    
    this.lastEnemySpawnTime = 0
    this.lastBulletTime = 0
    
    // 重新启动游戏循环
    if (this.gameTimer) {
      clearInterval(this.gameTimer)
    }
    this.startGameLoop()
  }

  // 开始游戏循环
  private startGameLoop() {
    this.gameTimer = setInterval(() => {
      this.updateGame()
    }, this.GAME_INTERVAL)
  }

  // 游戏逻辑更新
  private updateGame() {
    const currentTime = Date.now()

    // 使用动态计算的生成间隔
    const currentSpawnInterval = this.getCurrentEnemySpawnInterval()
    if (currentTime - this.lastEnemySpawnTime > currentSpawnInterval) {
      this.spawnEnemy()
      this.lastEnemySpawnTime = currentTime
    }

    // 发射子弹 - 修改这部分
    if (currentTime - this.lastBulletTime > this.BULLET_INTERVAL) {  // 使用BULLET_INTERVAL
      this.fireBullet()
      this.lastBulletTime = currentTime
    }

    // 更新敌机位置
    this.updateEnemies()

    // 更新子弹位置
    this.updateBullets()

    // 检测碰撞
    this.checkCollisions()
  }

  // 生成敌机
  private spawnEnemy() {
    const x = Math.random() * (this.gameAreaWidth - this.ENEMY_SIZE)
    console.info(`Spawning enemy at x: ${x}, y: -${this.ENEMY_SIZE}`)
    this.enemies.push(new EnemyPlane(x, -this.ENEMY_SIZE, this.ENEMY_SIZE, this.ENEMY_SIZE))
    console.info(`Current enemies count: ${this.enemies.length}`)
  }

  // 更新敌机位置
  private updateEnemies() {
    console.info(`Before update - Enemies count: ${this.enemies.length}`)
    this.enemies = this.enemies.filter(enemy => {
      enemy.y += this.ENEMY_SPEED
      console.info(`Enemy position: x: ${enemy.x}, y: ${enemy.y}`)
      return enemy.y < this.gameAreaHeight
    })
    console.info(`After update - Enemies count: ${this.enemies.length}`)
  }

  // 更新子弹位置
  private updateBullets() {
    this.bullets = this.bullets.filter(bullet => {
      bullet.y -= this.BULLET_SPEED
      return bullet.y > -this.BULLET_SIZE // 移除超屏幕的子弹
    })
  }

  // 碰撞检测
  private checkCollisions() {
    // 检查玩家与敌机的碰撞
    for (const enemy of this.enemies) {
      if (this.isColliding(
        new GameObject(this.playerX, this.playerY, this.PLAYER_SIZE, this.PLAYER_SIZE),
        enemy
      )) {
        this.gameOver()
        return
      }
    }

    // 检查子弹与敌机的碰撞
    this.bullets = this.bullets.filter(bullet => {
      let bulletHit = false
      this.enemies = this.enemies.filter(enemy => {
        if (!bulletHit && this.isColliding(bullet, enemy)) {
          bulletHit = true
          this.score += 100
          return false
        }
        return true
      })
      return !bulletHit
    })
  }

  // 碰撞检测辅助函数
  private isColliding(obj1: GameObject, obj2: GameObject): boolean {
    return obj1.x < obj2.x + obj2.width &&
           obj1.x + obj1.width > obj2.x &&
           obj1.y < obj2.y + obj2.height &&
           obj1.y + obj1.height > obj2.y
  }

  // 游戏结束
  private gameOver() {
    this.isGameOver = true
    if (this.gameTimer) {
      clearInterval(this.gameTimer)
      this.gameTimer = 0
    }
    this.stopGameTimer()  // 停止计时器
    this.stopMoving()
  }

  aboutToDisappear() {
    clearInterval(this.gameTimer)
    this.stopGameTimer()  // 清理计时器
    this.stopMoving()
  }

  // 开始移动
  private startMoving() {
    this.isMoving = true
    if (this.moveTimer) {
      clearInterval(this.moveTimer)
    }
    this.moveTimer = setInterval(() => {
      const dx = this.targetX - this.playerX
      const dy = this.targetY - this.playerY
      const distance = Math.sqrt(dx * dx + dy * dy)

      if (distance < this.PLAYER_SPEED) {
        // 到达目标位置
        this.playerX = this.targetX
        this.playerY = this.targetY
      } else {
        // 按比例计算X和Y方向的移动距离
        const ratio = this.PLAYER_SPEED / distance
        this.playerX += dx * ratio
        this.playerY += dy * ratio
      }
    }, this.GAME_INTERVAL)
  }

  // 停止移动
  private stopMoving() {
    this.isMoving = false
    clearInterval(this.moveTimer)
  }

  // 开始计时器
  private startGameTimer() {
    this.gameTimeTimer = setInterval(() => {
      this.gameTime += this.TIME_UPDATE_INTERVAL
    }, this.TIME_UPDATE_INTERVAL)
  }

  // 停止计时器
  private stopGameTimer() {
    if (this.gameTimeTimer) {
      clearInterval(this.gameTimeTimer)
      this.gameTimeTimer = 0
    }
  }

  // 获取当前敌机生成间隔
  private getCurrentEnemySpawnInterval(): number {
    // 每10秒减少500ms，直到达到最小间隔
    const reduction = Math.floor(this.gameTime / 10000) * 500
    return Math.max(
      this.MIN_ENEMY_SPAWN_INTERVAL,
      this.INITIAL_ENEMY_SPAWN_INTERVAL - reduction
    )
  }
}