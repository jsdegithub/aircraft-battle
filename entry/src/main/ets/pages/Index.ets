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
  private readonly GAME_INTERVAL: number = 16 // 约60帧/秒
  
  // 游戏参数
  private readonly PLAYER_SIZE: number = 50
  private readonly ENEMY_SIZE: number = 40
  private readonly BULLET_SIZE: number = 8
  private readonly ENEMY_SPEED: number = 3
  private readonly BULLET_SPEED: number = 8
  private readonly ENEMY_SPAWN_INTERVAL: number = 1000 // 1秒生成一个敌机

  private lastEnemySpawnTime: number = 0
  private lastBulletTime: number = 0

  // 添加移动相关的属性
  private readonly PLAYER_SPEED: number = 10 // 飞机移动速度
  private moveTimer: number = 0 // 移动定时器
  private targetX: number = 0 // 目标X坐标
  private targetY: number = 0 // 目标Y坐标
  private isMoving: boolean = false // 是否正在移动

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
        // 游戏界面
        Column() {
          // 得分显示
          Text(`得分: ${this.score}`)
            .fontSize(30)
            .margin({ top: 20 })
            .width('100%')
            .textAlign(TextAlign.Center)

          // 游戏区域
          Stack() {
            // 玩家飞机
            Image($r('app.media.player'))
              .width(this.PLAYER_SIZE)
              .height(this.PLAYER_SIZE)
              .position({
                x: `${this.playerX}px`,
                y: `${this.playerY}px`
              })

            // 敌机
            ForEach(this.enemies, (enemy: EnemyPlane) => {
              Image($r('app.media.player'))
                .width(this.ENEMY_SIZE)
                .height(this.ENEMY_SIZE)
                .position({
                  x: `${enemy.x}px`,
                  y: `${enemy.y}px`
                })
            })

            // 子弹
            ForEach(this.bullets, (bullet: BulletItem) => {
              Circle()
                .width(this.BULLET_SIZE)
                .height(this.BULLET_SIZE)
                .fill(Color.Yellow)
                .position({
                  x: `${bullet.x}px`,
                  y: `${bullet.y}px`
                })
            })
          }
          .width('100%')
          .height('80%')
          .backgroundColor('#F1F3F5')
          .onClick((event: ClickEvent) => {
            this.targetX = event.x - this.PLAYER_SIZE / 2
            this.targetY = event.y - this.PLAYER_SIZE / 2
            
            // 确保目标位置在屏幕范围内
            this.targetX = Math.max(0, Math.min(this.targetX, px2vp(750) - this.PLAYER_SIZE))
            this.targetY = Math.max(0, Math.min(this.targetY, px2vp(1000) - this.PLAYER_SIZE))

            if (!this.isMoving) {
              this.startMoving()
            }
          })
        }
        .width('100%')
        .height('100%')
      }

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
    this.resetGame()
    this.startGameLoop()
  }

  // 重置游戏状态
  private resetGame() {
    this.score = 0
    this.isGameOver = false
    this.enemies = []
    this.bullets = []
    this.playerX = px2vp(750) / 2 - this.PLAYER_SIZE / 2
    this.playerY = px2vp(1000) - this.PLAYER_SIZE - 50
    this.lastEnemySpawnTime = 0
    this.lastBulletTime = 0
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

    // 生成敌机
    if (currentTime - this.lastEnemySpawnTime > this.ENEMY_SPAWN_INTERVAL) {
      this.spawnEnemy()
      this.lastEnemySpawnTime = currentTime
    }

    // 发射子弹
    if (currentTime - this.lastBulletTime > 200) { // 每200ms发射一颗子弹
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
    const x = Math.random() * (px2vp(750) - this.ENEMY_SIZE)
    this.enemies.push(new EnemyPlane(x, -this.ENEMY_SIZE, this.ENEMY_SIZE, this.ENEMY_SIZE))
  }

  // 发射子弹
  private fireBullet() {
    this.bullets.push(new BulletItem(
      this.playerX + this.PLAYER_SIZE / 2 - this.BULLET_SIZE / 2,
      this.playerY,
      this.BULLET_SIZE,
      this.BULLET_SIZE
    ))
  }

  // 更新敌机位置
  private updateEnemies() {
    this.enemies = this.enemies.filter(enemy => {
      enemy.y += this.ENEMY_SPEED
      return enemy.y < px2vp(1000) // 移除超出屏幕的敌机
    })
  }

  // 更新子弹位置
  private updateBullets() {
    this.bullets = this.bullets.filter(bullet => {
      bullet.y -= this.BULLET_SPEED
      return bullet.y > -this.BULLET_SIZE // 移除超出屏幕的子弹
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
    clearInterval(this.gameTimer)
    this.stopMoving()
  }

  aboutToDisappear() {
    clearInterval(this.gameTimer)
    this.stopMoving()
  }

  // 开始移动
  private startMoving() {
    this.isMoving = true
    this.moveTimer = setInterval(() => {
      const dx = this.targetX - this.playerX
      const dy = this.targetY - this.playerY
      const distance = Math.sqrt(dx * dx + dy * dy)

      if (distance < this.PLAYER_SPEED) {
        // 到达目标位置
        this.playerX = this.targetX
        this.playerY = this.targetY
        this.stopMoving()
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
}