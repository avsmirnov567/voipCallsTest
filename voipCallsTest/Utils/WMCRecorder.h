//
//  WMCRecorder.h
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMCRecorder;

@protocol WMCRecorderDelegate <NSObject>

- (void)recorderDidRecordData: (NSData *)recordedData;

@end

@interface WMCRecorder : NSObject

@property (nonatomic) BOOL isRecording;
@property (nonatomic, weak) id<WMCRecorderDelegate> delegate;

- (void)startRecording;
- (void)stopRecording;

@end
