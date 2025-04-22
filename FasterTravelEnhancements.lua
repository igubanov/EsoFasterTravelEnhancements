local addon = { name = "FasterTravelEnhancements" }
local FT = FasterTravel
local FtCategoryNames = {
    All = GetString(FASTER_TRAVEL_WAYSHRINES_CATEGORY_ALL),
    Favorites = GetString(FASTER_TRAVEL_WAYSHRINES_CATEGORY_FAVOURITES),
    Recent = GetString(FASTER_TRAVEL_WAYSHRINES_CATEGORY_RECENT)
}


--- original FasterTravel fill recent and favorite categories without zoneId,
--- and it's a bug - you cant navigate by right-click to the wayshrine
local function fixRefresh(...)
    local categories = {}
    for _, category in ipairs(FT.MapTabWayshrines.categories) do
        if (category.name == FtCategoryNames.All
                or category.name == FtCategoryNames.Favorites
                or category.name == FtCategoryNames.Recent
            ) then
            categories[category.name] = category.data

            if (#categories == 3) then break end
        end
    end

    local allWayshrines = categories[FtCategoryNames.All]
    local lookup = {}
    for _, data in ipairs(allWayshrines)
    do
        lookup[data.nodeIndex] = data.zoneIndex
    end

    local wayshrineNeedToFixArrays =
    {
        categories[FtCategoryNames.Favorites],
        categories[FtCategoryNames.Recent]
    }

    for _, array in ipairs(wayshrineNeedToFixArrays) do
        for _, el in ipairs(array) do
            el.zoneIndex = el.zoneIndex or lookup[el.nodeIndex]
        end
    end
end

local function OnAddOnLoaded(event, addonName)
    if addonName ~= addon.name then return end

    if not FT then
        zo_callLater(function() d(addon.name .. " cant work without FasterTravel") end, 5000)
        return
    end
end

FasterTravelEnhancements = { addon = addon }

FT.MapTabWayshrines.init = FT.hook(FT.MapTabWayshrines.init,
    function(init, self, ...)
        local wayshrineTab = self
        local initResult = init(self, ...)
        FasterTravelEnhancements.wayshrineTab = wayshrineTab

        wayshrineTab.Refresh = FT.hook(wayshrineTab.Refresh,
            function(refresh, ...)
                local refreshResult = refresh(...)
                fixRefresh()
                return refreshResult
            end)

        return initResult
    end)

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
