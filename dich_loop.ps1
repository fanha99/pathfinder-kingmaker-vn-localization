<#
  dich_loop.ps1 - Vong lap Viet hoa Kingmaker bang cac PHIEN claude MOI.
  Moi vong = 1 lan 'claude -p' (phien moi HOAN TOAN -> reset context, tiet kiem token)
  dich 1 chunk roi merge, sau do tu thoat. Khong can mo/dong cua so thu cong.

  Dung khi:
    - Het chuoi chua dich  (vh.py pending tra exit code 1), HOAC
    - Het so vong gioi han (-MaxRuns), HOAC
    - claude tra ve loi    (de tranh lap loi vo han).

  Du lieu da merge nam trong tm.json (ghi kieu nguyen-tu + co tm.json.bak),
  nen dung script bat cu luc nao cung KHONG mat tien do, KHONG dich lai.

  Cach chay:
    pwsh -File _viethoa\dich_loop.ps1                 # chay den khi dich xong het
    pwsh -File _viethoa\dich_loop.ps1 -MaxRuns 5      # chi chay 5 vong
    pwsh -File _viethoa\dich_loop.ps1 -Chunk 100      # doi co chunk
#>
param(
    [int]$Chunk   = 150,   # so chuoi moi chunk (mac dinh 150)
    [int]$MaxRuns = 0      # so vong toi da; 0 = chay den khi dich xong het
)

$ErrorActionPreference = "Stop"
# Exit code != 0 cua python/claude KHONG duoc nem exception; ta tu xu ly qua $LASTEXITCODE.
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$loc = "F:\Games\PathfinderKingmaker\Kingmaker_Data\StreamingAssets\Localization"
Set-Location $loc
$vh = Join-Path $loc "_viethoa\vh.py"

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

    $prompt = @"
Tiep tuc dich Viet hoa (che do im lang: chi bao ket qua ngan gon, KHONG in noi dung dich ra man hinh).
Cac buoc, lam tuan tu:
1) Chay: python _viethoa/vh.py next $Chunk
2) Doc _viethoa/batch_in.json. Dich TAT CA cac chuoi sang tieng Viet theo dung _viethoa/glossary.md:
   - GIU NGUYEN moi tag: {mf|..} {g|..}{/g} {d|..} {n|..} \n <b></b> <i></i> <color..></color> <size..></size> [LONGSTART][LONGEND]
   - GIU NGUYEN ten lop nhan vat (Bard, Cleric, Paladin, Wizard, Sorcerer, Druid, Magus, Fighter, Rogue, Ranger, Inquisitor, Barbarian, Alchemist) va ten rieng/dia danh.
   Ghi ket qua ra _viethoa/batch_out.json dang object {"i":"ban dich"} (key 'i' lay tu batch_in.json).
3) Chay: python _viethoa/vh.py merge
Bao lai gon: nhan / tu_choi / tm_total. Neu co reject (xem batch_rejects.json, giu en goc) thi sua va merge lai 1 lan.
"@

    # --allowedTools: khong hoi quyen giua chung.  --max-turns: chan 1 phien lo "chay loan".
    # Neu van bi chan quyen, doi thanh:  claude -p $prompt --dangerously-skip-permissions --max-turns 40
    claude -p $prompt --allowedTools "Bash,Read,Write,Edit" --model claude-sonnet-4-6 --max-turns 40
    # Bat ky loi nao (ke ca HET QUOTA / usage limit) -> exit != 0 -> DUNG, khong lap tiep.
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[loop] claude tra ve loi (exit $LASTEXITCODE) - co the het quota/gioi han -> DUNG, khong tinh them."
        break
    }
}

# Sinh lai pack cho mod + bao thong ke cuoi cung
Write-Host "[loop] Sinh lai vnVN_pack.json + thong ke..."
python $vh build
python $vh stats
Write-Host "[loop] HOAN TAT."
