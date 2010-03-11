//
//	grl_json_parser.h
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

#include <stdlib.h>

#ifndef GRL_JSON_PARSER
#define GRL_JSON_PARSER

#define GRL_JSON_PARSER_BUF_SIZE			8192

#define GRL_JSON_VALUES_PER_BYTES			0.0150
#define GRL_JSON_VALUE_LISTS_PER_BYTES		0.0013
#define GRL_JSON_PAIRS_PER_BYTES			0.0130
#define GRL_JSON_PAIR_LISTS_PER_BYTES		0.0130
#define GRL_JSON_STRING_BUFFER_PER_BYTES	0.5500

typedef enum
{
	grl_json_issue_code_none,
	grl_json_issue_code_parse,
	grl_json_issue_code_string
} grl_json_issue_code;

typedef enum
{
	grl_json_value_type_null,
	grl_json_value_type_integer,
	grl_json_value_type_float,
	grl_json_value_type_boolean,
	grl_json_value_type_string,
	grl_json_value_type_array,
	grl_json_value_type_object
} grl_json_value_type;

struct grl_json_string
{
	unsigned short	*characters;
	unsigned long	length;
};

struct grl_json_value
{
	grl_json_value_type	type;
	
	union
	{
		long long					integer_value;
		double						float_value;
		unsigned char				boolean_value;
		struct grl_json_string		*string_value;
		struct grl_json_value_list	*array_value;
		struct grl_json_pair_list	*object_value;
	} value;
};

struct grl_json_value_list
{
	struct grl_json_value		*value;
	struct grl_json_value_list	*next;
};

struct grl_json_pair
{
	struct grl_json_string	*key;
	struct grl_json_value	*value;
};

struct grl_json_pair_list
{
	struct grl_json_pair		*pair;
	struct grl_json_pair_list	*next;
};

struct grl_json_issue
{
	grl_json_issue_code	code;
};

struct grl_json_issue_list
{
	struct grl_json_issue		*issue;
	struct grl_json_issue_list	*next;
};

struct grl_json_alloc_table
{
	unsigned char	*memory;
	unsigned char	*pointer;
	size_t			left;
};

struct grl_json_alloc_table_list
{
	struct grl_json_alloc_table			*table;
	struct grl_json_alloc_table_list	*next;
};

struct grl_json_parse_context
{
	void								*scanner;
	const char							*buffer;
	const char							*p;
	const char							*s;
	struct grl_json_alloc_table_list	*allocations;
	struct grl_json_issue_list			*issues;
	struct grl_json_value				*result;
};

int grl_json_lex_init ( void **scanner );
int grl_json_lex_destroy ( void *scanner );
void grl_json_set_extra ( struct grl_json_parse_context *context, void *scanner );

int grl_json_parse ( struct grl_json_parse_context *context );

void grl_json_init ( struct grl_json_parse_context *context, const char *buffer, long length );
void grl_json_close ( struct grl_json_parse_context *context );

void *grl_json_malloc ( struct grl_json_parse_context *context, size_t size );

struct grl_json_value *grl_json_integer_value ( struct grl_json_parse_context *context, long long integer_value );
struct grl_json_value *grl_json_float_value ( struct grl_json_parse_context *context, double float_value );
struct grl_json_value *grl_json_boolean_value ( struct grl_json_parse_context *context, unsigned char boolean_value );
struct grl_json_value *grl_json_string_value ( struct grl_json_parse_context *context, struct grl_json_string *string_value );
struct grl_json_value *grl_json_array_value ( struct grl_json_parse_context *context, struct grl_json_value_list *elements );
struct grl_json_value *grl_json_object_value ( struct grl_json_parse_context *context, struct grl_json_pair_list *members );
struct grl_json_value *grl_json_null_value ( struct grl_json_parse_context *context );

struct grl_json_value_list *grl_json_value_list ( struct grl_json_parse_context *context, struct grl_json_value *value, struct grl_json_value_list *next );
struct grl_json_value_list *grl_json_value_list_reverse (  struct grl_json_value_list *value_list );

struct grl_json_pair *grl_json_pair ( struct grl_json_parse_context *context, struct grl_json_string *key, struct grl_json_value *value );
struct grl_json_pair_list *grl_json_pair_list ( struct grl_json_parse_context *context, struct grl_json_pair *pair, struct grl_json_pair_list *next );
struct grl_json_pair_list *grl_json_pair_list_reverse ( struct grl_json_pair_list *pair_list );

struct grl_json_issue *grl_json_issue ( struct grl_json_parse_context *context, grl_json_issue_code code );
struct grl_json_issue_list *grl_json_issue_list ( struct grl_json_parse_context *context, struct grl_json_issue *issue, struct grl_json_issue_list *next );

struct grl_json_alloc_table *grl_json_alloc_table ( size_t size );
struct grl_json_alloc_table_list *grl_json_alloc_table_list ( struct grl_json_alloc_table *table, struct grl_json_alloc_table_list *next );

#endif