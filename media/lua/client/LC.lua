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

LetsCook = LetsCook or {}
LetsCook.LOG = LetsCook.LOG or {}
LetsCook.LOG.debug = getCore():getDebug() or false
LetsCook.LOG.trace = false

LetsCook.ALL_FOOD_RECIPES = LetsCook.ALL_FOOD_RECIPES or {}
LetsCook.ALL_EVOLVED_RECIPES = LetsCook.ALL_EVOLVED_RECIPES or {}
LetsCook.ALL_EVOLVED_RECIPES['Rest'] = LetsCook.ALL_EVOLVED_RECIPES['Rest'] or {}
--LetsCook.ALL_VESSELS = LetsCook.ALL_VESSELS or {}

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
    local itemRecipe = pi[i]
    output = output .. LetsCook.debugPrintItemRecipe(itemRecipe)
  end    
  return output
end

function LetsCook.init()
  LetsCook.ALL_FOOD_RECIPES = {}
  local size = getAllRecipes():size()
  for i = 0, size - 1 do
    local v = getAllRecipes():get(i)
    if v:getCategory() == 'Cooking' then
      if LetsCook.LOG.debug then print("Adding recipe from list: " .. tostring(v:getName())) end
      table.insert(LetsCook.ALL_FOOD_RECIPES, v)
    end
  end
  LetsCook.ALL_EVOLVED_RECIPES['Rest'] = {}
  size = RecipeManager.getAllEvolvedRecipes():size()
  for i = 0, size - 1 do    
    local v = RecipeManager.getAllEvolvedRecipes():get(i)
    if v:isCookable() then
      if LetsCook.LOG.debug then print("Adding evolved recipe from list: " .. tostring(v:getName())) end
      table.insert(LetsCook.ALL_EVOLVED_RECIPES['Rest'], v)
      print(LetsCook.debugPrintEvolvedRecipe(v))
    end    
  end  
end
Events.OnGameStart.Add(LetsCook.init)

--[[
function LetsCook.addItemToListOfList(theList, item)
  if theList[item:getType()] == nil then 
    theList[item:getType()] = {}
  end
  table.insert(theList[item:getType()], item)
end

function LetsCook.hasCanOpener(item)
    local itemTags = item:getTags()
    local size = itemTags:size()
    for i = 0, size - 1 do
      local tag = itemTags:get(i) or "None"
      if tag == "CanOpener" then -- What about tag == "HasMetal"?
        return true
      end
    end
    return false
end

-- Inspect all items in the container
-- @param itemContainer [in] the container to rummage through
-- @foodList [in, out] add found food item to this list
-- @vesselList [in, out] add found vessel item to this list
-- @toolList [in, out] add found tool item to this list
function LetsCook.searchForItems(itemContainer, foodList, vesselList, toolList)
  if itemContainer then
    local items = itemContainer:getItems()
    local size = items:size() 
    for i = size - 1, 0, -1 do
      local item = items:get(i)
      if item ~= nil then
        if item:getCategory() == "Container" then
          -- unpack containers
          LetsCook.searchForItems(item:getInventory(), foodList, vesselList)
        elseif item:getDisplayCategory() == 'Cooking' or item:isCookable() then 
          -- 'Cooking': vessel (something like a pot with no water or griddle pan but also can opener)
          -- isCookable: vessel with water (usually?)
          -- if contain a tag of canopener
          if LetsCook.hasCanOpener(item) then
            LetsCook.addItemToListOfList(toolList, item)
          else
            LetsCook.addItemToListOfList(vesselList, item)
          end
        elseif item:IsFood() or item:getDisplayCategory() == 'Food' then 
          -- food item
          LetsCook.addItemToListOfList(foodList, item)
        end
      end
    end
  end
end

--Not used
function LetsCook.getEvolvedRecipeOnBaseItem(evolvedRecipes, baseItem)
  local size = evolvedRecipes:size()
  for i = 0, size - 1 do
    local evolvedRecipe = evolvedRecipes:get(i)
    if evolvedRecipe:getBaseItem() == baseItem then -- or is cookable?
      return evolvedRecipe
      --local output = "\n(" .. i .. ") "
      --output = output .. "\n\tBaseItem: " .. evolvedRecipe:getBaseItem()
      --output = output .. "\n\tgetFullResultItem: " .. evolvedRecipe:getFullResultItem()
      --output = output .. "\n\tgetOriginalname: " .. evolvedRecipe:getOriginalname()
      --output = output .. "\n\tgetPossibleItems: " .. tostring(evolvedRecipe:getPossibleItems())
      --output = output .. "\n\tgetResultItem: " .. evolvedRecipe:getResultItem()
      --output = output .. "\n\tgetName: " .. evolvedRecipe:getName()
      --output = output .. "\n\tgetMaxItems: " .. tostring(evolvedRecipe:getMaxItems())
      --output = output .. "\n\tgetItemsList: " .. tostring(evolvedRecipe:getItemsList())
      --print(output)
    end
  end 
  return nil
end

function LetsCook.weightFoodItem(foodItem)
  print("Food item" .. tostring(foodItem:getType()) .. " food type: " .. tostring(foodItem:getFoodType()))
  return 0
end

function LetsCook.getIngredientsAroundPlayer(allFoodList, allVesselList, allTools)
  -- get player inv
  local player = getPlayer()
  local container = player:getInventory()
  LetsCook.searchForItems(container, allFoodList, allVesselList, allTools)
  
  local roomDef = player:getCurrentRoomDef()
  if roomDef == nil then
    print("getIngredientsAroundPlayer roomDef is nil")
  end
  -- Get all containers around the player
  local playerSq = player:getCurrentSquare()
  local squares = {
    playerSq,
    getSquare(playerSq:getX() - 1, playerSq:getY() - 1, playerSq:getZ()),
    getSquare(playerSq:getX() + 0, playerSq:getY() - 1, playerSq:getZ()),
    getSquare(playerSq:getX() + 1, playerSq:getY() - 1, playerSq:getZ()),
    getSquare(playerSq:getX() - 1, playerSq:getY() + 0, playerSq:getZ()),
    getSquare(playerSq:getX() + 1, playerSq:getY() + 0, playerSq:getZ()),
    getSquare(playerSq:getX() - 1, playerSq:getY() + 1, playerSq:getZ()),
    getSquare(playerSq:getX() + 0, playerSq:getY() + 1, playerSq:getZ()),
    getSquare(playerSq:getX() + 1, playerSq:getY() + 1, playerSq:getZ())
  }
  -- to do, check if sqaure is in the same room as the player, what about out side?
  for k,v in pairs(squares) do
    local square = v
    if roomDef and roomDef:getID() ~= square:getRoomID() then
      print(k .. ": Removing square outside the room: roomDef ID = " .. roomDef:getID() .. " square room ID = " .. square:getRoomID())
      squares[k] = nil
    end    
  end
  
  for _, v in pairs(squares) do
    local square = v
    local objects = square:getObjects()
    local oSize = objects:size()
    for i = 0, oSize - 1 do
      local object = objects:get(i)
      if object and object:getContainerCount() > 0 and object:getContainer() and object:getContainer():getItems() and object:getContainer():getItems():size() > 0 then
        --we have a container, get items
        LetsCook.searchForItems(object:getContainer(), allFoodList, allVesselList, allTools)
      end
    end
  end  
end

function LetsCook.updateEvolvedRecipesTable(baseType) 
  if LetsCook.ALL_EVOLVED_RECIPES[baseType] then
    return
  end
  print("Checking evo rec for " .. baseType)
  for k,v in pairs(LetsCook.ALL_EVOLVED_RECIPES['Rest']) do
    print(k .. ": " .. v:getName() .. ", " .. v:getBaseItem())
    if baseType == v:getBaseItem() then
      LetsCook.ALL_EVOLVED_RECIPES[baseType] = v
      LetsCook.ALL_EVOLVED_RECIPES['Rest'][k] = nil
      print("Found evo rec for " .. baseType)
      return
    end    
  end 
  print("Found NO evo rec for " .. baseType)
end

function LetsCook.getRecipeFromResultingItems(itemType)
  local evoRec = RecipeManager.getAllEvolvedRecipes()
  for _, v in pairs(evoRec) do
    if itemType == v:getResultItem() then
      return v
    end
  end
  return nil
end

function LetsCook.needsWater(evo, vessel)
  return not LetsCook.startsWith(vessel:getType(), evo:getBaseItem())
end

local function onExample(player)
	player:Say("This is a custom slice!")
end

local function exampleFunction(menu, player)
	menu:addSlice("What's This?", getTexture("media/ui/emotes/shrug.png"), onExample, player)
end

LetsCook.showCookingUI = function(item)
  print("showCookingUI: ", tostring(item:getType()))  
  -- Get all food and vessel items
  local allFoodItems = {}
  local allVesselItems = {}
  local allTools = {}
  local availableRecipes = {}
  LetsCook.getIngredientsAroundPlayer(allFoodItems, allVesselItems, allTools)
  for _, vesselList in pairs(allVesselItems) do
    for k = 0, LetsCook.ALL_EVOLVED_RECIPES['Rest']:size() - 1 do
      local evo = LetsCook.ALL_EVOLVED_RECIPES['Rest']:get(k) 
      print(k .. ": " .. evo:getName() .. ", " .. evo:getBaseItem())
      for _, vessel in pairs(vesselList) do
        if LetsCook.checkCombs(vessel, evo) then
          if availableRecipes[evo:getName()] == nil then
            availableRecipes[evo:getName()] = {}
          end
          table.insert(availableRecipes[evo:getName()], {evo, vessel, LetsCook.needsWater(evo, vessel)})
          print("Found one")
          -- add evo rec to list of current evo rec
          -- table.insert(workingVessels, {item, v})
        end
      end      
    end
  end
  
  print("availableRecipes")
  for k, v in pairs(availableRecipes) do
    print(k .. ": " .. v[1]:getName() .. ", " .. v[1]:getBaseItem() .. ", " .. v[2]:getName() .. ", " .. tostring(v[3]))
  end  
  
  print("allVesselItems")
  for k, v in pairs(allVesselItems) do
    print(k .. ": " .. tostring(v[1][2]:getName()))
  end  
  
  print("allFoodItems")
  for k, v in pairs(allFoodItems) do
    print(k .. ": " .. tostring(v[1][2]:getName()))
  end  
  
  print("allTools")
  for k, v in pairs(allTools) do
    print(k .. ": " .. tostring(v[1][2]:getName()))
  end 

  LetsCookMenuAPI.registerSlice("example", exampleFunction)
end 

function LetsCook.splitString(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
      table.insert(t, str)
    end
  return t
end

-- Get the replacement type for WaterSource key in the map
-- Can return nil
function LetsCook.getTypeFromReplaceTypesMap(map)
  if map and map:containsKey("WaterSource") then
    local value = LetsCook.splitString(map:get("WaterSource"), ".")
    if #value >= 2 then
      return value[2]
    else
      print("Value is not what was expected: ", tostring(map:get("WaterSource")))
    end
  end  
  return nil
end

function LetsCook.startsWith(needle, haystack)
  if needle == nil or haystack == nil then
    return false
  end
 return string.sub(haystack, 1, string.len(needle)) == needle
end

-- Check if the item's type or replacement type is or is the start of the evolved recipe's base item (str) name
-- Truem we found a match, false we didn't
function LetsCook.checkCombs(item, evoRec)
  return LetsCook.startsWith(item:getType(), evoRec:getBaseItem()) or LetsCook.startsWith(LetsCook.getTypeFromReplaceTypesMap(item:getReplaceTypesMap()), evoRec:getBaseItem()) 
end

function LetsCook.sortOnEvoRecName(a, b)
  return a[2]:getName() < b[2]:getName()
end

-- Add let's cook menu item if at least one vessel is in an inventory context menu
-- For now, a vessel is where the item's type match a evolved recipe's base item (type)
-- Also, check if the replacment type, when adding water, will produce a type that match a evolved recipe's base item (type)
-- Stop at first find
LetsCook.letsCookMenu = function(playerID, context, items)
  --addCookingMenuItem(playerID, context, items)
  if not context:isReallyVisible() then
    return
  end
  print("***### Fill ###***")
  --fill(playerID, context, items)  
  --local workingVessels = {}
  local foundItem = nil
  items = ISInventoryPane.getActualItems(items)
  for _, item in pairs(items) do
    for k = 0, LetsCook.ALL_EVOLVED_RECIPES['Rest']:size() - 1 do
      local v = LetsCook.ALL_EVOLVED_RECIPES['Rest']:get(k) 
      print(k .. ": " .. v:getName() .. ", " .. v:getBaseItem())
      if LetsCook.checkCombs(item, v) then
        print("Found one")
        -- add evo rec to list of current evo rec
        foundItem = item
        break
        --table.insert(workingVessels, {item, v})
      end      
    end
  end
  --table.sort(workingVessels, sortOnEvoRecName)
  --for k, v in pairs(workingVessels) do
  --  print(k .. ": " .. v[1]:getName() .. ", " .. v[2]:getName())
  --end
  if foundItem ~= nil then
    context:addOption(getText("ContextMenu_LetsCookMenu"), foundItem, LetsCook.showCookingUI)
  end
  print("***###___###***")
end

Events.OnFillInventoryObjectContextMenu.Add(LetsCook.letsCookMenu)

-- To do
--local function onKeyPressed(keynum)
--    if not MainScreen.instance or not MainScreen.instance.inGame or MainScreen.instance:getIsVisible() then return; end
--    local playerObj = getSpecificPlayer(0);
--    if not playerObj then return; end
--    if playerObj:getVehicle() then return; end
--
--    if playerObj ~= nil then
--        if keynum == KEY_BM.key then
--            ISBuildingMenuUI:toggleBuildingMenuUI(playerObj);
--        end
--    end
--end
--Events.OnKeyPressed.Add(onKeyPressed)
]]


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
