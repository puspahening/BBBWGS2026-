#!/bin/bash
# ============================================================
# MISSION 02 — Alignment ke Reference Genome SC5314
# Tools   : BWA-MEM
# Input   : sample_clean_1/2.fastq (dari Mission 01)
# Output  : alignment.sam
# ============================================================

set -euo pipefail

echo "======================================"
echo " MISSION 02: ALIGNMENT"
echo "======================================"

mkdir -p ~/wgs_candida/mission02
cd ~/wgs_candida/mission02

echo "[1/4] Copy clean reads dari Mission 01..."
cp ../mission01/sample_clean_1.fastq .
cp ../mission01/sample_clean_2.fastq .

# Reference genome SC5314 dari NCBI
# GCF_000182965.3 = assembly terbaru SC5314 (8 kromosom, ~14.3 Mb)
echo "[2/4] Download reference genome SC5314..."
wget -c "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/182/965/GCF_000182965.3_ASM18296v3/GCF_000182965.3_ASM18296v3_genomic.fna.gz"
gunzip GCF_000182965.3_ASM18296v3_genomic.fna.gz
mv GCF_000182965.3_ASM18296v3_genomic.fna reference.fna

# Verifikasi 8 kromosom C. albicans (Chr1-7 + ChrR)
echo "Kromosom dalam reference:"
grep "^>" reference.fna

echo "[3/4] Index reference (±1 menit)..."
bwa index reference.fna

# Alignment dengan Read Group
# Read Group wajib untuk variant calling yang akurat
echo "[4/4] Alignment BWA-MEM..."
bwa mem \
  -t 4 \
  -R '@RG\tID:SRR5876982\tSM:Ca_FL22\tPL:ILLUMINA\tLB:lib1\tPU:SRR5876982' \
  reference.fna \
  sample_clean_1.fastq \
  sample_clean_2.fastq \
  > alignment.sam

echo ""
echo "======================================"
echo " MISSION 02 SELESAI"
echo "======================================"
echo "Ukuran alignment.sam: $(du -sh alignment.sam | cut -f1)"
