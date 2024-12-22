-- This was my first Starfall script. Written to learn how to use it.

--@name Falling Stars
--@author Jacbo
--@client
-- Translated from https://codepen.io/chriscourses/pen/PzONKR

render.createRenderTarget("screen")
render.createRenderTarget("star")


local stars = {}
local particles = {}
local groundHeight = 0
local sizeMult = 1
--local sizeMult = 10
local targetInterval = 1/0.01
local sizeLoss = 2*sizeMult
--local sizeLoss = 0
local edgeOffset = 0
--local edgeOffset = 0
local minStarDelay = 0.75
local maxStarDelay = 2
local fps = 60
local nextFrameTime = timer.curtime()

local nextStarTime = timer.curtime()+math.random(minStarDelay,maxStarDelay)
local starMat = material.create("UnlitGeneric")
local bgMat = material.create("UnlitGeneric")
local bgLoaded = false

local makeParticle = function(x,y,dx,dy)
    table.insert(particles,{
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        radius = 2*sizeMult,
        gravity = 0.09*targetInterval,
        friction = 0.88,
        timeToLive = 2,
        maxTime = 2,
        opacity = 1
    })
end

local makeStar = function()
    local radius = (math.random()*10+5)*sizeMult
    table.insert(stars,{
        radius = radius,
        x = radius-radius/2+(1024-radius*1.5)*math.random(),
        y = -radius,
        dx = (math.random()-0.5)*20,
        dy = 30,
        friction = 0.54,
        gravity = 0.5*targetInterval
    })
end

local explode = function(star)
    for i = 0, 7 do
        makeParticle(star.x,star.y,(math.random()-0.5)*5,(math.random()-0.5)*15)
    end
end

local updateParticles = function(timeElapsed)
    local i = 1
    while i <= #particles do
        part = particles[i]
        part.timeToLive = part.timeToLive-timeElapsed
        if part.timeToLive>0 then
            if part.y+part.radius>=1023-groundHeight then
                part.dy = -part.dy*part.friction
                part.dx = part.dx*part.friction
            else
                part.dy = part.dy+part.gravity*timeElapsed
            end
            
            if part.x+part.radius>=1023-edgeOffset or part.x-part.radius<=edgeOffset then
                part.dx = -part.dx*part.friction
            end
            
            part.x = math.clamp(part.x+part.dx*timeElapsed*targetInterval,part.radius+edgeOffset,1023-part.radius-edgeOffset)
            part.y = math.min(part.y+part.dy*timeElapsed*targetInterval,1023-groundHeight-part.radius)
            
            --part.opacity = 1/(1-part.timeToLive/part.maxTime)
            part.opacity = 255*part.timeToLive/part.maxTime
        else
            table.remove(particles,i)
            i = i-1
        end
        i = i+1
    end
end

local updateStars = function(timeElapsed)
    local i = 1
    while i <= #stars do
        star = stars[i]
        if star.y+star.radius>=1023-groundHeight then
            star.dy = -star.dy*star.friction
            star.dx = star.dx*star.friction
            star.radius = star.radius-sizeLoss
            explode(star)
        else
            star.dy = star.dy+star.gravity*timeElapsed
        end
        
        if star.x+star.radius>=1023-edgeOffset or star.x-star.radius<=edgeOffset then
            star.dx = -star.dx*star.friction
            star.radius = star.radius-sizeLoss
            explode(star)
        end
        
        if star.radius<=0 then
            table.remove(stars,i)
            i = i-1
        else
            star.x = math.clamp(star.x+star.dx*timeElapsed*targetInterval,star.radius+edgeOffset,1023-star.radius-edgeOffset)
            star.y = math.min(star.y+star.dy*timeElapsed*targetInterval,1023-groundHeight-star.radius)
        end
        i = i+1
    end
end

local drawParticles = function()
    render.selectRenderTarget("screen")
    render.setMaterial(starMat)
    for i, part in pairs(particles) do
        render.setColor(Color(255,255,255,math.clamp(part.opacity,0,255)))
        render.drawTexturedRect(
            part.x-part.radius*3,
            part.y-part.radius*3,
            part.radius*6,part.radius*6)
    end
end

local drawStars = function()
    render.selectRenderTarget("screen")
    render.setColor(Color(255,255,255))
    render.setMaterial(starMat)
    for i, star in pairs(stars) do
        render.drawTexturedRect(
            star.x-star.radius*3,
            star.y-star.radius*3,
            star.radius*6,star.radius*6)
    end
end

local init = false
local oldTime = timer.curtime()
local starLoaded = false
starMat:setTextureURL("$basetexture","https://i.imgur.com/NGP2PCD.png",function()
    starLoaded = true
end)
--bgMat:setTextureURL("$basetexture","https://i.imgur.com/w0vzH9Q.png",function()
bgMat:setTextureURL("$basetexture","https://i.imgur.com/MxWbiRp.png",function()
    bgLoaded = true
end)

hook.add("think","",function()
    if timer.curtime()>=nextStarTime then
        nextStarTime = nextStarTime+math.random(minStarDelay,maxStarDelay)
        makeStar()
    end
end)
--for drawing
hook.add("renderoffscreen","",function()
    local time = timer.curtime()
    if time >= nextFrameTime then
        nextFrameTime = nextFrameTime + 1/fps
        local timeElapsed = time-oldTime
        oldTime = time
        render.selectRenderTarget("screen")
        render.clear()
        if bgLoaded then
            render.setColor(Color(255,255,255))
            render.setMaterial(bgMat)
            render.drawTexturedRect(0,0,1024,1024)
        end
        if starLoaded then
            updateStars(timeElapsed)
            updateParticles(timeElapsed)
            drawStars()
            drawParticles()
        end
        --[[render.setColor(Color(255,0,0))
        render.drawLine(edgeOffset,edgeOffset,1023-edgeOffset,edgeOffset)
        render.drawLine(edgeOffset,edgeOffset,0,1023-edgeOffset)
        render.drawLine(1023-edgeOffset,edgeOffset,1023-edgeOffset,1023-edgeOffset)
        render.drawLine(edgeOffset,1023-edgeOffset,1023-edgeOffset,1023-edgeOffset)]]
    end
end)

hook.add("render","",function()
    render.setRenderTargetTexture("screen")
    render.drawTexturedRect(0,0,512,512)
end)

--[[render.drawTexturedRect()
[nil] pizza tim`s jit compiler: after doing
[Moderator] Jacbo: oh ok
[nil] pizza tim`s jit compiler: render.setRenderTargetTexture("star")
]]

--[[
        var canvas = document.querySelector('canvas');
        var c = canvas.getContext('2d');

        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        window.addEventListener("resize", function() {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;        
        });

  
    /*
    * ------------------------------------------
    * *-----------------------------
    *  Design
    * *-----------------------------
    * ------------------------------------------
    */

        function Star() {
            this.radius = (Math.random() * 10) + 5;
            this.x = this.radius + (canvas.width - this.radius * 2) * Math.random();
            this.y = -10; 
            this.dx = (Math.random() - 0.5) * 20;
            this.dy = 30;
            this.gravity = .5;
            this.friction = .54;

            this.update = function() {

                // Bounce particles off the floor of the canvas
                if (this.y + this.radius + this.dy >= canvas.height - groundHeight) {
                    this.dy = -this.dy * this.friction;
                    this.dx *= this.friction;
                    this.radius -= 3;

                    explosions.push(new Explosion(this));
                } else {
                    this.dy += this.gravity;
                }

                // Bounce particles off left and right sides of canvas
                if (this.x + this.radius + this.dx >= canvas.width || this.x - this.radius + this.dx < 0) {
                    this.dx = -this.dx;
                    this.dx *= this.friction;
                    explosions.push(new Explosion(this));
                };

                // Move particles by velocity
                this.x += this.dx;
                this.y += this.dy;

                this.draw();

                // Draw particles from explosion
                for (var i = 0; i < explosions.length; i++) {
                    explosions[i].update();
                }

            }
            this.draw = function() {
                c.save();
                c.beginPath();
                c.arc(this.x, this.y, Math.abs(this.radius), 0, Math.PI * 2, false);

                c.shadowColor = '#E3EAEF';
                c.shadowBlur = 20;
                c.shadowOffsetX = 0;
                c.shadowOffsetY = 0;

                c.fillStyle = "#E3EAEF";
                c.fill();
                c.closePath();
                c.restore();
            }
        }

        function Particle(x, y, dx, dy) {
            this.x = x;
            this.y = y; 
            this.size = {
                width: 2,
                height: 2
            };
            this.dx = dx;
            this.dy = dy;
            this.gravity = .09;
            this.friction = 0.88;
            this.timeToLive = 3;
            this.opacity = 1;

            this.update = function() {
                if (this.y + this.size.height + this.dy >= canvas.height - groundHeight) {
                    this.dy = -this.dy * this.friction;
                    this.dx *= this.friction;
                } else {
                    this.dy += this.gravity;
                }

                if (this.x + this.size.width + this.dx >= canvas.width || this.x + this.dx < 0) {
                    this.dx = -this.dx;
                    this.dx *= this.friction;
                };
                this.x += this.dx;
                this.y += this.dy;

                this.draw();

                this.timeToLive -= 0.01;
                this.opacity -= 1 / (this.timeToLive / 0.01);
            }
            this.draw = function() {
                c.save();
                c.fillStyle = "rgba(227, 234, 239," + this.opacity + ")";
                c.shadowColor = '#E3EAEF';
                c.shadowBlur = 20;
                c.shadowOffsetX = 0;
                c.shadowOffsetY = 0;
                c.fillRect(this.x, this.y, this.size.width, this.size.height);
                c.restore();
            }

            this.isAlive = function() {
                return 0 <= this.timeToLive;
            }
        }

        function Explosion(star) {
            this.particles = [];

            this.init = function(parentStar) {
                for (var i = 0; i < 8; i++) {
                    var velocity = {
                        x: (Math.random() - 0.5) * 5,
                        y: (Math.random() - 0.5) * 15, 
                    }
                    this.particles.push(new Particle(parentStar.x, parentStar.y, velocity.x, velocity.y));
                }
            }

            this.init(star);

            this.update = function() {
                for (var i = 0; i < this.particles.length; i++) {
                    this.particles[i].update();
                    if (this.particles[i].isAlive() == false) {
                        this.particles.splice(i, 1);
                    }
                }
            }
        }


        function createMountainRange(mountainAmount, height,  color) {
            for (var i = 0; i < mountainAmount; i++) {
                var mountainWidth = canvas.width / mountainAmount;

                // Draw triangle
                c.beginPath();
                c.moveTo(i * mountainWidth, canvas.height);
                c.lineTo(i * mountainWidth + mountainWidth + 325, canvas.height);

                // Triangle peak
                c.lineTo(i * mountainWidth + mountainWidth / 2, canvas.height - height);
                c.lineTo(i * mountainWidth - 325, canvas.height);
                c.fillStyle = color;
                c.fill();
                c.closePath();
            }
        }

        function MiniStar() {
            this.x = Math.random() * canvas.width;
            this.y = Math.random() * canvas.height;
            this.radius = Math.random() * 3;

            this.draw = function() {
                c.save();
                c.beginPath();
                c.arc(this.x, this.y, this.radius, 0, Math.PI * 2, false);

                c.shadowColor = '#E3EAEF';
                c.shadowBlur = (Math.random() * 10) + 10;
                c.shadowOffsetX = 0;
                c.shadowOffsetY = 0;

                c.fillStyle = "white";
                c.fill();

                c.closePath();    
                c.restore();
            }
        }


    /*
    * ------------------------------------------
    * *-----------------------------
    *  Implementation
    * *-----------------------------
    * ------------------------------------------
    */
  
        var timer = 0;
        var stars = [];
        var explosions = [];
        var groundHeight = canvas.height * 0.15;
        var randomSpawnRate = Math.floor((Math.random() * 25) + 60)
        var backgroundGradient = c.createLinearGradient(0,0,0, canvas.height);
        backgroundGradient.addColorStop(0,"#171e26");
        backgroundGradient.addColorStop(1,"#3f586b");

        var miniStars = [];
        for (var i = 0; i < 150; i++) {
            miniStars.push(new MiniStar());
        }

  


        function animate() {
            window.requestAnimationFrame(animate);
            c.fillStyle = backgroundGradient;
            c.fillRect(0, 0, canvas.width, canvas.height);

            for (var i = 0; i < miniStars.length; i++) {
                miniStars[i].draw();
            }
            createMountainRange(1, canvas.height - 50, "#384551");
            createMountainRange(2, canvas.height - 100,  "#2B3843");
            createMountainRange(3, canvas.height - 300 , "#26333E");

            c.fillStyle = "#182028";
            c.fillRect(0, canvas.height - groundHeight, canvas.width, groundHeight);

                
            
            for (var i = 0; i < stars.length; i++) {
                stars[i].update();
                // console.log(stars[0].isAlive());

                if (stars[i].radius <= 0) {
                    stars.splice(i, 1);
                }
            }

            for (var i = 0; i < explosions.length; i++) {
                if (explosions[i].length <= 0) {
                    explosions.splice(i, 1);
                }
            }

            timer ++;
            // console.log(timer);
            if (timer % randomSpawnRate == 0) {
                stars.push(new Star());
                randomSpawnRate = Math.floor((Math.random() * 10) + 75)
            }

        }

        animate();
]]