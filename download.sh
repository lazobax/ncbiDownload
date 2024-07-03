#!/bin/bash

download() {
    local species="$1"

    #download the species reference genome, include the protein and gff3 (if available) --> "ncbi_dataset.zip"
    if ! datasets download genome taxon "$species" --reference --include "genome,gff3,protein"; then
        echo "$species: Failed to download dataset" >> download_errors.txt
        return 1
    fi

    #unzip the download file, 
    if ! unzip "ncbi_dataset.zip"; then
        echo "$species: Failed to unzip dataset" >> download_errors.txt
        #if unzipping fails, move it to the zipFiles folder and we will deal with it later manually 
        mv "ncbi_dataset.zip" "zipFiles/${species}.zip"
        #the unzipping might fail partially, thus in that case, when the new species' data is unzipped, the cmd asks you if you want to replace, select A and continue
        return 1
    fi

    if [ "$annotated" = true ]; then
        # Find the genome file's full path
        full_path=$(ls ncbi_dataset/data/GC*/*.fna 2>/dev/null | head -n 1)
        if [ -z "$full_path" ]; then
            # This error almost never occurs
            echo "$species: Failed to find genome file" >> download_errors.txt
            return 1
        fi

        # Get the base name of the genome file path, GC*_#########.#...etc it's in this format
        file=$(basename "$full_path")
        # Get the GC*_######### (accession number)
        path=$(echo "$file" | cut -d "_" -f -2)
        # Split the numbers into ###/###/###
        path1=$(echo "$file" | cut -d "_" -f 2 | cut -d "." -f 1 | sed 's/\(...\)\(...\)/\1\/\2\//')
        # This is the full genome name, it's the accession number + some extra name
        path2=$(echo "$file" | rev | cut -d "_" -f 2- | rev)

        # The feature_table of a genome is usually available at this exact link
        url="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/${path1}/${path2}/${path2}_feature_table.txt.gz"
        target_dir="ncbi_dataset/data/${path}"

        # Download the feature table into the same path as the genome, proteome, and gff3
        if ! wget "$url" -P "$target_dir"; then
            echo "$species: Failed to download feature table" >> download_errors.txt
            # If it fails, or not found, it will delete the data of this species and move on to the next
            rm -f "README.md"
            rm -rf "ncbi_dataset"
            rm -f ncbi_dataset.zip
            return 1
        fi

        # The feature table is a .gz file, unzip it
        if ! gunzip "${target_dir}/${path2}_feature_table.txt.gz"; then
            echo "$species: Failed to unzip feature table" >> download_errors.txt
            rm -f "README.md"
            rm -rf "ncbi_dataset"
            rm -f ncbi_dataset.zip
            return 1
        fi
    fi

}

rename() {
    local species="$1"

    #similar to the download method, get some paths necessary
    genomePath=$(ls ncbi_dataset/data/GC*/*.fna | head -n 1)
    genomeFile=$(basename "$genomePath")
    subFolder=$(echo "$genomeFile" | cut -d "_" -f 1-2)
    source_dir="ncbi_dataset/data/${subFolder}"

    featureTableTemp=$(echo "$genomeFile" | rev | cut -d "_" -f 2- | rev)
    featureTable="${featureTableTemp}_feature_table.txt"

    #move everything to its correct directory and rename it as such
    if ! mv "${source_dir}/${genomeFile}" "genomes/${species}_genome.fna"; then
        echo "$species: Failed to move genome file" >> download_errors.txt
        return 1
    fi

    if [ "$annotated" = true ]; then
        if ! mv "${source_dir}/genomic.gff" "gff/${species}.gff"; then
            echo "$species: Failed to move gff file" >> download_errors.txt
            return 1
        fi
        if ! mv "${source_dir}/protein.faa" "proteomes/processed_${species}.fasta"; then
            echo "$species: Failed to move protein file" >> download_errors.txt
            return 1
        fi
        if ! mv "${source_dir}/${featureTable}" "featureTable/${species}_feature_table.txt"; then
            echo "$species: Failed to move feature table" >> download_errors.txt
            return 1
        fi
    fi

    #after this species is done, remove the remaining data for it and move on
    rm -f "README.md"
    rm -rf "ncbi_dataset"
    rm -f ncbi_dataset.zip
}


mkdir "genomes" "proteomes" "gff" "featureTables" "zipFiles"


annotated=true
#please note the last line of the file must be an empty new line and not a species name
input_file="species_list.txt"


while IFS= read -r species; do
    echo "____________________________________"
    echo "Processing $species"
    if ! download "$species"; then
        echo "Skipping $species due to download error"
        continue
    fi
    if ! rename "$species"; then
        echo "Skipping $species due to rename error"
        continue
    fi
    echo "____________________________________"
done < "$input_file"

rm -f "README.md"
rm -rf "ncbi_dataset"
rm -f ncbi_dataset.zip