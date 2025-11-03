#!/bin/bash
#SBATCH --job-name=GatherVcfs
#SBATCH --output=/data/home/wanchana/Coconut/FF68/log/GatherVcfs_%A.log
ml load gatk
gatk GatherVcfs \
--INPUT ./VCF/Vigina_radiata_405ea_Chr1.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr2.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr3.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr4.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr5.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr6.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr7.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr8.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr9.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr10.vcf.gz \
--INPUT ./VCF/Vigina_radiata_405ea_Chr11.vcf.gz \
--OUTPUT ./VCF/Vigina_radiata_405ea.raw.vcf.gz 2>&1 | tee -a ./VCF/Vigina_radiata_405ea.log