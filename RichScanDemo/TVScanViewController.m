//
//  TVScanViewController.m
//  TVScanViewController
//
//  Created by boyer on 2021/8/11.
//

#import "TVScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "TVSCanResultController.h"

#define vorerLayWidth self.view.frame.size.width-80
#define ScreenWidth     [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight    [[UIScreen mainScreen] bounds].size.height
#define IsIOS7Later [[[UIDevice currentDevice] systemVersion] floatValue] >= 7

@interface TVScanViewController ()<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
//打开摄像头
@property (strong,nonatomic)AVCaptureDevice * device;
//得到输入流
@property (strong,nonatomic)AVCaptureDeviceInput * input;
//得到输出流
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
//扫描器
@property (strong,nonatomic)AVCaptureSession * session;
//覆盖物
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;

@property (strong,nonatomic)AVCapturePhotoSettings *outputSettings;

//覆盖视图
@property (nonatomic, strong) UIView *overlayView;
//边框视图
@property (nonatomic, strong) UIView *ratioView;


@property (nonatomic ,strong) AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic  ,copy)   NSString *getResult;//得到的扫描结果
@end

@implementation TVScanViewController
{
    //扫描的线
    UIImageView *readLineView;
    BOOL is_have;
    BOOL is_Anmotion;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied)
    {
        // 无权限
//        [MBProgressHUD displayHudError:@"请打开相机权限!"];
        //关闭页面
        [self clcikBack:nil];
        return;
    }
    [self initDevice];
    [self createView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

#pragma mark - UIAction
-(void)resultAction:(UIButton *)btn
{
    TVSCanResultController *result = [TVSCanResultController new];
    [self.navigationController pushViewController:result animated:NO];
}
- (void)clcikBack:(UIButton *)btn
{
    is_Anmotion = true;
    if (readLineView) {
        [readLineView removeFromSuperview];
    }
    if (_session != nil) {
        [_session stopRunning];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:NO completion:NULL];
}

#pragma mark - UI层
-(void)createView
{
    UIButton *backButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"VTBack"] forState:UIControlStateNormal];
    backButton.frame=CGRectMake(0, 0, 30, 30);
    [backButton addTarget:self action:@selector(clcikBack:) forControlEvents:UIControlEventTouchUpInside];
    UIView *viewU = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [viewU addSubview:backButton];
    UIBarButtonItem *backButtonItem=[[UIBarButtonItem alloc]initWithCustomView:viewU];
    self.navigationItem.leftBarButtonItem=backButtonItem;
    
    UIButton *resultButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [resultButton setImage:[UIImage imageNamed:@"VTBack"] forState:UIControlStateNormal];
    resultButton.frame=CGRectMake(0, 0, 30, 30);
    [resultButton addTarget:self action:@selector(resultAction:) forControlEvents:UIControlEventTouchUpInside];
    UIView *viewU1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [viewU1 addSubview:resultButton];
    UIBarButtonItem *result=[[UIBarButtonItem alloc]initWithCustomView:viewU1];
    self.navigationItem.rightBarButtonItem=result;
    
    [self.view.layer insertSublayer:self.overlayView.layer atIndex:2];
    [self.view.layer insertSublayer:self.ratioView.layer atIndex:3];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    // Left side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.ratioView.frame.origin.x,
                                        self.overlayView.frame.size.height));
    // Right side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(
                                        self.ratioView.frame.origin.x + self.ratioView.frame.size.width,
                                        0,
                                        self.overlayView.frame.size.width - self.ratioView.frame.origin.x - self.ratioView.frame.size.width,
                                        self.overlayView.frame.size.height));
    // Top side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0, 0,
                                        self.overlayView.frame.size.width,
                                        self.ratioView.frame.origin.y));
    // Bottom side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0,
                                        self.ratioView.frame.origin.y + self.ratioView.frame.size.height,
                                        self.overlayView.frame.size.width,
                                        self.overlayView.frame.size.height - self.ratioView.frame.origin.y + self.ratioView.frame.size.height));
    maskLayer.path = path;
    self.overlayView.layer.mask = maskLayer;
    CGPathRelease(path);
}

-(UIView *)overlayView
{
    if (!_overlayView) {
        _overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
        _overlayView.alpha = 0.5;
        _overlayView.backgroundColor = [UIColor blackColor];
        _overlayView.userInteractionEnabled = true;
        _overlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, ((ScreenHeight)-vorerLayWidth)/2+ScreenWidth, ScreenWidth, 40)];
        label.text = @"将设备二维码放入框内，自动扫描";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.lineBreakMode = 0;
        label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14];
        [_overlayView addSubview:label];
    }
    return _overlayView;
}

-(UIView *)ratioView
{
    if (!_ratioView) {
        _ratioView = [[UIView alloc] initWithFrame:CGRectMake(40, ((ScreenHeight)-vorerLayWidth)/2 + 66, vorerLayWidth, vorerLayWidth)];
        _ratioView.backgroundColor = [UIColor clearColor];
        _ratioView.autoresizingMask = UIViewAutoresizingNone;
        
        UIImageView *ScanQR1 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"VTScanTranslation1"]];
        ScanQR1.frame = CGRectMake(0, 0, 30, 30);
        [_ratioView addSubview:ScanQR1];
        
        
        UIImageView *ScanQR2 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"VTScanTranslation2"]];
        ScanQR2.frame = CGRectMake(vorerLayWidth-30, 0, 30, 30);
        [_ratioView addSubview:ScanQR2];
        
        UIImageView *ScanQR3 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"VTScanTranslation3"]];
        ScanQR3.frame = CGRectMake(0, vorerLayWidth-30, 30, 30);
        [_ratioView addSubview:ScanQR3];
        
        UIImageView *ScanQR4 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"VTScanTranslation4"]];
        ScanQR4.frame = CGRectMake(vorerLayWidth-30,vorerLayWidth-30, 30, 30);
        [_ratioView addSubview:ScanQR4];
    }
    return _ratioView;
}

//初始化扫描的
- (void)initDevice
{
    CGRect  rect = CGRectMake(40, ((ScreenHeight)-vorerLayWidth)/2, vorerLayWidth, 66);
    if (readLineView) {
        [readLineView removeFromSuperview];
    }
    readLineView = [[UIImageView alloc] initWithFrame:rect];
    //readLineView.backgroundColor = [UIColor greenColor];
    readLineView.image = [UIImage imageNamed:@"tvScanLine"];
    [UIView animateWithDuration: 2.0
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         //修改fream的代码写在这里
                         readLineView.frame =CGRectMake(40, ((ScreenHeight)-vorerLayWidth)/2+vorerLayWidth-50, vorerLayWidth, 66);
                         [readLineView setAnimationRepeatCount:0];
                     }
                     completion:^(BOOL finished){
                         if (!is_Anmotion) {
                             [self initDevice];
                         }
    }];
    if (!is_have)
    {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
        
        _output = [[AVCaptureMetadataOutput alloc]init];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        // 设置识别区域 这个值是按比例0~1设置，而且X、Y要调换位置，width、height调换位置
        CGRect cropRect2 =CGRectMake((ScreenWidth-(vorerLayWidth))/2, ((ScreenHeight-88)-(vorerLayWidth))/2, (vorerLayWidth), (vorerLayWidth));
        _output.rectOfInterest = CGRectMake(cropRect2.origin.y/ScreenHeight, cropRect2.origin.x/ScreenWidth, (vorerLayWidth)/ScreenHeight, (vorerLayWidth)/ScreenWidth);
        
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.output]) {
            [_session addOutput:self.output];
        }
        
        // 添加视频输出
        _videoDataOutput = [AVCaptureVideoDataOutput new];
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [_videoDataOutput setVideoSettings:rgbOutputSettings];
        // 代理方法会提供额外的时间用于处理样本，但会增加内存消耗
        [_videoDataOutput setAlwaysDiscardsLateVideoFrames:NO];
        if ([_session canAddOutput:_videoDataOutput]) {
            [_session addOutput:_videoDataOutput];
        }
      _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,//二维码
                                      //以下为条形码，如果项目只需要扫描二维码，下面都不要写
                                      AVMetadataObjectTypeEAN13Code,
                                      AVMetadataObjectTypeEAN8Code,
                                      AVMetadataObjectTypeUPCECode,
                                      AVMetadataObjectTypeCode39Code,
                                      AVMetadataObjectTypeCode39Mod43Code,
                                      AVMetadataObjectTypeCode93Code,
                                      AVMetadataObjectTypeCode128Code,
                                      AVMetadataObjectTypePDF417Code];
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _preview.frame =self.view.bounds;
        //CGRectMake(40, 85, vorerLayWidth, vorerLayWidth);
        [self.view.layer insertSublayer:_preview atIndex:0];
        [_session startRunning];
        is_have = YES;
    }
    
    [self.view.layer insertSublayer:readLineView.layer atIndex:1];
    
}

#pragma mark -
//得到扫描结果进行处理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *strValue;
    if ([metadataObjects count]>0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        strValue = metadataObject.stringValue;
    }
    self.getResult = strValue;
    [_session stopRunning];
    //判断是否是连接
    is_Anmotion = true;//防止死循环
    TVSCanResultController *result = [TVSCanResultController new];
    result.tvCode = strValue;
    [self.navigationController pushViewController:result animated:NO];
}
@end
