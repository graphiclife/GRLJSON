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
#import "GRLJSONValueTransformer.h"

#import "grl_json_parser.h"

@interface GRLJSON (Private)

+ (id)createJSONObjectFromValue:(struct grl_json_value *)value preserveNull:(BOOL)preserveNull;

@end

@implementation GRLJSON

+ (void)init
{
	[GRLJSONValueTransformer self];
}

+ (NSData *)serializeArray:(NSArray *)array
{
	return [self serializeArray:array tidy:NO];
}

+ (NSData *)serializeDictionary:(NSDictionary *)dictionary
{
	return [self serializeDictionary:dictionary tidy:NO];
}

+ (NSData *)serializeObject:(id <GRLJSONCoding>)object
{
	return [self serializeObject:object tidy:NO];
}

+ (NSData *)serializeArray:(NSArray *)array tidy:(BOOL)tidy
{
	GRLJSONCoder	*encoder = [[GRLJSONCoder alloc] init];
	NSData			*data;
	
	[encoder encodeRootObject:kGRLJSONObjectTypeSingle];
	[encoder encodeArray:array];
	
	data = [encoder serializeByTidying:tidy];
	[encoder release];
	
	return data;
}

+ (NSData *)serializeDictionary:(NSDictionary *)dictionary tidy:(BOOL)tidy
{
	GRLJSONCoder	*encoder = [[GRLJSONCoder alloc] init];
	NSData			*data;
	
	[encoder encodeRootObject:kGRLJSONObjectTypeSingle];
	[encoder encodeDictionary:dictionary];
	
	data = [encoder serializeByTidying:tidy];
	[encoder release];
	
	return data;
}

+ (NSData *)serializeObject:(id <GRLJSONCoding>)object tidy:(BOOL)tidy
{
	GRLJSONCoder	*encoder = [[GRLJSONCoder alloc] init];
	NSData			*data;
	
	[encoder encodeRootObject:kGRLJSONObjectTypeSingle];
	[encoder encodeObject:object];
	
	data = [encoder serializeByTidying:tidy];
	[encoder release];
	
	return data;
}

+ (id)deserializeData:(NSData *)data error:(NSError **)error
{
	return [self deserializeData:data preserveNulls:NO error:error];
}

+ (id)deserializeData:(NSData *)data preserveNulls:(BOOL)preserveNulls error:(NSError **)error
{
	id result = nil;
	struct grl_json_parse_context context;
	
	grl_json_init( &context );
	grl_json_load( &context, [data bytes], [data length] );
	
	if ( grl_json_parse( &context ) == 0 )
	{
		result = [self createJSONObjectFromValue:context.result preserveNull:preserveNulls];
	}
	else
	{
		
	}
	
	grl_json_close( &context );
	grl_json_destroy( &context );
	
	return result;
}

+ (id)createJSONObjectFromValue:(struct grl_json_value *)value preserveNull:(BOOL)preserveNull
{
	NSMutableArray				*array;
	NSMutableDictionary			*dictionary;
	struct grl_json_value_list	*vlist;
	struct grl_json_pair_list	*plist;
	id							json;
	
	switch ( value->type )
	{
		case grl_json_value_type_null:
			return ( preserveNull ? [NSNull null] : nil );
			
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
				json = [self createJSONObjectFromValue:vlist->value preserveNull:preserveNull];
				
				if ( json )
				{
					[array addObject:json];
				}
			}
			
			return array;
			
		case grl_json_value_type_object:
			dictionary = [NSMutableDictionary dictionary];
			
			for ( plist = value->value.object_value ; plist ; plist = plist->next )
			{
				json = [self createJSONObjectFromValue:plist->pair->value preserveNull:preserveNull];
				
				if ( json )
				{
					[dictionary setObject:json forKey:[NSString stringWithCharacters:plist->pair->key->characters length:plist->pair->key->length]];
				}
			}
			
			return dictionary;
	}
	
	return nil;
}

@end
