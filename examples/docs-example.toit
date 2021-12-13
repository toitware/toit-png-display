// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

// A PNG-producing version of the code in the display.mdx docs file.

import encoding.json
import font show *
import font.x11_100dpi.sans.sans_14_bold
import monitor show Mutex

import pictogrammers_icons.size_48 as icons

import pixel_display.two_color show *
import pixel_display.texture show *
import pixel_display show TwoColorPixelDisplay

import png_display show *

// Search for icon names on https://materialdesignicons.com/
// (hover over icons to get names).
WMO_4501_ICONS ::= [
  icons.WEATHER_SUNNY,
  icons.WEATHER_CLOUDY,
  icons.WEATHER_SNOWY,
  icons.WEATHER_SNOWY_HEAVY,
  icons.WEATHER_FOG,
  icons.WEATHER_PARTLY_RAINY,
  icons.WEATHER_RAINY,
  icons.WEATHER_SNOWY,
  icons.WEATHER_PARTLY_RAINY,
  icons.WEATHER_LIGHTNING,
]

// We don't want separate threads updating the display at the
// same time, so this mutex is used to ensure the tasks only
// have access one at a time.
display_mutex := Mutex

driver := TwoColorPngDriver 128 64
display:= TwoColorPixelDisplay driver

main:
  sans_14_font ::= Font [
    sans_14_bold.ASCII,  // Regular characters.
    sans_14_bold.LATIN_1_SUPPLEMENT,  // Degree symbol.
  ]
  display.background = BLACK
  context := display.context
    --landscape
    --color=WHITE
    --font=sans_14_font
  black_context := context.with --color=BLACK

  // White circle as background of weather icon.  We are
  // just using the window to draw a circle here, not as an
  // actual window with its own textures.
  DIAMETER ::= 56
  CORNER_RADIUS ::= DIAMETER / 2
  display.add
    RoundedCornerWindow 68 4 DIAMETER DIAMETER
      context.transform
      CORNER_RADIUS
      WHITE
  // Icon is added after the white dot so it is in a higher
  // layer.
  icon_texture :=
    display.icon black_context 72 48 icons.WEATHER_CLOUDY

  // Temperature is black on white.
  display.filled_rectangle context 0 0 64 32
  temperature_context :=
    black_context.with --alignment=TEXT_TEXTURE_ALIGN_CENTER
  temperature_texture :=
    display.text temperature_context 32 23 "??°C"

  // Time is white on the black background, aligned by the
  // center so it looks right relative to the temperature
  // without having to zero-pad the hours.
  time_context := context.with --alignment=TEXT_TEXTURE_ALIGN_CENTER
  time_texture := display.text time_context 32 53 "??:??"

  task --background:: clock_task time_texture
  task --background:: weather_task icon_texture temperature_texture

  sleep --ms=100
  driver.write_file "docs-example.png"

weather_task weather_icon/IconTexture temperature_texture/TextTexture:
  while true:
    map := json.parse """
      {"wmo_4501": $(random 8),
       "temperature_c": 24.1,
       "temperature_f": 75.4}"""
    code := map["wmo_4501"]
    temp := map["temperature_c"]
    display_mutex.do:
      weather_icon.icon = WMO_4501_ICONS[code]
      temperature_texture.text = "$(%.1f temp)°C"
      display.draw
    sleep --ms=1000

clock_task time_texture:
  while true:
    now := (Time.now).local
    display_mutex.do:
      // H:MM or HH:MM depending on time of day.
      time_texture.text = "$now.h:$(%02d now.m)"
      display.draw
    // Sleep this task until the next whole minute.
    sleep_time := 60 - now.s
    sleep --ms=sleep_time*1000
