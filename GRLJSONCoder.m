//
//  GRLJSONCoder.m
//  GRLJSON
//
//  Created by Måns Severin on 2010-03-31.
//  Copyright 2010 Graphiclife. All rights reserved.
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

#import "GRLJSONCoder.h"

#import "grl_json_parser.h"
#import "grl_json_utilities.h"

@interface GRLJSONCoder (Private)

- (struct grl_json_value *)result;
- (unichar *)copyCharactersOfString:(NSString *)string;

@end

@implementation GRLJSONCoder

- (id)init
{
	if ( self = [super init] )
	{
		_context = malloc( sizeof( struct grl_json_parse_context ) ); grl_json_init( _context );
		_coders = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	grl_json_destroy( _context ); free( _context ); _context = nil;
	
	[_coders release]; _coders = nil;
	[super dealloc];
}

- (void)encodeRootObject:(GRLJSONObjectType)objectType
{
	struct grl_json_parse_context *ctx = (struct grl_json_parse_context *) _context;
	
	switch ( objectType )
	{
		case kGRLJSONObjectTypeSingle:
			ctx->result = NULL;
			break;
		
		case kGRLJSONObjectTypeObject:
			ctx->result = grl_json_object_value( ctx, NULL );
			break;
		
		case kGRLJSONObjectTypeArray:
			ctx->result = grl_json_array_value( ctx, NULL );
			break;
	}
}

- (void)encodeNull
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = grl_json_null_value( ctx );
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
}

- (void)encodeNullForKey:(NSString *)key
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = grl_json_null_value( ctx );
	unichar							*keyc = [self copyCharactersOfString:key];
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	free( keyc );
}

- (void)encodeBool:(BOOL)flag
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = grl_json_boolean_value( ctx, ( flag == NO ? 0 : 1 ) );
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
}

- (void)encodeBool:(BOOL)flag forKey:(NSString *)key
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = grl_json_boolean_value( ctx, ( flag == NO ? 0 : 1 ) );
	unichar							*keyc = [self copyCharactersOfString:key];
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	free( keyc );
}

- (void)encodeNumber:(NSNumber *)number
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	
	switch ( CFNumberGetType((CFNumberRef) number) )
	{
		case kCFNumberCharType:
		{
			NSInteger i = [number integerValue];
			
			if ( i == 0 || i == 1 )
			{
				value = grl_json_boolean_value( ctx, i );
			}
			else
			{
				value = grl_json_integer_value( ctx, i );
			}
		}
			break;
			
		case kCFNumberFloat32Type:
		case kCFNumberFloat64Type:
		case kCFNumberFloatType:
		case kCFNumberDoubleType:
			value = grl_json_float_value( ctx, [number doubleValue] );
			break;
			
		case kCFNumberSInt8Type:
		case kCFNumberSInt16Type:
		case kCFNumberSInt32Type:
		case kCFNumberSInt64Type:
		case kCFNumberShortType:
		case kCFNumberIntType:
		case kCFNumberLongType:
		case kCFNumberLongLongType:
		case kCFNumberCFIndexType:
		default:
			value = grl_json_integer_value( ctx, [number longLongValue] );
			break;
	}
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
}

- (void)encodeNumber:(NSNumber *)number forKey:(NSString *)key
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	unichar							*keyc = [self copyCharactersOfString:key];
	
	switch ( CFNumberGetType((CFNumberRef) number) )
	{
		case kCFNumberCharType:
		{
			NSInteger i = [number integerValue];
			
			if ( i == 0 || i == 1 )
			{
				value = grl_json_boolean_value( ctx, i );
			}
			else
			{
				value = grl_json_integer_value( ctx, i );
			}
		}
			break;
			
		case kCFNumberFloat32Type:
		case kCFNumberFloat64Type:
		case kCFNumberFloatType:
		case kCFNumberDoubleType:
			value = grl_json_float_value( ctx, [number doubleValue] );
			break;
			
		case kCFNumberSInt8Type:
		case kCFNumberSInt16Type:
		case kCFNumberSInt32Type:
		case kCFNumberSInt64Type:
		case kCFNumberShortType:
		case kCFNumberIntType:
		case kCFNumberLongType:
		case kCFNumberLongLongType:
		case kCFNumberCFIndexType:
		default:
			value = grl_json_integer_value( ctx, [number longLongValue] );
			break;
	}
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	free( keyc );
}

- (void)encodeString:(NSString *)string
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	unichar							*c = [self copyCharactersOfString:string];
	
	value = grl_json_string_value( ctx, grl_json_strdup( ctx, c, [string length] ) );
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
	
	free( c );
}

- (void)encodeString:(NSString *)string forKey:(NSString *)key
{
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	unichar							*keyc = [self copyCharactersOfString:key];
	unichar							*c = [self copyCharactersOfString:string];
	
	value = grl_json_string_value( ctx, grl_json_strdup( ctx, c, [string length] ) );
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	free( keyc );
	free( c );
}

- (void)encodeObject:(id <GRLJSONCoding>)object
{
	GRLJSONCoder					*coder = [[GRLJSONCoder alloc] init];
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	
	[object encodeWithJSONCoder:coder]; value = [coder result];
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
	
	[_coders addObject:coder];
	[coder release];
}

- (void)encodeObject:(id <GRLJSONCoding>)object forKey:(NSString *)key
{
	GRLJSONCoder					*coder = [[GRLJSONCoder alloc] init];
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	unichar							*keyc = [self copyCharactersOfString:key];
	
	[object encodeWithJSONCoder:coder]; value = [coder result];
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	[_coders addObject:coder];
	[coder release];
	
	free( keyc );
}

- (void)encodeArray:(NSArray *)array
{
	GRLJSONCoder					*coder = [[GRLJSONCoder alloc] init];
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	id								aelement;
	
	[coder encodeRootObject:kGRLJSONObjectTypeArray];
	
	for ( aelement in array )
	{
		if ( [aelement conformsToProtocol:@protocol(GRLJSONCoding)] )
		{
			[coder encodeObject:aelement];
		}
		else if ( [aelement isKindOfClass:[NSNull class]] )
		{
			[coder encodeNull];
		}
		else if ( [aelement isKindOfClass:[NSNumber class]] )
		{
			[coder encodeNumber:aelement];
		}
		else if ( [aelement isKindOfClass:[NSString class]] )
		{
			[coder encodeString:aelement];
		}
		else if ( [aelement isKindOfClass:[NSArray class]] )
		{
			[coder encodeArray:aelement];
		}
		else if ( [aelement isKindOfClass:[NSDictionary class]] )
		{
			[coder encodeDictionary:aelement];
		}
		else
		{
			// Error
		}
	}
	
	value = [coder result];
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
	
	[_coders addObject:coder];
	[coder release];
}

- (void)encodeArray:(NSArray *)array forKey:(NSString *)key
{
	GRLJSONCoder					*coder = [[GRLJSONCoder alloc] init];
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	unichar							*keyc = [self copyCharactersOfString:key];
	id								aelement;
	
	[coder encodeRootObject:kGRLJSONObjectTypeArray];
	
	for ( aelement in array )
	{
		if ( [aelement conformsToProtocol:@protocol(GRLJSONCoding)] )
		{
			[coder encodeObject:aelement];
		}
		else if ( [aelement isKindOfClass:[NSNull class]] )
		{
			[coder encodeNull];
		}
		else if ( [aelement isKindOfClass:[NSNumber class]] )
		{
			[coder encodeNumber:aelement];
		}
		else if ( [aelement isKindOfClass:[NSString class]] )
		{
			[coder encodeString:aelement];
		}
		else if ( [aelement isKindOfClass:[NSArray class]] )
		{
			[coder encodeArray:aelement];
		}
		else if ( [aelement isKindOfClass:[NSDictionary class]] )
		{
			[coder encodeDictionary:aelement];
		}
		else
		{
			// Error
		}
	}
	
	value = [coder result];
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	[_coders addObject:coder];
	[coder release];
	
	free( keyc );
}

- (void)encodeDictionary:(NSDictionary *)dictionary
{
	GRLJSONCoder					*coder = [[GRLJSONCoder alloc] init];
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	id								delement;
	id								dkey;
	
	[coder encodeRootObject:kGRLJSONObjectTypeObject];
	
	for ( dkey in dictionary )
	{
		delement = [dictionary objectForKey:dkey];
		
		if ( [delement conformsToProtocol:@protocol(GRLJSONCoding)] )
		{
			[coder encodeObject:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSNull class]] )
		{
			[coder encodeNullForKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSNumber class]] )
		{
			[coder encodeNumber:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSString class]] )
		{
			[coder encodeString:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSArray class]] )
		{
			[coder encodeArray:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSDictionary class]] )
		{
			[coder encodeDictionary:delement forKey:dkey];
		}
		else
		{
			// Error
		}
	}
	
	value = [coder result];
	
	if ( ctx->result == NULL )
	{
		ctx->result = value;
	}
	else if ( ctx->result->type == grl_json_value_type_array )
	{		
		ctx->result->value.array_value = grl_json_value_list( ctx, value, ctx->result->value.array_value );
	}
	else
	{
		// Error
	}
	
	[_coders addObject:coder];
	[coder release];
}

- (void)encodeDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
	GRLJSONCoder					*coder = [[GRLJSONCoder alloc] init];
	struct grl_json_parse_context	*ctx = (struct grl_json_parse_context *) _context;
	struct grl_json_value			*value = NULL;
	unichar							*keyc = [self copyCharactersOfString:key];
	id								delement;
	id								dkey;
	
	[coder encodeRootObject:kGRLJSONObjectTypeObject];
	
	for ( dkey in dictionary )
	{
		delement = [dictionary objectForKey:dkey];
		
		if ( [delement conformsToProtocol:@protocol(GRLJSONCoding)] )
		{
			[coder encodeObject:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSNull class]] )
		{
			[coder encodeNullForKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSNumber class]] )
		{
			[coder encodeNumber:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSString class]] )
		{
			[coder encodeString:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSArray class]] )
		{
			[coder encodeArray:delement forKey:dkey];
		}
		else if ( [delement isKindOfClass:[NSDictionary class]] )
		{
			[coder encodeDictionary:delement forKey:dkey];
		}
		else
		{
			// Error
		}
	}
	
	value = [coder result];
	
	if ( ctx->result == NULL )
	{
		// Error
	}
	else if ( ctx->result->type == grl_json_value_type_object )
	{		
		ctx->result->value.object_value = grl_json_pair_list( ctx, grl_json_pair( ctx, grl_json_strdup( ctx, keyc, [key length] ), value ), ctx->result->value.object_value );
	}
	else
	{
		// Error
	}
	
	[_coders addObject:coder];
	[coder release];
	
	free( keyc );
}
																  
#pragma mark Private API

- (struct grl_json_value *)result
{
	struct grl_json_parse_context *ctx = (struct grl_json_parse_context *) _context;
	
	return ctx->result;
}

- (unichar *)copyCharactersOfString:(NSString *)string
{
	NSRange range = NSMakeRange( 0, [string length] );
	unichar	*buffer = (unichar *) malloc( sizeof(unichar) * range.length );
	
	[string getCharacters:buffer range:range];
	
	return buffer;
}

@end
