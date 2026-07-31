-- models.lua
local models = {
    -- Base Warrior Model
    Warrior = {
        class = "Warrior",
        baseClass = nil, -- Base class, no parent
        abilities = {
            Strike = {
                id = "Strike",
                displayName = "Strike",
                lvlUnlock = 1,
                damage = 6,
                energyCost = 0,
                cooldown = 0,
                targetType = "SingleEnemy",
                priority = 1, -- Base low-priority filler
                condition = function(ctx)
                    return true -- Always available, costs nothing
                end,
                -- Optional helper to calculate exact damage with scaling
                getExpectedDamage = function(ctx)
                    local str = ctx.stats and ctx.stats.STR or 0
                    local dex = ctx.stats and ctx.stats.DEX or 0
                    return 6 * (1 + (0.02 * str) + (0.01 * dex))
                end
            },
            CrossSlash = {
                id = "CrossSlash",
                displayName = "Cross Slash",
                lvlUnlock = 1,
                damage = 16, -- 8x2 physical
                energyCost = 2,
                cooldown = 4,
                targetType = "SingleEnemy",
                priority = 3, -- Preferred over Strike when energy allows
                condition = function(ctx)
                    return ctx.energy >= 2
                end,
                getExpectedDamage = function(ctx)
                    local str = ctx.stats and ctx.stats.STR or 0
                    return 16 * (1 + (0.012 * str))
                end
            },
            Taunt = {
                id = "Taunt",
                displayName = "Taunt",
                lvlUnlock = 3,
                energyCost = 1,
                cooldown = 5,
                targetType = "SingleEnemy",
                priority = function(ctx)
                    -- Prioritize keeping aggro if health is safe and allies are present
                    if ctx.health > 0.4 and ctx.enemyCount > 1 then
                        return 4
                    end
                    return 0.5 -- Low priority if critical health
                end,
                condition = function(ctx)
                    -- Don't taunt if we are already under the effects of Taunt
                    local alreadyTaunting = ctx.buffs and ctx.buffs.Taunted
                    return ctx.energy >= 1 and not alreadyTaunting and ctx.enemyCount > 0
                end
            },
            Rally = {
                id = "Rally",
                displayName = "Rally",
                lvlUnlock = 5,
                energyCost = 3,
                cooldown = 6,
                targetType = "AllAlly",
                priority = 5, -- High priority party buff
                condition = function(ctx)
                    -- Only use if we don't already have the Rallied buff active
                    local alreadyRallied = ctx.buffs and ctx.buffs.Rallied
                    return ctx.energy >= 3 and not alreadyRallied
                end
            }
        },
        -- Target selection logic for single target abilities
        targetSelection = function(ctx, enemies, abilityId)
            if not enemies or #enemies == 0 then return nil end
            -- Default base logic: target lowest HP enemy
            table.sort(enemies, function(a, b) return a.hp < b.hp end)
            return enemies[1]
        end
    },
    
    -- Rampager Subclass Model (Inherits base Warrior abilities unless overridden)
    Rampager = {
        class = "Rampager",
        baseClass = "Warrior",
        abilities = {
            BrutalSlashes = {
                id = "BrutalSlashes",
                displayName = "Brutal Slashes",
                lvlUnlock = 1,
                damage = 18, -- 9x2 physical
                energyCost = 2,
                cooldown = 4,
                targetType = "SingleEnemy",
                priority = 3.5, -- Takes priority over Cross Slash
                condition = function(ctx)
                    return ctx.energy >= 2
                end,
                getExpectedDamage = function(ctx)
                    local str = ctx.stats and ctx.stats.STR or 0
                    return 18 * (1 + (0.0125 * str))
                end
            },
            Berserk = {
                id = "Berserk",
                displayName = "Berserk",
                lvlUnlock = 3,
                energyCost = 0,
                cooldown = 5,
                targetType = "Self",
                priority = 6, -- High priority self-buff to setup subsequent attacks
                condition = function(ctx)
                    -- Only cast if we are healthy and do not currently have the Reckless buff
                    local isReckless = ctx.buffs and ctx.buffs.Reckless
                    return ctx.health > 0.4 and not isReckless
                end
            },
            CleavingBlow = {
                id = "CleavingBlow",
                displayName = "Cleaving Blow",
                lvlUnlock = 4,
                damage = 11,
                energyCost = 4,
                cooldown = 5,
                targetType = "AllEnemy",
                priority = function(ctx)
                    -- Priority scales up significantly if multiple enemies are present
                    if ctx.enemyCount >= 3 then
                        return 5
                    elseif ctx.enemyCount == 2 then
                        return 3
                    end
                    return 1 -- Low priority if only one enemy left
                end,
                condition = function(ctx)
                    return ctx.energy >= 4 and ctx.enemyCount > 0
                end,
                getExpectedDamage = function(ctx)
                    local str = ctx.stats and ctx.stats.STR or 0
                    local enemyCount = ctx.enemyCount or 1
                    -- Precision scaling: Base * (1 + Scaling * Stat) * (1 + Precision * (5 - enemyCount))
                    local baseScaling = 11 * (1 + (0.0125 * str))
                    local precisionScaling = 1 + (0.15 * (5 - enemyCount))
                    return baseScaling * precisionScaling
                end
            },
            OverpoweringSlash = {
                id = "OverpoweringSlash",
                displayName = "Overpowering Slash",
                lvlUnlock = 6,
                damage = 17,
                energyCost = 4,
                cooldown = 5,
                targetType = "SingleEnemy",
                priority = 7, -- Highest priority single target due to Stun effect
                condition = function(ctx)
                    return ctx.energy >= 4 and ctx.enemyCount > 0
                end,
                getExpectedDamage = function(ctx)
                    local str = ctx.stats and ctx.stats.STR or 0
                    return 17 * (1 + (0.025 * str))
                end
            }
        },
        -- Target override configurations
        targetSelection = function(ctx, enemies, abilityId)
            if not enemies or #enemies == 0 then return nil end
            
            if abilityId == "OverpoweringSlash" then
                -- Target the highest threat/dangerous enemy first to maximize the Stun utility
                table.sort(enemies, function(a, b) return (a.threat or 0) > (b.threat or 0) end)
                return enemies[1]
            else
                -- Fall back to Warrior (lowest HP targeting) for other skills
                return nil
            end
        end
    }
}

return models
