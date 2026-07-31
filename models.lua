-- models.lua
return {
    -- Base Warrior Model
    Warrior = {
        class = "Warrior",
        baseClass = nil, -- No parent
        abilities = {
            Strike = {
                id = "Strike",
                energyCost = 0,
                cooldown = 0,
                targetType = "SingleEnemy",
                priority = 4,
                condition = function(ctx) return true end -- Always available
            },
            CrossSlash = {
                id = "CrossSlash",
                energyCost = 2,
                cooldown = 4,
                targetType = "SingleEnemy",
                priority = 6,
                condition = function(ctx) 
                    return ctx.energy >= 2 and ctx.enemyCount > 0
                end
            },
            Taunt = {
                id = "Taunt",
                energyCost = 1,
                cooldown = 5,
                targetType = "SingleEnemy",
                priority = 5,
                condition = function(ctx)
                    return ctx.energy >= 1 and ctx.health < 0.4 and ctx.enemyCount > 0
                end
            },
            Rally = {
                id = "Rally",
                energyCost = 3,
                cooldown = 6,
                targetType = "AllAlly",
                priority = 5,
                condition = function(ctx)
                    return ctx.energy >= 3 and ctx.health > 0.6 and ctx.turnCount > 2
                end
            }
        },
        -- Target selection logic for single target abilities
        targetSelection = function(ctx, enemies)
            -- Default: target lowest HP enemy
            table.sort(enemies, function(a, b) return a.hp < b.hp end)
            return enemies[1]
        end
    },
    
    -- Rampager Subclass Model
    Rampager = {
        class = "Rampager",
        baseClass = "Warrior", -- Inherits from Warrior
        abilities = {
            -- New abilities (added to Warrior's)
            BrutalSlashes = {
                id = "BrutalSlashes",
                energyCost = 2,
                cooldown = 4,
                targetType = "SingleEnemy",
                priority = 7,
                condition = function(ctx)
                    return ctx.energy >= 2 and ctx.enemyCount > 0
                end
            },
            Berserk = {
                id = "Berserk",
                energyCost = 0,
                cooldown = 5,
                targetType = "Self",
                priority = 8,
                condition = function(ctx)
                    return ctx.health > 0.6 and not ctx.buffs.Berserk
                end
            },
            CleavingBlow = {
                id = "CleavingBlow",
                energyCost = 4,
                cooldown = 5,
                targetType = "AllEnemy",
                priority = function(ctx)
                    if ctx.enemyCount >= 3 then return 9
                    elseif ctx.enemyCount == 2 then return 7
                    else return 4 end
                end,
                condition = function(ctx)
                    return ctx.energy >= 4 and ctx.enemyCount >= 2
                end
            },
            OverpoweringSlash = {
                id = "OverpoweringSlash",
                energyCost = 4,
                cooldown = 5,
                targetType = "SingleEnemy",
                priority = 9,
                condition = function(ctx)
                    return ctx.energy >= 4 and ctx.enemyCount > 0 and ctx.highPriorityEnemy
                end
            }
        },
        -- Override target selection for specific abilities if needed
        targetSelection = function(ctx, enemies, abilityId)
            if abilityId == "OverpoweringSlash" then
                -- Target highest threat enemy
                table.sort(enemies, function(a, b) return a.threat > b.threat end)
                return enemies[1]
            else
                -- Use parent logic for other abilities
                return nil -- Will fall back to parent
            end
        end
    }
}
