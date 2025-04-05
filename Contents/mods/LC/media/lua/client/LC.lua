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

┌───────────┐
│ Lets Cook │
└───────────┘
Version: 1.03
]]

require "LCUtil"
require "LCMenu"

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
  if LetsCook.LOG.debug then
    local logo = "\n"
    logo = logo .. "  -----------------------------------------\n"
    logo = logo .. " /                                        /|\n"
    logo = logo .. "+----------------------------------------+ |\n"
    logo = logo .. "|     _/      _/  _/_/_/_/_/  _/      _/ | |\n"
    logo = logo .. "|    _/_/  _/_/      _/        _/  _/    | |\n"
    logo = logo .. "|   _/  _/  _/      _/          _/       | |\n"
    logo = logo .. "|  _/      _/      _/        _/  _/      | |\n"
    logo = logo .. "| _/      _/      _/      _/      _/     | |\n"
    logo = logo .. "+----------------------------------------+ |\n"
    logo = logo .. "| (c) Copyright 2025                     |/\n"
    logo = logo .. "+----------------------------------------+\n\n"
    logo = logo .. "             +------------+\n"
    logo = logo .. "             | Let's Cook |\n"
    logo = logo .. "             +------------+\n\n"
    logo = logo .. "             Version: 1.03\n\n"
    print(logo)
  end
  
  local player = getPlayer()
  LetsCook.ALL_FOOD_RECIPES = {}
  local size = getAllRecipes():size()
  for i = 0, size - 1 do
    local recipe = getAllRecipes():get(i)
    if (recipe:getCategory() == 'Cooking' or LCUtil.startsWith("Open Canned", recipe:getName())) and not recipe:isHidden() and (not recipe:needToBeLearn() or (player and player:isRecipeKnown(recipe))) then
      if LetsCook.LOG.trace then print("Adding recipe from list: " .. tostring(recipe:getName())) end
      table.insert(LetsCook.ALL_FOOD_RECIPES, recipe)
    end
  end
  LetsCook.ALL_EVOLVED_RECIPES = {}
  size = RecipeManager.getAllEvolvedRecipes():size()
  for i = 0, size - 1 do    
    local evo = RecipeManager.getAllEvolvedRecipes():get(i)
    if evo:isCookable() and not evo:isHidden() then
      if LetsCook.LOG.trace then print("Adding evolved recipe from list: " .. tostring(evo:getName())) end
      if LetsCook.LOG.trace then print(LetsCook.debugPrintEvolvedRecipe(evo)) end
      table.insert(LetsCook.ALL_EVOLVED_RECIPES, evo)
    end    
  end  
end
Events.OnGameStart.Add(LetsCook.init)