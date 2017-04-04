//
//  ViewController.h
//  voipCallsTest
//
//  Created by Aleksandr Smirnov on 03.04.17.
//  Copyright © 2017 Line App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *buttonCall;
@property (weak, nonatomic) IBOutlet UIButton *buttonAnswer;
@property (weak, nonatomic) IBOutlet UISwitch *roleSwitcher;
@property (weak, nonatomic) IBOutlet UILabel *labelMain;

@end

