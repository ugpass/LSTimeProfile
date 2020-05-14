//
//  ViewController.m
//  LSTimeProfile
//
//  Created by demo on 2020/5/11.
//  Copyright © 2020 ls. All rights reserved.
//

#import "ViewController.h"
#import "LSCatonMonitor.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
 
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableview registerClass: [UITableViewCell class] forCellReuseIdentifier: @"cell"];
    [[LSCatonMonitor shareInstance] startMonitor];
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *identify =@"cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
        if(!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identify];
        }
        if (indexPath.row % 10 == 0) {
            usleep(1 * 1000 * 1000); // 1秒
            cell.textLabel.text = @"卡了";
        }else{
            cell.textLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row];
        }
        
        return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1000;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
