// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

// A PNG-producing version of the code in the display.mdx docs file.

import encoding.json
import font show *
import font-x11-adobe.sans-14-bold
import monitor show Mutex

import pictogrammers-icons.size-48 as icons

import pixel-display.two-color show *
import pixel-display.texture show *
import pixel-display show TwoColorPixelDisplay

import png-display show *

import .write-file

// Search for icon names on https://materialdesignicons.com/
// (hover over icons to get names).
WMO-4501-ICONS ::= [
  icons.WEATHER-SUNNY,
  icons.WEATHER-CLOUDY,
  icons.WEATHER-SNOWY,
  icons.WEATHER-SNOWY-HEAVY,
  icons.WEATHER-FOG,
  icons.WEATHER-PARTLY-RAINY,
  icons.WEATHER-RAINY,
  icons.WEATHER-SNOWY,
  icons.WEATHER-PARTLY-RAINY,
  icons.WEATHER-LIGHTNING,
]

// We don't want separate threads updating the display at the
// same time, so this mutex is used to ensure the tasks only
// have access one at a time.
display-mutex := Mutex

driver := TwoColorPngDriver 128 64
display:= TwoColorPixelDisplay driver

main:
  sans-14-font ::= Font [
    sans-14-bold.ASCII,  // Regular characters.
    sans-14-bold.LATIN-1-SUPPLEMENT,  // Degree symbol.
  ]
  display.background = BLACK
  context := display.context
    --landscape
    --color=WHITE
    --font=sans-14-font
  black-context := context.with --color=BLACK

  // White circle as background of weather icon.  We are
  // just using the window to draw a circle here, not as an
  // actual window with its own textures.
  DIAMETER ::= 56
  CORNER-RADIUS ::= DIAMETER / 2
  display.add
    RoundedCornerWindow 68 4 DIAMETER DIAMETER
      context.transform
      CORNER-RADIUS
      WHITE
  // Icon is added after the white dot so it is in a higher
  // layer.
  icon-texture :=
    display.icon black-context 72 48 icons.WEATHER-CLOUDY

  // Temperature is black on white.
  display.filled-rectangle context 0 0 64 32
  temperature-context :=
    black-context.with --alignment=TEXT-TEXTURE-ALIGN-CENTER
  temperature-texture :=
    display.text temperature-context 32 23 "??°C"

  // Time is white on the black background, aligned by the
  // center so it looks right relative to the temperature
  // without having to zero-pad the hours.
  time-context := context.with --alignment=TEXT-TEXTURE-ALIGN-CENTER
  time-texture := display.text time-context 32 53 "??:??"

  task --background:: clock-task time-texture
  task --background:: weather-task icon-texture temperature-texture

  sleep --ms=100
  write-file "docs-example.png" driver display

weather-task weather-icon/IconTexture temperature-texture/TextTexture:
  while true:
    map := json.parse """
      {"wmo_4501": $(random 8),
       "temperature_c": 24.1,
       "temperature_f": 75.4}"""
    code := map["wmo_4501"]
    temp := map["temperature_c"]
    display-mutex.do:
      weather-icon.icon = WMO-4501-ICONS[code]
      temperature-texture.text = "$(%.1f temp)°C"
    sleep --ms=1000

clock-task time-texture:
  while true:
    now := (Time.now).local
    display-mutex.do:
      // H:MM or HH:MM depending on time of day.
      time-texture.text = "$now.h:$(%02d now.m)"
    // Sleep this task until the next whole minute.
    sleep-time := 60 - now.s
    sleep --ms=sleep-time*1000
