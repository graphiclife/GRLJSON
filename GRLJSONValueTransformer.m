//
//  GRLJSONValueTransformer.m
//  GRLJSON
//
//  Created by Måns Severin on 2010-05-11.
//  Copyright 2010 Graphiclife. All rights reserved.
//

#import "GRLJSONValueTransformer.h"

#import "GRLJSON.h"

@implementation GRLJSONValueTransformer

+ (void)initialize
{	
    [NSValueTransformer setValueTransformer:[[[GRLJSONValueTransformer alloc] init] autorelease] forName:@"GRLJSONValueTransformer"];
}

+ (Class)transformedValueClass
{
	return [NSObject class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	if ( value == nil )
		return nil;
	
	NSData *result = nil;
	
	if ( [value conformsToProtocol:@protocol(GRLJSONCoding)] )
	{
		result = [GRLJSON serializeObject:value];
	}
	else if ( [value isKindOfClass:[NSDictionary class]] )
	{
		result = [GRLJSON serializeDictionary:value];
	}
	else if ( [value isKindOfClass:[NSArray class]] )
	{
		result = [GRLJSON serializeArray:value];
	}
	
	return result;
}

- (id)reverseTransformedValue:(id)value
{
	if ( value == nil )
		return nil;
	
	if ( ![value isKindOfClass:[NSData class]] )
		return nil;
	
	NSError *error = nil;
	id		json;
	
	if ( (json = [GRLJSON deserializeData:value error:&error]) == nil )
	{
		return nil;
	}
	
	return json;
}

@end
