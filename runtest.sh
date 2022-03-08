files_path="test/data"
output_directory="test/results"

echo -e "======\n Testing NF execution \n======" \
&& rm -rf $output_directory \
&& nextflow run ihs.nf \
	--files_path $files_path \
	--output_dir $output_directory \
	-resume \
	-with-report $output_directory/`date +%Y%m%d_%H%M%S`_report.html \
	-with-dag $output_directory/`date +%Y%m%d_%H%M%S`.DAG.html \
&& echo -e "======\n Basic pipeline TEST SUCCESSFUL \n======"
