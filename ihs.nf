#!/usr/bin/env nextflow

/*================================================================
The Aguilar Lab presents...

The iHS calculation pipeline

- A tool for the automated computing of iHS

==================================================================
Version: 0.1
Project repository:
==================================================================
Authors:

- Bioinformatics Design
 Israel Aguilar-Ordonez (iaguilaror@gmail.com)
 María Fernanda Mirón Toruño (fernandamiront@gmail.com)

- Bioinformatics Development
 María Fernanda Mirón Toruño (fernandamiront@gmail.com)

- Nextflow Port
 Israel Aguilar-Ordonez (iaguilaror@gmail.com)
 María Fernanda Mirón Toruño (fernandamiront@gmail.com)

=============================
Pipeline Processes In Brief:

Pre-processing:
vcf_phasing
genetic_map_generation

Core-processing:
ihs_computing

Pos-processing:

Analysis:

================================================================*/

/* Define the help message as a function to call when needed *//////////////////////////////
def helpMessage() {
	log.info"""
  ==========================================
  The iHS calculation pipeline
  v${version}
  ==========================================

	Usage:

	nextflow run ${pipeline_name}.nf --files_path <path with files> [--output_dir path to results ]

	  --files_path	<- The path to the files required to calculate iHS

	  --output_dir  <- directory where results, intermediate and log files will bestored;
	      default: same dir where vcf files are

	  -resume	   <- Use cached results if the executed project has been run before;
	      default: not activated
	      This native NF option checks if anything has changed from a previous pipeline execution.
	      Then, it resumes the run from the last successful stage.
	      i.e. If for some reason your previous run got interrupted,
	      running the -resume option will take it from the last successful pipeline stage
	      instead of starting over
	      Read more here: https://www.nextflow.io/docs/latest/getstarted.html#getstart-resume
	  --help           <- Shows Pipeline Information
	  --version        <- Show version
	""".stripIndent()
}

/*//////////////////////////////
  Define pipeline version
  If you bump the number, remember to bump it in the header description at the begining of this script too
*/
version = "0.1"

/*//////////////////////////////
  Define pipeline Name
  This will be used as a name to include in the results and intermediates directory names
*/
pipeline_name = "nf_ihs_computing"

/*
  Initiate default values for parameters
  to avoid "WARN: Access to undefined parameter" messages
*/
params.files_path = false // default is false to not trigger help message
params.help = false //default is false to not trigger help message automatically at every run
params.version = false //default is false to not trigger version message automatically at every run

/*//////////////////////////////
  If the user inputs the --help flag
  print the help message and exit pipeline
*/
if (params.help){
	helpMessage()
	exit 0
}

/*//////////////////////////////
  If the user inputs the --version flag
  print the pipeline version
*/
if (params.version){
	println "${pipeline_name} v${version}"
	exit 0
}

/*//////////////////////////////
  Define the Nextflow version under which this pipeline was developed or successfuly tested
  Updated by iaguilar at MAY 2021
*/
nextflow_required_version = '20.01.0'
/*
  Try Catch to verify compatible Nextflow version
  If user Nextflow version is lower than the required version pipeline will continue
  but a message is printed to tell the user maybe it's a good idea to update her/his Nextflow
*/
try {
	if( ! nextflow.version.matches(">= $nextflow_required_version") ){
		throw GroovyException('Your Nextflow version is older than Pipeline required version')
	}
} catch (all) {
	log.error "-----\n" +
			"  This pipeline requires Nextflow version: $nextflow_required_version \n" +
      "  But you are running version: $workflow.nextflow.version \n" +
			"  The pipeline will continue but some things may not work as intended\n" +
			"  You may want to run `nextflow self-update` to update Nextflow\n" +
			"============================================================"
}

/*//////////////////////////////
  INPUT PARAMETER VALIDATION BLOCK
*/

/* Check if the input directory is provided
    if it was not provided, it keeps the 'false' value assigned in the parameter initiation block above
    and this test fails
*/
if ( !params.files_path ) {
  log.error " Please provide the --files_path \n\n" +
  " For more information, execute: nextflow run nf_ihs_computing --help"
  exit 1
}

/*
Output directory definition
Default value to create directory is the parent dir of --input_dir
*/
params.output_dir = file(params.files_path).getParent() //!! maybe creates bug, should check

/*
  Results and Intermediate directory definition
  They are always relative to the base Output Directory
  and they always include the pipeline name in the variable pipeline_name defined by this Script

  This directories will be automatically created by the pipeline to store files during the run
*/
results_dir = "${params.output_dir}/${pipeline_name}-results/"
intermediates_dir = "${params.output_dir}/${pipeline_name}-intermediate/"

/*
Useful functions definition
*/

/*//////////////////////////////
  LOG RUN INFORMATION
*/
log.info"""
==========================================
The iHS computing pipeline
v${version}
==========================================
"""
log.info "--Nextflow metadata--"
/* define function to store nextflow metadata summary info */
def nfsummary = [:]
/* log parameter values beign used into summary */
/* For the following runtime metadata origins, see https://www.nextflow.io/docs/latest/metadata.html */
nfsummary['Resumed run?'] = workflow.resume
nfsummary['Run Name']			= workflow.runName
nfsummary['Current user']		= workflow.userName
/* string transform the time and date of run start; remove : chars and replace spaces by underscores */
nfsummary['Start time']			= workflow.start.toString().replace(":", "").replace(" ", "_")
nfsummary['Script dir']		 = workflow.projectDir
nfsummary['Working dir']		 = workflow.workDir
nfsummary['Current dir']		= workflow.launchDir
nfsummary['Launch command'] = workflow.commandLine
log.info nfsummary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "\n\n--Pipeline Parameters--"
/* define function to store nextflow metadata summary info */
def pipelinesummary = [:]
/* log parameter values beign used into summary */
pipelinesummary['iHS: not phased']			= params.notphased
pipelinesummary['Input data']			= params.files_path
pipelinesummary['Results Dir']		= results_dir
pipelinesummary['Intermediate Dir']		= intermediates_dir
/* print stored summary info */
log.info pipelinesummary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "==========================================\nPipeline Start"

/*//////////////////////////////
  PIPELINE START
*/
/* Activar modo DSL2*/
nextflow.enable.dsl=2

/*
	READ INPUTS
*/

/* Load files  into channel*/
vcf = Channel.fromPath("${params.files_path}/*.vcf")
genetic_map_shapeit = Channel.fromPath("${params.files_path}/genetic_map*")
reference_haplotypes = Channel.fromPath("${params.files_path}/*.hap")
reference_legend = Channel.fromPath("${params.files_path}/*.legend")
reference_sample = Channel.fromPath("${params.files_path}/*.sample")
exclude_file = Channel.fromPath("${params.files_path}/*.exclude")
python_script = Channel.fromPath("nf_modules/core-scripts/make_map.py")
r_script = Channel.fromPath("nf_modules/core-rscripts/ihs_treatment.R")

/* Import modules
*/
 include {
   vcf_phasing; haps_to_vcf;
	 vcf_to_hap ; generating_map ;ihs_computing; ihs_treatment} from './nf_modules/modules.nf'

 /*
  * main pipeline logic
  */

 workflow  {
	 if (params.notphased){
		 p1 = vcf_phasing(vcf, genetic_map_shapeit, reference_haplotypes, reference_legend, reference_sample, exclude_file)
		 p2 = haps_to_vcf(p1.hap_file, p1.sample_file)
	 } else {
		p2 = vcf
	 }
	 p3 = vcf_to_hap(p2)
	 p4 = generating_map(reference_haplotypes, reference_legend, genetic_map_shapeit, python_script)
	 p5 = ihs_computing(p3, p4)
	 p6 = ihs_treatment(p5, r_script)
 }
