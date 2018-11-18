//
//  IGFMDB.m
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import "IGFMDB.h"
#import <FMDB/FMDB.h>
#import <objc/runtime.h>

#ifdef DEBUG
#define debugLog(...)    NSLog(__VA_ARGS__)
#define debugMethod()    NSLog(@"%s", __func__)
#define debugError()     NSLog(@"Error at %s Line:%d", __func__, __LINE__)
#else
#define debugLog(...)
#define debugMethod()
#define debugError()
#endif

#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define kDatabaseVersionKey     @"YH_DBVersion" //数据库版本


static NSString * const DEFAULT_DB_NAME = @"database.sqlite";
static NSString * const ig_primary_key  = @"primaryId";     // 主键
static NSString * const ig_sql_text     = @"text";          // 字符串
static NSString * const ig_sql_real     = @"real";          // 浮点型
static NSString * const ig_sql_blob     = @"blob";          // 二进制
static NSString * const ig_sql_integer  = @"integer";       // 整型



@interface IGFMDB ()

@property (strong, nonatomic) FMDatabaseQueue * dbQueue;

@property (nonatomic, assign) int currentDBVersion;  //当要升级就给这个值赋值

@end

@implementation IGFMDB
{
    // 保证创建sql语句时的线程安全
    dispatch_semaphore_t _sqlLock;
}


- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

// 校验表名
- (BOOL)checkTableName:(NSString *)tableName {
    if (tableName == nil || tableName.length == 0 || [tableName rangeOfString:@" "].location != NSNotFound) {
        debugLog(@"ERROR, table name: %@ format error.", tableName);
        return NO;
    }
    return YES;
}

- (BOOL)isStringVaild:(id)object  {
     return [object isKindOfClass:[NSString class]] && ((NSString*)object).length > 0;
}




#pragma mark -单利，创建默认DB

+ (instancetype) shareDatabase {
    static IGFMDB *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[IGFMDB alloc] init];
        }
    });
    return _instance;
}

- (instancetype) init {
    if (self = [super init]) {
        _currentDBVersion = 0;
        _sqlLock = dispatch_semaphore_create(1);
        [self createDBWithName:DEFAULT_DB_NAME];
    }
    return self;
}




#pragma mark -创建DB方法

- (void) createDBWithName:(NSString *)dbName {
    
    [self createDBWithName:dbName path:PATH_OF_DOCUMENT];
}

- (void) createDBWithName:(NSString *)dbName path:(NSString *)dbPath {
    
    NSString *path = [dbPath stringByAppendingPathComponent:dbName];
    
    debugLog(@"-----path: %@ \n-----",path);
    
    if (_dbQueue) {
        [self close];
    }
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    
    

    
}

#pragma mark -数据库升级模块
//这样写还是很好的， 不可以参数暴露在外面
- (void)upgradeDatabase:(NSString *)dbName
{
    int dbVersion = [self getDBVersion:dbName];
    
    if (_currentDBVersion > dbVersion) {
        //debugLog(@"-----升级操作: 为student表 增加个sound------");
        if ([self existTable:@"student"]) {
            [self alterTable:@"student" column:@"sound" type:IGFMDBValueTypeData];
            [self setDBVersion:_currentDBVersion dbName:dbName];
            //debugLog(@"-----升级操作成功-----");
        } 
    }
    
    
}




- (int)getDBVersion:(NSString *)dbName {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:kDatabaseVersionKey];
}

- (void)setDBVersion:(int)version dbName:(NSString *)dbName {
    [[NSUserDefaults standardUserDefaults] setInteger:version forKey:kDatabaseVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}






#pragma mark -创建表

- (BOOL)createTableWithModelClass:(Class _Nonnull)modelClass excludedProperties:(NSArray<NSString *> * _Nullable)excludedProperties tableName:(NSString * _Nonnull)tableName {
    
    if (![self checkTableName:tableName]) {
        return NO;
    }

    IGLock(_sqlLock);
    NSString *pkID = ig_primary_key;
    NSMutableString *sqliteString = [NSMutableString  stringWithFormat:@"create table if not exists %@ (%@ integer primary key",tableName, pkID];
    IGUnLock(_sqlLock);

    NSDictionary *properties = [self getPropertiesWithModel:modelClass]; //获取model的所有属性以及类型
    for (NSString *key in properties) {
        if ([excludedProperties containsObject:key]) {
            continue;
        }
        [sqliteString appendFormat:@", %@ %@", key, properties[key]];
    }
    [sqliteString appendString:@")"];

    __block BOOL res ;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        res = [db executeUpdate:sqliteString];
    }];

    return res;
}

#pragma mark - 插入数据

- (BOOL)insertWithModel:(id _Nonnull)model tableName:(NSString * _Nonnull)tableName {
    
    if (![self checkTableName:tableName]) {
        return NO;
    }
    
    if (model)
    {
        IGLock(_sqlLock);
        NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"insert into %@ (", tableName];
        NSArray *columns =  [self getAllColumnsFromTable:tableName dbQueue:self.dbQueue isIncludingPrimaryKey:NO];
        NSMutableArray *values = [NSMutableArray array];
        for (int index = 0; index < columns.count; index++) {
            [values addObject:@"?"];
        }
        [sqliteString appendFormat:@"%@) values (%@)", [columns componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
        IGUnLock(_sqlLock);
        
        
        __block BOOL isSuccess ;
        NSArray *arguments = [self getValuesFromModel:model columns:columns];
        [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            isSuccess = [db executeUpdate:sqliteString withArgumentsInArray:arguments];
        }];
        if (!isSuccess) {
            debugLog(@"----插入失败----");
        }
        else {
            debugLog(@"----插入成功----");
        }
        return  isSuccess;
        
    }
    else {
        
        return NO;
    }
    
    
}


- (void)insertWithModels:(NSArray *)models tableName:(NSString * _Nonnull)tableName {
    
    if (![self checkTableName:tableName]) return;
    
    
    if (models && [models isKindOfClass:[NSArray class]] && models.count > 0)
    {
        
        IGLock(_sqlLock);
        NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"insert into %@ (", tableName];
        NSArray *columns = [self getAllColumnsFromTable:tableName dbQueue:self.dbQueue isIncludingPrimaryKey:NO];
        NSMutableArray *values = [NSMutableArray array];
        for (int index = 0; index < columns.count; index++) {
            [values addObject:@"?"];
        }
        [sqliteString appendFormat:@"%@) values (%@)", [columns componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
        IGUnLock(_sqlLock);
        
        
        for (id model in models) {
            
            __block BOOL isSuccess;
            NSArray *arguments = [self getValuesFromModel:model columns:columns];
            [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
                isSuccess = [db executeUpdate:sqliteString withArgumentsInArray:arguments];
            }];
            if (!isSuccess) {
                debugLog(@"----插入失败----");
            }
        }
    }
    else {
        
        debugLog(@"----插入数据的数据源有误----");
    }
    
}






#pragma mark - 删除数据

- (BOOL)deleteFromTable:(NSString * _Nonnull)tableName whereParameters:(IGParameters *)parameters {

    if (![self checkTableName:tableName]) return NO;
    
    
    if (![self isStringVaild:parameters.whereParameters]) {
        debugLog(@"-----单条删除没有条件------");
        return NO;
    }
    
    
    IGLock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"delete from %@", tableName];
    if (parameters) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    IGUnLock(_sqlLock);
    
    
    __block BOOL isSuccess ;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        isSuccess = [db executeUpdate:sqliteString];
    }];
    if (!isSuccess) {
        debugLog(@"----删除失败----");
    }
    return isSuccess;
}


- (BOOL)deleteAllDataFromTable:(NSString * _Nonnull)tableName {

    if (![self checkTableName:tableName]) return NO;
    

    IGLock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"delete from %@", tableName];
    IGUnLock(_sqlLock);
    
    
    __block BOOL isSuccess ;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        isSuccess = [db executeUpdate:sqliteString];
    }];
    if (!isSuccess) {
        debugLog(@"----删除失败----");
    }
    return isSuccess;
    
}








#pragma mark - 更改数据

- (BOOL)updateTable:(NSString * _Nonnull)tableName dictionary:(NSDictionary * _Nonnull)dictionary whereParameters:(IGParameters *)parameters {

    if (![self checkTableName:tableName]) return NO;
    
    if (dictionary.allKeys.count <= 0) {
        debugLog(@"----要更新的数据不能为nil----");
        return NO;
    }
    

    IGLock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"update %@ set ", tableName];
    NSMutableArray *values = [NSMutableArray array];
    for (NSString *key in dictionary) {
        if ([key isEqualToString:ig_primary_key]) {
            continue;
        }
        [sqliteString appendFormat:@"%@ = ? ", key];
        [values addObject:dictionary[key]];
    }
    IGUnLock(_sqlLock);

    
    if (values.count > 0) {
        
        if ([self isStringVaild:parameters.whereParameters]) {
            [sqliteString appendFormat:@"where %@", parameters.whereParameters];
        } else {
            debugLog(@"sql语句当中,where后面的参数为nil");
            [sqliteString deleteCharactersInRange:NSMakeRange(sqliteString.length-1, 1)];
        }

        __block BOOL isSuccess;
        [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            isSuccess = [db executeUpdate:sqliteString withArgumentsInArray:values];
        }];
        
        if (!isSuccess) {
            debugLog(@"-----更改数据------");
        }
        return isSuccess;
        
    } else {

        debugLog(@"要更新的数据不能仅仅含有主键");
        return NO;
    }
}





#pragma mark - 查询数据

- (NSArray *)queryFromTable:(NSString * _Nonnull)tableName model:(Class _Nonnull)modelClass whereParameters:(IGParameters *)parameters {

    
    if (![self checkTableName:tableName]) return nil;
    

    IGLock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"select * from %@", tableName];
    if (parameters && [self isStringVaild:parameters.whereParameters]) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    IGUnLock(_sqlLock);
    
    
    __block NSMutableArray *array = [NSMutableArray array];
    NSDictionary *properties = [self getPropertiesWithModel:modelClass];
    
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *res = [db executeQuery:sqliteString];
        while ([res next]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (NSString *key in properties) {
                NSString *type = properties[key];
                // 根据数据类型从数据库当中获取数据
                if ([type isEqualToString:ig_sql_text]) {
                    // 字符串
                    dict[key] = [res stringForColumn:key] ? : @"";
                } else if ([type isEqualToString:ig_sql_integer]) {
                    // 整型
                    dict[key] = @([res longLongIntForColumn:key]);
                } else if ([type isEqualToString:ig_sql_real]) {
                    // 浮点型
                    dict[key] = @([res doubleForColumn:key]);
                } else if ([type isEqualToString:ig_sql_blob]) {
                    // 二进制
                    id value = [res dataForColumn:key];
                    if (value) {
                        dict[key] = value;
                    }
                }
            }
            [array addObject:dict];
        }
        
    }];
    
    return (array.count > 0 ? array : nil);
    
}




#pragma mark - 除去增删改查之外常用的功能



/**
 *  表是否存在
 *  @param tableName    表的名字
 *  @return             表是否存在
 */
- (BOOL)existTable:(NSString * _Nonnull)tableName {

    if (![self checkTableName:tableName]) return NO;
    
    __block BOOL isExist;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
         FMResultSet *res = [db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
        while ([res next]) {
            NSInteger count = [res intForColumn:@"count"];
            isExist = ((count == 0) ? NO : YES);
        }
    }];
    
    return isExist;

}


/**
 *  为一个表增加字段
 *  @param tableName    表的名字
 *  @param column       要增加的字段
 *  @param type         增加的字段类型
 *  @return             是否添加成功
 */
- (BOOL)alterTable:(NSString * _Nonnull)tableName column:(NSString * _Nonnull)column type:(IGFMDBValueType)type {

    if (![self checkTableName:tableName]) return NO;
    
    if (![self isStringVaild:column]) {
        debugLog(@"---要新增的column必须是字符串，且不能为nil-----");
        return NO;
    }
    
    
    IGLock(_sqlLock);
    NSString *typeString = nil;
    switch (type) {
        case IGFMDBValueTypeString:
            typeString = ig_sql_text;
            break;
        case IGFMDBValueTypeInteger:
            typeString = ig_sql_integer;
            break;
        case IGFMDBValueTypeFloat:
            typeString = ig_sql_real;
            break;
        case IGFMDBValueTypeData:
            typeString = ig_sql_blob;
            break;
        default:
            typeString = @"";
            break;
    }
    NSString *sqliteString = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, column, typeString];
    IGUnLock(_sqlLock);
    
    __block BOOL isSuccess;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        isSuccess = [db executeUpdate:sqliteString];
    }];
    
    return isSuccess;
    
    
}


/**
 *  删除一张表
 *  @param tableName    表的名字
 *  @return             是否删除成功
 */
- (BOOL)dropTable:(NSString * _Nonnull)tableName {

    if (![self checkTableName:tableName]) return NO;
    
    IGLock(_sqlLock);
    NSString *sqliteString = [NSString stringWithFormat:@"drop table %@", tableName];
    IGUnLock(_sqlLock);
    
    __block BOOL isSuccess ;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        isSuccess = [db executeUpdate:sqliteString];
    }];
    
    return isSuccess;
    
}

/**
 *  获取某一个表中所有的字段名
 *  @param tableName    表的名字
 *  @return             所有字段名
 */
- (NSArray<NSString *> *)getAllColumnsFromTable:(NSString * _Nonnull)tableName {
    
    if (![self checkTableName:tableName]) return nil;
    
    return [self getAllColumnsFromTable:tableName dbQueue:self.dbQueue isIncludingPrimaryKey:YES];
}


/**
 *  获取表中有多少条数据
 *  @param tableName    表的名字
 *  @param parameters   参数，IGParameters决定了sql语句"where"后面的参数
 *  @return             数据的个数
 */
- (long long int)numberOfItemsFromTable:(NSString * _Nonnull)tableName whereParameters:(IGParameters * _Nullable)parameters {

    if (![self checkTableName:tableName]) return 0;
    
    IGLock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"select count(*) as 'count' from %@", tableName];
    if (parameters && [self isStringVaild:parameters.whereParameters]) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    IGUnLock(_sqlLock);
    
    __block long long count ;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *res = [db executeQuery:sqliteString];
        while ([res next]) {
            count = [res longLongIntForColumn:@"count"];
        }
    }];
    return count;

}



/**
 *  数学相关操作
 *  @param type         数学运算的type
 *  @param tableName    表的名字
 *  @param parameters   参数，IGParameters决定了sql语句"where"后面的参数
 *  @return             计算的值
 */
- (double)numberWithMathType:(IGFMDBMathType)type table:(NSString * _Nonnull)tableName column:(NSString * _Nonnull)column whereParameters:(IGParameters * _Nullable)parameters {


    if (![self checkTableName:tableName]) return 0;
    
    
    if (![self isStringVaild:parameters.whereParameters]) {
        debugLog(@"---要新增的column必须是字符串，且不能为nil----");
        return 0.0;
    }
    
    IGLock(_sqlLock);
    NSMutableString *sqliteString = nil;
    NSString *operation = nil;
    switch (type) {
        case IGFMDBMathTypeSum:
            operation = @"sum";
            break;
        case IGFMDBMathTypeAvg:
            operation = @"avg";
            break;
        case IGFMDBMathTypeMax:
            operation = @"max";
            break;
        case IGFMDBMathTypeMin:
            operation = @"min";
            break;
        default:
            break;
    }
    if ([self isStringVaild:operation]) {
        sqliteString = [NSMutableString stringWithFormat:@"select %@(%@) %@Count from %@", operation, column, operation, tableName];
    } else {
        debugLog(@"----不支持当前运算----");
    }
    if (parameters) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    IGUnLock(_sqlLock);
    
    __block double value = 0.0;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *res = [db executeQuery:sqliteString];
        while ([res next]) {
            value = [res doubleForColumn:[NSString stringWithFormat:@"%@Count", operation]];
        }
    }];
    
    return value;
    

}

















































#pragma mark - 数据库相关操作

// 获取数据库里的所有元素
- (NSArray<NSString *> *)getAllColumnsFromTable:(NSString *)tableName dbQueue:(FMDatabaseQueue *)dbQueue isIncludingPrimaryKey:(BOOL)isIncluding {

    __block  NSMutableArray *columns = [NSMutableArray array];
    
    [dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *res = [db getTableSchema:tableName];
        while ([res next]) {
            NSString *columnName = [res stringForColumn:@"name"];
            if ([columnName isEqualToString:ig_primary_key] && !isIncluding) {
                 continue;
            }
            [columns addObject:columnName];
        }
    }];
    return columns;
}






#pragma mark - Private Method

/**
 *  基于runtime获取model的所有属性以及类型
 *  根据传入的ModelClass去获取所有的属性的key以及类型type，返回值的字典的key就是modelClass的属性，value就是modelClass的属性对应的type
 */
- (NSDictionary *)getPropertiesWithModel:(Class)modelClass {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList(modelClass, &count);
    for (int index = 0; index < count; index++) {
        objc_property_t property = propertyList[index];
        NSString *key = [NSString stringWithFormat:@"%s", property_getName(property)];
        NSString *type = nil;
        NSString *attributes = [NSString stringWithFormat:@"%s", property_getAttributes(property)];

        if ([attributes hasPrefix:@"T@\"NSString\""]) {
            type = ig_sql_text;
        } else if ([attributes hasPrefix:@"Tf"] || [attributes hasPrefix:@"Td"]) {
            type = ig_sql_real;
        } else if ([attributes hasPrefix:@"T@\"NSData\""]) {
            type = ig_sql_blob;
        } else if ([attributes hasPrefix:@"Ti"] || [attributes hasPrefix:@"TI"] || [attributes hasPrefix:@"Tl"] || [attributes hasPrefix:@"TL"] || [attributes hasPrefix:@"Tq"] || [attributes hasPrefix:@"TQ"] || [attributes hasPrefix:@"Ts"] || [attributes hasPrefix:@"TS"] || [attributes hasPrefix:@"TB"] || [attributes hasPrefix:@"T@\"NSNumber\""]) {
            type = ig_sql_integer;
        }

        if (type) {
            [dict setObject:type forKey:key];
        } else {
            debugLog(@"---%@----",[NSString stringWithFormat:@"不支持的属性:key = %@, attributes = %@", key, attributes]);
        }
    }

    free(propertyList);

    return dict;
}

// 根据keys获取到model里面的所有values
- (NSArray *)getValuesFromModel:(id _Nonnull)model columns:(NSArray *)columns {
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *column in columns) {
        id value = [model valueForKey:column];
        [array addObject:value ? : @""];
    }
    return array;
}


// 加锁
void IGLock(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

// 解锁
void IGUnLock(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_signal(semaphore);
}








@end
