(*
    Unit     : fbxml
    Date     : 2023-01-10
    Compiler : Delphi XE3, Delphi 12
    Author   : Shalamyansky Mikhail Arkadievich
    Contents : Firebird UDR XML support procedure
    Project  : https://github.com/shalamyansky/fb_xml
    Company  : BWR
*)

//DDL definition
(*

create or alter procedure nodes(
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

*)

unit fbxml;

interface

uses
    SysUtils
  , Windows
  , firebird  // https://github.com/shalamyansky/fb_common
  , fbudr     // https://github.com/shalamyansky/fb_common
  , OmniXML
;


type

{ sleep }

TNodesProcedureFactory = class( TBwrProcedureFactory )
  public
    function newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure; override;
end;{ TNodesProcedureFactory }

TNodesProcedure = class( TBwrSelectiveProcedure )
  const
    INPUT_FIELD_XML        = 0;
    INPUT_FIELD_XPATH      = 1;
    OUTPUT_FIELD_NUMBER    = 0;
    OUTPUT_FIELD_SOURCE    = 1;
    OUTPUT_FIELD_NAME      = 2;
    OUTPUT_FIELD_TEXT      = 3;
    OUTPUT_FIELD_ATTRIBUTE = 4;
  public
    function open( AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER ):IExternalResultSet; override;
end;{ TNodesProcedure }

TNodesResultSet = class( TBwrResultSet )
  private
    fDoc    : TXMLDocument;
    fIDoc   : IXMLDocument;
    fNodes  : IXMLNodeList;
    fNumber : LONGINT;
  public
    constructor Create( ASelectiveProcedure:TBwrSelectiveProcedure; AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER ); override;
    destructor Destroy; override;
    function  fetch( AStatus:IStatus ):BOOLEAN; override;
    procedure ReleaseDoc;
end;{ TNodesResultSet }


implementation


{ TNodesProcedureFactory }

function TNodesProcedureFactory.newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure;
begin
    Result := TNodesProcedure.create( AMetadata );
end;{ TNodesProcedureFactory.newItem }

{ TNodesProcedure }

function TNodesProcedure.open( AStatus:IStatus; AContext:IExternalContext; aInMsg:POINTER; aOutMsg:POINTER ):IExternalResultSet;
begin
    inherited open( AStatus, AContext, aInMsg, aOutMsg );
    Result := TNodesResultSet.create( Self, AStatus, AContext, AInMsg, AOutMsg );
end;{ TNodesProcedure.open }

{ TSplitWordsResultSet }

constructor TNodesResultSet.Create( ASelectiveProcedure:TBwrSelectiveProcedure; AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER );
var
    Xml,     XPath     : UnicodeString;
    XmlNull, XPathNull : WORDBOOL;
    XmlOk,   XPathOk   : BOOLEAN;
begin
    inherited Create( ASelectiveProcedure, AStatus, AContext, AInMsg, AOutMsg );
    fNodes  := nil;
    fNumber := 0;
    XmlOk   := RoutineContext.ReadInputString( AStatus, TNodesProcedure.INPUT_FIELD_XML,   Xml,   XmlNull   );
    XPathOk := RoutineContext.ReadInputString( AStatus, TNodesProcedure.INPUT_FIELD_XPATH, XPath, XpathNull );

    fDoc  := nil;
    fDoc  := TXMLDocument.Create;
    fIDoc := nil;
    fIDoc := fDoc as IXMLDocument;
    if( fDoc.LoadXML( Xml ) )then begin
        fNodes := fDoc.SelectNodes( XPath );
    end;
end;{ TNodesResultSet.Create }

destructor TNodesResultSet.Destroy;
begin
    ReleaseDoc;
    inherited Destroy;
end;{ TNodesResultSet.Destroy; }

procedure TNodesResultSet.ReleaseDoc;
begin
    fNodes := nil;
    fIDoc  := nil;
    fDoc   := nil;
end;{ TNodesResultSet.ReleaseDoc }

function TNodesResultSet.fetch( AStatus:IStatus ):BOOLEAN;
var
    Source, Name, Text : UnicodeString;
    IsAttribute : BOOLEAN;
    NumberNull, SourceNull, NameNull, TextNull, IsAttributeNull : WORDBOOL;
    NumberOk,   SourceOk,   NameOk,   TextOk,   IsAttributeOk   : BOOLEAN;
    Node : IXMLNode;
begin
    Result := FALSE;
    NumberNull      := TRUE;
    System.Finalize( Source );
    SourceNull      := TRUE;
    System.Finalize( Name );
    NameNull        := TRUE;
    System.Finalize( Text );
    TextNull        := TRUE;
    IsAttribute     := FALSE;
    IsAttributeNull := TRUE;
    if( ( fNodes <> nil ) and ( fNumber < fNodes.Length ) )then begin
        Node := nil;
        Node := fNodes.Item[ fNumber ];
        if( Node <> nil )then begin
            Source     := Node.XML;
            SourceNull := FALSE;
            Name       := Node.NodeName;
            NameNull   := FALSE;
            if( Node.NodeType          = ATTRIBUTE_NODE )then begin
                Text            := Node.NodeValue;
                TextNull        := FALSE;
                IsAttribute     := TRUE;
                IsAttributeNull := FALSE;
            end else if( Node.NodeType = ELEMENT_NODE )then begin
                Text            := Node.Text;
                TextNull        := FALSE;
                IsAttribute     := FALSE;
                IsAttributeNull := FALSE;
            end;
        end;
        Inc( fNumber );
        NumberNull := FALSE;
        Result     := TRUE;
    end else begin
        Result := FALSE;
        Node   := nil;
        ReleaseDoc;
    end;
    NumberOk      := RoutineContext.WriteOutputLongint( AStatus, TNodesProcedure.OUTPUT_FIELD_NUMBER,    fNumber,     NumberNull      );
    SourceOk      := RoutineContext.WriteOutputString(  AStatus, TNodesProcedure.OUTPUT_FIELD_SOURCE,    Source,      SourceNull      );
    NameOk        := RoutineContext.WriteOutputString(  AStatus, TNodesProcedure.OUTPUT_FIELD_NAME,      Name,        NameNull        );
    TextOk        := RoutineContext.WriteOutputString(  AStatus, TNodesProcedure.OUTPUT_FIELD_TEXT,      Text,        TextNull        );
    IsAttributeOk := RoutineContext.WriteOutputBoolean( AStatus, TNodesProcedure.OUTPUT_FIELD_ATTRIBUTE, IsAttribute, IsAttributeNull );
end;{ TNodesResultSet.fetch }



end.
