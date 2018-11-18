//
//  IGParameters.h
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 参数相关的关系
typedef NS_ENUM(NSUInteger, IGParametersRelationType) {
    IGParametersRelationTypeEqualTo,               // 数学运算@"=",等于
    IGParametersRelationTypeUnequalTo,             // 数学运算@"!=",不等于
    IGParametersRelationTypeGreaterThan,           // 数学运算@">",大于
    IGParametersRelationTypeGreaterThanOrEqualTo,  // 数学运算@">=",大于等于
    IGParametersRelationTypeLessThan,              // 数学运算@"<",小于
    IGParametersRelationTypeLessThanOrEqualTo,     // 数学运算@"<=",小于等于
    IGParametersRelationTypeLike,                  // 字符串运算@"like",模糊查询   这个又有左右模糊之分
};

// 排序顺序
typedef NS_ENUM(NSUInteger, IGParametersOrderType) {
    IGParametersOrderTypeAsc,                      // 升序
    IGParametersOrderTypeDesc,                     // 降序
};



@interface IGParameters : NSObject

#pragma mark - sql语句当中为where之后的条件增加参数

/**
 *  筛选条件的数量限制
 */
@property (nonatomic, assign) NSInteger limitCount;

/**
 *  and(&&，与)操作
 *  @param column           数据库中表的key值
 *  @param value            column值对应的value值
 *  @param relationType     column与value之间的关系
 *  比如只执行[andWhere:@"age" value:18 relationType:IGParametersRelationTypeGreaterThan],那么where后面的参数会变成"age > 18"
 */
- (void)andWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(IGParametersRelationType)relationType;


/**
 *  or(||，或)操作
 *  @param column           数据库中表的key值
 *  @param value            column值对应的value值
 *  @param relationType     column与value之间的关系
 */
- (void)orWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(IGParametersRelationType)relationType;


/**
 *  设置排序结果
 *  @param column           排序的字段
 *  @param orderType        排序选择，有升序和降序
 *  比如执行[ orderByColumn:@"Id" orderType:IGParametersOrderTypeAsc],那么对应的sql语句就是@"order by Id asc",意思就是根据"Id"来进行升序排列
 */
- (void)orderByColumn:(NSString * _Nonnull)column orderType:(IGParametersOrderType)orderType;


/**
 *  sql语句的参数，也就是sql语句当中，where之后的参数.
 *  值得一提的是，如果设置了这个参数，那么在属性whereParameters上面的方法都无效
 *  如果不设置这个参数，那么调用此属性的get方法则会获取到以上的方法所形成的sql语句
 */
@property (nonatomic, copy)   NSString *whereParameters;










@end

NS_ASSUME_NONNULL_END
