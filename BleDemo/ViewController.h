//
//  ViewController.h
//  BleDemo
//
//  Created by ZTELiuyw on 15/8/13.
//  Copyright (c) 2015年 liuyanwei. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextField *textField;

- (IBAction)beCentral:(id)sender;
- (IBAction)bePeripheral:(id)sender;


@end

