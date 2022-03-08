

# **nf_PBS_gen**

Nextflow pipeline that calculates PBS by SNP
given a VCF file and three populations. 

------------------------------------------------------------------------

### Workflow overview

![General Workflow](dev_notes/PBS_tool.png)

------------------------------------------------------------------------

## Requirements

#### Compatible OS\*:

-   [Ubuntu 18.04 ](http://releases.ubuntu.com/18.04/)

#### Software:

|                    Requirement                     |          Version           |  Required Commands \*  |
|:--------------------------------------------------:|:--------------------------:|:----------------------:|
|        [Nextflow](https://www.nextflow.io/)        |          21.04.2           |        nextflow        |
|          [R](https://www.r-project.org/)           |           4.0.5            |   \*\* See R scripts   |
| [VCFtools](http://vcftools.sourceforge.net/)       |           0.1.15           | \*\*   See bash code   |

\* These commands must be accessible from your `$PATH` (*i.e.* you
should be able to invoke them from your command line).

\* You need to install the dplyr and ggplot2 libraries in R/RStudio

### Installation

Download nf_PBS_gen from Github repository:

    git clone git@github.com:fernanda-miron/nf-PBS-snp.git

------------------------------------------------------------------------

#### Test

To test nf_PBS_gen execution using test data, run:

    ./runtest.sh

Your console should print the Nextflow log for the run, once every
process has been submitted, the following message will appear:

     ======
     Basic pipeline TEST SUCCESSFUL
     ======

results for test data should be in the following file:

    nf_pre_PBS_DSL2_/test/results

------------------------------------------------------------------------

### Usage

To run with your own data go to the pipeline directory and execute:

    nextflow run ${pipeline_name}.nf --fst_path <path to input 1> [--output_dir path to results ]

Note: the path must have the files: .vcf, pop1, pop2 and pop3 files. 

For information about options and parameters, run:

    nextflow run wrangling.nf --help

------------------------------------------------------------------------

#### Authors

Israel Aguilar Ordonez

Maria Fernanda Miron T

# nf-PBS-snp
