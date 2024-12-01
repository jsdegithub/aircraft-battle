import { GameObject, EnemyPlane, BulletItem, PlayerPlane, Explosion } from '../model/GameModels'
import { ImageSize, PixelMapOptions } from '../model/ImageTypes'
import image from '@ohos.multimedia.image'
import common from '@ohos.app.ability.common'
import resourceManager from '@ohos.resourceManager'

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
  @State private gameTimer: number = 0
  @State private enemySpawnTimer: number = 0
  @State private shootTimer: number = 0
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

  // Canvas相关
  @State private canvasWidth: number = 0
  @State private canvasHeight: number = 0
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private renderContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // 图片资源
  @State private playerImage: Resource = $r('app.media.img_player_aircraft1')
  private playerPixelMap: image.PixelMap | null = null

  aboutToAppear() {
    // 设置游戏区域尺寸
    this.gameAreaWidth = 750
    this.gameAreaHeight = 1000
    
    // 初始化飞机位置
    this.initializePlayerPosition()

    // 加载玩家飞机图片
    void this.initPlayerImage()
  }

  private initPlayerImage(): void {
    console.info('Starting to load player image')
    const context = getContext(this) as common.UIAbilityContext
    const resourceMgr = context.resourceManager

    resourceMgr.getMediaContent(this.playerImage)
      .then(imgRes => {
        console.info('Got media content')
        return image.createImageSource(imgRes.buffer)
      })
      .then(imageSource => {
        if (!imageSource) {
          console.error('Failed to create image source')
          return null
        }
        console.info('Created image source')
        const size: ImageSize = {
          width: this.PLAYER_SIZE,
          height: this.PLAYER_SIZE
        }
        const options: PixelMapOptions = {
          desiredSize: size
        }
        return imageSource.createPixelMap(options)
      })
      .then(pixelMap => {
        if (pixelMap) {
          this.playerPixelMap = pixelMap
          console.info('Successfully loaded player image')
        } else {
          console.error('Failed to create pixel map')
        }
      })
      .catch(() => {
        console.error('Failed to load player image')
      })
  }

  private initializePlayerPosition() {
    // 计算飞机的初始位置（屏幕底部中间）
    this.player.x = (this.gameAreaWidth - this.PLAYER_SIZE) / 2  // 居中
    this.player.y = this.gameAreaHeight * 0.75  // 在屏幕3/4处
    
    // 同步目标位置
    this.targetX = this.player.x
    this.targetY = this.player.y
  }

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

  private startGameLoop() {
    this.gameTimer = setInterval(() => {
      this.updateGame()
    }, this.GAME_INTERVAL)
  }

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

    // 渲染游戏画面
    this.renderGame()
  }

  private renderGame() {
    if (!this.renderContext) return

    // 清空画布
    this.renderContext.clearRect(0, 0, this.gameAreaWidth, this.gameAreaHeight)

    // 绘制敌机
    this.enemies.forEach(enemy => {
      this.drawEnemy(enemy)
    })

    // 绘制子弹
    this.bullets.forEach(bullet => {
      this.drawBullet(bullet)
    })

    // 绘制爆炸效果
    this.explosions = this.explosions.filter(explosion => {
      if (explosion.currentFrame < explosion.totalFrames) {
        this.drawExplosionEffect(explosion)
        explosion.currentFrame++
        return true
      }
      return false
    })
  }

  private drawEnemy(enemy: EnemyPlane) {
    const ctx = this.renderContext
    const x = enemy.x
    const y = enemy.y
    const width = enemy.width
    const height = enemy.height

    // 保存当前状态
    ctx.save()
    
    // 移动到飞机中心点
    ctx.translate(x + width / 2, y + height / 2)
    // 不再旋转180度，让飞机朝上
    // 移回原点
    ctx.translate(-(x + width / 2), -(y + height / 2))

    // 设置颜色
    ctx.fillStyle = '#8B4513' // 深棕色机身
    ctx.strokeStyle = '#8B4513'
    ctx.lineWidth = 2

    // 绘制机身（细长的矩形）
    const bodyWidth = width * 0.2
    const bodyHeight = height * 0.6
    const bodyX = x + (width - bodyWidth) / 2
    const bodyY = y + height * 0.2
    ctx.fillRect(bodyX, bodyY, bodyWidth, bodyHeight)

    // 绘制机翼（两侧的三角形）
    ctx.beginPath()
    // 左机翼
    ctx.moveTo(x, y + height * 0.4)
    ctx.lineTo(x + width * 0.3, y + height * 0.4)
    ctx.lineTo(x + width * 0.3, y + height * 0.6)
    ctx.closePath()
    ctx.fill()

    // 右机翼
    ctx.beginPath()
    ctx.moveTo(x + width, y + height * 0.4)
    ctx.lineTo(x + width * 0.7, y + height * 0.4)
    ctx.lineTo(x + width * 0.7, y + height * 0.6)
    ctx.closePath()
    ctx.fill()

    // 绘制尾翼（小三角形）
    ctx.beginPath()
    ctx.moveTo(x + width * 0.4, y + height * 0.8)
    ctx.lineTo(x + width * 0.6, y + height * 0.8)
    ctx.lineTo(x + width * 0.5, y + height)
    ctx.closePath()
    ctx.fill()

    // 绘制机头（圆形）
    ctx.beginPath()
    ctx.arc(x + width / 2, y + height * 0.2, width * 0.15, 0, Math.PI * 2)
    ctx.fill()

    // 绘制装饰线条
    ctx.beginPath()
    ctx.moveTo(x + width * 0.3, y + height * 0.3)
    ctx.lineTo(x + width * 0.7, y + height * 0.3)
    ctx.stroke()

    // 恢复状态
    ctx.restore()
  }

  private drawBullet(bullet: BulletItem) {
    const ctx = this.renderContext
    
    // 绘制子弹主体（圆形）
    ctx.beginPath()
    ctx.arc(bullet.x + this.BULLET_SIZE / 2, bullet.y + this.BULLET_SIZE / 2, 
            this.BULLET_SIZE / 2, 0, Math.PI * 2)
    ctx.fillStyle = '#000000'
    ctx.fill()

    // 绘制子弹尾迹（小圆形）
    ctx.beginPath()
    ctx.arc(bullet.x + this.BULLET_SIZE / 2, bullet.y + this.BULLET_SIZE, 
            this.BULLET_SIZE / 3, 0, Math.PI * 2)
    ctx.fill()
  }

  private drawExplosionEffect(explosion: Explosion) {
    const ctx = this.renderContext
    const progress = explosion.currentFrame / explosion.totalFrames
    const radius = progress * explosion.maxRadius
    
    ctx.beginPath()
    ctx.arc(
      explosion.x + explosion.width / 2,
      explosion.y + explosion.height / 2,
      radius,
      0,
      Math.PI * 2
    )
    
    const alpha = 1 - progress
    ctx.fillStyle = `rgba(255, 100, 0, ${alpha})`
    ctx.fill()
  }

  private createExplosion(x: number, y: number, size: number) {
    this.explosions.push(new Explosion(x, y, size, size))
  }

  private spawnEnemy() {
    const x = Math.random() * (this.gameAreaWidth - this.ENEMY_SIZE)
    console.info(`Spawning enemy at x: ${x}, y: -${this.ENEMY_SIZE}`)
    this.enemies.push(new EnemyPlane(x, -this.ENEMY_SIZE, this.ENEMY_SIZE, this.ENEMY_SIZE))
    console.info(`Current enemies count: ${this.enemies.length}`)
  }

  private checkCollisions() {
    // 检查子弹和敌机的碰撞
    this.bullets.forEach((bullet, bulletIndex) => {
      this.enemies.forEach((enemy, enemyIndex) => {
        if (this.isColliding(bullet, enemy)) {
          // 创建爆炸效果
          this.createExplosion(enemy.x, enemy.y, enemy.width)
          
          // 移除子弹和敌机
          this.bullets.splice(bulletIndex, 1)
          this.enemies.splice(enemyIndex, 1)
          
          // 增加分数
          this.score += 10
        }
      })
    })

    // 检查玩家和敌机的碰撞
    if (!this.player.invincible) {
      this.enemies.forEach((enemy, index) => {
        if (this.isColliding(this.player, enemy)) {
          // 创建爆炸效果
          this.createExplosion(enemy.x, enemy.y, enemy.width)
          
          // 移除敌机
          this.enemies.splice(index, 1)
          
          // 玩家受伤
          this.player.lives--
          if (this.player.lives <= 0) {
            this.gameOver()
          } else {
            // 设置无敌状态
            this.player.invincible = true
            setTimeout(() => {
              this.player.invincible = false
            }, 2000)
          }
        }
      })
    }
  }

  private isColliding(obj1: GameObject, obj2: GameObject): boolean {
    return obj1.x < obj2.x + obj2.width &&
           obj1.x + obj1.width > obj2.x &&
           obj1.y < obj2.y + obj2.height &&
           obj1.y + obj1.height > obj2.y
  }

  private gameOver() {
    // 停止所有计时器
    if (this.gameTimer) {
      clearInterval(this.gameTimer)
      this.gameTimer = 0
    }
    if (this.enemySpawnTimer) {
      clearInterval(this.enemySpawnTimer)
      this.enemySpawnTimer = 0
    }
    if (this.shootTimer) {
      clearInterval(this.shootTimer)
      this.shootTimer = 0
    }

    // 重置游戏状态
    this.isGameStarted = false
    this.isMoving = false
    this.gameTime = 0
    this.score = 0
    this.enemies = []
    this.bullets = []
    this.explosions = []
    
    // 重置玩家状态
    this.player = new PlayerPlane(0, 0, this.PLAYER_SIZE, this.PLAYER_SIZE)

    // 强制重新渲染
    this.renderContext?.clearRect(0, 0, this.gameAreaWidth, this.gameAreaHeight)
  }

  aboutToDisappear() {
    clearInterval(this.gameTimer)
    this.stopGameTimer()  // 清理计时器
    this.stopMoving()
  }

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

  private stopMoving() {
    this.isMoving = false
    clearInterval(this.moveTimer)
  }

  private startGameTimer() {
    this.gameTimeTimer = setInterval(() => {
      this.gameTime += this.TIME_UPDATE_INTERVAL
    }, this.TIME_UPDATE_INTERVAL)
  }

  private stopGameTimer() {
    if (this.gameTimeTimer) {
      clearInterval(this.gameTimeTimer)
      this.gameTimeTimer = 0

    }
  }

  build() {
    Column() {
      if (!this.isGameStarted) {
        Column() {
          Text('飞机大战')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })
          
          if (this.score > 0) {
            Text(`游戏结束！得分：${this.score}`)
              .fontSize(30)
              .margin({ bottom: 20 })
          }
          
          Button('开始游戏')
            .width(200)
            .height(50)
            .onClick(() => {
              this.startGame()
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F1F3F5')
        .justifyContent(FlexAlign.Center)
      } else {
        Stack() {
          Canvas(this.renderContext)
            .width('100%')
            .height('100%')
            .backgroundColor('#F1F3F5')
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.canvasWidth = newValue.width as number
              this.canvasHeight = newValue.height as number
              this.gameAreaWidth = newValue.width as number
              this.gameAreaHeight = newValue.height as number
              if (!this.gameTimer) {
                this.initializePlayerPosition()
                this.startGame()
              }
            })
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

          // 玩家飞机
          Image($r('app.media.img_player_aircraft1'))
            .width(this.PLAYER_SIZE)
            .height(this.PLAYER_SIZE)
            .position({ x: this.player.x, y: this.player.y })
            .opacity(this.player.invincible ? 0.5 : 1)

          Column() {
            Text(`时间: ${(this.gameTime / 1000).toFixed(1)}s`)
              .fontSize(24)
              .fontColor(Color.Black)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 5 })
            
            Text(`得分: ${this.score}`)
              .fontSize(24)
              .fontColor(Color.Black)
              .alignSelf(ItemAlign.Start)
              .margin({ top: 5 })
            
            Text(`生命: ${this.player.lives}`)
              .fontSize(24)
              .fontColor(Color.Black)
              .alignSelf(ItemAlign.Start)
              .margin({ top: 5 })
          }
          .backgroundColor('rgba(255, 255, 255, 0.7)')
          .padding(10)
          .borderRadius(15)
          .margin({ left: 20, top: 20 })
          .position({ x: 0, y: 0 })
          .alignSelf(ItemAlign.Start)
          .width('auto')
          .zIndex(2)

        }
        .width('100%')
        .height('100%')

        if (this.isGameOver) {
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
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .justifyContent(FlexAlign.Center)
        }
      }
    }
    .width('100%')
    .height('100%')
  }

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
}