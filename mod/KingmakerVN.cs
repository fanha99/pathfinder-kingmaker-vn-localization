// KingmakerVN - phu tieng Viet len Pathfinder: Kingmaker qua Unity Mod Manager.
// Co che (BAN MOI - NHE, KHONG TREO):
//   Harmony PREFIX hàm LocalizationPack.GetText(key, bool). Khi locale hien tai = ruRU
//   va key co trong goi VN (vnVN_pack.json - full: da dich=Viet, chua=English) thi tra
//   ngay chuoi Viet, BO QUA ham goc. Khong dung AppendPack (cach cu AppendPack ca 63k
//   chuoi luc khoi tao locale -> treo). Tra cuu O(1) moi lan -> khong the treo.
//   File ruRU goc (Nga) GIU NGUYEN tren dia; mod chi can thiep luc chay.
// API (Assembly-CSharp 2.1.7b, xac minh bang dnlib):
//   Kingmaker.Localization.LocalizationManager.CurrentLocale (Locale, public static prop)
//   Kingmaker.Localization.LocalizationPack.GetText(string, bool) : string  (public)
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using HarmonyLib;
using UnityModManagerNet;
using UnityEngine;
using Newtonsoft.Json;
using Kingmaker.Localization;
using Kingmaker.Localization.Shared;   // enum Locale

namespace KingmakerVN
{
    public static class Main
    {
        public static UnityModManager.ModEntry.ModLogger Log;
        public static bool Enabled = true;

        static Dictionary<string, string> _vn;          // guid -> text (Viet, fallback English)

        public static bool Load(UnityModManager.ModEntry modEntry)
        {
            Log = modEntry.Logger;
            modEntry.OnToggle = OnToggle;
            try
            {
                LoadPackFile(modEntry);

                var harmony = new Harmony(modEntry.Info.Id);
                MethodInfo target = AccessTools.Method(typeof(LocalizationPack), "GetText",
                                        new Type[] { typeof(string), typeof(bool) });
                MethodInfo prefix = typeof(Main).GetMethod("GetText_Prefix",
                                        BindingFlags.Static | BindingFlags.NonPublic);
                if (target == null)
                {
                    if (Log != null) Log.Error("Khong tim thay LocalizationPack.GetText(string,bool) - mod khong hoat dong.");
                    return false;
                }
                harmony.Patch(target, prefix: new HarmonyMethod(prefix));
                if (Log != null) Log.Log("Da patch LocalizationPack.GetText. San sang phu tieng Viet cho khe ruRU.");
            }
            catch (Exception e)
            {
                if (Log != null) Log.Error("Load loi: " + e);
                return false;
            }
            return true;
        }

        static void LoadPackFile(UnityModManager.ModEntry modEntry)
        {
            // Uu tien doc tu StreamingAssets (tu dong moi sau moi lan 'vh.py build/pack'),
            // fallback ve thu muc mod.
            string p1 = Path.Combine(Application.streamingAssetsPath,
                            "Localization/_viethoa/vnVN_pack.json");
            string p2 = Path.Combine(modEntry.Path, "vnVN_pack.json");
            string path = File.Exists(p1) ? p1 : p2;

            string json = File.ReadAllText(path);
            _vn = JsonConvert.DeserializeObject<Dictionary<string, string>>(json)
                  ?? new Dictionary<string, string>();

            if (Log != null) Log.Log("Nap " + _vn.Count + " chuoi tu " + path);
        }

        // Harmony PREFIX cho LocalizationPack.GetText(string key, bool).
        // Tra true = chay ham goc; tra false = dung __result (bo qua goc).
        // __0 = tham so dau (key). __result = gia tri tra ve.
        static bool GetText_Prefix(string __0, ref string __result)
        {
            try
            {
                if (!Enabled) return true;
                // Check locale TRUOC bang so sanh enum truc tiep (nhanh, KHONG cap phat chuoi).
                // enum.ToString() cu cham gap nhieu lan -> goi moi lan GetText lam load cuc cham.
                if (LocalizationManager.CurrentLocale != Locale.ruRU) return true;
                var vn = _vn;
                if (vn == null || __0 == null) return true;
                string vi;
                if (!vn.TryGetValue(__0, out vi)) return true;   // khong co key -> de game tu xu
                __result = vi;
                return false;   // bo qua ham goc
            }
            catch
            {
                return true;    // co loi gi thi cu chay ham goc, khong lam chet game
            }
        }

        static bool OnToggle(UnityModManager.ModEntry modEntry, bool value)
        {
            Enabled = value;   // bat/tat tuc thi (prefix doc co Enabled moi lan tra cuu)
            return true;
        }
    }
}
