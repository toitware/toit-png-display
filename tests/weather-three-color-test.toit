// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png_display show *
import pixel_display show *
import pixel_display.three_color show *
import roboto.bold_36 as bold
import roboto.black_36 as black
import pictogrammers_icons.size_96 as icons

import .write_file

main args:
  driver := ThreeColorPngDriver 320 239
  display := ThreeColorPixelDisplay driver
  display.background = WHITE

  font := Font [bold.ASCII, bold.LATIN_1_SUPPLEMENT]
  time_font := Font [black.ASCII]

  context := display.context --landscape --color=RED --font=font
  icon_context := context.with --color=BLACK
  time := context.with --color=BLACK --font=time_font
  location_context := context.with --color=RED

  display.text context 20 200 "Rain with thunder"
  display.icon icon_context 200 120 icons.WEATHER_LIGHTNING_RAINY
  display.text time 20 40 "13:37"
  display.text location_context 20 100 "Borås"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write_file filename driver display
