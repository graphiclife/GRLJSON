//
//	GRLJSON.m
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

#import "GRLJSON.h"

#import "GRLJSONCoder.h"
#import "GRLJSONCoder_Internal.h"

#import "GRLJSONCoding.h"

#import "grl_json_parser.h"

@interface GRLJSON (Private)

- (id)createJSONObjectFromValue:(struct grl_json_value *)value;

@end

@implementation GRLJSON

+ (NSData *)serializeArray:(NSArray *)array
{
	GRLJSONCoder	*encoder = [[GRLJSONCoder alloc] init];
	NSData			*data;
	
	[encoder encodeRootObject:kGRLJSONObjectTypeSingle];
	[encoder encodeArray:array];
	
	data = [encoder serialize];
	[encoder release];
	
	return data;
}

+ (NSData *)serializeDictionary:(NSDictionary *)dictionary
{
	GRLJSONCoder	*encoder = [[GRLJSONCoder alloc] init];
	NSData			*data;
	
	[encoder encodeRootObject:kGRLJSONObjectTypeSingle];
	[encoder encodeDictionary:dictionary];
	
	data = [encoder serialize];
	[encoder release];
	
	return data;
}

+ (NSData *)serializeObject:(id <GRLJSONCoding>)object
{
	GRLJSONCoder	*encoder = [[GRLJSONCoder alloc] init];
	NSData			*data;
	
	[encoder encodeRootObject:kGRLJSONObjectTypeSingle];
	[encoder encodeObject:object];
	
	data = [encoder serialize];
	[encoder release];
	
	return data;
}

- (id)initWithData:(NSData *)data
{
	if ( self = [super init] )
	{
		_data = [data retain];
	}
	
	return self;
}

- (void)dealloc
{
	[_data release]; _data = nil;
	[super dealloc];
}

- (id)parse:(NSError **)error
{
	id result = nil;
	struct grl_json_parse_context context;
	
	grl_json_init( &context );
	grl_json_load( &context, [_data bytes], [_data length] );
	
	if ( grl_json_parse( &context ) == 0 )
	{
		result = [self createJSONObjectFromValue:context.result];
	}
	else
	{
		
	}
	
	grl_json_close( &context );
	grl_json_destroy( &context );
	
	return result;
}

- (id)createJSONObjectFromValue:(struct grl_json_value *)value
{
	NSMutableArray				*array;
	NSMutableDictionary			*dictionary;
	struct grl_json_value_list	*vlist;
	struct grl_json_pair_list	*plist;
	
	switch ( value->type )
	{
		case grl_json_value_type_null:
			return [NSNull null];
			
		case grl_json_value_type_integer:
			return [NSNumber numberWithLongLong:value->value.integer_value];
				
		case grl_json_value_type_float:
			return [NSNumber numberWithDouble:value->value.float_value];
					
		case grl_json_value_type_boolean:
			return [NSNumber numberWithBool:value->value.boolean_value];
			
		case grl_json_value_type_string:
			return [NSString stringWithCharacters:value->value.string_value->characters length:value->value.string_value->length];
			
		case grl_json_value_type_array:
			array = [NSMutableArray array];
			
			for ( vlist = value->value.array_value ; vlist ; vlist = vlist->next )
			{
				[array addObject:[self createJSONObjectFromValue:vlist->value]];
			}
			
			return array;
			
		case grl_json_value_type_object:
			dictionary = [NSMutableDictionary dictionary];
			
			for ( plist = value->value.object_value ; plist ; plist = plist->next )
			{
				[dictionary setObject:[self createJSONObjectFromValue:plist->pair->value]
							   forKey:[NSString stringWithCharacters:plist->pair->key->characters length:plist->pair->key->length]];
			}
			
			return dictionary;
	}
	
	return nil;
}

@end
