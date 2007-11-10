CREATE
    TABLE kinds
    (
		id int(11) NOT NULL AUTO_INCREMENT,
        kind varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id)
    )    
    ENGINE=InnoDB;

INSERT INTO kinds (id,kind) values (1,'url'),(2,'rss');

ALTER TABLE pages ADD COLUMN kind_id int(11) NOT NULL;
ALTER TABLE pages ADD constraint fk_page_kind foreign key(kind_id) references kinds(id);
ALTER TABLE pages ADD COLUMN last_scantime DATETIME NOT NULL;
UPDATE pages SET kind_id = 1;

CREATE
	VIEW extended_words AS
	SELECT w.* , iw.name , iw.language_id
	FROM words w , int_words iw
	WHERE w.id = iw.id ;