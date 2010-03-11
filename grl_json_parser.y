%{

//
//	grl_json_parser.y
//	GRLJSON
//
//	Created by Måns Severin on 2010-03-09.
//	Copyright 2010 Graphiclife. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//	
	
#include <stdio.h>
#include <stdlib.h>

#include "grl_json_parser.h"
	
int grl_json_lex ( void *lvalp, void *grl_scanner );

void grl_json_error ( struct grl_json_parse_context *context, const char *error );
	
#define grl_json_scanner context->scanner

%}

%pure-parser
%name-prefix="grl_json_"
%defines
%parse-param { struct grl_json_parse_context *context }
%lex-param { void *grl_json_scanner }

%union
{
	long long					integer_value;
	double						float_value;
	unsigned char				boolean_value;
	struct grl_json_string		*string_value;
	struct grl_json_value		*json_value;
	struct grl_json_pair		*pair_value;
	struct grl_json_value_list	*value_list_value;
	struct grl_json_pair_list	*pair_list_value;
}

%token NULLX COMMA COLON
%token L_BRACE R_BRACE L_BRACKET R_BRACKET

%token <integer_value> INTEGER
%token <float_value> FLOAT
%token <string_value> STRING
%token <boolean_value> BOOLEAN

%type <json_value> value array object
%type <pair_value> pair
%type <value_list_value> elements
%type <pair_list_value> members

%%

start:	value		{ context->result = $1; }
		;

object: 
		L_BRACE R_BRACE				{ $$ = grl_json_object_value( context, NULL ); }
	|	L_BRACE members R_BRACE		{ $$ = grl_json_object_value( context, grl_json_pair_list_reverse( $2 ) ); }
		;
		
array:
		L_BRACKET R_BRACKET				{ $$ = grl_json_array_value( context, NULL ); }
	|	L_BRACKET elements R_BRACKET	{ $$ = grl_json_array_value( context, grl_json_value_list_reverse( $2 ) ); }
		;

members:
			pair				{ $$ = grl_json_pair_list( context, $1, NULL ); }
		|	members COMMA pair	{ $$ = grl_json_pair_list( context, $3, $1 ); }
		;

pair:
		STRING COLON value	{ $$ = grl_json_pair( context, $1, $3 ); }
		;

elements:
			value					{ $$ = grl_json_value_list( context, $1, NULL ); }
		|	elements COMMA value	{ $$ = grl_json_value_list( context, $3, $1 ); }
		;
		
value:
		INTEGER		{ $$ = grl_json_integer_value( context, $1 ); }
	|	FLOAT		{ $$ = grl_json_float_value( context, $1 ); }
	|	STRING		{ $$ = grl_json_string_value( context, $1 ); }
	|	BOOLEAN		{ $$ = grl_json_boolean_value( context, $1 ); }
	|	NULLX		{ $$ = grl_json_null_value( context ); }
	|	object		{ $$ = $1; }
	|	array		{ $$ = $1; }
	;

%%