    //
    //  ViewController.m
    //  YQIAPTest
    //
    //  Created by problemchild on 16/8/25.
    //  Copyright © 2016年 ProblenChild. All rights reserved.
    //

#import "AHViewController.h"
#import "YQInAppPurchaseTool.h"

@interface AHViewController ()
@property (nonatomic,strong) NSMutableArray *productArray;
@property (nonatomic,strong) NSNotificationCenter* notify;
@property(nonatomic,assign) BOOL inited;

@end

@implementation AHViewController

-(NSMutableArray *)productArray{
    if(!_productArray){
        _productArray = [NSMutableArray array];
    }
    return _productArray;
}

/**
 开始
 
 @param productIDs 产品ID的Json数组的字符串形式
 @param isDebug 是否是沙盒模式
 */
- (void)startWithProductIDs:(NSString*)productIDs AndDebug:(BOOL)isDebug{
    _notify= [NSNotificationCenter defaultCenter];
        //获取单例
    YQInAppPurchaseTool *IAPTool = [YQInAppPurchaseTool defaultTool];
        // 设置是否是沙盒模式
    [IAPTool setDebug:isDebug];
        //设置代理
    [self thisAddObservers];
    
        //购买后，向苹果服务器验证一下购买结果。默认为YES。不建议关闭
        //IAPTool.CheckAfterPay = NO;
        // 讲获得到的json 数组解析成一个数据
    NSArray *json_array =  [NSJSONSerialization JSONObjectWithData:[productIDs dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
    NSMutableArray * product_IDs = [[NSMutableArray alloc] init];
    for (NSString * item in json_array) {
        [product_IDs addObject:item];
    }
        //向苹果询问哪些商品能够购买
    [IAPTool requestProductsWithProductArray:product_IDs];
}

    // 监听数据通知
- (void)thisAddObservers{
    
        // 系统错误
    [self.notify addObserver:self selector:@selector(IAPToolSysWrong) name:IAPToolSysWrong_NAME object:nil];
        // 已刷新可购买商品
    [self.notify addObserver:self selector:@selector(IAPToolGotProducts:) name:IAPToolGotProducts_NAME object:nil];
        // 购买成功
    [self.notify addObserver:self selector:@selector(IAPToolBoughtProductSuccessedWithProductID:) name:IAPToolBoughtProductSuccessedWithProductID_NAME object:nil];
        // 取消购买
    [self.notify addObserver:self selector:@selector(IAPToolCanceldWithProductID:) name:IAPToolCanceldWithProductID_NAME object:nil];
        // 重复验证
    [self.notify addObserver:self selector:@selector(IAPToolCheckRedundantWithProductID:) name:IAPToolCheckRedundantWithProductID_NAME object:nil];
        // 购买成功，开始验证购买
    [self.notify addObserver:self selector:@selector(IAPToolBeginCheckingdWithProductID:) name:IAPToolBeginCheckingdWithProductID_NAME object:nil];
        // 验证失败
    [self.notify addObserver:self selector:@selector(IAPToolCheckFailedWithProductID:) name:IAPToolCheckFailedWithProductID_NAME object:nil];
        // 恢复了已购买的商品（永久性商品）
    [self.notify addObserver:self selector:@selector(IAPToolRestoredProductID:) name:IAPToolRestoredProductID_NAME object:nil];
    
}
    // 取消监听数据通知
- (void)thisRemoveObservers{
    [self.notify removeObserver:self];
}

-(void)dealloc{
    [self thisRemoveObservers];
}

-(void)end{
    [self setInited:NO];
    [self thisRemoveObservers];
    inst= nil;
    
    NSLog(@"END");
}

#pragma mark --------YQInAppPurchaseToolDelegate
    //IAP工具已获得可购买的商品
-(void)IAPToolGotProducts:(NSNotification *)user {
    NSMutableArray * products =  [user.userInfo valueForKey:@"value"];
    
    NSLog(@" 成功获取到可购买的商品  GotProducts:%@",products);
    
    NSMutableArray * productIDs= [NSMutableArray new];
    
    for (SKProduct *product in products){
//        NSLog(@"localizedDescription:%@\nlocalizedTitle:%@\nprice:%@\npriceLocale:%@\nproductID:%@",
//              product.localizedDescription,
//              product.localizedTitle,
//              product.price,
//              product.priceLocale,
//              product.productIdentifier);
//
//        ;
//
        [productIDs addObject:[NSString stringWithFormat:@"{\"productId\":\"%@\",\"price\":\"%@\",\"localizedTitle\":\"%@\",\"localizedDescription\":\"%@\"}",product.productIdentifier,product.price,product.localizedTitle,product.localizedDescription]];
    }
    self.productArray = products;
    NSData * jsonData=  [NSJSONSerialization  dataWithJSONObject:productIDs options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    UnitySendMessage(BlankInAppPurchaseBridgeLink,"Init", [self stringToChar:jsonString]);
    [self setInited:YES];
}
    //支付失败/取消
-(void)IAPToolCanceldWithProductID:(NSNotification *)user {
    
    NSString* productID = [user.userInfo valueForKey:@"value"];
    UnitySendMessage(BlankInAppPurchaseBridgeLink, "Failed", [self stringToChar:productID]);
    NSLog(@" 购买失败  canceld:%@",productID);
}
    //支付成功了，并开始向苹果服务器进行验证（若CheckAfterPay为NO，则不会经过此步骤）
-(void)IAPToolBeginCheckingdWithProductID:(NSNotification *)user {
    
    NSString* productID = [user.userInfo valueForKey:@"value"];
    
    NSLog(@" 购买成功，正在验证购买   BeginChecking:%@",productID);
    
        //    [SVProgressHUD showWithStatus:@"购买成功，正在验证购买"];
}
    //商品被重复验证了
-(void)IAPToolCheckRedundantWithProductID:(NSNotification*)user{
    
    NSString*productID = [user.userInfo valueForKey:@"productID"];
    
    NSLog(@" 重复验证了  CheckRedundant:%@",productID);
}
    //商品完全购买成功且验证成功了。（若CheckAfterPay为NO，则会在购买成功后直接触发此方法）
-(void)IAPToolBoughtProductSuccessedWithProductID:(NSNotification*)user {
    NSString * productID = [user.userInfo valueForKey:@"ProductID"];
    NSDictionary * infoDic =[user.userInfo valueForKey:@"value"];
    
    
    UnitySendMessage(BlankInAppPurchaseBridgeLink, "Success", [self stringToChar:[NSString stringWithFormat:@"{\"productID\":\"%@\",\"Info\":\"%@\"}",productID,infoDic]]);
    NSLog(@"BoughtSuccessed:%@",productID);
    NSLog(@"successedInfo:%@",infoDic);
    
}
    //商品购买成功了，但向苹果服务器验证失败了
    //2种可能：
    //1，设备越狱了，使用了插件，在虚假购买。
    //2，验证的时候网络突然中断了。（一般极少出现，因为购买的时候是需要网络的）
-(void)IAPToolCheckFailedWithProductID:(NSNotification *)user{
    
    NSString* productID = [user.userInfo valueForKey:@"ProductID"];
    UnitySendMessage(BlankInAppPurchaseBridgeLink, "CheckFailed", [self stringToChar: productID]);
    NSLog(@"验证失败了  CheckFailed:%@",productID);
}
    //恢复了已购买的商品（仅限永久有效商品）
-(void)IAPToolRestoredProductID:(NSNotification*)user {
    
    NSString*productID = [user.userInfo valueForKey:@"value"];
    UnitySendMessage(BlankInAppPurchaseBridgeLink, "Restored", [self stringToChar: productID]);
    NSLog(@"成功恢复了商品（已打印） Restored:%@",productID);
}
    //内购系统错误了
-(void)IAPToolSysWrong {
    
    UnitySendMessage(BlankInAppPurchaseBridgeLink, "SystemError", [self stringToChar:@"内购系统出错"]);
    NSLog(@"内购系统出错  SysWrong");
        //    [SVProgressHUD showErrorWithStatus:@"内购系统出错"];
}


-(char *)stringToChar:(NSString *)str{
    
    const char *charstr = [str UTF8String];
        // alloc
    char *result = (char*)malloc(strlen(charstr)+1);
        // copy
    strcpy(result, charstr);
    
    return result;
}


#pragma mark --------Functions



    //恢复已购买的商品
-(void)restoreProduct{
        //直接调用
    [[YQInAppPurchaseTool defaultTool]restorePurchase];
}

    //购买商品
-(void)BuyProduct:(NSString *)productID{
    
    if ([self inited] == NO) {
        NSLog(@"没有初始化完成.请稍后");
        return;
    }
    
    [[YQInAppPurchaseTool defaultTool]buyProduct:productID];
}

AHViewController * inst;

#if defined (__cplusplus)
extern "C" {
#endif
    void start(char * productIDs,bool isdebug){
        inst =  [[AHViewController alloc] init];
        [inst startWithProductIDs:[NSString stringWithUTF8String:productIDs] AndDebug:isdebug];
        
    }
    void end(){
        [inst end];
        inst = nil;
        
    }
    
    void restore(){
        
        [inst restoreProduct];
    }
    void buy(char * product_id){
        [inst BuyProduct:[NSString stringWithUTF8String:product_id]];
        
    }
#if defined (__cplusplus)
}
#endif

@end
