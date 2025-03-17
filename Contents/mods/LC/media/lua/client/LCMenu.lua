--[[
┌────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ _/_/_/_/_/  _/    _/  _/      _/    _/_/_/    _/_/_/  _/_/_/_/_/  _/_/_/_/  _/      _/  _/      _/ │    
│    _/      _/    _/  _/_/    _/  _/        _/            _/      _/        _/_/    _/    _/  _/    │   
│   _/      _/    _/  _/  _/  _/  _/  _/_/    _/_/        _/      _/_/_/    _/  _/  _/      _/       │   
│  _/      _/    _/  _/    _/_/  _/    _/        _/      _/      _/        _/    _/_/    _/  _/      │   
│ _/        _/_/    _/      _/    _/_/_/  _/_/_/        _/      _/_/_/_/  _/      _/  _/      _/     │   
├────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ © Copyright 2024                                                                                   │ 
└────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────┐
│ Lets Cook Menu │
└────────────────┘
]]
-- TODO: Check if pot is full (can do evo recipe)
-- TODO: Change number of items when using resultItem for baseItem
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

function LCMenu.mixIngredients(playerObj, evolvedRecipe)  
  local returnToContainer = {};
  local baseItemFullType = evolvedRecipe:getResultItem()
  if not playerObj:getInventory():contains(baseItemFullType) then
    baseItemFullType = evolvedRecipe:getBaseItem()
  end
  local baseItem = playerObj:getInventory():getItemFromType(baseItemFullType)
  
  for _, inventoryItem in pairs(LCMenu.currentIngredients) do
    if inventoryItem then
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
            return
          end
        end
      else
        if not playerObj:getInventory():contains(inventoryItem) then -- take the item if it's not in our inventory
          ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, inventoryItem, inventoryItem:getContainer(), playerObj:getInventory(), nil))
          table.insert(returnToContainer, inventoryItem)
        end
        if not playerObj:getInventory():contains(baseItem) then -- take the base item if it's not in our inventory
          ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, baseItem, baseItem:getContainer(), playerObj:getInventory(), nil))
          table.insert(returnToContainer, button.baseItem)
        end
        ISTimedActionQueue.add(ISAddItemInRecipe:new(playerObj, evolvedRecipe, baseItem, inventoryItem, (70 - playerObj:getPerkLevel(Perks.Cooking))))
      end
    elseif LCMenu.LOG.debug then
      print("mixIngredients: inventory item is nil")
    end
  end
end

function LCMenu.openCan(selectedItem, recipe, playerObj, evolvedRecipe)
	local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
	local container = selectedItem:getContainer()
  local selectedItemContainer = selectedItem:getContainer()
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

function LCMenu.OnCraftComplete(completedAction, recipe, playerObj, evolvedRecipe, selectedItemType)  
  for index, inventoryItem in pairs(LCMenu.currentIngredients) do
    if inventoryItem then
      local itemFullType = inventoryItem:getFullType()
      if itemFullType == selectedItemType then
        table.remove(LCMenu.currentIngredients)
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

function LCMenu.countIngredientsOnly()
  local count = 0
  for _, inventoryItem in pairs(LCMenu.currentIngredients) do
    if not inventoryItem:isSpice() then
      count = count + 1
    end
  end
  return count
end

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
        --if LCMenu.LOG.debug then print("Adding: " .. inventoryItem:getName()) end
        table.insert(LCMenu.allIngredients, inventoryItem)
      end
    elseif inventoryItem and inventoryItem:IsInventoryContainer() then
      LCMenu.taverseInventory(playerObj, inventoryItem)
    end
  end
end

-- TODO: Search if there is a build in function to get all itemcontainers around player
function LCMenu.getAllIngredients(playerObj)
  LCMenu.allIngredients = {}
  local itemContainer = playerObj:getInventory()--:getAllCategory("Food")
  LCMenu.taverseInventory(playerObj, itemContainer)
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
The rules:
  1 Spice last, if both spice, then which one makes more happy
  2 Fresh before canned and other stuff that will not go off
      is fresh offAge < 1000000000
  3 if both fresh then fresh level
      fresh (3): Age - offAge > 0
      stale (2):  Age - offAge < 0 and Age - offAgeMax > 0
      rotten(1): Age - offAgeMax < 0
  4 same fresh level then check hunger change (x -1) largest first
  5 same hunger change (x -1) check Calories largest first
  6 same Calorie then youngest first (<age)
  7 else true
]]
function LCMenu.sortFreshFirst(leftInventoryItem, rightInventoryItem)
  local leftIsSpice  = leftInventoryItem:isSpice()
  local rightIsSpice = rightInventoryItem:isSpice()
  -- 1
  if leftIsSpice ~= rightIsSpice then
    return rightIsSpice
  elseif leftIsSpice then -- both spice leftIsSpice == rightIsSpice, which one more happy
    return leftInventoryItem():getUnhappyChange() > rightInventoryItem:getUnhappyChange()
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

function hasEnough(itemType, allInv)
  local countCorrectItems = 0
  for _, inventoryItem in pairs(allInv) do
    if inventoryItem:getFullType() == itemType then
      countCorrectItems = countCorrectItems + 1
    end
  end
  return (countCorrectItems > 0)
end

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

local function formatFoodValue(f)
	return string.format("%+.2f", f)
end

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

function LCMenu.addIngredients(playerObj, evolvedRecipe, inventoryItem, startAt)
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
      local used = LCUtil.contains(fullTypeInventoryItem, LCMenu.currentIngredients)
      local show = (not canAddIngredient and spice and not used) or (canAddIngredient and not spice) or (canAddIngredient and spice and not used)
      --local hasEnough = hasEnough(fullType, LCMenu.allIngredients) -- ?
      if show then 
        for i = 0, size - 1 do
          local itemRecipe = pi:get(i)
          local fullTypeItemRecipe = makeFullType(itemRecipe, haveTinOpeners)
          if fullTypeItemRecipe == fullTypeInventoryItem then
            if LCMenu.LOG.debug then print("addIngredients selecting item: " .. tostring(inventoryItem:getFullType())) end
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
    
    local noOfIng = LCUtil.count(inventoryItem:getFullType(), LCMenu.currentIngredients)
    
    local displayName = makeDisplayName(inventoryItem, noOfIng)
      
    menu:addSlice(displayName, tex, LCMenu.addIngredients, playerObj, evolvedRecipe, inventoryItem, startAt)
  end  
  
  if (i <= size) then
    local tex = getTexture("media/ui/Moodle_internal_plus_green.png")
    menu:addSlice(getText("IGUI_LC_Slice_Next_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, nil, startAt + intervalStartAt)
  else
    local tex = getTexture("media/ui/Moodle_internal_plus_red.png")
    menu:addSlice(getText("IGUI_LC_Slice_No_Next_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, nil, startAt)
  end
  if (startAt > 1) then
    local tex = getTexture("media/ui/Moodle_internal_minus_green.png")
    menu:addSlice(getText("IGUI_LC_Slice_Prev_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, nil, startAt - intervalStartAt)
  else 
    local tex = getTexture("media/ui/Moodle_internal_minus_red.png")
    menu:addSlice(getText("IGUI_LC_Slice_No_Prev_Ingredients"), tex, LCMenu.addIngredients, playerObj, evolvedRecipe, nil, startAt)
  end
  
  local nextStep = getText("IGUI_LC_Slice_Next_Step") .. " [" .. tostring(ingredientsOnly) .. "/" .. tostring(evolvedRecipe:getMaxItems()) .. "]"
  local evoBaseFullType = evolvedRecipe:getResultItem()
  if not playerObj:getInventory():contains(evoBaseFullType) then
    evoBaseFullType = evolvedRecipe:getBaseItem()
  end
  if ingredientsOnly == 0 then
    LCMenu.addEvoSlice(menu, evoBaseFullType, playerObj, LCMenu.addIngredients, nextStep, evolvedRecipe)
  else
    LCMenu.addEvoSlice(menu, evoBaseFullType, playerObj, LCMenu.mixIngredients, nextStep, evolvedRecipe)
  end
  
  LCMenu.menuEnd(menu)
end

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

function LCMenu.menuEnd(menu)
	menu:center()
	menu:addToUIManager()
end

function LCMenu.addEvoSlice(menu, fullType, playerObj, func, description, data)
  local inventoryItem = InventoryItemFactory.CreateItem(fullType)
  local tex = inventoryItem:getTexture()
  menu:addSlice(description, tex, func, playerObj, data)
end

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
      if itemContainer:contains(evolvedRecipe:getResultItem()) then
        LCMenu.addEvoSlice(menu, evolvedRecipe:getResultItem(), playerObj, LCMenu.addIngredients, evolvedRecipe:getOriginalname(), evolvedRecipe)
      elseif itemContainer:contains(evolvedRecipe:getBaseItem()) then
        LCMenu.addEvoSlice(menu, evolvedRecipe:getBaseItem(), playerObj, LCMenu.addIngredients, evolvedRecipe:getOriginalname(), evolvedRecipe)
      end
    end    
  end

  LCMenu.menuEnd(menu)
end

local function testContextMenu(playerIndex, context, worldObjects, test)
	context:addOption("Test 1 - Open LC Menu", getSpecificPlayer(playerIndex), LCMenu.create)
end
if LCMenu.LOG.debug then
  Events.OnFillWorldObjectContextMenu.Add(testContextMenu)
end

function LCMenu.OnFillInventoryObjectContextMenu(playerNum, context, items)
  local player = getSpecificPlayer(playerNum)
  local itemContainer = player:getInventory()
  if player:getVehicle() then
    return -- can't work in a vehicle
  end
  
  local tempItem = nil
  local item = nil
  
  for k, v in ipairs(items) do
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
          break
        end
      end    
    end
  end

	if item then
    context:addOption(getText("ContextMenu_LetsCookMenu"), item, LCMenu.create, player)
  end

  return context
end
Events.OnFillInventoryObjectContextMenu.Add(LCMenu.OnFillInventoryObjectContextMenu)

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