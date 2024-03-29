--
-- RK_Mobj.Lua
-- Resource file Mobj-specific functions and behavior
-- 
-- 
-- Flame
--
-- Date: 3-21-21
--

RK.mobj = {}

-- Lat'
RK.mobj.spawnAura = function(mo, color)	-- spawn a aura around mo
	if leveltime%2 then return end
	if not valid(mo) then return end
	color = $ or SKINCOLOR_TEAL
	if (type(color) ~= "number") then
		error("Error: spawnAura expects a number")
		return
	end
	local baseangle = P_RandomRange(1, 360)*ANG1
	local dist = 30
	for i = 0, 12 do
		local angle = baseangle + i*6*ANG1
		local x, y = mo.x + dist*cos(angle), mo.y + dist*sin(angle)

		local aura = P_SpawnMobj(x, y, mo.z + mo.height/4 + i*FRACUNIT*3, MT_DUMMY)
		--if not valid(aura) continue end
		aura.state = S_AURA1
		aura.angle = angle - ANGLE_90
		aura.color = color
		aura.momz = P_RandomRange(2, 5)*FRACUNIT
		aura.scale = FRACUNIT/2
		aura.destscale = FRACUNIT
		P_InstaThrust(aura, angle, FRACUNIT*P_RandomRange(1, 3))
	end

	local zoffs = mo.eflags & MFE_VERTICALFLIP and -65*mo.scale or 0
	for i = 1, 8 do
		local wf = 32
		local hf = P_RandomRange(65, 1)*mo.scale*P_MobjFlip(mo)
		local x, y, z = mo.x + P_RandomRange(-wf, wf)*mo.scale, mo.y + P_RandomRange(-wf, wf)*mo.scale, mo.z + zoffs + hf
		local t = P_SpawnMobj(x, y, z, MT_DUMMY)
		t.color = color or SKINCOLOR_TEAL
		t.eflags = mo.eflags & MFE_VERTICALFLIP
		t.flags2 = mo.flags2 & MF2_OBJECTFLIP
		t.state = i==7 and S_FRAG5 or S_FRAG1
		P_SetObjectMomZ(t, P_RandomRange(4, 12)*FRACUNIT)
		t.scale = mo.scale*2
		t.destscale = 1
		t.scalespeed = mo.scale/24
	end
end

RK.mobj.spawnArrow = function(mo, target, dist)
	-- Need both a source 'mo' and a target 'mo'
	if not valid(mo) then return end
	if not valid(target) then return end
	if (type(dist) ~= "number") then
		error("Error: spawnArrow expects a number")
		return
	end
	
	local arw = P_SpawnMobj(mo.x, mo.y, mo.z + mo.height/2, MT_DUMMY)
	arw.state = S_RKAW1
	arw.angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
	arw.target = mo
	arw.color = target.color or SKINCOLOR_GREEN -- Opponent's color
	-- Fancy maths. Ensure your papersprite angle points towards your opponent.
	local ft = FixedAngle((leveltime%45)*(8*FRACUNIT))
	P_MoveOrigin(arw, mo.x + FixedMul(cos(arw.angle), 3*mo.radius + FixedMul(sin(ft), 4*FRACUNIT)),
						mo.y + FixedMul(sin(arw.angle), 3*mo.radius + FixedMul(sin(ft), 4*FRACUNIT)),
						mo.z + mo.height/2)

	-- Some more fancy maths. Grow/shrink according to your target's distance
	local tdist, zdiff = R_PointToDist2(mo.x, mo.y, target.x, target.y), (target.z - mo.z)
	local zaim = R_PointToAngle2(0, 0, tdist, zdiff) -- Use that distance to 'aim' towards your target
	local camangle = R_PointToAngle(mo.x, mo.y)
	
	-- Grow/shrink
	arw.scale = FixedDiv(FixedMul(FRACUNIT, dist), tdist)/2
	
	-- Rollangle
	if ((camangle - arw.angle) < 0) then zaim = InvAngle($) end
	arw.rollangle = zaim
end

RK.mobj.spawnSmoke = function(mo, freq)
	if not valid(mo) then return end
	freq = $ or 3
	if (type(freq) ~= "number") then
		error("Error: spawnSmoke expects a number")
		return
	end

	if not (leveltime%freq) then
		local r = mo.radius>>FRACBITS
		local smoke = P_SpawnMobj(mo.x + (P_RandomRange(-r, r)<<FRACBITS),
									mo.y + (P_RandomRange(-r, r)<<FRACBITS),
									mo.z + (P_RandomKey(mo.height>>FRACBITS)<<FRACBITS),
									MT_DUMMY)
		smoke.state = S_TNTDUST_5
		smoke.angle = R_PointToAngle2(mo.x, mo.y, smoke.x, smoke.y)
		smoke.rollangle = P_RandomKey(36)*ANG10
		P_InstaThrust(smoke, smoke.angle, FRACUNIT/2)
		P_SetObjectMomZ(smoke, FRACUNIT, false)
		smoke.scale = FRACUNIT/2
		smoke.scalespeed = FRACUNIT/(TICRATE/2)
		smoke.destscale = FRACUNIT
	end
end

RK.mobj.spawnRecoilSmoke = function(mo)
	if not valid(mo) then return end
	
	if not (leveltime%4) then
		local trail = P_SpawnMobj(mo.x,
									mo.y,
									mo.z + mo.height/2, 
									MT_DUMMY)
		trail.state = S_TNTDUST_2
		trail.colorized = true
		trail.color = mo.lastbumper.color or SKINCOLOR_GREY
		trail.angle = R_PointToAngle2(trail.x, trail.y, mo.x + mo.momx, mo.y + mo.momy) -- Always point to your target
		trail.rollangle = P_RandomKey(36)*ANG10
		trail.destscale = 2*FRACUNIT
		trail.scalespeed = FRACUNIT/(TICRATE/2)
		
		trail.flags = $|MF_NOGRAVITY
		if (mo.eflags & MFE_VERTICALFLIP) then trail.flags = $|MFE_VERTICALFLIP end
		P_InstaThrust(trail, P_RandomKey(36)*ANG10, FRACUNIT)
		P_SetObjectMomZ(trail, FRACUNIT, false)
	end
end

RK.mobj.spawnMobjPercent = function(mo)
	if (type(mo.percent) ~= "number") then
		error("Error: spawnMobjPercent mo does not have a .percent!")
		return
	end
	local nstr = tostring(mo.percent)
	local nlen = nstr:len()
	
	local num = {}
	for i = 0, 9 do -- 0 - 9 (S_NMBR0 - S_NMBR9)
		table.insert(num, S_NMBR0+i)
	end

	for i = 1, nlen do -- How long is the string?
		local n = P_SpawnMobj(mo.x + mo.momx - FixedMul(cos(R_PointToAngle(mo.x, mo.y)+ANGLE_90), ((i-1)*(16*FRACUNIT))-(nlen*(8*FRACUNIT))), 
								mo.y + mo.momy - FixedMul(sin(R_PointToAngle(mo.x, mo.y)+ANGLE_90), ((i-1)*(16*FRACUNIT))-(nlen*(8*FRACUNIT))), 
								mo.z + 5*mo.height/2, MT_DUMMY)
		--print(nstr:sub(i, 1+(i-1)))
		n.state = num[tonumber(nstr:sub(i, 1+(i-1)))+1] -- Print this character in the string
		n.angle = R_PointToAngle(mo.x, mo.y)-ANGLE_90
		n.target = mo
		n.scale = 2*FRACUNIT
	end

	-- Percent Char (S_NMBR10)
	local per = P_SpawnMobj(mo.x + mo.momx - FixedMul(cos(R_PointToAngle(mo.x, mo.y)+ANGLE_90), (nlen)*(16*FRACUNIT)-(nlen*(8*FRACUNIT))), 
								mo.y + mo.momy - FixedMul(sin(R_PointToAngle(mo.x, mo.y)+ANGLE_90), (nlen)*(16*FRACUNIT)-(nlen*(8*FRACUNIT))), 
								mo.z + 5*mo.height/2, MT_DUMMY)
	per.state = S_NMBR10
	per.angle = R_PointToAngle(mo.x, mo.y)-ANGLE_90
	per.target = mo
	per.scale = 2*FRACUNIT
end

-- Search for other player objects around 'mo' and return the count.
-- Because I hate 'searchBlockmap'
-- Flame
/*RK.mobj.CountPlayersInRadius = function(mo, dist)
	local pcount = 0
	if not valid(mo) then return pcount end
	for p in players.iterate do
		if p.spectator then continue end -- We're a spectator. Skip.
		if (p.playerstate ~= PST_LIVE) continue end -- Skip anyone not alive
		if not p.mo then continue end -- Not a mo object. Skip.
		if not valid(p.mo.rock) then continue end -- No rock to reference. Skip.
		if (p.mo.rock == mo) then continue end -- Our rock? Skip us
		if (FixedHypot(FixedHypot(p.mo.x - mo.x, p.mo.y - mo.y), 
									p.mo.z - mo.z) > dist) then
			continue -- Out of range
		end
		pcount = $ + 1
	end
	return pcount
end*/

RK.mobj.look4ClosestMo = function(mo, dist, mtype)
	if not valid(mo) then return nil end
	if not dist then dist = FixedMul(1024*FRACUNIT, mo.scale) end
	
	local closestmo
	local closestdist = dist
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if mtype and (found.type ~= mtype) then return nil end
		if (found.health <= 0) then return nil end
		--if found.player and found.player.spectator then return nil end
		
		local idist = FixedMul(FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z)), refmo.scale)
		if (idist > dist) then return nil end -- Ignore objects outside of 'dist' range.
		
		if (idist < closestdist) then
			closestmo = found
			closestdist = idist
		end
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return closestmo
end

addHook("MobjThinker", function(mo)
    if valid(mo)
    and G_IsRolloutGametype() then
		mo.percent = $ or 0
		
		if valid(mo.target) then -- Valid target
			-- Did your target player suddenly die?
			if valid(mo.target.player)
			and (mo.target.player.playerstate == PST_DEAD) then
				P_RemoveMobj(mo) -- So should you!
				return
			end
			
			-- Your ball is colored!
			if mo.colorized then
				-- If you have a lastbumper, set your color to your lastbumper for a bit!
				if valid(mo.lastbumper)
				and (mo.lastbumpertics > 9*TICRATE)
				and not (leveltime%2) then
					mo.color = mo.lastbumper.color
				else
					mo.color = mo.target.color 	-- All else, set your color to your target
				end
			end
			
			-- Percentages and Arrows
			if valid(mo.target.player) then
				local p = mo.target.player -- Simplify
				
				if (cv_rkpercentview.value == 2) then
					for m in mobjs.iterate() do
						if (m == mo) then continue end -- Skip us
						if (m.type ~= MT_ROLLOUTROCK) then continue end -- Only look for other MT_ROLLOUTROCK's
						if (m.health <= 0) then continue end -- Dead
						if (m.flags & MF_NOBLOCKMAP) or (m.flags & MF_SCENERY) then continue end -- Not Part of the blockmap. Ignore
						local dist = FixedHypot(FixedHypot(m.x - mo.x, m.y - mo.y), 2*(m.z - mo.z))
						
						if (dist < 512*FRACUNIT) then
							if (p == consoleplayer) -- Don't display for us.
							and not splitscreen then
								RK.mobj.spawnMobjPercent(m)
							end
							
							local xydist = FixedHypot(m.x - mo.x, m.y - mo.y)
							if (xydist > 8*mo.radius) then
								RK.mobj.spawnArrow(mo, m, 512*FRACUNIT)
							end
						end
					end
				elseif (cv_rkpercentview.value == 1) then
					local closestmo = RK.mobj.look4ClosestMo(mo, 512*FRACUNIT, MT_ROLLOUTROCK) -- Look for a mo that's closest to us.
					
					if closestmo -- Found one?
						if not valid(consoleplayer) then return end -- Error checking, something has gone horribly wrong.
						
						if (p == consoleplayer) -- Don't display for us.
						and not splitscreen then
							RK.mobj.spawnMobjPercent(closestmo) -- Spawn it's percent!
						end
						
						-- Distance check. Do not care about Z
						local xydist = FixedHypot(closestmo.x - mo.x, closestmo.y - mo.y)
						if (xydist > 8*mo.radius) then
							RK.mobj.spawnArrow(mo, closestmo, 512*FRACUNIT)
						end
					end
				end
				
				if (mo.target.player.weapondelay == 3) then -- Last tic before restoring dash abolity
					local g = P_SpawnGhostMobj(mo)
					g.color = mo.target.color
					g.destscale = 4*FRACUNIT
					g.scalespeed = FRACUNIT/(2*TICRATE/3)
					S_StartSound(mo, sfx_s3k8c, mo.target.player)
				end
			end
			
			-- Rock Ability stuff
			if mo.rkabilitytics and (mo.rkabilitytics > 0) then
				mo.rkabilitytics = $ - 1 -- Decrease each tic
				/*if RK.WepRings -- Weapon rings are enabled
				and mo.rkability then
					if (mo.rkability == WEP_RAIL) then
						mo.extravalue1 = $ or 0
						mo.extravalue2 = $ or 0
						mo.extravalue1 = $ + ANGLE_11hh
						mo.extravalue2 = mo.extravalue1 + ANGLE_180
						
						--if ((leveltime%2) == 0)
							local trail = P_SpawnMobj(mo.x, mo.y, mo.z, MT_THOK)
							trail.color = SKINCOLOR_WHITE
							trail.tics = 2*TICRATE
							trail.scale = 2*FRACUNIT
							trail.destscale = FRACUNIT/16
							trail.scalespeed = trail.scale/TICRATE
						--end
						
						local orb1 = P_SpawnMobj(mo.x, mo.y, mo.z, MT_THOK)
						orb1.color = mo.color or SKINCOLOR_RED
						orb1.angle = mo.extravalue1
						P_TeleportMove(orb1, 
										mo.x + FixedMul(cos(orb1.angle), 3*mo.radius/2), 
										mo.y + FixedMul(sin(orb1.angle), 3*mo.radius/2), 
										mo.z + mo.height/2)
						orb1.fuse = TICRATE/3
						orb1.destscale = FRACUNIT/16
						orb1.scalespeed = (FRACUNIT/5)
						
						local orb2 = P_SpawnMobj(mo.x, mo.y, mo.z, MT_THOK)
						orb2.color = mo.color or SKINCOLOR_RED
						orb2.angle = mo.extravalue2
						P_TeleportMove(orb2, 
										mo.x + FixedMul(cos(orb2.angle), 3*mo.radius/2), 
										mo.y + FixedMul(sin(orb2.angle), 3*mo.radius/2), 
										mo.z + mo.height/2)
						orb2.fuse = orb1.fuse
						orb2.destscale = orb1.destscale
						orb2.scalespeed = orb1.scalespeed
					end
				else*/
					if not P_IsObjectOnGround(mo) and not (leveltime%3) then 
						local g = P_SpawnGhostMobj(mo) 
						g.color = mo.target.color
					end -- Default dashing.
				--end
			else
				mo.rkability = 0
				mo.rkabilitytics = 0
			end
        else -- Oops, your target dissappeared?
			P_RemoveMobj(mo) -- So should you!
			return
        end
		
		-- Last bumper for score calculation
		if valid(mo.lastbumper) -- Validity check
		and (mo.lastbumpertics > 0) then
			mo.lastbumpertics = $ - 1
			if (mo.lastbumpertics == 1) then -- Last tic
				mo.lastbumper = nil -- Nil out your last bumper
			end
			
			-- Impact recoil. Spawn a dust trail.
			if (mo.lastbumpertics > 9*TICRATE)
			and (FixedHypot(mo.momx, mo.momy) > (20*FRACUNIT)) then
				RK.mobj.spawnRecoilSmoke(mo)
			end
		else -- mo.lastbumper not valid
			mo.lastbumpertics = 0
			mo.lastbumper = nil -- Nil out your last bumper
		end

		-- Bump count for Player Respawning
		mo.bumpcount = $ or 0
		if mo.bumpcount and (mo.bumpcounttics > 0) then
			mo.bumpcounttics = $ - 1
			if (mo.bumpcounttics == 1) then -- Last tic
				mo.bumpcount = 0 -- Reset the bump count
			end
		end
		
		if mo.fxtimer and (mo.fxtimer > 0) then
			mo.fxtimer = $ - 1
			RK.mobj.spawnAura(mo, mo.target.color)
		end
		
		-- Percentage Based goodies
		if assert(type(mo.percent) == "number") then
			if (mo.percent > 999) then mo.percent = 999 end -- Cap at 999%
			if (mo.percent >= 75) then
				local threshold = (6 - (mo.percent/50))
				if (threshold < 1) then threshold = 1 end
				RK.mobj.spawnSmoke(mo, threshold)
			end
		end
		
		/*-- Spawn an item box just for fun.
		if valid(mo.target)
		and valid(mo.target.player) then
			local cmd = mo.target.player.cmd
			if (cmd.buttons & BT_CUSTOM1) and not mo.rkabilitytics then
				local itembox = P_SpawnMobj(mo.x - FixedMul(cos(mo.target.angle), mo.radius*3), 
											mo.y - FixedMul(sin(mo.target.angle), mo.radius*3), 
											mo.z, MT_DUMMY)
				itembox.state = S_RKITEMBOX1
				itembox.flags = $ | (MF_SPECIAL) & ~(MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOCLIP)
				itembox.frame = $ & ~(FF_PAPERSPRITE)
				itembox.color = P_RandomKey(68)
				itembox.angle = mo.angle
				mo.rkabilitytics = TICRATE/2
			end
		end*/
    end
end, MT_ROLLOUTROCK)

local ringtrans_t = {TR_TRANS20, TR_TRANS30, TR_TRANS40, TR_TRANS50, TR_TRANS60, TR_TRANS70, TR_TRANS80, TR_TRANS90}
-- Item box object
addHook("MobjThinker", function(mo)
	if valid(mo)
	and G_IsRolloutGametype() then
		if (mo.state == S_RKITEMBOX1) and not mo.ring then -- Main '?' circle
			for i = 1, 2 do
				local fa = i*ANGLE_90
				mo.ring = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY) -- Spawn outer ring
				mo.ring.state = S_RKITEMBOX2
				mo.ring.target = mo
				mo.ring.angle = mo.angle+fa
			end
		elseif (mo.state == S_RKITEMBOX2) -- Outer ring
			if valid(mo.target)
			and mo.target.health then
				if (mo.target == MT_ROLLOUTROCK) then
					P_MoveOrigin(mo, mo.target.x, mo.target.y, mo.target.z)
				else
					P_MoveOrigin(mo, mo.target.x, mo.target.y, mo.target.z)
				end
				mo.rollangle = $ + ANGLE_11hh
				mo.angle = $ + ANGLE_11hh/3
				mo.color = mo.target.color or SKINCOLOR_GREEN
			else -- Fading ring
				local fadetimer = TICRATE/3
				if not mo.fuse then
					mo.fuse = fadetimer
					mo.destscale = 4*FRACUNIT
					mo.scalspeed = FRACUNIT/fadetimer
				end
				local ease = cosEase(1,9,(fadetimer)-mo.fuse,fadetimer)
				mo.frame = B|FF_PAPERSPRITE|ringtrans_t[ease]
			end
		end
	end
end, MT_DUMMY)

addHook("MobjMoveCollide", function(tmthing, thing)
	if valid(tmthing)
	and valid(thing) then
		if (tmthing.z > (thing.z + thing.height)) -- No Z collision? Let's fix that!
		or ((tmthing.z + tmthing.height) < thing.z) then
			return -- Out of range
		end
		
		if (thing.type == MT_DUMMY)
		and (thing.state == S_RKITEMBOX1) then
			for i = 1, 2
				local fa = i*ANGLE_90
				local itmr = P_SpawnMobj(tmthing.x, tmthing.y, tmthing.z, MT_DUMMY)
				itmr.state = S_RKITEMBOX2
				itmr.target = tmthing
				itmr.angle = tmthing.angle+fa
				itmr.scale = 3*FRACUNIT
				itmr.destscale = FRACUNIT+(FRACUNIT/4)
				itmr.scalespeed = FRACUNIT/(TICRATE/3)
			end
			P_RemoveMobj(thing)
		end
	end
end, MT_ROLLOUTROCK) -- Rock vs Dummy object

-- Score object
addHook("MobjThinker", function(mo)
	if valid(mo)
	and G_IsRolloutGametype() then
		if (mo.state == S_NIGHTSCORE100) then
			mo.color = (leveltime%69) -- NICE
			if (mo.fuse < TICRATE) then mo.flags2 = $ ^^ MF2_DONTDRAW end		
		/*elseif (mo.state == S_THOK) then
			if (mo.threshold == 100)
			and not (leveltime%2) then
				mo.flags2 = $ ^^ MF2_DONTDRAW
			end
			
			if (mo.threshold == 101)
				mo.extravalue1 = $ or 1
				if (mo.extravalue1 >= 7) then return end
				if (leveltime%7) then
					mo.extravalue1 = $ + 1
				end
				mo.frame = $ | (FF_TRANS10 * mo.extravalue1)
			end*/
		end
	end
end, MT_DUMMY)

-- Clairebun
-- getXYZangle: Self explainitory
rawset(_G, "getXYZangle", function(mo1, mo2)
	local x1, x2 = mo1.x - mo1.momx, mo2.x - mo2.momx
	local y1, y2 = mo1.y - mo1.momy, mo2.y - mo2.momy
	local angle = R_PointToAngle2(x1, y1, x2, y2)
	local dist = R_PointToDist2(x1, y1, x2, y2)
	local z1, z2 = mo1.z + mo1.height/2, mo2.z + mo2.height/2
	local zdist = z2 - z1
	local zangle = R_PointToAngle2(0, 0, dist, zdist)
	return angle, zangle
end)

-- Clairebun
rawset(_G, "getThrust", function(mo1, mo2, minimal)
	local xyangle, zangle = getXYZangle(mo1, mo2) -- Get thrust direction based on collision angle
	local speed
	if minimal
		speed = mo1.scale/2 -- "Shove" knockback
	else
		 -- Momentum-influenced knockback
		local momx = mo1.momx - mo2.momx
		local momy = mo1.momy - mo2.momy
		local momz = mo1.momz - mo2.momz
		speed = R_PointToDist2(0, 0, R_PointToDist2(0, 0, momx, momy), momz)
	end
	local thrust = P_ReturnThrustX(mo1, zangle, speed)
	local zthrust = P_ReturnThrustY(mo1, zangle, speed)
	local xthrust = P_ReturnThrustX(mo1, xyangle, thrust)
	local ythrust = P_ReturnThrustY(mo1, xyangle, thrust)
	return xthrust, ythrust, zthrust
end)

-- Rock v rock
addHook("MobjCollide", function(thing, tmthing)
	if valid(thing)
	and valid(tmthing) then
		if (thing.z > (tmthing.z + tmthing.height)) -- No Z collision? Let's fix that!
		or ((thing.z + thing.height) < tmthing.z) then
			return -- Out of range
		end
		
		if (thing.type == tmthing.type) then
			thing.bumpcount = $ + 1
			thing.bumpcounttics = TICRATE/3
		end
		
		if valid(thing.target)
		and valid(thing.target.player) then
			local p = thing.target.player
			
			-- Respawn failsafe
			if p.ingametics and (p.ingametics < 2*TICRATE) -- Player has been in-game for less than 2 seconds
			and thing.bumpcount and (thing.bumpcount > 15) -- And the bumpcount greater than 15 bumps?
				p.playerstate = PST_REBORN -- respawn
			elseif thing.bumpcount and (thing.bumpcount > TICRATE) -- Bumpcount is greater than 70 bumps
				local aang = R_PointToAngle2(tmthing.x, tmthing.y, thing.x, thing.y) -- Get the adjusted angle
				--p.playerstate = PST_REBORN -- Hack respawn
				/*P_TeleportMove(thing, thing.x - FixedMul(cos(aang), thing.radius),
										thing.y - FixedMul(sin(aang), thing.radius), 
										thing.z)*/
				P_SetOrigin(tmthing, tmthing.x - FixedMul(cos(aang), 3*tmthing.radius/2),
										tmthing.y - FixedMul(sin(aang), 3*tmthing.radius/2), 
										tmthing.z)
			end
		end
	end
end, MT_ROLLOUTROCK)

RK.mobj.calcKnockback = function(p, d, w, b, r)
	return ((p/10) + ((p*d)/20))*FRACUNIT/2
end

-- Moving rock v rock
addHook("MobjMoveCollide", function(tmthing, thing)
	if valid(tmthing)
	and valid(thing) then
		if (tmthing.z > (thing.z + thing.height)) -- No Z collision? Let's fix that!
		or ((tmthing.z + tmthing.height) < thing.z) then
			return -- Out of range
		end

		if (tmthing.type == MT_ROLLOUTROCK) and (thing.type == MT_ROLLOUTROCK) then
			local impact = { intensity = FixedHypot(abs(tmthing.momx), abs(tmthing.momy)),
							angle = R_PointToAngle2(0,0,tmthing.momx,tmthing.momy),
							mobj = P_SpawnMobj((tmthing.x + thing.x)/2,
										(tmthing.y + thing.y)/2, 
										((tmthing.z + tmthing.height/2) + (thing.z + thing.height/2))/2,
										MT_DUMMY)
							}
			if cv_rkquake.value then -- If the specified consvar is enabled...
				P_StartQuake(min(2*tmthing.info.speed,impact.intensity), 5) -- Shake the screen.
			end
			if thing.lastbumper and (thing.lastbumpertics > 9*TICRATE) then
				impact.mobj.state = S_SXPA
			else
				impact.mobj.state = S_IMPACT1
			end

			if valid(tmthing) then
				-- Collision! for points!
				thing.lastbumper = tmthing.target
				thing.lastbumpertics = 10*TICRATE -- 10 second cooldown
			end

			-- This following bit may seem backwards, but it's not
			if (tmthing.eflags & MFE_VERTICALFLIP) then
				FreeSetZ(tmthing, thing.z + thing.height) -- Upside down 
			else
				FreeSetZ(tmthing, thing.z)
			end
			
			if assert(type(thing.percent) == "number") then
				thing.percent = $ + impact.intensity/FRACUNIT
				if (thing.percent > 999) then thing.percent = 999 end
			end

			if (thing.percent > 30) -- Below 30 Percent, process normal knockback behavior.
			and (impact.intensity > 10) then -- Not light taps
				impact.knockback = RK.mobj.calcKnockback(thing.percent, impact.intensity/FRACUNIT)
				P_Thrust(thing, impact.angle, impact.knockback)
				S_StartSound(tmthing, sfx_s3k49) -- [Impact]
				--S_StartSound(tmthing, sfx_s3k5d) -- [Heavy Hit]
				tmthing.momx = 0
				tmthing.momy = 0
				return true
			end
		end
	end
end, MT_ROLLOUTROCK) -- Our tmthing

-- Rock removed
addHook("MobjRemoved", function(mobj)
	if G_IsRolloutGametype() then
		if valid(mobj) -- Valid check
		and valid(mobj.target) -- Do you have a target?
		and valid(mobj.target.player) then -- Is it a player?
			-- Poof goes the rock!
			local poof = P_SpawnMobj(mobj.x, mobj.y, mobj.z + FRACUNIT*32, MT_EXPLODE)
			P_SetMobjStateNF(poof, S_FBOMB_EXPL1)
			S_StartSound(poof, sfx_s3k4e)
			
			-- Your host is already dead. Eg. Your host died before you.
			if (mobj.target.player.playerstate == PST_DEAD) then 
				if valid(mobj.lastbumper)
				and valid(mobj.lastbumper.player) then -- Validity check
					-- There would be occurances where your host dies before the rock disappears, and no points for score are awarded
					-- This 'hopefully' fixes that.
					--print("Player died before the Rock despawned!")
					P_AddPlayerScore(mobj.lastbumper.player, 100)
					if valid(mobj.lastbumper.rock) then
						mobj.lastbumper.rock.fxtimer = 3*TICRATE/2
						S_StartSound(mobj.lastbumper.rock, sfx_pointu)
						
						local dummy = P_SpawnMobj(mobj.lastbumper.rock.x, 
													mobj.lastbumper.rock.y, 
													mobj.lastbumper.rock.height/2 + mobj.lastbumper.rock.z, 
													MT_DUMMY)
						P_SetMobjStateNF(dummy, S_NIGHTSCORE100)
						P_SetObjectMomZ(dummy, FRACUNIT, false)
						dummy.fuse = 3*TICRATE
						dummy.scalespeed = FRACUNIT/25
						dummy.destscale = 2*FRACUNIT
					end
				end
			else -- You died before your host.
				if valid(mobj.lastbumper)
				and valid(mobj.lastbumper.rock) then
					--print("Rock died before the player! Killing player!")
					P_DamageMobj(mobj.target,mobj.lastbumper.rock,mobj.lastbumper,1,DMG_INSTAKILL) -- Kill your host
					mobj.lastbumper.rock.fxtimer = 3*TICRATE/2
					S_StartSound(mobj.lastbumper.rock, sfx_pointu)
					
					local dummy = P_SpawnMobj(mobj.lastbumper.rock.x, 
												mobj.lastbumper.rock.y, 
												mobj.lastbumper.rock.height/2 + mobj.lastbumper.rock.z, 
												MT_DUMMY)
					P_SetMobjStateNF(dummy, S_NIGHTSCORE100)
					P_SetObjectMomZ(dummy, FRACUNIT, false)
					dummy.fuse = 3*TICRATE
					dummy.scalespeed = FRACUNIT/25
					dummy.destscale = 2*FRACUNIT
				elseif valid(mobj.lastbumper) then
					-- Goto: HURTMSG Hook for this
					P_DamageMobj(mobj.target,mobj.lastbumper,mobj.lastbumper,1,DMG_INSTAKILL) -- Kill your host
				else
					P_DamageMobj(mobj.target,nil,nil,1,DMG_INSTAKILL) -- Kill your host
				end
			end
		end
    end
end, MT_ROLLOUTROCK)