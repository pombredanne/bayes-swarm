drop database if exists bayesfortest ;

create database bayesfortest ;
GRANT ALL ON bayesfortest.* TO 'testuser'@'localhost' IDENTIFIED BY 'test' ;
GRANT SELECT, INSERT ON bayesfortest.* TO 'webuser'@'localhost' IDENTIFIED BY 'test' ;
    
use bayesfortest ; 

CREATE
	TABLE languages
	(
	language varchar(100) NOT NULL,
	PRIMARY KEY USING BTREE(language)
	)	
	ENGINE=InnoDB;

INSERT INTO languages (language) values ('ita'),('eng');


CREATE
    TABLE sources
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        name varchar(100) NOT NULL,
	    language varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id),
	    constraint fk_source_lang   FOREIGN key(language)  references languages(language)
    )
    ENGINE=InnoDB;



CREATE
    TABLE pages
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        source_id int(11) NOT NULL,
        url varchar(255) NOT NULL,
	language varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id),
        constraint fk_page_source foreign key(source_id) references sources(id),
        constraint fk_page_lang   FOREIGN key(language)  references sources(language)
    )
    ENGINE=InnoDB;




CREATE
    TABLE articles
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        page_id int(11) NOT NULL,
        url varchar(255) NOT NULL,
	     language varchar(3) NOT NULL,
        flg_visited int(1) NOT NULL,
        PRIMARY KEY USING BTREE(id),
        constraint fk_article_page foreign key(page_id) references pages(id),
          constraint fk_article_lang   FOREIGN key(language)  references pages(language)
    )
    ENGINE=InnoDB;


CREATE
    TABLE int_words
    (
        id int(11) NOT NULL AUTO_INCREMENT,
        name varchar(255) NOT NULL,
	    language varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id),
	    constraint fk_int_word_lang FOREIGN key(language) references languages(language)
    )
    ENGINE=InnoDB;


CREATE
    TABLE words
    (
        id int(11) NOT NULL,
        article_id int(11) NOT NULL,
        scantime DATETIME NOT NULL,
        count int(11) NOT NULL DEFAULT 0,
        titlecount int(11) NOT NULL DEFAULT 0,
        weight decimal(6,3) NOT NULL DEFAULT 0.0,
        language varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(id, article_id, scantime),
        constraint fk_word_intword foreign key(id) references int_words(id),
        constraint fk_word_article foreign key(article_id) references articles(id),
        constraint fk_word_lang FOREIGN key(language) references articles(language)
    )
    ENGINE=InnoDB;


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


INSERT INTO int_words (name,language) values ('cina','ita'),('india','ita'),('iraq','ita'),('terror','ita'),
    ('mussulm','ita'),('islam','ita'),('bomb','ita'),('bush','ita'),('you-tube','ita'),('italy','ita'),('porn','ita') ;

	





	

