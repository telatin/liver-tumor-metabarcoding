#!/usr/bin/env python3

import argparse
import subprocess
import shutil
import sys
import re
from pathlib import Path

def parse_arguments():
    """
    Initialize argument parser for sequence file validation parameters.
    
    Returns:
        argparse.Namespace: Parsed command-line arguments
    """
    parser = argparse.ArgumentParser(
        description="Validate sequence files based on minimum read count requirements"
    )
    parser.add_argument(
        "-i", "--input",
        required=True,
        type=str,
        help="Input sequence file path"
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        type=str,
        help="Output sequence file path"
    )
    parser.add_argument(
        "-m", "--minreads",
        required=True,
        type=int,
        help="Minimum number of reads required"
    )
    return parser.parse_args()

def extract_sequence_count(stats_output):
    """
    Parse SeqFU stats output to extract sequence count.
    
    Args:
        stats_output (str): Output from seqfu stats command
    
    Returns:
        int: Number of sequences, or None if parsing fails
    """
    try:
        # Skip header and get first data line
        data_line = stats_output.strip().split('\n')[1]
        # Extract sequence count (second field)
        seq_count = int(data_line.split('\t')[1])
        return seq_count
    except (IndexError, ValueError) as e:
        sys.stderr.write(f"Error parsing SeqFU stats output: {e}\n")
        return None

def validate_sequence_file(input_path, output_path, min_reads):
    """
    Validate sequence file using SeqFU and process based on read count.
    
    Args:
        input_path (str): Path to input sequence file
        output_path (str): Path to output sequence file
        min_reads (int): Minimum required number of reads
    
    Returns:
        bool: True if validation succeeds, False otherwise
    """
    try:
        # Execute SeqFU command pipeline
        cmd = f"seqfu head -n {min_reads} {input_path} | seqfu stats -"
        process = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True
        )
        
        if process.returncode != 0:
            sys.stderr.write(f"SeqFU command failed: {process.stderr}\n")
            return False
        
        # Extract sequence count from stats output
        seq_count = extract_sequence_count(process.stdout)
        if seq_count is None:
            return False
            
        # Process based on sequence count
        if seq_count == min_reads:
            # Copy input file to output location
            shutil.copy2(input_path, output_path)
            sys.stdout.write(f"File copied: contains at least {min_reads} reads\n")
            return True
        else:
            sys.stdout.write(f"No action taken: file contains {seq_count} reads (requirement: {min_reads})\n")
            return False
            
    except Exception as e:
        sys.stderr.write(f"Validation failed: {str(e)}\n")
        return False

def main():
    """
    Main execution function for sequence file validation.
    """
    args = parse_arguments()
    
    # Validate input file existence
    if not Path(args.input).is_file():
        sys.stderr.write(f"Error: Input file '{args.input}' does not exist\n")
        sys.exit(1)
    
    # Validate minimum reads parameter
    if args.minreads <= 0:
        sys.stderr.write("Error: Minimum reads must be greater than 0\n")
        sys.exit(1)
    
    # Execute validation
    success = validate_sequence_file(args.input, args.output, args.minreads)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
