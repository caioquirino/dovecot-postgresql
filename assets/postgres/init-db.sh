#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
CREATE TABLE transport (
  domain VARCHAR(128) NOT NULL,
  transport VARCHAR(128) NOT NULL,
  PRIMARY KEY (domain)
);
CREATE TABLE users (
  userid VARCHAR(128) NOT NULL,
  password VARCHAR(128),
  realname VARCHAR(128),
  uid INTEGER NOT NULL,
  gid INTEGER NOT NULL,
  home VARCHAR(128),
  mail VARCHAR(255),
  PRIMARY KEY (userid)
);
CREATE TABLE virtual (
  address VARCHAR(255) NOT NULL,
  userid VARCHAR(255) NOT NULL,
  PRIMARY KEY (address)
);
create view postfix_mailboxes as
  select userid, home||'/' as mailbox from users
  union all
  select domain as userid, 'dummy' as mailbox from transport;
  create view postfix_virtual as
  select userid, userid as address from users
  union all
  select userid, address from virtual;
EOSQL
