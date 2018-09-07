//
//  ViewController.m
//  BleDemo
//
//  Created by ZTELiuyw on 15/8/13.
//  Copyright (c) 2015年 liuyanwei. All rights reserved.
//

#import "ViewController.h"
#import "BeCentralVewController.h"
#import "BePeripheralViewController.h"

@interface ViewController (){
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
    
}


- (IBAction)beCentral:(id)sender {
    BeCentralVewController *vc = [[BeCentralVewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)bePeripheral:(id)sender {
    
    NSString *idString = @"00000001";
    
    if ([_textField.text length] > 0) {
        idString = _textField.text;
    }
    
    BePeripheralViewController *vc = [[BePeripheralViewController alloc]init];
    vc.peripheralName = [NSString stringWithFormat:@"bowl%@", idString];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
