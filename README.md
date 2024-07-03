# ncbiDownload
This script takes a `species_list.txt` and downloads all the genomes of the species in the list.

## Notes
+ Make sure NCBI has the genome of the species.
+ If the genome is not annotated, set the `annotated` variable to `false` in the script..
+ make sure the last line of the `species_list.txt` is an empty new line and not a species' name.

## Quick Start

Clone this repository:

```
git clone https://github.com/lazobax/ncbiDownload.git
```

Move to directory and create conda environment, activate the environment:

```
cd ncbiDownload
conda env create -f environment.yaml
conda activate ncbi-datasets
```

Run the script after configuration:

```
bash download.sh
```

Raise issues if found. 