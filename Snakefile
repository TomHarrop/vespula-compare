#!/usr/bin/env python3

###########
# GLOBALS #
###########

ref_genome = 'data/vvul_hic25.fasta'
query_genome = 'data/vger_k71.fasta'


#########
# RULES #
#########

rule target:
    input:
        'output/nucmer/output.delta'

rule whole_genome_alignment:
    input:
        ref = ref_genome,
        query = query_genome,
    output:
        'output/nucmer/output.delta'
    shell:
        'nucmer '
        '-maxmatch '
        '-p output '
        '{input.ref} '
        '{input.query} '

