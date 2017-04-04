//
//  ViewController.m
//  voipCallsTest
//
//  Created by Aleksandr Smirnov on 03.04.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import "ViewController.h"
#import "WMCCallManager.h"

@interface ViewController () <WMCCallManagerDelegate>

@property (nonatomic, strong) WMCCallManager *callManager;
@property (nonatomic, assign) UInt32 sendedDataLength;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _callManager = [[WMCCallManager alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)callAction:(id)sender {
    [_buttonCall setEnabled:NO];
    [_buttonCall setTitle:@"Звоним ребёнку" forState:UIControlStateDisabled];
    [_roleSwitcher setEnabled:NO];
    [_callManager callChildWithId:261473];
}

- (IBAction)answerAction:(id)sender {
    [_buttonAnswer setEnabled:NO];
    [_buttonAnswer setTitle:@"Отвечаем родителю" forState:UIControlStateDisabled];
    [_roleSwitcher setEnabled:NO];
    [_callManager answerToCall];
}

- (IBAction)switchAction:(id)sender {
    if (_roleSwitcher.on) {
        [_buttonCall setEnabled:NO];
        [_buttonAnswer setEnabled:YES];
    } else {
        [_buttonCall setEnabled:YES];
        [_buttonAnswer setEnabled:NO];
    }
}

- (void)sendedDatalength:(UInt32)length {
    _sendedDataLength += length;
    [_labelMain setText:[NSString stringWithFormat:@"%u", (unsigned int)_sendedDataLength]];
}

@end
