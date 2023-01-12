#!/bin/sh

if [ ! -d examples ]
then
  echo "Please run from project root"
  exit 1
fi

set -e

mkdir -p examples/tmp
cd examples/tmp

rm -f *.png *.mp4 *.gif

toit.run ../merge-sort.toit --naive &
toit.run ../merge-sort.toit --half &
toit.run ../merge-sort.toit --quarter &

wait  # Wait for pngs to be written.

ffmpeg -framerate 24 -pattern_type glob -i 'merge*.png'   -c:v libx264 -pix_fmt yuv420p merge.mp4
ffmpeg -framerate 24 -pattern_type glob -i 'half*.png'   -c:v libx264 -pix_fmt yuv420p half.mp4
ffmpeg -framerate 24 -pattern_type glob -i 'quarter*.png'   -c:v libx264 -pix_fmt yuv420p quarter.mp4

convert -delay 4 -loop 0 merge*.png merge.gif &
convert -delay 4 -loop 0 half*.png half.gif &
convert -delay 4 -loop 0 quarter*.png quarter.gif &

wait  # Wait for gifs to be written
