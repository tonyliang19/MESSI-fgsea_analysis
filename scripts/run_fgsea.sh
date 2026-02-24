#!/bin/bash
# run_fgsea.sh
# SLURM array job — one task per chunk RDS file.
# Each task runs run_fgsea.R on its assigned chunk.
#
# Environment variables expected (set by submit_fgsea.sh via --export):
#   CHUNKS_DIR   : directory containing per-chunk RDS files
#   DB_RDS       : path to pathway database RDS
#   RESULTS_DIR  : directory where per-chunk CSVs are written
#   SRC_DIR      : directory containing run_fgsea.R
#   IMAGE        : path to the apptainer .sif image

#SBATCH --job-name=fgsea_array
#SBATCH --account=st-singha53-1
#SBATCH --output=logs/fgsea_%A_%a.out
#SBATCH --error=logs/fgsea_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=2
# Array range is set dynamically by submit_fgsea.sh via --array

module load apptainer

cd "$SLURM_SUBMIT_DIR"
mkdir -p logs "$RESULTS_DIR"

# Pick the chunk for this array task (1-indexed SLURM_ARRAY_TASK_ID)
CHUNK_FILE=$(ls "${CHUNKS_DIR}"/*.rds | sed -n "${SLURM_ARRAY_TASK_ID}p")

echo "Job ID       : ${SLURM_JOB_ID}"
echo "Array task   : ${SLURM_ARRAY_TASK_ID}"
echo "Chunk file   : ${CHUNK_FILE}"
echo "DB RDS       : ${DB_RDS}"
echo "Results dir  : ${RESULTS_DIR}"
echo "Start        : $(date)"

apptainer exec --home "${SLURM_SUBMIT_DIR}" "${IMAGE}" \
    Rscript "${SRC_DIR}/run_fgsea.R" \
        "${CHUNK_FILE}" \
        "${DB_RDS}" \
        "${RESULTS_DIR}"

echo "End: $(date)"
