# Panduan Interpretasi Hasil WGS *Candida albicans*

## Mengapa C. albicans Diploid Penting?

*C. albicans* adalah organisme **diploid obligat** — setiap gen memiliki dua salinan (alel).
Ini berpengaruh besar pada interpretasi VCF:

| Genotype | Kode VCF | Arti |
|---|---|---|
| Homozygous reference | 0/0 | Kedua alel wild-type |
| Heterozygous | 0/1 | Satu alel mutan, satu wild-type |
| Homozygous alt | 1/1 | Kedua alel mutan — Loss of Heterozygosity (LOH) |

Pada isolat yang terpapar antifungal berulang, sering terjadi **LOH** — alel mutan menjadi homozygous melalui mitotic recombination, meningkatkan level resistansi.

---

## Metodologi Verifikasi Koordinat Gen (WAJIB DIBACA)

Analisis awal pipeline ini mengasumsikan koordinat genomik gen target resistansi (FKS1, TAC1, ERG11) berdasarkan estimasi dari literatur umum. **Pendekatan ini terbukti salah** — koordinat yang diasumsikan untuk FKS1 ternyata berada pada gen PUT3/RBT4/MEF2, dan koordinat untuk TAC1/ERG11 berada pada kromosom yang salah.

**Pelajaran kunci**: koordinat genomik bersifat *assembly-specific*. Nama gen dan nomor kodon mutasi yang divalidasi di literatur (misalnya "S645 pada FKS1") tidak otomatis memberi tahu posisi genomik pada assembly tertentu — assembly yang berbeda (bahkan untuk strain yang sama) dapat memiliki koordinat berbeda akibat perbedaan penomoran kontig/kromosom.

### Metode verifikasi yang benar

```bash
# Cari gene symbol langsung di file GFF3 dari assembly yang SAMA PERSIS
# dengan yang dipakai untuk alignment
grep -i "gene=FKS1" data/CaSC5314_custom/genes.gff
grep -i "gene=ERG11" data/CaSC5314_custom/genes.gff
grep -i "gene=TAC1" data/CaSC5314_custom/genes.gff
```

Jika gene symbol tidak ditemukan secara eksplisit (seperti kasus FKS1, yang ternyata terdaftar dengan alias **GSC1**), cari berdasarkan deskripsi `product` atau `Note` di kolom atribut GFF3 (misalnya "1,3-beta-glucan synthase", "lanosterol 14-alpha-demethylase", "zinc cluster transcriptional activator").

**Jangan pernah** mengekstrak varian VCF berdasarkan koordinat sebelum koordinat tersebut diverifikasi dengan metode di atas.

---

## Koordinat Terverifikasi (Reference: GCF_000182965.3)

| Gen | Gene Symbol GFF | Lokasi | Locus Tag | GeneID |
|---|---|---|---|---|
| FKS1 | **GSC1** | NC_032089.1:505,969–511,662 (Chr1, strand −) | CAALFM_C102420CA | 3636794 |
| — | **ERG11** | NC_032093.1:148,115–149,701 (Chr5, strand −) | CAALFM_C500660CA | 3641571 |
| — | **TAC1** | NC_032093.1:416,400–419,345 (Chr5, strand −) | CAALFM_C501840CA | 3643755 |

Perhatikan bahwa **ERG11 dan TAC1 berada pada kromosom yang sama (Chr5)**, sesuatu yang tidak terduga dari asumsi awal yang menempatkan keduanya di kromosom berbeda (Chr2 dan Chr4).

---

## Gen Resistansi dan Interpretasi Varian

### GSC1/FKS1 — Resistansi Echinocandin (Caspofungin/Micafungin)

GSC1 (alias FKS1) mengkode subunit katalitik beta-1,3-glucan synthase, target langsung echinocandin.

Hotspot resistansi tervalidasi klinis:
- **HS1**: kodon 641–649 → **S645P dan S645F** paling umum
- **HS2**: kodon 1345–1365 (lebih jarang)

**Temuan pipeline ini**: 13 varian (2 missense: p.Thr1886Ser, p.Pro1838Ala), seluruhnya berada **di luar** HS1 dan HS2. **Wild-type** terhadap resistansi echinocandin — konsisten dengan riwayat paparan isolat yang hanya fluconazole, bukan echinocandin.

### ERG11 — Resistansi Azole (Fluconazole/Voriconazole)

ERG11 mengkode lanosterol 14α-demethylase, target langsung azole.

Substitusi klinis yang dipetakan ke empat region struktural Erg11 (catalytic site, external loop, proximal surface, proximal surface-to-heme) telah dikarakterisasi secara sistematis oleh Flowers et al. (2015) dengan memasukkan setiap alel ke dalam background strain SC5314 dan menguji kerentanannya terhadap fluconazole, itraconazole, dan voriconazole.

**Temuan pipeline ini**: 10 varian (2 missense: area K128T, p.Asp116Glu/D116E). Kombinasi alel dengan kedua substitusi ini (GenBank accession XM_711729) dikarakterisasi oleh Flowers et al. (2015) sebagai alel **wild-type** — tidak mempengaruhi level resistansi azole ketika diuji dalam background SC5314. **Wild-type secara fungsional**.

### TAC1 — Regulator Efflux Pump CDR1/CDR2

TAC1 mengkode zinc cluster transcription factor yang mengaktifkan ekspresi CDR1, CDR2, MDR1, dan ERG11 (Mahdizade Ari et al., 2024). Mutasi gain-of-function pada TAC1 meningkatkan ekspresi gen-gen tersebut, menyebabkan overekspresi efflux pump dan resistansi azole.

Berbeda dengan FKS1 dan ERG11, **TAC1 tidak memiliki katalog hotspot tunggal yang divalidasi secara luas**. Variannya dinilai melalui:
- Pengukuran ekspresi CDR1/CDR2 dengan RT-qPCR (Mahdizade Ari et al., 2024)
- Uji fungsional langsung pada sistem ekspresi homolog/heterolog
- Loss of heterozygosity pada Chr5, lokus yang juga berdekatan dengan MTL locus (Coste et al., 2004)

**Temuan pipeline ini**: 23 varian (9 missense), termasuk p.Leu941Pro (substitusi ke Proline — residu dengan struktur rigid yang berpotensi mengganggu konformasi). **Signifikansi belum dapat disimpulkan** dari data genomik saja — diperlukan data ekspresi gen untuk konfirmasi.

---

## Implikasi Klinis Keseluruhan

Karena kedua target obat utama (FKS1 untuk echinocandin, ERG11 untuk azole) terverifikasi **wild-type secara fungsional**, jika isolat FL22-passaged menunjukkan resistansi azole secara fenotipik, mekanismenya kemungkinan besar adalah:

1. **Overekspresi efflux pump** (CDR1/CDR2) — perlu konfirmasi via RT-qPCR, dengan TAC1 sebagai kandidat regulator (Coste et al., 2004; Mahdizade Ari et al., 2024)
2. **Aneuploidi kromosom** (terutama Chr5, yang mengandung baik TAC1 maupun ERG11) — perlu analisis copy number (YMAP/bedtools)
3. **Mekanisme non-genetik** (adaptasi epigenetik, perubahan komposisi membran) — di luar lingkup analisis WGS

Susceptibility testing fenotipik (E-test/EUCAST) sangat disarankan untuk mengonfirmasi apakah isolat ini benar-benar resistan secara fenotipik, mengingat profil genotipik target obat utamanya wild-type.

---

## Referensi
1. Flowers SA, Colón B, Whaley SG, Schuler MA, Rogers PD (2015). Contribution of clinically derived mutations in ERG11 to azole resistance in *Candida albicans*. *Antimicrobial Agents and Chemotherapy*, 59(1), 450–460. DOI: 10.1128/AAC.03470-14
2. Jones T, Federspiel NA, Chibana H, et al. (2004). The diploid genome sequence of *Candida albicans*. *PNAS*, 101(19), 7329–7334. DOI: 10.1073/pnas.0401648101
3. Mahdizade Ari AH, Hoseinnejad A, Ghazanfari M, Boozhmehrani MJ, Bahreiny SS, Abastabar M, Galbo R, Giuffrè L, Haghani I, Romeo O (2024). The TAC1 Gene in *Candida albicans*: Structure, Function, and Role in Azole Resistance: A Mini-Review. *Microbial Drug Resistance*, 30(7), 288–296. DOI: 10.1089/mdr.2023.0334
4. National Center for Biotechnology Information (NCBI). *Candida albicans* SC5314 genome assembly ASM18296v3, RefSeq accession: GCF_000182965.3. https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000182965.3/
5. Ruiz-Baca E, Arredondo-Sánchez RI, Corral-Pérez K, López-Rodríguez A, Meneses-Morales I, Ayala-García VM, Martínez-Rocha AL (2021). Molecular Mechanisms of Resistance to Antifungals in *Candida albicans*. In: *Candida and Candidiasis*. IntechOpen. DOI: 10.5772/intechopen.95108
