using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class BlankInAppPurchaseExample : MonoBehaviour
{
#if UNITY_IOS
    private string m_text = "";

    private void OnGUI()
    {
        GUILayout.Space(50);
        m_text = GUILayout.TextField(m_text, GUILayout.Width(300), GUILayout.Height(50));
        if (GUILayout.Button("Start", GUILayout.Width(300), GUILayout.Height(100)))
        {
            BlankInAppPurchase.Instance.StartIAP("[\"60\",\"180\",\"300\",\"680\",\"1280\",\"1980\",\"3280\",\"6480\"]", true);
        }
        if (GUILayout.Button("End", GUILayout.Width(300), GUILayout.Height(100)))
        {
            BlankInAppPurchase.Instance.End();
        }

        if (GUILayout.Button("Buy", GUILayout.Width(300), GUILayout.Height(100)))
        {
            BlankInAppPurchase.Instance.Buy(m_text);
        }
        if (GUILayout.Button("ReStore", GUILayout.Width(300), GUILayout.Height(100)))
        {
            BlankInAppPurchase.Instance.Restore();
        }

    }
#endif

}
