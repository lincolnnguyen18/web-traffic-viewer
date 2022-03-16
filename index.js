const fs = require('fs');

let logPath = '../haproxy.log';

function diffStrings(str1, str2) {
  let diff = '';
  let i = 0;
  while (i < str1.length && i < str2.length) {
    if (str1[i] !== str2[i]) {
      diff += str1[i];
    }
    i++;
  }
  if (i < str1.length) {
    diff += str1.substring(i);
  }
  if (i < str2.length) {
    diff += str2.substring(i);
  }
  return diff;
}

fs.watchFile('../haproxy.log', { persistent: true, interval: 1000 }, (curr, prev) => {
  let log = fs.readFileSync(logPath, 'utf8');
  console.log(log); 
  fs.writeFileSync('../haproxy.diff', '');
});