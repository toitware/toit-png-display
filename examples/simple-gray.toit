// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.four_gray show WHITE BLACK LIGHT_GRAY DARK_GRAY
import font show *

main:
  driver := FourGrayPngDriver 104 50
  display := FourGrayPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")
  light_gray := context.with --color=LIGHT_GRAY
  dark_gray := context.with --color=DARK_GRAY

  display.text context 5 30 "Toit"
  display.text light_gray 35 20 "Light gray"
  display.text dark_gray 35 40 "Dark gray"
  display.draw

  print "Writing simple-gray.png"
  driver.write "simple-gray.png"
