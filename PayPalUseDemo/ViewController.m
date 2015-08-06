//
//  ViewController.m
//  PayPalUseDemo
//
//  Created by zezefamily on 15/8/6.
//  Copyright (c) 2015年 zezefamily. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PayPalMobile.h"
// Set the environment:
// - For live charges, use PayPalEnvironmentProduction (default).
// - To use the PayPal sandbox, use PayPalEnvironmentSandbox.
// - For testing, use PayPalEnvironmentNoNetwork.
#define kPayPalEnvironment PayPalEnvironmentNoNetwork

@interface ViewController ()<PayPalFuturePaymentDelegate,PayPalPaymentDelegate,PayPalProfileSharingDelegate,UIPopoverControllerDelegate>
{
    UIAlertView *_alterView;
}
@property(nonatomic,strong) NSString *environment;
@property(nonatomic,assign) BOOL acceptCreditCards;
@property(nonatomic,strong) NSString *resultText;

@property (nonatomic,strong) PayPalConfiguration *payPalConfig;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _alterView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    //初始化PayPal配置类（类似于一个描述文件,支付API需要）
    self.payPalConfig = [[PayPalConfiguration alloc]init];
    //设置是否支持信用卡支付
    self.payPalConfig.acceptCreditCards = YES;
    //商户公司名称
    self.payPalConfig.merchantName = @"北京咚嗒科技有限公司";
    //商户公司隐私政策
    self.payPalConfig.merchantPrivacyPolicyURL = [NSURL URLWithString:@""];
    //商户公司用户协议
    self.payPalConfig.merchantUserAgreementURL = [NSURL URLWithString:@""];
    //设置语言和区域
    self.payPalConfig.languageOrLocale = [NSLocale preferredLanguages][0];
    //选择送货方式
    self.payPalConfig.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
    
    //准备付款
    [PayPalMobile preconnectWithEnvironment:kPayPalEnvironment];
    
    NSLog(@"PayPal iOS SDK version: %@", [PayPalMobile libraryVersion]);
    
}

//提交订单
- (IBAction)submitOrder:(id)sender {
    
    //打包商品
    //商品1
    PayPalItem *item1 = [PayPalItem itemWithName:@"娃娃" withQuantity:2 withPrice:[NSDecimalNumber decimalNumberWithString:@"59.99"] withCurrency:@"USD" withSku:@"ZZ-00040"];
    //商品2
    PayPalItem *item2 = [PayPalItem itemWithName:@"充气筒" withQuantity:1 withPrice:[NSDecimalNumber decimalNumberWithString:@"5.99"] withCurrency:@"USD" withSku:@"ZZ-00055"];
    //商品3
    PayPalItem *item3 = [PayPalItem itemWithName:@"润滑油" withQuantity:1 withPrice:[NSDecimalNumber decimalNumberWithString:@"4.00"] withCurrency:@"USD" withSku:@"ZZ-00055"];
    
    NSArray *items = @[item1,item2,item3];
    
    //商品总价
    NSDecimalNumber *subtotal = [PayPalItem totalPriceForItems:items];
    
    //运费
    NSDecimalNumber *shipping = [[NSDecimalNumber alloc]initWithString:@"5.99"];
    //税费
    NSDecimalNumber *tax = [[NSDecimalNumber alloc]initWithString:@"2.50"];
    
    //整合支付款项
    PayPalPaymentDetails *paymentDetails = [PayPalPaymentDetails paymentDetailsWithSubtotal:subtotal withShipping:shipping withTax:tax];
    //所有总价(商品总价+运费+税费)
    NSDecimalNumber *total = [[subtotal decimalNumberByAdding:shipping]decimalNumberByAdding:tax];
    
    //付款
    PayPalPayment *payment = [[PayPalPayment alloc]init];
    payment.amount = total;
    payment.currencyCode = @"USD";
    payment.shortDescription = @"开放日折扣大促销";
    payment.items = items;
    payment.paymentDetails = paymentDetails;

    if(payment.processable==NO){
        //这种特殊的支付会处理的
        //比如 金额为负值 或 shortdescription是nil,processable 会返回 NO
        //此付款不会处理的，和你想要的
    }
    
    self.payPalConfig.acceptCreditCards = YES;
    
    //去付款
    PayPalPaymentViewController *paymentVC = [[PayPalPaymentViewController alloc]initWithPayment:payment configuration:self.payPalConfig delegate:self];
    [self presentViewController:paymentVC animated:YES completion:nil];
    
}
#pragma mark - 支付回调
//支付完成回调
- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment
{
    NSLog(@"PayPal 支付成功 !");
    _alterView.message = @"PayPal 支付成功";
    [_alterView show];
    
    [self sendCompletedPaymentToServer:completedPayment];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)sendCompletedPaymentToServer:(PayPalPayment *)completedPayment {
    NSLog(@"这是你的付款证明:\n\n%@\n\n 你要把这个给你的服务器确认和完成.", completedPayment.confirmation);
}
//支付取消回调
- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController
{
    NSLog(@"用户取消付款");
    _alterView.message = @"支付取消";
    [_alterView show];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}




//授权预支付
- (IBAction)PayPalFuturePayment:(id)sender {
    
    PayPalFuturePaymentViewController *futurePaymentVC = [[PayPalFuturePaymentViewController alloc]initWithConfiguration:self.payPalConfig delegate:self];
    [self presentViewController:futurePaymentVC animated:YES completion:nil];
}
#pragma mark - 预支付授权回调
- (void)payPalFuturePaymentViewController:(PayPalFuturePaymentViewController *)futurePaymentViewController didAuthorizeFuturePayment:(NSDictionary *)futurePaymentAuthorization
{
    NSLog(@"预支付授权成功！");
    _alterView.message = @"预支付授权成功";
    [_alterView show];
    
    [self sendFuturePaymentAuthorizationToServer:futurePaymentAuthorization];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
//异步提交自己的服务器
- (void)sendFuturePaymentAuthorizationToServer:(NSDictionary *)authorization {
    NSLog(@"这是您的授权:\n\n%@\n\n 把这个发送到您的服务器，以完成预支付设置.", authorization);
}
- (void)payPalFuturePaymentDidCancel:(PayPalFuturePaymentViewController *)futurePaymentViewController
{
    NSLog(@"用户取消预支付授权");
    _alterView.message = @"用户取消预支付授权";
    [_alterView show];
    [self dismissViewControllerAnimated:YES completion:nil];
}



//授权文件共享
- (IBAction)payPalProfileSharing:(id)sender {
    
    NSSet *scopeValues = [NSSet setWithArray:@[kPayPalOAuth2ScopeAddress,kPayPalOAuth2ScopeEmail,kPayPalOAuth2ScopeOpenId,kPayPalOAuth2ScopePhone]];
    PayPalProfileSharingViewController *paypalProfileVC = [[PayPalProfileSharingViewController alloc]initWithScopeValues:scopeValues configuration:self.payPalConfig delegate:self];
    [self presentViewController:paypalProfileVC animated:YES completion:nil];
    
}
#pragma mark - 授权文件共享回调
- (void)payPalProfileSharingViewController:(PayPalProfileSharingViewController *)profileSharingViewController userDidLogInWithAuthorization:(NSDictionary *)profileSharingAuthorization
{
    _alterView.message = @"PayPal 配置文件共享授权成功!";
    [_alterView show];
    
    [self sendProfileSharingAuthorizationToServer:profileSharingAuthorization];
    [self dismissViewControllerAnimated:YES completion:nil];
}
//异步提交自己的服务器
- (void)sendProfileSharingAuthorizationToServer:(NSDictionary *)authorization {
    NSLog(@"这是您的授权:\n\n%@\n\n发送这到你的服务器来完成文件共享设置.", authorization);
}
- (void)userDidCancelPayPalProfileSharingViewController:(PayPalProfileSharingViewController *)profileSharingViewController
{
    _alterView.message = @"用户取消共享授权";
    [_alterView show];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
