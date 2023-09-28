import pixel-display show PixelDisplay
import png-display show *
import host.file show *
import host.pipe

/**
Writes a PNG file to the given filename.
Only light compression is used, basically just run-length encoding
  of equal pixels.  This is fast and reduces memory use.
*/
write-file filename/string driver/PngDriver_ display/PixelDisplay:
  if filename == "-":
    write-to
        pipe.stdout
        driver
        display
  else:
    write-to
        Stream.for-write filename
        driver
        display
