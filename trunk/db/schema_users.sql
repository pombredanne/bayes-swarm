# contains users
# useful for keeping track of who can access the db

GRANT ALL ON bayesswarm02.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
GRANT SELECT ON bayesswarm02.* TO 'webuser'@'localhost' IDENTIFIED BY 'test';
GRANT INSERT ON bayesswarm02.int_words TO 'webuser'@'localhost' IDENTIFIED BY 'test';
