#!/bin/bash
#this one just downloads the gbff and proteome, it was for the annotation project 

download() {
    local species="$1"
    local accession="$2"

    # Remove newlines and trim spaces from accession and species
    accession=$(echo "$accession" | tr -d '\n' | xargs)
    species=$(echo "$species" | tr -d '\n' | xargs | sed 's/[^a-zA-Z0-9]/_/g') # Replace non-alphanumeric characters with underscores
    echo "$species" > species_names.txt
    echo "Downloading for species: $species and accession: $accession"
    
    # Download genome data
    if ! datasets download genome accession "$accession" --include "gbff,protein" --filename "${species}.zip"; then
        echo "$species: Failed to download dataset for accession $accession" >> download_errors.txt
        return 1
    fi

    # Unzip the downloaded file
    if ! unzip "${species}.zip" -d "${species}_dataset"; then
        echo "$species: Failed to unzip dataset" >> download_errors.txt
        mv "${species}.zip" "zipFiles/${species}.zip"
        return 1
    fi
}

rename() {
    local species="$1"
    local accession="$2"

    # Remove newline and trim whitespace
    species=$(echo "$species" | tr -d '\n' | xargs | sed 's/[^a-zA-Z0-9]/_/g') # Replace non-alphanumeric characters with underscores

    # Get paths needed for renaming files
    path="${species}_dataset/ncbi_dataset/data/$accession"
    protFile="$path/protein.faa"
    gbffFile="$path/genomic.gbff"
    

    if ! mv "$gbffFile" "gbff/${species}.gbff"; then
        echo "$species: Failed to move gff file" >> download_errors.txt
        return 1
    fi

    if ! mv "$protFile" "proteomes/${species}.fasta"; then
        echo "$species: Failed to move protein file" >> download_errors.txt
        return 1
    fi

    # Cleanup
    rm -f "README.md"
    rm -rf "${species}_dataset"
    rm -f "${species}.zip"
}

# Prepare directories
mkdir -p "genomes" "proteomes" "gbff" "zipFiles"

annotated=true
input_file="data1.csv"

# Read each row of CSV file
while IFS=',' read -r accession species; do
    echo "____________________________________"
    echo "Processing species: $species with accession: $accession"
    if ! download "$species" "$accession"; then
        echo "Skipping $species due to download error"
        continue
    fi
    if ! rename "$species" "$accession"; then
        echo "Skipping $species due to rename error"
        continue
    fi
    echo "____________________________________"
done < "$input_file"

# Final cleanup
rm -f "README.md"
