// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import png_display show *

main:
  driver := TrueColorPngDriver 1 1
  print "Writing out.png"
  driver.write "1x1.png"
