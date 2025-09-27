#!/bin/bash
#SBATCH --job-name=fastp_array
#SBATCH --array=1-49           # Distribute 16 jobs (8 jobs per node)
#SBATCH --ntasks=1            # Use 16 tasks
#SBATCH --cpus-per-task=8      # Use 4 cores per sample
#SBATCH --mem=16G               # Allocate 4GB RAM per sample (4GB * 32 = 128GB)
#SBATCH --output=/data/home/wanchana/Water_Buffaloes/Call_SNP/log/fastp_%A_%a.log

ml load fastp

# Read input file (sequencing ID, sample ID, seq_1.fq.gz, seq_2.fq.gz)
INPUT_FILE="metadata_metadata_part3.txt"
OUT_trim="/data/home/wanchana/Water_Buffaloes/Call_SNP/Trimed/"
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INPUT_FILE)

# Extract values from the input file
SEQ_ID=$(echo ${LINE} | cut -d"," -f1)
SAMPLE_ID=$(echo ${LINE} | cut -d"," -f2)
IN1=$(echo ${LINE} | cut -d"," -f3)
IN2=$(echo ${LINE} | cut -d"," -f4)

echo "$SEQ_ID:$SAMPLE_ID"

#<<comment
# Define output filenames
OUT1="${SAMPLE_ID}_forward_paired.fq.gz"
OUT2="${SAMPLE_ID}_reverse_paired.fq.gz"

mkdir -p ${OUT_trim}

Fastp_function () {
echo "Processing sample: $SAMPLE_ID on Node $(hostname)" 
 # Run fastp
fastp -i "$IN1" -I "$IN2" \
-o "${OUT_trim}${OUT1}" \
-O "${OUT_trim}${OUT2}" \
--thread 8 \
--detect_adapter_for_pe \
--cut_tail --cut_window_size 4 --cut_mean_quality 28 \
--length_required 16 \
--json "${OUT_trim}${SAMPLE_ID}_fastp.json" \
--html "${OUT_trim}${SAMPLE_ID}_fastp.html" 2>&1 | tee -a ${OUT_trim}${SAMPLE_ID}_fastp.log

  md5sum ${OUT_trim}${OUT1} > ${OUT_trim}${SAMPLE_ID}.md5
	md5sum ${OUT_trim}${OUT2} >> ${OUT_trim}${SAMPLE_ID}.md5
 rm "$IN1"
 rm "$IN2"
 
}
	#Check
	if [ -f "${OUT_trim}${OUT1}" ] && [ -f "${OUT_trim}${OUT2}" ]; then
 		if md5sum --status -c ${OUT_trim}${SAMPLE_ID}.md5; then
			echo "${OUT_trim}${SAMPLE_ID}.md5 is OK"
		else
			echo "Pass into Trimmomatic by check MD5sum not PASS"
			Fastp_function	
		fi
	else
		Fastp_function
	fi
#comment