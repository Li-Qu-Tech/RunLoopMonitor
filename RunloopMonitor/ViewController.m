//
//  ViewController.m
//  RunloopMonitor
//
//  Created by xx on 2021/9/22.
//

#import "ViewController.h"

#import "Monitor.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[Monitor shareInstance] startMonitor];
    
    [self loadTableView];
}

- (void)loadTableView {
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.bounces = NO;
    _tableView.rowHeight = 44;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _tableView.center = self.view.center;
    _tableView.bounds = self.view.bounds;
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    NSString *text = [NSString stringWithFormat:@"cell - %ld",indexPath.row];
    
    if (indexPath.row % 5 == 0) {//每5行休眠0.5秒
        usleep(500*1000);
    
        text = @"这个操作很复杂，我需要执行一些时间";
    }
    
    cell.textLabel.text = text;
    cell.textLabel.textColor = [UIColor blackColor];
    
    return cell;
}

@end
