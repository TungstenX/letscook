--[[
┌────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ _/_/_/_/_/  _/    _/  _/      _/    _/_/_/    _/_/_/  _/_/_/_/_/  _/_/_/_/  _/      _/  _/      _/ │    
│    _/      _/    _/  _/_/    _/  _/        _/            _/      _/        _/_/    _/    _/  _/    │   
│   _/      _/    _/  _/  _/  _/  _/  _/_/    _/_/        _/      _/_/_/    _/  _/  _/      _/       │   
│  _/      _/    _/  _/    _/_/  _/    _/        _/      _/      _/        _/    _/_/    _/  _/      │   
│ _/        _/_/    _/      _/    _/_/_/  _/_/_/        _/      _/_/_/_/  _/      _/  _/      _/     │   
├────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ © Copyright 2025                                                                                   │ 
└────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────┐
│ Lets Cook Menu │
└────────────────┘
Version: 1.03
]]
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISAddItemInRecipe"
-- TODO: Check if pot is full of water (can do evo recipe)
-- TODO: click hold to increase amount
-- TODO: ModOptions
-- TODO: Search if there is a build in function to get all itemcontainers around player
LCMenu = LCMenu or {}
LCMenu.LOG = LCMenu.LOG or {}
LCMenu.LOG.debug = getCore():getDebug() or false
LCMenu.LOG.trace = false
LCMenu.UI = {}
LCMenu.somethingTicked = false
LCMenu.joinedGameNow = true
LCMenu.foodList = {}
LCMenu.vesselList = {}
LCMenu.toolList = {}
LCMenu.currentIngredients = LCMenu.currentIngredients or {}
LCMenu.ingredientShown = LCMenu.ingredientShown or {}

--[[
* Loop through selected items
* If selected item is a can, then open it and add the open can to the selected item list
* Do the vanilla add ingredients to base (or result) item per loop
* @param IsoPlayer playerObj         - The player object
* @param EvolvedRecipe evolvedRecipe - The evolved recipe object
* @param InventoryItem baseItem      - The evolved recipe's base item
]]
function LCMenu.mixIngredients(playerObj, evolvedRecipe, baseItem)  
  local returnToContainer = {}
  
  for _, inventoryItem in pairs(LCMenu.currentIngredients) do
    if inventoryItem then
      local md = inventoryItem:getModData()
      if not md.lcIgnore then
        local name = inventoryItem:getType()
        if not LCUtil.endsWith("Open", name) and (LCUtil.startsWith("Canned", name) or LCUtil.startsWith("Tinned", name) or LCUtil.startsWith("TunaTin", name)) then
          for _, recipe in pairs(LetsCook.ALL_FOOD_RECIPES) do          
            if LCUtil.startsWith("Canned", name) then
              name = string.sub(name, string.len("Canned") + 1)
            end
          
            if LCUtil.startsWith("Tinned", name) then
              name = string.sub(name, string.len("Tinned") + 1)
            end
          
            if name == "TunaTin" then
              name = "Tuna"
            end
        
            if LCUtil.endsWith("2", name) then
              name = string.sub(name, 1, string.len(name) - 1)
            end
            if recipe:getOriginalname() == "Open Canned " .. name then
              LCMenu.openCan(inventoryItem, recipe, playerObj, evolvedRecipe)
            end
          end
        else
          if not playerObj:getInventory():contains(inventoryItem) then -- take the item if it's not in our inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, inventoryItem, inventoryItem:getContainer(), playerObj:getInventory(), nil))
            table.insert(returnToContainer, inventoryItem)
          end
          if not playerObj:getInventory():contains(baseItem) then -- take the base item if it's not in our inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, baseItem, baseItem:getContainer(), playerObj:getInventory(), nil))
            table.insert(returnToContainer, baseItem)
          end
          LCMenu.currentBaseItem = baseItem
          ISTimedActionQueue.add(ISAddItemInRecipe:new(playerObj, evolvedRecipe, baseItem, inventoryItem, (70 - playerObj:getPerkLevel(Perks.Cooking))))
        end
      elseif LCMenu.LOG.debug then
        print("mixIngredients: inventory item is nil")
      end
    end
  end
  -- release memory early
  LCMenu.currentIngredients = {}
end

--[[
* Call the Timed Action to open can.
* @param InventoryItem selectedItem  - The can to be opened
* @param Recipe recipe               - The recipe to open that can
* @param IsoPlayer playerObj         - The player object
* @param EvolvedRecipe evolvedRecipe - The evolved recipe object
]]
function LCMenu.openCan(selectedItem, recipe, playerObj, evolvedRecipe)
	local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
	local container = selectedItem:getContainer()
	if not recipe:isCanBeDoneFromFloor() then
		container = playerObj:getInventory()
	end
	local items = RecipeManager.getAvailableItemsNeeded(recipe, playerObj, containers, selectedItem, nil)
	local returnToContainer = {}; -- keep track of items we moved to put them back to their original container
	if not recipe:isCanBeDoneFromFloor() then
		for i = 1, items:size() do
			local item = items:get(i - 1)
			if item:getContainer() ~= playerObj:getInventory() then
				ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerObj:getInventory(), nil))
				table.insert(returnToContainer, item)
			end
		end
	end
  
  local additionalTime = 0
  if container == playerObj:getInventory() and recipe:isCanBeDoneFromFloor() then
    for i = 1, items:size() do
      local item = items:get(i - 1)
      if item:getContainer() ~= playerObj:getInventory() then
        local w = item:getActualWeight()
        if w > 3 then w = 3; end
        additionalTime = additionalTime + 50*w
      end
    end
  end
  
	local action = ISCraftAction:new(playerObj, selectedItem, recipe:getTimeToMake() + additionalTime, recipe, container, containers)
	action:setOnComplete(LCMenu.OnCraftComplete, action, recipe, playerObj, evolvedRecipe, selectedItem:getFullType())
	ISTimedActionQueue.add(action)
  -- add back their item to their original container
  ISCraftingUI.ReturnItemsToOriginalContainer(playerObj, returnToContainer)
end

--[[
* Finish up the can opening by adding the open can to the selected item list
* @param ? completedAction              - [not used]
* @param Recipe recipe                  - The recipe to open that can
* @param IsoPlayer playerObj            - The player object
* @param EvolvedRecipe evolvedRecipe    - The evolved recipe object
* @param InventoryItem selectedItemType - The selected item
]]
function LCMenu.OnCraftComplete(completedAction, recipe, playerObj, evolvedRecipe, selectedItemType)  
  for k, inventoryItem in pairs(LCMenu.currentIngredients) do
    if inventoryItem then
      local itemFullType = inventoryItem:getFullType()
      if itemFullType == selectedItemType then
        table.remove(LCMenu.currentIngredients, k)
        break
      end
    elseif LCMenu.LOG.debug then
      print("Not removing nil item")
    end
  end
  
  local inventoryItem = playerObj:getInventory():getItemFromType(recipe:getResult():getFullType())
  if inventoryItem then
    table.insert(LCMenu.currentIngredients, inventoryItem)
  elseif LCMenu.LOG.debug then
    print("Not adding nil item")
  end
  -- do the next
  LCMenu.mixIngredients(playerObj, evolvedRecipe)
end

--[[
* Counting the ingredients and not the spices in LCMenu.currentIngredients array
]]
function LCMenu.countIngredientsOnly()
  local count = 0
  if LCMenu.LOG.debug then print("countIngredientsOnly: " .. tostring(#LCMenu.currentIngredients)) end
  for _, inventoryItem in pairs(LCMenu.currentIngredients) do
    if not inventoryItem:isSpice() then
      count = count + 1
    end
  end
  return count
end

--[[
* Taverse the supplied inventory (item container)
* @param IsoPlayer playerObj         - The player object
* @param ItemContainer itemContainer - The item container / inventory
]]
function LCMenu.taverseInventory(playerObj, itemContainer)
  if not instanceof(itemContainer, "ItemContainer") then
    if instanceof(itemContainer, "InventoryContainer") then
      itemContainer = itemContainer:getItemContainer()
    else
      if LCMenu.LOG.debug then print("taverseInventory was not supplied with an item container: " .. tostring(itemContainer)) end
      return
    end
  end
  
  local inventoryItemList = itemContainer:getItems()
  local size = inventoryItemList:size()
  
  for i = size - 1, 0, -1 do
    local inventoryItem = inventoryItemList:get(i)
    if inventoryItem and instanceof(inventoryItem, "Food") and inventoryItem:getType() ~= "Cigarettes" then
      -- check skill level - don't add rotten food if cooking skill is 6 or below
      local cookingLvl = playerObj:getPerkLevel(Perks.Cooking)
      local age = inventoryItem:getAge()
      local offAgeMax = inventoryItem:getOffAgeMax()
      if age < offAgeMax and cookingLvl > 6 then
        if LCMenu.LOG.debug then print("Adding: " .. inventoryItem:getName()) end
        table.insert(LCMenu.allIngredients, inventoryItem)
      end
    elseif inventoryItem and inventoryItem:IsInventoryContainer() then
      LCMenu.taverseInventory(playerObj, inventoryItem, evorecipe)
    end
  end
end

--[[
* Get all food items from the player's inventory as well as the 3x3 cells around the player. (There might be a function already for this)
* @param IsoPlayer playerObj - The player object
]]
function LCMenu.getAllIngredients(playerObj)
  LCMenu.allIngredients = {}
  local itemContainer = playerObj:getInventory()--:getAllCategory("Food")
  LCMenu.taverseInventory(playerObj, itemContainer, evorecipe)
  if LCMenu.LOG.debug then print("allIngredients size after player inventory(s) = " .. tostring(#LCMenu.allIngredients)) end
  
  local square = playerObj:getCurrentSquare()
  local playerIsoRoom = square:getRoom()
  local playerRoomName = "OUTSIDE"
  if playerIsoRoom then
    playerRoomName = playerIsoRoom:getName()
  end
  if LCMenu.LOG.debug then print("allIngredients player room = " .. tostring(playerRoomName)) end
  for x = -1, 1 do
    for y = -1, 1 do      
      local sq = getSquare(square:getX() + x, square:getY() + y, square:getZ())
      local sqIsoRoom = sq:getRoom()
      local sqRoomName = "OUTSIDE"
      if sqIsoRoom then
        sqRoomName = sqIsoRoom:getName()
      end    
      if sqRoomName == playerRoomName then
        local objects = sq:getObjects()
        if objects then
          local size = objects:size()
          for i = 0, size - 1 do
            local object = objects:get(i)
            if object and object:getContainerCount() > 0 and object:getContainer() and object:getContainer():getItems() and object:getContainer():getItems():size() > 0 then
              LCMenu.taverseInventory(playerObj, object:getContainer())
            end
          end
        end
      end
    end
  end
  
  table.sort(LCMenu.allIngredients, LCMenu.sortFreshFirst)
  
  if LCMenu.LOG.debug then print("allIngredients size after 3x3 squares inventory(s) = " .. tostring(#LCMenu.allIngredients)) end
end

--[[
* Make freshness level based on age, offAge, offAgeMax
* @param float age       - age (of the item)
* @param float offAge    - days before item becomes stale
* @param float offAgeMax - days before item becomes rotten
* @return int - 0, 1, 2, 3 -> not set/don't use, rotten, stale, fresh
]]
local function getFreshLevel(age, offAge, offAgeMax)
  if age - offAge > 0 then
    return 3
  elseif age - offAge < 0 and age - offAgeMax > 0 then
    return 2
  elseif age - offAgeMax < 0 then
    return 1
  end
  return 0 --paranoid android
end

--[[
* The rules:
*   1 Spice last, if both spice, then which one makes more happy
*   2 Fresh before canned and other stuff that will not go off
*       is fresh offAge < 1000000000
*   3 if both fresh then fresh level
*       fresh (3): Age - offAge > 0
*       stale (2):  Age - offAge < 0 and Age - offAgeMax > 0
*       rotten(1): Age - offAgeMax < 0
*   4 same fresh level then check hunger change (x -1) largest first
*   5 same hunger change (x -1) check Calories largest first
*   6 same Calorie then youngest first (<age)
*   7 else true*
* @parma InventoryItem leftInventoryItem  - the left inventory item
* @parma InventoryItem rightInventoryItem - the right inventory item
* @param boolean - true then left inventory item earlier in array, else the right one
]]
function LCMenu.sortFreshFirst(leftInventoryItem, rightInventoryItem)
  local leftIsSpice  = leftInventoryItem:isSpice()
  local rightIsSpice = rightInventoryItem:isSpice()
  -- 1
  if leftIsSpice ~= rightIsSpice then
    return rightIsSpice
  elseif leftIsSpice then -- both spice leftIsSpice == rightIsSpice, which one more happy
    return leftInventoryItem:getUnhappyChange() > rightInventoryItem:getUnhappyChange()
  end
  -- 2
  local leftAge        = leftInventoryItem:getAge()
  local leftOffAge     = leftInventoryItem:getOffAge()
  local leftOffAgeMax  = leftInventoryItem:getOffAgeMax()
  local rightAge       = rightInventoryItem:getAge()
  local rightOffAge    = rightInventoryItem:getOffAge()
  local rightOffAgeMax = rightInventoryItem:getOffAgeMax()
  
  local leftIsFresh  = leftOffAge < 1000000000
  local rightIsFresh = rightOffAge < 1000000000
  
  -- either left or right is fresh, not both
  if leftIsFresh ~= rightIsFresh then
    return leftIsFresh
  end
  -- 3
  -- both left and right are fresh
  local leftFreshLevel  = 0
  local rightFreshLevel = 0
  if leftIsFresh then
    leftFreshLevel =  getFreshLevel(leftAge, leftOffAge, leftOffAgeMax)
  end
  if rightIsFresh then
    rightFreshLevel =  getFreshLevel(rightAge, rightOffAge, rightOffAgeMax)
  end
  
  -- left and right is not on the same fresh level
  if leftFreshLevel ~= rightFreshLevel then
    return leftFreshLevel < rightFreshLevel
  end
  -- 4
  -- both left and right are on the same fresh level
  local leftHungerChange  = (-1 * leftInventoryItem:getHungerChange())
  local rightHungerChange = (-1 * rightInventoryItem:getHungerChange())
  
  -- left and right is not on the same hunger change
  if leftHungerChange ~= rightHungerChange then
    return leftHungerChange > rightHungerChange
  end
  --5
  -- left and right is not on the same hunger change
  local leftCaloriesChange  = leftInventoryItem:getCalories()
  local rightCaloriesChange = rightInventoryItem:getCalories()
  
  if leftCaloriesChange ~= rightCaloriesChange then
    return leftCaloriesChange > rightCaloriesChange
  end
  -- 6
  if leftAge ~= rightAge then
    return leftAge < rightAge
  end
  -- 7
  return true
end

--[[
* Count the number of items in the supplied array and return true if there are more than 1 of these item full type in the array
* @param string itemType - the full type of an item
* @param array allInv    - an array of InventoryItem
* @return boolean - true if there are more than 1 item in the array with the same full type as the supplied full type
]]
function hasEnough(itemType, allInv)
  local countCorrectItems = 0
  for _, inventoryItem in pairs(allInv) do
    if inventoryItem:getFullType() == itemType then
      countCorrectItems = countCorrectItems + 1
    end
  end
  return (countCorrectItems > 0)
end

--[[
* Return the unopened full type of the supplied item if the supplied have tin openers is true and the supplied item's full type starts with Canned, Tinned or TunaTin and ends with Open. Or if the supplied item's full type is OpenBeans
* @param InventoryItem itemRecipe - The item to check
* @param boolean haveTinOpeners   - Does the player have a can opener
* @return string - the supplied item's full type or the changed full type
]]
function makeFullType(itemRecipe, haveTinOpeners)
  local fullType = itemRecipe:getFullType()
  -- Process unopened cans as fullType
  local name = itemRecipe:getName()
  if haveTinOpeners and 
    (LCUtil.startsWith("Canned", name) or 
     LCUtil.startsWith("Tinned", name) or 
     LCUtil.startsWith("TunaTin", name)) 
    and LCUtil.endsWith("Open", name) then
        
    fullType = string.sub(fullType, 1, string.len(fullType) - string.len("Open"))
    -- The #2 cans?
    if fullType == "Base.CannedTomato" or fullType == "Base.CannedCarrots" or fullType == "Base.CannedPotato" then
      fullType = fullType .. "2"
    end
  end 
  
  -- exception can: OpenBeans => TinnedBeans
  if haveTinOpeners and name == "OpenBeans" then
    fullType = "Base.TinnedBeans"
  end
  return fullType
end

--[[
* Format the supplied float
* @param float f - the value to be formatted
* @return string - formatted float
]]
local function formatFoodValue(f)
	return string.format("%+.2f", f)
end

--[[
* Make the display name for the supplied item
* @param InventoryItem inventoryItem - The supplied item
* @param int noOfIng                 - The number of ingriedents / items already added
* @return string - The string to be used as a display name
]]
local function makeDisplayName(inventoryItem, noOfIng)
  local displayName = inventoryItem:getDisplayName()
  
  if noOfIng > 0 then
    displayName = displayName .. " [ " .. tostring(noOfIng) .. "]"
  end
  
  local maxLabelLength = 0
  local labelHunger = getText("Tooltip_food_Hunger")
  local labelThirst = getText("Tooltip_food_Thirst")
  local labelUnhappy = getText("Tooltip_food_Unhappiness")
  if inventoryItem:getHungerChange() ~= 0.0 and maxLabelLength < string.len(labelHunger) then
    maxLabelLength = string.len(labelHunger)
  end
  if inventoryItem:getThirstChange() ~= 0.0 and maxLabelLength < string.len(labelThirst) then
    maxLabelLength = string.len(labelThirst)
  end
  if inventoryItem:getUnhappyChange() ~= 0.0 and maxLabelLength < string.len(labelUnhappy) then
    maxLabelLength = string.len(labelUnhappy)
  end
    
  if inventoryItem:getHungerChange() ~= 0.0 then
    displayName = displayName .. "\n" .. labelHunger .. ": " .. formatFoodValue(inventoryItem:getHungerChange() * 100.0)
  end
  if inventoryItem:getThirstChange() ~= 0.0 then
    displayName = displayName .. "\n" .. labelThirst .. ": " .. formatFoodValue(inventoryItem:getThirstChange() * 100.0)
  end
  if inventoryItem:getUnhappyChange() ~= 0.0 then
    displayName = displayName .. "\n" .. labelUnhappy .. ": " .. formatFoodValue(inventoryItem:getUnhappyChange())
  end
  return displayName
end

--[[
* Add ingredient(s) to the LCMenu.currentIngredients array and create a new menu to display
* @param IsoPlayer playerObj            - The player object
* @param EvolvedRecipe evolvedRecipe    - The evolved recipe object
* @param InventoryItem evoItem          - The base/result item
* @param InventoryItem inventoryItem    - The selected item
* @param int startAt                    - Start index for paging
]]
function LCMenu.addIngredients(playerObj, evolvedRecipe, evoItem, inventoryItem, startAt)
  if LCMenu.LOG.debug then print("addIngredients: " .. tostring(#LCMenu.currentIngredients)) end
  if inventoryItem ~= nil then
    table.insert(LCMenu.currentIngredients, inventoryItem)
    LCUtil.removeFirstItem(inventoryItem:getFullType(), LCMenu.allIngredients)
  end
    
  local menu = LCMenu.menuStart(playerObj)
  if menu == nil then return end
  
  LCMenu.ingredientShown = {}  
  local ingredientsOnly = LCMenu.countIngredientsOnly()
  
  local canAddIngredient = ingredientsOnly < evolvedRecipe:getMaxItems()
  local itemContainer = playerObj:getInventory() -- for can/tin opener
  
  local haveTinOpeners = itemContainer:containsTypeRecurse("TinOpener")
  
  local pi = evolvedRecipe:getPossibleItems()
  local size = pi:size()
  -- first get all ingredients that we have and is possible items
  local ingredientsToUse = {}
  
  -- Run through the ingredients list first, rather than sorting the pi entries as well
  for _, inventoryItem in pairs(LCMenu.allIngredients) do
    local fullTypeInventoryItem = inventoryItem:getFullType()    
    if not LCMenu.ingredientShown[fullTypeInventoryItem] then
      LCMenu.ingredientShown[fullTypeInventoryItem] = true      
      local spice = inventoryItem:isSpice()
      local used = LCUtil.containsFullType(fullTypeInventoryItem, LCMenu.currentIngredients)
      local show = (not canAddIngredient and spice and not used) or (canAddIngredient and not spice) or (canAddIngredient and spice and not used)      
      if show then 
        for i = 0, size - 1 do
          local itemRecipe = pi:get(i)
          local fullTypeItemRecipe = makeFullType(itemRecipe, haveTinOpeners)          
          if fullTypeItemRecipe == fullTypeInventoryItem or itemRecipe:getFullType() == fullTypeInventoryItem then
            if LCMenu.LOG.debug then print("addIngredients selecting item full type: " .. tostring(fullTypeInventoryItem)) end
            table.insert(ingredientsToUse, inventoryItem)
          end
        end
      end      
    end
  end
  
  if startAt == nil then
    startAt = 1
  end
  
  local intervalStartAt = 12 -- TODO: ModOptions
  local minTries = intervalStartAt
  size = #ingredientsToUse
  local i = startAt
  while ((i <= size) and (minTries > 0)) do
    local inventoryItem = ingredientsToUse[i]
    i = i + 1      
    minTries = minTries - 1
    local tex = inventoryItem:getTexture()
    
    local noOfIng = LCUtil.count(inventoryItem, LCMenu.currentIngredients)
    
    local displayName = makeDisplayName(inventoryItem, noOfIng)
      
    menu:addSlice(displayName, tex, LCMenu.addIngredients, playerObj, evolvedRecipe, evoItem, inventoryItem, startAt)
  end  
  
  if (i <= size) then
    local tex = getTexture("media/ui/Moodle_internal_plus_green.png")
    menu:addSlice(getText("IGUI_LC_Slice_Next_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, evoItem, nil, startAt + intervalStartAt)
  else
    local tex = getTexture("media/ui/Moodle_internal_plus_red.png")
    menu:addSlice(getText("IGUI_LC_Slice_No_Next_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, evoItem, nil, startAt)
  end
  if (startAt > 1) then
    local tex = getTexture("media/ui/Moodle_internal_minus_green.png")
    menu:addSlice(getText("IGUI_LC_Slice_Prev_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, evoItem, nil, startAt - intervalStartAt)
  else 
    local tex = getTexture("media/ui/Moodle_internal_minus_red.png")
    menu:addSlice(getText("IGUI_LC_Slice_No_Prev_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, evoItem, nil, startAt)
  end
  
  local nextStep = getText("IGUI_LC_Slice_Next_Step") .. " [" .. tostring(ingredientsOnly or "0") .. "/" .. tostring(evolvedRecipe:getMaxItems()) .. "]"
    
  if ingredientsOnly == 0 then
    LCMenu.addEvoSlice(menu, evoItem, playerObj, LCMenu.addIngredients, nextStep, evolvedRecipe)
  else
    LCMenu.addEvoSlice(menu, evoItem, playerObj, LCMenu.mixIngredients, nextStep, evolvedRecipe)
  end
  
  LCMenu.menuEnd(menu)
end

--[[
* Boiler plate for making a radial menu
* @param IsoPlayer playerObj - The player object
]]
function LCMenu.menuStart(playerObj)
  local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
	if isPaused then return nil end
  
 	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
	menu:clear()
	if menu:isReallyVisible() then
		if menu.joyfocus then
			setJoypadFocus(playerObj:getPlayerNum(), nil)
		end
		menu:undisplay()
		return menu --nil?
	end
  return menu
end

--[[
* Boiler plate for finishing up a radial menu
* @param ? menu - The radial menu object
]]
function LCMenu.menuEnd(menu)
	menu:center()
	menu:addToUIManager()
end

--[[
* Add a slice to the radial menu
* @param ? menu                         - The radial menu object
* @param InventoryItem inventoryItem    - The selected item
* @param IsoPlayer playerObj            - The player object
* @param lua function func              - The function to call when menu slice is clicked
* @param string description             - The description
* @param lua table data                 - Extra data    
]]
function LCMenu.addEvoSlice(menu, inventoryItem, playerObj, func, description, data)
  local tex = inventoryItem:getTexture()
  menu:addSlice(description, tex, func, playerObj, data, inventoryItem)
end

--[[
* Create the radial menu
]]
function LCMenu.create()
  local playerObj = getPlayer()
  local menu = LCMenu.menuStart(playerObj)
  if menu == nil then return end

  --Reset ingredients
  LCMenu.currentIngredients = {}
  
  LCMenu.getAllIngredients(playerObj)
  local itemContainer = playerObj:getInventory()
  
  for _, evolvedRecipe in pairs(LetsCook.ALL_EVOLVED_RECIPES) do
    if itemContainer then
      --Frist check half made stuff
      local evoItem = nil      
      if itemContainer:contains(evolvedRecipe:getResultItem()) then
        evoItem = itemContainer:getItemFromTypeRecurse(evolvedRecipe:getResultItem())
      elseif itemContainer:contains(evolvedRecipe:getBaseItem()) then        
        evoItem = itemContainer:getItemFromTypeRecurse(evolvedRecipe:getBaseItem())
      end      
      if evoItem and (not instanceof(evoItem, "DrainableComboItem") or (instanceof(evoItem, "DrainableComboItem") and evoItem:getDelta() == 1.0)) then
        LCMenu.checkAlreadyAdded(evoItem)
        LCMenu.addEvoSlice(menu, evoItem, playerObj, LCMenu.addIngredients, evolvedRecipe:getOriginalname(), evolvedRecipe)
      end
    end    
  end

  LCMenu.menuEnd(menu)
end

function LCMenu.checkAlreadyAdded(evoItem)  
  if LCMenu.LOG.debug then print("checkAlreadyAdded: " .. tostring(#LCMenu.currentIngredients)) end
  local ingAlreadyUse = evoItem:getExtraItems()
  if ingAlreadyUse then
    local size = ingAlreadyUse:size()
    for i = 0, size - 1 do
      local itemFullType = ingAlreadyUse:get(i)
      local dummyItem = InventoryItemFactory.CreateItem(itemFullType)
      local md = dummyItem:getModData()
      md.lcIgnore = true
      table.insert(LCMenu.currentIngredients, dummyItem)
    end
  end
  
  if instanceof(evoItem, "Food") then
    local spicesAlreadyUse = evoItem:getSpices()  
    if spicesAlreadyUse then
      local size = spicesAlreadyUse:size()
      for i = 0, size - 1 do
        local itemFullType = spicesAlreadyUse:get(i)
        local dummyItem = InventoryItemFactory.CreateItem(itemFullType)
        local md = dummyItem:getModData()
        md.lcIgnore = true
        table.insert(LCMenu.currentIngredients, dummyItem)
      end
    end
  end
  if LCMenu.LOG.debug then print("checkAlreadyAdded: " .. tostring(#LCMenu.currentIngredients)) end
end

--[[
* Create the radial menu
* @param InventoryItem evoItem       - The base/result item
* @param IsoPlayer playerObj         - The player object
* @param EvolvedRecipe evolvedRecipe - The evolved recipe object
]]
function LCMenu.createByMenu(evoItem, playerObj, evolvedRecipe)
  
  --Reset ingredients
  LCMenu.currentIngredients = {}  
  LCMenu.getAllIngredients(playerObj)
  LCMenu.checkAlreadyAdded(evoItem)
  LCMenu.addIngredients(playerObj, evolvedRecipe, evoItem)
end

--[[
Debug stuff
]]
local function testContextMenu(playerIndex, context, worldObjects, test)
	context:addOption("Test 1 - Open LC Menu", getSpecificPlayer(playerIndex), LCMenu.create)
end
if LCMenu.LOG.debug then
  Events.OnFillWorldObjectContextMenu.Add(testContextMenu)
end

--[[
* Handle event
]]
function LCMenu.OnFillInventoryObjectContextMenu(playerNum, context, items)
  local player = getSpecificPlayer(playerNum)
  if player:getVehicle() then
    return -- can't work in a vehicle
  end
  
  local tempItem = nil
  local item = nil
  local evoRecipe = nil
  
  for _, v in ipairs(items) do
    if not instanceof(v, "InventoryItem") then
      if #v.items == 2 then
        tempItem = v.items[1]
      end
      tempItem = v.items[1]
    else
      tempItem = v
    end

    if tempItem then
      for _, evolvedRecipe in pairs(LetsCook.ALL_EVOLVED_RECIPES) do
        if tempItem:getType() == evolvedRecipe:getResultItem() or tempItem:getType() == evolvedRecipe:getBaseItem() then
          item = tempItem
          evoRecipe = evolvedRecipe
          break
        end
      end    
    end
  end

	if item and (not instanceof(item, "DrainableComboItem") or (instanceof(item, "DrainableComboItem") and item:getDelta() == 1.0)) then
    context:addOptionOnTop(getText("ContextMenu_LetsCookMenu"), item, LCMenu.createByMenu, player, evoRecipe)
  end

  return context
end
Events.OnFillInventoryObjectContextMenu.Add(LCMenu.OnFillInventoryObjectContextMenu)

--[[
* Key binding stuff
]]
function LCMenu.createBindings()
	local bindings = {
		{
      name = '[LC]'
    },
    {
      value = "OpenMenu",
			action = LCMenu.create,
      key = Keyboard.KEY_C,
    },
	}
	for _, bind in ipairs(bindings) do
    if bind.name then
      table.insert(keyBinding, { value = bind.name, key = nil })
		else 
      if bind.key then
        table.insert(keyBinding, { value = bind.value, key = bind.key })
			end
		end
	end

	LCMenu.createAction = function(key)
    local player = getSpecificPlayer(0)
    local action
    for _, bind in ipairs(bindings) do
      if key == getCore():getKey(bind.value) then
        action = bind.action
      end
    end

		if not action or not player or player:isDead() then
			return 
		end
		action(player)
	end

  Events.OnGameStart.Add(function()
    Events.OnKeyPressed.Add(LCMenu.createAction)
  end)  
end
Events.OnGameBoot.Add(LCMenu.createBindings)