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
#import "WMCBufferWriter.h"

@interface WMCCallManager () <WMCRecorderDelegate, NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) WMCRecorder *recorder;
@property (nonatomic, strong) STKAudioPlayer *audioPlayer;
@property (nonatomic, strong) WMCBufferWriter *bufferWriter;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL connectedAsParent;
@property (nonatomic, assign) BOOL serverApprovedConnection;

@end

@implementation WMCCallManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _recorder = [[WMCRecorder alloc] init];
        _recorder.delegate = self;
        _bufferWriter = [[WMCBufferWriter alloc] init];
    }
    return self;
}

#pragma mark - Public methods

- (void)callChildWithId:(NSInteger)childId {
    [self setupSocketConnection];
    [self sendRequestWithChildId:childId];
}

- (void)answerToCall {
    [self setupSocketConnection];
    [self connectAsChild];
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
        [_inputStream setDelegate:self];
        [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inputStream open];
        
        _outputStream = (__bridge NSOutputStream *)writeStream;
        [_outputStream setDelegate:self];
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream open];
    }
}

- (void)sendRequestWithChildId: (NSInteger)childId {
    const char dataTobeSent[] = {0xff, 0xf1, 0x1f}; //11111111 11110010 00011111 - для родителя
    uint8_t dataArray[3];
    
    for (NSInteger i = 0; i < 3; i++) {
        dataArray[i] = (uint8_t) dataTobeSent[i];
    }
    
    [_outputStream write:dataArray maxLength:sizeof(dataArray)];
    
    NSDictionary *sendData = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"gKT2NImx%2BdOO9EpJwfINmgReKUH9zg%3D%3D", @"u",
                              @(childId), @"childId", nil];
    
//    NSDictionary *sendData = [NSDictionary dictionaryWithObjectsAndKeys:
//                              @"ZOQJZ7qDMzmTiImr3zaTDQ3KCE7htw==", @"u",
//                              @"138261", @"childId", nil];
    
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
    
    _connectedAsParent = YES;
}

- (void)connectAsChild {
    const char dataTobeSent[] = {0xff, 0xf1, 0x2f}; //11111111 11110010 00101111 - для ребёнка
    uint8_t dataArray[3];
    
    for (NSInteger i = 0; i < 3; i++) {
        dataArray[i] = (uint8_t) dataTobeSent[i];
    }
    
    [_outputStream write:dataArray maxLength:sizeof(dataArray)];
    
    NSDictionary *sendData = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"aupt4hBJOYsTDPE3vdp%2BT6NrdL3Y3w%3D%3D", @"u", nil];
    
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
    
    _connectedAsParent = NO;
}

#pragma mark WMCRecorderDelegate

- (void)recorderDidRecordData:(NSData *)recordedData {
    if (_outputStream && [recordedData length] > 0) {
        [self.delegate sendedDatalength:(UInt32)[recordedData length]];
        [_outputStream write:[recordedData bytes] maxLength:[recordedData length]];
    }
}

#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    NSLog(@"got an event");
    
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"None!");
            break;
        }
        case NSStreamEventOpenCompleted: {
            NSLog(@"Stream opened");
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"Stream has bytes");
            if (aStream == _inputStream) {
                uint8_t buffer[1024];
                NSUInteger length;
                
                while ([_inputStream hasBytesAvailable]) {
                    length = [_inputStream read:buffer maxLength:sizeof(buffer)];
                    
                    if (length > 0) {
                        if (!_serverApprovedConnection){
                            if (buffer[0] == 0) {
                                
                                NSLog(@"Server approved connection");
                                _serverApprovedConnection = YES;
                                
                                [_recorder startRecording];
                                
                                AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                                [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                                
                            } else {
                                NSLog(@"Server NOT approved connection");
                                _serverApprovedConnection = NO;
                            }
                        }
                        
                        if (_serverApprovedConnection) {
                            if (!_isPlaying) {
                                [_bufferWriter openOutputStream];
                                
                                CFReadStreamRef playerInputStream = (__bridge CFReadStreamRef)_bufferWriter.inputStream;
                                _audioPlayer = [[STKAudioPlayer alloc] init];
                                [_audioPlayer playStream:playerInputStream];
                                _isPlaying = YES;
                            }
                        
                            [_bufferWriter addBytesToBuffer:buffer length:length];
                        }
                    }
                }
            }
            break;
        }
        case NSStreamEventErrorOccurred:
            NSLog(@"CONNECTION ERROR: Connection to the host failed!");
            break;
        case NSStreamEventEndEncountered: {
            if (aStream == _inputStream){
                NSLog(@"Stream Closed");
            }
            break;
        }
        default:
            break;
    }
}

@end
