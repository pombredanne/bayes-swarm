-- add visible flag to intwords
 
ALTER TABLE intwords ADD column visible TINYINT(1) NOT NULL DEFAULT 0;
UPDATE intwords SET visible = 1;

-- add id column to intwords
alter table words drop foreign key `fk_word_page`;
alter table words drop foreign key `fk_word_intword`;
alter table words drop key `fk_word_page`;
alter table words drop primary key;
alter table words add column id int not null auto_increment first, add primary key (id);
alter table words add constraint fk_word_intword foreign key(intword_id) references intwords(id);
alter table words add constraint fk_word_page foreign key(page_id) references pages(id);

-- add users table

create
    table users (
        id int NOT NULL AUTO_INCREMENT,
        name varchar(100),
        fullname varchar(100),
        email varchar(100),
        hashed_password char(40),
        primary key (id)
    );
