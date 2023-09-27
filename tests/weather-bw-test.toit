// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png-display show *
import pixel-display show *
import pixel-display.two-color show *
import roboto.bold-36 as bold
import roboto.black-36 as black
import pictogrammers-icons.size-96 as icons

import .write-file

main args:
  driver := TwoColorPngDriver 320 239
  display := TwoColorPixelDisplay driver
  display.background = WHITE

  font := Font [bold.ASCII, bold.LATIN-1-SUPPLEMENT]
  time-font := Font [black.ASCII]

  context := display.context --landscape --color=BLACK --font=font
  icon-context := context.with --color=BLACK
  time := context.with --color=BLACK --font=time-font
  location-context := context.with --color=BLACK

  display.text context 20 200 "Rain with thunder"
  display.icon icon-context 200 120 icons.WEATHER-LIGHTNING-RAINY
  display.text time 20 40 "13:37"
  display.text location-context 20 100 "Borås"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
