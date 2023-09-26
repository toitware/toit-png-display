// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.three_color show WHITE BLACK RED
import font show *

import .write_file

main args:
  driver := ThreeColorPngDriver 104 50
  display := ThreeColorPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  red := context.with --color=RED

  display.text context 20 30 "Toit"
  display.text red 60 30 "Red"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write_file filename driver display
