-- add visible flag to intwords
 
ALTER TABLE intwords ADD column visible TINYINT(1) NOT NULL DEFAULT 0;
UPDATE intwords SET visible = 1;
