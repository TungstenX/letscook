
LetsCookMenuAPI = {}

local sliceFuncTable = {}
local sliceKeyTable = {}

function LetsCookMenuAPI.registerSlice(sliceName, sliceFunction)
	if not sliceFuncTable[sliceName] then
		table.insert(sliceKeyTable, sliceName)
	end
	sliceFuncTable[sliceName] = sliceFunction
end

function LetsCookMenuAPI.unregisterSlice(sliceName)
	for i,v in ipairs(sliceKeyTable) do
		if v == sliceName then
			table.remove(sliceKeyTable, i)
			break
		end
	end
	sliceFuncTable[sliceName] = nil
end

local function fillSubMenu(menu, args)
  local icon = nil;
  for i,v in pairs(LetsCookRadialMenu.menu[args.subMenu].subMenu) do
    icon = nil;
    if LetsCookRadialMenu.icons[i] then
      icon = LetsCookRadialMenu.icons[i];
    end
    menu:addSlice(v, icon, args.selfObject.emote, args.selfObject, i)
  end
end

function LetsCookRadialMenu:fillMenu(submenu)
	local menu = getPlayerRadialMenu(self.playerNum)
	menu:clear()

  --do vanilla slices accounting for table inserts for compatibility with mods not using the API
	local icon = nil;
  for i,v in pairs(LetsCookRadialMenu.menu) do
    icon = nil;
    if LetsCookRadialMenu.icons[i] then
      icon = LetsCookRadialMenu.icons[i];
    end
    if v.subMenu then -- stuff with submenu
      menu:addSlice(v.name, icon, ISRadialMenu.createSubMenu, menu, fillSubMenu, {subMenu = i, selfObject = self})
    else -- stuff for rapid access
      menu:addSlice(v.name, icon, self.emote, self, i)
    end
  end

  --do LetsCookMenuAPI slices
  for _,k in ipairs(sliceKeyTable) do
		sliceFuncTable[k](menu, self.character)
	end

	self:display()
end
