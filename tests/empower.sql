drop table if exists world;
create table if not exists world (
  id int primary key,
  randomNumber int
);
drop table if exists fortune;
create table if not exists fortune (
  id integer primary key,
  message text
);