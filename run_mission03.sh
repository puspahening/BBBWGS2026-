#!/bin/bash
# ============================================================
# MISSION 03 — BAM Processing & QC
# Tools   : SAMtools
# Input   : alignment.sam (dari Mission 02)
# Output  : alignment_sorted.bam + .bai
# ============================================================

set -euo pipefail

echo "======================================"
echo " MISSION 03: BAM PROCESSING"
echo "======================================"

mkdir -p ~/wgs_candida/mission03
cd ~/wgs_candida/mission03

cp ../mission02/alignment.sam .
cp ../mission02/reference.fna .

echo "[1/4] SAM → BAM..."
samtools view -Sb -@ 4 alignment.sam > alignment.bam

echo "[2/4] Sort BAM..."
samtools sort -@ 4 alignment.bam -o alignment_sorted.bam

echo "[3/4] Index BAM..."
samtools index alignment_sorted.bam

# Hapus file sementara
rm alignment.sam alignment.bam

echo "[4/4] QC alignment..."
samtools quickcheck alignment_sorted.bam && echo "BAM OK"

echo ""
echo "=== FLAGSTAT ==="
samtools flagstat alignment_sorted.bam | tee flagstat_output.txt

echo ""
echo "=== COVERAGE PER KROMOSOM ==="
samtools coverage alignment_sorted.bam | tee coverage_output.txt

echo ""
echo "=== MEAN DEPTH ==="
samtools depth -a alignment_sorted.bam | \
  awk '{sum+=$3; count++} END {printf "Mean depth: %.2fx\n", sum/count}'

echo ""
echo "======================================"
echo " MISSION 03 SELESAI"
echo "======================================"
echo "Expected: mapped ~95%, mean depth ~38x"
echo "Output: alignment_sorted.bam + .bai"
