// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png_display show *
import pixel_display show *
import pixel_display.several_color show *
import roboto.bold_36 as bold
import roboto.black_36 as black
import pictogrammers_icons.size_96 as icons

WHITE ::= 0
BLACK ::= 1
RED ::= 2
GREEN ::= 3
BLUE ::= 4
YELLOW ::= 5
ORANGE ::= 6

main:
  driver := SeveralColorPngDriver 319 239
  display := SeveralColorPixelDisplay driver
  display.background = BLACK

  font := Font [bold.ASCII, bold.LATIN_1_SUPPLEMENT]
  time_font := Font [black.ASCII]

  context := display.context --landscape --color=ORANGE --font=font
  icon_context := context.with --color=WHITE
  time := context.with --color=GREEN --font=time_font
  location_context := context.with --color=YELLOW

  display.text context 20 200 "Rain with thunder"
  display.icon icon_context 200 120 icons.WEATHER_LIGHTNING_RAINY
  display.text time 20 40 "13:37"
  display.text location_context 20 100 "Borås"

  write_file "weather-several-color.png" driver display
