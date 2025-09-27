\# Fastp SLURM Array Script

Run [fastp](https://github.com/OpenGene/fastp) in parallel using SLURM array jobs for paired-end FASTQ files.

## Features
- Run **fastp** in parallel using **SLURM job arrays**
- Input from a metadata CSV file (sample list)
- Generate trimmed FASTQ, HTML, JSON reports
- Automatic **MD5 checksum validation**
- Remove raw FASTQ after successful trimming

## Requirements
- SLURM workload manager
- fastp installed (via module or conda/mamba)

## Metadata File Format
```
sequencing_id,sample_id,read1.fastq.gz,read2.fastq.gz
SEQ001,SAMPLE_A,/path/to/sampleA_R1.fq.gz,/path/to/sampleA_R2.fq.gz
SEQ002,SAMPLE_B,/path/to/sampleB_R1.fq.gz,/path/to/sampleB_R2.fq.gz
```

## Usage
1. Edit the script:
   - Set `INPUT_FILE` to your metadata file
   - Set `OUT_trim` to your output directory
2. Submit job to SLURM:
   ```bash
   sbatch submit_fastp_array.sh
   ```
3. Monitor logs:
   ```
   fastp_<JOBID>_<ARRAYID>.log
   ```

## Example SLURM Settings
```bash
#SBATCH --job-name=fastp_array
#SBATCH --array=1-49
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
```

## Output
For each sample:
- `<sample_id>_forward_paired.fq.gz`
- `<sample_id>_reverse_paired.fq.gz`
- `<sample_id>_fastp.json`
- `<sample_id>_fastp.html`
- `<sample_id>.md5`

## Citation
Chen et al., *Bioinformatics* (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor.