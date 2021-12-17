#!/bin/sh

for name in 1x1.toit blit_explanation.toit docs-example.toit simple-3-color.toit simple-bw.toit simple-color.toit simple-gray.toit simple-several.toit weather-4-gray.toit weather-bw.toit weather-gray.toit weather-several-color.toit weather-three-color.toit weather.toit
do
  echo $name
  ../../toit/build/host/sdk/bin/toitvm $name
done
