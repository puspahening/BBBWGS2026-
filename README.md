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
[Mission 04] FreeBayes (--ploidy 2) → bcftools → snpEff (custom DB) → variants_annotated.vcf
      │
      ▼
Antifungal resistance profile (GSC1/FKS1, ERG11, TAC1)
```

---

## ⚠️ Catatan Penting: Database snpEff Custom

Semua database snpEff publik untuk *C. albicans* (termasuk `Candida_albicans_sc5314_gca_000784635`) menggunakan **assembly lama yang fragmented** (38–77 scaffold), yang **tidak kompatibel** dengan reference genom modern 8-kromosom (GCF_000182965.3) yang dipakai untuk alignment di pipeline ini.

Mission 04 karena itu **membangun database snpEff custom** langsung dari `reference.fna` + GFF3 resmi NCBI, bukan menggunakan database publik. Ini menghindari `ERROR_OUT_OF_CHROMOSOME_RANGE` yang muncul ribuan kali jika memaksakan rename kromosom ke database publik.

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

Mission 04 akan otomatis mengunduh GFF3 NCBI dan membangun database snpEff custom pada eksekusi pertama (memerlukan koneksi internet, ±1-2 menit tambahan).

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

---

## Profil Resistansi Antifungal — Terverifikasi

Koordinat genomik ketiga gen berikut **diverifikasi langsung** dari file GFF3 resmi NCBI (`grep -i "gene=<SYMBOL>" genes.gff`), bukan estimasi dari literatur umum. Lihat `docs/interpretation.md` untuk metodologi verifikasi lengkap.

| Gen | Gene Symbol GFF | Lokasi (GCF_000182965.3) | GeneID | Status |
|---|---|---|---|---|
| FKS1 | **GSC1** | NC_032089.1:505,969–511,662 (Chr1) | 3636794 | **Wild-type** (HS1 & HS2) |
| Fluconazole target | **ERG11** | NC_032093.1:148,115–149,701 (Chr5) | 3641571 | **Wild-type** (fungsional) |
| Efflux regulator | **TAC1** | NC_032093.1:416,400–419,345 (Chr5) | 3643755 | Belum dapat disimpulkan |

### Ringkasan Temuan

- **GSC1/FKS1** (target echinocandin): 13 varian (2 missense), seluruhnya di luar Hotspot HS1 (kodon 641–649) dan HS2 (kodon 1345–1365). **Wild-type** terhadap resistansi echinocandin.
- **ERG11** (target fluconazole): 10 varian (2 missense: K128T, D116E). Kedua substitusi telah dikarakterisasi sebagai wild-type/non-resistan — Flowers et al. (2015) menguji kombinasi alel ini dalam background strain SC5314 dan mengklasifikasikannya tidak mempengaruhi sensitivitas azole.
- **TAC1** (regulator efflux pump CDR1/CDR2): 23 varian (9 missense, termasuk p.Leu941Pro). Berbeda dengan FKS1 dan ERG11, TAC1 tidak memiliki katalog hotspot tunggal yang divalidasi secara luas — variannya dinilai melalui pengukuran ekspresi CDR1/CDR2, bukan posisi mutasi (Mahdizade Ari et al., 2024). Signifikansi fungsional varian-varian ini **memerlukan RT-qPCR** ekspresi CDR1/CDR2 untuk konfirmasi.
- **Implikasi**: karena kedua target obat utama (FKS1 untuk echinocandin, ERG11 untuk azole) wild-type secara fungsional, mekanisme resistansi azole pada isolat ini — jika ada — kemungkinan besar melalui **overekspresi efflux pump**, bukan mutasi titik pada target obat.

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
| snpEff | 5.4c | Variant annotation (custom database) |

---

## Referensi

1. Coste AT, Karababa M, Ischer F, Bille J, Sanglard D (2004). TAC1, transcriptional activator of CDR genes, is a new transcription factor involved in the regulation of *Candida albicans* ABC transporters CDR1 and CDR2. *Eukaryotic Cell*, 3(6), 1639–1652. DOI: 10.1128/EC.3.6.1639-1652.2004
2. Flowers SA, Colón B, Whaley SG, Schuler MA, Rogers PD (2015). Contribution of clinically derived mutations in ERG11 to azole resistance in *Candida albicans*. *Antimicrobial Agents and Chemotherapy*, 59(1), 450–460. DOI: 10.1128/AAC.03470-14
3. Jones T, Federspiel NA, Chibana H, et al. (2004). The diploid genome sequence of *Candida albicans*. *PNAS*, 101(19), 7329–7334. DOI: 10.1073/pnas.0401648101
4. Mahdizade Ari AH, Hoseinnejad A, Ghazanfari M, et al. (2024). The TAC1 Gene in *Candida albicans*: Structure, Function, and Role in Azole Resistance: A Mini-Review. *Microbial Drug Resistance*, 30(7), 288–296. DOI: 10.1089/mdr.2023.0334
5. National Center for Biotechnology Information (NCBI). *Candida albicans* SC5314 genome assembly ASM18296v3, RefSeq accession: GCF_000182965.3. https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000182965.3/
6. Ruiz-Baca E, Arredondo-Sánchez RI, Corral-Pérez K, López-Rodríguez A, Meneses-Morales I, Ayala-García VM, Martínez-Rocha AL (2021). Molecular Mechanisms of Resistance to Antifungals in *Candida albicans*. In: *Candida and Candidiasis*. IntechOpen. DOI: 10.5772/intechopen.95108

---

*Puspa Hening, S.Pd., M.Biotech. — Bioteknologi UNDIP*
