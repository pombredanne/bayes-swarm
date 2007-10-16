CREATE
    TABLE types
    (
        type varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(type)
    )    
    ENGINE=InnoDB;

ALTER TABLE pages ADD COLUMN page_type varchar(3) NOT NULL;
ALTER TABLE pages ADD constraint fk_page_type foreign key(page_type) references types(type);
ALTER TABLE pages ADD COLUMN last_scantime DATETIME NOT NULL;
UPDATE pages SET type="url";
