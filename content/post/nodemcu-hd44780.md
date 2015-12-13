+++
date = "2015-11-13T21:28:00Z"
draft = false
title = "NodeMCU with a HD44780 display"
tags = ["NodeMCU", "ESP8266", "HD44780", "Lua"]
topics = ["NodeMCU", "ESP8266"]
+++

Today I tried to hook up a HD44780 LCD display up to a NodeMCU. A week ago i did this with an Arduino, that was relatively easy. I expect a bit more pain with the NodeMCU as there are no standard libraries available for the LCD display i have.

![Hello World](/photos/Hello_World_ESP8266.jpg)

For the wiring i followed rougly [this](https://learn.adafruit.com/drive-a-16x2-lcd-directly-with-a-raspberry-pi/wiring) guide. At first i was concerned that i needed to use a level shifter for the 5V and 3.3V difference between the LCD and the ESP. But the article on Adafruit tells that it is not neccessary, as long as the RW pin of the display is not connected to the ESP, connect it to GND. Apparently that is the only pin that is written to from the 
LCD.

Here is a schema of the circuit made with [Frizing](http://fritzing.org/) (really awesome tool!)
![ESP8266 and HD44780 schema](/fritzing/ESP8266_and_HD44780_bb.png)

I used [this](https://github.com/Tieske/rpi-gpio/blob/master/lua/module/lcd-hd44780.lua) code as a guide.
I kept running into out of memory errors when trying to load in the script. Removing all the non-essential stuff resulted in the script below that works! Printing a message to the screen is slow, you can see it writing character per character. Next goal is to get it faster.

~~~lua
local bor, band, bnot = bit.bor, bit.band, bit.bnot

local function write4bits(self, bits, char_mode)
  tmr.delay(1000)
  gpio.write(self.pin_rs, char_mode and gpio.HIGH or gpio.LOW)

  for n = 1, 2 do
    for i, pin in ipairs(self.pin_db) do
      local j = (2-n)*4 + (i-1)
      local val = (bit.isset(bits, j))
      gpio.write(pin, val and gpio.HIGH or gpio.LOW)
    end
    gpio.write(self.pin_e, gpio.LOW)
    tmr.delay(1000)
    gpio.write(self.pin_e, gpio.HIGH)
    tmr.delay(1000)
    gpio.write(self.pin_e, gpio.LOW)
    tmr.delay(37000)
  end
end

local function home(self)
  write4bits(self, 0x02)
  tmr.delay(3000000)
end    

local function clear(self)
  write4bits(self, 0x01)
  tmr.delay(3000000)
end

local function message(self, text)
  tmptext = text:gsub("\n", string.char(0xC0))
  for i = 1, #tmptext do
    local c = tmptext:byte(i)
    write4bits(self, c, (c ~= 0xC0))
  end
end

function init(pin_rs, pin_e, pin_db)
  local self = {
    pin_rs = pin_rs,
    pin_e = pin_e,
    pin_db = pin_db
  }
  
  gpio.mode(self.pin_rs, gpio.OUTPUT)
  gpio.mode(self.pin_e, gpio.OUTPUT)
  for _, pin in ipairs(self.pin_db) do
    gpio.mode(pin, gpio.OUTPUT)
  end

  self.begin = begin
  self.home = home
  self.clear = clear
  self.message = message
  self.write4bits = write4bits

  self:write4bits(0x33) -- initialization
  write4bits(self, 0x32) -- initialization
  write4bits(self, 0x28) -- 2 line 5x7 matrix
  write4bits(self, 0x0C) -- turn cursor off 0x0E to enable cursor
  write4bits(self, 0x06) -- shift cursor right

  self:clear()
  return self
end

m = init(1, 2, {3, 4, 5, 6})
m:message("Hello World\nFrom ESP8266")
~~~

Tip of the day: use [ESPlorer!](http://esp8266.ru/esplorer/)
