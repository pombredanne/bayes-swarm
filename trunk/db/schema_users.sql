# contains users
# useful for keeping track of who can access the db

GRANT ALL ON bayesswarm022.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
GRANT SELECT ON bayesswarm022.* TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT ON bayesswarm022.intwords TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT, UPDATE ON bayesswarm022.globalize_translations TO 'webuser'@'localhost' IDENTIFIED BY 'test';
