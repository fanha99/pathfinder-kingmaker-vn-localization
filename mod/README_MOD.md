# Mod Việt hóa Pathfinder: Kingmaker (KingmakerVN)

Mod cho **Unity Mod Manager (UMM)**: nạp gói `vnVN_pack.json` (guid → tiếng Việt) rồi
`LocalizationPack.AppendPack()` để **phủ tiếng Việt lên ngôn ngữ đang chọn** trong game.
Chỉ override các chuỗi ĐÃ dịch — phần chưa dịch giữ nguyên ngôn ngữ gốc (mặc định English).

## Trạng thái
- Mã nguồn `KingmakerVN.cs` + `Info.json` + `build.bat` đã sẵn sàng.
- API game đã được kiểm chứng biên dịch OK (csc .NET Framework 4).
- **Chưa biên dịch ra .dll** vì cần Unity Mod Manager cài trước (để có `0Harmony.dll` + `UnityModManager.dll`).

## Các bước cài (làm 1 lần)
1. **Cài Unity Mod Manager**
   - Tải UMM: https://www.nexusmods.com/site/mods/21 (hoặc trang Nexus của Kingmaker).
   - Mở `UnityModManager.exe` → chọn game **Pathfinder: Kingmaker** (trỏ vào `Kingmaker.exe`) → **Install**.
   - UMM sẽ tạo thư mục `Mods\` trong game và thêm `0Harmony.dll`, `UnityModManager.dll` vào `Kingmaker_Data\Managed\` (hoặc `...\Managed\UnityModManager\`).

2. **Biên dịch mod**
   - Chạy `build.bat` trong thư mục này (nhấp đúp hoặc chạy trong cmd).
   - Nó dùng `csc.exe` của .NET Framework 4 để build → `Mods\KingmakerVN\KingmakerVN.dll`, kèm `Info.json` và `vnVN_pack.json`.

3. **Chạy game**
   - Vào game, mở UMM (phím **Ctrl+F10** mặc định) → thấy mod **"Vietnamese Translation"** → bật.
   - Phần đã dịch sẽ hiển thị tiếng Việt ngay (không cần đổi ngôn ngữ trong Settings).

## Cập nhật bản dịch
- Mỗi lần dịch thêm: chạy `python _viethoa/vh.py build` (đã tự gọi `pack`) hoặc `vh.py pack`.
- Mod đọc `StreamingAssets/Localization/_viethoa/vnVN_pack.json` lúc khởi động → chỉ cần khởi động lại game (không cần build lại .dll) là thấy bản mới.

## Ghi chú kỹ thuật
- `LocalizationManager.CurrentPack.AppendPack(packVN)`: `GetText` ưu tiên gói append → phủ tiếng Việt, fallback chuỗi gốc.
- Patch Harmony postfix `OnLocaleChanged` + `Init` để tái-nạp khi game đổi/khởi tạo ngôn ngữ.
- Tắt mod trong UMM = append gói rỗng → về ngôn ngữ gốc.
- Sau mỗi lần game cập nhật, chỉ cần chạy lại `build.bat` (nếu Managed thay đổi).
