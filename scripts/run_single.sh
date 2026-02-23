#!/bin/bash
#SBATCH --time=2:00:00           # Request 10 hours of runtime
#SBATCH --account=st-singha53-1      # Specify your allocation code
#SBATCH --nodes=1                 # Request 1 node
#SBATCH --ntasks=1                # Request 1 task
#SBATCH --cpus-per-task=4         # request 4 cpu per task
#SBATCH --mem=8G                  # Request 2 GB of memory
#SBATCH --job-name=fgsea_results-single_run       # Specify the job name
#SBATCH -e slurm-%j.err           # Specify the error file. The %j will be replaced by the Slurm job id.
#SBATCH -o slurm-%j.out           # Specify the output file
#SBATCH --mail-user=chunqingliang@gmail.com  # Email address for job notifications
#SBATCH --mail-type=ALL           # Receive email notifications for all job events

module load apptainer
cd $SLURM_SUBMIT_DIR


IMAGE="/arc/project/st-singha53-1/apptainer_images/fgsea.sif"

# Then run the script
apptainer exec --home ${SLURM_SUBMIT_DIR} ${IMAGE} Rscript single_data_run.R
