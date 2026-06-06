<#
  dich_loop.ps1 - Vong lap Viet hoa Kingmaker bang cac PHIEN claude MOI.
  Moi vong = 1 lan 'claude -p' (phien moi HOAN TOAN -> reset context, tiet kiem token).

  PHAN CONG (de re context, claude chi lam viec dat tien = DICH):
    - PowerShell tu chay  : python vh.py next  (tao batch_in)  va  python vh.py merge (gop ket qua)
    - claude -p chi lam   : doc batch_in.json + glossary.md -> ghi batch_out.json
      => claude KHONG can Bash/Edit, it turn hon, context nho hon.

  Dung khi:
    - Het chuoi chua dich  (vh.py pending tra exit code 1), HOAC
    - Het so vong gioi han (-MaxRuns), HOAC
    - claude tra ve loi    (de tranh lap loi vo han / het quota).

  Du lieu da merge nam trong tm.json (ghi nguyen-tu + xoay vong .bak/.bak.1/.bak.2
  + snapshot tm.YYYYMMDD.json), nen dung script bat cu luc nao cung KHONG mat tien do.

  Reject: chuoi bi tu choi khong vao tm.json -> van con 'pending' -> tu dong duoc
  'next' chon lai o vong sau de dich lai (khong can buoc sua-trong-phien nua).

  Cach chay:
    pwsh -File dich_loop.ps1                       # chay den khi dich xong het
    pwsh -File dich_loop.ps1 -MaxRuns 2            # chi chay 2 vong
    pwsh -File dich_loop.ps1 -Chunk 150 -MaxChars 30000   # doi co chunk
    pwsh -File dich_loop.ps1 -Model claude-opus-4-8       # doi model (mac dinh Sonnet)
#>
param(
    [int]$Chunk    = 150,                 # so chuoi toi da moi chunk
    [int]$MaxChars = 20000,               # tran ky tu moi chunk (0 = tat); chan chunk qua dai
    [int]$MaxRuns  = 0,                    # so vong toi da; 0 = chay den khi dich xong het
    [string]$Model = "claude-sonnet-4-6"  # model cho phien dich (Sonnet re hon Opus nhieu lan)
)

$ErrorActionPreference = "Stop"
# Exit code != 0 cua python/claude KHONG duoc nem exception; ta tu xu ly qua $LASTEXITCODE.
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$loc = "F:\Games\PathfinderKingmaker\Kingmaker_Data\StreamingAssets\Localization"
Set-Location $loc
$vh  = Join-Path $loc "_viethoa\vh.py"
$tm  = Join-Path $loc "_viethoa\tm.json"

# Moi lan goi loop = 1 "phien" co dau thoi gian rieng; moi VONG trong phien ghi
# 1 file backup tm.json theo thu tu (run1, run2, ...). O cung rong nen giu het.
$bakDir = Join-Path $loc "_viethoa\tm_backup"
if (-not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir | Out-Null }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$run = 0
while ($true) {
    if ($MaxRuns -gt 0 -and $run -ge $MaxRuns) {
        Write-Host "[loop] Da chay du $MaxRuns vong -> dung."
        break
    }

    # Con chuoi chua dich khong? (pending in so + exit 1 neu da xong het)
    $remain = (python $vh pending | Select-Object -Last 1)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[loop] Da dich xong TAT CA. Dung."
        break
    }

    $run++
    Write-Host ("[loop] === Vong {0} | con {1} chuoi chua dich | {2} ===" -f `
                $run, $remain, (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))

    # 1) PowerShell tu tao batch_in.json (claude khoi ton turn/Bash cho viec nay).
    python $vh next $Chunk $MaxChars
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[loop] 'vh.py next' loi (exit $LASTEXITCODE) -> DUNG."
        break
    }

    # 2) claude CHI DICH: doc batch_in + glossary -> ghi batch_out. Chi can Read,Write.
    $prompt = @"
Che do im lang: KHONG in noi dung dich ra man hinh, chi bao da ghi xong bao nhieu muc.
Buoc lam:
1) Doc _viethoa/batch_in.json (mang cac {"i":id,"en":"chuoi goc"}) va _viethoa/glossary.md.
2) Dich TAT CA chuoi 'en' sang tieng Viet theo dung glossary:
   - GIU NGUYEN moi tag: {mf|..} {g|..}{/g} {d|..} {n|..} \n <b></b> <i></i> <color..></color> <size..></size> [LONGSTART][LONGEND]
   - GIU NGUYEN ten lop nhan vat (Bard, Cleric, Paladin, Wizard, Sorcerer, Druid, Magus, Fighter, Rogue, Ranger, Inquisitor, Barbarian, Alchemist) va ten rieng/dia danh.
3) Ghi ket qua ra _viethoa/batch_out.json dang object {"i":"ban dich"} (key 'i' lay DUNG tu batch_in.json). KHONG ghi them gi khac.
"@
    # --allowedTools chi Read,Write: claude khong chay python, khong sua file khac -> it turn, re context.
    # Neu bi chan quyen, doi thanh: claude -p $prompt --dangerously-skip-permissions ...
    claude -p $prompt --allowedTools "Read,Write" --model $Model --max-turns 12
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[loop] claude tra ve loi (exit $LASTEXITCODE) - co the het quota/gioi han -> DUNG, khong tinh them."
        break
    }

    # 3) PowerShell tu merge (kiem tra tag, vao tm.json, in nhan/tu_choi/tm_total).
    python $vh merge
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[loop] 'vh.py merge' loi (exit $LASTEXITCODE) -> DUNG."
        break
    }

    # 4) Sao luu tm.json sau merge thanh cong: 1 file/vong theo thu tu loop.
    if (Test-Path $tm) {
        $bak = Join-Path $bakDir ("tm_{0}_run{1:D3}.json" -f $stamp, $run)
        Copy-Item $tm $bak -Force
        Write-Host "[loop] da sao luu -> $bak"
    }
}

# Sinh lai pack cho mod + bao thong ke cuoi cung
Write-Host "[loop] Sinh lai vnVN_pack.json + thong ke..."
python $vh build
python $vh stats
Write-Host "[loop] HOAN TAT."
