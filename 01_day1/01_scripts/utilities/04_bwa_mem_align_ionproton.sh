#!/bin/bash
#SBATCH -J "GBS_Align"
#SBATCH -o log_%j
#SBATCH -c 4 
#SBATCH -p medium
#SBATCH --mail-type=ALL
#SBATCH --mail-user=claire.merot@gmail.com
#SBATCH --time=7-00:00
#SBATCH --mem=10G

# Important: Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

#this script is adapted from stacks workflow https://github.com/enormandeau/stacks_workflow by Eric Normandeau
#it is tailored for single-end reads coming from ionproton sequencing

# Global variables
GENOMEFOLDER="02_genome"
GENOME="genome_mallotus_dummy.fasta"
DATAFOLDER="03_raw_reads"
ALIGNEDFOLDER="04_aligned_files"
NCPU=$4

# Test if user specified a number of CPUs
if [[ -z "$NCPU" ]]
then
    NCPU=1
fi

# Load needed modules
module load bwa
module load samtools

# Index genome if not alread done
bwa index -p "$GENOMEFOLDER"/"$GENOME" "$GENOMEFOLDER"/"$GENOME"

for file in $(ls -1 "$DATAFOLDER"/*.fq.gz)
do
    # Name of uncompressed file
    echo "Aligning file $file"

    name=$(basename "$file")
    ID="@RG\tID:ind\tSM:ind\tPL:IonProton"

    # Align reads 1 step
    bwa mem -t "$NCPU" -k 19 -c 500 -O 0,0 -E 2,2 -T 0 \
        -R "$ID" \
        "$GENOMEFOLDER"/"$GENOME" "$DATAFOLDER"/"$name" 2> /dev/null |
        samtools view -Sb -q 1 -F 4 -F 256 -F 2048 \
        - > "$ALIGNEDFOLDER"/"${name%.fq.gz}".bam

    # Samtools sort
    samtools sort --threads "$NCPU" -o "$ALIGNEDFOLDER"/"$name".sorted.bam "$ALIGNEDFOLDER"/"${name%.fq.gz}".bam

    # Cleanup
    rm "$ALIGNEDFOLDER"/"${name%.fq.gz}".bam
done

