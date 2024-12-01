export class GameObject {
  x: number
  y: number
  width: number
  height: number
  isDestroyed: boolean = false
  animationFrame: number = 0
  
  constructor(x: number, y: number, width: number, height: number) {
    this.x = x
    this.y = y
    this.width = width
    this.height = height
  }
}

export class EnemyPlane extends GameObject {
  explosionState: number = 0 // 0: 正常, 1-4: 爆炸动画帧
  
  constructor(x: number, y: number, width: number, height: number) {
    super(x, y, width, height)
  }
}

export class BulletItem extends GameObject {
  constructor(x: number, y: number, width: number, height: number) {
    super(x, y, width, height)
  }
}

export class PlayerPlane extends GameObject {
  lives: number = 3
  invincible: boolean = false
  invincibleTimer: number = 0
  
  constructor(x: number, y: number, width: number, height: number) {
    super(x, y, width, height)
  }
}

export class Explosion extends GameObject {
  frame: number = 0
  
  constructor(x: number, y: number, width: number, height: number) {
    super(x, y, width, height)
  }
}