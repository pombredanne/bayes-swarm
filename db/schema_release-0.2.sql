drop view if exists extended_words; 
drop table if exists associations;
drop table if exists words;
drop table if exists int_words;
drop table if exists pages;
drop table if exists sources;
drop table if exists languages;
drop table if exists kinds;

CREATE
    TABLE languages
    (
		id int(11) NOT NULL AUTO_INCREMENT,
        language varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id)
    )
    ENGINE=InnoDB;

INSERT INTO languages (id,language) values (1,'ita'),(2,'eng');


CREATE
    TABLE kinds
    (
		id int(11) NOT NULL AUTO_INCREMENT,
        kind varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id)
    )    
    ENGINE=InnoDB;

INSERT INTO kinds (id,kind) values (1,'url'),(2,'rss');


CREATE
    TABLE sources
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        name varchar(100) NOT NULL,
        PRIMARY KEY USING BTREE(id)
    )
    ENGINE=InnoDB;


CREATE
    TABLE pages
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        source_id int(11) NOT NULL,
        url varchar(255) NOT NULL,
        language_id int(11) NOT NULL,
        kind_id int(11) NOT NULL,
        last_scantime DATETIME NOT NULL,
        PRIMARY KEY USING BTREE(id),
        constraint fk_page_source foreign key(source_id) references sources(id),
        constraint fk_page_lang FOREIGN key(language_id) references languages(id),
        constraint fk_page_kind foreign key(kind_id) references kinds(id)
    )
    ENGINE=InnoDB;


--CREATE
--    TABLE articles
--    (
--        id int(11) NOT NULL AUTO_INCREMENT,
--        page_id int(11) NOT NULL,
--        url varchar(255) NOT NULL,
--        publish_time DATETIME NOT NULL,
--        PRIMARY KEY USING BTREE(id),
--        constraint fk_article_page foreign key(page_id) references pages(id),
--    )
--    ENGINE=InnoDB;


CREATE
    TABLE int_words
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        name varchar(255) NOT NULL,
        language_id int(11) NOT NULL,
        PRIMARY KEY USING BTREE(id),
        constraint fk_int_word_lang FOREIGN key(language_id) references languages(id)
    )
    ENGINE=InnoDB;


CREATE
    TABLE words
    (
        id int(11) NOT NULL,
        page_id int(11) NOT NULL,
        scantime DATETIME NOT NULL,
        count int(11) NOT NULL DEFAULT 0,
        titlecount int(11) NOT NULL DEFAULT 0,
        weight decimal(6,3) NOT NULL DEFAULT 0.0,
        PRIMARY KEY USING BTREE(id, page_id, scantime),
        constraint fk_word_intword foreign key(id) references int_words(id),
        constraint fk_word_page foreign key(page_id) references pages(id)
    )
    ENGINE=InnoDB;

CREATE
	VIEW extended_words AS
	SELECT w.* , iw.name , iw.language_id
	FROM words w , int_words iw
	WHERE w.id = iw.id ;

CREATE
    TABLE associations
    (
        words_from_id int(11) NOT NULL,
        words_to_id int(11) NOT NULL,
        cdist1 int(11) NOT NULL DEFAULT 0,
        cdist2 int(11) NOT NULL DEFAULT 0,
        cdist3 int(11) NOT NULL DEFAULT 0,
        cdist4 int(11) NOT NULL DEFAULT 0,
        cdist5 int(11) NOT NULL DEFAULT 0,
        weight decimal(6,3) NOT NULL DEFAULT 0.0,
        PRIMARY KEY USING BTREE(words_from_id, words_to_id),
        constraint fk_assoc_from_word foreign key(words_from_id) references words(id),
        constraint fK_assoc_to_word foreign key(words_to_id) references words(id)
    )
    ENGINE=InnoDB;
    





    

