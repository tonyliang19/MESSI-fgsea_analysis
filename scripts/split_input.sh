#!/bin/bash
# split_input.sh
# SLURM job: runs split_input.R on a compute node to split the input RDS
# into per-chunk RDS files. Runs before the fgsea array job.
#
# Environment variables expected (set by submit_fgsea.sh via --export):
#   INPUT_RDS    : path to the input named-list RDS
#   CHUNKS_DIR   : output directory for per-chunk RDS files
#   CHUNK_SIZE   : vectors per chunk (0 = split by name prefix)
#   SRC_DIR      : directory containing split_input.R
#   IMAGE        : path to the apptainer .sif image

#SBATCH --job-name=fgsea_split
#SBATCH --account=st-singha53-1
#SBATCH --output=logs/fgsea_split_%j.out
#SBATCH --error=logs/fgsea_split_%j.err
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --time=00:15:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

module load apptainer

cd "$SLURM_SUBMIT_DIR"
mkdir -p "$CHUNKS_DIR" logs

echo "Job ID     : ${SLURM_JOB_ID}"
echo "INPUT_RDS  : ${INPUT_RDS}"
echo "CHUNKS_DIR : ${CHUNKS_DIR}"
echo "CHUNK_SIZE : ${CHUNK_SIZE}"
echo "Start      : $(date)"

apptainer exec --home "${SLURM_SUBMIT_DIR}" "${IMAGE}" \
    Rscript "${SRC_DIR}/split_input.R" \
        "${INPUT_RDS}" \
        "${CHUNKS_DIR}" \
        "${CHUNK_SIZE}"

echo "End: $(date)"
