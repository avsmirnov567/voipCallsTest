//
//  NSData+ASBinary.h
//  aacEncodingTest
//
//  File created by Aleksandr Smirnov on 13.03.17. Used code created by Adam Kaplan on 4/15/15.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ASBinary)

/** Returns a bit-string representation of this data, formatted as 1s and 0s grouped by 8-bits. */
- (NSString *)binaryString;

@end
