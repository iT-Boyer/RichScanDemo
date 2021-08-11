//
//  ViewController.m
//  RichScanDemo
//
//  Created by boyer on 2021/8/11.
//

#import "ViewController.h"
#import "TVScanViewController.h"
@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)ibaScanAction:(id)sender {
    TVScanViewController *tv = [TVScanViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tv];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:NO completion:nil];
}

@end
