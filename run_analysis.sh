#!/usr/bin/bash

# Make sure that the shell script stops running if it hits an error
set -e

# Description:
# Shell script to execute the nextflow pipeline for multiple replicates with a single input control.

# Usage: 
# $ ./run_analysis.sh ./path/to/genome.fa single/paired sample_SRR_code [control_SRR_code]
# sample SRR codes should a comma-separated list with no spaces
# control SRR code is optional

genome=$1
sequencing_type=$2

# split the sample list into an array
allSamples=$3
IFS=',' read -ra sampleList <<< "$allSamples"

control=$4

# Ensure python script is executable
chmod +x bin/getFastaLength.py

# Create function for downloading fastq files
function get_data { fasterq-dump $1 -O $1; }

# Run analysis
if [[ -z "$control" ]];
then
	if [ "$sequencing_type" = "single" ];
	then
		for sample in "${sampleList[@]}"; do if [ ! -f "$sample" ]; then get_data "$sample"; fi; done;
		nextflow run callPeaks.nf --genome-fasta  "${genome}" --chip-seq-fastq "$allSamples" --use-rmdup;
	elif [ "$sequencing_type" = "paired" ];
	then
		for sample in "${sampleList[@]}"; do if [ ! -f "$sample" ]; then get_data "$sample"; fi; done;
		nextflow run callPeaks.nf --genome-fasta  "${genome}" --chip-seq-fastq "$allSamples" --paired --use-rmdup;
	fi
elif if [[ -n "$control" ]];
then
	if [ "$sequencing_type" = "single" ];
	then
		for sample in "${sampleList[@]}" "$control"; do if [ ! -f "$sample" ]; then get_data "$sample"; fi; done;
		nextflow run callPeaks.nf --genome-fasta  "${genome}" --chip-seq-fastq "$allSamples" --control-fastq "$control" --use-rmdup;
	elif [ "$sequencing_type" = "paired" ];
	then
		for sample in "${sampleList[@]}" "$control"; do if [ ! -f "$sample" ]; then get_data "$sample"; fi; done;
		nextflow run callPeaks.nf --genome-fasta  "${genome}" --chip-seq-fastq "$allSamples" --control-fastq "$control" --paired --use-rmdup;
	fi
fi

# Remove fastq files (optional)
rm -rf SRR*;

# Remove temporary files.
cd work; rm -rf *; cd ..;

# Remove unneccessary files (optional)
cd output;
rm -rf SRR*;

# Rename output peak files.
mv mergedBroadPeaks.bed "${sampleList[0]}"mergedBroadPeaks.bed;
mv mergedNarrowPeaks.bed "${sampleList[0]}"mergedNarrowPeaks.bed;
cd ..;
