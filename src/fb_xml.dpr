(*
    Unit     : fb_xml
    Date     : 2023-01-10
    Compiler : Delphi XE3
    Author   : Shalamyansky Mikhail Arkadievich
    Contents : Firebird UDR XML support procedure plugin module
    Project  : https://github.com/shalamyansky/fb_xml
    Company  : BWR
*)
library fb_xml;

uses
    fbxml_register
;

{$R *.res}

exports
    firebird_udr_plugin
;

begin
end.
