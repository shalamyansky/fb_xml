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
(*
Define NO_FBCLIENT in your .dproj file to take effect on firebird.pas
*)
(*
ADOM4 DOM Vendor is used by default.
Define OMNIXML in your .dproj file to use OmniXML DOM Vendor.
ADOM4 supports XPath better but OmniXML is faster.
*)

(* Changes:
2024-05-29 ver. 2.1.0.0
 - Returns node_type insteed of is_attribute;
 - Returns full path from xml root to the found node;
 - DOM Vendor bundled with Delphi is used, and there are alternative options:
     a) ADOM4
     b) OmniXML.
*)


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
