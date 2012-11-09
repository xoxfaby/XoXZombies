function love.load()
	gamestate = "game"
	
	turretshot = love.audio.newSource("turret.wav", "static")
	playershot = love.audio.newSource("gun.wav", "static")
	buysound = love.audio.newSource("buy.wav", "static")
	reloadsound = love.audio.newSource("reload.wav", "static")
	
	turretbase = love.graphics.newImage("turretbase.png")
	turrettop	= love.graphics.newImage("turrettop.png")
	
	
	nextzombie = 1.5
	
	env = {playersize = 12}
	
	weaps = {}
	weaps.pistol = { name = "Pistol", dmg = 33.34, bulletspeed = 1000, bulletsize = 2, delay = 150, auto = false, mag = 10 }
	weaps.mst = { name = "M16", dmg = 25, bulletspeed = 1000, bulletsize = 2, delay = 50, auto = true, mag = 30 }
	
	weaps.turret = {}
	weaps.turret.ninemm = { dmg = 10, bulletspeed = 1000, bulletsize = 2, delay = 150 }
	
	player =  { typ = "player", score = 0, health = 100, armor = 0, stamina = 100, money = 999999, x = 250, y = 250, ammo = 100, clip = 10, weap = weaps.pistol, canFire = true, autoreload = false, moneyheal = false, autobuy = false }
	shotwait = 0
	zombies = {}
	bullets = {}
	turrets = {}
	shop = {}
	shop.items = {}
	shop.weaps = {}
	shop.rects = {}
	
	shopItems()
	
	nextzombiehealth = 100
	
	itemQueue = {}
	
	math.randomseed( os.time() )
	
	love.graphics.setMode( 1600, 900, false, true, 2 )
	
	love.graphics.setBackgroundColor( 250, 250, 250 )
	
end

function shopItems()
	shop.items[1] = {name = "Automatic Reload", desc = "Automatic Gun Reloading!", price = 500, onBuy = function() player.autoReload = true end}
	shop.items[2] = {name = "Turret", desc = "A turret will shoot zombies for you :D", price = 1000, onBuy = function() itemQueue[#itemQueue + 1] = "turret" end}
	shop.items[3] = {name = "Ammo", desc = "Buy 100 rounds", price = 100, onBuy = function() player.ammo = player.ammo + 100 end}
	shop.items[4] = {name = "Health", desc = "Restore your health", price = 100, onBuy = function() player.health = 100 end}
	shop.items[5] = {name = "Armor", desc = "Restore your armor", price = 150, onBuy = function() player.armor = 100 end}
	
	shop.weaps[1] = {name = "M16", price = 300, onBuy = function() player.weap = weaps.mst end}
end

function love.update(dt)
	if gamestate == "menu" then
	
	elseif gamestate == "shop" then
		
	elseif gamestate == "game" then
	
		for i, v in ipairs(zombies) do
			if v.health <= 0 then
				table.remove(zombies, i)
				player.money = player.money + 20
				player.score = player.score + 20
			end
		end
		
		if player.autoReload then
			if player.clip <= 0 and player.ammo > 0 then
				reloadGun()
			end
		end
		
		if nextzombie < 0 then
			nextzombie = math.random(1,6) / 2
			spawnrandomzombie(nextzombiehealth)
			nextzombiehealth = nextzombiehealth + 0.5
		else
			nextzombie = nextzombie - 1 * dt
		end
		
		bulletMovement(dt)
		zombieMovement(dt)
		
		collisions()
		
		findTargets()
		
		fireTurrets(dt)
		
		mouseX = love.mouse.getX()
		mouseY = love.mouse.getY()

		
		if not player.canFire then
			if player.weap.delay  < shotwait then
				shotwait = 0
				player.canFire = true
			else
				shotwait = shotwait + 1000 * dt
			end
		end
		
		
		
		
		if love.mouse.isDown("l") then
			if player.weap.auto then
				if player.canFire then
					firebullet(love.mouse.getX(), love.mouse.getY(), player)
					player.canFire = false
					shotwait = 0
				end
			end
		end
	
	------------------------------ KEYS ----------------------------------
	
		if love.keyboard.isDown("lshift") then
			if player.stamina > 0 then
				if love.keyboard.isDown("w") then
					player.y = player.y - 200 * dt
				end
				if love.keyboard.isDown("s") then
					player.y = player.y + 200 * dt
				end
				if love.keyboard.isDown("a") then
					player.x = player.x - 200 * dt
				end
				if love.keyboard.isDown("d") then
					player.x = player.x + 200 * dt
				end
				player.stamina = player.stamina - 1
			else
				if love.keyboard.isDown("w") then
					player.y = player.y - 100 * dt
				end
				if love.keyboard.isDown("s") then
					player.y = player.y + 100 * dt
				end
				if love.keyboard.isDown("a") then
					player.x = player.x - 100 * dt
				end
				if love.keyboard.isDown("d") then
					player.x = player.x + 100 * dt
				end
			end
		else
			if player.stamina < 100 then
				player.stamina = player.stamina + 0.1
			end
			if love.keyboard.isDown("w") then
				player.y = player.y - 100 * dt
			end
			if love.keyboard.isDown("s") then
				player.y = player.y + 100 * dt
			end
			if love.keyboard.isDown("a") then
				player.x = player.x - 100 * dt
			end
			if love.keyboard.isDown("d") then
				player.x = player.x + 100 * dt
			end
		end
	end
end

function fireTurrets(dt)
	for i, v in ipairs(turrets) do
		if v.target ~= nil then
			if v.canFire then
				firebullet(v.target.x, v.target.y, v)
				v.shotwait = 0
				v.canFire = false
			else
				if v.weap.delay < v.shotwait then
					v.shotwait = 0
					v.canFire = true
				else
					v.shotwait = v.shotwait + 1000 * dt
				end		
			end
		end
	end
end

function findTargets()
	for i, v in ipairs(turrets) do
		local lowestdist = 1000000 
		if #zombies > 0 then
			for zi, zv in ipairs(zombies) do
				zdist = math.abs( v.x - zv.x ) + math.abs( v.y - zv.y )
				if zdist < lowestdist then
					v.target = zv
					lowestdist = zdist
				end
			end
		else 
			v.target = nil
		end
	end
end

function collisions()
	for i, v in ipairs(bullets) do
		for zi, zv in ipairs(zombies) do
			if v.x + v.size > zv.x - env.playersize and v.x - v.size < zv.x + env.playersize and v.y + v.size > zv.y - env.playersize and v.y - v.size < zv.y + env.playersize then
				zv.health = zv.health - v.dmg
				table.remove(bullets, i)
				break
			end
		end
	end
end

function zombieMovement(dt)
	for i, v in ipairs(zombies) do	
		if v.age > 10 then
			v.speed = v.speed + 0.03
		end
	
		local angle = math.atan2((v.y - player.y), (v.x - player.x))
	
		local vDx = v.speed * math.cos(angle)
		local vDy = v.speed * math.sin(angle)
		
		v.x = v.x - vDx * dt
		v.y = v.y - vDy * dt
		
		v.age = v.age + 1 * dt
	end
	
end

function bulletMovement(dt)
		for i, v in ipairs(bullets) do
			if v.age > 10 then
				table.remove(bullets, i)
			else
				v.x = v.x + v.dx * dt
				v.y = v.y + v.dy * dt
				v.age = v.age + 1 * dt
			end
		end
end

function love.keypressed(key)
	if gamestate == "menu" then
		
	elseif gamestate == "shop" then
	
		if key == "escape" then
			gamestate = "game"
		end
		
	elseif gamestate == "paused" then 
	
		if key == "p" then
			gamestate = "game"
		end
	
	elseif gamestate == "game" then
		
		if key == "r" then
			reloadGun()
		end
		if key == "q" then
			gamestate = "shop"
		end
		if key == "p" then
			gamestate = "paused"
		end
		
	end
end

function reloadGun()
		local switch = math.min( player.ammo, player.weap.mag )
		player.ammo = player.ammo - switch
		player.clip = switch
		
		if reloadsound:isStopped() then
						reloadsound:play()
					else
						reloadsound:rewind()
					end
end

function love.mousepressed(x, y, button)
	if gamestate == "menu" then
	elseif gamestate == "shop" then
		
		for i,v in ipairs(shop.rects) do
		
			if x > v.x and x < v.x + 250 and y > v.y and y < v.y + 49 then
			
				if v.item.price <= player.money then
				
					player.money = player.money - v.item.price
					
					if buysound:isStopped() then
						buysound:play()
					else
						buysound:rewind()
					end
					
					v.item.onBuy()
				
				end
			
			end
			
		end
		
	elseif gamestate == "game" then 
		if button == "l" then
			if not player.weap.auto then
				if player.canFire then
					firebullet(x, y, player)
					player.canFire = false
					shotwait = 0
				end
			end
		elseif button == "r" then
			if itemQueue[1] ~= nil then
				if itemQueue[1] == "turret" then
				createTurret(x, y)
				table.remove(itemQueue, 1)
				elseif itemQueue[1] == "" then
					
				elseif itemQueue[1] == ""then
					
				elseif itemQueue[1] == "" then
					
				end
			end
		end
	end
end

function firebullet(x , y, shooter)
	if player.clip > 0 or shooter ~= player then
		if shooter == nil then 
			shooter = player
		end
		local mouseX = x
		local mouseY = y
		
		local angle = math.atan2((mouseY - shooter.y), (mouseX - shooter.x))
		
		local startX =  shooter.x + ( ( env.playersize * 2 - ( env.playersize / 4 ) ) * math.cos(angle) )
		local startY =  shooter.y + ( ( env.playersize * 2 - ( env.playersize / 4 ) ) * math.sin(angle) )
		
		local bulletDx = shooter.weap.bulletspeed * math.cos(angle)
		local bulletDy = shooter.weap.bulletspeed * math.sin(angle)
		
		bullets[#bullets + 1] = {x = startX, y = startY, dx = bulletDx, dy = bulletDy, age = 0, shooter = shooter, size = shooter.weap.bulletsize, dmg = shooter.weap.dmg }
		
		if shooter == player then
		
			if playershot:isStopped() then
				playershot:play()
			else
				playershot:rewind()
			end
		
			player.clip = player.clip - 1
		else 
			if turretshot:isStopped() then
				turretshot:play()
			else
				turretshot:rewind()
			end
		end
	end
end

function createTurret(x, y)
	turrets[#turrets + 1] = {typ = "turret", x = x, y = y, weap = weaps.turret.ninemm , canFire = true, shotwait = 0 }
end

function spawnzombie(x, y, health, speed)
	
	zspeed = 80	

	if speed ~= nil then 
		zspeed = speed
	end
	zombies[#zombies + 1] = {x = x, y = y, health = health, maxhealth = health, speed = zspeed , age = 0}

end

function spawnrandomzombie(health)
	local randx = math.random( 10, 1590 )
	local randy = math.random( 10, 890)
	spawnzombie(randx, randy, health)
end

function love.draw()
	
	
	if gamestate == "menu" then
	
	elseif gamestate == "shop" then
	
	drawShop()
	drawPlayerInfo()
	
	elseif gamestate == "paused" then
	
	love.graphics.print( "PAUSED", 100 , 20 )
	
	drawPlayer()
	drawPlayerInfo()
	drawBullets()
	drawZombies()
	drawTurrets()
	
	elseif gamestate == "game" then
		
	drawPlayer()
	drawPlayerInfo()
	drawBullets()
	drawZombies()
	drawTurrets()
	
	end
end

function drawPlayer()
	love.graphics.setColor( 0, 0, 0 )
	love.graphics.circle( "fill" , player.x, player.y, env.playersize)
	local angle = math.atan2((mouseY - player.y), (mouseX - player.x))
	local weaplinex =  player.x + ( ( env.playersize * 2 - ( env.playersize / 4 ) ) * math.cos(angle) )
	local weapliney =  player.y + ( ( env.playersize * 2 - ( env.playersize / 4 ) ) * math.sin(angle) )
	love.graphics.line(player.x, player.y, weaplinex, weapliney)
end

function drawPlayerInfo()
	love.graphics.print( "Healh: " .. player.health, 20 , 20 )
	love.graphics.print( "Armor: " .. player.armor, 20 , 30 )
	love.graphics.print( "Stamina: " .. math.floor(player.stamina), 20 , 40 )
	love.graphics.print( "Weapon: " .. player.weap.name, 20 , 70 )
	love.graphics.print( "Ammo: " .. player.clip .. "/" .. player.ammo, 20 , 80 )
	love.graphics.print( "Money: $" .. player.money, 20 , 60 )
	love.graphics.print( "Score: " .. player.score, 20 , 10 )
	
	if itemQueue[1] ~= nil then
		love.graphics.print( "Items left in queue: " .. #itemQueue, 20 , 100 )
		love.graphics.print( "Next item" .. itemQueue[1], 20 , 110 )
	else
	end
end

function drawZombies()
		if zombies == {} then 
	else
		for i, v in ipairs(zombies) do
			drawcolor = ( v.health / v.maxhealth ) * 100
			love.graphics.setColor( math.abs( -255 +( drawcolor * 2.5 )), drawcolor * 2.5, 0 )
			love.graphics.circle( "fill", v.x, v.y, env.playersize ) 
		end
	end
end

function drawBullets()
	if bullets == {} then
	else
		for i, v in ipairs(bullets) do
			love.graphics.setColor( 0, 0, 0 )
		
			if v.shooter.typ == "turret" then
			love.graphics.setColor( 130, 130, 255 )
			end
			love.graphics.circle( "fill", v.x, v.y, v.size ) 
		end
	end
end

function drawTurrets()
	if turrets ~= {} then
		love.graphics.setColor( 150, 150, 150 )
		for i, v in ipairs(turrets) do
			local x1 = v.x - env.playersize 
			local y1 = v.y - env.playersize 
			--love.graphics.rectangle( "fill",  x1, y1, env.playersize * 2, env.playersize * 2) 
			love.graphics.draw(turretbase, x1, y1)
			
			if v.target ~= nil then
				local angle = math.atan2((v.target.y - v.y), (v.target.x - v.x))
				local weaplinex =  v.x + ( ( env.playersize * 2 - ( env.playersize / 4 ) ) * math.cos(angle) )
				local weapliney =  v.y + ( ( env.playersize * 2 - ( env.playersize / 4 ) ) * math.sin(angle) )
				--love.graphics.line(v.x, v.y, weaplinex, weapliney)
				love.graphics.draw(turrettop, x1 + 12, y1 + 12, angle - math.rad(90), 1, 1, 12, 6 )
			end
		end
	end
end

function drawShop()
	shop.rects = {}
	love.graphics.setColor( 200, 200, 200)
	for i,v in ipairs(shop.items) do
		x1 = 150  
		y1 = 50 * i
		
		love.graphics.setColor( 200, 200, 200)
		love.graphics.rectangle( "fill", x1 , y1, 250, 49 ) 
		shop.rects[#shop.rects + 1] = {x = x1,y = y1, item = v}
		love.graphics.setColor( 100, 100, 100)
		
		love.graphics.print(  v.name , x1 + 5 , y1 + 5 )
		love.graphics.print( "Price: $" .. v.price , x1 + 7 , y1 + 20 )
		love.graphics.print( v.desc , x1 + 4 , y1 + 33 )
	end
	for i,v in ipairs(shop.weaps) do
		x1 = 401 
		y1 = 50 * i
		
		love.graphics.setColor( 200, 200, 200)
		love.graphics.rectangle( "fill", x1 , y1, 250, 49 ) 
		shop.rects[#shop.rects + 1] = {x = x1,y = y1, item = v}
		
		love.graphics.setColor( 100, 100, 100)
		love.graphics.print(  v.name , x1 + 5 , y1 + 5 )
		love.graphics.print( "Price: $" .. v.price , x1 + 7 , y1 + 20 )
	end
	--shop.items[4] = {name = "Armor", desc = "Restore your armor", price = "150", onBuy = function() player.Armor = 100 end}
	--shop.weaps[1] = {name = "M16", price = 300, onBuy = function() player.weap = weaps.mst end}
end











