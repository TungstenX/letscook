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
│ Lets Cook Util │
└────────────────┘
]]

LCUtil = LCUtil or {}

function LCUtil.startsWith(needle, haystack)
  if needle == nil or haystack == nil then
    return false
  end
 return string.sub(haystack, 1, string.len(needle)) == needle
end

function LCUtil.endsWith(needle, haystack)
  if needle == nil or haystack == nil then
    return false
  end
 return string.sub(haystack, string.len(haystack) - string.len(needle) + 1) == needle
end

function LCUtil.contains(needle, array)
  for _, v in pairs(array) do
    if v == needle then
      return true
    end
  end
  return false
end

function LCUtil.containsItem(fullType, inventoryItemList)
  for _, inventoryItem in pairs(inventoryItemList) do
    if inventoryItem:getFullType() == fullType then
      return true
    end
  end
  return false
end

function LCUtil.removeFirstItem(fullType, inventoryItemList)
  for index, inventoryItem in pairs(inventoryItemList) do
    if inventoryItem:getFullType() == fullType then
      table.remove(inventoryItemList, index)
      return inventoryItem
    end
  end
  return nil
end

function LCUtil.getFirstItem(fullType, inventoryItemList)
  for index, inventoryItem in pairs(inventoryItemList) do
    if inventoryItem:getFullType() == fullType then
      return inventoryItem
    end
  end
  return nil
end

function LCUtil.count(needle, array)
  local count = 0
  for _, v in pairs(array) do
    if v == needle then
      count = count + 1
    end
  end
  return count
end

function LCUtil.getValidModData()
	local modData = ModData.getOrCreate("LetsCook")
	if modData.favEvoRecipes == nil then
		modData.favEvoRecipes = {}
	end
	return modData
end

--TODO: Remove this function
function LCUtil.getTextSize(text, width, font, zoom)
	if not zoom then zoom = 1 end
	local brokenText = {}
	table.insert(brokenText, text)
	local currentTextPart = brokenText[#brokenText]
	local brokenTextLastElementWidth = getTextManager():MeasureStringX(font, currentTextPart) * zoom
	while brokenTextLastElementWidth > width do
		local currentText = brokenText[#brokenText]
		local currentTextCut = string.sub(currentText, 1, #currentText-1)
		local currentTextWidth = getTextManager():MeasureStringX(font, currentText) * zoom
		while currentTextWidth >= width do
			currentTextCut = string.sub(currentTextCut, 1, #currentTextCut-1)
			currentTextWidth = getTextManager():MeasureStringX(font, currentTextCut) * zoom
		end
		brokenText[#brokenText] = currentTextCut
		table.insert(brokenText, string.sub(currentText, #currentTextCut + 1, #currentText))
		brokenTextLastElementWidth = getTextManager():MeasureStringX(font, brokenText[#brokenText]) * zoom
	end

	local fontSize = getTextManager():MeasureStringY(font, text) * zoom
	local margin = fontSize / 4
	local finalText = ""
	for _, value in pairs(brokenText) do
		local lineBreak = "\n"
		if finalText == "" then 
			lineBreak = "" 
		end
		finalText = finalText .. lineBreak .. value
	end

	local textWidth = getTextManager():MeasureStringX(font, finalText) * zoom
	local textHeight = getTextManager():MeasureStringY(font, finalText) * zoom
	local textHeightWithMargin = textHeight + margin

	return finalText, textWidth, textHeight, textHeightWithMargin
end
