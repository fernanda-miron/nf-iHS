## This script prepares iHS data to do PBS comparison

## Charging library
library("vroom")
library("dplyr")
library("stringr")

## Read args from command line
args <- commandArgs(trailingOnly = T)

# Uncomment for debbuging
# Comment for production mode only
#args[1] <- "./ihs_file"
#args[2] <- "treated_ihs.tsv"

## Place args into named object
ihs_file <- args[1]
tsv_file <- args[2]

## Read file
vcf_file <- vroom(file = ihs_file, col_names = T)

## getting position from ID
changed_vcf <- str_split_fixed(vcf_file$ID, ":", 4)

## changing from matrix to dataframe format 
changed_vcf2 <- as.data.frame(changed_vcf) 

## Getting the column of interest
colum_of_interest <- changed_vcf2 %>% 
  select(V2) %>% 
  rename(POS = V2)

## Merging column of interest to original data 
final_ihs_vcf <- vcf_file %>% 
  mutate(POS = colum_of_interest$POS)

## Saving table
write.table(x = final_ihs_vcf, file = tsv_file, 
            quote = FALSE, col.names = TRUE, row.names = FALSE, sep = "\t")
