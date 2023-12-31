// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

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

STYLE ::= Style
    --class-map = {
        "stride-line": Style --background=0xff0000,
        "stride-label": Style --color=0xff0000 --font=SANS-10,
        "slice-label": Style --color=0xff0000 --font=SANS-10,
        "title": Style --font=(Font [sans-24-bold.ASCII]) --color=0x323232,
    }
    --type-map = {
        "grid": Style --color=0x000000 { "square-size": BYTE-SIZE },
        "grid-annotations": Style --color=0x2828c8 --font=SANS-10 { "square-size": BYTE-SIZE },
        "slice": Style --color=0xff0000 { "thickness": 3, "square-size": BYTE-SIZE },
        "picture": Style { "color-1": 0xff_be_aa, "color-0": 0xc0_96_6e, "square-size": BYTE-SIZE },
        "code": Style --font=CODE-FONT --color=0x000000 {
            "color-comment": 0x0000ff,
            "color-literal": 0xffc0c0,
        },
    }

// Generates a PNG file showing how blit works.
diagram filename/string --pixel-stride=1 --extra-code=null:
  driver := TrueColorPngDriver WIDTH HEIGHT
  display := PixelDisplay.true-color driver

  display.add
      Div --x=0 --y=0 --w=WIDTH --h=HEIGHT --background=0xffffff [
          Picture --x=SOURCE-X --y=SOURCE-Y "blit" --text-x=5 --text-y=(SOURCE-HEIGHT - 2) --w=SOURCE-WIDTH --h=SOURCE-HEIGHT,
          Grid --x=SOURCE-X --y=SOURCE-Y --width=SOURCE-WIDTH --height=SOURCE-HEIGHT,
          GridOffsets --x=SOURCE-X --y=SOURCE-Y --width=SOURCE-WIDTH --height=SOURCE-HEIGHT,
          Slice --x=SOURCE-X --y=SOURCE-Y --byte-array-width=SOURCE-WIDTH 5 3 13 16,
          Picture --x=DEST-X --y=DEST-Y "b" --text-x=0 --text-y=12 --w=8 --h=13 --pixel-stride=pixel-stride,
          Grid --x=DEST-X --y=DEST-Y --width=DEST-WIDTH --height=DEST-HEIGHT,
          GridOffsets --x=DEST-X --y=DEST-Y --width=DEST-WIDTH --height=DEST-HEIGHT,
          Slice --x=600 --y=130 --byte-array-width=4 1 0 3 2,
          Label --x=600 + 5 * BYTE-SIZE --y=150 --classes=["slice-label"] --text="= slice of byte array",
          Code --x=50 --y=421 --w=500 --h=330 --id="code" """
                // Copy 8x13 rectangle at (5, 4)
                //   from source to dest.
                X := 5
                Y := 4
                W := 8
                H := 9
                SLS := 30  // Source line stride.
                DLS := 20  // Dest line stride.
                slice-start := X + Y * SLS
                slice-end := X + W + (Y + H) * SLS
                blit
                  source[slice-start..slice-end]
                  dest
                  W
                  --source-line-stride=SLS
                  --destination-line-stride=DLS
                """,
      ]

  if extra-code:
    (display.get-element-by-id "code").text += extra-code

  add-grid-annotations display "Source" "source" SOURCE-X SOURCE-Y SOURCE-WIDTH SOURCE-HEIGHT
  add-grid-annotations display "Dest" "destination" DEST-X DEST-Y DEST-WIDTH DEST-HEIGHT

  display.set-styles [STYLE]

  write-file "$(filename).png" driver display

/// Used to display the code snippet in the diagram.
class Code extends CustomElement:
  color/int := 0x000000
  color-comment/int := 0x0000ff
  color-literal/int := 0xffc0c0
  font/Font? := null
  text_/string := ""

  constructor --x/int?=null --y/int?=null --w/int?=null --h/int?=null --id/string?=null .text_:
    super --x=x --y=y --w=w --h=h --id=id

  type -> string: return "code"

  set-attribute_ key/string value -> none:
    if key == "color":
      invalidate
      color = value
    else if key == "color-comment":
      invalidate
      color-comment = value
    else if key == "color-literal":
      invalidate
      color-literal = value
    else if key == "font":
      invalidate
      font = value
    else:
      super key value

  text= value/string -> none:
    invalidate
    text_ = value

  text -> string:
    return text_

  custom-draw canvas/Canvas -> none:
    y := 19
    text_.split "\n": | line |
      comment := line.index-of "//"
      if comment != -1:
        code := line.copy 0 comment
        width := font.pixel-width code
        canvas.text width y --text=line[comment..] --color=color-comment --font=font
        line = line[..comment]
      if line.size != 0 and ' ' <= line[line.size - 1] <= '9':
        literal := ""
        while ' ' <= line[line.size - 1] <= '9':
          literal = line[line.size - 1..] + literal
          line = line.copy 0 line.size - 1
        width := font.pixel-width line
        canvas.text width y --text=literal --color=color-literal --font=font
      canvas.text 0 y --text=line --color=color --font=font
      y += 19

/// Draws the outline of a slice on a ByteArray that is W bytes wide.
class Slice extends CustomElement:
  color/int := ?
  byte-array-width/int
  left/int := ?
  top/int := ?
  right/int := ?
  bottom/int := ?
  thickness/int := 1
  square-size_/int := 20

  constructor --.byte-array-width --x/int?=null --y/int?=null --.color/int?=0 --square-size/int=20 .left .top .right .bottom:
    square-size_ = square-size
    super --x=x --y=y --w=(square-size * byte-array-width) --h=(square-size * bottom)

  type -> string: return "slice"

  set-attribute_ key/string value -> none:
    if key == "thickness":
      invalidate
      thickness = value
    else if key == "color":
      invalidate
      color = value
    else if key == "square-size":
      square-size_ = value
      w = square-size_ * byte-array-width
      h = square-size_ * bottom
    else:
      super key value

  vertical_ canvas/Canvas --x/int --y/int --h/int:
    canvas.rectangle x y --w=thickness --h=h --color=color

  horizontal_ canvas/Canvas --x/int --y/int --w/int:
    canvas.rectangle x y --w=w --h=thickness --color=color

  custom-draw canvas/Canvas:
    vertical_ canvas --x=0 --y=((top + 1) * square-size_) --h=((bottom - top - 1) * square-size_)
    horizontal_ canvas --x=0 --y=((top + 1) * square-size_) --w=(left * square-size_ + thickness)
    vertical_ canvas --x=(left * square-size_) --y=(top * square-size_ + thickness) --h=square-size_
    horizontal_ canvas --x=(left * square-size_) --y=(top * square-size_) --w=((byte-array-width - left) * square-size_)
    vertical_ canvas --x=(byte-array-width * square-size_ - thickness) --y=(top * square-size_) --h=((bottom - top - 1) * square-size_)
    horizontal_ canvas --x=(right * square-size_ - thickness) --y=((bottom - 1) * square-size_ - thickness) --w=((byte-array-width - right) * square-size_)
    vertical_ canvas --x=(right * square-size_ - thickness) --y=((bottom - 1) * square-size_ - thickness) --h=square-size_
    horizontal_ canvas --x=0 --y=(bottom * square-size_ - thickness) --w=(right * square-size_)

/// Draws a text with the pixels blown up to large squares.
class Picture extends CustomElement:
  color-0/int := 0x000000
  color-1/int := 0xffffff
  text/string
  text-x/int
  text-y/int
  pixel-stride/int
  width/int := 1  // In bytes, not pixels.
  height/int := 1 // In bytes, not pixels.
  square-size_/int := 20

  constructor .text/string --.text-x --.text-y --.pixel-stride=1 --x/int?=null --y/int?=null --w/int --h/int --square-size/int=20:
    square-size_ = square-size
    super --x=x --y=y --w=(square-size * w * pixel-stride) --h=(square-size * h)
    width = w
    height = h

  type -> string: return "picture"

  set-attribute_ key/string value -> none:
    if key == "color-0":
      invalidate
      color-0 = value
    else if key == "color-1":
      invalidate
      color-1 = value
    else if key == "square-size":
      square-size_ = value
      w = square-size_ * width
      h = square-size_ * height
    else:
      super key value

  custom-draw canvas/Canvas:
    // Draw text that we will scale up.
    img := ByteArray width * height
    bytemap-draw-text text-x text-y 255 ORIENTATION-0 text SANS-10 img width

    for y := 0; y < height; y++:
      for x := 0; x < width; x++:
        canvas.rectangle
          (x * pixel-stride) * square-size_ + 1
          y * square-size_ + 1
          --w = square-size_ - 1
          --h = square-size_ - 1
          --color = img[y * width + x] == 0 ? color-0 : color-1

/// Draws a grid that represents a ByteArray used as a 2D bytemap.
class Grid extends CustomElement:
  color_/int := ?
  width/int
  height/int
  square-size_/int := 20

  constructor --.width --.height --x/int?=null --y/int?=null --color/int?=0 --square-size/int=20:
    square-size_ = square-size
    color_ = color
    super --x=x --y=y --w=(square-size * width + 1) --h=(square-size * height + 1)

  type -> string: return "grid"

  set-attribute_ key/string value -> none:
    if key == "color":
      invalidate
      color = value
    else if key == "square-size":
      square-size_ = value
      w = (square-size_ * width + 1)
      h = (square-size_ * height + 1)
    else:
      super key value

  color= value/int -> none:
    invalidate
    color_ = value

  custom-draw canvas/Canvas:
    for y := 0; y <= height; y++:
      canvas.rectangle 0 (y * square-size_) --w=(width * square-size_ + 1) --h=1 --color=color_
    for x := 0; x <= width; x++:
      canvas.rectangle (x * square-size_) 0 --w=1 --h=(height * square-size_ + 1) --color=color_

/// Draws a row of byte offset labels on each side of a grid.
class GridOffsets extends CustomElement:
  static X-PADDING_ ::= 50  // Ideally would depend on the height, width and font.
  color_/int := ?
  font_/Font? := null
  width/int
  height/int
  square-size_/int := 20

  constructor --.width --.height --x/int?=null --y/int?=null --color/int?=0 --square-size/int=20:
    square-size_ = square-size
    color_ = color
    super --x=(x and x - X-PADDING_) --y=y --w=(width * square-size + 2 * X-PADDING_) --h=(height * square-size)

  type -> string: return "grid-annotations"

  set-attribute_ key/string value -> none:
    if key == "color":
      color = value
    else if key == "square-size":
      square-size_ = value
      w = (square-size_ * width + 1 + 2 * X-PADDING_)
      h = (square-size_ * height + 1)
    else if key == "font":
      invalidate
      font_ = value
    else:
      super key value

  color= value/int -> none:
    invalidate
    color_ = value

  x= value/int -> none:
    invalidate
    super = value - X-PADDING_

  custom-draw canvas/Canvas:
    for y := 0; y < height; y++:
      y-coord := y * square-size_ + 14
      rhs := X-PADDING_ + width * square-size_
      y-line := y * square-size_ + square-size_/2
      pixel-width := font_.pixel-width "$(y * width)"
      canvas.text (X-PADDING_ - 4 - pixel-width) y-coord --text="$(y * width)" --font=font_ --color=color_
      canvas.text (rhs + 5) y-coord --text="$(y * width + width - 1)" --font=font_ --color=color_
      canvas.rectangle (X-PADDING_ - 3) y-line --h=1 --w=((square-size_ / 2) + 3) --color=color_
      canvas.rectangle (rhs - square-size_ / 2) y-line --h=1 --w=((square-size_ / 2) + 4) --color=color_

/// Draws the annotations on a grid that represents a ByteArray used as a 2D bytemap.
/// The annotations are a title and a diagram for the line stride of the grid.
add-grid-annotations display/PixelDisplay name/string lc-name/string X/int Y/int W/int H/int:
  label := Label --classes=["title"] --x=X --y=(Y - 30) --text="$(name) $(W)x$(H) = $(W * H) bytes"
  display.add label

  stride-y := Y + H * BYTE-SIZE
  label = Label
      --classes = ["stride-label"]
      --x = X + W * BYTE-SIZE/2
      --y = stride-y + 25
      --text = "--$(lc-name)-line-stride=$W"
      --alignment = ALIGN-CENTER
  display.add label

  R := X + W * BYTE-SIZE

  [
      Div --classes=["stride-line"] --x=X --y=(stride-y + 10) --w=(W * BYTE-SIZE + 1) --h=1,
      Div --classes=["stride-line"] --x=X --y=(stride-y + 5) --w=1 --h=5,
      Div --classes=["stride-line"] --x=R --y=(stride-y + 5) --w=1 --h=5,
  ].do: display.add it
