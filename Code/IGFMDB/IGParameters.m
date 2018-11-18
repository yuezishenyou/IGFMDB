//
//  IGParameters.m
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import "IGParameters.h"

@interface IGParameters ()

@property (nonatomic, strong) NSMutableArray<NSString *> *andParameters;    // and参数
@property (nonatomic, strong) NSMutableArray<NSString *> *orParameters;     // or参数
@property (nonatomic, copy)   NSString *orderString;                        // 排序语句


@end

@implementation IGParameters

- (NSMutableArray<NSString *> *)andParameters {
    if (!_andParameters) {
        _andParameters = [NSMutableArray array];
    }
    
    return _andParameters;
}

- (NSMutableArray<NSString *> *)orParameters {
    if (!_orParameters) {
        _orParameters = [NSMutableArray array];
    }
    
    return _orParameters;
}

- (NSString *)whereParameters {
    if (_whereParameters) {
        return _whereParameters;
    } else {
        NSMutableString *string = [NSMutableString string];
        NSString *andString = [self.andParameters componentsJoinedByString:@" and "];
        NSString *orString  = [self.orParameters componentsJoinedByString:@" or "];
        if (andString && andString.length > 0) {
            [string appendFormat:@"%@", andString];
        }
        
        if (orString && orString.length > 0) {
            [string appendFormat:@"%@%@", (string.length > 0 ? @" or " : @""), orString];
        }
        
        if (self.orderString) {
            [string appendFormat:@" %@", self.orderString];
        }
        
        if (self.limitCount > 0) {
            [string appendFormat:@" limit %ld", (long)self.limitCount];
        }
        
        return (NSString *)(string.length > 0 ? string : nil);
    }
}






/**
 *  and(&&，与)操作
 */
- (void)andWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(IGParametersRelationType)relationType {
    
    if ([value isKindOfClass:[NSString class]] && relationType != IGParametersRelationTypeLike) {
        
        value = [NSString stringWithFormat:@"'%@'",value]; //如果是字符串， 外面会加 单引号
    }
    
    
    NSString *string = nil;
    switch (relationType) {
        case IGParametersRelationTypeEqualTo:
            string = [NSString stringWithFormat:@"%@ = %@", column, value];
            break;
        case IGParametersRelationTypeUnequalTo:
            string = [NSString stringWithFormat:@"%@ != %@", column, value];
            break;
        case IGParametersRelationTypeGreaterThan:
            string = [NSString stringWithFormat:@"%@ > %@", column, value];
            break;
        case IGParametersRelationTypeGreaterThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ >= %@", column, value];
            break;
        case IGParametersRelationTypeLessThan:
            string = [NSString stringWithFormat:@"%@ < %@", column, value];
            break;
        case IGParametersRelationTypeLessThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ <= %@", column, value];
            break;
        case IGParametersRelationTypeLike:
        {
            //左右都要模糊 %%%@%%
            //左模糊 %%%@
            //右模糊 %@%%
            string = [NSString stringWithFormat:@"%@ like '%@%%' ", column, value];
        }
            break;
        default:
            break;
    }
    if (string) {
        [self.andParameters addObject:string];
    }
}




/**
 *  or(||，或)操作
 */
- (void)orWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(IGParametersRelationType)relationType {
    
    NSString *string = nil;
    switch (relationType) {
        case IGParametersRelationTypeEqualTo:
            string = [NSString stringWithFormat:@"%@ = %@", column, value];
            break;
        case IGParametersRelationTypeUnequalTo:
            string = [NSString stringWithFormat:@"%@ != %@", column, value];
            break;
        case IGParametersRelationTypeGreaterThan:
            string = [NSString stringWithFormat:@"%@ > %@", column, value];
            break;
        case IGParametersRelationTypeGreaterThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ >= %@", column, value];
            break;
        case IGParametersRelationTypeLessThan:
            string = [NSString stringWithFormat:@"%@ < %@", column, value];
            break;
        case IGParametersRelationTypeLessThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ <= %@", column, value];
            break;
        default:
            break;
    }
    if (string) {
        [self.orParameters addObject:string];
    }
}




/**
 *  设置排序结果
 */
- (void)orderByColumn:(NSString * _Nonnull)column orderType:(IGParametersOrderType)orderType {
    
    if (orderType == IGParametersOrderTypeAsc) {
        self.orderString = [NSString stringWithFormat:@"order by %@ asc", column];
    } else if (orderType == IGParametersOrderTypeDesc) {
        self.orderString = [NSString stringWithFormat:@"order by %@ desc", column];
    }
}







@end
