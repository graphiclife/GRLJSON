%option full
%option noyywrap
%option reentrant
%option prefix="grl_json_"
%option bison-bridge
%option 8bit

%{

//
//	grl_json_parser.l
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
	
#include "y.tab.h"
	
#include "grl_json_parser.h"
#include "grl_json_utilities.h"
	
#define YY_INPUT( buffer, result, max_size )				\
{															\
	struct grl_json_parse_context *context = yyextra;		\
															\
	int	left = context->s - context->p;						\
	int copy = ((left) < (max_size) ? (left) : (max_size));	\
															\
	memcpy( buffer, context->p, copy );						\
															\
	context->p += copy;										\
															\
	result = copy;											\
}
	
#define YY_EXTRA_TYPE struct grl_json_parse_context *

int grl_json_lex ( YYSTYPE *lvalp, void *grl_scanner );
	
void grl_json_error ( struct grl_json_parse_context *context, const char *error )
{
	context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_parse ), context->issues );
}
	
#define grl_json_scanner context->scanner
	
%}

integer  	-?[0-9]+
floating 	-?((([0-9]+)|([0-9]*\.[0-9]+))([eE][-+]?[0-9]+)?)
string		\"(\\.|[^"])*\"

%%

[\n\r\t ]+		{ /* " */ }

{integer}		{ yylval->integer_value = strtoll( yytext, NULL, 10 ); return INTEGER; }
{floating}		{ yylval->float_value = strtod( yytext, NULL ); return FLOAT; }
{string}		{ yylval->string_value = grl_json_quoted_utf8_strcpy( yyextra, yytext, yyleng ); return STRING; }

"null"			{ return NULLX; }
"true"			{ yylval->boolean_value = 1; return BOOLEAN; }
"false"			{ yylval->boolean_value = 0; return BOOLEAN; }
":"				{ return COLON; }
","				{ return COMMA; }
"{"				{ return L_BRACE; }
"}"				{ return R_BRACE; }
"["				{ return L_BRACKET; }
"]"				{ return R_BRACKET; }

.				;

%%
