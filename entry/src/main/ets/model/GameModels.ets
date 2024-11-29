export class GameObject {
  x: number
  y: number
  width: number
  height: number

  constructor(x: number, y: number, width: number, height: number) {
    this.x = x
    this.y = y
    this.width = width
    this.height = height
  }
}

export class EnemyPlane extends GameObject {
  constructor(x: number, y: number, width: number, height: number) {
    super(x, y, width, height)
  }
}

export class BulletItem extends GameObject {
  constructor(x: number, y: number, width: number, height: number) {
    super(x, y, width, height)
  }
} 