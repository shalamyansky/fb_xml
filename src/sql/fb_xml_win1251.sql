set term ^;

create or alter package xml
as begin

procedure nodes(
    xml          blob sub_type text segment size 16384 character set WIN1251
  , xpath        varchar(32765)                        character set WIN1251
)returns(
    number       integer
  , source       blob sub_type text segment size 16384 character set WIN1251
  , name         varchar(32765)                        character set WIN1251
  , text         varchar(32765)                        character set WIN1251
  , is_attribute boolean
);

function get_node(
    xml   blob sub_type text segment size 16384 character set WIN1251
  , xpath varchar(32765)                        character set WIN1251
)returns  blob sub_type text segment size 16384 character set WIN1251;

function get_value(
    xml   blob sub_type text segment size 16384 character set WIN1251
  , xpath varchar(32765)                        character set WIN1251
)returns  varchar(32765)                        character set WIN1251;

end^

recreate package body xml
as
begin

procedure nodes(
    xml          blob sub_type text segment size 16384 character set WIN1251
  , xpath        varchar(32765)                        character set WIN1251
)returns(
    number       integer
  , source       blob sub_type text segment size 16384 character set WIN1251
  , name         varchar(32765)                        character set WIN1251
  , text         varchar(32765)                        character set WIN1251
  , is_attribute boolean
)
external name
    'fb_xml!nodes'
engine
    udr
;

function get_node(
    xml   blob sub_type text segment size 16384 character set WIN1251
  , xpath varchar(32765)                        character set WIN1251
)returns  blob sub_type text segment size 16384 character set WIN1251
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
    xml   blob sub_type text  segment size 16384 character set WIN1251
  , xpath varchar(32765)                         character set WIN1251
)returns  varchar(32765)                         character set WIN1251
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
