// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.four-gray show *
import pixel-display.style show *
import roboto.bold-36 as bold
import roboto.black-36 as black
import pictogrammers-icons.size-96 as icons

import .write-file

main args:
  driver := FourGrayPngDriver 320 239
  display := PixelDisplay.four-gray driver
  display.background = BLACK

  font := Font [bold.ASCII, bold.LATIN-1-SUPPLEMENT]
  time-font := Font [black.ASCII]

  context := Style --color=LIGHT-GRAY --font=font
  icon-context := Style --color=WHITE
  time := Style --color=DARK-GRAY --font=time-font
  location-context := Style --color=DARK-GRAY --font=font

  [
      Label --style=context --x=20 --y=200 --label="Rain with thunder",
      Label --style=icon-context --x=200 --y=120 --icon=icons.WEATHER-LIGHTNING-RAINY,
      Label --style=time --x=20 --y=40 --label="13:37",
      Label --style=location-context --x=20 --y=100 --label="Borås",
  ].do: display.add it

  display.set-styles []  // Workaround.

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
