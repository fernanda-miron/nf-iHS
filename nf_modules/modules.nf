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
	path "*.png", emit: ihs_plots
	path "*.tsv", emit: ihs_tsv

	"""
	Rscript --vanilla ihs_treatment.R . final_ihs.tsv ${cutoff} final_ihs.manhattan.png final_ihs.histogram.png
	"""
}

process ihs_ggf_format {

	publishDir "${results_dir}/ihs_as_ggf/",mode:"copy"

	input:
	file p8
	file biomart
	file r_script_format_ihs

	output:
	path "biomart.gff", emit: biomart_gff
	path "ihs.gff", emit: ihs_gff

	"""
	Rscript --vanilla ihs_format.R ${p8} ${biomart}
	"""
}

process ihs_annotation {

	publishDir "${results_dir}/ihs_annotation/",mode:"copy"

	input:
	file p8_ihs
	file p8_gff

	output:
	path "intersect_gff.tsv"

	"""
	bedtools intersect -a ${p8_ihs} -b ${p8_gff} -wa -wb  > temp_intersect_gff.tsv
	cut -f1,4,9,18 temp_intersect_gff.tsv > temp.f1
	echo -e "CHR\tPOS\tiHS_value\tGene" | cat - temp.f1 > intersect_gff.tsv
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
	path "*.png", emit: png_pbs
	path "*.tsv*", emit: png_tsv

	"""
	Rscript --vanilla pbs_calculator.R . "pbs_by_snp.png" "pbs.tsv"
	"""
}

process ggf_format {

	publishDir "${results_dir}/pbs_as_ggf/",mode:"copy"

	input:
	file p16
	file biomart
	file r_script_format_pbs

	output:
	path "biomart.gff", emit: biomart_gff
	path "pbs.gff", emit: pbs_gff

	"""
	Rscript --vanilla pbs_format.R ${p16} ${biomart}
	"""
}

process pbs_annotation {

	publishDir "${results_dir}/pbs_annotation/",mode:"copy"

	input:
	file p17_pbs
	file p17_gff

	output:
	path "intersect_gff.tsv"

	"""
	bedtools intersect -a ${p17_pbs} -b ${p17_gff} -wa -wb  > temp_intersect_gff.tsv
	cut -f1,4,9,18 temp_intersect_gff.tsv > temp.f1
	echo -e "CHR\tPOS\tPBS_value\tGene" | cat - temp.f1 > intersect_gff.tsv
	"""
}

process merged_results {

	publishDir "${results_dir}/pbs_vs_ihs/",mode:"copy"

	input:
	file p16
	file p8
	val p_cut
	val i_cut
	file r_script_merged

	output:
	path "*.html", emit: html_file
	path "*.tsv", emit: tsv_file

	"""
	Rscript --vanilla circus.R ${p16} ${p8} ${p_cut} ${i_cut}
	"""
}
