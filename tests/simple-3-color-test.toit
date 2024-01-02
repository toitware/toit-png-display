// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *
import pixel-display.three-color show WHITE BLACK RED
import font show *

import .write-file

main args:
  driver := ThreeColorPngDriver 104 50
  display := PixelDisplay.three-color driver
  display.background = WHITE

  style := Style --color=BLACK --font=(Font.get "sans10")
  red := Style --color=RED --font=(Font.get "sans10")

  display.add (Label --style=style --x=20 --y=30 --text="Toit")
  display.add (Label --style=red --x=60 --y=30 --text="Red")

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
