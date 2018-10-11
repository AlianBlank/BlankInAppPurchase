    //
    //  ViewController.h
    //  YQIAPTest
    //
    //  Created by problemchild on 16/8/25.
    //  Copyright © 2016年 ProblenChild. All rights reserved.
    //

#import <UIKit/UIKit.h>

// 链接桥的名称
#define BlankInAppPurchaseBridgeLink "BlankInAppPurchaseBridgeLink"

@interface AHViewController : UIViewController


-(void)startWithProductIDs:(NSString*)productIDs AndDebug:(BOOL)isDebug;

-(void)end;

/**
 恢复已购买的商品（仅限永久有效商品）
 */
-(void)restoreProduct;

/**
 购买商品
 
 @param productID 产品ID
 */
-(void)BuyProduct:(NSString *)productID;




#if defined (__cplusplus)
extern "C" {
#endif
    // 开始
    void start(char * productIDs,bool isdebug);
    // 结束
    void end();
    // 购买
    void buy(char * product_id);
    // 恢复已经购买的商品(仅限永久性商品)
    void restore();
#if defined (__cplusplus)
}
#endif

@end

