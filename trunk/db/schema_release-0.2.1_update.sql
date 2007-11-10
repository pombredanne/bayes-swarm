-- drop usage of internal languages table
-- use globalize_langauges instead

ALTER TABLE pages DROP FOREIGN KEY fk_page_language;
UPDATE pages SET language_id=2600 WHERE language_id=2;
UPDATE pages SET language_id=1819 WHERE language_id=1;
ALTER TABLE pages ADD constraint fk_page_language FOREIGN KEY(language_id) REFERENCES globalize_languages(id);
 
ALTER TABLE intwords DROP FOREIGN KEY fk_int_words_language;
UPDATE intwords SET language_id=2600 WHERE language_id=2;
UPDATE intwords SET language_id=1819 WHERE language_id=1;
ALTER TABLE intwords ADD constraint fk_intword_language FOREIGN KEY(language_id) REFERENCES globalize_languages(id);
 
DROP TABLE languages
