import csfml

const
    BACKGROUND_COLOR = color(30, 30, 40)
    WINDOW_X: cint = 800
    WINDOW_Y: cint = 600

let
    ctxSettings = ContextSettings(antialiasingLevel: 16)
    window = newRenderWindow(videoMode(WINDOW_X, WINDOW_Y), "E", settings = ctxSettings)
    shipTexture = newTexture("src/res/ship.png")
    shipSize = shipTexture.size
    bulletTexture = newTexture("src/res/bullet.png")
    bulletSize = bulletTexture.size

window.verticalSyncEnabled = true

proc newBullet(ship: Sprite): Sprite =
    result = newSprite(bulletTexture)
    result.origin = vec2(0, bulletSize.y/2)
    result.position = vec2(ship.position.x+35, ship.position.y-1.5)

proc drawSprites(window: RenderWindow, sprites: seq[Sprite]) =
    for s in sprites:
        window.draw(s)

proc updateBullets(bullets: seq[Sprite]): seq[Sprite] =
    for b in bullets:
        if b.position.x < WINDOW_X.toFloat:
            b.position = vec2(b.position.x + 10, b.position.y)
            result.add(b)
            
var
    event: Event
    ship = newSprite(shipTexture)
    bullets: seq[Sprite]
    obstacles: seq[Sprite]
    shipYMov = 0.0
    shipXMov = 0.0

ship.origin = vec2(shipSize.x / 2, shipSize.y / 2)
ship.position = vec2(WINDOW_X / 3, WINDOW_Y / 2)

while window.open:
    if window.pollEvent(event):
        case event.kind:
        of EventType.Closed:
            window.close()
            break
        of EventType.KeyPressed:
            case event.key.code:
            of KeyCode.Escape:
                window.close()
                break
            of KeyCode.Space: bullets.add(newBullet(ship))
            of KeyCode.Up: shipYMov -= 5
            of KeyCode.Down: shipYMov += 5
            of KeyCode.Right: shipXMov += 5
            of KeyCode.Left: shipXMov -= 5
            else: discard
        else: discard

    window.clear(BACKGROUND_COLOR)

    if ship.position.x + shipXMov < 40 or ship.position.x + shipXMov + (shipTexture.size.x.toFloat / 2.0) > WINDOW_X.toFloat:
        shipXMov = 0

    if (ship.position.y + shipYMov - shipTexture.size.y.toFloat/2.0) < 0 or ship.position.y + shipTexture.size.y.toFloat/2 + shipYMov > WINDOW_Y.toFloat:
        shipYMov = 0

    ship.position = vec2(ship.position.x + shipXMov, ship.position.y + shipYMov)

    window.draw(ship)
    window.drawSprites(bullets)

    window.display()

    bullets = bullets.updateBullets()
    
    if abs(shipYMov) > 0.05:
        shipYMov /= 1.2
    else:
        shipYMov = 0
    
    if abs(shipXMov) > 0.05:
        shipXMov /= 1.1
    else:
        shipXMov = 0

window.destroy()
