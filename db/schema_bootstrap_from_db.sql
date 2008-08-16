# bootstrap a new db from a previous one

insert into pulsar.globalize_languages select * from bayesswarm022.globalize_languages;
insert into pulsar.globalize_countries select * from bayesswarm022.globalize_countries;
insert into pulsar.globalize_translations select * from bayesswarm022.globalize_translations;

insert into pulsar.kinds select * from bayesswarm022.kinds;

insert into pulsar.sources (id, name, created_at) select id, name, "2008-08-14 15.41" from bayesswarm022.sources;
insert into pulsar.pages (id, source_id, url, last_scantime, kind_id, language_id, created_at) select id, source_id, url, NULL, kind_id, language_id, "2008-08-14 15.41" from bayesswarm022.pages;

GRANT ALL ON pulsar.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
