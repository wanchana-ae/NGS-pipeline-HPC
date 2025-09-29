#!/bin/bash
#SBATCH --job-name=haplotypecaller
#SBATCH --array=1-50
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/data/home/wanchana/Water_Buffaloes/Call_SNP/log/haplotypecaller_%A_%a.log
#SBATCH --nodelist=compute-02
set -euo pipefail
ml load gatk

# Set directory paths
#BASE_DIR="/data/home/wanchana/Water_Buffaloes/Call_SNP/"
IN_DIR_MAPPED="/data/home/wanchana/Water_Buffaloes/Call_SNP/Mapped/"
OUT_DIR_GVCF="/data/home/wanchana/Water_Buffaloes/Call_SNP/GVCF/"
#REF_DIR="/data/home/wanchana/Water_Buffaloes/Ref/"

mkdir -p ${OUT_DIR_GVCF}

# Reference genome
REFERENCE="/data/home/wanchana/Water_Buffaloes/Ref/NDDB_SH_1_chr.fasta"

# Sample metadata
INFO_FILE="metadata_part2.txt"

# Get line corresponding to SLURM_ARRAY_TASK_ID
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INFO_FILE)
#SEQ_ID=$(echo ${LINE} | cut -d"," -f1)
SAMPLE_ID=$(echo ${LINE} | cut -d"," -f2)
IN_BAM="${IN_DIR_MAPPED}${SAMPLE_ID}_MD.bam"
OUT_GVCF="${OUT_DIR_GVCF}${SAMPLE_ID}.g.vcf.gz"

# Run HaplotypeCaller
echo "Running HaplotypeCaller for $SAMPLE_ID"
gatk --java-options "-Xmx16G" HaplotypeCaller \
    -R ${REFERENCE} \
    -I ${IN_BAM} \
    -O ${OUT_GVCF} \
    -ERC GVCF \
    --native-pair-hmm-threads 8 \
    2>&1 | tee -a ${OUT_DIR_GVCF}${SAMPLE_ID}_haplotypecaller.log

# MD5 checksum
md5sum ${OUT_GVCF} > ${OUT_GVCF}.md5

echo "HaplotypeCaller completed for $SAMPLE_ID"
