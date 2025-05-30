// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.several-color
import pixel-display.style show *
import font show *

import .gold

WHITE ::= 0
BLACK ::= 1
RED ::= 2
GREEN ::= 3
BLUE ::= 4
YELLOW ::= 5
ORANGE ::= 6

main args:
  driver := SeveralColorPngDriver 104 50
  display := PixelDisplay.several-color driver
  display.background = WHITE

  font := Font.get "sans10"
  style := Style --color=BLACK --font=font
  orange := Style --color=ORANGE --font=font
  blue := Style --color=BLUE --font=font

  display.add (Label --style=style --x=5 --y=30 --text="Toit")
  display.add (Label --style=orange --x=35 --y=20 --text="Orange")
  display.add (Label --style=blue --x=35 --y=40 --text="Blue")

  check-gold driver display
