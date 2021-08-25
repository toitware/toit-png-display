import bitmap show blit bytemap_draw_text ORIENTATION_0
import font show *
import pixel_display show *
import pixel_display.true_color show *
import png_display show *
import pixel_display.texture show TEXT_TEXTURE_ALIGN_RIGHT TEXT_TEXTURE_ALIGN_LEFT TEXT_TEXTURE_ALIGN_CENTER

import font.x11_100dpi.sans.sans_24_bold

WIDTH ::= 1024
HEIGHT ::= 768

SOURCE_Y ::= 100
SOURCE_X ::= 50

SOURCE_WIDTH ::= 30
SOURCE_HEIGHT ::= 20

BYTE_SIZE := 16

DEST_WIDTH := 20
DEST_HEIGHT := 25

DEST_X ::= 600
DEST_Y ::= 300

main:
  driver := TrueColorPngDriver WIDTH HEIGHT
  display := TrueColorPixelDisplay driver

  grid display "Source" "source" SOURCE_X SOURCE_Y SOURCE_WIDTH SOURCE_HEIGHT
  grid display "Dest" "destination" DEST_X DEST_Y DEST_WIDTH DEST_HEIGHT

  picture display "blit" SOURCE_X SOURCE_Y SOURCE_WIDTH SOURCE_HEIGHT

  slice display SOURCE_X SOURCE_Y SOURCE_WIDTH SOURCE_HEIGHT 5 3 13 16

  display.draw

  driver.write "blit.png"

slice display X Y W H x y w h:
  red_line := display.context --landscape --color=(get_rgb 255 0 0)

  display.filled_rectangle red_line
    X
    Y + (y + 1) * BYTE_SIZE
    3
    h * BYTE_SIZE

  display.filled_rectangle red_line
    X
    Y + (y + 1) * BYTE_SIZE
    x * BYTE_SIZE + 3
    3

  display.filled_rectangle red_line
    X + x * BYTE_SIZE
    Y + y * BYTE_SIZE + 3
    3
    BYTE_SIZE

picture display text X Y W H:
  fg := display.context --landscape --color=(get_rgb 255 190 170) --font=(Font.get "sans10")
  bg := display.context --landscape --color=(get_rgb 192 150 110) --font=(Font.get "sans10")

  img := ByteArray W * H

  font := Font.get "sans10"

  bytemap_draw_text 5 H - 5 255 ORIENTATION_0 text font img W

  for y := 0; y < H; y++:
    for x := 0; x < W; x++:
      display.filled_rectangle
        img[y * W + x] == 0 ? bg : fg
        X + x * BYTE_SIZE + 1
        Y + y * BYTE_SIZE + 1
        BYTE_SIZE - 1
        BYTE_SIZE - 1

grid display name lc_name X Y W H:
  context := display.context --landscape --color=BLACK --font=(Font.get "sans10")

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
  stride_label := left_labels.with --alignment=TEXT_TEXTURE_ALIGN_CENTER --color=(get_rgb 255 0 0)

  stride_y := Y + H * BYTE_SIZE
  display.text stride_label
    X + W * BYTE_SIZE/2
    stride_y + 25
    "--$(lc_name)_line_stride=$W"

  R := X + W * BYTE_SIZE + 1

  display.line left_labels X stride_y + 10 R stride_y + 10
  display.line left_labels X stride_y + 10 X stride_y + 5
  display.line left_labels R stride_y + 10 R stride_y + 5

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

