//
//  IGStudent.h
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IGStudent : NSObject

@property (nonatomic, copy  ) NSString *Id;

@property (nonatomic, copy  ) NSString *name;

@property (nonatomic, assign) NSInteger age;

@property (nonatomic, strong) NSData *sound;


@end

NS_ASSUME_NONNULL_END
