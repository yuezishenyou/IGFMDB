//
//  IGMainController.m
//  IGFMDB
//
//  Created by maoziyue on 2018/11/17.
//  Copyright © 2018年 maoziyue. All rights reserved.
//

#import "IGMainController.h"
#import "IGFMDB.h"

#import "IGLoginController.h"

#import "IGStudent.h"
#import "IGOrder.h"






@interface IGMainController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tbView;

@property (nonatomic, strong) NSMutableArray *dataArray;


@end

@implementation IGMainController

- (void)rightClick {
    
    IGLoginController *vc = [[IGLoginController alloc] init];
    
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.title = @"一般是登录之后创建数据库，然后其他页操作数据库";
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"登录"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(rightClick)];
    
    [self initData];

    [self initSubViews];


}

- (void)initData {
    
    self.dataArray = [[NSMutableArray alloc] init];
    
    [self.dataArray addObject:@"增-student"];
    [self.dataArray addObject:@"删-student"];
    [self.dataArray addObject:@"改-student"];
    [self.dataArray addObject:@"查-student"];
    
    [self.dataArray addObject:@"增-morder"];
    [self.dataArray addObject:@"删-morder"];
    [self.dataArray addObject:@"改-morder"];
    [self.dataArray addObject:@"查-morder"];
    
    
}



- (void)initSubViews {
    
    
    self.tbView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    
    self.tbView.delegate = self;
    
    self.tbView.dataSource = self;
    
    [self.view addSubview:self.tbView];
    
}


#pragma mark ---------------- tbView代理 -------------------------

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellId = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    
    switch (row) {
        case 0:
        {
            [self st_insertTable];
        }
            break;
        case 1:
        {
            [self st_deleteTable];
        }
            break;
        case 2:
        {
            [self st_updateTable];
        }
            break;
        case 3:
        {
            [self st_selectedTable];
        }
            break;
        case 4:
        {
            [self or_insertTable];
        }
            break;
        case 5:
        {
            [self or_deleteTable];
        }
            break;
        case 6:
        {
            [self or_updateTable];
        }
            break;
        case 7:
        {
            [self or_selectedTable];
        }
            break;
            
            
        default:
            break;
    }
    
}


- (void)st_insertTable {
 
    IGFMDB *db = [IGFMDB shareDatabase];
    
    for (int i = 0; i < 5; i++) {
        IGStudent *st = [[IGStudent alloc] init];
        st.Id = [NSString stringWithFormat:@"%d",i];
        st.name = [NSString stringWithFormat:@"毛%d",i];
        st.age = i;
        [db insertWithModel:st tableName:@"student"];
    }
    
    
//    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
//    for (int i = 10; i < 20; i++) {
//
//        IGStudent *st = [[IGStudent alloc] init];
//        st.Id = [NSString stringWithFormat:@"aaaa%d",i];
//        st.name = [NSString stringWithFormat:@"bbbb毛%d",i];
//        st.age = i;
//        [dataArray addObject:st];
//    }
//    [db insertWithModels:dataArray tableName:@"student"];

}



- (void)st_deleteTable {
    
    IGFMDB *db = [IGFMDB shareDatabase];
    
    IGParameters *parameters = [[IGParameters alloc] init];
    
    [parameters andWhere:@"Id" value:@"aaaa11" relationType:IGParametersRelationTypeEqualTo];
    
    [db deleteFromTable:@"student" whereParameters:parameters];
    
    
    //[db deleteAllDataFromTable:@"student"];
}



- (void)st_updateTable {
    
    IGFMDB *db = [IGFMDB shareDatabase];
    
    IGParameters *parameters = [[IGParameters alloc] init];
    [parameters andWhere:@"name" value:@"毛0" relationType:IGParametersRelationTypeEqualTo];
    
    [db updateTable:@"student" dictionary:@{@"age":@"100"} whereParameters:parameters];
    [db updateTable:@"student" dictionary:@{@"name":@"毛姿跃"} whereParameters:parameters];
    
}



- (void)st_selectedTable {
    

    
    IGFMDB *db = [IGFMDB shareDatabase];
    IGParameters *parameters = [[IGParameters alloc] init];
    

    // age 大于3的 前2个
    [parameters andWhere:@"age" value:@"3" relationType:IGParametersRelationTypeGreaterThan];
    
    [parameters orderByColumn:@"age" orderType:IGParametersOrderTypeDesc];
    
    parameters.limitCount = 2;
    
    NSArray *array = [db queryFromTable:@"student" model:[IGStudent class] whereParameters:parameters];
    
    NSLog(@"------array:%@--------",array);
    
}








- (void)or_insertTable {
    
    IGFMDB *db = [IGFMDB shareDatabase];
    
    for (int i = 0; i < 5; i++) {
        IGOrder *or = [[IGOrder alloc] init];
        or.orderNo = [NSString stringWithFormat:@"ydx%d",i];
        or.paymentStatus = [NSString stringWithFormat:@"%d",i];
        or.price = 11.1;
        [db insertWithModel:or tableName:@"morder"];
    }
}


- (void)or_deleteTable {
    
}

- (void)or_updateTable {
    
}

- (void)or_selectedTable {
    
    IGFMDB *db = [IGFMDB shareDatabase];
    IGParameters *parameters = [[IGParameters alloc] init];
    NSArray *array = [db queryFromTable:@"morder" model:[IGOrder class] whereParameters:parameters];
    NSLog(@"----array:%@------",array);
    
    for (NSDictionary *dict in array) {
        NSNumber * price = dict[@"price"];
        float p = [price floatValue];
        NSLog(@"----price:%f------",p);
       
    }
}















@end
