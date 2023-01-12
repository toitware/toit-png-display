import bitmap show blit bytemap_draw_text ORIENTATION_0
import font show *
import math
import pixel_display show *
import pixel_display.true_color show *
import png_display show *
import pixel_display.texture show TEXT_TEXTURE_ALIGN_RIGHT TEXT_TEXTURE_ALIGN_LEFT TEXT_TEXTURE_ALIGN_CENTER

import font_x11_adobe.sans_24_bold

import .write_file

FONT ::= Font [sans_24_bold.ASCII, sans_24_bold.LATIN_1_SUPPLEMENT]

// PNG size generated.
WIDTH ::= 512
HEIGHT ::= 400

BACKGROUND ::= get_rgb 255 255 255

LABEL_Y ::= 380
TOP_BUFFER_Y ::= 180
BOTTOM_BUFFER_Y ::= 340
TOP_BUFFER_X ::= 24
BOTTOM_BUFFER_X ::= 24
SPACING ::= 15
COLUMN_WIDTH ::= 9

class Element:
  height/int
  width/int

  x_goal/int := 0
  y_goal/int := 0

  x/int := 0
  y/int := 0

  vx/float := 0.9
  vy/float := 0.0

  rectangle := null
  left := null
  right := null
  top := null
  bottom := null

  speed := 100.0

  static hsl_to_rgb_ h/int s/int l/int -> int:
    sf := s.to_float / 100.0
    lf := l.to_float / 100.0

    a := sf * (min lf (1 - lf))
    f := (: | n |
      k := (n + h / 30.0) % 12
      max1 :=
          max
              -1
              min
                  k - 3
                  min (9 - k) 1
      lf - a * max1
    )
    r := (255.0 * (f.call 0)).to_int
    g := (255.0 * (f.call 8)).to_int
    b := (255.0 * (f.call 4)).to_int
    [r, g, b].do: assert: 0 <= it <= 255
    return (r << 16) + (g << 8) + b

  constructor display rect_context edge_context .x .y .width .height:
    x_goal = x
    y_goal = y
    //hue := ((height - 20) * 2.5).to_int
    hue := height + 120
    context := rect_context.with --color=(hsl_to_rgb_ hue 80 50)
    rectangle = display.filled_rectangle      context 0 0 width height
    left      = display.filled_rectangle edge_context 0 0 1 height
    right     = display.filled_rectangle edge_context 0 0 1 height
    top       = display.filled_rectangle edge_context 0 0 width + 1 1
    bottom    = display.filled_rectangle edge_context 0 0 width + 1 1
    update_position_

  update_position_:
    rectangle.move_to x         y - height
    left.move_to      x         y - height
    right.move_to     x + width y - height
    top.move_to       x         y - height
    bottom.move_to    x         y

  move_goal x y:
    x_goal = TOP_BUFFER_X + x * SPACING
    y_goal = y

  slide:
    if x != x_goal or y != y_goal:
      dx/num := x_goal - x
      dy/num := y_goal - y
      angle := math.atan2 dy dx
      d := (dx * dx + dy * dy).sqrt
      vx += (math.cos angle) * d / speed
      vy += (math.sin angle) * d / speed
    x = (x + vx).round
    y = (y + vy).round
    if (x - x_goal).sign == vx.sign:
      vx = 0.0
      x = x_goal
    if (y - y_goal).sign == vy.sign:
      vy = 0.0
      y = y_goal
    update_position_

  arrived -> bool:
    return x == x_goal and y == y_goal

class Cursor:
  height/int
  width/int
  padding/int

  x/int := 0
  y/int := 0

  left := null
  right := null
  top := null
  bottom := null

  constructor display context .width .height .padding:
    x = -10000
    y = -10000
    left      = display.filled_rectangle context 0 0 1 height
    right     = display.filled_rectangle context 0 0 1 height
    top       = display.filled_rectangle context 0 0 width + 1 1
    bottom    = display.filled_rectangle context 0 0 width + 1 1
    update_position_

  hide:
    x = -10000
    y = -10000
    update_position_

  move_to x y:
    this.x = TOP_BUFFER_X + x * SPACING - padding
    this.y = y + padding
    update_position_

  update_position_:
    left.move_to      x         y - height
    right.move_to     x + width y - height
    top.move_to       x         y - height
    bottom.move_to    x         y

usage:
  print "Usage:"
  print "  toit.run merge-sort.toit --naive"
  print "  toit.run merge-sort.toit --half"
  print "  toit.run merge-sort.toit --quarter"
  exit 1

main args:
  driver := TrueColorPngDriver WIDTH HEIGHT
  display := TrueColorPixelDisplay driver

  display.background = BACKGROUND

  if args.size != 1:
    usage

  if args[0] == "--naive":
    display.remove_all
    visualization := Visualization driver display "merge"
    visualization.naive

  else if args[0] == "--half":
    display.remove_all
    visualization := Visualization driver display "half"
    visualization.half

  else if args[0] == "--quarter":
    display.remove_all
    visualization := Visualization driver display "quarter"
    visualization.quarter

  else:
    usage

class Visualization:
  driver := null
  display := null
  filename /string
  array /List
  cursor1 /Cursor
  cursor2 /Cursor
  group_context := ?
  text_context := ?
  group1 /Cursor? := null
  group2 /Cursor? := null
  ctr := 0

  constructor .driver .display .filename:
    context := display.context --landscape --alignment=TEXT_TEXTURE_ALIGN_CENTER --color=(get_rgb 0 0 0) --font=FONT

    text_context = context
    rect_context := context.with --color=(get_rgb 180 120 120)
    edge_context := context.with --color=(get_rgb 20 20 20)
    cursor_context := context.with --color=(get_rgb 255 20 20)
    group_context = context.with --color=(get_rgb 20 20 255)

    array = List 32:
      Element display rect_context edge_context
          TOP_BUFFER_X + it * SPACING
          TOP_BUFFER_Y
          COLUMN_WIDTH
          20 + (random 120)

    cursor1 = Cursor display cursor_context COLUMN_WIDTH + 4 144 2
    cursor2 = Cursor display cursor_context COLUMN_WIDTH + 4 144 2

    20.repeat:
      write

  swap_pairs y:
    for i := 0; i < array.size; i += 2:
      first := array[i]
      second := array[i + 1]
      if first.height > second.height:
        array[i] = second
        array[i + 1] = first
        first.move_goal i + 1 y
        second.move_goal i y
      array.do:
        it.slide
      write
    complete
    array.do: it.speed = 50.0

  naive:
    //display.text text_context WIDTH/2 LABEL_Y "Two-buffer merge sort"
    20.repeat: write
    swap_pairs TOP_BUFFER_Y
    naive_sort 2 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    naive_sort 4 BOTTOM_BUFFER_Y TOP_BUFFER_Y
    naive_sort 8 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    naive_sort 16 BOTTOM_BUFFER_Y TOP_BUFFER_Y
    20.repeat: write

  naive_sort size/int from_y/int to_y/int:
    print "naive: Sort $size image $ctr"
    dest_array := []
    group1 = Cursor display group_context (SPACING * size) 146 3
    group2 = Cursor display group_context (SPACING * size) 146 3

    for i := 0; i < array.size; i += size * 2:
      group1.move_to i from_y
      group2.move_to i + size from_y
      dest := i
      x := i
      x2 := i + size
      while x < i + size or x2 < i + size * 2:
        cursor1.move_to x from_y
        cursor2.move_to x2 from_y

        pick_left := ?
        if x == i + size:
          cursor1.hide
          pick_left = false
        else if x2 == i + size * 2:
          cursor2.hide
          pick_left = true
        else:
          pick_left = array[x].height <= array[x2].height
        write
        new_x := dest_array.size
        mover := pick_left ? array[x++] : array[x2++]
        mover.move_goal new_x to_y
        dest_array.add mover
        slide_steps --steps=10

    array.replace 0 dest_array
    cursor1.hide
    cursor2.hide
    complete
    group1.hide
    group2.hide
    write

  half:
    //display.text text_context WIDTH/2 LABEL_Y "Merge sort with half-sized buffer"
    20.repeat: write
    buffer := Cursor display group_context (SPACING * array.size / 2) 146 3
    buffer.move_to 0 BOTTOM_BUFFER_Y
    swap_pairs TOP_BUFFER_Y
    half_sort 0 2 2 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 0 4 4 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 0 8 8 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 0 16 16 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    buffer.hide
    100.repeat: write

  quarter:
    //display.text text_context WIDTH/2 LABEL_Y "Merge sort with ¼-sized buffer"
    20.repeat: write
    swap_pairs TOP_BUFFER_Y
    buffer := Cursor display group_context (SPACING * array.size / 4) 146 3
    buffer.move_to 0 BOTTOM_BUFFER_Y
    half_sort 0 2 2 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 0 4 4 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 16 8 8 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 8 8 16 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    half_sort 0 8 24 TOP_BUFFER_Y BOTTOM_BUFFER_Y
    buffer.hide
    100.repeat: write

  half_sort start/int size1/int size2/int from_y/int to_y/int:
    print "half: Sort $size1/$size2 image $ctr"
    dest_array := []
    group1 = Cursor display group_context (SPACING * (size1 + size2)) 146 3

    pick_state := null

    for i := start; i < array.size; i += size1 + size2:
      complete
      group1.move_to i from_y
      dest_array = []
      for x := i; x < i + size1; x++:
        item := array[x]
        array[x] = null
        dest_array.add item
        item.move_goal x - i to_y
      complete dest_array

      dest := i
      x := i + size1
      x2 := 0
      idx := i
      while x2 < size1:
        cursor1.move_to x from_y
        cursor2.move_to x2 to_y

        pick_left := ?
        if x == i + size1 + size2:
          cursor1.hide
          pick_left = false
        else if x2 == size1:
          cursor2.hide
          pick_left = true
        else:
          pick_left = array[x].height <= dest_array[x2].height
        if pick_left != pick_state:
          complete
          pick_state = pick_left
        mover := ?
        if pick_left:
          mover = array[x]
          array[x++] = null
        else:
          mover = dest_array[x2++]
        mover.move_goal idx from_y
        array[idx++] = mover
        slide_steps --steps=2

      cursor1.hide
      cursor2.hide
      complete
      group1.hide
      write

  slide_steps list/List=array --steps=10 -> none:
    while steps > 0 and (list.any: it and not it.arrived):
      list.do: if it: it.slide
      steps--
      write

  complete list/List=array -> none:
    while (list.any: it and not it.arrived):
      list.do: if it: it.slide
      write

  write:
    write_file "$filename$(%04d ctr++).png" driver display
