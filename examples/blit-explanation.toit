// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import bitmap show blit bytemap-draw-text ORIENTATION-0
import font show *
import pixel-display show *
import pixel-display.true-color show *
import png-display show *
import pixel-display.texture show TEXT-TEXTURE-ALIGN-RIGHT TEXT-TEXTURE-ALIGN-LEFT TEXT-TEXTURE-ALIGN-CENTER

import font-x11-adobe.sans-24-bold
import font-x11-adobe.typewriter-14-bold

import .write-file

// Generates the diagrams used on https://docs.toit.io/language/sdk/blit

// PNG size generated.
WIDTH ::= 1024
HEIGHT ::= 768

// Position and size of the source byte array in the PNG.
SOURCE-Y ::= 100
SOURCE-X ::= 50
SOURCE-WIDTH ::= 30
SOURCE-HEIGHT ::= 17

// Size of each square (byte) in the byte array diagrams.
BYTE-SIZE := 16

// Position and size of the destination byte array in the PNG.
DEST-X ::= 600
DEST-Y ::= 300
DEST-WIDTH := 20
DEST-HEIGHT := 25

SANS-10 ::= Font.get "sans10"
CODE-FONT := Font [typewriter-14-bold.ASCII]

main:
  diagram "blit"
  diagram "blit-stride" --pixel-stride=2 --extra-code="  --destination-pixel-stride=2"

// Generates a PNG file showing how blit works.
diagram filename/string --pixel-stride=1 --extra-code=null:
  driver := TrueColorPngDriver WIDTH HEIGHT
  display := TrueColorPixelDisplay driver

  stride-label := display.context --landscape --alignment=TEXT-TEXTURE-ALIGN-CENTER --color=(get-rgb 255 0 0) --font=SANS-10

  grid display stride-label "Source" "source" SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT
  grid display stride-label "Dest" "destination" DEST-X DEST-Y DEST-WIDTH DEST-HEIGHT

  picture display "blit" 5 SOURCE-HEIGHT - 2 SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT

  picture display "b" 0 12 DEST-X DEST-Y 8 13 --pixel-stride=pixel-stride

  // Slice of source.
  slice display SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT 5 3 13 16

  // Slice legend.
  slice display 600 130 4 3 1 0 3 2
  left-align := stride-label.with --alignment=TEXT-TEXTURE-ALIGN-LEFT
  display.text left-align 600 + 5 * BYTE-SIZE 150 "= slice of byte array"

  code-context := left-align.with --color=(get-rgb 0 0 0) --font=CODE-FONT
  comment-context := left-align.with --color=(get-rgb 0 0 255) --font=CODE-FONT
  literal-context := left-align.with --color=(get-rgb 255 192 192) --font=CODE-FONT
  code := Code display 50 440 code-context comment-context literal-context

  code.line "// Copy 8x13 rectangle at (5, 4)"
  code.line "// from source to dest."
  code.line "X := 5"
  code.line "Y := 4"
  code.line "W := 8"
  code.line "H := 9"
  code.line "SLS := 30  // source line stride."
  code.line "DLS := 20  // dest line stride."
  code.line "slice-start := X + Y * SLS"
  code.line "slice-end := X + W + (Y + H) * SLS"
  code.line "blit"
  code.line "  source[slice-start..slice-end]"
  code.line "  dest"
  code.line "  W"
  code.line "  --source-line-stride=SLS"
  code.line "  --destination-line-stride=DLS"
  if extra-code:
    code.line extra-code

  write-file "$(filename).png" driver display

// Used to display the code snippet in the diagram.
class Code:
  display := ?
  x/int ::= ?
  y/int := ?
  code-context := ?
  comment-context := ?
  literal-context := ?

  constructor .display .x .y .code-context .comment-context .literal-context:

  line text/string:
    comment := text.index-of "//"
    if comment != -1:
      code := text.copy 0 comment
      width := code-context.font.pixel-width code
      display.text comment-context x + width y (text.copy comment)
      text = text.copy 0 comment
    if text.size != 0 and ' ' <= text[text.size - 1] <= '9':
      literal := ""
      while ' ' <= text[text.size - 1] <= '9':
        literal = text[text.size - 1..] + literal
        text = text.copy 0 text.size - 1
      width := code-context.font.pixel-width text
      display.text literal-context x + width y literal
    display.text code-context x y text
    y += 19

// Draws the outline of a slice on a ByteArray of size W * H.
slice display X Y W H left top right bottom:
  red-line := display.context --landscape --color=(get-rgb 255 0 0)

  display.filled-rectangle red-line
    X
    Y + (top + 1) * BYTE-SIZE
    3
    (bottom - top - 1) * BYTE-SIZE

  display.filled-rectangle red-line
    X
    Y + (top + 1) * BYTE-SIZE
    left * BYTE-SIZE + 3
    3

  display.filled-rectangle red-line
    X + left * BYTE-SIZE
    Y + top * BYTE-SIZE + 3
    3
    BYTE-SIZE

  display.filled-rectangle red-line
    X + left * BYTE-SIZE
    Y + top * BYTE-SIZE
    (W - left) * BYTE-SIZE
    3

  display.filled-rectangle red-line
    X + W * BYTE-SIZE - 3
    Y + top * BYTE-SIZE
    3
    (bottom - top - 1) * BYTE-SIZE

  display.filled-rectangle red-line
    X + right * BYTE-SIZE - 3
    Y + (bottom - 1) * BYTE-SIZE - 3
    (W - right) * BYTE-SIZE
    3

  display.filled-rectangle red-line
    X + right * BYTE-SIZE - 3
    Y + (bottom - 1) * BYTE-SIZE - 3
    3
    BYTE-SIZE

  display.filled-rectangle red-line
    X
    Y + bottom * BYTE-SIZE - 3
    right * BYTE-SIZE
    3

// Draws an image in the ByteArray (some letters).
picture display/TrueColorPixelDisplay text/string text-x/int text-y/int X/int Y/int W/int H/int --pixel-stride=1:
  fg := display.context --landscape --color=(get-rgb 255 190 170) --font=SANS-10
  bg := display.context --landscape --color=(get-rgb 192 150 110) --font=SANS-10

  img := ByteArray W * H

  bytemap-draw-text text-x text-y 255 ORIENTATION-0 text SANS-10 img W

  for y := 0; y < H; y++:
    for x := 0; x < W; x++:
      display.filled-rectangle
        img[y * W + x] == 0 ? bg : fg
        X + (x * pixel-stride) * BYTE-SIZE + 1
        Y + y * BYTE-SIZE + 1
        BYTE-SIZE - 1
        BYTE-SIZE - 1

// Draws a grid that represents a ByteArray used as a 2D bytemap.
grid display label-context name lc-name X Y W H:
  context := display.context --landscape --color=BLACK --font=SANS-10

  for y := 0; y <= H; y++:
    y-coord := Y + y * BYTE-SIZE
    display.line context X y-coord
      X + BYTE-SIZE * W + 1
      y-coord

  for x := 0; x <= W; x++:
    x-coord := X + x * BYTE-SIZE
    display.line context x-coord Y
      x-coord
      Y + BYTE-SIZE * H + 1

  title-font := context.with --font=(Font [sans-24-bold.ASCII]) --color=(get-rgb 50 50 50)

  display.text title-font X Y - 30 "$name $(W)x$H = $(W * H) bytes"

  left-labels := context.with --alignment=TEXT-TEXTURE-ALIGN-RIGHT --color=(get-rgb 40 40 200)
  right-labels := left-labels.with --alignment=TEXT-TEXTURE-ALIGN-LEFT

  stride-y := Y + H * BYTE-SIZE
  display.text label-context
    X + W * BYTE-SIZE/2
    stride-y + 25
    "--$(lc-name)_line-stride=$W"

  R := X + W * BYTE-SIZE + 1

  display.line label-context X stride-y + 10 R stride-y + 10
  display.line label-context X stride-y + 10 X stride-y + 5
  display.line label-context R stride-y + 10 R stride-y + 5

  for y := 0; y < H; y++:
    y-coord := Y + y * BYTE-SIZE + 14
    rhs := X + W * BYTE-SIZE
    display.text left-labels X - 4 y-coord "$(y * W)"
    display.text right-labels rhs + 5 y-coord "$(y * W + W - 1)"
    y-line := Y + y * BYTE-SIZE + BYTE-SIZE/2
    display.line left-labels
      X - 3
      y-line
      X + BYTE-SIZE/2
      y-line
    display.line right-labels
      rhs + 4
      y-line
      rhs - BYTE-SIZE/2
      y-line
