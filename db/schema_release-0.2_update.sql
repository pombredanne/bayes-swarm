use bayesfortest;

ALTER TABLE pages ADD COLUMN type varchar(3) NOT NULL;
ALTER TABLE pages ADD COLUMN last_scantime DATETIME NOT NULL;
UPDATE pages SET type="url";
