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

function LCMenu.createRecipeList()
  local items = {}
  -- TODO: LetsCook.init() -- Do we need to do this here or every 10min in letscook 
  LestCook.sortEvos(foodList, vesselList, toolList)
  
  for _, recipe in pairs(LetsCook.ALL_EVOLVED_RECIPES) do
    items[recipe:getName()] = recipe--UI:addImageButton("ibutton1", "media/ui/myImage.png", toDo)
    if LCMenu.LOG.debug then print("LCMenu.createRecipeList: baseItem str: ", recipe:getBaseItem()) end
  end
  return items
end

function LCMenu.selectRecipe(_, recipe)
  if recipe then
    if recipe.getName then
      print("Clicked on recipe: ", tostring(recipe:getName()))
    else
      print("Clicked on, no getName")
    end
  else
    print("Clicked on, no recipe")
  end
end

function LCMenu.create()
  LCMenu.foodList = {}
  LCMenu.vesselList = {}
  LCMenu.toolList = {}
  LCFindItems.findAll(LCMenu.foodList, LCMenu.vesselList, LCMenu.toolList)
  
  local mainColumnWidth = 200
  LCMenu.UI = NewUI()
  
  LCMenu.UI:setTitle(getText("UI_LC_Title"))
  LCMenu.UI:setColumnWidthPixel(1, 40)
  LCMenu.UI:setColumnWidthPixel(2, mainColumnWidth)
  LCMenu.UI:setColumnWidthPixel(3, 40)
  LCMenu.UI:setWidthPixel(280)
  LCMenu.UI:setDefaultLineHeightPixel(10)
  --LCMenu.UI:setMarginPixel(10, 10);

  LCMenu.UI:addEmpty()
  LCMenu.UI:setLineHeightPixel(10)
  LCMenu.UI:nextLine()
  
  --LCMenu.UI:addEmpty()
  --LCMenu.UI:setLineHeightPixel(10)
  local recipes = LCMenu.createRecipeList()
  --LCMenu.UI:addScrollList("recipes", items) -- Create list
  --LCMenu.UI["recipes"]:setOnMouseDownFunction(_, LCMenu.selectRecipe)
  
  LCMenu.fillWithItems(recipes, mainColumnWidth)

  --LCMenu.UI:addEmpty()
 --[[ LCMenu.UI:setLineHeightPixel(10)
  LCMenu.UI:nextLine()

  LCMenu.UI:setColumnWidthPixel(1, 40)
  LCMenu.UI:setColumnWidthPixel(2, 90)
  LCMenu.UI:setColumnWidthPixel(3, 20)
  LCMenu.UI:setColumnWidthPixel(4, 90)
  LCMenu.UI:setColumnWidthPixel(5, 40)

  LCMenu.UI:addEmpty()
  LCMenu.UI:addButton("addNew1", getText("UI_LC_Button_AddNew"), LCMenu.createNewItem)
  LCMenu.UI["addNew1"]:setTooltip(getText("UI_LC_Button_AddNew_Tooltip") .. getKeyName(getCore():getKey('LCMenuNew')))

  LCMenu.UI:addEmpty()
  LCMenu.UI:addButton("checkOff1", getText("UI_LC_Button_CheckOff"), LCMenu.checkOff)
  LCMenu.UI["checkOff1"]:setTooltip(getText("UI_LC_Button_CheckOff_Tooltip") .. getKeyName(getCore():getKey('LCMenuCheckOff')))

  LCMenu.UI.namedElements["checkOff1"].enable = LCMenu.somethingTicked

  LCMenu.UI:addEmpty()
  LCMenu.UI:setLineHeightPixel(30)
  LCMenu.UI:nextLine()

  LCMenu.UI:addEmpty()
  LCMenu.UI:setLineHeightPixel(10)
]]
  LCMenu.UI:saveLayout()
--[[
  local modData = LCUtil.getValidModData()
  if modData.position ~= nil then
    local x = modData.position.x
    local y = modData.position.y
    LCMenu.UI:setPositionPixel(x, y)

    if modData.position.isVisible == true then
      LCMenu.UI:open()
    end
  else
    LCMenu.UI:setPositionPercent(1, 1)
    modData.position = {}
    modData.position.x = LCMenu.UI.x
    modData.position.y = LCMenu.UI.y
  end
  ModData.add("LetsCook", modData)

  if LCMenu.joinedGameNow then
    LCMenu.hideForGamepad()
    LCMenu.joinedGameNow = false
  end
  ]]
end

-- TODO: Show if we can make it, fav, etc
function LCMenu.fillWithItems(recipes, width)
  local lineHeight = 20
  for key, value in pairs(recipes) do
    local item = InventoryItemFactory.CreateItem(value:getFullResultItem())
    if item then
      --local lineHeight = select(4, ToDoListUtility.getTextSize(value.text, width, UIFont["Medium"]))
      LCMenu.UI:setLineHeightPixel(lineHeight)
      LCMenu.UI:addImageButton("tickBox" .. key, item:getTex():getPath(), LCMenu.selectRecipe)
      LCMenu.UI:addText("item" .. key, key, "Medium", "Left")
      --[[
      if value.ticked == true then
        ToDoList.interface["tickBox" .. key]:setValue(true)
        ToDoList.interface["item" .. key]:setColor(0.5, 96, 96, 96)
        ToDoList.somethingTicked = true
      end
]]
      LCMenu.UI:addEmpty()
      LCMenu.UI:nextLine()
    end
  end
  --[[
  local modData = ToDoListUtility.getValidModData()
  local itemList = modData.lists[1]
  local function byValue(first, second)
    if second.ticked ~= first.ticked then
      return second.ticked and not first.ticked
    end
    return second.id > first.id
  end

  table.sort(itemList, byValue)

  ToDoList.somethingTicked = false

  for key,value in pairs(itemList) do
    local lineHeight = select(4, ToDoListUtility.getTextSize(value.text, width, UIFont["Medium"]))
    ToDoList.interface:setLineHeightPixel(lineHeight)
    ToDoList.interface:addTickBox("tickBox" .. key)
    ToDoList.interface:addText("item" .. key, value.text, "Medium", "Left")

    if value.ticked == true then
      ToDoList.interface["tickBox" .. key]:setValue(true)
      ToDoList.interface["item" .. key]:setColor(0.5, 96, 96, 96)

      ToDoList.somethingTicked = true
    end

    ToDoList.interface:addEmpty()
    ToDoList.interface:nextLine()
  end
  ]]
end

function LCMenu.createNewItem()
  
end

function LCMenu.checkOff()
end

-- Creating key bindings
function LCMenu.createBindings()
  local bindings = {
    {
      name = '[LCMenu]'
    },
   --[[ {
      value = "LCMenuToggle",
      action = LCMenu.toggleViaBinding,
      key = Keyboard.KEY_O,
    },]]
    {
      value = "LCMenuNew",
      action = LCMenu.createNewItem,
      key = Keyboard.KEY_ADD,
    },
    {
      value = "LCMenuCheckOff",
      action = LCMenu.checkOff,
      key = Keyboard.KEY_SUBTRACT,
    },
    {
      value = "LCMenuDeleteAll",
      action = LCMenu.createWarning,
      key = Keyboard.KEY_NUMPAD0,
    },
  }

  for _, bind in ipairs(bindings) do
    if bind.name then
      table.insert(keyBinding, {value = bind.name, key = nil})
    elseif bind.key then
      table.insert(keyBinding, {value = bind.value, key = bind.key})
    end
  end

  LCMenu.createAction = function(key)
    local player = getSpecificPlayer(0)
    local action
    for _,bind in ipairs(bindings) do
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

function LCMenu.hideForGamepad(playerIndex)
  if LCMenu.getJoypadData(playerIndex) then
    LCMenu.UI:setVisible(false);
    LCMenu.UI.isUIVisible = false;
  end
end

-- Rebuild interface when something changed --
function LCMenu.rebuildInterface()
	LetsCook.saveModData()
	LCMenu.UI:close()
	LCMenu.create()
end

-- To pass self to toggling when done via key binding --
function LCMenu.toggleViaBinding()
	LCMenu.UI:toggle()
end

function LCMenu.getJoypadData(playerIndex)
  if not playerIndex then playerIndex = 0 end
  return JoypadState.players[playerIndex + 1]
end

Events.OnGameBoot.Add(LCMenu.createBindings)
Events.OnLoad.Add(LCMenu.create) -- Todo: Not this?

local function onCustomUIKeyPressed(key)
  if not MainScreen.instance or not MainScreen.instance.inGame or MainScreen.instance:getIsVisible() then return end
  if key == 24 then -- Need to make it config, O for now
    --[[print("LCMenu", type(LCMenu))
    print("LCMenu.UI", type(LCMenu.UI))
    print("next(LCMenu.UI)", tostring(next(LCMenu.UI)))
    if LCMenu and LCMenu.UI and next(LCMenu.UI) == nil then
      print("LCMenu.UI not there")
      LCMenu.create()
    else
      print("LCMenu.UI is there")
      LCMenu.toggleViaBinding()
    end]]
    --LCMenu.rebuildInterface()
    LCMenu.create()
  end
end

Events.OnCustomUIKeyPressed.Add(onCustomUIKeyPressed)
