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

function LCUtil.getValidModData()
	local modData = ModData.getOrCreate("LetsCook")
	if modData.favEvoRecipes == nil then
		modData.favEvoRecipes = {}
	end
	return modData
end

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
	for key,value in pairs(brokenText) do
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
