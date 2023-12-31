// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import font show *
import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *
import pixel-display.true-color show *
import roboto.bold-36 as bold
import roboto.black-36 as black
import pictogrammers-icons.size-96 as icons

import .write-file

main args:
  driver := TrueColorPngDriver 320 240
  display := PixelDisplay.true-color driver
  display.background = get-rgb 30 30 30

  font := Font [bold.ASCII, bold.LATIN-1-SUPPLEMENT]
  time-font := Font [black.ASCII]

  style := Style --color=(get-rgb 160 255 128) --font=font
  icon-style := Style --color=(get-rgb 200 255 255)
  time := Style --color=(get-rgb 200 100 80) --font=time-font
  location-style := Style --color=(get-rgb 255 240 230) --font=font

  [  
      Label --style=style --x=20 --y=200 --text="Rain with thunder",
      Label --style=icon-style --x=200 --y=120 --icon=icons.WEATHER-LIGHTNING-RAINY,
      Label --style=time --x=20 --y=40 --text="13:37",
      Label --style=location-style --x=20 --y=100 --text="Borås",
  ].do: display.add it

  display.set-styles []  // Workaround.

  filename := args.size == 0 ? "-" : args[0]

  print "Writing $filename"
  write-file filename driver display
