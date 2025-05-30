// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.four-gray show WHITE BLACK LIGHT-GRAY DARK-GRAY
import pixel-display.style show *
import font show *

import .gold

main args:
  driver := FourGrayPngDriver 104 50
  display := PixelDisplay.four-gray driver
  display.background = WHITE

  font := Font.get "sans10"
  style := Style --color=BLACK --font=font
  light-gray := Style --color=LIGHT-GRAY --font=font
  dark-gray := Style --color=DARK-GRAY --font=font

  display.add (Label --style=style --x=5 --y=30 --text="Toit")
  display.add (Label --style=light-gray --x=35 --y=20 --text="Light gray")
  display.add (Label --style=dark-gray --x=35 --y=40 --text="Dark gray")

  check-gold driver display
