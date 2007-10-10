CREATE
    TABLE types
    (
        type varchar(3) NOT NULL,
        PRIMARY KEY USING BTREE(type)
    )    
    ENGINE=InnoDB;

ALTER TABLE pages ADD COLUMN type varchar(3) NOT NULL;
ALTER TABLE pages ADD constraint fk_page_type foreign key(type) references types(type);
ALTER TABLE pages ADD COLUMN last_scantime DATETIME NOT NULL;
UPDATE pages SET type="url";
