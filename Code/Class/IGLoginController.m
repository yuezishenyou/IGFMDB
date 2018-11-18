//
//  IGLoginController.m
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import "IGLoginController.h"

#import "IGFMDB.h"
#import "IGStudent.h"
#import "IGOrder.h"

@interface IGLoginController ()

@end

@implementation IGLoginController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.title = @"登录：不同人不同数据库";
    
    
    
    
}

- (IBAction)loginButtonAction1:(id)sender {
    
    IGFMDB *db = [IGFMDB shareDatabase];
    
    [db createDBWithName:@"18217726501.sqlite"];
    
    [db createTableWithModelClass:[IGStudent class] excludedProperties:nil tableName:@"student"];
    
    [db createTableWithModelClass:[IGOrder class] excludedProperties:@[@"paymentStatus"] tableName:@"morder"];
    
    [db upgradeDatabase:@"18217726501.sqlite"];

    
    [self.navigationController popViewControllerAnimated:YES];
}



- (IBAction)loginButtonAction2:(id)sender {
    
  
    IGFMDB *db = [IGFMDB shareDatabase];
    
    [db createDBWithName:@"993056895.sqlite"];
    
    [db createTableWithModelClass:[IGOrder class] excludedProperties:nil tableName:@"morder"];
    
    [db upgradeDatabase:@"993056895.sqlite"];
    
    
    [self.navigationController popViewControllerAnimated:YES];
}




















@end
