import { GameObject, EnemyPlane, BulletItem, PlayerPlane, Explosion } from '../model/GameModels'

@Entry
@Component
struct Index {
  // 游戏状态
  @State private isGameStarted: boolean = false
  @State private isGameOver: boolean = false
  @State private score: number = 0
  @State private gameTime: number = 0  // 游戏时间（毫秒）

  // 游戏区域尺寸
  @State private gameAreaWidth: number = 0
  @State private gameAreaHeight: number = 0

  // 玩家飞机
  @State private player: PlayerPlane = new PlayerPlane(0, 0, 50, 50)
  @State private targetX: number = 0
  @State private targetY: number = 0
  @State private isMoving: boolean = false
  private moveTimer: number = 0
  private readonly PLAYER_SPEED: number = 15

  // 游戏元素
  @State private enemies: EnemyPlane[] = []
  @State private bullets: BulletItem[] = []
  @State private explosions: Explosion[] = []

  // 游戏循环定时器
  private gameTimer: number = 0
  private readonly GAME_INTERVAL: number = 50 // 降低更新频率
  
  // 游戏参数
  private readonly PLAYER_SIZE: number = 50
  private readonly ENEMY_SIZE: number = 40
  private readonly BULLET_SIZE: number = 10
  private readonly ENEMY_SPEED: number = 3
  private readonly BULLET_SPEED: number = 8
  private readonly ENEMY_SPAWN_INTERVAL: number = 2000
  private readonly BULLET_INTERVAL: number = 200
  private readonly EXPLOSION_DURATION: number = 500
  private readonly INVINCIBLE_DURATION: number = 2000

  // 时间记录
  private lastEnemySpawnTime: number = 0
  private lastBulletTime: number = 0
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
    Column() {
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
            if (!enemy.isDestroyed) {
              Image($r('app.media.img_enemy_aircraft3'))
                .width(this.ENEMY_SIZE)
                .height(this.ENEMY_SIZE)
                .position({
                  x: enemy.x,
                  y: enemy.y
                })
                .rotate({ angle: 180 })
                .opacity(enemy.explosionState === 0 ? 1 : (1 - enemy.explosionState / 4))
            }
          })

          // 子弹
          ForEach(this.bullets, (bullet: BulletItem) => {
            Image($r('app.media.bullet'))
              .width(this.BULLET_SIZE)
              .height(this.BULLET_SIZE * 2)
              .position({
                x: bullet.x,
                y: bullet.y
              })
          })

          // 玩家飞机
          Image($r('app.media.img_player_aircraft1'))
            .width(this.PLAYER_SIZE)
            .height(this.PLAYER_SIZE)
            .position({
              x: this.player.x,
              y: this.player.y
            })
            .opacity(this.player.invincible ? 0.5 : 1)

          // 状态显示
          Row() {
            Column() {
              Text(`时间: ${(this.gameTime / 1000).toFixed(1)}s`)
                .fontSize(24)
                .fontColor(Color.Black)
                .margin({ bottom: 5 })
              
              Text(`得分: ${this.score}`)
                .fontSize(24)
                .fontColor(Color.Black)
              
              Text(`生命: ${this.player.lives}`)
                .fontSize(24)
                .fontColor(Color.Black)
                .margin({ top: 5 })
            }
            .backgroundColor('rgba(255, 255, 255, 0.7)')
            .padding(10)
            .borderRadius(15)
            .margin({ left: 20, top: 20 })
          }
          .alignItems(VerticalAlign.Top)
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
    this.explosions = []
    this.gameTime = 0  // 重置游戏时间
    
    this.initializePlayerPosition()
    this.startGameLoop()
    this.startGameTimer()  // 启动计时器
  }

  // 修改初始化飞机位置的方法
  private initializePlayerPosition() {
    // 计算飞机的初始位置（屏幕底部中间）
    this.player.x = (this.gameAreaWidth - this.PLAYER_SIZE) / 2  // 居中
    this.player.y = this.gameAreaHeight * 0.75  // 在屏幕3/4处
    
    // 同步目标位置
    this.targetX = this.player.x
    this.targetY = this.player.y
  }

  // 修改发射子弹的方法
  private fireBullet() {
    // 从飞机顶部中心发射子弹
    const bulletX = this.player.x + (this.PLAYER_SIZE - this.BULLET_SIZE) / 2
    const bulletY = this.player.y  // 从飞机当前位置发射
    
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
    this.explosions = []
    
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
    const currentTime = new Date().getTime()

    // 更新无敌状态
    if (this.player.invincible) {
      this.player.invincibleTimer -= this.GAME_INTERVAL
      if (this.player.invincibleTimer <= 0) {
        this.player.invincible = false
      }
    }

    // 更新敌机状态
    this.enemies = this.enemies.filter(enemy => {
      if (enemy.explosionState > 0) {
        enemy.explosionState++
        return enemy.explosionState <= 4
      }
      enemy.y += this.ENEMY_SPEED
      return enemy.y < this.gameAreaHeight
    })

    // 更新子弹位置
    this.bullets = this.bullets.filter(bullet => {
      bullet.y -= this.BULLET_SPEED
      return bullet.y > -this.BULLET_SIZE
    })

    // 检查碰撞
    this.checkCollisions()

    // 生成新的敌机
    if (currentTime - this.lastEnemySpawnTime > this.ENEMY_SPAWN_INTERVAL) {
      this.spawnEnemy()
      this.lastEnemySpawnTime = currentTime
    }

    // 发射子弹
    if (currentTime - this.lastBulletTime > this.BULLET_INTERVAL) {
      this.fireBullet()
      this.lastBulletTime = currentTime
    }
  }

  // 生成敌机
  private spawnEnemy() {
    const x = Math.random() * (this.gameAreaWidth - this.ENEMY_SIZE)
    console.info(`Spawning enemy at x: ${x}, y: -${this.ENEMY_SIZE}`)
    this.enemies.push(new EnemyPlane(x, -this.ENEMY_SIZE, this.ENEMY_SIZE, this.ENEMY_SIZE))
    console.info(`Current enemies count: ${this.enemies.length}`)
  }

  // 碰撞检测
  private checkCollisions() {
    // 检查子弹和敌机的碰撞
    this.bullets.forEach((bullet, bulletIndex) => {
      this.enemies.forEach((enemy) => {
        if (!enemy.isDestroyed && this.isColliding(bullet, enemy)) {
          enemy.explosionState = 1
          enemy.isDestroyed = true
          this.score += 10
          this.bullets.splice(bulletIndex, 1)
        }
      })
    })

    // 检查玩家和敌机的碰撞
    if (!this.player.invincible) {
      this.enemies.forEach((enemy) => {
        if (!enemy.isDestroyed && this.isColliding(this.player, enemy)) {
          enemy.explosionState = 1
          enemy.isDestroyed = true
          this.player.lives--
          if (this.player.lives <= 0) {
            this.gameOver()
          } else {
            this.player.invincible = true
            this.player.invincibleTimer = this.INVINCIBLE_DURATION
          }
        }
      })
    }
  }

  private createExplosion(x: number, y: number) {
    this.explosions.push(new Explosion(x, y, this.ENEMY_SIZE, this.ENEMY_SIZE))
  }

  private updateExplosions() {
    this.explosions.forEach((explosion, index) => {
      explosion.frame++
      if (explosion.frame >= 5) {
        this.explosions.splice(index, 1)
      }
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
      const dx = this.targetX - this.player.x
      const dy = this.targetY - this.player.y
      const distance = Math.sqrt(dx * dx + dy * dy)

      if (distance < this.PLAYER_SPEED) {
        // 到达目标位置
        this.player.x = this.targetX
        this.player.y = this.targetY
      } else {
        // 按比例计算X和Y方向的移动距离
        const ratio = this.PLAYER_SPEED / distance
        this.player.x += dx * ratio
        this.player.y += dy * ratio
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
}