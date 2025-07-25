set term ^ ;

create or alter package xml
as
begin

-- nodes

procedure nodes(
    xml       blob sub_type text  character set utf8
  , xpath     varchar(32765)      character set utf8
)returns(
    number    integer
  , source    blob sub_type text  character set utf8
  , name      varchar(32765)      character set utf8
  , text      varchar(32765)      character set utf8
  , node_type smallint
  , path      varchar(32765)      character set utf8
  , root      bigint
  , node      bigint
);

function get_node(
    xml   blob sub_type text      character set utf8
  , xpath varchar(32765)          character set utf8
)returns  blob sub_type text      character set utf8;

function get_value(
    xml   blob sub_type text      character set utf8
  , xpath varchar(32765)          character set utf8
)returns  varchar(32765)          character set utf8;

function get_name(
    xml   blob sub_type text      character set utf8
  , xpath varchar(32765)          character set utf8
)returns  varchar(32765)          character set utf8;


-- handle_nodes

procedure handle_nodes(
    handle    bigint
  , xpath     varchar(32765)      character set utf8
)returns(
    number    integer
  , source    blob sub_type text  character set utf8
  , name      varchar(32765)      character set utf8
  , text      varchar(32765)      character set utf8
  , node_type smallint
  , path      varchar(32765)      character set utf8
  , root      bigint
  , node      bigint
);

function handle_get_node(
    handle bigint                 
  , xpath  varchar(32765)         character set utf8
)returns   blob sub_type text     character set utf8;

function handle_get_value(
    handle bigint
  , xpath  varchar(32765)         character set utf8
)returns   varchar(32765)         character set utf8;

function handle_get_name(
    handle bigint
  , xpath  varchar(32765)         character set utf8
)returns   varchar(32765)         character set utf8;


end^

recreate package body xml
as
begin

-- nodes

procedure nodes(
    xml       blob sub_type text  character set utf8
  , xpath     varchar(32765)      character set utf8
)returns(
    number    integer
  , source    blob sub_type text  character set utf8
  , name      varchar(32765)      character set utf8
  , text      varchar(32765)      character set utf8
  , node_type smallint
  , path      varchar(32765)      character set utf8
  , root      bigint
  , node      bigint
)
external name
    'fb_xml!nodes'
engine
    udr
;

function get_node(
    xml   blob sub_type text      character set utf8
  , xpath varchar(32765)          character set utf8
)returns  blob sub_type text      character set utf8
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
    xml   blob sub_type text      character set utf8
  , xpath varchar(32765)          character set utf8
)returns  varchar(32765)          character set utf8
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

function get_name(
    xml   blob sub_type text      character set utf8
  , xpath varchar(32765)          character set utf8
)returns  varchar(32765)          character set utf8
as
begin
    return (
      select
        first 1
          name
        from
          nodes( :xml, :xpath )
    );
end

-- handle_nodes

procedure handle_nodes(
    handle    bigint
  , xpath     varchar(32765)      character set utf8
)returns(
    number    integer
  , source    blob sub_type text  character set utf8
  , name      varchar(32765)      character set utf8
  , text      varchar(32765)      character set utf8
  , node_type smallint           
  , path      varchar(32765)      character set utf8
  , root      bigint
  , node      bigint
)
external name
    'fb_xml!handle_nodes'
engine
    udr
;

function handle_get_node(
    handle bigint
  , xpath  varchar(32765)         character set utf8
)returns   blob sub_type text     character set utf8
as
begin
    return (
      select
        first 1
          source
        from
          handle_nodes( :handle, :xpath )
    );
end

function handle_get_value(
    handle bigint
  , xpath  varchar(32765)         character set utf8
)returns   varchar(32765)         character set utf8
as
begin
    return (
      select
        first 1
          text
        from
          handle_nodes( :handle, :xpath )
    );
end

function handle_get_name(
    handle bigint
  , xpath  varchar(32765)         character set utf8
)returns   varchar(32765)         character set utf8
as
begin
    return (
      select
        first 1
          name
        from
          handle_nodes( :handle, :xpath )
    );
end


end^

set term ; ^

