#!/bin/sh

for name in 1x1.toit blit-explanation.toit docs-example.toit
do
  echo $name
  toit.run $name
done
