--[[
┌────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ _/_/_/_/_/  _/    _/  _/      _/    _/_/_/    _/_/_/  _/_/_/_/_/  _/_/_/_/  _/      _/  _/      _/ │
│    _/      _/    _/  _/_/    _/  _/        _/            _/      _/        _/_/    _/    _/  _/    │
│   _/      _/    _/  _/  _/  _/  _/  _/_/    _/_/        _/      _/_/_/    _/  _/  _/      _/       │
│  _/      _/    _/  _/    _/_/  _/    _/        _/      _/      _/        _/    _/_/    _/  _/      │
│ _/        _/_/    _/      _/    _/_/_/  _/_/_/        _/      _/_/_/_/  _/      _/  _/      _/     │
├────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ © Copyright 2024                                                                                   │
├────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ © Copyright 2024                                                                                   │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌───────────┐
│ Lets Cook │
└───────────┘
]]
require "LCUtil"
require "LCMenu"
require "LCFindItems"

LetsCook = LetsCook or {}
LetsCook.LOG = LetsCook.LOG or {}
LetsCook.LOG.debug = getCore():getDebug() or false
LetsCook.LOG.trace = false

LetsCook.ALL_FOOD_RECIPES = LetsCook.ALL_FOOD_RECIPES or {}
LetsCook.ALL_EVOLVED_RECIPES = LetsCook.ALL_EVOLVED_RECIPES or {}
LetsCook.favEvoRecipes = {}

function LetsCook.debugPrintItemRecipe(itemRecipe)
  local output = "\n    Item recipe (" .. tostring(itemRecipe:getName()) .. ")"
  output = output .. "\n      Full Type: " .. tostring(itemRecipe:getFullType())
  output = output .. "\n      Module:    " .. tostring(itemRecipe:getModule())
  output = output .. "\n      Use:       " .. tostring(itemRecipe:getUse())
  return output
end

function LetsCook.debugPrintRecipe(recipe)
  -- TBD getFullType()
  
end

function LetsCook.debugPrintEvolvedRecipe(evolvedRecipe)  
  local output = "\nEvolved recipe (" .. tostring(evolvedRecipe:getName()) .. ")"
  output = output .. "\n  Base Item:        " .. tostring(evolvedRecipe:getBaseItem())
  output = output .. "\n  Full Result Item: " .. tostring(evolvedRecipe:getFullResultItem())
  output = output .. "\n  Max Items:        " .. tostring(evolvedRecipe:getMaxItems())
  output = output .. "\n  Original name:    " .. tostring(evolvedRecipe:getOriginalname())
  output = output .. "\n  Result Item:      " .. tostring(evolvedRecipe:getResultItem())
  output = output .. "\n  Possible Items:"
  local pi = evolvedRecipe:getPossibleItems()
  local size = pi:size()
  for i = 0, size - 1 do
    local itemRecipe = pi:get(i)
    output = output .. LetsCook.debugPrintItemRecipe(itemRecipe)
  end    
  return output
end

function LetsCook.init()
  local player = getPlayer()
  LetsCook.ALL_FOOD_RECIPES = {}
  local size = getAllRecipes():size()
  for i = 0, size - 1 do
    local recipe = getAllRecipes():get(i)
    if recipe:getCategory() == 'Cooking' and not recipe:isHidden() and (not recipe:needToBeLearn() or (player and player:isRecipeKnown(recipe))) then
      if LetsCook.LOG.debug then print("Adding recipe from list: " .. tostring(recipe:getName())) end
      table.insert(LetsCook.ALL_FOOD_RECIPES, recipe)
    end
  end
  LetsCook.ALL_EVOLVED_RECIPES = {}
  size = RecipeManager.getAllEvolvedRecipes():size()
  for i = 0, size - 1 do    
    local evo = RecipeManager.getAllEvolvedRecipes():get(i)
    if evo:isCookable() and not evo:isHidden() then
      if LetsCook.LOG.debug then print("Adding evolved recipe from list: " .. tostring(evo:getName())) end
      if LetsCook.LOG.debug then print(LetsCook.debugPrintEvolvedRecipe(evo)) end
      table.insert(LetsCook.ALL_EVOLVED_RECIPES, evo)
    end    
  end  
end
Events.OnGameStart.Add(LetsCook.init)

-- To preserve UI position between sessions --
function LetsCook.saveModData()
	local modData = LCUtil.getValidModData()
	if LCMenu.UI.x ~= nil then
		modData.position.x = LCMenu.UI.x
		modData.position.y = LCMenu.UI.y
		modData.position.isVisible = LCMenu.UI.isUIVisible
	end
  modData.favEvoRecipes = LetsCook.favEvoRecipes
	ModData.add("LetsCook", modData)
end
Events.OnSave.Add(LetsCook.saveModData)

function LetsCook.loadModData()
	local modData = LCUtil.getValidModData()
	if LCMenu.UI.x ~= nil and modData.position and modData.position.x then
		LCMenu.UI.x = modData.position.x
		LCMenu.UI.y = modData.position.y
		LCMenu.UI.isUIVisible = modData.position.isVisible
	end
  if modData.favEvoRecipes then
    LetsCook.favEvoRecipes = modData.favEvoRecipes
  end
end
Events.OnLoad.Add(LetsCook.loadModData)

function LestCook.addToFavEvoRecipes(evo)
  for _, v in pairs(LetsCook.favEvoRecipes) do
    if v == evo then
      if LetsCook.LOG.debug then print("Skipping already added evo to fav list", tostring(evo:getOriginalname())) end
      return
    end
  end
  if LetsCook.LOG.debug then print("Adding evo to fav list", tostring(evo:getOriginalname())) end
  table.insert(LetsCook.favEvoRecipes, evo)
end

function LestCook.removeFromFavEvoRecipes(evo)
  for i = 1, #LetsCook.favEvoRecipes do
    if LetsCook.favEvoRecipes[i] == evo then
      if LetsCook.LOG.debug then print("Removing evo from fav list", tostring(evo:getOriginalname())) end
      LetsCook.favEvoRecipes[i] = nil
      return
    end
  end 
  if LetsCook.LOG.debug then print("Evo was not in fav list", tostring(evo:getOriginalname())) end
end

function LestCook.isInFavEvoRecipes(evo)
  for i = 1, #LetsCook.favEvoRecipes do
    if LetsCook.favEvoRecipes[i] == evo then
      return true
    end
  end 
  return false
end

function LestCook.hasDeeperRecipesFor(vesselList, strBaseItem)
  local output = "\nhasDeeperRecipeFor: " .. strBaseItem
  for k, v in pairs(LetsCook.ALL_FOOD_RECIPES) do
    if LetsCook.LOG.debug then output = output .. "\nRecipe result: " .. tostring(v:getResult():getType()) end
    if v:getResult() and getResult():getType() == strBaseItem then
      local sourceList = v:getSource()
      local size = sourceList:size()
      for i = 0, size - 1 do
        local source = sourceList:get(i)
        local items = source:getItems()
        local iSize = items:size()
        for j = 0, iSize - 1 do
          local item = items:get(j)
          if LetsCook.LOG.debug then output = output .. "\nSee if source item (" .. tostring(item) .. ") is in vesselList" end
          if LCFindItems.isInList(vesselList, item) then
            if LetsCook.LOG.debug then print(output .. "\nGot it") end
            return true
          end
        end
      end
    end
  end
  if LetsCook.LOG.debug then print(output .. "\nNo luck") end
  return false
end

-- TODO, rather use getHungerChange?
function LestCook.countItems(foodList, possibleItems)
  --foodList InventoryItems
  --possibleItems ItemRecipe
  local count = 0
  local size = possibleItems:size()
  for i = 0, size - 1 do
    local pItem = possibleItems:get(i)
    local pCount = 0
    if foodList[pItem:getName()] then
      pCount = #foodList[pItem:getName()]
    end
    count = count + pCount
  end
  
  return count
end

function LestCook.sortEvos(foodList, vesselList, toolList)
  local function byValue(first, second)
    -- A) is evo in fav list (even if it can't be made?)
    -- B) check if we have the base item (or pre base item) near
    -- C) then count the available ing for first and second
    local output = "***"
    if LetsCook.LOG.debug then
      output = output .. "\n1st = " .. first:getBaseItem() .. "[" .. tostring(LestCook.isInFavEvoRecipes(first)) .. ", " .. tostring(LCFindItems.isInList(vesselList, first:getBaseItem())) .. ", " .. LCFindItems.getRecipesFor(first:getBaseItem()) .. "]"
      output = output .. "\n2nd = " .. second:getBaseItem() .. "[" .. tostring(LestCook.isInFavEvoRecipes(second)) .. ", " .. tostring(LCFindItems.isInList(vesselList, second:getBaseItem())) .. ", " .. LCFindItems.getRecipesFor(second:getBaseItem()) .. "]"
    end
    if (LestCook.isInFavEvoRecipes(first) and LestCook.isInFavEvoRecipes(second)) or (not LestCook.isInFavEvoRecipes(first) and not LestCook.isInFavEvoRecipes(second)) then
      local firstHasBaseItem = LCFindItems.isInList(vesselList, first:getBaseItem())
      if not firstHasBaseItem then -- check if we can make it
        firstHasBaseItem = LestCook.hasDeeperRecipesFor(vesselList, first:getBaseItem())
      end
      local secondHasBaseItem = LCFindItems.isInList(vesselList, second:getBaseItem())
      if not secondHasBaseItem then -- check if we can make it
        secondHasBaseItem = LestCook.hasDeeperRecipesFor(vesselList, second:getBaseItem())
      end
      if firstHasBaseItem and secondHasBaseItem then
        local ret = LestCook.countItems(foodList, first:getPossibleItems()) > LestCook.countItems(foodList, second:getPossibleItems())
        if LetsCook.LOG.debug then
          output = output .. "\nResult(A) = " .. tostring(ret)
          print(output)
        end
        return ret
      else
        local ret = first:getBaseItem() < second:getBaseItem()
        if LetsCook.LOG.debug then
          output = output .. "\nResult(B) = " .. tostring(ret)
          print(output)
        end
        return ret
      end
    end
    local ret = LestCook.isInFavEvoRecipes(first) and not LestCook.isInFavEvoRecipes(second)
    if LetsCook.LOG.debug then
      output = output .. "\nResult(C) = " .. tostring(ret)
      print(output)
    end
    return ret
  end
  
  table.sort(LetsCook.ALL_EVOLVED_RECIPES, byValue)
end

-- Created by shadowhunter100 aka "Cows with Guns" on Steam for Project Zomboid Modding
-- 
-- The integer is the [<number>] in Project Zomboid's LUA, the "<string>" is the key on a Windows keyboard.
-- Keyboard keys may differ depending on hardware setup; don't expect a Mac keyboard map from me.
-- This keyboard mapping was done using a GE76 Laptop Keyboard in April 2023.

-- Get the key
-- @param int iKey the key's index 0..255
-- @return string The keyboard's key. E.g. "1". "ERROR" will be returned if iKey is not in the array
function LetsCook.getKey(iKey)
  if iKey < 0 or iKey > 255 then
    return "ERROR"
  end
  return LetsCook.KEY_MAP[iKey]
end

-- Get the key code
-- @param string sKey the keyboard's key
-- @return int the mapped key code (index) 0..255 or -1 if not found
function LetsCook.getKeyCode(sKey)
  for k,v in pairs(LetsCook.KEY_MAP) do
    if v == sKey then
      return k
    end
  end
  return -1
end

LetsCook.KEY_MAP = {
  [0] = "",
  [1] = "Esc",
  [2] = "1",
  [3] = "2",
  [4] = "3",
  [5] = "4",
  [6] = "5",
  [7] = "6",
  [8] = "7",
  [9] = "8",
  [10] = "9",
  [11] = "0",
  [12] = "_", -- should be a '-', but this is differentiate from numpad -
  [13] = "=",
  [14] = "Backspace",
  [15] = "Tab",
  [16] = "Q",
  [17] = "W",
  [18] = "E",
  [19] = "R",
  [20] = "T",
  [21] = "Y",
  [22] = "U",
  [23] = "I",
  [24] = "O",
  [25] = "P",
  [26] = "[",
  [27] = "]",
  [28] = "Enter",
  [29] = "Left Ctrl",
  [30] = "A",
  [31] = "S",
  [32] = "D",
  [33] = "F",
  [34] = "G",
  [35] = "H",
  [36] = "J",
  [37] = "K",
  [38] = "L",
  [39] = ";",
  [40] = "'",
  [41] = "~",
  [42] = "Left Shift",
  [43] = "",
  [44] = "Z",
  [45] = "X",
  [46] = "C",
  [47] = "V",
  [48] = "B",
  [49] = "N",
  [50] = "M",
  [51] = ",",
  [52] = ".",
  [53] = "?", -- Should be a '/', Next to Right Shift. This is to differentiate from numpad divide
  [54] = "Right Shift",
  [55] = "*", -- numpad Multiply
  [56] = "Left Alt",
  [57] = "Space Bar",
  [58] = "Caps Lock",
  [59] = "F1",
  [60] = "F2",
  [61] = "F3",
  [62] = "F4",
  [63] = "F5",
  [64] = "F6",
  [65] = "F7",
  [66] = "F8",
  [67] = "F9",
  [68] = "F10",
  [69] = "Num Lock",
  [70] = "Scroll Lock",
  [71] = "numpad 7",
  [72] = "numpad 8",
  [73] = "numpad 9",
  [74] = "numpad -",
  [75] = "numpad 4",
  [76] = "numpad 5",
  [77] = "numpad 6",
  [78] = "numpad +",
  [79] = "numpad 1",
  [80] = "numpad 2",
  [81] = "numpad 3",
  [82] = "numpad 0",
  [83] = "numpad .",
  [84] = "",
  [85] = "",
  [86] = "",
  [87] = "F11",
  [88] = "F12",
  [89] = "",
  [90] = "",
  [91] = "",
  [92] = "",
  [93] = "",
  [94] = "",
  [95] = "",
  [96] = "",
  [97] = "",
  [98] = "",
  [99] = "",
  [100] = "",
  [101] = "",
  [102] = "",
  [103] = "",
  [104] = "",
  [105] = "",
  [106] = "",
  [107] = "",
  [108] = "",
  [109] = "",
  [110] = "",
  [111] = "",
  [112] = "",
  [113] = "",
  [114] = "",
  [115] = "",
  [116] = "",
  [117] = "",
  [118] = "",
  [119] = "",
  [120] = "",
  [121] = "",
  [122] = "",
  [123] = "",
  [124] = "",
  [125] = "",
  [126] = "",
  [127] = "",
  [128] = "",
  [129] = "",
  [130] = "",
  [131] = "",
  [132] = "",
  [133] = "",
  [134] = "",
  [135] = "",
  [136] = "",
  [137] = "",
  [138] = "",
  [139] = "",
  [140] = "",
  [141] = "",
  [142] = "",
  [143] = "",
  [144] = "",
  [145] = "",
  [146] = "",
  [147] = "",
  [148] = "",
  [149] = "",
  [150] = "",
  [151] = "",
  [152] = "",
  [153] = "",
  [154] = "",
  [155] = "",
  [156] = "Numpad Enter", -- Different from the "big Enter"
  [157] = "Right Ctrl",
  [158] = "",
  [159] = "",
  [160] = "",
  [161] = "",
  [162] = "",
  [163] = "",
  [164] = "",
  [165] = "",
  [166] = "",
  [167] = "",
  [168] = "",
  [169] = "",
  [170] = "",
  [171] = "",
  [172] = "",
  [173] = "",
  [174] = "",
  [175] = "",
  [176] = "",
  [177] = "",
  [178] = "",
  [179] = "",
  [180] = "",
  [181] = "/", -- numpad divide
  [182] = "",
  [183] = "",
  [184] = "Right Alt",
  [185] = "",
  [186] = "",
  [187] = "",
  [188] = "",
  [189] = "",
  [190] = "",
  [191] = "",
  [192] = "",
  [193] = "",
  [194] = "",
  [195] = "",
  [196] = "",
  [197] = "",
  [198] = "",
  [199] = "Home",
  [200] = "Up Arrow", -- the 4 directional arrows, NOT numpad
  [201] = "Page Up", -- NOT numlock numpad 7
  [202] = "",
  [203] = "Left Arrow", -- the 4 directional arrows, NOT numpad
  [204] = "",
  [205] = "Right Arrow", -- the 4 directional arrows, NOT numpad
  [206] = "",
  [207] = "End",
  [208] = "Down Arrow", -- the 4 directional arrows, NOT numpad
  [209] = "Page Down", -- NOT numlock numpad 3
  [210] = "Insert",
  [211] = "Delete",
  [212] = "",
  [213] = "",
  [214] = "",
  [215] = "",
  [216] = "",
  [217] = "",
  [218] = "",
  [219] = "Windows Key",
  [220] = "",
  [221] = "",
  [222] = "",
  [223] = "",
  [224] = "",
  [225] = "",
  [226] = "",
  [227] = "",
  [228] = "",
  [229] = "",
  [230] = "",
  [231] = "",
  [232] = "",
  [233] = "",
  [234] = "",
  [235] = "",
  [236] = "",
  [237] = "",
  [238] = "",
  [239] = "",
  [240] = "",
  [241] = "",
  [242] = "",
  [243] = "",
  [244] = "",
  [245] = "",
  [246] = "",
  [247] = "",
  [248] = "",
  [249] = "",
  [250] = "",
  [251] = "",
  [252] = "",
  [253] = "",
  [254] = "",
  [255] = "",
}
