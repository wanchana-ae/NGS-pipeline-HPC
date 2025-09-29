#!/bin/bash
#SBATCH --job-name=bowtie2
#SBATCH --array=1-50
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --nodelist=compute-02
#SBATCH --output /data/home/wanchana/Water_Buffaloes/Call_SNP/log/bowtie2_%A_%a.log
set -euo pipefail
ml load bowtie2
ml load picard
ml load samtools

# Set base directory paths (HDD)
#BASE_DIR="/data/home/wanchana/Water_Buffaloes/Call_SNP/"
OUT_MAPPED="/data/home/wanchana/Water_Buffaloes/Call_SNP/Mapped/"
OUT_TRIMED="/data/home/wanchana/Water_Buffaloes/raw_data_ncbi/fastq/"
#REF_DIR="/data/home/wanchana/Water_Buffaloes/Ref/"
BT2_INDEX="/data/home/wanchana/Water_Buffaloes/Ref/NDDB_SH_1_chr"

# Create necessary directories if they do not exist
mkdir -p ${OUT_MAPPED}

# Sample metadata file
INFO_FILE="metadata.txt"

# Set parameters
PLATFORM="ILLUMINA"

# Read sample information
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INFO_FILE)
SEQ_ID=$(echo ${LINE} | cut -d"," -f1)
SAMPLE_ID=$(echo ${LINE} | cut -d"," -f2)
IN1="${OUT_TRIMED}${SAMPLE_ID}_1.fastq"
IN2="${OUT_TRIMED}${SAMPLE_ID}_2.fastq"

# Function to run Bowtie2
run_bowtie2() {
    echo "Running Bowtie2 for sample: $SAMPLE_ID"
    bowtie2 -p 16 -t \
        -x ${BT2_INDEX} \
        -1 $IN1 -2 $IN2 \
        -S ${OUT_MAPPED}${SAMPLE_ID}.sam \
        2>&1 | tee -a ${OUT_MAPPED}${SAMPLE_ID}.bowtie2.log
    md5sum ${OUT_MAPPED}${SAMPLE_ID}.sam > ${OUT_MAPPED}${SAMPLE_ID}.sam.md5
}

# Function to add read groups
run_add_read_groups() {
    echo "Adding Read Groups for $SAMPLE_ID"
    picard AddOrReplaceReadGroups \
        -INPUT ${OUT_MAPPED}${SAMPLE_ID}.sam \
        -OUTPUT ${OUT_MAPPED}${SAMPLE_ID}_ADD.bam \
        -SORT_ORDER coordinate \
        -CREATE_INDEX true \
        -VALIDATION_STRINGENCY LENIENT \
        -RGID $SAMPLE_ID -RGLB $SAMPLE_ID -RGPL $PLATFORM -RGPU $SEQ_ID -RGSM $SAMPLE_ID \
        2>&1 | tee -a ${OUT_MAPPED}${SAMPLE_ID}_ADD.log
    md5sum ${OUT_MAPPED}${SAMPLE_ID}_ADD.bam > ${OUT_MAPPED}${SAMPLE_ID}_ADD.md5
}

# Function to run FixMateInformation
run_fixmate() {
    echo "Running FixMate for $SAMPLE_ID"
    picard FixMateInformation \
        -I ${OUT_MAPPED}${SAMPLE_ID}_ADD.bam \
        -O ${OUT_MAPPED}${SAMPLE_ID}_mate.bam \
        -ADD_MATE_CIGAR true \
        2>&1 | tee -a ${OUT_MAPPED}${SAMPLE_ID}_mate.log
    md5sum ${OUT_MAPPED}${SAMPLE_ID}_mate.bam > ${OUT_MAPPED}${SAMPLE_ID}_mate.md5
}

# Function to run MarkDuplicates
run_markduplicates() {
    echo "Running MarkDuplicates for $SAMPLE_ID"
    picard MarkDuplicates \
        -I ${OUT_MAPPED}${SAMPLE_ID}_mate.bam \
        -O ${OUT_MAPPED}${SAMPLE_ID}_MD.bam \
        -M ${OUT_MAPPED}${SAMPLE_ID}_MD.txt \
        -CREATE_INDEX true \
        2>&1 | tee -a ${OUT_MAPPED}${SAMPLE_ID}_MD.log
    md5sum ${OUT_MAPPED}${SAMPLE_ID}_MD.bam > ${OUT_MAPPED}${SAMPLE_ID}_MD.md5
}

# Check for existing files and run the pipeline accordingly
if [ -f ${OUT_MAPPED}${SAMPLE_ID}_MD.bam ] && md5sum --status -c ${OUT_MAPPED}${SAMPLE_ID}_MD.md5; then
    echo "Final BAM file exists: Skipping re-run"
else
    if [ ! -f ${OUT_MAPPED}${SAMPLE_ID}_mate.bam ] || ! md5sum --status -c ${OUT_MAPPED}${SAMPLE_ID}_mate.md5; then
        if [ ! -f ${OUT_MAPPED}${SAMPLE_ID}_ADD.bam ] || ! md5sum --status -c ${OUT_MAPPED}${SAMPLE_ID}_ADD.md5; then
            if [ ! -f ${OUT_MAPPED}${SAMPLE_ID}.sam ] || ! md5sum --status -c ${OUT_MAPPED}${SAMPLE_ID}.sam.md5; then
                run_bowtie2
            fi
            run_add_read_groups
        fi
        run_fixmate
    fi
    run_markduplicates
fi

# Remove intermediate files to save space
rm -f ${OUT_MAPPED}${SAMPLE_ID}.sam
rm -f ${OUT_MAPPED}${SAMPLE_ID}_ADD.bam
rm -f ${OUT_MAPPED}${SAMPLE_ID}_mate.bam

echo "Pipeline completed for $SAMPLE_ID"
