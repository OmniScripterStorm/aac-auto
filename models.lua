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
                    local R_need = 1.0 - (ctx.energy / 6)
                    return 10 + (R_need * 35)
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
                    local O_drive = ctx.health
                    local E_ratio = ctx.energy / 6
                    return 25 + (O_drive * 15) + (E_ratio * 15)
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
                    local O_drive = ctx.health
                    local E_ratio = ctx.energy / 6
                    return 30 + (O_drive * 15) + (E_ratio * 15)
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
                    local D = ctx.enemyCount / 5
                    local E_ratio = ctx.energy / 6
                    return 20 + (D * 55) + (E_ratio * 15)
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
                    local T = ctx.highPriorityEnemy and 1.0 or 0.0
                    return 40 + (T * 40)
                end
            }
        },
        targetSelection = function(ctx, enemies, abilityId)
            if not enemies or #enemies == 0 then return nil end
            
            if abilityId == "OverpoweringSlash" then
                table.sort(enemies, function(a, b) return (a.threat or 0) > (b.threat or 0) end)
                return enemies[1]
            else
                return nil
            end
        end
    }
}

return models
