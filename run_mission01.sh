#!/bin/bash
# ============================================================
# MISSION 01 — Quality Control & Trimming
# Dataset : SRR5876982 (C. albicans FL22-passaged, ENA)
# Tools   : FastQC, MultiQC, fastp
# ============================================================

set -euo pipefail

echo "======================================"
echo " MISSION 01: QC & TRIMMING"
echo "======================================"

mkdir -p ~/wgs_candida/mission01
cd ~/wgs_candida/mission01

# Download dari ENA
echo "[1/5] Downloading SRR5876982 dari ENA..."
wget -c ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR587/002/SRR5876982/SRR5876982_1.fastq.gz
wget -c ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR587/002/SRR5876982/SRR5876982_2.fastq.gz

echo "[2/5] Ekstrak FASTQ..."
gunzip SRR5876982_1.fastq.gz
gunzip SRR5876982_2.fastq.gz

echo "Reads R1: $(wc -l < SRR5876982_1.fastq | awk '{print $1/4}')"
echo "Reads R2: $(wc -l < SRR5876982_2.fastq | awk '{print $1/4}')"

# QC raw reads
echo "[3/5] FastQC & MultiQC raw reads..."
fastqc SRR5876982_1.fastq SRR5876982_2.fastq -o . -t 4
multiqc . -o . --filename multiqc_raw

# Trimming
# Data kualitasnya bagus (Q30 >85%), parameter standar cukup
echo "[4/5] Trimming dengan fastp..."
fastp \
  -i SRR5876982_1.fastq \
  -I SRR5876982_2.fastq \
  -o sample_clean_1.fastq \
  -O sample_clean_2.fastq \
  --detect_adapter_for_pe \
  --qualified_quality_phred 20 \
  --unqualified_percent_limit 40 \
  --n_base_limit 5 \
  --length_required 50 \
  --thread 4 \
  --html fastp_report.html \
  --json fastp_report.json

echo "[5/5] FastQC post-trimming..."
fastqc sample_clean_1.fastq sample_clean_2.fastq -o . -t 4

echo ""
echo "======================================"
echo " MISSION 01 SELESAI"
echo "======================================"
echo "Reads sebelum : $(wc -l < SRR5876982_1.fastq | awk '{print $1/4}')"
echo "Reads sesudah : $(wc -l < sample_clean_1.fastq | awk '{print $1/4}')"
echo "Buka laporan  : explorer.exe fastp_report.html"
