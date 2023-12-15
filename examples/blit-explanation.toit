// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

// TODO: Rewrite with a custom element, instead of lots of Divs and Labels.

import bitmap show bytemap-draw-text ORIENTATION-0
import font show *
import pixel-display show *
import png-display show *
import pixel-display show *
import pixel-display.element show *
import pixel-display.style show *

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
  display := PixelDisplay.true-color driver

  stride-span-style := Style --color=0xff0000 --font=SANS-10 --background=0xff0000
  stride-style := Style --background=0x2828c8 --font=SANS-10
  stride-label-style := Style --color=0x2828c8 --font=SANS-10

  grid display stride-style stride-label-style stride-span-style "Source" "source" SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT
  grid display stride-style stride-label-style stride-span-style "Dest" "destination" DEST-X DEST-Y DEST-WIDTH DEST-HEIGHT

  picture display "blit" 5 SOURCE-HEIGHT - 2 SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT

  picture display "b" 0 12 DEST-X DEST-Y 8 13 --pixel-stride=pixel-stride

  // Slice of source.
  slice display SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT 5 3 13 16

  // Slice legend.
  slice display 600 130 4 3 1 0 3 2
  display.add
      Label
          --style = stride-span-style
          --x = 600 + 5 * BYTE-SIZE
          --y = 150
          --label = "= slice of byte array"

  code-style := Style --color=0x000000 --font=CODE-FONT
  comment-style := Style --color=0x0000ff --font=CODE-FONT
  literal-style := Style --color=0xffc0c0 --font=CODE-FONT
  code := Code display 50 440 CODE-FONT code-style comment-style literal-style

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
  display/PixelDisplay
  x/int
  y/int := ?
  font/Font
  code-style/Style
  comment-style/Style
  literal-style/Style

  constructor .display .x .y .font .code-style .comment-style .literal-style:

  line text/string:
    comment := text.index-of "//"
    if comment != -1:
      code := text.copy 0 comment
      width := font.pixel-width code
      display.add
          Label --style=comment-style --x=(x + width) --y=y --label=text[comment..]
      text = text[..comment]
    if text.size != 0 and ' ' <= text[text.size - 1] <= '9':
      literal := ""
      while ' ' <= text[text.size - 1] <= '9':
        literal = text[text.size - 1..] + literal
        text = text.copy 0 text.size - 1
      width := font.pixel-width text
      display.add
          Label --style=literal-style --x=(x + width) --y=y --label=literal
    display.add
        Label --style=code-style --x=x --y=y --label=text
    y += 19

// Draws the outline of a slice on a ByteArray of size W * H.
slice display X Y W H left top right bottom:
  red-line := Style --background=0xff0000

  display.add
      Div --style=red-line
          --x = X
          --y = Y + (top + 1) * BYTE-SIZE
          --w = 3
          --h = (bottom - top - 1) * BYTE-SIZE

  display.add
      Div --style=red-line
          --x = X
          --y = Y + (top + 1) * BYTE-SIZE
          --w = left * BYTE-SIZE + 3
          --h = 3

  display.add
      Div --style=red-line
          --x = X + left * BYTE-SIZE
          --y = Y + top * BYTE-SIZE + 3
          --w = 3
          --h = BYTE-SIZE

  display.add
      Div --style=red-line
          --x = X + left * BYTE-SIZE
          --y = Y + top * BYTE-SIZE
          --w = (W - left) * BYTE-SIZE
          --h = 3

  display.add
      Div --style=red-line
          --x = X + W * BYTE-SIZE - 3
          --y = Y + top * BYTE-SIZE
          --w = 3
          --h = (bottom - top - 1) * BYTE-SIZE

  display.add
      Div --style=red-line
          --x = X + right * BYTE-SIZE - 3
          --y = Y + (bottom - 1) * BYTE-SIZE - 3
          --w = (W - right) * BYTE-SIZE
          --h = 3

  display.add
      Div --style=red-line
          --x = X + right * BYTE-SIZE - 3
          --y = Y + (bottom - 1) * BYTE-SIZE - 3
          --w = 3
          --h = BYTE-SIZE

  display.add
      Div --style=red-line
          --x = X
          --y = Y + bottom * BYTE-SIZE - 3
          --w = right * BYTE-SIZE
          --h = 3

// Draws an image in the ByteArray (some letters).
picture display/PixelDisplay text/string text-x/int text-y/int X/int Y/int W/int H/int --pixel-stride=1:
  fg := Style --background=0xff_be_aa --font=SANS-10
  bg := Style --background=0xc0_96_6e --font=SANS-10

  img := ByteArray W * H

  bytemap-draw-text text-x text-y 255 ORIENTATION-0 text SANS-10 img W

  for y := 0; y < H; y++:
    for x := 0; x < W; x++:
      rect := Div
        --style = img[y * W + x] == 0 ? bg : fg
        --x = X + (x * pixel-stride) * BYTE-SIZE + 1
        --y = Y + y * BYTE-SIZE + 1
        --w = BYTE-SIZE - 1
        --h = BYTE-SIZE - 1
      display.add rect

// Draws a grid that represents a ByteArray used as a 2D bytemap.
grid display/PixelDisplay grid-style/Style label-style/Style stride-span-style/Style name/string lc-name/string X/int Y/int W/int H/int:
  style := Style --background=0x000000

  for y := 0; y <= H; y++:
    display.add
        Div
            --style = style
            --x = X
            --y = Y + y * BYTE-SIZE
            --w = BYTE-SIZE * W + 1
            --h = 1

  for x := 0; x <= W; x++:
    display.add
        Div
            --style = style
            --x = X + x * BYTE-SIZE
            --y = Y
            --w = 1
            --h = BYTE-SIZE * H + 1

  title-font := Style --font=(Font [sans-24-bold.ASCII]) --color=0x323232

  label := Label --style=title-font --x=X --y=(Y - 30) --label="$(name) $(W)x$(H) = $(W * H) bytes"
  display.add label

  stride-y := Y + H * BYTE-SIZE
  label = Label
      --style = stride-span-style
      --x = X + W * BYTE-SIZE/2
      --y = stride-y + 25
      --label = "--$(lc-name)-line-stride=$W"
      --alignment = ALIGN-CENTER
  display.add label

  R := X + W * BYTE-SIZE

  [
      Div --style=stride-span-style --x=X --y=(stride-y + 10) --w=(W * BYTE-SIZE + 1) --h=1,
      Div --style=stride-span-style --x=X --y=(stride-y + 5) --w=1 --h=5,
      Div --style=stride-span-style --x=R --y=(stride-y + 5) --w=1 --h=5,
  ].do: display.add it

  for y := 0; y < H; y++:
    y-coord := Y + y * BYTE-SIZE + 14
    rhs := X + W * BYTE-SIZE
    y-line := Y + y * BYTE-SIZE + BYTE-SIZE/2
    [
        Label --style=label-style --x=(X - 4) --y=y-coord --label="$(y * W)" --alignment=ALIGN-RIGHT,
        Label --style=label-style --x=(rhs + 5) --y=y-coord --label="$(y * W + W - 1)" --alignment=ALIGN-LEFT,
        Div --style=grid-style --x=(X - 3) --y=y-line --h=1 --w=((BYTE-SIZE / 2) + 3),
        Div --style=grid-style --x=(rhs - BYTE-SIZE / 2) --y=y-line --h=1 --w=((BYTE-SIZE / 2) + 4),
    ].do: display.add it
