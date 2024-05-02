LetsCook = LetsCook or {}
LetsCook.ALL_RECIPES = LetsCook.ALL_RECIPES or getAllRecipes()
LetsCook.ALL_EVOLVED_RECIPES = LetsCook.ALL_EVOLVED_RECIPES or {}
LetsCook.ALL_EVOLVED_RECIPES['Rest'] = LetsCook.ALL_EVOLVED_RECIPES['Rest'] or RecipeManager.getAllEvolvedRecipes()
LetsCook.ALL_VESSELS = LetsCook.ALL_VESSELS or {}

function LetsCook.init()
  -- prune ALL_RECIPES
  for k,v in pairs(LetsCook.ALL_RECIPES) do
    if v.getCategory() ~= 'Cooking' then
      print("Removing recipe from list: " .. v:getName() .. ": " .. v.getCategory())
      LetsCook.ALL_RECIPES[k] = nil
    end
  end
  -- prune ALL_EVOLVED_RECIPES
  for k,v in pairs(LetsCook.ALL_EVOLVED_RECIPES['Rest']) do
    if not v.isCookable() then
      print("Removing evolved recipe from list: " .. v:getName() .. ": " .. v.getCategory())
      LetsCook.ALL_EVOLVED_RECIPES['Rest'][k] = nil
    end    
  end  
end
Events.OnGameStart.Add(LetsCook.init)

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
