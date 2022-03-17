-- visit(id, date, ip, app, country, region, city)
-- detail(id, time, bytes, path)
-- visit_details(visit_id, detail_id)

DROP DATABASE IF EXISTS web_traffic_viewer;
CREATE DATABASE web_traffic_viewer;
USE web_traffic_viewer;

CREATE TABLE visit (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip TEXT,
  app TEXT,
  country TEXT,
  region TEXT,
  city TEXT,
  time INTEGER DEFAULT 0,
  bytes INTEGER DEFAULT 0
);

CREATE TABLE detail (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  time TEXT,
  bytes INTEGER,
  path TEXT
);

CREATE TABLE visit_details (
  visit_id INTEGER,
  detail_id INTEGER,
  FOREIGN KEY(visit_id) REFERENCES visit(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY(detail_id) REFERENCES detail(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

DELIMITER //

CREATE PROCEDURE insert_visit(_ip TEXT, _app TEXT, _country TEXT, _region TEXT, _city TEXT, _time TEXT, _bytes INTEGER, _path TEXT) BEGIN
  -- get id of visit with same values created in past minute
  SET @visit_id := (SELECT id FROM visit WHERE ip = _ip AND app = _app AND date > DATE_SUB(NOW(), INTERVAL 5 MINUTE));
  -- if visit_id doesn't exist then insert new visit
  IF @visit_id IS NULL THEN
    INSERT INTO visit (ip, app, country, region, city) VALUES (_ip, _app, _country, _region, _city);
    SET @visit_id := LAST_INSERT_ID();
  ELSE
    -- else update visit with new time and bytes
    UPDATE visit SET time = _time, bytes = bytes + _bytes WHERE id = @visit_id;
  END IF;
  -- insert new detail
  INSERT INTO detail (time, bytes, path) VALUES (_time, _bytes, _path);
  SET @detail_id := LAST_INSERT_ID();
  -- insert visit_details
  INSERT INTO visit_details (visit_id, detail_id) VALUES (@visit_id, @detail_id);
END//

CREATE PROCEDURE get_last_15_visits(_search TEXT) BEGIN
  -- if _search is "" then get all visits
  IF _search = "" THEN
    SELECT * FROM visit ORDER BY date DESC LIMIT 15;
  ELSE
    -- get all visits with ip, app, or path containing _search
    SELECT * FROM visit WHERE ip LIKE CONCAT('%', _search, '%') OR app LIKE CONCAT('%', _search, '%') OR country LIKE CONCAT('%', _search, '%') OR region LIKE CONCAT('%', _search, '%') OR city LIKE CONCAT('%', _search, '%') ORDER BY id DESC LIMIT 15;
  END IF;
END//

CREATE PROCEDURE get_visits(_id INTEGER, _search TEXT) BEGIN
  IF _search = "" THEN
    SELECT * FROM visit WHERE id < _id ORDER BY id DESC LIMIT 15;
  ELSE
    SELECT * FROM visit WHERE id < _id AND (ip LIKE CONCAT('%', _search, '%') OR app LIKE CONCAT('%', _search, '%') OR country LIKE CONCAT('%', _search, '%') OR region LIKE CONCAT('%', _search, '%') OR city LIKE CONCAT('%', _search, '%')) ORDER BY id DESC LIMIT 15;
  END IF;
END//

CREATE PROCEDURE get_details(_visit_id INTEGER) BEGIN
  SELECT * FROM detail JOIN visit_details ON visit_details.detail_id = detail.id WHERE visit_details.visit_id = _visit_id ORDER BY detail.id DESC;
END//

DELIMITER ;