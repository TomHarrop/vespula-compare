#!/usr/bin/env python3

import pathlib


############
# FUNCTION #
############

def resolve_path(x):
    return str(pathlib.Path(x).resolve())

###########
# GLOBALS #
###########

ref_genome = resolve_path('data/vvul_hic25.fasta')
query_genome = resolve_path('data/vger_k71.fasta')

# containers
mummer_container = 'shub://TomHarrop/singularity-containers:mummer_4.0.0beta2'
bbduk_container = 'shub://TomHarrop/singularity-containers:bbmap_38.00'
minimap_container = 'shub://TomHarrop/singularity-containers:minimap2_2.11r797'

#########
# RULES #
#########

rule target:
    input:
        'output/minimap/aln.sam'

rule wga_minimap:
    input:
        ref = 'output/filtered_genomes/vvul_hic25.fasta',
        query = 'output/filtered_genomes/vger_k71.fasta'
    output:
        sam = 'output/minimap/aln.sam'
    threads:
        20
    singularity:
        minimap_container
    log:
        'output/minimap/minimap.log'
    shell:
        'minimap2 '
        '-a '
        '-x asm20 '
        '-t {threads} '
        '{input.ref} '
        '{input.query} '
        '> {output.sam} '
        '2> {log} '



rule whole_genome_alignment:
    input:
        ref = resolve_path('output/filtered_genomes/vvul_hic25.fasta'),
        query = resolve_path('output/filtered_genomes/vger_k71.fasta')
    output:
        'output/nucmer/output.delta'
    threads:
        20
    params:
        wd = 'output/nucmer'
    singularity:
        mummer_container
    shell:
        'cd {params.wd} || exit 1 ; '
        'nucmer '
        '-t {threads} '
        '--maxmatch '
        '-p output '
        '{input.ref} '
        '{input.query} '
        '&> nucmer.log'

rule filter_short_contigs:
    input:
        'data/{genome}.fasta'
    output:
        'output/filtered_genomes/{genome}.fasta'
    threads:
        1
    log:
        'output/logs/filter_short_contigs/{genome}.log'
    singularity:
        bbduk_container
    shell:
        'reformat.sh '
        'in={input} '
        'out={output} '
        'minlength=10000 '
        '2> {log}'



