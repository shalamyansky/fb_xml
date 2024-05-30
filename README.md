# fb_xml
Firebird UDR module to support XML parsing in SQL.

## Basis

Parsing is based on bundled Delphi ADOM4 or OmniXML parsers.

## Routines

Routines are assembled into package ***xml***. Pseudotype ***string*** marks any of string type ***char***, ***varchar*** of any length or ***blob sub_type text***. All the routines can accept and return any string type.

## procedure *nodes*

    procedure nodes(
        xml        string    -- XML to be parsed
      , xpath      string    -- XPath expression
    )returns(
        number     integer   -- order number of node started from 1
      , source     string    -- XML view of node
      , name       string    -- node name
      , text       string    -- node value
      , node_type  smallint  -- node type
      , path       string    -- full path from source xml root to the found node
    );

    Node types are:
		 1 - element node
		 2 - attribute node
		 3 - text node
		 4 - CDATA section node
		 5 - entity reference node
		 6 - entity node
		 7 - processing instruction node
		 8 - comment node
		 9 - document node
		10 - document type node
		11 - document fragment node
		12 - notation node


This is а selective procedure, main routine of XML package. Returns set of nodes. Each row contains some node properties.

***source*** is xml view of node. For an element node ***source*** looks like **\<elem\>..\</elem\>** and is suitable for further parsing. For an attribute node ***source*** looks like **attr="attribute-value"**.  

***text*** is the node scalar value, i.e. it is element text for an element node or an attribute value for an attribute node.


## functions *get_node*, *get_value* and *get_name*

    function get_node(
        xml   string    -- XML to be parsed
      , xpath string    -- XPath expression
    )returns  string;   -- XML view of the first found node (source)

    function get_value(
        xml   string    -- XML to be parsed
      , xpath string    -- XPath expression
    )returns  string;   -- value of the first found node (text)

    function get_name(
        xml   string    -- XML to be parsed
      , xpath string    -- XPath expression
    )returns  string;   -- name of the first found node (name)

These are truncated versions of ***nodes*** procedure. Return source or value or name of the first found node.

## Limitations

The module provides very simple XPath. More complex if ADOM4 XML parser is selected to compile (by default). But it be faster with OmniXML parser.

## Installation

0. Download a release package.

1. Copy fb_xml.dll to %firebird%\plugins\udr
   where %firebird% is Firebird 4.0(3.0) server root directory.
   Make sure library module matches the Firebird bitness.

2. Select script fb_xml_utf8.sql or fb_xml_win1251.sql.

3. Connect to target database and execute the script.


## Using

You can use binaries as you see fit.

If you get code or part of code please keep my name and a link [here](https://github.com/shalamyansky/fb_xml).   


## Examples

Animals XML data:

	<animals>
	  <animal name="Angel Fish" size="2" weight="2">
	    <area>Computer Aquariums</area>
	  </animal>
	  <animal name="Boa" size="10" weight="10">
	    <area>South America</area>
	  </animal>
	  <animal name="Parrot" size="30" weight="30">
	    <area>South Africa</area>
	  </animal>
	</animals>


### Example 1

Task : Get name of the second animal.

Solution :

    select
        xml.get_value( :XML, 'animals/animal[2]/@name' ) as name
      from
        rdb$database

Result :

    NAME
    ====
    Boa

### Example 2

Task : Get area of animal named Parrot.

Solution :

    select
        xml.get_value( :XML, 'animals/animal[@name="Parrot"]/area' ) as area
      from
        rdb$database

Result :

    AREA
    ============
    South Africa


### Example 3

Task : Select all attributes names and values for the first sub-element of 'animals'. 

Solution :

    select
          attribute.name
        , attribute.text
      from
        xml.nodes( :XML, 'animals/*[1]/@*' ) as attribute

Result :

    NAME   TEXT
    ====   ==========
    name   Angel Fish
    size   2
    weight 2

### Example 4

Task : select all animal elements

Solution :  

    select
          animal.number
        , animal.source
      from
        xml.nodes( :XML, 'animals/animal' ) as animal

Result :

    NUMBER  SOURCE
    ======  ================================================================================================
         1	<animal name="Angel Fish" size="2" weight="2">[LF] <area>Computer Aquariums</area>[LF] </animal>
         2	<animal name="Boa" size="10" weight="10">[LF] <area>South America</area>[LF] </animal>
         3  <animal name="Parrot" size="30" weight="30">[LF] <area>South Africa</area>[LF] </animal>

### Example 5

Task : select all animal names and areas

Solution :  

    select
          xml.get_value( animal.source, 'animal/@name' ) as name
        , xml.get_value( animal.source, 'animal/area'  ) as area
      from
        xml.nodes( :XML, 'animals/animal' ) as animal

Result :

    NAME        AREA
    ==========  ==================
    Angel Fish  Computer Aquariums
    Boa         South America
    Parrot      South Africa

### Example 5

Task : select all the animal elements

Solution :  
	
	select
		  *
	  from
	    xml.nodes( :XML, '//animal' )

Result :

	NUMBER  SOURCE                                                                                  NAME    TEXT                NODE_TYPE  PATH
	======  ======================================================================================  ======  ==================  =========  ==================
	     1  <animal name="Angel Fish" size="2" weight="2"><area>Computer Aquariums</area></animal>  animal  Computer Aquariums          1  /animals/animal[1]
	     2  <animal name="Boa" size="10" weight="10"><area>South America</area></animal>            animal  South America               1  /animals/animal[2]
	     3  <animal name="Parrot" size="30" weight="30"><area>South Africa</area></animal>          animal  South Africa                1  /animals/animal[3]
