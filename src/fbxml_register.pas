(*
    Unit     : fbxml_register
    Date     : 2023-01-10
    Compiler : Delphi XE3, Delphi 12
    Author   : Shalamyansky Mikhail Arkadievich
    Contents : Register UDR function for fb_xml module
    Project  : https://github.com/shalamyansky/fb_xml
    Company  : BWR
*)
(*
    References and thanks:

    Denis Simonov. Firebird UDR writing in Pascal.
                   2019, IBSurgeon

*)
//DDL definition
(*
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
*)
unit fbxml_register;

interface

uses
    firebird
;

function firebird_udr_plugin( AStatus:IStatus; AUnloadFlagLocal:BooleanPtr; AUdrPlugin:IUdrPlugin ):BooleanPtr; cdecl;


implementation


uses
    fbxml
;

var
    myUnloadFlag    : BOOLEAN;
    theirUnloadFlag : BooleanPtr;

function firebird_udr_plugin( AStatus:IStatus; AUnloadFlagLocal:BooleanPtr; AUdrPlugin:IUdrPlugin ):BooleanPtr; cdecl;
begin
    AUdrPlugin.registerProcedure( AStatus, 'nodes',        fbxml.TXNodesProcedureFactory.Create() );
    AUdrPlugin.registerProcedure( AStatus, 'handle_nodes', fbxml.THNodesProcedureFactory.Create() );

    theirUnloadFlag := AUnloadFlagLocal;
    Result          := @myUnloadFlag;
end;{ firebird_udr_plugin }

procedure InitalizationProc;
begin
    IsMultiThread := TRUE;
    myUnloadFlag  := FALSE;
end;{ InitalizationProc }

procedure FinalizationProc;
begin
    if( ( theirUnloadFlag <> nil ) and ( not myUnloadFlag ) )then begin
        theirUnloadFlag^ := TRUE;
    end;
end;{ FinalizationProc }

initialization
begin
    InitalizationProc;
end;

finalization
begin
    FinalizationProc;
end;

end.
