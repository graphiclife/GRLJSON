//
//	grl_json_utilities.c
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

#include "grl_json_utilities.h"

#include <stdlib.h>

struct grl_json_string *grl_json_quoted_strcpy ( struct grl_json_parse_context *context, char *string, long length )
{
	struct grl_json_string	*json_string = (struct grl_json_string *) grl_json_malloc( context, sizeof(struct grl_json_string) );
	unsigned short			*buffer = (unsigned short *) grl_json_malloc( context, sizeof(unsigned short) * length );
	unsigned short			*p, ucs2 = 0;
	unsigned long			i, j, ucs4 = 0, ucs4_tmp = 0, ucs4_h, ucs4_l;
	enum					{ NORMAL = 0, ESCAPE, UNICODE } state = NORMAL;
	int						shift, digit, ucs4_state = 0, ucs4_bytes = 1;
	char					*s, c;
	
	for ( i = 0, s = string, p = buffer ; i < length ; i++ )
	{
		c = *s++;
		
		switch ( state )
		{
			case NORMAL:
				switch ( c )
				{
					case '"':
						break;
						
					case '\\':
						state = ESCAPE;
						break;
						
					default:
						if ( ucs4_state == 0 )
						{
							if ( (c & 0x80) == 0 )
							{
								*p++ = (unsigned short) c;
							}
							else if ( (0xE0 & c) == 0xC0 )
							{
								ucs4 = (unsigned long) c;
								ucs4 = (ucs4 & 0x1F) << 6;
								ucs4_state = 1;
								ucs4_bytes = 2;
							}
							else if ( (0xF0 & c) == 0xE0 )
							{
								ucs4 = (unsigned long) c;
								ucs4 = (ucs4 & 0x0F) << 12;
								ucs4_state = 2;
								ucs4_bytes = 3;
							}
							else if ( (0xF8 & c) == 0xF0 )
							{
								ucs4 = (unsigned long) c;
								ucs4 = (ucs4 & 0x07) << 18;
								ucs4_state = 3;
								ucs4_bytes = 4;
							}
							else if ( (0xFC & c) == 0xF8 )
							{
								ucs4 = (unsigned long) c;
								ucs4 = (ucs4 & 0x03) << 24;
								ucs4_state = 4;
								ucs4_bytes = 5;
							}
							else if ( (0xFE & c) == 0xFC )
							{
								ucs4 = (unsigned long) c;
								ucs4 = (ucs4 & 1) << 30;
								ucs4_state = 5;
								ucs4_bytes = 6;
							}
							else
							{
								context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
								
								return NULL;
							}
						}
						else
						{
							if ( (0xC0 & c) == 0x80 )
							{
								shift = (ucs4_state - 1) * 6;
								
								ucs4_tmp = (unsigned long) c;
								ucs4_tmp = (ucs4_tmp & 0x0000003F) << shift;
								
								ucs4 |= ucs4_tmp;
								
								ucs4_state -= 1;
								
								if ( ucs4_state == 0 )
								{
									if ( (ucs4_bytes == 2) && (ucs4 < 0x0080) )
									{
										context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
										
										return NULL;
									}
									
									if ( (ucs4_bytes == 3) && (ucs4 < 0x0800) )
									{
										context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
										
										return NULL;
									}
									
									if ( (ucs4_bytes == 4) && (ucs4 < 0x10000) )
									{
										context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
										
										return NULL;
									}
									
									if ( (ucs4_bytes > 4) )
									{
										context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
										
										return NULL;
									}
									
									if ( ( (ucs4 & 0xFFFFF800) == 0xD800 ) || (ucs4 > 0x10FFFF) )
									{
										context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
										
										return NULL;
									}
									
									if ( ucs4 > 0xFFFF )
									{
										ucs4_h = ucs4 - 0x10000;
										ucs4_l = 0;
										
										for ( j = 0 ; j < 10 ; j++, (ucs4_h >>= 1) )
										{
											ucs4_l |= (( ucs4_h & 0x1 ) << j);
										}
										
										*p++ = (unsigned short) ( 0xD800 | ucs4_h );
										*p++ = (unsigned short) ( 0xDC00 | ucs4_l );
									}
									else if ( ucs4 != 0xFEFF )
									{
										*p++ = (unsigned short) ucs4;
									}

									ucs4 = 0;
									ucs4_state = 0;
									ucs4_bytes = 1;
								}
							}
							else
							{
								context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
								
								return NULL;
							}
						}
						break;
				}
				break;
				
			case ESCAPE:
				switch ( c )
				{
					case '/':
						*p++ = (unsigned short) '/'; state = NORMAL;
						break;
						
					case '\\':
						*p++ = (unsigned short) '\\'; state = NORMAL;
						break;
						
					case '"':
						*p++ = (unsigned short) '"'; state = NORMAL;
						break;
						
					case 'r':
						*p++ = (unsigned short) '\r'; state = NORMAL;
						break;
						
					case 'n':
						*p++ = (unsigned short) '\n'; state = NORMAL;
						break;
					
					case 't':
						*p++ = (unsigned short) '\t'; state = NORMAL;
						break;
						
					case 'b':
						*p++ = (unsigned short) '\b'; state = NORMAL;
						break;
					
					case 'f':
						*p++ = (unsigned short) '\f'; state = NORMAL;
						break;
					
					case 'u':
						shift = 12; ucs2 = 0; state = UNICODE;
						break;
					
				}
				break;
				
			case UNICODE:				
				digit = c - '0';
				
				if ( !( digit >= 0 && digit <= 9 ) )
				{
					digit = c - 'a';
					
					if ( !( digit >= 0 && digit <= 6 ) )
					{
						digit = c - 'A';
						
						if ( !( digit >= 0 && digit <= 6 ) )
						{
							digit = -1;
						}
						else
						{
							digit = 10 + digit;
						}
					}
					else
					{
						digit = 10 + digit;
					}
				}
				
				if ( digit != -1 )
				{
					ucs2 |= ( digit << shift );
				}
				else
				{
					context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
					
					return NULL;
				}
				
				shift -= 4;
				
				if ( shift < 0 )
				{
					*p++ = ucs2;
					
					state = NORMAL;
				}
				break;
		}
	}
	
	if ( state != NORMAL )
	{
		context->issues = grl_json_issue_list( context, grl_json_issue( context, grl_json_issue_code_string ), context->issues );
		
		return NULL;
	}
	
	json_string->characters = buffer;
	json_string->length = p - buffer;
	
	return json_string;
}
