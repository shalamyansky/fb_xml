set term ^;

create or alter package xml
as begin

procedure nodes(
    xml          blob sub_type text segment size 16384 character set UTF8
  , xpath        varchar(8191)                         character set UTF8
)returns(
    number       integer
  , source       blob sub_type text segment size 16384 character set UTF8
  , name         varchar(8191)                         character set UTF8
  , text         varchar(8191)                         character set UTF8
  , is_attribute boolean
);

function get_node(
    xml   blob sub_type text segment size 16384 character set UTF8
  , xpath varchar(8191)                         character set UTF8
)returns  blob sub_type text segment size 16384 character set UTF8;

function get_value(
    xml   blob sub_type text segment size 16384 character set UTF8
  , xpath varchar(8191)                         character set UTF8
)returns  varchar(8191)                         character set UTF8;

end^

recreate package body xml
as
begin

procedure nodes(
    xml          blob sub_type text segment size 16384 character set UTF8
  , xpath        varchar(8191)                         character set UTF8
)returns(
    number       integer
  , source       blob sub_type text segment size 16384 character set UTF8
  , name         varchar(8191)                         character set UTF8
  , text         varchar(8191)                         character set UTF8
  , is_attribute boolean
)
external name
    'fb_xml!nodes'
engine
    udr
;

function get_node(
    xml   blob sub_type text segment size 16384 character set UTF8
  , xpath varchar(8191)                         character set UTF8
)returns  blob sub_type text segment size 16384 character set UTF8
as
begin
    return (
      select
        first 1
          source
        from
          nodes( :xml, :xpath )
    );
end

function get_value(
    xml   blob sub_type text segment size 16384 character set UTF8
  , xpath varchar(8191)                         character set UTF8
)returns  varchar(8191)                         character set UTF8
as
begin
    return (
      select
        first 1
          text
        from
          nodes( :xml, :xpath )
    );
end

end^

set term ;^
