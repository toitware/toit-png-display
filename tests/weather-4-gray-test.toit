// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png-display show *
import pixel-display show *
import pixel-display.four-gray show *
import roboto.bold-36 as bold
import roboto.black-36 as black
import pictogrammers-icons.size-96 as icons

import .write-file

main args:
  driver := FourGrayPngDriver 320 239
  display := FourGrayPixelDisplay driver
  display.background = BLACK

  font := Font [bold.ASCII, bold.LATIN-1-SUPPLEMENT]
  time-font := Font [black.ASCII]

  context := display.context --landscape --color=LIGHT-GRAY --font=font
  icon-context := context.with --color=WHITE
  time := context.with --color=DARK-GRAY --font=time-font
  location-context := context.with --color=DARK-GRAY

  display.text context 20 200 "Rain with thunder"
  display.icon icon-context 200 120 icons.WEATHER-LIGHTNING-RAINY
  display.text time 20 40 "13:37"
  display.text location-context 20 100 "Borås"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
