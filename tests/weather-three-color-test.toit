// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *
import pixel-display.three-color show *
import roboto.bold-36 as bold
import roboto.black-36 as black
import pictogrammers-icons.size-96 as icons

import .write-file

main args:
  driver := ThreeColorPngDriver 320 239
  display := PixelDisplay.three-color driver
  display.background = WHITE

  font := Font [bold.ASCII, bold.LATIN-1-SUPPLEMENT]
  time-font := Font [black.ASCII]

  context := Style --color=RED --font=font
  icon-context := Style --color=BLACK
  time := Style --color=BLACK --font=time-font
  location-context := Style --color=RED --font=font

  [
      Label --style=context --x=20 --y=200 --label="Rain with thunder",
      Label --style=icon-context --x=200 --y=120 --icon=icons.WEATHER-LIGHTNING-RAINY,
      Label --style=time --x=20 --y=40 --label="13:37",
      Label --style=location-context --x=20 --y=100 --label="Borås",
  ].do: display.add it

  filename := args.size == 0 ? "-" : args[0]

  display.set-styles []  // Workaround.

  print "Writing $filename"
  write-file filename driver display
