// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import png_display show *
import pixel_display show *
import pixel_display.true_color show *
import font show *

main:
  driver := TrueColorPngDriver 104 50
  display := TrueColorPixelDisplay driver

  context := display.context --landscape --color=(get_rgb 255 128 128) --font=(Font.get "sans10")
  blue := context.with --color=(get_rgb 30 40 255)

  display.text context 20 30 "Toit"
  display.text blue 50 30 "50%"
  display.draw

  print "Writing simple-color.png"
  driver.write "simple-color.png"
