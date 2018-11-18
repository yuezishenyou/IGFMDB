//
//  IGOrder.h
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IGOrder : NSObject

@property (nonatomic, copy  ) NSString *orderNo;

@property (nonatomic, copy  ) NSString *paymentStatus;

@property (nonatomic, assign) float price;


@end

NS_ASSUME_NONNULL_END
