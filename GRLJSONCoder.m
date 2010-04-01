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

#import "GRLJSONCoder_Internal.h"

#import "GRLJSONCoding.h"

#import "grl_json_parser.h"
#import "grl_json_utilities.h"

@interface GRLJSONCoder (Private)

- (struct grl_json_value *)result;
- (unichar *)copyCharactersOfString:(NSString *)string;
- (NSData *)serializeJSONValue:(struct grl_json_value *)value;
- (NSData *)serializeString:(struct grl_json_string *)string;

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
	if ( number == nil )
	{
		[self encodeNull]; return;
	}
	
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
	if ( number == nil )
	{
		[self encodeNullForKey:key]; return;
	}
	
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
	if ( string == nil )
	{
		[self encodeNull]; return;
	}
	
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
	if ( string == nil )
	{
		[self encodeNullForKey:key]; return;
	}
	
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
	if ( object == nil )
	{
		[self encodeNull]; return;
	}
	
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
	if ( object == nil )
	{
		[self encodeNullForKey:key]; return;
	}
	
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
	if ( array == nil )
	{
		[self encodeNull]; return;
	}
	
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
	if ( array == nil )
	{
		[self encodeNullForKey:key]; return;
	}
	
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
	if ( dictionary == nil )
	{
		[self encodeNull]; return;
	}
	
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
	if ( dictionary == nil )
	{
		[self encodeNullForKey:key]; return;
	}
	
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

- (NSData *)serialize
{
	return [self serializeJSONValue:[self result]];
}

- (NSData *)serializeJSONValue:(struct grl_json_value *)value
{
	NSMutableData				*data = [NSMutableData data];
	NSAutoreleasePool			*pool;
	struct grl_json_value_list	*vlist;
	struct grl_json_pair_list	*plist;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	switch ( value->type )
	{
		case grl_json_value_type_null:
			[data appendBytes:"null" length:4];
			break;
			
		case grl_json_value_type_integer:
			[data appendData:[[NSString stringWithFormat:@"%ld", value->value.integer_value] dataUsingEncoding:NSASCIIStringEncoding]];
			break;
			
		case grl_json_value_type_float:
			[data appendData:[[NSString stringWithFormat:@"%f", value->value.float_value] dataUsingEncoding:NSASCIIStringEncoding]];
			break;
			
		case grl_json_value_type_boolean:
			if ( value->value.boolean_value )
				[data appendBytes:"true" length:4];
			else
				[data appendBytes:"false" length:5];
			break;
			
		case grl_json_value_type_string:
			[data appendData:[self serializeString:value->value.string_value]];
			break;
			
		case grl_json_value_type_array:
			[data appendBytes:"[" length:1];
			
			for ( vlist = value->value.array_value ; vlist ; vlist = vlist->next )
			{
				[data appendData:[self serializeJSONValue:vlist->value]];
				
				if ( vlist->next )
				{
					[data appendBytes:"," length:1];
				}
			}
			
			[data appendBytes:"]" length:1];
			break;
			
		case grl_json_value_type_object:
			[data appendBytes:"{" length:1];
			
			for ( plist = value->value.object_value ; plist ; plist = plist->next )
			{
				[data appendData:[self serializeString:plist->pair->key]];
				[data appendBytes:":" length:1];
				[data appendData:[self serializeJSONValue:plist->pair->value]];
				
				if ( plist->next )
				{
					[data appendBytes:"," length:1];
				}
			}
			
			[data appendBytes:"}" length:1];
			break;
	}	
	
	[pool release];
	
	return data;
}

- (NSData *)serializeString:(struct grl_json_string *)string
{
	NSMutableData	*sdata = [NSMutableData data];
	unsigned short	c;
	
	[sdata appendBytes:"\"" length:1];
	
	for ( unsigned long i = 0 ; i < string->length ; i++ )
	{
		switch ( (c = string->characters[i] ) )
		{
			case '/':
				[sdata appendBytes:"\\/" length:2];
				break;
				
			case '\\':
				[sdata appendBytes:"\\\\" length:2];
				break;
				
			case '"':
				[sdata appendBytes:"\\\"" length:2];
				break;
				
			case '\r':
				[sdata appendBytes:"\\r" length:2];
				break;
				
			case '\n':
				[sdata appendBytes:"\\n" length:2];
				break;
				
			case '\t':
				[sdata appendBytes:"\\t" length:2];
				break;
				
			case '\b':
				[sdata appendBytes:"\\b" length:2];
				break;
				
			case '\f':
				[sdata appendBytes:"\\f" length:2];
				break;
				
			default:
				if ( c > 0x7F )
				{
					[sdata appendData:[[NSString stringWithFormat:@"\\u%.4X", c] dataUsingEncoding:NSASCIIStringEncoding]];
				}
				else
				{
					[sdata appendData:[[NSString stringWithFormat:@"%c", (char) c] dataUsingEncoding:NSASCIIStringEncoding]];
				}
				break;
		}
	}
	
	[sdata appendBytes:"\"" length:1];
	
	return sdata;
}

@end
