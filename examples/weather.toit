// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import font show *
import png_display show *
import pixel_display show *
import pixel_display.true_color show *
import roboto.bold_36 as roboto_36_bold
import roboto.black_36 as black
import pictogrammers_icons.size_96 as icons

main:
  driver := TrueColorPngDriver 320 240
  display := TrueColorPixelDisplay driver
  display.background = get_rgb 30 30 30

  font := Font [roboto_36_bold.ASCII, roboto_36_bold.LATIN_1_SUPPLEMENT]
  time_font := Font [black.ASCII]

  context := display.context --landscape --color=(get_rgb 160 255 128) --font=font
  icon_context := context.with --color=(get_rgb 200 255 255)
  time := context.with --color=(get_rgb 200 100 80) --font=time_font
  location_context := context.with --color=(get_rgb 255 240 230)

  display.text context 20 200 "Rain with thunder"
  display.icon icon_context 200 120 icons.WEATHER_LIGHTNING_RAINY
  display.text time 20 40 "13:37"
  display.text location_context 20 100 "Borås"
  display.draw

  driver.write "weather.png"
