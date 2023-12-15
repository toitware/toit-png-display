// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.several-color show *
import pixel-display.style show *
import roboto.bold-36 as bold
import roboto.black-36 as black
import pictogrammers-icons.size-96 as icons

import .write-file

WHITE ::= 0
BLACK ::= 1
RED ::= 2
GREEN ::= 3
BLUE ::= 4
YELLOW ::= 5
ORANGE ::= 6

main args:
  driver := SeveralColorPngDriver 319 239
  display := PixelDisplay.several-color driver
  display.background = BLACK

  font := Font [bold.ASCII, bold.LATIN-1-SUPPLEMENT]
  time-font := Font [black.ASCII]

  style := Style --color=ORANGE --font=font
  icon-style := Style --color=WHITE
  time := Style --color=GREEN --font=time-font
  location-style := Style --color=YELLOW --font=font

  [
      Label --style=style --x=20 --y=200 --label="Rain with thunder",
      Label --style=icon-style --x=200 --y=120 --icon=icons.WEATHER-LIGHTNING-RAINY,
      Label --style=time --x=20 --y=40 --label="13:37",
      Label --style=location-style --x=20 --y=100 --label="Borås",
  ].do: display.add it

  display.set-styles []  // Workaround.

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
