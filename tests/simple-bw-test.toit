// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.two-color show WHITE BLACK
import font show *

import .write-file

main args:
  driver := TwoColorPngDriver 104 50
  display := TwoColorPixelDisplay driver
  display.background = WHITE

  font := Font.get "sans10"

  black := display.context --landscape --color=BLACK --font=font
  white := display.context --landscape --color=WHITE --font=font

  display.filled-rectangle black 15 15 40 30
  display.text white 20 30 "Toit"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
