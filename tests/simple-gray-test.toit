// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.four-gray show WHITE BLACK LIGHT-GRAY DARK-GRAY
import font show *

import .write-file

main args:
  driver := FourGrayPngDriver 104 50
  display := FourGrayPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  light-gray := context.with --color=LIGHT-GRAY
  dark-gray := context.with --color=DARK-GRAY

  display.text context 5 30 "Toit"
  display.text light-gray 35 20 "Light gray"
  display.text dark-gray 35 40 "Dark gray"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
