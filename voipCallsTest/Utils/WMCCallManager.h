//
//  WMCCallManager.h
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 03.04.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMCCallManager;

@protocol WMCCallManagerDelegate <NSObject>



@end

@interface WMCCallManager : NSObject

- (void)callChildWithId: (NSInteger)childId;
- (void)answerToCall;
- (void)cancelCurrentCall;

@end
