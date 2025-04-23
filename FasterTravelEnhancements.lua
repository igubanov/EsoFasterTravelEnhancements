FasterTravelEnhancements = { addon = { name = "FasterTravelEnhancements" } }

local FT = FasterTravel
local FTE = FasterTravelEnhancements
local addon = FTE.addon
local savedVars
local FtCategoryNames = {
    All = GetString(FASTER_TRAVEL_WAYSHRINES_CATEGORY_ALL),
    Favorites = GetString(FASTER_TRAVEL_WAYSHRINES_CATEGORY_FAVOURITES),
    Recent = GetString(FASTER_TRAVEL_WAYSHRINES_CATEGORY_RECENT)
}


--- original FasterTravel fill recent and favorite categories without zoneId,
--- and it's a bug - you cant navigate by right-click to the wayshrine
local function FixZoneIndexForFavoriteAndRecent()
    local function afterRefreshFixRecentAndFavorites()
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

    FTE.wayshrineTab.Refresh = FT.hook(FTE.wayshrineTab.Refresh,
        function(refresh, ...)
            local refreshResult = refresh(...)
            afterRefreshFixRecentAndFavorites()
            return refreshResult
        end)
end

--- save last tab NAME and try to find and restore after game restart
--- probably in the future may change to tab index/number (but it'savedVars required cycle)
local function FixLastTab()
    if (savedVars.lastTab ~= nil) then
        local originalFunc = WORLD_MAP_INFO.SelectTab;
        WORLD_MAP_INFO.SelectTab = FasterTravel.hook(WORLD_MAP_INFO.SelectTab,
            function(base, self, tabId)
                local lastTabId = tabId
                for _, btn in ipairs(WORLD_MAP_INFO.modeBar.buttonData) do
                    local tabName = GetString(btn.descriptor)
                    if (tabName == savedVars.lastTab) then
                        lastTabId = btn.descriptor
                        break
                    end
                end

                base(self, lastTabId)
                -- d("SelectTab hooked, restore " .. lastTabId)
                WORLD_MAP_INFO.SelectTab = originalFunc
            end)
    end

    SCENE_MANAGER:GetScene('worldMap'):RegisterCallback("StateChange",
        function(oldState, newState)
            if (newState ~= SCENE_HIDDEN) then return end
            savedVars.lastTab = GetString(WORLD_MAP_INFO.modeBar.lastFragmentName)
            -- d("LastTab saved " .. savedVars.lastTab)
        end)
end

local function OnAddOnLoaded(event, addonName)
    if addonName ~= addon.name then return end

    savedVars = ZO_SavedVars:NewAccountWide(addon.name .. "_Data", 1, nil, {})
    FTE.savedVars = savedVars

    local ftTabSetting = FT.Options.initial_tab[FT.settings.initial_tab].value
    if (ftTabSetting == FASTER_TRAVEL_SETTINGS_INITIAL_TAB_LAST) then
        FixLastTab()
    end

    FixZoneIndexForFavoriteAndRecent()

    if not FT then
        zo_callLater(function() d(addon.name .. " cant work without FasterTravel") end, 5000)
        return
    end
end

-- override init method asap to hook creation of object
FT.MapTabWayshrines.init = FT.hook(FT.MapTabWayshrines.init,
    function(init, self, ...)
        local initResult = init(self, ...)
        local wayshrineTab = self
        FTE.wayshrineTab = wayshrineTab
        return initResult
    end)

EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
