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

## Gen Resistansi dan Interpretasi Varian

### FKS1 — Resistansi Echinocandin (Caspofungin/Micafungin)
FKS1 mengkode subunit beta-1,3-glucan synthase, target langsung echinocandin.

Hotspot resistansi:
- **HS1**: sekitar codon 641–649 → **S645P dan S645F** paling umum
- **HS2**: sekitar codon 1345–1365 (lebih jarang)

Temuan pipeline ini: 3 varian heterozygous (0/1) di HS1 termasuk kandidat **S645P** (MNP TTG→CTA di posisi 1497120). Heterozygous menunjukkan isolat sedang dalam proses akuisisi resistansi.

### ERG11 — Resistansi Azole (Fluconazole/Voriconazole)
ERG11 mengkode lanosterol 14α-demethylase, target langsung azole.

Mutasi umum: Y132H, K143R, F145L, D446E, G448E, G464S.
Tidak terdeteksi pada sampel ini → kemungkinan mekanisme resistansi melalui efflux pump (CDR1/CDR2), bukan mutasi target.

### TAC1 — Regulator Efflux Pump CDR1/CDR2
TAC1 adalah transcription factor yang mengaktifkan ekspresi CDR1 dan CDR2.
Gain-of-function mutations di TAC1 → overekspresi CDR1/CDR2 → fluconazole dipompa keluar sel.
14 varian ditemukan di region TAC1 pada sampel ini.

### ERG3 — Resistansi Azole + Polyene
Loss-of-function mutations di ERG3 mencegah akumulasi sterol toksik saat azole digunakan,
menyebabkan cross-resistance terhadap azole dan polyene (amphotericin B).

---

## Interpretasi Anomali supercont4.1:2700000

Ditemukan 262,736 varian dalam satu window 100kb — bukan varian biologis nyata.

Penyebab yang mungkin:
- Region subtelomeric yang sangat polimorfik
- Transposable elements (*Zorro* family di *C. albicans*)
- Collapsed assembly dari repeated sequences (tandem repeats)

Region ini wajib dieksklusi menggunakan `bcftools view --targets "^supercont4.1:2700000-2800000"`.

---

## Missense/Silent Ratio = 3.57

| Ratio | Interpretasi |
|---|---|
| ~2.0–2.5 | Normal — tekanan seleksi netral |
| **3.57** | **Tinggi — tekanan seleksi positif** |
| >5.0 | Sangat tinggi — mungkin artefak |

Ratio 3.57 pada FL22-passaged menunjukkan banyak mutasi non-synonymous yang lolos seleksi karena menguntungkan di bawah tekanan fluconazole — konsisten dengan adaptasi aktif.

---

## Referensi

1. Flowers SA, Colón B, Whaley SG, Schuler MA, Rogers PD (2015). Contribution of clinically derived mutations in ERG11 to azole resistance in Candida albicans. Antimicrobial Agents and Chemotherapy, 59(1), 450–460. DOI: 10.1128/AAC.03470-14 
2. Jones T, Federspiel NA, Chibana H, Dungan J, Kalman S, Magee BB, Newport G, Thorstenson YR, Agabian N, Magee PT, Davis RW, Scherer S (2004). The diploid genome sequence of Candida albicans. Proceedings of the National Academy of Sciences, 101(19), 7329–7334. DOI: 10.1073/pnas.0401648101 
3. Mahdizade Ari AH, Hoseinnejad A, Ghazanfari M, Boozhmehrani MJ, Bahreiny SS, Abastabar M, Galbo R, Giuffrè L, Haghani I, Romeo O (2024). The TAC1 Gene in Candida albicans: Structure, Function, and Role in Azole Resistance: A Mini-Review. Microbial Drug Resistance, 30(7), 288–296. DOI: 10.1089/mdr.2023.0334 
4. National Center for Biotechnology Information (NCBI). Candida albicans SC5314 genome assembly ASM18296v3, RefSeq accession: GCF_000182965.3. Available at: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000182965.3/ 
5. Ruiz-Baca E, Arredondo-Sánchez RI, Corral-Pérez K, López-Rodríguez A, Meneses-Morales I, Ayala-García VM, Martínez-Rocha AL (2021). Molecular Mechanisms of Resistance to Antifungals in Candida albicans. Dalam: Candida and Candidiasis. IntechOpen. DOI: 10.5772/intechopen.95108
