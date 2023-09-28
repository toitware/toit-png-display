// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.true-color show *
import font show *

import .write-file

main args:
  driver := TrueColorPngDriver 104 50
  display := TrueColorPixelDisplay driver

  context := display.context --landscape --color=(get-rgb 255 128 128) --font=(Font.get "sans10")
  blue := context.with --color=(get-rgb 30 40 255)

  display.text context 20 30 "Toit"
  display.text blue 50 30 "50%"

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
