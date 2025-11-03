# NGS Pipeline HPC

This repository contains high-performance computing (HPC) pipelines for processing NGS data on SLURM-managed clusters. It currently includes:

1. **FASTQ preprocessing using `fastp`**
2. **Alignment and post-processing using `Bowtie2` and `Picard`**
3. **Variant calling using `GATK HaplotypeCaller`**

## Workflow Overview

The following diagram shows the full NGS pipeline workflow:

```
                 ┌───────────────┐
                 │   Raw FASTQ   │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │   fastp QC    │
                 │ (trim + QC)   │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │   Trimmed     │
                 │   FASTQ       │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │  Bowtie2      │
                 │  Alignment    │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │  Picard       │
                 │  Add RG +     │
                 │  FixMate +    │
                 │  MarkDuplicates │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │  Final BAM    │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │  GATK         │
                 │  HaplotypeCaller │
                 └──────┬────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │  GVCF files   │
                 └───────────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │  CombineGVCFs │
                 └───────────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │ Combined GVCF │
                 └───────────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │ GenotypeGVCFs │
                 └───────────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │   VCF files   │
                 └───────────────┘
                        │
                        ▼
                 ┌───────────────┐
                 │   GatherVcfs  │
                 └───────────────┘
              
```

---

## 0. Prepare Bowtie2 Index

- Before running the alignment pipeline, you need to build a Bowtie2 index for your reference genome.

```bash
# Load module
ml load bowtie2

# Paths
REF_FASTA="/path/to/Ref/REFERENCE.fasta"
BT2_INDEX="/path/to/Ref/REFERENCE"

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

### SLURM Script Snippet `*** WARNING Please Read ***`

After fastp finishes, remove raw FASTQ files to save space
If you need to keep raw FASTQ, comment in `submit_fastp_array.sh` file in lines:

```bash
rm "$IN1" #This line will remove raw FASTQ
rm "$IN2" #This line will remove raw FASTQ

# Comment to

#rm "$IN1" #comment and keep raw FASTQ
#rm "$IN2" #comment and keep raw FASTQ
```

### SLURM Script Example

```bash
#!/bin/bash
#SBATCH --job-name=fastp_array
#SBATCH --array=1-50           # Distribute 50 jobs
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8      # Use 8 cores per sample
#SBATCH --mem=16G               # Allocate 16GB RAM per sample
#SBATCH --output=/path/to/log/fastp_%A_%a.log

ml load fastp

# Paths

# Read input file (sequencing ID, sample ID, seq_1.fq.gz, seq_2.fq.gz)
INPUT_FILE="metadata.txt"
OUT_trim="/path/to/TrimmedFastq/"
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INPUT_FILE)

# Run FASTQ Preprocessing pipeline...
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
#SBATCH --output /path/to/log/bowtie2_%A_%a.log

ml load bowtie2
ml load picard
ml load samtools

# Paths
OUT_MAPPED="/path/to/Mapped/"
OUT_TRIMED="/path/to/TrimmedFastq/"
BT2_INDEX="/path/to/Ref/REFERENCE"

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

## 3. Variant Calling with GATK HaplotypeCaller

### Metadata File Format

- Can use the same metadata.txt as for fastp, e.g.:

```
SEQ001,SAMPLE_A
SEQ002,SAMPLE_B
```

### SLURM Script Example

```bash
#!/bin/bash
#SBATCH --job-name=haplotypecaller
#SBATCH --array=1-50
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/path/to/log/haplotypecaller_%A_%a.log
#SBATCH --nodelist=compute-02

ml load gatk

# Paths

IN_DIR_MAPPED="/path/to/Mapped/"
OUT_DIR_GVCF="/path/to/GVCF/"
REFERENCE="/path/to/Ref/REFERENCE.fasta"

INFO_FILE="metadata.txt"

mkdir -p ${OUT_DIR_GVCF}

# Read sample information
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INFO_FILE)
SAMPLE_ID=$(echo ${LINE} | cut -d"," -f2)
IN_BAM="${IN_DIR_MAPPED}${SAMPLE_ID}_MD.bam"
OUT_GVCF="${OUT_DIR_GVCF}${SAMPLE_ID}.g.vcf.gz"

# Run HaplotypeCaller pipeline...
gatk --java-options "-Xmx16G" HaplotypeCaller \
    -R ${REFERENCE} \
    -I ${IN_BAM} \
    -O ${OUT_GVCF} \
    -ERC GVCF \
    --native-pair-hmm-threads 8 \
    2>&1 | tee -a ${OUT_DIR_GVCF}${SAMPLE_ID}_haplotypecaller.log
md5sum ${OUT_GVCF} > ${OUT_GVCF}.md5
```

### Usage

1. Edit metadata.txt to include your sample information.
2. Submit the SLURM job array:

```bash
sbatch submit_haplotypecaller_array.sh
```

## 4. Combine Variant Calling file with GATK CombineGVCFs

### Prepare File

- `GVCF_LIST` File contain name and path gvcf from HaplotypeCaller step. e.g.:

```
/path/to/GVCF/SAMPLE_A.g.vcf.gz
/path/to/GVCF/SAMPLE_B.g.vcf.gz  
/path/to/GVCF/SAMPLE_C.g.vcf.gz
```

Add *.list* to the file name (e.g., example.list)

- `Chr_file` File chrmosome name or genomic intervals over which to operate. e.g.:

```
1
2
3
4
...
```

### SLURM Script Example

```bash
#!/bin/bash
#SBATCH --job-name=combine_gvcfs
#SBATCH --array=1-50
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/path/to/log/combine_gvcfs_%A_%a.log

ml load gatk  # Adjust module version as needed

# Paths
GVCF_LIST="/path/to/GVCF/GVCF.list"
REFERENCE="/path/to/Ref/REFERENCE.fasta"
OUT_dir="/path/output/Combine_gvcf/"
Chr_file="/path/to/chr.list"

# Get line corresponding to SLURM_ARRAY_TASK_ID
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $Chr_file)
Number_chr=$(echo ${LINE} | cut -d"," -f1)

# Run HaplotypeCaller
echo "CombineGVCFsr for ${Number_chr}"

gatk --java-options "-Xmx64G -XX:ParallelGCThreads=16" CombineGVCFs \
    -R ${REFERENCE} \
    --variant ${GVCF_LIST} \
    -L ${Number_chr} \
    -O ${OUT_dir}Prefix_output_Chr${Number_chr}.g.vcf.gz 2>&1 | tee -a Prefix_output_Chr${Number_chr}.log

echo "CombineGVCFs completed for ${Number_chr}"
```

### Usage

1. Edit GVCF.list to include your gvcf information.
2. Edit chr.list fllow chrmosome name of REFERENCE.fasta.
3. Submit the SLURM job array:

```bash
sbatch submit_combine_gvcf_array.sh
```

## 5. GATK GenotypeGVCFs to generate VCF files from individual GVCF files

📌 Overview

This script runs GATK GenotypeGVCFs to generate VCF files from individual GVCF files (samples) using a SLURM job array for parallel execution on an HPC cluster.

📝 Input

File: name_gvcf.txt
A text file listing the full path of each GVCF file, one sample per line, e.g.:

```bash
/path/to/sample1.g.vcf.gz
/path/to/sample2.g.vcf.gz
```

🖥️ SLURM Job Configuration

```bash
#SBATCH --job-name=Genotype_GVCFs
#SBATCH --array=1-11              # Number of samples (adjust according to name_gvcf.txt lines)
#SBATCH --cpus-per-task=16        # CPU cores per job
#SBATCH --mem=64G                 # Memory per job
#SBATCH --output=/.../log/GenotypeGVCFs_%A_%a.log
```

Set path

- **GVCF_LIST** A text file containing the full path of each .g.vcf.gz file, one per sample.
- **REFERENCE** The reference genome used for genotyping.
- **OUT_dir** Directory where output .vcf.gz and .log files will be saved.

```bash
GVCF_LIST="/path/to/name_gvcf.txt"
REFERENCE="/path/to/Ref/REFERENCE.fasta"
OUT_dir="/path/output/VCF/"
```

🚀 Running the Script

Load the GATK module and submit the job via SLURM:

```bash
sbatch Genotype_GVCFs.sh
```

📤 Output

For each sample, the script produces:

```bash
VCF/<sample_name>.vcf.gz
VCF/<sample_name>.log
```

## 6.GATK GatherVcfs Pipeline

📘 Overview

This script merges multiple chromosome-level VCF files into a single genome-wide VCF file using
a tool that concatenates variant files produced by GATK.

```bash
📂 Directory Structure
/data/home/wanchana/Coconut/FF68/
├── log/
│   └── GatherVcfs_<jobID>.log
├── VCF/
│   ├──VCF_Chr1.vcf.gz
│   ├──VCF_Chr2.vcf.gz
│   ├── ...
│   ├──VCF_Chr11.vcf.gz
│   └──VCF.raw.vcf.gz   # ← final merged output
└── scripts/
    └── GatherVcfs.sh
```

▶️ Running the Job

Submit the job via SLURM:

```bash
sbatch scripts/GatherVcfs.sh
```

📥 Input

Multiple per-chromosome .vcf.gz files such as:

```bash
VCF_Chr1.vcf.gz
VCF_Chr2.vcf.gz
...
VCF_Chr11.vcf.gz
```

📤 Output

- Merged VCF file:

```bash
./VCF/Vigina_radiata_405ea.raw.vcf.gz
```

- GATK log file:

```bash
./VCF/Vigina_radiata_405ea.log
```

- SLURM log file:

```bash
./log/GatherVcfs_<jobID>.log
```

### Requirements

- SLURM workload manager
- fastp
- bowtie2
- picard
- samtools
- gatk
- Module environment (ml load) or conda/mamba installation

### Notes

- Ensure output directories exist and have sufficient storage.
- Intermediate files are removed automatically; final BAM and GVCF files are preserved.
- MD5 checksums are generated for all final files to verify integrity.
