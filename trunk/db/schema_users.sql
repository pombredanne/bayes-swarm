# contains users
# useful for keeping track of who can access the db

GRANT ALL ON bayesswarmdev.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
GRANT SELECT ON bayesswarmdev.* TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT ON bayesswarmdev.intwords TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT, UPDATE ON bayesswarmdev.globalize_translations TO 'webuser'@'localhost' IDENTIFIED BY 'test';
