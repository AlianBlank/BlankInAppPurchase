    //
    //  YQInAppPurchaseTool.m
    //  YQStoreToolDemo
    //
    //  Created by problemchild on 16/8/24.
    //  Copyright © 2016年 ProblenChild. All rights reserved.
    //


#import "YQInAppPurchaseTool.h"

@interface YQInAppPurchaseTool ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>

/**
 *  商品字典
 */
@property(nonatomic,strong)NSMutableDictionary *productDict;

/**
 通知对象
 */
@property(nonatomic,strong)NSNotificationCenter* notify;

@property (nonatomic,strong)NSString*checkURL ;

/**
 是否是沙盒模式
 */
@property(nonatomic,assign) BOOL isDebug;

@end

@implementation YQInAppPurchaseTool


    //单例
static YQInAppPurchaseTool *storeTool;

    //单例
+(YQInAppPurchaseTool *)defaultTool{
    if(!storeTool){
        storeTool = [YQInAppPurchaseTool new];
        [storeTool setup];
    }
    return storeTool;
}


/**
 设置是否是沙盒模式

 @param isDebug 是否是沙盒模式
 */
- (void)setDebug:(BOOL)isDebug{
    
    [self setIsDebug:isDebug];
    if ([self isDebug]) {
        [self setCheckURL: @"https://sandbox.itunes.apple.com/verifyReceipt"];
    }else{
        [self setCheckURL: @"https://buy.itunes.apple.com/verifyReceipt"];
    }
    
    
}

#pragma mark  初始化
/**
 *  初始化
 */
-(void)setup{
    
    if ([self isDebug]) {
        [self setCheckURL: @"https://sandbox.itunes.apple.com/verifyReceipt"];
    }else{
        [self setCheckURL: @"https://buy.itunes.apple.com/verifyReceipt"];
    }
    self.CheckAfterPay = YES;
    _notify = [NSNotificationCenter defaultCenter];
        // 设置购买队列的监听器
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
}

#pragma mark 询问苹果的服务器能够销售哪些商品
/**
 *  询问苹果的服务器能够销售哪些商品
 */
- (void)requestProductsWithProductArray:(NSArray *)products
{
    NSLog(@"开始请求可销售商品");
    
        // 能够销售的商品
    NSSet *set = [[NSSet alloc] initWithArray:products];
    
        // "异步"询问苹果能否销售
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    
    request.delegate = self;
    
        // 启动请求
    [request start];
}

#pragma mark 获取询问结果，成功采取操作把商品加入可售商品字典里
/**
 *  获取询问结果，成功采取操作把商品加入可售商品字典里
 *
 *  @param request  请求内容
 *  @param response 返回的结果
 */
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"获取询问结果，成功采取操作把商品加入可售商品字典里");
    if (self.productDict == nil) {
        self.productDict = [NSMutableDictionary dictionaryWithCapacity:response.products.count];
    }
    
    NSMutableArray *productArray = [NSMutableArray array];
    
    for (SKProduct *product in response.products) {
            //NSLog(@"%@", product.productIdentifier);
        
            // 填充商品字典
        [self.productDict setObject:product forKey:product.productIdentifier];
        
        [productArray addObject:product];
    }
        //通知代理
    
    
    NSMutableDictionary * dict = [NSMutableDictionary new];
    [dict setObject:productArray forKey:@"value"];
    
    [self.notify postNotificationName:IAPToolGotProducts_NAME object:nil userInfo:dict ];
        //    [self.delegate IAPToolGotProducts:productArray];
}

#pragma mark - 用户决定购买商品
/**
 *  用户决定购买商品
 *
 *  @param productID 商品ID
 */
- (void)buyProduct:(NSString *)productID
{
    SKProduct *product = self.productDict[productID];
    if(product==nil){
        NSLog(@"Not Found The productID:%@ ",productID);
        return;
    }
    
        // 要购买产品(店员给用户开了个小票)
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    
        // 去收银台排队，准备购买(异步网络)
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKPaymentTransaction Observer
#pragma mark 购买队列状态变化,,判断购买状态是否成功
/**
 *  监测购买队列的变化
 *
 *  @param queue        队列
 *  @param transactions 交易
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
        // 处理结果
    for (SKPaymentTransaction *transaction in transactions) {
        NSLog(@"队列状态变化 %@", transaction);
            // 如果小票状态是购买完成
        if (SKPaymentTransactionStatePurchased == transaction.transactionState) {
                //NSLog(@"购买完成 %@", transaction.payment.productIdentifier);
            
            if(self.CheckAfterPay){
                    //需要向苹果服务器验证一下
                    //通知代理
                NSMutableDictionary* dict =[NSMutableDictionary new];
                [dict setObject:transaction.payment.productIdentifier forKey:@"value"];
                [self.notify postNotificationName:IAPToolBeginCheckingdWithProductID_NAME object:nil userInfo:dict];
                    //                [self.delegate IAPToolBeginCheckingdWithProductID:transaction.payment.productIdentifier];
                    // 验证购买凭据
                [self verifyPruchaseWithID:transaction.payment.productIdentifier];
            }else{
                    //不需要向苹果服务器验证
                    //通知代理
                    //                [self.delegate IAPToolBoughtProductSuccessedWithProductID:transaction.payment.productIdentifier
                    //                                                                    andInfo:nil];
                NSMutableDictionary* dict =[NSMutableDictionary new];
                [dict setObject:transaction.payment.productIdentifier forKey:@"value"];
                [self.notify postNotificationName:IAPToolBoughtProductSuccessedWithProductID_NAME object:nil userInfo:dict];
            }
                // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            
        } else if (SKPaymentTransactionStateRestored == transaction.transactionState) {
                //NSLog(@"恢复成功 :%@", transaction.payment.productIdentifier);
            
                // 通知代理
                //            [self.delegate IAPToolRestoredProductID:transaction.payment.productIdentifier];
            NSMutableDictionary* dict =[NSMutableDictionary new];
            [dict setObject:transaction.payment.productIdentifier forKey:@"value"];
            [self.notify postNotificationName:IAPToolRestoredProductID_NAME object:nil userInfo:dict];
                // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        } else if (SKPaymentTransactionStateFailed == transaction.transactionState){
            
                // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                //NSLog(@"交易失败");
                //            [self.delegate IAPToolCanceldWithProductID:transaction.payment.productIdentifier];
            NSMutableDictionary* dict =[NSMutableDictionary new];
            [dict setObject:transaction.payment.productIdentifier forKey:@"value"];
            [self.notify postNotificationName:IAPToolCanceldWithProductID_NAME object:nil userInfo:dict];
            
        }else if(SKPaymentTransactionStatePurchasing == transaction.transactionState){
            NSLog(@"正在购买");
        }else{
            NSLog(@"state:%ld",(long)transaction.transactionState);
            NSLog(@"已经购买");
                // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
}

#pragma mark - 恢复商品
/**
 *  恢复商品
 */
- (void)restorePurchase
{
    NSLog(@"恢复商品");
        // 恢复已经完成的所有交易.（仅限永久有效商品）
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark 验证购买凭据
/**
 *  验证购买凭据
 *
 *  @param ProductID 商品ID
 */
- (void)verifyPruchaseWithID:(NSString *)ProductID
{
        // 验证凭据，获取到苹果返回的交易凭据
        // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
        // 发送网络POST请求，对购买凭据进行验证
        //In the test environment, use https://sandbox.itunes.apple.com/verifyReceipt
        //In the real environment, use https://buy.itunes.apple.com/verifyReceipt
        // Create a POST request with the receipt data.
    NSURL *url = [NSURL URLWithString:[self checkURL]];
    
    NSLog(@"checkURL:%@",[self checkURL]);
    
        // 国内访问苹果服务器比较慢，timeoutInterval需要长一点
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
    
    request.HTTPMethod = @"POST";
    
        // 在网络中传输数据，大多情况下是传输的字符串而不是二进制数据
        // 传输的是BASE64编码的字符串
    /**
     BASE64 常用的编码方案，通常用于数据传输，以及加密算法的基础算法，传输过程中能够保证数据传输的稳定性
     BASE64是可以编码和解码的
     */
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    
    request.HTTPBody = payloadData;
    
        // 提交验证请求，并获得官方的验证JSON结果
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
        // 官方验证结果为空
    if (result == nil) {
            //NSLog(@"验证失败");
            //验证失败,通知代理
            //        [self.delegate IAPToolCheckFailedWithProductID:ProductID
            //                                                 andInfo:result];
        
        NSMutableDictionary* dict =[NSMutableDictionary new];
        [dict setObject:result forKey:@"value"];
        [dict setObject:ProductID forKey:@"ProductID"];
        [self.notify postNotificationName:IAPToolCheckFailedWithProductID_NAME object:nil userInfo:dict];
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:result
                                                         options:NSJSONReadingAllowFragments error:nil];
    
        //NSLog(@"RecivedVerifyPruchaseDict：%@", dict);
    
    if (dict != nil) {
            // 验证成功,通知代理
            // bundle_id&application_version&product_id&transaction_id
            //        [self.delegate IAPToolBoughtProductSuccessedWithProductID:ProductID
            //                                                            andInfo:dict];
        NSMutableDictionary* paramdict =[NSMutableDictionary new];
        [paramdict setObject:dict forKey:@"value"];
        [paramdict setObject:ProductID forKey:@"ProductID"];
        [self.notify postNotificationName:IAPToolBoughtProductSuccessedWithProductID_NAME object:nil userInfo:paramdict];
        
    }else{
        
            //验证失败,通知代理
        NSMutableDictionary* paramdict =[NSMutableDictionary new];
        [paramdict setObject:result forKey:@"value"];
        [paramdict setObject:ProductID forKey:@"ProductID"];
        [self.notify postNotificationName:IAPToolCheckFailedWithProductID_NAME object:nil userInfo:paramdict];
        
            //        [self.delegate IAPToolCheckFailedWithProductID:ProductID
            //                                                 andInfo:result];
    }
}



@end
