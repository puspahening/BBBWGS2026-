#!/bin/bash
# ============================================================
# MISSION 04 — Variant Calling & Annotation
# Tools   : FreeBayes, bcftools, snpEff (custom database)
# Input   : alignment_sorted.bam (dari Mission 03)
# Output  : variants_annotated.vcf
#
# CATATAN PENTING — DIBACA DULU SEBELUM MENJALANKAN:
#
# 1. C. albicans = DIPLOID -> --ploidy 2 (bukan 1!)
#    GT=0/1 heterozygous, GT=1/1 homozygous (LOH)
#
# 2. SEMUA database snpEff publik untuk C. albicans (termasuk
#    "Candida_albicans_sc5314_gca_000784635" dan
#    "Candida_albicans_sc5314_gca_000784655") menggunakan assembly
#    LAMA yang fragmented (38-77 scaffold/supercontig). Assembly ini
#    TIDAK bisa dipetakan 1:1 ke reference modern 8-kromosom
#    (GCF_000182965.3) yang dipakai untuk alignment di script ini.
#    Mencoba bcftools annotate --rename-chrs akan menyebabkan
#    ERROR_OUT_OF_CHROMOSOME_RANGE pada ribuan varian.
#
#    SOLUSI: script ini membangun database snpEff CUSTOM langsung
#    dari reference.fna + GFF3 resmi NCBI -- assembly yang identik
#    dengan yang dipakai alignment, sehingga tidak ada chr mismatch
#    sama sekali dan tidak perlu file rename.
#
# 3. snpEff build memerlukan -noCheckCds -noCheckProtein karena
#    file protein.fa/cds.fa terpisah tidak disediakan -- tanpa flag
#    ini, build akan gagal di tahap validasi akhir meskipun
#    snpEffectPredictor.bin (file yang sebenarnya dibutuhkan) sudah
#    berhasil terbentuk.
#
# 4. snpEff ann WAJIB pakai -Xmx6g -- tanpa ini, snpEff mengalami
#    java.lang.OutOfMemoryError saat memproses ~64,000 varian
#    dengan anotasi yang padat (banyak transcript overlap per posisi).
#
# 5. KOORDINAT GEN TARGET RESISTANSI sudah diverifikasi langsung
#    dari genes.gff (bukan estimasi literatur). Lihat tabel di
#    bagian akhir script ini. Jangan mengasumsikan posisi gen dari
#    sumber lain tanpa verifikasi ulang yang sama -- kesalahan
#    koordinat (mengasumsikan FKS1 di posisi yang ternyata milik
#    PUT3/RBT4/MEF2; mengasumsikan TAC1/ERG11 di Chr2/Chr4 padahal
#    keduanya di Chr5) pernah terjadi dan baru terdeteksi setelah
#    anotasi selesai.
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

# ---- Variant Calling ------------------------------------------------
echo "[1/7] FreeBayes variant calling (--ploidy 2)..."
freebayes \
  -f reference.fna \
  --min-mapping-quality 20 \
  --min-base-quality 20 \
  --min-coverage 5 \
  --ploidy 2 \
  alignment_sorted.bam > variants_raw.vcf

echo "Raw variants: $(grep -v '^#' variants_raw.vcf | wc -l)"

# ---- Filtering --------------------------------------------------------
echo "[2/7] Filter (QUAL>=20, DP>=5)..."
bcftools filter \
  -e 'QUAL < 20 || INFO/DP < 5' \
  variants_raw.vcf \
  -o variants_filtered.vcf

echo "Filtered: $(grep -v '^#' variants_filtered.vcf | wc -l)"

# ---- Normalisasi -------------------------------------------------------
echo "[3/7] Normalisasi VCF..."
bcftools norm \
  -f reference.fna \
  -m- \
  variants_filtered.vcf \
  -o variants_norm.vcf

echo "Normalized: $(grep -v '^#' variants_norm.vcf | wc -l)"

# ---- Build database snpEff custom --------------------------------------
echo "[4/7] Build database snpEff custom dari reference + GFF3 NCBI..."

SNPEFF_DATA_DIR=~/wgs_candida/snpeff_data
mkdir -p "$SNPEFF_DATA_DIR/data/CaSC5314_custom"
cd "$SNPEFF_DATA_DIR"

cp ../mission02/reference.fna data/CaSC5314_custom/sequences.fa

if [ ! -f GCF_000182965.3_ASM18296v3_genomic.gff ]; then
  wget -c "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/182/965/GCF_000182965.3_ASM18296v3/GCF_000182965.3_ASM18296v3_genomic.gff.gz"
  gunzip GCF_000182965.3_ASM18296v3_genomic.gff.gz
fi
cp GCF_000182965.3_ASM18296v3_genomic.gff data/CaSC5314_custom/genes.gff

# Setup config snpEff jika belum ada
if [ ! -f snpEff.config ]; then
  SNPEFF_INSTALL_DIR=$(dirname "$(readlink -f "$(which snpEff)")")
  cp "$SNPEFF_INSTALL_DIR/snpEff.config" .
  echo "" >> snpEff.config
  echo "# Candida albicans SC5314 custom (GCF_000182965.3)" >> snpEff.config
  echo "CaSC5314_custom.genome : Candida_albicans_SC5314_custom" >> snpEff.config
fi

# Build -- wajib -noCheckCds -noCheckProtein, lihat catatan di atas
snpEff build -c snpEff.config -gff3 -noCheckCds -noCheckProtein -v CaSC5314_custom \
  > build_log.txt 2>&1

if [ -f "data/CaSC5314_custom/snpEffectPredictor.bin" ]; then
  echo "Database custom berhasil dibangun."
else
  echo "GAGAL: snpEffectPredictor.bin tidak terbentuk. Cek build_log.txt"
  exit 1
fi

cd ~/wgs_candida/mission04

# ---- Anotasi snpEff dengan database custom -----------------------------
echo "[5/7] Anotasi snpEff (database custom, -Xmx6g)..."
snpEff -Xmx6g ann -v \
  -c "$SNPEFF_DATA_DIR/snpEff.config" \
  -stats snpEff_summary.html \
  -csvStats snpEff_summary.csv \
  CaSC5314_custom \
  variants_norm.vcf > variants_annotated.vcf 2> snpeff_log.txt

# Verifikasi tidak ada error pemrosesan VCF (genome-build stats di
# bagian akhir log boleh diabaikan -- itu bukan error pemrosesan VCF)
if grep -q "ERROR_OUT_OF_CHROMOSOME_RANGE\|ERROR_CHROMOSOME_NOT_FOUND" snpeff_log.txt; then
  echo "PERINGATAN: terdeteksi chromosome mismatch error -- cek snpeff_log.txt"
else
  echo "Anotasi bersih: tidak ada chromosome mismatch error."
fi

# ---- Statistik ----------------------------------------------------------
echo ""
echo "======================================"
echo " VARIANT SUMMARY"
echo "======================================"
echo "Raw        : $(grep -v '^#' variants_raw.vcf | wc -l)"
echo "Filtered   : $(grep -v '^#' variants_filtered.vcf | wc -l)"
echo "Normalized : $(grep -v '^#' variants_norm.vcf | wc -l)"
echo "Missense   : $(grep -v '^#' variants_annotated.vcf | grep -c 'missense_variant')"
echo "Synonymous : $(grep -v '^#' variants_annotated.vcf | grep -c 'synonymous_variant')"
echo "Stop gained: $(grep -v '^#' variants_annotated.vcf | grep -c 'stop_gained')"

# ---- [6/7] Koordinat gen target resistansi -- TERVERIFIKASI -------------
# Koordinat berikut diverifikasi langsung dari genes.gff dengan:
#   grep -i "gene=<SYMBOL>" data/CaSC5314_custom/genes.gff
# JANGAN mengganti koordinat ini dengan estimasi dari sumber lain
# tanpa verifikasi ulang yang sama.
echo ""
echo "======================================"
echo " ANTIFUNGAL RESISTANCE -- KOORDINAT TERVERIFIKASI"
echo "======================================"
echo "Gen        Symbol di GFF   Lokasi                          GeneID"
echo "GSC1/FKS1  GSC1            NC_032089.1:505,969-511,662      3636794"
echo "ERG11      ERG11           NC_032093.1:148,115-149,701      3641571"
echo "TAC1       TAC1            NC_032093.1:416,400-419,345      3643755"

echo ""
echo "--- GSC1/FKS1 (echinocandin target) -- Chr1 ---"
grep -v "^#" variants_annotated.vcf | \
  awk '$1=="NC_032089.1" && $2>=505969 && $2<=511662' | wc -l

echo "--- ERG11 (azole target) -- Chr5 ---"
grep -v "^#" variants_annotated.vcf | \
  awk '$1=="NC_032093.1" && $2>=148115 && $2<=149701' | wc -l

echo "--- TAC1 (efflux regulator) -- Chr5 ---"
grep -v "^#" variants_annotated.vcf | \
  awk '$1=="NC_032093.1" && $2>=416400 && $2<=419345' | wc -l

echo ""
echo "======================================"
echo " MISSION 04 SELESAI"
echo "======================================"
echo "Output utama :"
echo "  - variants_annotated.vcf"
echo "  - snpEff_summary.html"
echo ""
echo "Buka laporan: explorer.exe snpEff_summary.html"
echo ""
echo "PENTING: Sebelum menafsirkan gen resistansi APAPUN selain"
echo "ketiga gen di atas, verifikasi koordinatnya terlebih dahulu:"
echo '  grep -i "gene=NAMA_GEN" ~/wgs_candida/snpeff_data/data/CaSC5314_custom/genes.gff'
