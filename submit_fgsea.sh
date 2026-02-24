#!/bin/bash
# =============================================================================
# submit_fgsea.sh
# Pure wrapper — only submits SLURM jobs, no apptainer/R on the login node.
#
# HOW IT WORKS
# ------------
# 1. split_input.sh : SLURM job on compute node — runs split_input.R to split
#                     the input RDS into per-chunk RDS files in CHUNKS_DIR.
# 2. run_fgsea.sh   : SLURM array job (depends on step 1) — each task runs
#                     run_fgsea.R on its chunk, writing one CSV to RESULTS_DIR.
# 3. merge_fgsea.R  : Run manually after the array completes (command printed).
#
# CONTROLLING PARALLELISM via chunk_size (arg 3)
# -----------------------------------------------
#   chunk_size = 0    : one chunk per name-prefix (e.g. one per method)
#   chunk_size = N    : fixed N stat vectors per chunk
#   chunk_size = 9999 : everything in one chunk -> effectively a single job
#                       (useful for small inputs; --array=1-1 is valid SLURM)
#
# NOTE: The array size is inferred after the split job completes by counting
# files in CHUNKS_DIR. The array job is submitted with a dependency on the
# split job, so SLURM handles the ordering automatically.
#
# USAGE
# -----
#   ./submit_fgsea.sh <input_rds> <db_rds> [chunk_size] [max_concurrent]
#
# EXAMPLES
#   Split by method prefix, unlimited concurrency (recommended default):
#     ./submit_fgsea.sh data/input.rds data/pathways.rds 0
#
#   Fixed chunk of 100 vectors per task:
#     ./submit_fgsea.sh data/input.rds data/pathways.rds 100
#
#   Small input — run as a single job:
#     ./submit_fgsea.sh data/input.rds data/pathways.rds 9999
#
#   Limit to 4 tasks running at once:
#     ./submit_fgsea.sh data/input.rds data/pathways.rds 0 4
# =============================================================================

set -euo pipefail

# ── User-configurable paths ────────────────────────────────────────────────────
IMAGE="/arc/project/st-singha53-1/apptainer_images/fgsea.sif"
SRC_DIR="src"                   # R scripts: split_input.R, run_fgsea.R, merge_fgsea.R
SCRIPTS_DIR="scripts"           # SLURM scripts: split_input.sh, run_fgsea.sh
CHUNKS_DIR="chunks"             # per-chunk RDS files (written by split job)
RESULTS_DIR="results/chunks"    # per-chunk CSV outputs (written by array job)
FINAL_CSV="results/fgsea_merged.csv"
# ──────────────────────────────────────────────────────────────────────────────

if [ "$#" -lt 2 ]; then
    echo "Usage: ./submit_fgsea.sh <input_rds> <db_rds> [chunk_size] [max_concurrent]"
    echo "       chunk_size     : 0=by-prefix, N=fixed size, 9999=single job (default: 0)"
    echo "       max_concurrent : max array tasks running at once, e.g. 4 (default: unlimited)"
    exit 1
fi

INPUT_RDS="$1"
DB_RDS="$2"
CHUNK_SIZE="${3:-0}"
MAX_CONCURRENT="${4:-}"

# Validate inputs
for f in "$INPUT_RDS" "$DB_RDS"; do
    if [ ! -f "$f" ]; then
        echo "Error: file not found: $f"
        exit 1
    fi
done

mkdir -p "$CHUNKS_DIR" "$RESULTS_DIR" logs

# ── Step 1: Submit split job ───────────────────────────────────────────────────
echo "==> Submitting split job ..."
SPLIT_JOB_ID=$(sbatch \
    --export=ALL,INPUT_RDS="${INPUT_RDS}",CHUNKS_DIR="${CHUNKS_DIR}",CHUNK_SIZE="${CHUNK_SIZE}",SRC_DIR="${SRC_DIR}",IMAGE="${IMAGE}" \
    "${SCRIPTS_DIR}/split_input.sh" \
    | awk '{print $NF}')

echo "    Split job ID: ${SPLIT_JOB_ID}"

# ── Step 2: Submit array job (depends on split job) ────────────────────────────
# Array size is determined at runtime by counting chunks written by the split job.
# The --wrap trick counts files and builds the array spec inside the compute node
# environment, after the split job has finished.
#
# We use a small coordinator job (afterok:SPLIT) that counts chunks and submits
# the real array job — keeping the login node free of any heavy work.
echo "==> Submitting array coordinator (depends on split job ${SPLIT_JOB_ID}) ..."
COORD_JOB_ID=$(sbatch \
    --job-name=fgsea_coord \
    --account=st-singha53-1 \
    --output=logs/fgsea_coord_%j.out \
    --error=logs/fgsea_coord_%j.err \
    --ntasks=1 --nodes=1 --time=00:05:00 --mem=256M \
    --dependency="afterok:${SPLIT_JOB_ID}" \
    --wrap="
        N_CHUNKS=\$(ls ${CHUNKS_DIR}/*.rds | wc -l)
        ARRAY_SPEC=\"1-\${N_CHUNKS}${MAX_CONCURRENT:+%${MAX_CONCURRENT}}\"
        echo \"Submitting fgsea array: \${ARRAY_SPEC}\"
        sbatch \\
            --array=\"\${ARRAY_SPEC}\" \\
            --export=ALL,CHUNKS_DIR=${CHUNKS_DIR},DB_RDS=${DB_RDS},RESULTS_DIR=${RESULTS_DIR},SRC_DIR=${SRC_DIR},IMAGE=${IMAGE} \\
            ${SCRIPTS_DIR}/run_fgsea.sh
    " \
    | awk '{print $NF}')

echo "    Coordinator job ID: ${COORD_JOB_ID}"
echo ""
echo "Job chain:"
echo "    ${SPLIT_JOB_ID} (split) --> ${COORD_JOB_ID} (coord) --> array (fgsea)"
echo ""
echo "Monitor with:"
echo "    squeue -u \$USER"
echo ""
echo "Once the array completes, merge results:"
echo " sh merge_output.sh results/chunks results/bulk_merged.csv"
