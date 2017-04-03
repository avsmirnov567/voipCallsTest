//
//  WMCRecorder.m
//  aacEncodingTest
//
//  Created by Aleksandr Smirnov on 13.03.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "WMCRecorder.h"
#import "WMCAACEncoder.h"

#import <AVFoundation/AVFoundation.h>

@interface WMCRecorder () <NSStreamDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, strong) AVCaptureAudioDataOutput* audioOutput;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, strong) AVCaptureConnection* audioConnection;
@property (nonatomic, strong) WMCAACEncoder *aacEncoder;

@end

@implementation WMCRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSession];
        _aacEncoder = [[WMCAACEncoder alloc] init];
    }
    return self;
}

- (void)setupSession
{
    _session = [[AVCaptureSession alloc] init];
    [self setupAudioCapture];
}

- (void)setupAudioCapture
{
    /*
     * Create audio connection
     */
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput];
    }
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void)startRecording
{
    [_session startRunning];
    self.isRecording = YES;
}

- (void)stopRecording
{
    [_session stopRunning];
    self.isRecording = NO;
}

#pragma mark AVCaptureOutputDelegate method
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_isRecording) {
        return;
    }
    // pass frame to encoders
    if (connection == _audioConnection) {
        [_aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
            [self.delegate recorderDidRecordData:encodedData];
        }];
    }
}

@end
