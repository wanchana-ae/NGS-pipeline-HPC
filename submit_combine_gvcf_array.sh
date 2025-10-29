#!/bin/bash
#SBATCH --job-name=combine_gvcfs
#SBATCH --array=1-11
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/log/combine_gvcfs_%A_%a.log

ml load gatk  # Adjust module version as needed

# Paths
GVCF_LIST="/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/GVCF/name_405ea_update_27102025.list"
REFERENCE="/data/share/fs6/Vigna_radiata/Reference/Vrad_JL7/Vrad_JL7.chr.sort.genome.fa"
OUT_dir="/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/GVCF/Combine_gvcf/"
Chr_file="/data/share/fs6/Vigna_radiata/Germplasm_Ref_Vrad_JL7/chr.list"

# Get line corresponding to SLURM_ARRAY_TASK_ID
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $Chr_file)
Number_chr=$(echo ${LINE} | cut -d"," -f1)

# Run HaplotypeCaller
echo "CombineGVCFsr for ${Number_chr}"

gatk --java-options "-Xmx64G -XX:ParallelGCThreads=16" CombineGVCFs \
    -R ${REFERENCE} \
    --variant ${GVCF_LIST} \
    -L ${Number_chr} \
    -O ${OUT_dir}Vigina_radiata_405ea_Chr${Number_chr}.g.vcf.gz 2>&1 | tee -a Vigina_radiata_405ea_Chr${Number_chr}.log

echo "CombineGVCFs completed for ${Number_chr}"

