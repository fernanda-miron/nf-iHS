#!/usr/bin/env nextflow

/*Modulos de prueba para  nextflow */
results_dir = "./test/results"
intermediates_dir = "./test/results/intermediates"

process phasing_with_ref {

publishDir "${results_dir}/phasing_with_ref", mode:"copy"

	input:
	tuple val(chromosome), path(path_vcf), path(path_hap), path(path_legend), path(path_sample), path(path_genetic_map), path(path_strand_exclude)

	output:
	tuple val(chromosome), path("${chromosome}.phased.with.ref.vcf")

	"""
	shapeit --input-vcf ${path_vcf} \
        -M ${path_genetic_map} \
        --input-ref ${path_hap} ${path_legend} ${path_sample} \
				--exclude-snp ${path_strand_exclude} \
        -O ${chromosome}.phased.with.ref

	shapeit -convert \
	--input-haps ${chromosome}.phased.with.ref \
			        --output-vcf ${chromosome}.phased.with.ref.vcf
	"""
}

process vcf_to_hap {

publishDir "${results_dir}/IMPUTE_format_file/", mode:"copy"

	input:
	tuple val(chromosome), path(path_files)

	output:
	tuple val(chromosome), path("chr${chromosome}.*.hap")

	"""
	vcftools --vcf ${path_files} --IMPUTE --out chr${chromosome}
	"""
}

process generating_map {

publishDir "${results_dir}/hapbin_genetic_map/", mode:"copy"

	input:
	tuple val(chromosome), path(path_legend), path(path_sample), path(path_genetic_map)

	output:
	tuple val(chromosome), path("chr${chromosome}.map")

	"""
	make_map.py --chromosome ${chromosome}
	"""
}

process ihs_computing {

publishDir "${results_dir}/ihs_results/", mode:"copy"

	input:
	tuple val(chromosome), path(path_hap), path(path_map)
	val maff

	output:
	tuple val(chromosome), path("chr${chromosome}.ihs_file")

	"""
	ihsbin --hap ${path_hap} --map ${path_map} --minmaf ${maff} --out chr${chromosome}.ihs_file
	"""
}

process add_chromosome {

publishDir "${results_dir}/ihs_results_chr/", mode:"copy"

	input:
	tuple val(chromosome), path(path_files)

	output:
	path("add.chr${chromosome}.ihs_file")

	"""
	awk '{print \$0, "\t${chromosome}"}' ${path_files} >  add.chr${chromosome}.ihs_file
	"""
}

process merging_chromosomes {

publishDir "${results_dir}/all_chr_ihs/", mode:"copy"

	input:
	path(path_files)
	file rscript
	val cutoff

	output:
	path("final_ihs.*")

	"""
	Rscript --vanilla ihs_treatment.R . final_ihs.tsv ${cutoff} final_ihs.png
	"""
}

process fst_calculation {

publishDir "${results_dir}/fst_results_pop1_pop2/", mode:"copy"

	input:
	tuple path(path_vcf), path(path_pop1), path(path_pop2), path(path_popout)

	output:
	path "*.fst"

	"""
	vcftools --vcf ${path_vcf} \
					 --weir-fst-pop ${path_pop1} \
					 --weir-fst-pop ${path_pop2} \
					 --out pop1pop2
	"""
}

process fst_calculation_2 {

publishDir "${results_dir}/fst_results_pop1_popout/", mode:"copy"

	input:
	tuple path(path_vcf), path(path_pop1), path(path_pop2), path(path_popout)

	output:
	path "*.fst"

	"""
	vcftools --vcf ${path_vcf} \
					 --weir-fst-pop ${path_pop1} \
					 --weir-fst-pop ${path_popout} \
					 --out pop1popout
	"""
}

process fst_calculation_3 {

publishDir "${results_dir}/fst_results_pop2_popout/", mode:"copy"

	input:
	tuple path(path_vcf), path(path_pop1), path(path_pop2), path(path_popout)

	output:
	path "*.fst"

	"""
	vcftools --vcf ${path_vcf} \
					 --weir-fst-pop ${path_pop2} \
					 --weir-fst-pop ${path_popout} \
					 --out pop2popout
	"""
}

process af_1 {

	publishDir "${results_dir}/af_pop1/",mode:"copy"

	input:
	tuple path(path_vcf), path(path_pop1), path(path_pop2), path(path_popout)

	output:
	file "*.frq"

	"""
	vcftools --vcf ${path_vcf} --keep ${path_pop1} --freq --out pop1
	"""
}

process af_2 {

	publishDir "${results_dir}/af_pop2/",mode:"copy"

	input:
	tuple path(path_vcf), path(path_pop1), path(path_pop2), path(path_popout)

	output:
	file "*.frq"

	"""
	vcftools --vcf ${path_vcf} --keep ${path_pop2} --freq --out pop2
	"""
}

process af_3 {

	publishDir "${results_dir}/af_pop3/",mode:"copy"

	input:
	tuple path(path_vcf), path(path_pop1), path(path_pop2), path(path_popout)

	output:
	file "*.frq"

	"""
	vcftools --vcf ${path_vcf} --keep ${path_popout} --freq --out pop3
	"""
}

process pbs_by_snp {

	publishDir "${results_dir}/pbs_by_snp/",mode:"copy"

	input:
	file p15
	file r_script_pbs

	output:
	file "pbs*"

	"""
	Rscript --vanilla pbs_calculator.R . "pbs_by_snp.png" "pbs.tsv"
	"""
}
