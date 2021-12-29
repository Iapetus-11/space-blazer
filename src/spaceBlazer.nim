import std/[random, math, sets, sequtils, hashes]
import csfml/[audio]
import csfml

randomize()

type
    AsteroidSprite = ref object
        sprite: Sprite
        rotationSpeed: float

    AsteroidExplosion = ref object
        sprite: Sprite
        stage: int

const
    BACKGROUND_COLOR = color(30, 30, 40)
    WINDOW_X: cint = 800
    WINDOW_Y: cint = 600

let
    ctxSettings = ContextSettings(antialiasingLevel: 16)
    window = newRenderWindow(videoMode(WINDOW_X, WINDOW_Y), "StarBlazer Clone", settings = ctxSettings)

    shipTexture = newTexture("res/ship.png")
    shipSize = shipTexture.size

    bulletTexture = newTexture("res/bullet.png")
    bulletSize = bulletTexture.size

    enemyShipTexture = newTexture("res/enemy_ship.png")
    enemyShipSize = enemyShipTexture.size

    enemyBulletTexture = newTexture("res/enemy_bullet.png")
    enemyBulletSize = enemyBulletTexture.size

    smallExhaustTexture = newTexture("res/exhaust_small.png")
    smallExhaustSize = smallExhaustTexture.size
    
    largeExhaustTexture = newTexture("res/exhaust_large.png")
    largeExhaustSize = largeExhaustTexture.size

    asteroidTexture = newTexture("res/asteroid.png")
    asteroidSize = asteroidTexture.size

    healthPickupTexture = newTexture("res/health_pickup.png")
    healthPickupSize = healthPickupTexture.size

    font = newFont("res/Pixeled.ttf")

    laserSound = newSound(newSoundBuffer("res/laser.wav"))
    oofSound = newSound(newSoundBuffer("res/oof.wav"))
    music = newMusic("res/music.wav")

window.verticalSyncEnabled = true
window.framerateLimit = 60

laserSound.volume = 5

music.loop = true
music.volume = 0

proc hash(a: AsteroidSprite): Hash =
    return hash(a.sprite)

proc newBullet(ship: Sprite): Sprite =
    result = newSprite(bulletTexture)
    result.origin = vec2(0, bulletSize.y/2)
    result.position = vec2(ship.position.x+35, ship.position.y-1.5)

proc newEnemyBullet(ship: Sprite): Sprite =
    result = newSprite(enemyBulletTexture)
    result.origin = vec2(0, enemyBulletSize.y/2)
    result.position = vec2(ship.position.x-35, ship.position.y)

proc newAsteroid(): AsteroidSprite =
    let sprite = newSprite(asteroidTexture)

    sprite.origin = vec2(asteroidSize.x / 2, asteroidSize.y / 2)
    sprite.rotation = rand(360).cfloat
    sprite.position = vec2(WINDOW_X+asteroidSize.x, rand(WINDOW_Y - (asteroidSize.y * 2))+asteroidSize.y)

    return AsteroidSprite(sprite: sprite, rotationSpeed: rand(4) / 4)

proc newHealthPickup(): Sprite =
    result = newSprite(healthPickupTexture)

    result.origin = vec2(healthPickupSize.x / 2, healthPickupSize.y / 2)
    result.position = vec2(WINDOW_X+healthPickupSize.x, rand(WINDOW_Y - (healthPickupSize.y * 2))+healthPickupSize.y)

proc newEnemyShip(): Sprite =
    result = newSprite(enemyShipTexture)

    result.origin = vec2(enemyShipSize.x / 2, enemyShipSize.y / 2)
    result.position = vec2(WINDOW_X+enemyShipSize.x, rand(WINDOW_Y - (enemyShipSize.y * 2))+enemyShipSize.y)

proc drawSprites(window: RenderWindow, sprites: seq[Sprite]) =
    for s in sprites:
        window.draw(s)

proc drawAsteroids(window: RenderWindow, asteroids: seq[AsteroidSprite]) =
    for a in asteroids:
        window.draw(a.sprite)

proc updateBullets(bullets: seq[Sprite]): seq[Sprite] =
    for b in bullets:
        if b.position.x < WINDOW_X.toFloat:
            b.position = vec2(b.position.x + 15, b.position.y)
            result.add(b)

proc updateHealthPickups(healthPickups: seq[Sprite]): seq[Sprite] =
    for h in healthPickups:
        if h.position.x + (healthPickupSize.x / 2).cfloat > 0:
            h.position = vec2(h.position.x - 7, h.position.y)
            result.add(h)

proc drawHealth(window: RenderWindow, health: int) =
    let
        baseX = WINDOW_X - 15
        baseY = 20

    for i in 0 .. health - 1:
        let healthBox = newRectangleShape(vec2(20, 20))

        healthBox.position = vec2(baseX - (i*25), baseY)
        healthBox.origin = vec2(10, 10)
        healthBox.fillColor = color(255, 10, 10)

        window.draw(healthBox)

proc drawScore(window: RenderWindow, score: int) =
    let text = newText("Score: " & $score, font)

    text.color = color(200, 200, 200)
    text.origin = vec2(0, 0)
    text.position = vec2(10, 15)
    text.characterSize = 20

    window.draw(text)

proc drawGameOver(window: RenderWindow) =
    let text = newText("GAME OVER", font)

    text.color = color(255, 10, 10)
    text.origin = vec2(text.localBounds.width / 2, text.localBounds.height / 2)
    text.position = vec2(WINDOW_X / 2, WINDOW_Y / 2)

    window.draw(text)

proc drawShip(window: RenderWindow, ship: Sprite, eS: Sprite, eL: Sprite, moving: bool) =
    window.draw(ship)

    if moving:
        eL.position = vec2(ship.position.x-25, ship.position.y)
        window.draw(eL)
    else:
        eS.position = vec2(ship.position.x-25, ship.position.y)
        window.draw(eS)
        
proc pBulletOverlapsAsteroid(bullet: Sprite, asteroid: AsteroidSprite): bool =
    let
        sprite = asteroid.sprite
        oldRot = sprite.rotation

    sprite.rotation = 0

    var
        bGlobalBounds: FloatRect = bullet.globalBounds
        aGlobalBounds: FloatRect = sprite.globalBounds
        intersection: FloatRect = rect(1.0, 1.0, 1.0, 1.0)

    result = aGlobalBounds.intersects(bGlobalBounds, intersection)
    
    sprite.rotation = oldRot

proc pShipOverlapsAsteroid(ship: Sprite, asteroid: AsteroidSprite): bool =
    let
        sprite = asteroid.sprite
        oldRot = sprite.rotation

    sprite.rotation = 0

    var
        sGlobalBounds: FloatRect = ship.globalBounds
        aGlobalBounds: FloatRect = sprite.globalBounds
        intersection: FloatRect = rect(1.0, 1.0, 1.0, 1.0)

    sGlobalBounds.width -= 12
    sGlobalBounds.left += 6
    sGlobalBounds.height -= 12
    sGlobalBounds.top += 6

    result = aGlobalBounds.intersects(sGlobalBounds, intersection)
    
    sprite.rotation = oldRot

proc pShipOverlapsHealthPickup(ship: Sprite, healthPickup: Sprite): bool =
    var
        sGlobalBounds: FloatRect = ship.globalBounds
        hGlobalBounds: FloatRect = healthPickup.globalBounds
        intersection: FloatRect = rect(1.0, 1.0, 1.0, 1.0)

    result = hGlobalBounds.intersects(sGlobalBounds, intersection)

var
    ship = newSprite(shipTexture)

    exhaustLarge = newSprite(largeExhaustTexture)
    exhaustSmall = newSprite(smallExhaustTexture)

    running: bool
    event: Event

    bullets: seq[Sprite]
    asteroids: seq[AsteroidSprite]
    healthPickups: seq[Sprite]
    enemyShips: seq[Sprite]
    enemyBullets: seq[Sprite]
    
    shipYMove: float
    shipXMove: float

    health: int
    score: int

    bulletLimiter: int

    moving: bool

proc resetGame() =
    running = true

    ship.origin = vec2(shipSize.x / 2, shipSize.y / 2)
    ship.position = vec2(WINDOW_X / 3, WINDOW_Y / 2)

    exhaustLarge.origin = vec2(largeExhaustSize.x.toFloat, largeExhaustSize.y / 2)
    exhaustSmall.origin = vec2(smallExhaustSize.x.toFloat, smallExhaustSize.y / 2)

    shipYMove = 0.0
    shipXMove = 0.0

    health = 3
    score = 0

    bulletLimiter = 0

    bullets.setLen(0)
    asteroids.setLen(0)
    healthPickups.setLen(0)
    enemyShips.setLen(0)
    enemyBullets.setLen(0)

    moving = false

proc updateAsteroids(asteroids: seq[AsteroidSprite]): seq[AsteroidSprite] =
    for a in asteroids:
        let s = a.sprite

        if s.position.x + (asteroidSize.x / 2).cfloat > 0:
            s.position = vec2(s.position.x - 5, s.position.y)
            s.rotation = ((s.rotation + a.rotationSpeed) mod 360)
            result.add(a)
        else:
            score -= 1

proc updateEnemyShips(): seq[Sprite] =
    for s in enemyShips:
        if s.position.x + (asteroidSize.x / 2).cfloat > 0:
            s.position = vec2(s.position.x - 5, s.position.y)
            result.add(s)
        else:
            score -= 10

resetGame()
music.play()

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
            of KeyCode.Space:
                if not running:
                    resetGame()
                    sleep(milliseconds(250))
                    music.play()

            else: discard
        of EventType.Resized: window.size = vec2(WINDOW_X, WINDOW_Y)
        else: discard

    if running and (music.volume < 80):
        music.volume = music.volume + 0.1
    elif music.volume > 1:
        music.volume = music.volume / 1.1
    else:
        music.volume = 0
        music.stop()

    window.clear(BACKGROUND_COLOR)

    window.drawAsteroids(asteroids)
    window.drawSprites(healthPickups)
    window.drawSprites(enemyShips)
    window.drawShip(ship, exhaustSmall, exhaustLarge, moving)
    window.drawSprites(bullets)
    window.drawHealth(health)
    window.drawScore(score)

    if health < 1 or score < 0:
        running = false
        
        window.drawGameOver()

    window.display()

    if not running:
        continue

    if keyboard_isKeyPressed(KeyCode.Space) or keyboard_isKeyPressed(KeyCode.A):
        if bulletLimiter <= 10:
            bullets.add(newBullet(ship))
            bulletLimiter += 12
            laserSound.play()

    moving = false

    if keyboard_isKeyPressed(KeyCode.Up):
        shipYMove -= 1.75
        moving = true
    if keyboard_isKeyPressed(KeyCode.Down):
        shipYMove += 1.75
        moving = true
    if keyboard_isKeyPressed(KeyCode.Right):
        shipXMove += 1.75
        moving = true
    if keyboard_isKeyPressed(KeyCode.Left):
        shipXMove -= 1.75
        moving = true

    if bulletLimiter > 0:
        bulletLimiter -= 1

    if ship.position.x + shipXMove < 50 or ship.position.x + shipXMove + (shipTexture.size.x.toFloat / 2.0) > WINDOW_X.toFloat:
        shipXMove = 0

    if (ship.position.y + shipYMove - shipTexture.size.y.toFloat/2.0) < 0 or ship.position.y + shipTexture.size.y.toFloat/2 + shipYMove > WINDOW_Y.toFloat:
        shipYMove = 0

    ship.position = vec2(ship.position.x + shipXMove, ship.position.y + shipYMove)

    var
        newBullets = bullets.toHashSet
        newAsteroids = asteroids.toHashSet

    for a in asteroids:
        for b in bullets:
            if b.pBulletOverlapsAsteroid(a):
                newBullets.excl(b)
                newAsteroids.excl(a)
                score += 1

    asteroids = newAsteroids.toSeq
    
    for a in asteroids:
        if ship.pShipOverlapsAsteroid(a):
            newAsteroids.excl(a)
            health -= 1
            oofSound.play()

    bullets = newBullets.toSeq
    asteroids = newAsteroids.toSeq

    var newHealthPickups = healthPickups.toHashSet

    for h in healthPickups:
        if ship.pShipOverlapsHealthPickup(h):
            newHealthPickups.excl(h)

            if health < 10:
                health += 1

    healthPickups = newHealthPickups.toSeq

    bullets = bullets.updateBullets()
    asteroids = asteroids.updateAsteroids()
    healthPickups = healthPickups.updateHealthPickups()
    enemyShips = updateEnemyShips()

    if abs(shipYMove) > 0.05:
        shipYMove /= 1.2
    else:
        shipYMove = 0
    
    if abs(shipXMove) > 0.75:
        shipXMove /= 1.1

    if rand(34) == 12:
        asteroids.add(newAsteroid())

    if rand(2048) == 420:
        healthPickups.add(newHealthPickup())

    if rand(2048) == 420:
        healthPickups.add(newEnemyShip())

window.destroy()
music.stop()
music.destroy()
