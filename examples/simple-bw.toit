// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.two_color show WHITE BLACK
import font show *

main:
  driver := TwoColorPngDriver 104 50
  display := TwoColorPixelDisplay driver
  display.background = WHITE

  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")

  display.text context 20 30 "Toit"
  display.draw

  print "Writing simple-bw.png"
  driver.write "simple-bw.png"
