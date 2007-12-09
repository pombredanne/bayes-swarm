# contains users
# useful for keeping track of who can access the db

GRANT ALL ON bayesswarm021.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
GRANT SELECT ON bayesswarm021.* TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT ON bayesswarm021.intwords TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT, UPDATE ON bayesswarm021.globalize_translations TO 'webuser'@'localhost' IDENTIFIED BY 'test';
