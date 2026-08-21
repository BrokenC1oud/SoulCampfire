create table player
(
    id integer default 0 not null
        constraint player_pk
            primary key
        constraint player_pk_2
            unique
);

