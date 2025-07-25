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
  , root      bigint
  , node      bigint
)
external name
    'fb_xml!nodes'
engine
    udr
;

create or alter procedure $nodes(
    $xml      bigint
  , xpath     varchar(8191)      character set UTF8
)returns(
    number    integer
  , source    blob sub_type text character set UTF8
  , name      varchar(8191)      character set UTF8
  , text      varchar(8191)      character set UTF8
  , node_type smallint
  , path      varchar(8191)      character set UTF8
  , root      bigint
  , node      bigint
)
external name
    'fb_xml!$nodes'
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

{$IFNDEF MSWINDOWS}
    {$UNDEF MSXML}
{$ENDIF}
// ADOM DOM Vendor as default
{$IF ( not Defined(MSXML) ) and ( not Defined(OMNIXML) )}
    {$DEFINE ADOMXML}
{$IFEND}

unit fbxml;

interface

uses
    SysUtils
  , firebird  // https://github.com/shalamyansky/fb_common
  , fbudr     // https://github.com/shalamyansky/fb_common
  , Xml.XMLIntf
  , Xml.XMLDoc
  , Xml.xmldom
  //Choose DOM Vendor                                                                                         3
  {$IF     Defined( MSXML   )}
    , Winapi.ActiveX
    , Xml.Win.msxmldom
  {$ELSEIF Defined( OMNIXML )}
    , Xml.omnixmldom
  {$ELSEIF Defined( ADOMXML )}
    , Xml.adomxmldom
  {$IFEND}
;


type

{ TBaseNodesProcedure }

TBaseNodesProcedure = class( TBwrSelectiveProcedure )
  const
    INPUT_FIELD_XPATH   = 1;
    OUTPUT_FIELD_NUMBER = 0;
    OUTPUT_FIELD_SOURCE = 1;
    OUTPUT_FIELD_NAME   = 2;
    OUTPUT_FIELD_TEXT   = 3;
    OUTPUT_FIELD_TYPE   = 4;
    OUTPUT_FIELD_PATH   = 5;
    OUTPUT_FIELD_ROOT   = 6;
    OUTPUT_FIELD_NODE   = 7;
  protected
    class function GetBwrResultSetClass:TBwrResultSetClass; override;
end;{ TBaseNodesProcedure }

TBaseNodesResultSet = class( TBwrResultSet )
  private
    fRoot   : IDOMNodeEx;
    fNodes  : IDOMNodeList;
    fNode   : IDOMNodeEx;
    fNumber : LONGINT;
  protected
    procedure SetRoot( AStatus:IStatus ); virtual;
  public
    constructor Create( ASelectiveProcedure:TBwrSelectiveProcedure; AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER ); override;
    destructor  Destroy; override;
    function    fetch( AStatus:IStatus ):BOOLEAN; override;
end;{ TBaseNodesResultSet }


{ THNodesProcedure }

THNodesProcedureFactory = class( TBwrProcedureFactory )
  public
    function newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure; override;
end;{ TNodesProcedureFactory }

THNodesProcedure = class( TBaseNodesProcedure )
  const
    INPUT_FIELD_NODE = 0;
  protected
    class function GetBwrResultSetClass:TBwrResultSetClass; override;
end;{ THNodesProcedure }

THNodesResultSet = class( TBaseNodesResultSet )
  protected
    procedure SetRoot( AStatus:IStatus ); override;
end;{ THNodesResultSet }



{ TXNodesProcedure }

TXNodesProcedureFactory = class( TBwrProcedureFactory )
  public
    function newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure; override;
end;{ TXNodesProcedureFactory }

TXNodesProcedure = class( TBaseNodesProcedure )
  const
    INPUT_FIELD_XML = 0;
  protected
    class function GetBwrResultSetClass:TBwrResultSetClass; override;
end;{ TXNodesProcedure }

TXNodesResultSet = class( TBaseNodesResultSet )
  private
    fDoc : IXMLDocument;
  protected
    procedure SetRoot( AStatus:IStatus ); override;
  public
    destructor Destroy; override;
end;{ TXNodesResultSet }


function GetNodeSource( Node:IDOMNodeEx ):UnicodeString;
function GetNodeHomonymNumber( Node:IDOMNode; out Single:BOOLEAN ):LONGINT;
function GetNodeParent( Node:IDOMNode ):IDOMNode;
function GetNodePath( Node:IDOMNode ):UnicodeString;


implementation


{ TBaseNodesProcedure }

class function TBaseNodesProcedure.GetBwrResultSetClass:TBwrResultSetClass;
begin
    Result := TBaseNodesResultSet;
end;{ TBaseNodesProcedure.GetBwrResultSetClass }

{ TBaseNodesResultSet }

procedure TBaseNodesResultSet.SetRoot( AStatus:IStatus );
begin
    fRoot := nil;
end;{ TBaseNodesResultSet.SetRoot }

constructor TBaseNodesResultSet.Create( ASelectiveProcedure:TBwrSelectiveProcedure; AStatus:IStatus; AContext:IExternalContext; AInMsg:POINTER; AOutMsg:POINTER );
var
    Xml,     XPath     : UnicodeString;
    XmlNull, XPathNull : WORDBOOL;
    XmlOk,   XPathOk   : BOOLEAN;
    DomNodeSelect      : IDomNodeSelect;
begin
    inherited Create( ASelectiveProcedure, AStatus, AContext, AInMsg, AOutMsg );
    fNodes  := nil;
    fRoot   := nil;
    fNumber := 0;
    SetRoot( AStatus );
    XPathOk  := RoutineContext.ReadInputString( AStatus, TBaseNodesProcedure.INPUT_FIELD_XPATH, XPath, XPathNull );
    if( XPathOk and Supports( fRoot, IDomNodeSelect, DomNodeSelect ) )then begin
        fNodes := DomNodeSelect.SelectNodes( XPath );
    end;
//    XmlOk    := RoutineContext.ReadInputString( AStatus, TNodesProcedure.INPUT_FIELD_XML,   Xml,   XmlNull   );
//    XPathOk  := RoutineContext.ReadInputString( AStatus, TNodesProcedure.INPUT_FIELD_XPATH, XPath, XpathNull );
//
//    if( Xml <> '' )then begin
//
//        fDoc := LoadXMLData( Xml );
//        if( fDoc <> nil )then begin
//            XmlDocOptions := fDoc.Options;
//            Exclude( XmlDocOptions, doNamespaceDecl );
//            fDoc.Options := XmlDocOptions;
//
//            fRoot := GetDOMNodeEx( fDoc.DOMDocument );
//            if( Supports( fRoot, IDomNodeSelect, DomNodeSelect ) )then begin
//                fNodes := DomNodeSelect.SelectNodes( XPath );
//            end;
//        end;
//    end;
end;{ TBaseNodesResultSet.Create }

destructor TBaseNodesResultSet.Destroy;
begin
    inherited Destroy;
    fNode  := nil;
    fNodes := nil;
    fRoot  := nil;
end;{ TBaseNodesResultSet.Destroy; }

function TBaseNodesResultSet.fetch( AStatus:IStatus ):BOOLEAN;
var
    Source, Name, Text, Path : UnicodeString;
    NodeType                 : SMALLINT;
    NumberNull, SourceNull, NameNull, TextNull, NodeTypeNull, PathNull, RootNull, NodeNull : WORDBOOL;
    NumberOk,   SourceOk,   NameOk,   TextOk,   NodeTypeOk,   PathOk,   RootOk,   NodeOk   : BOOLEAN;
    Root, Node : INT64;
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
    Root            := 0;
    RootNull        := TRUE;
    fNode           := nil;
    Node            := 0;
    NodeNull        := TRUE;
    if( ( fNodes <> nil ) and ( fNumber < fNodes.Length ) )then begin
        fNode := GetDOMNodeEx( fNodes.Item[ fNumber ] );
        if( fNode <> nil )then begin
            Source       := GetNodeSource( fNode );
            SourceNull   := FALSE;
            Name         := fNode.NodeName;
            NameNull     := FALSE;
            NodeType     := SMALLINT( fNode.NodeType );
            NodeTypeNull := FALSE;
            if( fNode.NodeType = ATTRIBUTE_NODE )then begin
                Text     := fNode.NodeValue;
                TextNull := FALSE;
            end else begin
                Text     := fNode.Text;
                TextNull := FALSE;
            end;
            Path         := GetNodePath( fNode );
            PathNull     := FALSE;
        end;
        Inc( fNumber );
        NumberNull := FALSE;
        RootNull   := ( fRoot = nil );
        Root       := INT64( POINTER( fRoot ) );
        NodeNull   := ( fNode = nil );
        Node       := INT64( POINTER( fNode ) );

        Result     := TRUE;

    end else begin

        Result     := FALSE;

    end;
    NumberOk   := RoutineContext.WriteOutputLongint(  AStatus, TBaseNodesProcedure.OUTPUT_FIELD_NUMBER, fNumber,  NumberNull   );
    SourceOk   := RoutineContext.WriteOutputString(   AStatus, TBaseNodesProcedure.OUTPUT_FIELD_SOURCE, Source,   SourceNull   );
    NameOk     := RoutineContext.WriteOutputString(   AStatus, TBaseNodesProcedure.OUTPUT_FIELD_NAME,   Name,     NameNull     );
    TextOk     := RoutineContext.WriteOutputString(   AStatus, TBaseNodesProcedure.OUTPUT_FIELD_TEXT,   Text,     TextNull     );
    NodeTypeOk := RoutineContext.WriteOutputSmallint( AStatus, TBaseNodesProcedure.OUTPUT_FIELD_TYPE,   NodeType, NodeTypeNull );
    PathOk     := RoutineContext.WriteOutputString(   AStatus, TBaseNodesProcedure.OUTPUT_FIELD_PATH,   Path,     PathNull     );
    RootOk     := RoutineContext.WriteOutputBigint(   AStatus, TBaseNodesProcedure.OUTPUT_FIELD_ROOT,   Root,     RootNull     );
    NodeOk     := RoutineContext.WriteOutputBigint(   AStatus, TBaseNodesProcedure.OUTPUT_FIELD_NODE,   Node,     NodeNull     );
end;{ TBaseNodesResultSet.fetch }


{ THNodesProcedureFactory }

function THNodesProcedureFactory.newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure;
begin
    Result := THNodesProcedure.create( AMetadata );
end;{ THNodesProcedureFactory.newItem }

{ THNodesProcedure }

class function THNodesProcedure.GetBwrResultSetClass:TBwrResultSetClass;
begin
    Result := THNodesResultSet;
end;{ THNodesProcedure.GetBwrResultSetClass }

{ THNodesResultSet }

procedure THNodesResultSet.SetRoot( AStatus:IStatus );
var
    Node64        : INT64;
    Node          : IDOMNodeEx absolute Node64;
    NodeNull      : WORDBOOL;
    NodeOk        : BOOLEAN;
begin
    NodeOk := RoutineContext.ReadInputBigint( AStatus, THNodesProcedure.INPUT_FIELD_NODE, Node64, NodeNull  );
    if( NodeOk )then begin
        fRoot  := Node;
        Node64 := 0;
    end;
end;{ THNodesResultSet.SetRoot }


{ TXNodesProcedureFactory }

function TXNodesProcedureFactory.newItem( AStatus:IStatus; AContext:IExternalContext; AMetadata:IRoutineMetadata ):IExternalProcedure;
begin
    Result := TXNodesProcedure.create( AMetadata );
end;{ TXNodesProcedureFactory.newItem }

{ TXNodesProcedure }

class function TXNodesProcedure.GetBwrResultSetClass:TBwrResultSetClass;
begin
    Result := TXNodesResultSet;
end;{ TXNodesProcedure.GetBwrResultSetClass }

{ TXNodesResultSet }

procedure TXNodesResultSet.SetRoot( AStatus:IStatus );
var
    Xml     : UnicodeString;
    XmlNull : WORDBOOL;
    XmlOk   : BOOLEAN;
    XmlDocOptions : TXMLDocOptions;
begin
    XmlOk := RoutineContext.ReadInputString( AStatus, TXNodesProcedure.INPUT_FIELD_XML, Xml, XmlNull );
    if( XmlOk and ( not XmlNull ) and ( Xml <> '' ) )then begin
        fDoc := LoadXMLData( Xml );
        if( fDoc <> nil )then begin
            XmlDocOptions := fDoc.Options;
            Exclude( XmlDocOptions, doNamespaceDecl );
            fDoc.Options := XmlDocOptions;
            fRoot := GetDOMNodeEx( fDoc.DOMDocument );
        end;
    end;
end;{ TXNodesResultSet.SetRoot }

destructor TXNodesResultSet.Destroy;
begin
    inherited Destroy;
    fDoc := nil;
end;{ TXNodesResultSet.Destroy; }


{routines}

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

{$REGION ADOMXML}
{$IFDEF ADOMXML}
//ADOM vendor does not recognize xpath like '/xxx:yyy'.
//This code snippet is intended to fix it.

function GetContextNamespaceURI( ContextNode:IDomNode; const Prefix:UnicodeString ):UnicodeString;
var
    RootNode   : IDomNode;
    attributes : IDOMNamedNodeMap;
    attrNode   : IDomNode;
begin
    Result := '';
    if( ( ContextNode = nil ) or ( Prefix = '' ) )then begin
        exit;
    end;
    RootNode := ContextNode.firstChild;
    if( ( RootNode <> nil ) and SameText( RootNode.NodeName, 'xml' ) )then begin
        RootNode := RootNode.nextSibling;
    end;
    if( RootNode <> nil )then begin
        attributes := RootNode.attributes;
        if( attributes <> nil )then begin
            attrNode := attributes.getNamedItemNS( SXMLNamespaceURI, Prefix );
            if( ( attrNode <> nil ) and ( attrNode.nodeType = ATTRIBUTE_NODE ) )then begin
                Result := attrNode.nodeValue;
            end;
        end;
    end;
end;{ GetContextNamespaceURI }

type

TLookupNamespaceHelper = class
  private
    procedure DoLookupNamespaceURI( const AContextNode: IDomNode; const APrefix: WideString; var ANamespaceURI: WideString );
end;

procedure TLookupNamespaceHelper.DoLookupNamespaceURI( const AContextNode: IDomNode; const APrefix: WideString; var ANamespaceURI: WideString );
begin
    ANamespaceURI := GetContextNamespaceURI( AContextNode, APrefix );
end;{ TLookupNamespaceHelper.DoLookupNamespaceURI }

{$ENDIF}
{$ENDREGION}

procedure InitProc;
begin
    {$IF Defined(MSXML)}
        CoInitialize( nil );
        Xml.xmldom.DefaultDOMVendor := Xml.Win.msxmldom.SMSXML;
    {$ELSEIF Defined(OMNIXML)}
        Xml.xmldom.DefaultDOMVendor := Xml.omnixmldom.sOmniXmlVendor;
    {$ELSEIF Defined(ADOMXML)}
        Xml.xmldom.DefaultDOMVendor := Xml.adomxmldom.sAdom4XmlVendor;
        Xml.adomxmldom.OnOx4XPathLookupNamespaceURI := TLookupNamespaceHelper( nil ).DoLookupNamespaceURI;
    {$IFEND}
end;{ InitProc }

procedure FinalProc;
begin
    Xml.xmldom.DefaultDOMVendor := '';
    {$IF Defined(MSXML)}
        CoUninitialize();
    {$ELSEIF Defined(OMNIXML)}
    {$ELSEIF Defined(ADOMXML)}
        //shalamyansky 2025-07-24 commented - probable unloading AV cause
        //Xml.adomxmldom.OnOx4XPathLookupNamespaceURI := nil;
    {$IFEND}
end;{ FinalProc }

initialization
begin
    InitProc;
end;{ initialization }

finalization
begin
    FinalProc;
end;{ finalization }

end.
