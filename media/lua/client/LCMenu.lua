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

require "ISUI/ISPanel"
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

LCMenu.UI = ISPanel:derive("LCMenuUI");

function LCMenu.UI:initialise()
  ISPanel.initialise(self);
  self:create();
end

function LCMenu.UI:prerender()
  ISPanel.prerender(self);
  self:drawText("Hello !", 10 ,10, 1,1,1,1, UIFont.Small);
end

function LCMenu.UI:render()
end

function LCMenu.UI:create()
  local btnWid = 75
  local btnHgt = FONT_HGT_SMALL + 2 * 4
  local padBottom = 10

  self.name = ISTextEntryBox:new("", 25, 60, 150, btnHgt);
  self.name:initialise();
  self.name:instantiate();
  self:addChild(self.name);

  self.cancel = ISButton:new(self:getWidth() - btnWid - 5, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, "Cancel", self, LCMenu.UI.onOptionMouseDown);
  self.cancel.internal = "CANCEL";
  self.cancel:initialise();
  self.cancel:instantiate();
  self.cancel.borderColor = self.buttonBorderColor;
  self:addChild(self.cancel);

  self.tick = ISTickBox:new(100, 5, 10, 10, "", nil, nil);
  self.tick:initialise();
  self.tick:instantiate();
  self.tick:setAnchorLeft(true);
  self.tick:setAnchorRight(false);
  self.tick:setAnchorTop(false);
  self.tick:setAnchorBottom(true);
  self.tick.selected[1] = true;
  self:addChild(self.tick);
  self.tick:addOption("Test tick box");
  
  local foodList, vesselList, toolList = {}, {}, {}
  LCFindItems.findAll(foodList, vesselList, toolList)
end

function LCMenu.UI:onOptionMouseDown(button, x, y)
  if button.internal == "CANCEL" then
    self:setVisible(false);
    self:removeFromUIManager();
  end
end

function LCMenu.UI:new()
  local playerNum = getPlayer():getPlayerNum()
  local sh = getPlayerScreenHeight(playerNum)
  local sl = getPlayerScreenLeft(playerNum)
  local st = getPlayerScreenTop(playerNum)
  local sw = getPlayerScreenWidth(playerNum)
  local x = getMouseX() + 10;
  local y = getMouseY() + 10;
  local w = 200
  local h = 120
  if (x + w) > (sw - sl) then
    x = (sw - sl) - w - 10
  end
  if (y + h) > (sh - st) then
    y = (sh - st) - h - 10
  end
  local o = ISPanel:new(x, y, 200, 120);
  setmetatable(o, self);
  self.__index = self;
  o.variableColor={r=0.9, g=0.55, b=0.1, a=1};
  o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
  o.backgroundColor = {r=0, g=0, b=0, a=1};
  o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
  o.zOffsetSmallFont = 25;
  o.moveWithMouse = false;

  return o;
end

function LCMenu.onCustomUIKeyPressed(key)
  if key == 24 then -- Need to make it config, O for now
    local LCMenuUI = LCMenu.UI:new()
    LCMenuUI:initialise();
    LCMenuUI:addToUIManager();
  end
end

Events.OnCustomUIKeyPressed.Add(LCMenu.onCustomUIKeyPressed)