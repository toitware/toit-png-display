// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *
import pixel-display.true-color show *
import font show *

import .write-file

main args:
  driver := TrueColorPngDriver 104 50
  display := PixelDisplay.true-color driver

  style := Style --color=(get-rgb 255 128 128) --font=(Font.get "sans10")
  blue := Style --color=(get-rgb 30 40 255) --font=(Font.get "sans10")

  display.add (Label --style=style --x=20 --y=30 --label="Toit")
  display.add (Label --style=blue --x=50 --y=30 --label="50%")

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
