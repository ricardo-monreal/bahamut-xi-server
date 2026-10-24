-----------------------------------
-- Bahamut XI: trust shop
-----------------------------------
-- Opens up trusts this 75-era server can't otherwise give (their quests and ciphers belong to
-- content that is turned off). Trusts unlock in tiers by the player's highest job level and
-- are bought with conquest points through a chat command:
--
--   !trustshop          list every tier, its price and what you own
--   !trustshop <n>      show trust number n; send it again within 30 seconds to buy it
--
-- Conquest points are the player's own nation's points (the ones shown in the conquest menu).
-- Edit the tiers below, then: sudo bahamut apply && sudo bahamut restart game
-----------------------------------
require('modules/module_utils')
-----------------------------------

-- Each tier: the job level needed, the price in conquest points, and five trusts as
-- { name in xi.magic.spell (scripts/enum/magic.lua), name shown to players }.
-- 35 trusts in all, 75-era jobs only.
local tiers =
{
    {
        level = 20, cost = 1000,
        trusts = { { 'ZEID', 'Zeid' }, { 'LION', 'Lion' }, { 'TENZEN', 'Tenzen' }, { 'MIHLI_ALIAPOH', 'Mihli Aliapoh' }, { 'VALAINERAL', 'Valaineral' } },
    },
    {
        level = 30, cost = 1500,
        trusts = { { 'NAJA_SALAHEEM', 'Naja Salaheem' }, { 'JOACHIM', 'Joachim' }, { 'RAINEMARD', 'Rainemard' }, { 'GADALAR', 'Gadalar' }, { 'NAJELITH', 'Najelith' } },
    },
    {
        level = 40, cost = 2000,
        trusts = { { 'LUZAF', 'Luzaf' }, { 'GESSHO', 'Gessho' }, { 'ZAZARG', 'Zazarg' }, { 'LEHKO_HABHOKA', 'Lehko Habhoka' }, { 'KARAHA_BARUHA', 'Karaha-Baruha' } },
    },
    {
        level = 50, cost = 2500,
        trusts = { { 'LILISETTE', 'Lilisette' }, { 'AREUHAT', 'Areuhat' }, { 'ELIVIRA', 'Elivira' }, { 'NOILLURIE', 'Noillurie' }, { 'RAHAL', 'Rahal' } },
    },
    {
        level = 60, cost = 3000,
        trusts = { { 'CID', 'Cid' }, { 'FABLINIX', 'Fablinix' }, { 'ADELHEID', 'Adelheid' }, { 'KORU_MORU', 'Koru-Moru' }, { 'FERREOUS_COFFIN', 'Ferreous Coffin' } },
    },
    {
        level = 70, cost = 4000,
        trusts = { { 'GILGAMESH', 'Gilgamesh' }, { 'DOMINA_SHANTOTTO', 'Domina Shantotto' }, { 'MUMOR', 'Mumor' }, { 'QULTADA', 'Qultada' }, { 'ROMAA_MIHGO', 'Romaa Mihgo' } },
    },
    {
        level = 75, cost = 5000,
        trusts = { -- the Ark Angels
            { 'AAHM', 'Ark Angel HM' }, { 'AAEV', 'Ark Angel EV' }, { 'AAMR', 'Ark Angel MR' }, { 'AATT', 'Ark Angel TT' }, { 'AAGK', 'Ark Angel GK' } },
    },
}

local confirmSeconds = 30
local channel        = xi.msg.channel.SYSTEM_3

-- Flat, numbered list built on first use, so xi.magic.spell is certainly loaded.
local entries = nil

local function getEntries()
    if entries then
        return entries
    end

    entries = {}
    for tierIndex, tier in ipairs(tiers) do
        for _, trust in ipairs(tier.trusts) do
            local key     = trust[1]
            local spellId = xi.magic.spell[key]
            if spellId then
                table.insert(entries, {
                    spellId = spellId,
                    name    = trust[2],
                    tier    = tierIndex,
                    level   = tier.level,
                    cost    = tier.cost,
                })
            else
                print(string.format('[bahamut_trust_shop] unknown trust %s in tier %d; skipped', key, tierIndex))
            end
        end
    end

    return entries
end

-- Highest level on any job, so changing jobs never locks a player out of a tier.
local function highestJobLevel(player)
    local best = player:getMainLvl()
    for jobId = 1, 22 do
        local lvl = player:getJobLevel(jobId)
        if lvl and lvl > best then
            best = lvl
        end
    end

    return best
end

local function say(player, text)
    player:printToPlayer(text, channel, '')
end

local function formatNumber(n)
    local s = tostring(n)
    local result = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (result:gsub('^,', ''))
end

local function listShop(player)
    local level = highestJobLevel(player)
    say(player, string.format('Trust shop: %s conquest points, highest job level %d.', formatNumber(player:getCP()), level))

    -- Open tiers and the next locked one in full; later tiers as one line, to keep chat short.
    local shownLocked = nil
    local laterLevels = {}
    local currentTier = nil
    for index, entry in ipairs(getEntries()) do
        local locked = level < entry.level
        if locked and shownLocked == nil then
            shownLocked = entry.tier
        end

        if locked and entry.tier ~= shownLocked then
            if entry.tier ~= currentTier then
                currentTier = entry.tier
                table.insert(laterLevels, tostring(entry.level))
            end
        else
            if entry.tier ~= currentTier then
                currentTier = entry.tier
                say(player, string.format('-- Level %d, %s CP each (%s) --', entry.level, formatNumber(entry.cost), locked and 'locked' or 'open'))
            end

            local mark
            if player:hasSpell(entry.spellId) then
                mark = 'owned'
            elseif locked then
                mark = 'locked'
            else
                mark = 'available'
            end

            say(player, string.format('%2d. %s  [%s]', index, entry.name, mark))
        end
    end

    if #laterLevels > 0 then
        say(player, string.format('More trusts unlock at level %s.', table.concat(laterLevels, ', ')))
    end

    say(player, 'Buy with !trustshop <number>.')
end

local function buy(player, index)
    local entry = getEntries()[index]
    if not entry then
        say(player, string.format('There is no trust number %d. Type !trustshop to see the list.', index))
        return
    end

    if player:hasSpell(entry.spellId) then
        say(player, string.format('You already know %s.', entry.name))
        return
    end

    local level = highestJobLevel(player)
    if level < entry.level then
        say(player, string.format('%s unlocks at level %d. Your highest job is level %d.', entry.name, entry.level, level))
        return
    end

    local points = player:getCP()
    if points < entry.cost then
        say(player, string.format('%s costs %s conquest points. You have %s.', entry.name, formatNumber(entry.cost), formatNumber(points)))
        return
    end

    -- First request: ask to confirm. Same number again within the time limit: buy.
    local now = GetSystemTime()
    if
        player:getLocalVar('TrustShopPending') ~= entry.spellId or
        now - player:getLocalVar('TrustShopPendingAt') > confirmSeconds
    then
        player:setLocalVar('TrustShopPending', entry.spellId)
        player:setLocalVar('TrustShopPendingAt', now)
        say(player, string.format('%s costs %s conquest points (you have %s). Type !trustshop %d again within %d seconds to buy.',
            entry.name, formatNumber(entry.cost), formatNumber(points), index, confirmSeconds))
        return
    end

    player:setLocalVar('TrustShopPending', 0)
    player:delCP(entry.cost)
    player:addSpell(entry.spellId, { silentLog = true })
    say(player, string.format('You learned Trust: %s. %s conquest points left.', entry.name, formatNumber(player:getCP())))
end

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'i',
}

commandObj.onTrigger = function(player, index)
    if xi.settings.main.ENABLE_TRUST_CASTING == 0 then
        say(player, 'Trusts are turned off on this server.')
        return
    end

    if index == nil then
        listShop(player)
    else
        buy(player, index)
    end
end

xi.module.registerCommand('trustshop', commandObj)

