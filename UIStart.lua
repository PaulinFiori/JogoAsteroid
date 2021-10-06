suit = require 'suit'

function love.load()
    sound = love.audio.newSource("Audios/SpaceShotButtonClick.mp3", "stream")
    optionsback = love.graphics.newImage("sprites/OptionsBack.png")
    startambient = love.audio.newSource("Audios/Flight.mp3", "stream")
    back = love.graphics.newImage("sprites/BackGroundSpace1.png")
    back2 = love.graphics.newImage("sprites/BackGroundSpace2.png")
end

local hideStartMenu = false
function love.draw()

    if hideStartMenu == false then love.graphics.draw(back, 0, 0) end

    if hideStartMenu == true then 
        love.graphics.draw(back2, 0, 0)
        love.graphics.draw(optionsback, 0, 0)
    end

    suit.draw()

end 

local Master = {value = 0, max = 1}
local fx = {value = 0, max = 1}

function love.update(dt)
    startambient:play()
  
    if hideStartMenu == false then
        if suit.Button("Start", 300,220, 200,35).hit then
            sound:play()
        end
        if suit.Button("Options", 300,270, 200,35).hit then
            sound:play()
            hideStartMenu = true;
        end
        if suit.Button("Quit", 300,320, 200,35).hit then
            love.Quit()
        end
    end

    if hideStartMenu == true then
      
        suit.Label("Ambient sound", 0,70, 300,30)
        suit.Slider(Master, 50,120, 200,30)
        suit.Label(tostring(Master.value), {align = "left"}, 280,120, 100,30)
        

        suit.Label("Effect sound", 0,170, 300,30)
        suit.Slider(fx, 50,220, 200,30)
        suit.Label(tostring(fx.value), {align = "left"}, 280,220, 100,30)


        suit.Label("Ir para frente:        ARROWUP", 470, 400, 250,30)
        suit.Label("Ir para Direita:       ARROWRIGHT", 470,430, 269,30)
        suit.Label("Ir para Esquerda:   ARROWLEFT", 470,460, 262,30)
        suit.Label("Atirar:                     Z", 470,490, 195,30)

        if suit.Button("Retrun to menu", 90,555, 200,35).hit then
            sound:play()
            hideStartMenu = false;
        end
    end

end

function love.Quit()
	love.event.quit() 
end