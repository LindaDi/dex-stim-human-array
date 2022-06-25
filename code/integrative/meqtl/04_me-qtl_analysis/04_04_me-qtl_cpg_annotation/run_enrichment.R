library(data.table)
library(dplyr)

library(GenomicRanges)
library(GenomeInfoDb)

library(parallel)
library(foreach)
library(doParallel)

out.dir.pre  <- "~/bio/code/mpip/dex-stim-human-array/output/data/integrative/matrixEQTL/meqtls/region_wise_independent_snps/"

# Relation to island

meqtls.cpg.delta.coord.gr <- readRDS(paste0(out.dir.pre, "meqtl_delta_cpgs_gr.rds"))
meqtls.cpg.veh.coord.gr   <- readRDS(paste0(out.dir.pre, "meqtl_veh_cpgs_gr.rds"))
anno.epic.gr              <- readRDS(paste0(out.dir.pre, "anno_epic_gr.rds"))    

features.lst <- elementMetadata(meqtls.cpg.delta.coord.gr)[, "Relation_to_Island"] %>% unique() %>% sort()

no.cores <- detectCores() - 2
cl <- makeCluster(no.cores)
registerDoParallel(cl)

nperm   <- 20
nsample <- 1000

gen.loc.enrich.perm.rslt <- foreach(i =  seq_along(features.lst), 
                                    .combine = rbind, 
                                    .packages =  c("GenomicRanges", "dplyr")) %dopar% {
                                       state <- features.lst[i]                                     
                                       public <- anno.epic.gr[(elementMetadata(anno.epic.gr)[, "Relation_to_Island"]) == state, ] 
                                       EnrichmentWithPermutationGeneLocWithoutMAF(own = meqtls.cpg.delta.coord.gr,
                                                                           background = meqtls.cpg.veh.coord.gr,
                                                                           public = public,
                                                                           nperm = nperm)
                                     }

stopImplicitCluster()

gen.loc.enrich.perm.rslt <- cbind(gen.loc.enrich.perm.rslt %>% data.frame(row.names = NULL), 
                                  Feature = features.lst)

gen.loc.enrich.perm.rslt[["n_perm"]] <- nperm

gen.loc.enrich.perm.rslt

fwrite(gen.loc.enrich.perm.rslt, 
       file = paste0("~/bio/code/mpip/dex-stim-human-array/output/data/integrative/matrixEQTL/05_me-qtl_enrichment/region_wise_independent_snps/",  "meqtl_cpgs_relation_to_island_enrichment_perm.csv"), 
       row.names = F, quote = F)

# ChIPSeeker 

delta.meqtl.snp.anno.rds <- readRDS(paste0(out.dir.pre, "meqtls_cpg_annotated_withChIPseeker_delta.rds"))
veh.meqtl.snp.anno.rds   <- readRDS(paste0(out.dir.pre, "meqtls_cpg_annotated_withChIPseeker_veh.rds"))

features.lst <- elementMetadata(delta.meqtl.snp.anno.rds@anno)[, "annotation"] %>% unique() %>% sort()

