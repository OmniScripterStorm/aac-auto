local models = {
    Warrior = {
        class = "Warrior",
        baseClass = nil,
        abilities = {
            Strike = {
                id = "Strike",
                displayName = "Strike",
                lvlUnlock = 1,
                energyCost = 0,
                cooldown = 0,
                targetType = "SingleEnemy",
                calculateUtility = function(ctx)
                    -- Check if an enemy is within executive Strike range (6 HP)
                    if ctx.enemies then
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 0 and enemy.hp <= 6 then
                                return 120 -- Maximum priority to secure low-resource kill
                            end
                        end
                    end
                    
                    local R_need = 1.0 - (ctx.energy / 6)
                    local baseScore = 10 + (R_need * 35)
                    
                    -- Reduce filler priority at the end of combat to encourage spending energy
                    if ctx.enemyCount == 1 then
                        baseScore = baseScore - 15
                    end
                    return baseScore
                end
            },
            CrossSlash = {
                id = "CrossSlash",
                displayName = "Cross Slash",
                lvlUnlock = 1,
                energyCost = 2,
                cooldown = 4,
                targetType = "SingleEnemy",
                calculateUtility = function(ctx)
                    if ctx.energy < 2 then return -math.huge end
                    
                    -- Overkill Prevention: Don't waste energy if Strike can kill
                    if ctx.enemies then
                        local lowestHp = 999
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 0 and enemy.hp < lowestHp then lowestHp = enemy.hp end
                        end
                        if lowestHp <= 6 then return -100 end
                    end
                    
                    local O_drive = ctx.health
                    local E_ratio = ctx.energy / 6
                    local score = 25 + (O_drive * 15) + (E_ratio * 15)
                    
                    -- Finisher Phase: Dump high damage skills aggressively
                    if ctx.enemyCount == 1 then
                        score = score + 15
                    end
                    return score
                end
            },
            Taunt = {
                id = "Taunt",
                displayName = "Taunt",
                lvlUnlock = 3,
                energyCost = 1,
                cooldown = 5,
                targetType = "SingleEnemy",
                calculateUtility = function(ctx)
                    if ctx.energy < 1 or ctx.enemyCount == 0 then return -math.huge end
                    
                    -- Do not taunt solo (no allies to protect)
                    if ctx.allyCount and ctx.allyCount == 0 then
                        return -100
                    end
                    
                    local S_need = 1.0 - ctx.health
                    local D = ctx.enemyCount / 5
                    return (S_need * 50) + (D * 20)
                end
            },
            Rally = {
                id = "Rally",
                displayName = "Rally",
                lvlUnlock = 5,
                energyCost = 3,
                cooldown = 6,
                targetType = "AllAlly",
                calculateUtility = function(ctx)
                    if ctx.energy < 3 then return -math.huge end
                    if ctx.buffs and ctx.buffs.Rallied then return -50 end
                    
                    -- Do not cast team buffs if only 1 weak enemy remains
                    if ctx.enemyCount == 1 then
                        return -100
                    end
                    
                    local O_drive = ctx.health
                    local turnFactor = math.max(0, 1.0 - (ctx.turnCount or 1) / 10)
                    return 35 + (O_drive * 15) + (turnFactor * 15)
                end
            }
        },
        targetSelection = function(ctx, enemies, abilityId)
            if not enemies or #enemies == 0 then return nil end
            table.sort(enemies, function(a, b) return a.hp < b.hp end)
            return enemies[1]
        end
    },
    
    Rampager = {
        class = "Rampager",
        baseClass = "Warrior",
        abilities = {
            BrutalSlashes = {
                id = "BrutalSlashes",
                displayName = "Brutal Slashes",
                lvlUnlock = 1,
                energyCost = 2,
                cooldown = 4,
                targetType = "SingleEnemy",
                calculateUtility = function(ctx)
                    if ctx.energy < 2 then return -math.huge end
                    
                    -- Execution Window: Prioritize securing clean kill (approx 18 damage)
                    if ctx.enemies then
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 6 and enemy.hp <= 18 then
                                return 110
                            end
                        end
                        
                        -- Overkill Prevention: Let Strike take the kill if HP <= 6
                        local lowestHp = 999
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 0 and enemy.hp < lowestHp then lowestHp = enemy.hp end
                        end
                        if lowestHp <= 6 then return -100 end
                    end
                    
                    local O_drive = ctx.health
                    local E_ratio = ctx.energy / 6
                    local score = 30 + (O_drive * 15) + (E_ratio * 15)
                    
                    if ctx.enemyCount == 1 then
                        score = score + 20
                    end
                    return score
                end
            },
            Berserk = {
                id = "Berserk",
                displayName = "Berserk",
                lvlUnlock = 3,
                energyCost = 0,
                cooldown = 5,
                targetType = "Self",
                calculateUtility = function(ctx)
                    if ctx.buffs and ctx.buffs.Reckless then return -50 end
                    
                    -- Energy check: Do not buff if we cannot follow up with damage next turn
                    if ctx.energy < 2 then
                        return -50
                    end
                    
                    -- Do not waste setup if the last enemy is almost dead
                    if ctx.enemies and ctx.enemyCount == 1 then
                        local lowestHp = 999
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 0 and enemy.hp < lowestHp then lowestHp = enemy.hp end
                        end
                        if lowestHp <= 25 then return -100 end
                    end
                    
                    local O_drive = ctx.health
                    local S_need = 1.0 - ctx.health
                    return (O_drive * 65) - (S_need * 50)
                end
            },
            CleavingBlow = {
                id = "CleavingBlow",
                displayName = "Cleaving Blow",
                lvlUnlock = 4,
                energyCost = 4,
                cooldown = 5,
                targetType = "AllEnemy",
                calculateUtility = function(ctx)
                    if ctx.energy < 4 or ctx.enemyCount == 0 then return -math.huge end
                    
                    -- Do not waste heavy AoE on a single target
                    if ctx.enemyCount == 1 then
                        return -100
                    end
                    
                    local D = ctx.enemyCount / 5
                    local E_ratio = ctx.energy / 6
                    local baseScore = 20 + (D * 55) + (E_ratio * 15)
                    
                    -- Optimize for Cooldown Reset: Dump AoE freely if enemies are healthy
                    if ctx.enemyCount >= 2 then
                        baseScore = baseScore + 15
                    end
                    return baseScore
                end
            },
            OverpoweringSlash = {
                id = "OverpoweringSlash",
                displayName = "Overpowering Slash",
                lvlUnlock = 6,
                energyCost = 4,
                cooldown = 5,
                targetType = "SingleEnemy",
                calculateUtility = function(ctx)
                    if ctx.energy < 4 or ctx.enemyCount == 0 then return -math.huge end
                    
                    -- Secure Clean Execution (approx 17 damage)
                    if ctx.enemies then
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 12 and enemy.hp <= 17 then
                                return 115
                            end
                        end
                        
                        -- Overkill Prevention: Let Brutal Slashes or Strike take it if HP is low
                        local lowestHp = 999
                        for _, enemy in ipairs(ctx.enemies) do
                            if enemy.hp > 0 and enemy.hp < lowestHp then lowestHp = enemy.hp end
                        end
                        if lowestHp <= 12 then return -100 end
                    end
                    
                    local T = ctx.highPriorityEnemy and 1.0 or 0.0
                    local score = 40 + (T * 45)
                    
                    -- Finisher Phase: Dump heavy cooldown to finish off healthy final targets
                    if ctx.enemyCount == 1 then
                        score = score + 25
                    end
                    return score
                end
            }
        },
        targetSelection = function(ctx, enemies, abilityId)
            if not enemies or #enemies == 0 then return nil end
            
            if abilityId == "OverpoweringSlash" then
                -- Stun high-threat targets first
                table.sort(enemies, function(a, b) return (a.threat or 0) > (b.threat or 0) end)
                return enemies[1]
            else
                return nil
            end
        end
    }
}

return models
