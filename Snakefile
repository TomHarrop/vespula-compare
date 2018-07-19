#!/usr/bin/env python3

###########
# GLOBALS #
###########

ref_genome = 'data/vvul_hic25.fasta'
query_genome = 'data/vger_k71.fasta'

# containers
mummer_container = 'shub://TomHarrop/singularity-containers:mummer_4.0.0beta2'

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
    params:
        wd = 'output/nucmer'
    singularity:
        mummer_container
    shell:
        'cd {params.wd} || exit 1 ; '
        'nucmer '
        '--maxmatch '
        '-p output '
        '{input.ref} '
        '{input.query} '
        '&> nucmer.log'
