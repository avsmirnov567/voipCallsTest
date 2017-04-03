//
//  WMCCallManager.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 03.04.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "WMCCallManager.h"
#import "WMCRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "STKAudioPlayer.h"

@interface WMCCallManager () <WMCRecorderDelegate, NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) WMCRecorder *recorder;
@property (nonatomic, strong) STKAudioPlayer *audioPlayer;
@property (nonatomic, assign) BOOL isRecording;

@end

@implementation WMCCallManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioPlayer = [[STKAudioPlayer alloc] init];
        _recorder = [[WMCRecorder alloc] init];
    }
    return self;
}

#pragma mark - Public methods

- (void)callChildWithId:(NSInteger)childId {
    
}

- (void)answerToCall {
    
}

- (void)cancelCurrentCall {
    
}

#pragma mark - Private methods

- (void)setupSocketConnection {
    printf("initialSocket\n");
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    NSString *ip = @"185.137.12.28";   //Your IP Address
    uint port = 12556;
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)ip, port, &readStream,  &writeStream);
    
    if (readStream && writeStream) {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        _inputStream = (__bridge NSInputStream *)readStream;
        CFReadStreamRef playerInputStream = (__bridge CFReadStreamRef)_inputStream;
        [_audioPlayer playStream:playerInputStream];
        
        _outputStream = (__bridge NSOutputStream *)writeStream;
        [_outputStream setDelegate:self];
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream open];
    }
}

- (void)sendRequestWithChildId: (NSInteger)childId {
    const char dataTobeSent[] = {0xff, 0xf2, 0x1F}; //11111111 11110010 00011111 - для родителя
    uint8_t dataArray[3];
    
    for (NSInteger i = 0; i < 3; i++) {
        dataArray[i] = (uint8_t) dataTobeSent[i];
    }
    
    [_outputStream write:dataArray maxLength:sizeof(dataArray)];
    
    NSDictionary *sendData = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"zV/E94J5dDlNW+2+sqs3VZDHGSFdjg==", @"u",
                              @"186008", @"childId", nil];
    
    //j8cRW9FNbB261nLm4vVmDJ8b6f8uCA==   - uid ребёнка
    
    NSLog (@"JSON: %@", (NSString*)sendData);
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:sendData
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    
    const char bytes[] = {([data length] >> 8 & 0xff), ([data length] & 0xff)};
    
    uint8_t bytesArray[2];
    for (NSInteger i = 0; i < 2; i++) {
        bytesArray[i] = (uint8_t) bytes[i];
    }
    
    [_outputStream write:bytesArray maxLength:sizeof(bytesArray)];
    [_outputStream write:[data bytes] maxLength:[data length]];
}

#pragma mark WMCRecorderDelegate

- (void)recorderDidRecordData:(NSData *)recordedData {
    if (_outputStream) {
        [_outputStream write:[recordedData bytes] maxLength:[recordedData length]];
    }
}

@end
