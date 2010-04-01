//
//  GRLJSONCoder.h
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

#import <Foundation/Foundation.h>

@protocol GRLJSONCoding;

typedef enum
{
	kGRLJSONObjectTypeSingle,
	kGRLJSONObjectTypeObject,
	kGRLJSONObjectTypeArray
} GRLJSONObjectType;

@interface GRLJSONCoder : NSObject
{
@private
	void *_context;
	id _coders;
}

- (void)encodeRootObject:(GRLJSONObjectType)objectType;

- (void)encodeNull;
- (void)encodeNullForKey:(NSString *)key;

- (void)encodeBool:(BOOL)flag;
- (void)encodeBool:(BOOL)flag forKey:(NSString *)key;

- (void)encodeNumber:(NSNumber *)number;
- (void)encodeNumber:(NSNumber *)number forKey:(NSString *)key;

- (void)encodeString:(NSString *)string;
- (void)encodeString:(NSString *)string forKey:(NSString *)key;

- (void)encodeObject:(id <GRLJSONCoding>)object;
- (void)encodeObject:(id <GRLJSONCoding>)object forKey:(NSString *)key;

- (void)encodeArray:(NSArray *)array;
- (void)encodeArray:(NSArray *)array forKey:(NSString *)key;

- (void)encodeDictionary:(NSDictionary *)dictionary;
- (void)encodeDictionary:(NSDictionary *)dictionary forKey:(NSString *)key;

@end
