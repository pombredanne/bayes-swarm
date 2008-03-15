-- add id column to intwords
alter table words drop foreign key `fk_word_page`;
alter table words drop foreign key `fk_word_intword`;
alter table words drop key `fk_word_page`;
alter table words drop primary key;
alter table words add column id int not null auto_increment first, add primary key (id);
alter table words add constraint fk_word_intword foreign key(intword_id) references intwords(id);
alter table words add constraint fk_word_page foreign key(page_id) references pages(id);

-- add created_at in sources, pages
delete from sources where id=28;
delete from pages where id=48;
delete from sources where id=23;
alter table sources add column created_at DATETIME NOT NULL;
update sources, (select s.id, min(scantime) as scantime from pages p, sources s, words w where p.source_id=s.id and w.page_id=p.id group by s.id) as updated_sources set sources.created_at = updated_sources.scantime where sources.id=updated_sources.id;

alter table pages add column created_at DATETIME NOT NULL;
update pages, (select p.id, min(scantime) as scantime 
               from pages p, words w 
               where w.page_id=p.id 
               group by p.id) as updated_pages
set pages.created_at = updated_pages.scantime 
where pages.id=updated_pages.id;
update pages set created_at = "2007-09-25 11:52:51" where id=70;

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
