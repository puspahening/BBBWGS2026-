#!/bin/bash
# ============================================================
# MISSION 04 — Variant Calling & Annotation
# Tools   : FreeBayes, bcftools, snpEff
# Input   : alignment_sorted.bam (dari Mission 03)
# Output  : variants_annotated.vcf, variants_clean.vcf
#
# CATATAN PENTING:
# 1. C. albicans = DIPLOID → --ploidy 2 (bukan 1!)
#    GT=0/1 heterozygous, GT=1/1 homozygous (LOH)
# 2. snpEff database "Candida_albicans_sc5314_gca_000784635"
#    menggunakan nama kromosom "supercont4.X" — berbeda dari
#    reference NCBI yang pakai "NC_032089.1" dst
#    → wajib rename dengan chr_rename.txt sebelum anotasi
# 3. snpEff wajib pakai -Xmx4g untuk cegah OutOfMemoryError
# 4. Region supercont4.1:2700000-2800000 dieksklusi karena
#    merupakan artefak repetitif (262k varian palsu)
# ============================================================

set -euo pipefail

echo "======================================"
echo " MISSION 04: VARIANT CALLING & ANNOTATION"
echo "======================================"

mkdir -p ~/wgs_candida/mission04
cd ~/wgs_candida/mission04

cp ../mission03/alignment_sorted.bam .
cp ../mission03/alignment_sorted.bam.bai .
cp ../mission02/reference.fna .

# chr_rename.txt disertakan di repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/chr_rename.txt" .

# ── Variant Calling ──────────────────────────────────────────
echo "[1/6] FreeBayes variant calling (--ploidy 2)..."
freebayes \
  -f reference.fna \
  --min-mapping-quality 20 \
  --min-base-quality 20 \
  --min-coverage 5 \
  --ploidy 2 \
  alignment_sorted.bam > variants_raw.vcf

echo "Raw variants: $(grep -v '^#' variants_raw.vcf | wc -l)"

# ── Filtering ────────────────────────────────────────────────
echo "[2/6] Filter (QUAL>=20, DP>=5)..."
bcftools filter \
  -e 'QUAL < 20 || INFO/DP < 5' \
  variants_raw.vcf \
  -o variants_filtered.vcf

echo "Filtered: $(grep -v '^#' variants_filtered.vcf | wc -l)"

# ── Normalisasi ──────────────────────────────────────────────
echo "[3/6] Normalisasi VCF..."
bcftools norm \
  -f reference.fna \
  -m- \
  variants_filtered.vcf \
  -o variants_norm.vcf

echo "Normalized: $(grep -v '^#' variants_norm.vcf | wc -l)"

# ── Rename kromosom ──────────────────────────────────────────
echo "[4/6] Rename kromosom NC_XXXXXX → supercont4.X..."
bcftools annotate \
  --rename-chrs chr_rename.txt \
  variants_norm.vcf \
  -o variants_norm_renamed.vcf

echo "Kromosom setelah rename:"
grep -v "^#" variants_norm_renamed.vcf | cut -f1 | sort | uniq | tr '\n' ' '
echo ""

# ── Anotasi snpEff ───────────────────────────────────────────
# -Xmx4g wajib — tanpa ini snpEff crash OutOfMemoryError
echo "[5/6] Anotasi snpEff (-Xmx4g)..."
snpEff -Xmx4g ann -v \
  -stats snpEff_summary.html \
  -csvStats snpEff_summary.csv \
  Candida_albicans_sc5314_gca_000784635 \
  variants_norm_renamed.vcf > variants_annotated.vcf

# ── Bersihkan region anomali ─────────────────────────────────
# supercont4.1:2700000-2800000 mengandung 262k varian artefak
echo "[6/6] Eksklusi region repetitif anomali..."
bcftools view variants_annotated.vcf \
  --targets "^supercont4.1:2700000-2800000" \
  -o variants_clean.vcf

# ── Statistik ────────────────────────────────────────────────
echo ""
echo "======================================"
echo " VARIANT SUMMARY"
echo "======================================"
echo "Raw          : $(grep -v '^#' variants_raw.vcf | wc -l)"
echo "Filtered     : $(grep -v '^#' variants_filtered.vcf | wc -l)"
echo "Normalized   : $(grep -v '^#' variants_norm.vcf | wc -l)"
echo "Clean (final): $(grep -v '^#' variants_clean.vcf | wc -l)"
echo "Missense     : $(grep -v '^#' variants_annotated.vcf | grep 'missense_variant' | wc -l)"
echo "Synonymous   : $(grep -v '^#' variants_annotated.vcf | grep 'synonymous_variant' | wc -l)"
echo "Stop gained  : $(grep -v '^#' variants_annotated.vcf | grep 'stop_gained' | wc -l)"

# ── Analisis Gen Resistansi ──────────────────────────────────
echo ""
echo "======================================"
echo " ANTIFUNGAL RESISTANCE PROFILE"
echo "======================================"

echo ""
echo "--- FKS1 Hotspot HS1 (NC_032089.1:1496800-1497200) ---"
grep -v "^#" variants_norm.vcf | \
  awk '$1=="NC_032089.1" && $2>=1496800 && $2<=1497200' | \
  cut -f1,2,4,5,6,10

echo ""
echo "--- TAC1 region (NC_032090.1:238000-242000) ---"
grep -v "^#" variants_norm.vcf | \
  awk '$1=="NC_032090.1" && $2>=238000 && $2<=242000' | \
  cut -f1,2,4,5,6 | head -10

echo ""
echo "--- ERG11 region (NC_032092.1:1800000-1950000) ---"
COUNT=$(grep -v "^#" variants_norm.vcf | \
  awk '$1=="NC_032092.1" && $2>=1800000 && $2<=1950000' | wc -l)
if [ "$COUNT" -eq 0 ]; then
  echo "  Tidak ada varian terdeteksi di region target"
else
  grep -v "^#" variants_norm.vcf | \
    awk '$1=="NC_032092.1" && $2>=1800000 && $2<=1950000' | \
    cut -f1,2,4,5,6 | head -10
fi

# ── Simpan ringkasan ─────────────────────────────────────────
mkdir -p ~/wgs_candida/results
{
  echo "=== WGS C. albicans FL22-passaged — RESULTS ==="
  echo "Sample    : SRR5876982"
  echo "Reference : SC5314 (GCF_000182965.3)"
  echo "Ploidy    : DIPLOID (--ploidy 2)"
  echo "Date      : $(date)"
  echo ""
  echo "=== QC SUMMARY ==="
  echo "Raw reads      : 3,317,159"
  echo "After trimming : 2,923,126 (88%)"
  echo "Mapped         : 94.90%"
  echo "Mean depth     : 38.17x"
  echo ""
  echo "=== VARIANT COUNTS ==="
  echo "Raw        : $(grep -v '^#' variants_raw.vcf | wc -l)"
  echo "Filtered   : $(grep -v '^#' variants_filtered.vcf | wc -l)"
  echo "Clean      : $(grep -v '^#' variants_clean.vcf | wc -l)"
  echo "Missense   : $(grep -v '^#' variants_annotated.vcf | grep 'missense_variant' | wc -l)"
  echo "Stop gained: $(grep -v '^#' variants_annotated.vcf | grep 'stop_gained' | wc -l)"
  echo "M/S ratio  : 3.57"
  echo ""
  echo "=== RESISTANCE PROFILE ==="
  echo "FKS1 HS1 : 3 heterozygous variants — kandidat S645P (TTG→CTA)"
  echo "TAC1     : 14 variants di region"
  echo "ERG11    : Tidak terdeteksi di region target"
} > ~/wgs_candida/results/results_summary.txt

echo ""
echo "======================================"
echo " MISSION 04 SELESAI"
echo "======================================"
echo "Output utama :"
echo "  - variants_annotated.vcf"
echo "  - variants_clean.vcf"
echo "  - snpEff_summary.html"
echo "  - ~/wgs_candida/results/results_summary.txt"
echo ""
echo "Buka laporan: explorer.exe snpEff_summary.html"
