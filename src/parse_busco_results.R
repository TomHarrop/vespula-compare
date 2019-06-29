#!/usr/bin/env Rscript

library(data.table)

busco_files <- list.files("output/010_busco",
           pattern = 'full_table_.*.tsv',
           recursive = TRUE,
           full.names = TRUE)

stats_files <- list.files("output/020_stats",
           pattern = '.tsv',
           recursive = TRUE,
           full.names = TRUE)

names(busco_files) <- gsub("full_table_(.*).tsv", "\\1", basename(busco_files))
busco_list <- lapply(busco_files, fread, skip = 4, fill = TRUE)
busco_results <- rbindlist(busco_list, idcol = "assembly")

busco_results[, n_buscos := length(unique(`# Busco id`)), by = assembly]
busco_results[, c("species", "assembly_type") := tstrsplit(assembly, "_")]
busco_results[assembly_type == "scaffolded" & grepl("^Chr", Contig),
              busco_hit_on_chr := TRUE]
busco_results[assembly_type == "scaffolded" & !grepl("^Chr", Contig),
              busco_hit_on_chr := FALSE]


# busco summary
complete_by_assembly <- busco_results[, .(
    pct_by_status = 100 * length(unique(`# Busco id`)) / unique(n_buscos)
), by = .(Status, species, assembly_type)][Status == "Complete"]
full_assemblies <- dcast(complete_by_assembly,
      assembly_type ~ species,
      value.var = "pct_by_status")
full_assemblies[, variable := "busco_complete"]

# busco (scaffolds only)
complete_in_main_scaffolds <- busco_results[!is.na(busco_hit_on_chr), .(
    pct_by_status = 100 * length(unique(`# Busco id`)) / unique(n_buscos)
), by = .(Status, species, assembly_type, busco_hit_on_chr)][
    Status == "Complete" & busco_hit_on_chr == TRUE]
scaffolds_only <- dcast(complete_in_main_scaffolds,
      assembly_type ~ species,
      value.var = "pct_by_status")
scaffolds_only[, variable := "busco_complete"]
scaffolds_only[, assembly_type := "scaffoldsonly"]

# parse stats
names(stats_files) <- sub(".tsv", "", basename(stats_files))
stats_list <- lapply(stats_files, fread)
stats_results <- rbindlist(stats_list, idcol = "assembly")

stats_results[, c("species", "assembly_type") := tstrsplit(assembly, "_")]

# convert to nicer numbers
stats_long <- melt(stats_results, id.vars = c("species", "assembly_type"),
     measure.vars = c("scaf_bp", "n_scaffolds", "scaf_L50"))
stats_long[, value := as.double(value)]
stats_long[variable == "scaf_bp",
           c("variable", "value") := .("scaf_mbp", value / 1e6)]
stats_long[variable == "scaf_L50",
           c("variable", "value") := .("L50_kbp", value / 1e3)]

# collate the ones we want
sum_stats <- dcast(stats_long, assembly_type + variable ~ species)

# join busco and stats
all_stats <- rbindlist(list(
    sum_stats, full_assemblies, scaffolds_only
), use.names = TRUE)
type_order <- c("shortread", "scaffolded", "scaffoldsonly")
var_order <- c("scaf_mbp", "n_scaffolds", "L50_kbp", "busco_complete")
all_stats[, assembly_type := factor(assembly_type, levels = type_order)]
all_stats[, variable := factor(variable, levels = var_order)]
setkey(all_stats, variable, assembly_type)
