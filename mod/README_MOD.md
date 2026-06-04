# Mod Việt hóa Pathfinder: Kingmaker (KingmakerVN)

Mod cho **Unity Mod Manager (UMM)**: nạp gói `vnVN_pack.json` (guid → tiếng Việt) rồi
Harmony **prefix** `LocalizationPack.GetText` để **phủ tiếng Việt lên khe ruRU** lúc chạy.
Chỉ override các chuỗi ĐÃ dịch — phần chưa dịch fallback English (không lọt tiếng Nga gốc).
File locale gốc trên đĩa GIỮ NGUYÊN; mod chỉ can thiệp lúc chạy.

## Build (KHÔNG ghi vào thư mục Mods của game nữa)
`build.bat` chỉ build + gom vào `_viethoa\out\KingmakerVN\` (DLL + Info.json + vnVN_pack.json).
- **Yêu cầu 1 lần:** cài Unity Mod Manager trỏ vào game (để có `0Harmony.dll` + `UnityModManager.dll`
  trong `Kingmaker_Data\Managed\`).
- Chạy `_viethoa\mod\build.bat` → sinh `_viethoa\out\KingmakerVN\`.

### Test cục bộ
Copy cả thư mục `_viethoa\out\KingmakerVN\` vào `<game>\Mods\` → vào game, mở UMM (Ctrl+F10)
→ bật **"Vietnamese Translation (Việt hóa)"** → Settings → Language → **"Tiếng Việt"** (khe ruRU).

## Cập nhật bản dịch
- Dịch thêm rồi chạy `python _viethoa/vh.py build` (tự gọi `pack`) → cập nhật `vnVN_pack.json`.
- Build lại (`build.bat`) để gói pack mới vào `out\` — hoặc chỉ cần copy `vnVN_pack.json` mới
  đè lên file trong thư mục mod (KHÔNG cần build lại .dll nếu `KingmakerVN.cs` không đổi).

## Phát hành lên GitHub (release)
CI chỉ đóng gói, không compile (DLL game có bản quyền). Các bước:
1. Build ở máy (`build.bat`) → copy `out\KingmakerVN\KingmakerVN.dll` vào `_viethoa\release-assets\KingmakerVN.dll`, commit.
2. `python vh.py build` để `vnVN_pack.json` mới nhất, commit.
3. Bump `Version` trong `mod\Info.json` **và** `Repository.json`.
4. (Tùy chọn, thử trước ở máy) `pwsh -File _viethoa\package_release.ps1` → `dist\KingmakerVN-<ver>.zip`.
5. Đẩy tag `v<ver>` (vd `v0.1.0`) → workflow `.github/workflows/release.yml` (windows-latest) gom zip
   từ `release-assets\KingmakerVN.dll` + `vnVN_pack.json`, tạo Release kèm `KingmakerVN-<ver>.zip`
   và bản tên ổn định `KingmakerVN.zip` (cho UMM auto-update qua `DownloadUrl` trong `Repository.json`).

### Layout zip (chuẩn UMM)
```
KingmakerVN/
  Info.json
  KingmakerVN.dll
  vnVN_pack.json     (full: đã dịch=Việt, chưa=English)
```
Người dùng cuối: tải zip ở Releases → giải nén thư mục `KingmakerVN` vào `<game>\Mods\` → bật trong UMM.

## Ghi chú kỹ thuật
- Harmony **prefix** `LocalizationPack.GetText(string,bool)`: nếu `CurrentLocale==ruRU` và key có trong
  pack → trả chuỗi Việt, bỏ qua hàm gốc. Tra cứu O(1) → không treo lúc tải.
- Mod đọc pack ưu tiên từ `StreamingAssets/Localization/_viethoa/vnVN_pack.json` (máy dev),
  fallback `vnVN_pack.json` trong thư mục mod (bản phát hành cho người dùng).
- Tắt mod / chọn lại ngôn ngữ để về ngôn ngữ gốc.
