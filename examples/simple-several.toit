// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.several_color
import font show *

import .write_file

WHITE ::= 0
BLACK ::= 1
RED ::= 2
GREEN ::= 3
BLUE ::= 4
YELLOW ::= 5
ORANGE ::= 6

main:
  driver := SeveralColorPngDriver 104 50
  display := SeveralColorPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  orange := context.with --color=ORANGE
  blue := context.with --color=BLUE

  display.text context 5 30 "Toit"
  display.text orange 35 20 "Orange"
  display.text blue 35 40 "Blue"

  print "Writing simple-several.png"
  write_file "simple-several.png" driver display
