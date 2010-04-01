//
//	grl_json_parser.c
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

#include "grl_json_parser.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void grl_json_init ( struct grl_json_parse_context *context )
{
	context->buffer = NULL;
	context->p = NULL;
	context->s = NULL;
	context->allocations = NULL;
	context->issues = NULL;
	context->result = NULL;
}

void grl_json_load ( struct grl_json_parse_context *context, const char *buffer, long length )
{
	grl_json_lex_init( &(context->scanner) );
	grl_json_set_extra( context, context->scanner );
	
	context->buffer = context->p = buffer;
	context->s = buffer + length;
}

void grl_json_close ( struct grl_json_parse_context *context )
{
	grl_json_lex_destroy( context->scanner );
}

void grl_json_destroy ( struct grl_json_parse_context *context )
{
	struct grl_json_alloc_table_list *current = context->allocations, *next = NULL;
	
	while ( current )
	{
		next = current->next;
		
		free( current->table->memory );
		free( current->table );
		free( current );
		
		current = next;
	}
}

void *grl_json_malloc ( struct grl_json_parse_context *context, size_t size )
{
	if ( context->allocations == NULL || context->allocations->table->left < size )
	{
		struct grl_json_alloc_table *table;
		size_t						left, alloc = 0;
		
		left = context->s - context->p + GRL_JSON_PARSER_BUF_SIZE;
		
		alloc += left * GRL_JSON_VALUES_PER_BYTES;
		alloc += left * GRL_JSON_VALUE_LISTS_PER_BYTES;
		alloc += left * GRL_JSON_PAIRS_PER_BYTES;
		alloc += left * GRL_JSON_PAIR_LISTS_PER_BYTES;
		alloc += left * GRL_JSON_STRING_BUFFER_PER_BYTES;
		
		table = grl_json_alloc_table( ( alloc < size ? size : alloc ) );
				
		context->allocations = grl_json_alloc_table_list( table, context->allocations );
	}
	
	void *pointer = context->allocations->table->pointer;
	
	context->allocations->table->pointer += size;
	context->allocations->table->left -= size;
		
	return pointer;
}

struct grl_json_value *grl_json_integer_value( struct grl_json_parse_context *context, long long integer_value )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_integer;
	json_value->value.integer_value = integer_value;
			
	return json_value;
}

struct grl_json_value *grl_json_float_value( struct grl_json_parse_context *context, double float_value )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_float;
	json_value->value.float_value = float_value;
	
	return json_value;
}

struct grl_json_value *grl_json_boolean_value( struct grl_json_parse_context *context, unsigned char boolean_value )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_boolean;
	json_value->value.boolean_value = boolean_value;
	
	return json_value;
}

struct grl_json_value *grl_json_string_value( struct grl_json_parse_context *context, struct grl_json_string *string_value )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_string;
	json_value->value.string_value = string_value;
	
	return json_value;
}

struct grl_json_value *grl_json_array_value( struct grl_json_parse_context *context, struct grl_json_value_list *elements )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_array;
	json_value->value.array_value = elements;
	
	return json_value;
}

struct grl_json_value *grl_json_object_value( struct grl_json_parse_context *context, struct grl_json_pair_list *members )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_object;
	json_value->value.object_value = members;
	
	return json_value;
}

struct grl_json_value *grl_json_null_value ( struct grl_json_parse_context *context )
{
	struct grl_json_value *json_value = (struct grl_json_value *) grl_json_malloc( context, sizeof( struct grl_json_value ) );
	
	json_value->type = grl_json_value_type_null;
	
	return json_value;
}

struct grl_json_value_list *grl_json_value_list( struct grl_json_parse_context *context, struct grl_json_value *value, struct grl_json_value_list *next )
{
	struct grl_json_value_list *value_list = (struct grl_json_value_list *) grl_json_malloc( context, sizeof( struct grl_json_value_list ) );
	
	value_list->value = value;
	value_list->next = next;
	
	return value_list;
}

struct grl_json_value_list *grl_json_value_list_reverse ( struct grl_json_value_list *value_list )
{
	struct grl_json_value_list *current = value_list, *next = current->next, *last = value_list;
	
	current->next = NULL;
	
	while ( next != NULL )
	{
		current = next;
		
		next = current->next;
		
		current->next = last;
		
		last = current;
	}
	
	return current;
}

struct grl_json_pair *grl_json_pair ( struct grl_json_parse_context *context, struct grl_json_string *key, struct grl_json_value *value )
{
	struct grl_json_pair *pair = (struct grl_json_pair *) grl_json_malloc( context, sizeof( struct grl_json_pair ) );
	
	pair->key = key;
	pair->value = value;
	
	return pair;
}

struct grl_json_pair_list *grl_json_pair_list ( struct grl_json_parse_context *context, struct grl_json_pair *pair, struct grl_json_pair_list *next )
{
	struct grl_json_pair_list *pair_list = (struct grl_json_pair_list *) grl_json_malloc( context, sizeof( struct grl_json_pair_list ) );
	
	pair_list->pair = pair;
	pair_list->next = next;
	
	return pair_list;
}

struct grl_json_pair_list *grl_json_pair_list_reverse ( struct grl_json_pair_list *pair_list )
{
	struct grl_json_pair_list *current = pair_list, *next = current->next, *last = pair_list;
	
	current->next = NULL;
	
	while ( next != NULL )
	{
		current = next;
		
		next = current->next;
		
		current->next = last;
		
		last = current;
	}
	
	return current;
}

struct grl_json_issue *grl_json_issue ( struct grl_json_parse_context *context, grl_json_issue_code code )
{
	struct grl_json_issue *issue = (struct grl_json_issue *) grl_json_malloc( context, sizeof( struct grl_json_issue ) );
	
	issue->code = code;
	
	return issue;
}

struct grl_json_issue_list *grl_json_issue_list ( struct grl_json_parse_context *context, struct grl_json_issue *issue, struct grl_json_issue_list *next )
{
	struct grl_json_issue_list *issue_list = (struct grl_json_issue_list *) grl_json_malloc( context, sizeof( struct grl_json_issue_list ) );
	
	issue_list->issue = issue;
	issue_list->next = next;
	
	return issue_list;
}

struct grl_json_alloc_table *grl_json_alloc_table ( size_t size )
{
	struct grl_json_alloc_table *allocation = (struct grl_json_alloc_table *) malloc( sizeof(struct grl_json_alloc_table) );
	
	allocation->memory = allocation->pointer = (unsigned char *) malloc( size );
	allocation->left = size;
	
	return allocation;
}

struct grl_json_alloc_table_list *grl_json_alloc_table_list ( struct grl_json_alloc_table *table, struct grl_json_alloc_table_list *next )
{
	struct grl_json_alloc_table_list *list = (struct grl_json_alloc_table_list *) malloc( sizeof(struct grl_json_alloc_table_list) );
	
	list->table = table;
	list->next = next;
	
	return list;
}

