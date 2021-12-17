import bitmap show blit bytemap_draw_text ORIENTATION_0
import font show *
import pixel_display show *
import pixel_display.true_color show *
import png_display show *
import pixel_display.texture show TEXT_TEXTURE_ALIGN_RIGHT TEXT_TEXTURE_ALIGN_LEFT TEXT_TEXTURE_ALIGN_CENTER

import font.x11_100dpi.sans.sans_24_bold
import font.x11_100dpi.typewriter.typewriter_14_bold

import .write_file

// Generates the diagrams used on https://docs.toit.io/language/sdk/blit

// PNG size generated.
WIDTH ::= 1024
HEIGHT ::= 768

// Position and size of the source byte array in the PNG.
SOURCE_Y ::= 100
SOURCE_X ::= 50
SOURCE_WIDTH ::= 30
SOURCE_HEIGHT ::= 17

// Size of each square (byte) in the byte array diagrams.
BYTE_SIZE := 16

// Position and size of the destination byte array in the PNG.
DEST_X ::= 600
DEST_Y ::= 300
DEST_WIDTH := 20
DEST_HEIGHT := 25

SANS_10 ::= Font.get "sans10"
CODE_FONT := Font [typewriter_14_bold.ASCII]

main:
  diagram "blit"
  diagram "blit-stride" --pixel_stride=2 --extra_code="  --destination_pixel_stride=2"

// Generates a PNG file showing how blit works.
diagram filename/string --pixel_stride=1 --extra_code=null:
  driver := TrueColorPngDriver WIDTH HEIGHT
  display := TrueColorPixelDisplay driver

  stride_label := display.context --landscape --alignment=TEXT_TEXTURE_ALIGN_CENTER --color=(get_rgb 255 0 0) --font=SANS_10

  grid display stride_label "Source" "source" SOURCE_X SOURCE_Y SOURCE_WIDTH SOURCE_HEIGHT
  grid display stride_label "Dest" "destination" DEST_X DEST_Y DEST_WIDTH DEST_HEIGHT

  picture display "blit" 5 SOURCE_HEIGHT - 2 SOURCE_X SOURCE_Y SOURCE_WIDTH SOURCE_HEIGHT

  picture display "b" 0 12 DEST_X DEST_Y 8 13 --pixel_stride=pixel_stride

  // Slice of source.
  slice display SOURCE_X SOURCE_Y SOURCE_WIDTH SOURCE_HEIGHT 5 3 13 16

  // Slice legend.
  slice display 600 130 4 3 1 0 3 2
  left_align := stride_label.with --alignment=TEXT_TEXTURE_ALIGN_LEFT
  display.text left_align 600 + 5 * BYTE_SIZE 150 "= slice of byte array"

  code_context := left_align.with --color=(get_rgb 0 0 0) --font=CODE_FONT
  comment_context := left_align.with --color=(get_rgb 0 0 255) --font=CODE_FONT
  literal_context := left_align.with --color=(get_rgb 255 192 192) --font=CODE_FONT
  code := Code display 50 440 code_context comment_context literal_context

  code.line "// Copy 8x13 rectangle at (5, 4)"
  code.line "// from source to dest."
  code.line "X := 5"
  code.line "Y := 4"
  code.line "W := 8"
  code.line "H := 9"
  code.line "SLS := 30  // source line stride."
  code.line "DLS := 20  // dest line stride."
  code.line "slice_start := X + Y * SLS"
  code.line "slice_end := X + W + (Y + H) * SLS"
  code.line "blit"
  code.line "  source[slice_start..slice_end]"
  code.line "  dest"
  code.line "  W"
  code.line "  --source_line_stride=SLS"
  code.line "  --destination_line_stride=DLS"
  if extra_code:
    code.line extra_code

  write_file "$(filename).png" driver display

// Used to display the code snippet in the diagram.
class Code:
  display := ?
  x/int ::= ?
  y/int := ?
  code_context := ?
  comment_context := ?
  literal_context := ?

  constructor .display .x .y .code_context .comment_context .literal_context:

  line text/string:
    comment := text.index_of "//"
    if comment != -1:
      code := text.copy 0 comment
      width := code_context.font.pixel_width code
      display.text comment_context x + width y (text.copy comment)
      text = text.copy 0 comment
    if text.size != 0 and ' ' <= text[text.size - 1] <= '9':
      literal := ""
      while ' ' <= text[text.size - 1] <= '9':
        literal = text[text.size - 1..] + literal
        text = text.copy 0 text.size - 1
      width := code_context.font.pixel_width text
      display.text literal_context x + width y literal
    display.text code_context x y text
    y += 19

// Draws the outline of a slice on a ByteArray of size W * H.
slice display X Y W H left top right bottom:
  red_line := display.context --landscape --color=(get_rgb 255 0 0)

  display.filled_rectangle red_line
    X
    Y + (top + 1) * BYTE_SIZE
    3
    (bottom - top - 1) * BYTE_SIZE

  display.filled_rectangle red_line
    X
    Y + (top + 1) * BYTE_SIZE
    left * BYTE_SIZE + 3
    3

  display.filled_rectangle red_line
    X + left * BYTE_SIZE
    Y + top * BYTE_SIZE + 3
    3
    BYTE_SIZE

  display.filled_rectangle red_line
    X + left * BYTE_SIZE
    Y + top * BYTE_SIZE
    (W - left) * BYTE_SIZE
    3

  display.filled_rectangle red_line
    X + W * BYTE_SIZE - 3
    Y + top * BYTE_SIZE
    3
    (bottom - top - 1) * BYTE_SIZE

  display.filled_rectangle red_line
    X + right * BYTE_SIZE - 3
    Y + (bottom - 1) * BYTE_SIZE - 3
    (W - right) * BYTE_SIZE
    3

  display.filled_rectangle red_line
    X + right * BYTE_SIZE - 3
    Y + (bottom - 1) * BYTE_SIZE - 3
    3
    BYTE_SIZE

  display.filled_rectangle red_line
    X
    Y + bottom * BYTE_SIZE - 3
    right * BYTE_SIZE
    3

// Draws an image in the ByteArray (some letters).
picture display/TrueColorPixelDisplay text/string text_x/int text_y/int X/int Y/int W/int H/int --pixel_stride=1:
  fg := display.context --landscape --color=(get_rgb 255 190 170) --font=SANS_10
  bg := display.context --landscape --color=(get_rgb 192 150 110) --font=SANS_10

  img := ByteArray W * H

  bytemap_draw_text text_x text_y 255 ORIENTATION_0 text SANS_10 img W

  for y := 0; y < H; y++:
    for x := 0; x < W; x++:
      display.filled_rectangle
        img[y * W + x] == 0 ? bg : fg
        X + (x * pixel_stride) * BYTE_SIZE + 1
        Y + y * BYTE_SIZE + 1
        BYTE_SIZE - 1
        BYTE_SIZE - 1

// Draws a grid that represents a ByteArray used as a 2D bytemap.
grid display label_context name lc_name X Y W H:
  context := display.context --landscape --color=BLACK --font=SANS_10

  for y := 0; y <= H; y++:
    y_coord := Y + y * BYTE_SIZE
    display.line context X y_coord
      X + BYTE_SIZE * W + 1
      y_coord

  for x := 0; x <= W; x++:
    x_coord := X + x * BYTE_SIZE
    display.line context x_coord Y
      x_coord
      Y + BYTE_SIZE * H + 1

  title_font := context.with --font=(Font [sans_24_bold.ASCII]) --color=(get_rgb 50 50 50)

  display.text title_font X Y - 30 "$name $(W)x$H = $(W * H) bytes"

  left_labels := context.with --alignment=TEXT_TEXTURE_ALIGN_RIGHT --color=(get_rgb 40 40 200)
  right_labels := left_labels.with --alignment=TEXT_TEXTURE_ALIGN_LEFT

  stride_y := Y + H * BYTE_SIZE
  display.text label_context
    X + W * BYTE_SIZE/2
    stride_y + 25
    "--$(lc_name)_line_stride=$W"

  R := X + W * BYTE_SIZE + 1

  display.line label_context X stride_y + 10 R stride_y + 10
  display.line label_context X stride_y + 10 X stride_y + 5
  display.line label_context R stride_y + 10 R stride_y + 5

  for y := 0; y < H; y++:
    y_coord := Y + y * BYTE_SIZE + 14
    rhs := X + W * BYTE_SIZE
    display.text left_labels X - 4 y_coord "$(y * W)"
    display.text right_labels rhs + 5 y_coord "$(y * W + W - 1)"
    y_line := Y + y * BYTE_SIZE + BYTE_SIZE/2
    display.line left_labels
      X - 3
      y_line
      X + BYTE_SIZE/2
      y_line
    display.line right_labels
      rhs + 4
      y_line
      rhs - BYTE_SIZE/2
      y_line
