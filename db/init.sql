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

CREATE VIEW ips_by_total_visits AS
  SELECT row_number() OVER (ORDER BY results.total_visits ASC) AS id, results.ip, results.total_visits, results.country, results.region, results.city FROM
    (SELECT DISTINCT ip_visits.ip, ip_visits.total_visits, visit.country, visit.region, visit.city FROM
      (SELECT ip, COUNT(*) AS total_visits FROM visit GROUP BY ip) AS ip_visits
    JOIN visit ON visit.ip = ip_visits.ip
    ORDER BY total_visits DESC) AS results;

-- CREATE VIEW ips_by_total_visits AS
--   SELECT DISTINCT ip_visits.ip, ip_visits.total_visits, visit.country, visit.region, visit.city FROM
--     (SELECT ip, COUNT(*) AS total_visits FROM visit GROUP BY ip) AS ip_visits
--   JOIN visit ON visit.ip = ip_visits.ip;

DELIMITER //

CREATE PROCEDURE insert_visit(_ip TEXT, _app TEXT, _country TEXT, _region TEXT, _city TEXT, _time TEXT, _bytes INTEGER, _path TEXT) BEGIN
  -- get id of visit with same values created in past hour
  SET @visit_id := (SELECT id FROM visit WHERE ip = _ip AND app = _app AND date > DATE_SUB(NOW(), INTERVAL 1 HOUR) ORDER BY id DESC LIMIT 1);
  -- if visit_id doesn't exist then insert new visit
  IF @visit_id IS NULL THEN
    INSERT INTO visit (ip, app, country, region, city) VALUES (_ip, _app, _country, _region, _city);
    SET @visit_id := LAST_INSERT_ID();
  END IF;
  -- update visit by setting time to max of time and _time, date to current time stamp and bytes to bytes + _bytes
  UPDATE visit SET time = IF(time > _time, time, _time), date = NOW(), bytes = bytes + _bytes WHERE id = @visit_id;
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

CREATE PROCEDURE get_ips_by_total_visits(_order_direction TEXT, _continue_id INTEGER) BEGIN
  -- if order direction is ASC then order by ASC
  IF _order_direction = "ASC" THEN
    -- if continue id is 0 then get all ips
    IF _continue_id = 0 THEN
      SELECT * FROM ips_by_total_visits ORDER BY id ASC LIMIT 15;
    ELSE
      -- get all ips with id greater than continue id
      SELECT * FROM ips_by_total_visits WHERE id < _continue_id ORDER BY id ASC LIMIT 15;
    END IF;
  ELSE
    -- if order direction is DESC then order by DESC
    -- if continue id is 0 then get all ips
    IF _continue_id = 0 THEN
      SELECT * FROM ips_by_total_visits ORDER BY id DESC LIMIT 15;
    ELSE
      -- get all ips with id greater than continue id
      SELECT * FROM ips_by_total_visits WHERE id < _continue_id ORDER BY id DESC LIMIT 15;
    END IF;
  END IF;
END//

DELIMITER ;