#!/bin/bash
#SBATCH --job-name=Genotype_GVCFs
#SBATCH --array=1-11
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/log/GenotypeGVCFs_%A_%a.log

ml load gatk  # Adjust module version as needed

# Paths
GVCF_LIST="/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/name_gvcf.txt"
REFERENCE="/data/share/fs6/Vigna_radiata/Reference/Vrad_JL7/Vrad_JL7.chr.sort.genome.fa"
OUT_dir="/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/VCF/"

# Get line corresponding to SLURM_ARRAY_TASK_ID
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${GVCF_LIST})

input_gvcf=$(echo ${LINE})
filename=${input_gvcf##*/}
output_vcf=$(echo ${filename} | cut -d"." -f1)

echo "Input :  ${input_gvcf}"
echo "Output: ${OUT_dir}${output_vcf}.vcf.gz"

# Run GenotypeGVCFs
gatk --java-options "-Xmx32G -XX:ParallelGCThreads=8" GenotypeGVCFs \
    -R ${REFERENCE} \
    -V ${input_gvcf} \
    -O ${OUT_dir}${output_vcf}.vcf.gz 2>&1 | tee -a ${OUT_dir}${output_vcf}.log

echo "GenotypeGVCFs completed for ${output_vcf}"