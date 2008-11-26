-- Follow the SQL instructions in this file to bootstrap a new, empty database
-- from the contents of an existing one.
-- 
-- Use schema_latest.sql to create the empty schema first.
--
-- Replace $SOURCE_SCHEMA and $TARGET_SCHEMA respectively with the source and target schemata.

insert into $TARGET_SCHEMA.globalize_languages select * from $SOURCE_SCHEMA.globalize_languages;
insert into $TARGET_SCHEMA.globalize_countries select * from $SOURCE_SCHEMA.globalize_countries;
insert into $TARGET_SCHEMA.globalize_translations select * from $SOURCE_SCHEMA.globalize_translations;

insert into $TARGET_SCHEMA.kinds select * from $SOURCE_SCHEMA.kinds;

insert into $TARGET_SCHEMA.sources (id, name, created_at) select id, name, now() from $SOURCE_SCHEMA.sources;
insert into $TARGET_SCHEMA.pages (id, source_id, url, last_scantime, kind_id, language_id, created_at) select id, source_id, url, NULL, kind_id, language_id, now() from $SOURCE_SCHEMA.pages;

-- comment the following line if you don't want to migrate the intwords set
insert into $TARGET_SCHEMA.intwords (id, name, language_id, visible) select id, name, language_id, visible from $SOURCE_SCHEMA.intwords;


GRANT ALL ON $TARGET_SCHEMA.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
