
import express from 'express';
const app = express();
import fs from 'fs';
import cors from 'cors';
import fetch from 'node-fetch';
import mysql from 'mysql2';
// const DottedMap = require('dotted-map').default;
import DottedMap from 'dotted-map';
// DottedMap = DottedMap.default;
import util from 'util';
const conn = mysql.createConnection({
  host: 'localhost',
  user: 'admin',
  password: 'pass123',
  database: 'web_traffic_viewer',
  multipleStatements: true
});
import path from 'path';
const __dirname = path.resolve();
app.use(express.json());
app.use(cors());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

const ping = () => {
  // console.log('pinging mysql server; date: ' + new Date());
  conn.query('SELECT 1');
}

// ping mysql server to keep connection alive every 1 minute
ping();
setInterval(() => {
  ping();
}, 60000);

function getPosition(string, subString, index) {
  return string.split(subString, index).join(subString).length;
}

function getAppName(app) {
  switch (app) {
    case 'l18':
      return `resume site`;
    case 'd1':
      return `weeread`;
    case 'd3':
      return `decaminute`;
    case 'd4':
      return `weespeak2`;
    case 'd5':
      return `weespeak2 wss`;
    case 'd6':
      return `quickreader`;
    case 'd7':
      return `youtube-looper`;
    case 'd8':
      return `ip and address lookup`;
    case 'd9':
      return `rapid-tracing2`;
    case 'd10':
      return 'web-traffic-viewer';
    default:
      return `unknown`;
  }
}

let logPath = '../haproxy.log';
fs.writeFileSync('../haproxy.log', '');
fs.watchFile('../haproxy.log', { persistent: true, interval: 1000 }, async (curr, prev) => {
  let log = fs.readFileSync(logPath, 'utf8').trim();
  let logLines = log.split('\n');
  // client_address = "129.49.100.88", path = "/index.css", connect_time = 502, backend_name = "l18", bytes = 232
  if (log.trim()) {
    let visits = {};
    logLines.forEach(line => {
      // console.log(`line: ${line}`);
      let textAfterThirdColon = line.substring(getPosition(line, ':', 3) + 1).trim();
      // console.log(`textAfterThirdColon): ${textAfterThirdColon}`);
      let json = `[${textAfterThirdColon}]`;
      // console.log(`json: ${json}`);
      let parsed;
      try {
        parsed = JSON.parse(json);
      } catch (e) {
        // console.log(`error parsing json: ${e}`);
        return;
      }
      // console.log(parsed)
      let ip = parsed[0];
      if (ip == '192.168.1.254') return;
      let path = parsed[1];
      let Tt = parsed[2];
      let app = parsed[3];
      let Tq = parsed[4];
      let Tw = parsed[5];
      let Tc = parsed[6];
      let Tr = parsed[7];
      let Ta = parsed[8];
      let TR = parsed[9];
      // console.log(Tt, Tq, Tw, Tc, Tr, Ta, TR);
      let appName = `${app}: ${getAppName(app)}`;
      let bytes = parsed[4];
      // console.log(ip, path, time, appName, bytes);
      if (!(ip in visits)) {
        visits[ip] = {'apps': {}};
      }
      if (!(appName in visits[ip]['apps'])) {
        visits[ip]['apps'][appName] = [];
      }
      visits[ip]['apps'][appName].push({ path: path, time: Tt, bytes: bytes });
    });
    let ips = Object.keys(visits);
    let fetchArray = [];
    for (let i = 0; i < ips.length; i++) {
      let ip = ips[i];
      fetchArray.push(fetch(`http://localhost:7006/getCustomIpInfo?ip=${encodeURI(ip)}`));
    }
    // console.log(fetchArray)
    const res = await Promise.all(fetchArray);
    const data = await Promise.all(res.map(r => r.json()));
    data.forEach(result => {
      const { country, city, region, ll } = result;
      const ip = result.ip;
      visits[ip].country = country;
      visits[ip].city = city;
      visits[ip].region = region;
      visits[ip].ll = ll;
    });
    // console.log(util.inspect(visits, false, null, true));
    Object.keys(visits).forEach(ip => {
      // console.log(ip)
      let visit = visits[ip];
      // console.log(visit)
      const regionNamesInEnglish = new Intl.DisplayNames(['en'], { type: 'region' });
      if (visit.country) {
        visit.country = regionNamesInEnglish.of(visit.country);
      }
      let country = visit.country ? visit.country : 'N/A';
      let city = visit.city ? visit.city : 'N/A';
      let region = visit.region ? visit.region : 'N/A';
      let apps = Object.keys(visit.apps);
      let latitude = visit.ll ? visit.ll[0] : null;
      let longitude = visit.ll ? visit.ll[1] : null;
      apps.forEach(app => {
        // CREATE PROCEDURE insert_visit(_ip TEXT, _app TEXT, _country TEXT, _region TEXT, _city TEXT, _time TEXT, _bytes INTEGER, _path TEXT) BEGIN
        let reqs = visit.apps[app];
        reqs.forEach(req => {
          const { path, time, bytes } = req;
          // console.log(`CALL insert_visit(?, ?, ?, ?, ?, ?, ?, ?), ${[ip, app, country, region, city, time, bytes, path]}`);
          conn.execute(`CALL insert_visit(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [ip, app, country, region, city, time, bytes, path, latitude, longitude], (err, results, fields) => {
            if (err) {
              console.log(`error: ${err}`);
            }
          });
        });
      });
    });
  }
  fs.writeFileSync('../haproxy.log', '');
});

app.get('/', (req, res) => {
  res.sendFile(__dirname + '/vue/dist/index.html');
});

app.get('/getVisits', (req, res) => {
  let lastId = req.query.lastId;
  let search = req.query.search;
  if (!search) {
    search = "";
  }
  search = search.trim();
  if (!lastId) {
    conn.execute('CALL get_last_15_visits(?)', [search], (err, results, fields) => {
      if (err) {
        console.log(`error: ${err}`);
      } else {
        res.send(results[0]);
      }
    });
  } else {
    conn.execute('CALL get_visits(?, ?)', [lastId, search], (err, results, fields) => {
      if (err) {
        console.log(`error: ${err}`);
      } else {
        res.send(results[0]);
      }
    });
  }
});

app.get('/getDetails', (req, res) => {
  let visitId = req.query.visitId;
  if (!visitId) {
    return res.send({'error': 'no visitId'});
  } else {
    conn.execute('CALL get_details(?)', [visitId], (err, results, fields) => {
      if (err) {
        console.log(`error: ${err}`);
      } else {
        res.send(results[0]);
      }
    });
  }
});

app.get('/getMap', (req, res) => {
  conn.execute('CALL get_latitude_longitude_past_month()', (err, results, fields) => {
    if (err) {
      console.log(`error: ${err}`);
    } else {
      let points = results[0];
      const map = new DottedMap.default({ height: 60, grid: 'diagonal' });
      points.forEach(point => {
        map.addPin({
          lat: point.latitude,
          lng: point.longitude,
          svgOptions: { color: '#9BFF71', radius: 0.7 }
        });
      });
      const svgMap = map.getSVG({
        radius: 0.22,
        color: '#423B38',
        shape: 'circle',
        backgroundColor: '#020300',
      });
      res.send(svgMap);
    }
  });
});

const port = 7008;
app.listen(port, () => console.log(`Example app listening on port ${port}!`));