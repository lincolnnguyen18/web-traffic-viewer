const fs = require('fs');
const DottedMap = require('dotted-map').default;
// Or in the browser: import DottedMap from 'dotted-map';

const map = new DottedMap({ height: 60, grid: 'diagonal' });

map.addPin({
  lat: 40.73061,
  lng: -73.935242,
  svgOptions: { color: '#9BFF71', radius: 0.7 },
});
map.addPin({
  lat: 48.8534,
  lng: 2.3488,
  svgOptions: { color: '#9BFF71', radius: 0.7 },
});

const svgMap = map.getSVG({
  radius: 0.22,
  color: '#423B38',
  shape: 'circle',
  backgroundColor: '#020300',
});

fs.writeFileSync('./map.svg', svgMap);