#!/usr/bin/env nextflow

/*Modulos de prueba para  nextflow */
results_dir = "./test/results"
intermediates_dir = "./test/results/intermediates"

process vcf_phasing {

publishDir "${results_dir}/phased_vcf/", mode:"copy"

	input:
	file vcf
	file genetic_map_shapeit
	file reference_haplotypes
	file reference_legend
	file reference_sample
	file exclude_file

	output:
	path "*.haps", emit: hap_file
	path "*.sample", emit: sample_file

	"""
	shapeit --input-vcf ${vcf} \
        -M ${genetic_map_shapeit} \
        --input-ref ${reference_haplotypes} ${reference_legend} ${reference_sample} \
				--exclude-snp ${exclude_file} \
        -O phased.with.ref
	"""
}

process haps_to_vcf {

publishDir "${results_dir}/IMPUTE_format_file/", mode:"copy"

	input:
	file p1_haps
	file p1_sample

	output:
	path "*.vcf"

	"""
	shapeit -convert \
        --input-haps phased.with.ref \
        --output-vcf phased.with.ref.vcf
	"""
}

process vcf_to_hap {

publishDir "${results_dir}/IMPUTE_format_file/", mode:"copy"

	input:
	file p2

	output:
	path "*.hap"

	"""
	vcftools --vcf ${p2} --IMPUTE
	"""
}

process generating_map {

publishDir "${results_dir}/hapbin_genetic_map/", mode:"copy"

	input:
	file reference_haplotypes
	file reference_legend
	file genetic_map
	file python_script

	output:
	file "*.map"

	"""
	chr=\$(ls ${reference_legend} | egrep -o [0-9]+ | tail -1)
	./make_map.py --chromosome "\$chr"
	"""
}

process ihs_computing {

publishDir "${results_dir}/ihs_results/", mode:"copy"

	input:
	file p3
	file genetic_map

	output:
	file "ihs_file"

	"""
	ihsbin --hap ${p3} --map ${genetic_map} --minmaf 0.01 --out ihs_file
	"""
}

process ihs_treatment {

publishDir "${results_dir}/ihs_treated_results/", mode:"copy"

	input:
	file p5
	file rscript

	output:
	file "*.tsv"

	"""
	Rscript --vanilla ihs_treatment.R ${p5} ihs_treated.tsv
	"""
}
