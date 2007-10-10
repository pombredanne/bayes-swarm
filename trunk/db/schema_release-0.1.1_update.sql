CREATE
    TABLE languages
    (
        language varchar(100) NOT NULL,
        PRIMARY KEY USING BTREE(language)
    )
    ENGINE=InnoDB;

INSERT INTO languages (language) values ('ita'),('eng');

ALTER TABLE pages ADD COLUMN language varchar(3) NOT NULL;
ALTER TABLE pages ADD constraint fk_page_lang FOREIGN key(language) references languages(language);
UPDATE pages SET language="eng";

ALTER TABLE int_words ADD COLUMN language varchar(3) NOT NULL;
ALTER TABLE int_words ADD constraint fk_int_word_lang FOREIGN key(language) references languages(language);
UPDATE int_words SET language="eng";
