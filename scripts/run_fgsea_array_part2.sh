#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --account=st-singha53-1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --job-name=fgsea_array_part2
#SBATCH --array=1-80%30
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --output=logs/fgsea_part2_%A/job_%a.out
#SBATCH --error=logs/fgsea_part2_%A/job_%a.out
#SBATCH --mail-user=chunqingliang@gmail.com
#SBATCH --mail-type=ALL

module load apptainer

cd ${SLURM_SUBMIT_DIR}

# Extract the dataset path, pathway, and output path from the line of each tsv
# ARRAY TASK ID goes from 1 to 1015
INPUT_FILE="fgsea_part2_inputs.tsv"

line=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $INPUT_FILE)
dataset=$(echo "$line" | awk -F'\t' '{print $1}')
pathway=$(echo "$line" | awk -F'\t' '{print $2}')
output=$(echo "$line" | awk -F'\t' '{print $3}')


IMAGE="/arc/project/st-singha53-1/apptainer_images/fgsea.sif"

# Then run the script
apptainer exec --home ${SLURM_SUBMIT_DIR} ${IMAGE} Rscript run_fgsea.R "${dataset}" "${pathway}" "${output}"
