create table if not exists world (
  id int primary key,
  randomNumber int
);

create table if not exists fortune (
  id integer primary key,
  message text
);
