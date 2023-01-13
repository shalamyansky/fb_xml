set term ^;

create or alter package xml
as begin

procedure nodes(
    xml          blob sub_type text character set WIN1251
  , xpath        varchar(32765)      character set WIN1251
)returns(
    number       integer
  , source       blob sub_type text character set WIN1251
  , name         varchar(32765)      character set WIN1251
  , text         varchar(32765)      character set WIN1251
  , is_attribute boolean
);

end^

recreate package body xml
as
begin

procedure nodes(
    xml          blob sub_type text character set WIN1251
  , xpath        varchar(32765)      character set WIN1251
)returns(
    number       integer
  , source       blob sub_type text character set WIN1251
  , name         varchar(32765)      character set WIN1251
  , text         varchar(32765)      character set WIN1251
  , is_attribute boolean
)
external name
    'fb_xml!nodes'
engine
    udr
;

end^

set term ;^
