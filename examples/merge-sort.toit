import bitmap show blit bytemap-draw-text ORIENTATION-0
import font show *
import math
import pixel-display show *
import pixel-display.true-color show *
import png-display show *
import pixel-display.texture show TEXT-TEXTURE-ALIGN-RIGHT TEXT-TEXTURE-ALIGN-LEFT TEXT-TEXTURE-ALIGN-CENTER

import font-x11-adobe.sans-24-bold

import .write-file

FONT ::= Font [sans-24-bold.ASCII, sans-24-bold.LATIN-1-SUPPLEMENT]

// PNG size generated.
WIDTH ::= 512
HEIGHT ::= 400

BACKGROUND ::= get-rgb 255 255 255

LABEL-Y ::= 380
TOP-BUFFER-Y ::= 180
BOTTOM-BUFFER-Y ::= 340
TOP-BUFFER-X ::= 24
BOTTOM-BUFFER-X ::= 24
SPACING ::= 15
COLUMN-WIDTH ::= 9

class Element:
  height/int
  width/int

  x-goal/int := 0
  y-goal/int := 0

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

  static hsl-to-rgb_ h/int s/int l/int -> int:
    sf := s.to-float / 100.0
    lf := l.to-float / 100.0

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
    r := (255.0 * (f.call 0)).to-int
    g := (255.0 * (f.call 8)).to-int
    b := (255.0 * (f.call 4)).to-int
    [r, g, b].do: assert: 0 <= it <= 255
    return (r << 16) + (g << 8) + b

  constructor display rect-context edge-context .x .y .width .height:
    x-goal = x
    y-goal = y
    hue := height + 120
    context := rect-context.with --color=(hsl-to-rgb_ hue 80 50)
    rectangle = display.filled-rectangle      context 0 0 width height
    left      = display.filled-rectangle edge-context 0 0 1 height
    right     = display.filled-rectangle edge-context 0 0 1 height
    top       = display.filled-rectangle edge-context 0 0 width + 1 1
    bottom    = display.filled-rectangle edge-context 0 0 width + 1 1
    update-position_

  update-position_:
    rectangle.move-to x         y - height
    left.move-to      x         y - height
    right.move-to     x + width y - height
    top.move-to       x         y - height
    bottom.move-to    x         y

  move-goal x y:
    x-goal = TOP-BUFFER-X + x * SPACING
    y-goal = y

  slide:
    if x != x-goal or y != y-goal:
      dx/num := x-goal - x
      dy/num := y-goal - y
      angle := math.atan2 dy dx
      d := (dx * dx + dy * dy).sqrt
      vx += (math.cos angle) * d / speed
      vy += (math.sin angle) * d / speed
    x = (x + vx).round
    y = (y + vy).round
    if (x - x-goal).sign == vx.sign:
      vx = 0.0
      x = x-goal
    if (y - y-goal).sign == vy.sign:
      vy = 0.0
      y = y-goal
    update-position_

  arrived -> bool:
    return x == x-goal and y == y-goal

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
    left      = display.filled-rectangle context 0 0 1 height
    right     = display.filled-rectangle context 0 0 1 height
    top       = display.filled-rectangle context 0 0 width + 1 1
    bottom    = display.filled-rectangle context 0 0 width + 1 1
    update-position_

  hide:
    x = -10000
    y = -10000
    update-position_

  move-to x y:
    this.x = TOP-BUFFER-X + x * SPACING - padding
    this.y = y + padding
    update-position_

  update-position_:
    left.move-to      x         y - height
    right.move-to     x + width y - height
    top.move-to       x         y - height
    bottom.move-to    x         y

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
    display.remove-all
    visualization := Visualization driver display "merge"
    visualization.naive

  else if args[0] == "--half":
    display.remove-all
    visualization := Visualization driver display "half"
    visualization.half

  else if args[0] == "--quarter":
    display.remove-all
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
  group-context := ?
  text-context := ?
  group1 /Cursor? := null
  group2 /Cursor? := null
  ctr := 0

  constructor .driver .display .filename:
    context := display.context --landscape --alignment=TEXT-TEXTURE-ALIGN-CENTER --color=(get-rgb 0 0 0) --font=FONT

    text-context = context
    rect-context := context.with --color=(get-rgb 180 120 120)
    edge-context := context.with --color=(get-rgb 20 20 20)
    cursor-context := context.with --color=(get-rgb 255 20 20)
    group-context = context.with --color=(get-rgb 20 20 255)

    array = List 32:
      Element display rect-context edge-context
          TOP-BUFFER-X + it * SPACING
          TOP-BUFFER-Y
          COLUMN-WIDTH
          20 + (random 120)

    cursor1 = Cursor display cursor-context COLUMN-WIDTH + 4 144 2
    cursor2 = Cursor display cursor-context COLUMN-WIDTH + 4 144 2

    20.repeat:
      write

  swap-pairs y:
    for i := 0; i < array.size; i += 2:
      first := array[i]
      second := array[i + 1]
      if first.height > second.height:
        array[i] = second
        array[i + 1] = first
        first.move-goal i + 1 y
        second.move-goal i y
      array.do:
        it.slide
      write
    complete
    array.do: it.speed = 50.0

  naive:
    //display.text text_context WIDTH/2 LABEL_Y "Two-buffer merge sort"
    20.repeat: write
    swap-pairs TOP-BUFFER-Y
    naive-sort 2 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    naive-sort 4 BOTTOM-BUFFER-Y TOP-BUFFER-Y
    naive-sort 8 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    naive-sort 16 BOTTOM-BUFFER-Y TOP-BUFFER-Y
    20.repeat: write

  naive-sort size/int from-y/int to-y/int:
    print "naive: Sort $size image $ctr"
    dest-array := []
    group1 = Cursor display group-context (SPACING * size) 146 3
    group2 = Cursor display group-context (SPACING * size) 146 3

    for i := 0; i < array.size; i += size * 2:
      group1.move-to i from-y
      group2.move-to i + size from-y
      dest := i
      x := i
      x2 := i + size
      while x < i + size or x2 < i + size * 2:
        cursor1.move-to x from-y
        cursor2.move-to x2 from-y

        pick-left := ?
        if x == i + size:
          cursor1.hide
          pick-left = false
        else if x2 == i + size * 2:
          cursor2.hide
          pick-left = true
        else:
          pick-left = array[x].height <= array[x2].height
        write
        new-x := dest-array.size
        mover := pick-left ? array[x++] : array[x2++]
        mover.move-goal new-x to-y
        dest-array.add mover
        slide-steps --steps=10

    array.replace 0 dest-array
    cursor1.hide
    cursor2.hide
    complete
    group1.hide
    group2.hide
    write

  half:
    //display.text text_context WIDTH/2 LABEL_Y "Merge sort with half-sized buffer"
    20.repeat: write
    buffer := Cursor display group-context (SPACING * array.size / 2) 146 3
    buffer.move-to 0 BOTTOM-BUFFER-Y
    swap-pairs TOP-BUFFER-Y
    half-sort 0 2 2 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 0 4 4 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 0 8 8 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 0 16 16 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    buffer.hide
    100.repeat: write

  quarter:
    //display.text text_context WIDTH/2 LABEL_Y "Merge sort with ¼-sized buffer"
    20.repeat: write
    swap-pairs TOP-BUFFER-Y
    buffer := Cursor display group-context (SPACING * array.size / 4) 146 3
    buffer.move-to 0 BOTTOM-BUFFER-Y
    half-sort 0 2 2 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 0 4 4 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 16 8 8 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 8 8 16 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    half-sort 0 8 24 TOP-BUFFER-Y BOTTOM-BUFFER-Y
    buffer.hide
    100.repeat: write

  half-sort start/int size1/int size2/int from-y/int to-y/int:
    print "half: Sort $size1/$size2 image $ctr"
    dest-array := []
    group1 = Cursor display group-context (SPACING * (size1 + size2)) 146 3

    pick-state := null

    for i := start; i < array.size; i += size1 + size2:
      complete
      group1.move-to i from-y
      dest-array = []
      for x := i; x < i + size1; x++:
        item := array[x]
        array[x] = null
        dest-array.add item
        item.move-goal x - i to-y
      complete dest-array

      dest := i
      x := i + size1
      x2 := 0
      idx := i
      while x2 < size1:
        cursor1.move-to x from-y
        cursor2.move-to x2 to-y

        pick-left := ?
        if x == i + size1 + size2:
          cursor1.hide
          pick-left = false
        else if x2 == size1:
          cursor2.hide
          pick-left = true
        else:
          pick-left = array[x].height <= dest-array[x2].height
        if pick-left != pick-state:
          complete
          pick-state = pick-left
        mover := ?
        if pick-left:
          mover = array[x]
          array[x++] = null
        else:
          mover = dest-array[x2++]
        mover.move-goal idx from-y
        array[idx++] = mover
        slide-steps --steps=2

      cursor1.hide
      cursor2.hide
      complete
      group1.hide
      write

  slide-steps list/List=array --steps=10 -> none:
    while steps > 0 and (list.any: it and not it.arrived):
      list.do: if it: it.slide
      steps--
      write

  complete list/List=array -> none:
    while (list.any: it and not it.arrived):
      list.do: if it: it.slide
      write

  write:
    write-file "$filename$(%04d ctr++).png" driver display
