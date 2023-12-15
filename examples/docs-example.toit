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
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *

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

WIDTH ::= 128
HEIGHT ::= 64

driver := TwoColorPngDriver WIDTH HEIGHT
display:= PixelDisplay.two-color driver

main:
  sans-14-font ::= Font [
    sans-14-bold.ASCII,  // Regular characters.
    sans-14-bold.LATIN-1-SUPPLEMENT,  // Degree symbol.
  ]

  // Circle as background of weather icon.
  DIAMETER ::= 56
  CORNER-RADIUS ::= DIAMETER / 2

  STYLE ::= Style
      --class-map = {
          "top": Style --x=0 --y=0 --w=WIDTH --h=HEIGHT --background=BLACK,
          "rounded": Style --x=68 --y=4
              --w = DIAMETER
              --h = DIAMETER
              --border = RoundedCornerBorder --radius=CORNER-RADIUS
              --background = WHITE,
          "temp-box": Style --x=0 --y=0 --w=64 --h=32 --background=WHITE,
          "clock-box": Style --x=0 --y=32 --w=64 --h=32 --background=BLACK,
      }
      --id-map = {
          "icon": Style --x=(DIAMETER / 2) --y=(16 + DIAMETER / 2) --color=BLACK { "alignment": ALIGN-CENTER },
          "temp": Style --x=32 --y=23 --font=sans-14-font --color=BLACK { "alignment": ALIGN-CENTER },
          "time": Style --x=32 --y=23 --font=sans-14-font --color=WHITE { "alignment": ALIGN-CENTER },
      }

  display.add
      Div --classes=["top"] [
          Div.clipping --classes=["rounded"] [
              Label --id="icon",
          ],
          Div --classes=["temp-box"] [
              Label --id="temp",
          ],
          Div --classes=["clock-box"] [
              Label --id="time",
          ],
      ]

  display.set-styles [STYLE]

  task --background:: clock-task (display.get-element-by-id "time")
  task --background:: weather-task (display.get-element-by-id "icon") (display.get-element-by-id "temp")

  sleep --ms=100
  write-file "docs-example.png" driver display

weather-task weather-icon/Label temperature-element/Label:
  while true:
    // Simulate getting weather data from some JSON source.
    map := json.parse """
      {"wmo-4501": $(random 8),
       "temperature-c": 24.1,
       "temperature-f": 75.4}"""
    code := map["wmo-4501"]
    temp := map["temperature-c"]
    display-mutex.do:
      weather-icon.icon = WMO-4501-ICONS[code]
      temperature-element.label = "$(%.1f temp)°C"
    sleep --ms=1000

clock-task time-element/Label:
  while true:
    now := (Time.now).local
    display-mutex.do:
      // H:MM or HH:MM depending on time of day.
      time-element.label = "$now.h:$(%02d now.m)"
    // Sleep this task until the next whole minute.
    sleep-time := 60 - now.s
    sleep --ms=sleep-time*1000
