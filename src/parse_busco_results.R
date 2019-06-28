#!/usr/bin/env Rscript

library(data.table)

busco_files <- list.files("output/010_busco",
           pattern = 'full_table_.*.tsv',
           recursive = TRUE,
           full.names = TRUE)

names(busco_files) <- gsub("full_table_(.*).tsv", "\\1", basename(busco_files))
busco_list <- lapply(busco_files, fread, skip = 4, fill = TRUE)
busco_results <- rbindlist(busco_list, idcol = "assembly")

busco_results[, n_buscos := length(unique(`# Busco id`)), by = assembly]
busco_results[, c("species", "assembly_type") := tstrsplit(assembly, "_")]
busco_results[assembly_type == "scaffolded" & grepl("^Chr", Contig),
              busco_hit_on_scaffold := TRUE]
busco_results[assembly_type == "scaffolded" & !grepl("^Chr", Contig),
              busco_hit_on_scaffold := FALSE]

busco_results[busco_hit_on_scaffold == FALSE & Status != "Missing"]

busco_results[, .(
    frac_by_status = length(unique(`# Busco id`)) / n_buscos
), by = .(assembly, Status)]

busco_results[assembly_type == "scaffolded", .(
    frac_by_status = length(unique(`# Busco id`)) / n_buscos
), by = .(assembly, Status, busco_hit_on_scaffold)]


