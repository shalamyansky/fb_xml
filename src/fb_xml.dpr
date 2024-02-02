(*
    Unit     : fb_xml
    Date     : 2023-01-10
    Compiler : Delphi XE3, Delphi 12
    Author   : Shalamyansky Mikhail Arkadievich
    Contents : Firebird UDR XML support procedure plugin module
    Project  : https://github.com/shalamyansky/fb_xml
    Company  : BWR
*)

{$DEFINE NO_FBCLIENT}
{Define NO_FBCLIENT in your .dproj file to take effect on firebird.pas}

{Undefine KYLIX in OmniXML_JEDI.inc for Linux platform building}


library fb_xml;

uses
  {$IFDEF FastMM}
    {$DEFINE ClearLogFileOnStartup}
    {$DEFINE EnableMemoryLeakReporting}
    FastMM5,
  {$ENDIF}
  fbxml_register
;

{$R *.res}

exports
    firebird_udr_plugin
;

begin
end.
