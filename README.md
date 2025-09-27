# NGS Pipeline HPC

This repository contains high-performance computing (HPC) pipelines for processing NGS data on SLURM-managed clusters. It currently includes:

1. **FASTQ preprocessing using `fastp`**
2. **Alignment and post-processing using `Bowtie2` and `Picard`**

---
## 0. Prepare Bowtie2 Index

- Before running the alignment pipeline, you need to build a Bowtie2 index for your reference genome.

```bash
# Load module
ml load bowtie2

# Paths
REF_FASTA="/path/to/Ref/NDDB_SH_1_chr.fasta"
BT2_INDEX="/path/to/Ref/NDDB_SH_1_chr"

# Build index
bowtie2-build ${REF_FASTA} ${BT2_INDEX}
```
## 1. FASTQ Preprocessing with `fastp`

### Features
- Parallel processing using SLURM job arrays
- Generates trimmed FASTQ files and quality reports (HTML & JSON)
- MD5 checksum validation for data integrity
- Automatic cleanup of raw FASTQ files to save storage

### Metadata File Format
```
sequencing_id,sample_id,read1.fastq.gz,read2.fastq.gz
SEQ001,SAMPLE_A,/path/to/sampleA_R1.fq.gz,/path/to/sampleA_R2.fq.gz
SEQ002,SAMPLE_B,/path/to/sampleB_R1.fq.gz,/path/to/sampleB_R2.fq.gz
```

### Usage
1. Edit metadata.csv to include your sample information.
2. Submit the SLURM job array:
```bash
sbatch submit_fastp_array.sh
```

## 2. Alignment and Post-processing with Bowtie2 + Picard

### Features
- Align paired-end FASTQ to reference genome using Bowtie2
- Add read groups, fix mate information, and mark duplicates using Picard
- Generates BAM files with index and MD5 checksum validation
- Cleans up intermediate files to save storage

### Metadata File Format
- Can use the same metadata.txt as for fastp, e.g.:
```
SEQ001,SAMPLE_A
SEQ002,SAMPLE_B
```
### SLURM Script Example

```bash
#!/bin/bash
#SBATCH --job-name=bowtie2
#SBATCH --array=1-50
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --nodelist=compute-02
#SBATCH --output /path/to/log/bowtie2_%A_%a.log

ml load bowtie2
ml load picard
ml load samtools

# Paths
OUT_MAPPED="/path/to/Mapped/"
OUT_TRIMED="/path/to/TrimmedFastq/"
BT2_INDEX="/path/to/Ref/NDDB_SH_1_chr"

mkdir -p ${OUT_MAPPED}

INFO_FILE="metadata.txt"

# Read sample information
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INFO_FILE)
SEQ_ID=$(echo ${LINE} | cut -d"," -f1)
SAMPLE_ID=$(echo ${LINE} | cut -d"," -f2)
IN1="${OUT_TRIMED}${SAMPLE_ID}_1.fastq"
IN2="${OUT_TRIMED}${SAMPLE_ID}_2.fastq"

# Run Bowtie2 and Picard pipeline...

```
### Usage
1. Edit metadata.txt to include your sample information.
2. Submit the SLURM job array:
```bash
sbatch submit_bowtie2_array.sh
```

### Requirements
- SLURM workload manager
- fastp
- bowtie2
- picard
- samtools
- Module environment (ml load) or conda/mamba installation

### Notes
- Ensure output directories exist and have sufficient storage.
- Intermediate files are removed automatically; final BAM files are preserved.
- MD5 checksums are generated for all final files to verify integrity.