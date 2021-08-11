//
//  VTSCanResultController.m
//  VTSCanResultController
//
//  Created by boyer on 2021/8/11.
//

#import "TVSCanResultController.h"

@interface TVSCanResultController ()

@end

@implementation TVSCanResultController
{
    UILabel *msgLab;
    UIImageView *statusImgV;
    UIButton *submitBtn;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self createView];
}

-(void)createView
{
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat ViewH = [UIScreen mainScreen].bounds.size.height;
    CGFloat ViewW = [UIScreen mainScreen].bounds.size.width;
    
    UIButton *backButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"TVBlackBack"] forState:UIControlStateNormal];
    backButton.frame=CGRectMake(0, 0, 30, 30);
    [backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    UIView *viewU = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [viewU addSubview:backButton];
    UIBarButtonItem *backButtonItem=[[UIBarButtonItem alloc]initWithCustomView:viewU];
    self.navigationItem.leftBarButtonItem=backButtonItem;
    
    //statusImgV
    statusImgV = [[UIImageView alloc] initWithFrame:CGRectMake(ViewW/2-30, ViewH/2 - 60 - 20, 60, 60)];
    [self.view addSubview:statusImgV];
    //msg
    msgLab = [[UILabel alloc] initWithFrame:CGRectMake((ViewW-200)/2, ViewH/2, 200, 20)];
    msgLab.text = @"设备登录中...";
    msgLab.textAlignment = NSTextAlignmentCenter;
    msgLab.textColor = [UIColor colorWithRed:53/255.0 green:54/255.0 blue:56/255.0 alpha:1.0];
    msgLab.font = [UIFont systemFontOfSize:20];
    
    [self.view addSubview:msgLab];
    
    //msg
    submitBtn = [[UIButton alloc] initWithFrame:CGRectMake((ViewW-145)/2, ViewH - 108 - 20, 145, 40)];
    submitBtn.backgroundColor = [UIColor colorWithRed:4/255.0 green:161/255.0 blue:116/255.0 alpha:1.0];
    submitBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    submitBtn.layer.cornerRadius = 4;
    [submitBtn setTitle:@"确定" forState:UIControlStateNormal];
    
    [submitBtn addTarget:self action:@selector(submitAction:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:submitBtn];
}

-(void)submitAction:(UIButton *)btn
{
    if (!btn.isSelected) {
        //TODO: TV登录
        btn.selected = YES;
        msgLab.text = @"请求中...";
        [submitBtn setTitle:@"返回" forState:UIControlStateNormal];
        statusImgV.image = [UIImage imageNamed:@"result_false"];
        msgLab.text = @"登录失败";
        statusImgV.image = [UIImage imageNamed:@"result_true"];
        msgLab.text = @"登录成功";
    }else{
        if ([submitBtn.titleLabel.text isEqualToString:@"返回"]) {
            [self backAction:nil];
        }
    }
}

-(void)backAction:(UIButton *)btn
{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}
@end
