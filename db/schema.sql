drop table if exists associations ;
drop table if exists words;
drop table if exists pages;
drop table if exists sources;

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
		PRIMARY KEY USING BTREE(id),
		constraint fk_page_source foreign key(source_id) references sources(id)
	)
	ENGINE=InnoDB;
	
CREATE 
	TABLE words
	(
		id int(11) NOT NULL AUTO_INCREMENT,
		page_id int(11) NOT NULL,
		scantime DATETIME NOT NULL,
		name varchar(255) NOT NULL,
		count int(11) NOT NULL DEFAULT 0,
		titlecount int(11) NOT NULL DEFAULT 0,
		weight decimal(6,3) NOT NULL DEFAULT 0.0,
		PRIMARY KEY USING BTREE(id),
		constraint fk_word_page foreign key(page_id) references pages(id)
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