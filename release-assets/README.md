# release-assets

Nơi đặt **`KingmakerVN.dll`** đã build sẵn ở máy, để GitHub Actions đóng gói release
(CI chỉ đóng gói, KHÔNG compile — DLL tham chiếu các DLL game có bản quyền nên không
build trên runner public được).

## Cập nhật DLL trước khi ra release
1. Build ở máy: chạy `_viethoa\mod\build.bat` → sinh `_viethoa\out\KingmakerVN\KingmakerVN.dll`.
2. Copy file đó vào đây: `release-assets\KingmakerVN.dll`.
3. Commit (chỉ cần làm lại khi `KingmakerVN.cs` đổi hoặc game cập nhật `Managed\`).

Gói ngôn ngữ `vnVN_pack.json` thì CI lấy thẳng từ `_viethoa/vnVN_pack.json` đã commit
(sinh bởi `python vh.py build`) — không cần copy vào đây.
