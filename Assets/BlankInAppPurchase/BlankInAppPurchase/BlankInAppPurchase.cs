using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public class BlankInAppPurchase : MonoBehaviour {
#if UNITY_IOS

    [DllImport("__Internal")]
    private static extern void start(string productIDs, bool isdebug);
    [DllImport("__Internal")]
    private static extern void end();
    [DllImport("__Internal")]
    private static extern void restore();
    [DllImport("__Internal")]
    private static extern void buy(string productID);


    private bool m_isInited = false;

    private static BlankInAppPurchase _instance;
    public static BlankInAppPurchase Instance
    {
        get
        {
            if (_instance == null)
            {
                const string blankInAppPurchaseBridgeLink = "BlankInAppPurchaseBridgeLink";
                GameObject go = GameObject.Find(blankInAppPurchaseBridgeLink);
                if (go != null)
                {
                    Destroy(go);
                }
                go = new GameObject(blankInAppPurchaseBridgeLink);
                DontDestroyOnLoad(go);
                _instance = go.AddComponent<BlankInAppPurchase>();
            }
            return _instance;
        }
    }

    /// <summary>
    /// Start the specified productIDs and isDebug.
    /// </summary>
    /// <param name="productIDs">Product identifier.</param>
    /// <param name="isDebug">If set to <c>true</c> is debug.</param>
    public void StartIAP(string productIDs,bool isDebug)
    {
        if (m_isInited)
        {
            Debug.LogWarning("已经初始化过了");
            return;
        }
        start(productIDs, isDebug);
    }

    /// <summary>
    /// End this instance.
    /// </summary>
    public void End(){

        end();
        m_isInited = false;
        Destroy(this.gameObject);
    }

    /// <summary>
    /// 购买
    /// </summary>
    /// <param name="productID">产品ID.</param>
    public void Buy(string productID){
        buy(productID);
    }

    /// <summary>
    /// 恢复已经购买的商品(仅限永久性商品)
    /// </summary>
    public void Restore()
    {
        restore();
    }

    /// <summary>
    /// 初始化成功
    /// </summary>
    /// <param name="result">Result 获取到的商品列表 </param>
    private	void Init (string result) {
        Debug.Log("初始化成功");
        Debug.Log(result);
        m_isInited = true;
	}

    /// <summary>
    /// 支付成功
    /// </summary>
    /// <param name="result">Result.</param>
    private void Success(string result){
        Debug.Log("支付成功");
        Debug.Log(result);

    }

    /// <summary>
    /// 商品购买成功了，但向苹果服务器验证失败了
    ///  2种可能：
    ///  1，设备越狱了，使用了插件，在虚假购买。
    ///  2，验证的时候网络突然中断了。（一般极少出现，因为购买的时候是需要网络的）
    /// </summary>
    /// <param name="productID">Product identifier.</param>
    private void CheckFailed(string productID){

        Debug.Log("商品购买成功了，但向苹果服务器验证失败了");
        Debug.Log(productID);
    }

    /// <summary>
    /// 恢复了已购买的商品（仅限永久有效商品）
    /// </summary>
    /// <param name="productID">Product identifier.</param>
    private void Restored(string productID){

        Debug.Log("恢复了已购买的商品（仅限永久有效商品");
        Debug.Log(productID);
    }

    /// <summary>
    /// 支付失败
    /// </summary>
    /// <param name="result">Result.</param>
    private void Failed(string result){

        Debug.Log("支付失败");
        Debug.Log(result);
    }

    /// <summary>
    /// 内购系统出错
    /// </summary>
    /// <param name="result">Result.</param>
    private void SystemError(string result){
        Debug.LogError("内购系统出错");
    }
#endif
}
