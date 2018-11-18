//
//  IGFMDB.h
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGParameters.h"

NS_ASSUME_NONNULL_BEGIN



// 数据库支持的类型(如果不满足条件以下条件，那么在后续会增加)
typedef NS_ENUM(NSUInteger, IGFMDBValueType) {
    IGFMDBValueTypeString,     // 字符串
    IGFMDBValueTypeInteger,    // 整型，长整型，bool值 都是integer
    IGFMDBValueTypeFloat,      // 浮点型,double
    IGFMDBValueTypeData,       // 二进制数据
};

// 数学运算的类型
typedef NS_ENUM(NSUInteger, IGFMDBMathType) {
    IGFMDBMathTypeSum,         // 总和
    IGFMDBMathTypeAvg,         // 平均值
    IGFMDBMathTypeMax,         // 最大值
    IGFMDBMathTypeMin,         // 最小值
};







@interface IGFMDB : NSObject

#pragma mark - 初始化

+ (instancetype) shareDatabase; //会默认创建一个db

- (void) createDBWithName:(NSString *)dbName;

- (void) createDBWithName:(NSString *)dbName path:(NSString *)dbPath;


- (void)upgradeDatabase:(NSString *)dbName;






#pragma mark - 创建表

/**
 *  根据传入的Model去创建表(推荐使用此方法)
 *  @param modelClass
    model的属性名称作为表的key值, 属性的value的类型也就是表里面的value的类型，如value可以是NSString，integer，float，bool等
 *  @param excludedProperties  被排除掉属性，这些属性被排除掉之后则不会存在数据库当中
 *  @param tableName           表名，不可以为nil
 *  @return 是否创建成功
 */
- (BOOL)createTableWithModelClass:(Class _Nonnull)modelClass
               excludedProperties:(NSArray<NSString *> * _Nullable)excludedProperties
                        tableName:(NSString * _Nonnull)tableName;







#pragma mark - 插入数据

/**
 *  插入一条数据（推荐使用）
 *  @param model        需要插入Model
 *  @param tableName    表名，不可以为nil
 *  @return             是否插入成功
 */
- (BOOL)insertWithModel:(id _Nonnull)model tableName:(NSString * _Nonnull)tableName;


/**
 *  插入多条数据
 *  @param models       需要插入的存放Model的数组。其中必须要保证数组内的Model都是同一类型的Model
 *  @param tableName    表名，不可以为nil
 *  在连续插入多条数据的时候，很有可能会出现插入不成功的情况，如果想要联调，请将shouldOpenDebugLog设为YES
 */
- (void)insertWithModels:(NSArray *)models tableName:(NSString * _Nonnull)tableName;






#pragma mark - 删除数据

/**
 *  根据参数删除表中的数据
 *  @param tableName     表的名字
 *  @param parameters    参数，IGParameters决定了sql语句"where"后面的参数。
 *  @return 是否删除成功
 */
- (BOOL)deleteFromTable:(NSString * _Nonnull)tableName whereParameters:(IGParameters *)parameters;

/**
 *  删除所有数据
 *  @param tableName    同上
 *  @return             同上
 */
- (BOOL)deleteAllDataFromTable:(NSString * _Nonnull)tableName;





#pragma mark - 更改数据

/**
 *  根据参数删除表中的数据
 *  @param tableName    表的名字,不可以为nil
 *  @param dictionary   要更新的key-value.在我经验来看，更改典里部分数据
 *  @param parameters   参数，IGParameters决定了sql语句"where"后面的参数
 */
- (BOOL)updateTable:(NSString * _Nonnull)tableName dictionary:(NSDictionary * _Nonnull)dictionary whereParameters:(IGParameters *)parameters;





#pragma mark - 查询数据

/**
 *  根据参数删除表中的数据
 *  @param tableName    表的名字,不可以为nil
 *  @param modelClass   modelClass里属性的都当key拿值
 *  @param parameters   参数，IGParameters决定了sql语句"where"后面的参数
 *  @return             返回所有符合条件的数据
 */
- (NSArray *)queryFromTable:(NSString * _Nonnull)tableName model:(Class _Nonnull)modelClass whereParameters:(IGParameters *)parameters;




#pragma mark - 除去增删改查之外常用的功能


/**
 *  表是否存在
 *  @param tableName    表的名字
 *  @return             表是否存在
 */
- (BOOL)existTable:(NSString * _Nonnull)tableName;

/**
 *  为一个表增加字段
 *  @param tableName    表的名字
 *  @param column       要增加的字段
 *  @param type         增加的字段类型
 *  @return             是否添加成功
 */
- (BOOL)alterTable:(NSString * _Nonnull)tableName column:(NSString * _Nonnull)column type:(IGFMDBValueType)type;

/**
 *  删除一张表
 *  @param tableName    表的名字
 *  @return             是否删除成功
 */
- (BOOL)dropTable:(NSString * _Nonnull)tableName;

/**
 *  获取某一个表中所有的字段名
 *  @param tableName    表的名字
 *  @return             所有字段名
 */
- (NSArray<NSString *> *)getAllColumnsFromTable:(NSString * _Nonnull)tableName;

/**
 *  获取表中有多少条数据
 *  @param tableName    表的名字
 *  @param parameters   参数，IGParameters决定了sql语句"where"后面的参数
 *  @return             数据的个数
 */
- (long long int)numberOfItemsFromTable:(NSString * _Nonnull)tableName whereParameters:(IGParameters * _Nullable)parameters;

/**
 *  数学相关操作
 *  @param type         数学运算的type
 *  @param tableName    表的名字
 *  @param parameters   参数，IGParameters决定了sql语句"where"后面的参数
 *  @return             计算的值
 */
- (double)numberWithMathType:(IGFMDBMathType)type table:(NSString * _Nonnull)tableName column:(NSString * _Nonnull)column whereParameters:(IGParameters * _Nullable)parameters;





@end

NS_ASSUME_NONNULL_END
