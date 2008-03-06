-- add visible flag to intwords
 
ALTER TABLE intwords ADD column visible TINYINT(1) NOT NULL DEFAULT 0;
UPDATE intwords SET visible = 1;

create
    table users (
        id int NOT NULL AUTO_INCREMENT,
        name varchar(100),
        fullname varchar(100),
        email varchar(100),
        hashed_password char(40),
        primary key (id)
    );
