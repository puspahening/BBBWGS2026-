# WGS Pipeline: *Candida albicans* Antifungal Resistance Analysis

![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20WSL2-blue)
![Language](https://img.shields.io/badge/language-Bash-green)
![Organism](https://img.shields.io/badge/organism-C.%20albicans-purple)
![Status](https://img.shields.io/badge/status-complete-brightgreen)

Pipeline analisis Whole Genome Sequencing (WGS) *Candida albicans* untuk identifikasi varian resistansi antifungal, dikembangkan sebagai bagian dari praktikum mata kuliah **Bioinformatika**, Program Studi Bioteknologi, Universitas Diponegoro.

---

## Dataset

| Parameter | Nilai |
|---|---|
| Accession | SRR5876982 |
| Sumber | ENA (European Nucleotide Archive) |
| Sampel | FL22-passaged — isolat terpapar fluconazole dosis rendah |
| Platform | Illumina HiSeq 2500, paired-end 100bp |
| Reference Genome | SC5314 (GCF_000182965.3) |
| Ploidi | **DIPLOID** |

---

## Pipeline Overview

```
SRR5876982 (ENA)
      │
      ▼
[Mission 01] FastQC + MultiQC + fastp → clean reads
      │
      ▼
[Mission 02] BWA-MEM → alignment.sam (reference SC5314)
      │
      ▼
[Mission 03] SAMtools → alignment_sorted.bam (38x coverage)
      │
      ▼
[Mission 04] FreeBayes (--ploidy 2) → bcftools → snpEff → variants_annotated.vcf
      │
      ▼
Antifungal resistance profile (ERG11, FKS1, TAC1, CDR1)
```

---

## Cara Penggunaan

### 1. Setup environment

```bash
conda env create -f environment.yml
conda activate candida
```

### 2. Jalankan pipeline per mission

```bash
bash mission01/run_mission01.sh
bash mission02/run_mission02.sh
bash mission03/run_mission03.sh
bash mission04/run_mission04.sh
```

---

## Hasil Pipeline (SRR5876982)

| Tahap | Nilai |
|---|---|
| Raw reads | 3,317,159 |
| After trimming | 2,923,126 (88%) |
| Mapped to SC5314 | 94.90% |
| Mean coverage | **38.17x** |
| Raw variants | 84,885 |
| Filtered variants | 62,949 |
| Missense variants | 14,862 |
| Stop gained | 1,091 |
| Missense/Silent ratio | 3.57 |

---

## Gen Target Resistansi Antifungal

| Gen | Obat | Mekanisme | Varian Kunci |
|---|---|---|---|
| ERG11 | Azole (fluconazole) | Target inhibisi | Y132H, K143R, F145L |
| FKS1 | Echinocandin (caspofungin) | Target inhibisi | S645P, S645F |
| TAC1 | Azole | Regulator CDR1/CDR2 | Gain-of-function |
| CDR1/CDR2 | Azole | Efflux pump | Overexpression |
| ERG3 | Azole + Polyene | Ergosterol pathway | Loss-of-function |

---

## Temuan Kunci

- **FKS1 Hotspot HS1**: 3 varian heterozygous di posisi 1496950–1497120, termasuk MNP `TTG→CTA` kandidat **S645P** — marker resistansi echinocandin
- **Stop gained tinggi (1,091)**: Konsisten dengan adaptasi akibat tekanan fluconazole berulang
- **Missense/Silent ratio 3.57**: Menunjukkan banyak varian fungsional yang berpotensi mengubah protein

---

## Tools

| Tool | Versi | Fungsi |
|---|---|---|
| FastQC | 0.12.1 | Quality control |
| MultiQC | 1.34 | Agregasi QC |
| fastp | 1.3.3 | Trimming |
| BWA-MEM | 0.7.19 | Alignment |
| SAMtools | 1.x | BAM processing |
| FreeBayes | 1.x | Variant calling (diploid) |
| bcftools | 1.x | VCF filtering & normalization |
| snpEff | 5.4c | Variant annotation |

---

## Referensi

1. Perlin DS et al. (2015). The fungal cell wall and glucan synthase FKS1. *J Clin Microbiol*, 53, 1037-1044.
2. Pappas PG et al. (2018). Invasive candidiasis. *Nat Rev Dis Primers*, 4, 18026.
3. Weil T et al. (2017). Adaptive mistranslation accelerates fluconazole resistance. *mSphere*, 2, e00167-17.

---

*Puspa Hening, S.Pd., M.Biotech. — Bioteknologi UNDIP*
