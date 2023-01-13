set term ^;

create or alter package xml
as begin

procedure nodes(
    xml          blob sub_type text character set UTF8
  , xpath        varchar(8191)      character set UTF8
)returns(
    number       integer
  , source       blob sub_type text character set UTF8
  , name         varchar(8191)      character set UTF8
  , text         varchar(8191)      character set UTF8
  , is_attribute boolean
);

end^

recreate package body xml
as
begin

procedure nodes(
    xml          blob sub_type text character set UTF8
  , xpath        varchar(8191)      character set UTF8
)returns(
    number       integer
  , source       blob sub_type text character set UTF8
  , name         varchar(8191)      character set UTF8
  , text         varchar(8191)      character set UTF8
  , is_attribute boolean
)
external name
    'fb_xml!nodes'
engine
    udr
;

end^

set term ;^
