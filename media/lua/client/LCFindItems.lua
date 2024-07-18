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

┌──────────────────────┐
│ Lets Cook Find Items │
└──────────────────────┘
]]

LCFindItems = LCFindItems or {}
LCFindItems.LOG = LCFindItems.LOG or {}
LCFindItems.LOG.debug = getCore():getDebug() or false
LCFindItems.LOG.trace = false

function LCFindItems.addItemToListOfList(theList, item)
  if theList[item:getType()] == nil then 
    theList[item:getType()] = {}
  end
  table.insert(theList[item:getType()], item)
end

function LCFindItems.hasCanOpener(item)
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

function LCFindItems.processItem(item, foodList, vesselList, toolList)
  if item ~= nil then
    if item:getCategory() == "Container" then
      -- traverse containers
      LCFindItems.searchForItems(item:getInventory(), foodList, vesselList, toolList)
    elseif item:getDisplayCategory() == 'Cooking' or item:isCookable() then 
      -- 'Cooking': vessel (something like a pot with no water or griddle pan but also can opener)
      -- isCookable: vessel with water (usually?)
      -- if contain a tag of canopener
      if LCFindItems.hasCanOpener(item) then
        LCFindItems.addItemToListOfList(toolList, item)
      else
        LCFindItems.addItemToListOfList(vesselList, item)
      end
    elseif item:IsFood() or item:getDisplayCategory() == 'Food' then 
      -- food item
      LCFindItems.addItemToListOfList(foodList, item)
    end
  end
end

-- Inspect all items in the container
-- @param itemContainer [in] the container to rummage through
-- @foodList [in, out] add found food item to this list
-- @vesselList [in, out] add found vessel item to this list
-- @toolList [in, out] add found tool item to this list
function LCFindItems.searchForItems(itemContainer, foodList, vesselList, toolList)
  if itemContainer then
    local items = itemContainer:getItems()
    local size = items:size() 
    for i = size - 1, 0, -1 do
      local item = items:get(i)
      LCFindItems.processItem(item, foodList, vesselList, toolList)
    end
  end
end

function LCFindItems.debugPrintInventoryItem(inventoryItem)
  local output = "\n Item: " .. tostring(inventoryItem:getName())
  return output
end

function LCFindItems.debugPrintFVTLists(foodList, vesselList, toolList)
  local output = "\nfoodList [" .. tostring(#foodList) .. "]"
  for k, v in pairs(foodList) do
    output = output .. "\n  " .. tostring(k) .. ": #" .. tostring(#v)
  end
  output = output .. "\nvesselList [" .. tostring(#vesselList) .. "]"
  for k, v in pairs(vesselList) do
    output = output .. "\n  " .. tostring(k) .. ": #" .. tostring(#v)
  end
  output = output .. "\ntoolList [" .. tostring(#toolList) .. "]"
  for k, v in pairs(toolList) do
    output = output .. "\n  " .. tostring(k) .. ": #" .. tostring(#v)
  end
  
  return output
end

function LCFindItems.findAll(foodList, vesselList, toolList)
  
  -- Player's inv
  local player = getPlayer()
  LCFindItems.searchForItems(player:getInventory(), foodList, vesselList, toolList)
  local middleSquare = player:getCurrentSquare()
  if LCFindItems.LOG.debug then print("Middle Square (" .. tostring(middleSquare:getX()) .. ", " .. tostring(middleSquare:getY()) .. ")") end
  local roomId = middleSquare:getRoomID()
  for x = middleSquare:getX() - 1, middleSquare:getX() + 1 do
    for y = middleSquare:getY() - 1, middleSquare:getY() + 1 do
      local square = getCell():getGridSquare(x, y, middleSquare:getZ())
      if square:getRoomID() == roomId then
        -- Floor stuff
        local worldInventoryObjects = square:getWorldObjects()
        if worldInventoryObjects then
          local size = worldInventoryObjects:size()
          if LCFindItems.LOG.debug then print("Number of world objects in square (" .. x .. ", " .. y .. ") ", tostring(size)) end
          for i = 0, size - 1 do 
            local worldInventoryObject = worldInventoryObjects:get(i)
            local item = worldInventoryObject:getItem()
            LCFindItems.processItem(item, foodList, vesselList, toolList)
          end
        end
        -- Other objects in that square
        local objects = square:getObjects()
        local size = objects:size()
        if LCFindItems.LOG.debug then print("Number of objects in square (" .. x .. ", " .. y .. ") ", tostring(size)) end
        for k = 0, size - 1 do
          local object = objects:get(k)
          LCFindItems.searchForItems(object:getItemContainer(), foodList, vesselList, toolList)
        end
      else
        if LCFindItems.LOG.debug then print("Skipping (" .. tostring(x) .. ", " .. tostring(y) .. ") because it is not in the same room") end
      end
    end
  end
  if LCFindItems.LOG.debug then print(LCFindItems.debugPrintFVTLists(foodList, vesselList, toolList)) end
end