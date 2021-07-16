// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

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
