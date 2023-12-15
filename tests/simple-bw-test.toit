// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *
import pixel-display.two-color show WHITE BLACK
import font show *

import .write-file

main args:
  driver := TwoColorPngDriver 104 50
  display := PixelDisplay.two-color driver
  display.background = WHITE

  font := Font.get "sans10"

  black := Style --background=BLACK --font=font
  white := Style --color=WHITE --font=font

  display.add (Div --style=black --x=15 --y=15 --w=40 --h=30)
  display.add (Label --style=white --x=20 --y=30 --label="Toit")

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
