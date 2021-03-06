local class = require 'middleclass'
local jogo = class('jogo')

speedBuster = 10
larguraTela = love.graphics.getWidth() 
alturaTela = love.graphics.getHeight()

animacao = require("anim8")

function jogo:initialize()
    Pontos = 0
    PontosText = ""

    continuaJogando = true

    Fase = 1
    FaseText = ""
    
    Nave = love.graphics.newImage("/sprites/Nave2.png")
    Asteroid = love.graphics.newImage("/sprites/Asteroid.png")
    BackgroundA = love.graphics.newImage("/sprites/universe2.png")
    BackgroundB = love.graphics.newImage("/sprites/universe2.png")

    musicBackground = love.audio.newSource("Audios/Maximum_Impact.mp3", "static")
    shipExplosionSound = love.audio.newSource("Audios/ExplodeNave.wav", "static")
    enemyExplosionSound = love.audio.newSource("Audios/ExplodeInimigo.wav", "static")
    fireSound = love.audio.newSource("Audios/tiro.wav", "static")
    gameOver = love.audio.newSource("Audios/GameOver.ogg", "static")

    musicBackground:play()
    musicBackground:setVolume(0.8)
    musicBackground:setLooping(true)

    spriteExpInimigo = love.graphics.newImage("sprites/explosao.jpg")
    expInimigo = { }
    expInimigo.x = 0
    expInimigo.y = 0
    local gridExplosao = animacao.newGrid(64, 64, spriteExpInimigo:getWidth(), spriteExpInimigo:getHeight())
    ExplodeInimigo = animacao.newAnimation(gridExplosao('1-5', 1, '1-5', 2, '1-5', 3, '1-5', 4, '1-5', 5, '1-5', 6), 0.01, executaAnimacao)

    planoFundo =
    {
        x = 0,
        yA = 0,
        yB = 0 - BackgroundA:getHeight(),
        speed = 5 * speedBuster

    }

    arenaWidth = 800
    arenaHeight = 600

    shipRadius = 30

    bulletTimerLimit = 0.5
    bulletRadius = 5

    asteroidStages = {
        {
            speed = 120,
            radius = 15,
        },
        {
            speed = 70,
            radius = 30,
        },
        {
            speed = 50,
            radius = 50,
        },
        {
            speed = 20,
            radius = 80,
        },
    }

    function reset()
        shipX = arenaWidth / 2
        shipY = arenaHeight / 2
        shipAngle = 0
        shipSpeedX = 0
        shipSpeedY = 0

        musicBackground:play()
        musicBackground:setLooping(true)

        bullets = {}
        bulletTimer = bulletTimerLimit

        asteroids = {
            {
                x = 100,
                y = 100,
            },
            {
                x = arenaWidth - 100,
                y = 100,
            },
            {
                x = arenaWidth / 2,
                y = arenaHeight - 100,
            }
        }

        for asteroidIndex, asteroid in ipairs(asteroids) do
            asteroid.angle = love.math.random() * (2 * math.pi)
            asteroid.stage = #asteroidStages
        end

    end

    reset()
end

function jogo:update(dt)
    local turnSpeed = 10
    MovimentacaoPlanoFundo(dt)

    if continuaJogando then
    controlaExplosao(dt)

    PontosText = "Pontos: " .. Pontos
    FaseText = "Fase: " .. Fase

    if love.keyboard.isDown('right') then
         shipAngle = shipAngle + turnSpeed * dt
    end

    if love.keyboard.isDown('left') then
        shipAngle = shipAngle - turnSpeed * dt
    end

    shipAngle = shipAngle % (2 * math.pi)

    if love.keyboard.isDown('up') then
        local shipSpeed = 100
        shipSpeedX = shipSpeedX + math.cos(shipAngle) * shipSpeed * dt
        shipSpeedY = shipSpeedY + math.sin(shipAngle) * shipSpeed * dt
    end

    shipX = (shipX + shipSpeedX * dt) % arenaWidth
    shipY = (shipY + shipSpeedY * dt) % arenaHeight

    local function areCirclesIntersecting(aX, aY, aRadius, bX, bY, bRadius)
        return (aX - bX)^2 + (aY - bY)^2 <= (aRadius + bRadius)^2
    end

    for bulletIndex = #bullets, 1, -1 do
        local bullet = bullets[bulletIndex]

        bullet.timeLeft = bullet.timeLeft - dt
        if bullet.timeLeft <= 0 then
            table.remove(bullets, bulletIndex)
        else
            local bulletSpeed = 500
            bullet.x = (bullet.x + math.cos(bullet.angle) * bulletSpeed * dt)
                % arenaWidth
            bullet.y = (bullet.y + math.sin(bullet.angle) * bulletSpeed * dt)
                % arenaHeight

            for asteroidIndex = #asteroids, 1, -1 do
                local asteroid = asteroids[asteroidIndex]

                if areCirclesIntersecting(
                    bullet.x, bullet.y, bulletRadius,
                    asteroid.x, asteroid.y,
                    asteroidStages[asteroid.stage].radius
                ) then
                    table.remove(bullets, bulletIndex)
                    enemyExplosionSound:play()
                    Pontos = Pontos + 1;

                    expInimigo.x = asteroid.x
                    expInimigo.y = asteroid.y
                    table.insert(expInimigo, ExplodeInimigo)

                    if asteroid.stage > 1 then
                        local angle1 = love.math.random() * (2 * math.pi)
                        local angle2 = (angle1 - math.pi) % (2 * math.pi)

                        table.insert(asteroids, {
                            x = asteroid.x,
                            y = asteroid.y,
                            angle = angle1,
                            stage = asteroid.stage - 1,
                        })
                        table.insert(asteroids, {
                            x = asteroid.x,
                            y = asteroid.y,
                            angle = angle2,
                            stage = asteroid.stage - 1,
                        })
                    end

                    table.remove(asteroids, asteroidIndex)
                    break
                end
            end
        end
    end

    bulletTimer = bulletTimer + dt

    if love.keyboard.isDown('z') then
        if bulletTimer >= bulletTimerLimit then
            bulletTimer = 0

            table.insert(bullets, {
                x = shipX + math.cos(shipAngle) * shipRadius,
                y = shipY + math.sin(shipAngle) * shipRadius,
                angle = shipAngle,
                timeLeft = 4,
            })
        end
        fireSound:stop()
        fireSound:play()
    end

    for asteroidIndex, asteroid in ipairs(asteroids) do
        asteroid.x = (asteroid.x + math.cos(asteroid.angle)
            * asteroidStages[asteroid.stage].speed * dt) % arenaWidth
        asteroid.y = (asteroid.y + math.sin(asteroid.angle)
            * asteroidStages[asteroid.stage].speed * dt) % arenaHeight

        if areCirclesIntersecting(
            shipX, shipY, shipRadius,
            asteroid.x, asteroid.y, asteroidStages[asteroid.stage].radius
        ) then
            Pontos = 0
            Fase = 1

            shipExplosionSound:play()
            continuaJogando = false
            break
        end
    end

    if #asteroids == 0 then
        Fase = Fase + 1
        reset()
    end

    else
        musicBackground:stop()
        musicBackground:setLooping(false)
        gameOver:play()
        gameOver:stop()
    end

    if not continuaJogando and love.keyboard.isDown("r") then
        reset()
        continuaJogando = true
    end
end

function jogo:draw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(BackgroundA, planoFundo.x, planoFundo.yA);
    love.graphics.draw(BackgroundB, planoFundo.x, planoFundo.yB);
    love.graphics.setFont(love.graphics.newFont(18))

    love.graphics.setColor(255, 0 , 0)
    if not continuaJogando then
        love.graphics.print("Aperte 'r' para reiniciar.", larguraTela/3, alturaTela/2)
    end

    if continuaJogando then

        for y = -1, 1 do
            for x = -1, 1 do
                love.graphics.origin()
                love.graphics.translate(x * arenaWidth, y * arenaHeight)

                local shipCircleDistance = 40
                
                love.graphics.setColor(1,1,1)
                love.graphics.draw(Nave, shipX, shipY, shipAngle)

    
                for bulletIndex, bullet in ipairs(bullets) do
                    love.graphics.setColor(0, 1, 0)
                    love.graphics.circle('fill', bullet.x, bullet.y, bulletRadius)
                end
    
                for asteroidIndex, asteroid in ipairs(asteroids) do
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.draw(Asteroid, asteroid.x, asteroid.y,
                        asteroidStages[asteroid.stage].radius)
                end

                for i, _ in ipairs(expInimigo) do
                    ExplodeInimigo:draw(spriteExpInimigo, expInimigo.x, expInimigo.y)
                end
    
                love.graphics.setColor(255, 0 , 0)
                love.graphics.print(PontosText, 0, 0)
    
                love.graphics.setColor(255, 0 , 0)
                love.graphics.print(FaseText, love.graphics.getWidth() - 90, 0)

            end
        end
    end
end

function MovimentacaoPlanoFundo(dt)
    planoFundo.yA = planoFundo.yA + planoFundo.speed * dt
    planoFundo.yB = planoFundo.yB + planoFundo.speed * dt

    if (planoFundo.yA > alturaTela) then
        planoFundo.yA = planoFundo.yB - BackgroundA:getHeight()
    end

    if (planoFundo.yB > alturaTela) then
        planoFundo.yB = planoFundo.yA - BackgroundB:getHeight()
    end
end

function executaAnimacao()
    for i, _ in ipairs(expInimigo) do
        table.remove(expInimigo, i)
    end
end

function controlaExplosao(dt)
    for i, _ in ipairs(expInimigo) do
        ExplodeInimigo:update(dt)
    end
end

return jogo