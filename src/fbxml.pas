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
    xml       blob sub_type text character set UTF8
  , xpath     varchar(8191)      character set UTF8
)returns(
    number    integer
  , source    blob sub_type text character set UTF8
  , name      varchar(8191)      character set UTF8
  , text      varchar(8191)      character set UTF8
  , node_type smallint
  , path      varchar(8191)      character set UTF8
)
external name
    'fb_xml!nodes'
engine
    udr
;

// Node types:
//  1 - element node
//  2 - attribute node
//  3 - text node
//  4 - CDATA section node
//  5 - entity reference node
//  6 - entity node
//  7 - processing instruction node
//  8 - comment node
//  9 - document node
// 10 - document type node
// 11 - document fragment node
// 12 - notation node
*)

unit fbxml;

interface

uses
    SysUtils
  , firebird  // https://github.com/shalamyansky/fb_common
  , fbudr     // https://github.com/shalamyansky/fb_common
  , Xml.XMLIntf
  , Xml.XMLDoc
  , Xml.xmldom
  {$IFDEF OMNIXML}
    , Xml.omnixmldom
  {$ELSE}
    , Xml.adomxmldom
  {$ENDIF}
;


type

{ sleep }

TNodesProcedureFactory = class( TBwrProcedureFactory )
  public
    function newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure; override;
end;{ TNodesProcedureFactory }

TNodesProcedure = class( TBwrSelectiveProcedure )
  const
    INPUT_FIELD_XML     = 0;
    INPUT_FIELD_XPATH   = 1;
    OUTPUT_FIELD_NUMBER = 0;
    OUTPUT_FIELD_SOURCE = 1;
    OUTPUT_FIELD_NAME   = 2;
    OUTPUT_FIELD_TEXT   = 3;
    OUTPUT_FIELD_TYPE   = 4;
    OUTPUT_FIELD_PATH   = 5;
  protected
    class function GetBwrResultSetClass:TBwrResultSetClass; override;
end;{ TNodesProcedure }

TNodesResultSet = class( TBwrResultSet )
  private
    fIDoc   : IXMLDocument;
    fNodes  : IDomNodeList;
    fNumber : LONGINT;
  public
    constructor Create( ASelectiveProcedure:TBwrSelectiveProcedure; AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER ); override;
    destructor Destroy; override;
    function  fetch( AStatus:IStatus ):BOOLEAN; override;
    procedure ReleaseDoc;
end;{ TNodesResultSet }


function GetNodeSource( Node:IDOMNodeEx ):UnicodeString;
function GetNodeHomonymNumber( Node:IDOMNode; out Single:BOOLEAN ):LONGINT;
function GetNodeParent( Node:IDOMNode ):IDOMNode;
function GetNodePath( Node:IDOMNode ):UnicodeString;


implementation


{ TNodesProcedureFactory }

function TNodesProcedureFactory.newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure;
begin
    Result := TNodesProcedure.create( AMetadata );
end;{ TNodesProcedureFactory.newItem }

{ TNodesProcedure }

class function TNodesProcedure.GetBwrResultSetClass:TBwrResultSetClass;
begin
    Result := TNodesResultSet;
end;{ TNodesProcedure.GetBwrResultSetClass }


{ TNodesResultSet }

constructor TNodesResultSet.Create( ASelectiveProcedure:TBwrSelectiveProcedure; AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER );
var
    Xml,     XPath     : UnicodeString;
    XmlNull, XPathNull : WORDBOOL;
    XmlOk,   XPathOk   : BOOLEAN;
    DomNodeSelect      : IdomNodeSelect;
begin
    inherited Create( ASelectiveProcedure, AStatus, AContext, AInMsg, AOutMsg );
    fNodes  := nil;
    fIDoc   := nil;
    fNumber := 0;
    XmlOk   := RoutineContext.ReadInputString( AStatus, TNodesProcedure.INPUT_FIELD_XML,   Xml,   XmlNull   );
    XPathOk := RoutineContext.ReadInputString( AStatus, TNodesProcedure.INPUT_FIELD_XPATH, XPath, XpathNull );

    if( Xml <> '' )then begin
        fIDoc := LoadXMLData( Xml );
        if( Supports( fIDoc.DOMDocument, IDomNodeSelect, DomNodeSelect ) )then begin
            fNodes := DomNodeSelect.SelectNodes( XPath );
        end;
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
end;{ TNodesResultSet.ReleaseDoc }

function TNodesResultSet.fetch( AStatus:IStatus ):BOOLEAN;
var
    Source, Name, Text, Path : UnicodeString;
    NodeType                 : SMALLINT;
    NumberNull, SourceNull, NameNull, TextNull, NodeTypeNull, PathNull : WORDBOOL;
    NumberOk,   SourceOk,   NameOk,   TextOk,   NodeTypeOk,   PathOk   : BOOLEAN;
    Node : IDOMNodeEx;
begin
    Result := FALSE;
    NumberNull      := TRUE;
    System.Finalize( Source );
    SourceNull      := TRUE;
    System.Finalize( Name );
    NameNull        := TRUE;
    System.Finalize( Text );
    TextNull        := TRUE;
    NodeType        := 0;
    NodeTypeNull    := TRUE;
    System.Finalize( Path );
    PathNull        := TRUE;
    Node            := nil;
    if( ( fNodes <> nil ) and ( fNumber < fNodes.Length ) )then begin
        Node := GetDOMNodeEx( fNodes.Item[ fNumber ] );
        if( Node <> nil )then begin
            Source       := GetNodeSource( Node );
            SourceNull   := FALSE;
            Name         := Node.NodeName;
            NameNull     := FALSE;
            NodeType     := SMALLINT( Node.NodeType );
            NodeTypeNull := FALSE;
            if( Node.NodeType = ATTRIBUTE_NODE )then begin
                Text     := Node.NodeValue;
                TextNull := FALSE;
            end else begin
                Text     := Node.Text;
                TextNull := FALSE;
            end;
            Path         := GetNodePath( Node );
            PathNull     := FALSE;
        end;
        Inc( fNumber );
        NumberNull := FALSE;
        Result     := TRUE;
    end else begin
        Result := FALSE;
        ReleaseDoc;
    end;
    NumberOk   := RoutineContext.WriteOutputLongint(  AStatus, TNodesProcedure.OUTPUT_FIELD_NUMBER, fNumber,  NumberNull   );
    SourceOk   := RoutineContext.WriteOutputString(   AStatus, TNodesProcedure.OUTPUT_FIELD_SOURCE, Source,   SourceNull   );
    NameOk     := RoutineContext.WriteOutputString(   AStatus, TNodesProcedure.OUTPUT_FIELD_NAME,   Name,     NameNull     );
    TextOk     := RoutineContext.WriteOutputString(   AStatus, TNodesProcedure.OUTPUT_FIELD_TEXT,   Text,     TextNull     );
    NodeTypeOk := RoutineContext.WriteOutputSmallint( AStatus, TNodesProcedure.OUTPUT_FIELD_TYPE,   NodeType, NodeTypeNull );
    PathOk     := RoutineContext.WriteOutputString(   AStatus, TNodesProcedure.OUTPUT_FIELD_PATH,   Path,     PathNull     );
end;{ TNodesResultSet.fetch }

function GetNodeSource( Node:IDOMNodeEx ):UnicodeString;
begin
    System.Finalize( Result );
    if( Node <> nil )then begin
        {$IFDEF OMNIXML}
            Result := Node.XML;
        {$ELSE} //ADOM4
            if( Node.nodeType = ATTRIBUTE_NODE )then begin
                Result := Node.NodeName + '="' + Node.nodeValue + '"';
            end else begin
                Result := Node.XML;
                Delete( Result, 1, 1 ); //clear BOM FFFE
            end;
        {$ENDIF}
        if( Node.nodeType = ELEMENT_NODE )then begin
            Result := Trim( Result );
        end;
    end;
end;{ GetNodeSource }

function GetNodeHomonymNumber( Node:IDOMNode; out Single:BOOLEAN ):LONGINT;
var
    Name : UnicodeString;
    Prev, Next : IDOMNode;
begin
    Result := 0;
    Single := FALSE;
    Prev   := Node;
    while( Prev <> nil )do begin
        if( ( Result = 0 ) or SameStr( Prev.nodeName, Node.nodeName ) )then begin
            Inc( Result );
        end;
        Prev := Prev.previousSibling;
    end;
    if( Result > 1 )then begin
        exit;
    end;

    Single := TRUE;
    Next   := Node.nextSibling;
    while( Next <> nil )do begin
        if( SameStr( Next.nodeName, Node.nodeName ) )then begin
            Single := FALSE;
            break;
        end;
        Next := Next.nextSibling;
    end;
end;{ GetNodeHomonymNumber }

function GetNodeParent( Node:IDOMNode ):IDOMNode;
var
    DOMAttr : IDOMAttr;
begin
    Result := nil;
    if( Node <> nil )then begin
        Result := Node.parentNode;
        if( Result = nil )then begin
            if( Node.nodeType = ATTRIBUTE_NODE )then begin
                if( Supports( Node, IDOMAttr, DOMAttr ) )then begin
                    Result := DOMAttr.ownerElement;
                end;
            end;
        end;
    end;
end;{ GetNodeParent }

function GetNodePath( Node:IDOMNode ):UnicodeString;
var
    Path   : UnicodeString;
    Number : LONGINT;
    Single : BOOLEAN;
begin
    System.Finalize( Result );
    System.Finalize( Path   );
    if( Node = nil )then begin
        ;
    end else if( Node.nodeType = DOCUMENT_NODE )then begin
        ;
    end else if( Node.nodeType = TEXT_NODE )then begin
        Path := 'text()';
    end else if( Node.nodeType = ATTRIBUTE_NODE )then begin
        Path := '@' + Node.nodeName;
    end else begin
        Path   := Node.nodeName;
        Number := GetNodeHomonymNumber( Node, Single );
        if( not Single )then begin
            Path := Path + '[' + IntToStr( Number ) + ']';
        end;
    end;
    if( Path <> '' )then begin
        Result := GetNodePath( GetNodeParent( Node ) ) + '/' + Path;
    end;
end;{ GetNodePath }

procedure InitProc;
begin
    {$IFDEF OMNIXML}
        Xml.xmldom.DefaultDOMVendor := Xml.omnixmldom.sOmniXmlVendor;
    {$ELSE}
        Xml.xmldom.DefaultDOMVendor := Xml.adomxmldom.sAdom4XmlVendor;
    {$ENDIF}
end;{ InitProc }

initialization
begin
    InitProc;
end;{ initialization }

end.
