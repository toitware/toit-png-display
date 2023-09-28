// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png-display show *
import pixel-display show *
import pixel-display.true-color show *

import .write-file

main:
  driver := TrueColorPngDriver 1 1
  display := TrueColorPixelDisplay driver
  print "Writing out.png"
  write-file "1x2.png" driver display
