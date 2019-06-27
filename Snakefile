#!/usr/bin/env python3

import pathlib2
import multiprocessing

############
# FUNCTION #
############

def resolve_path(x):
    return str(pathlib2.Path(x).resolve())

###########
# GLOBALS #
###########

genome_files = {
    'vger_shortread': 'data/vger_shortread.fasta',
    'vvul_shortread': 'data/vvul_shortread.fasta',
    'vger_scaffolded': 'data/vger_scaffolded.fasta.gz',
    'vvul_scaffolded': 'data/vvul_scaffolded.fasta.gz'}

# containers
mummer_container = 'shub://TomHarrop/singularity-containers:mummer_4.0.0beta2'
bbduk_container = 'shub://TomHarrop/singularity-containers:bbmap_38.50b'
minimap_container = 'shub://TomHarrop/singularity-containers:minimap2_2.11r797'
busco_container = 'shub://TomHarrop/singularity-containers:busco_3.0.2'


#########
# RULES #
#########

rule target:
    input:
        expand('output/010_busco/{assembly}/full_table_{assembly}.tsv',
               assembly=list(genome_files.keys()))

rule busco_genome:
    input:
        fasta = 'data/{assembly}.fasta',
        lineage = 'data/hymenoptera_odb9'
    output:
        ('output/010_busco/{assembly}/'
         'full_table_{assembly}.tsv')
    log:
        str(pathlib2.Path(('output/logs/060_busco/'
                           'busco_{assembly}.log')).resolve())
    params:
        wd = 'output/010_busco',
        name = '{assembly}',
        fasta = lambda wildcards, input: resolve_path(input.fasta),
        lineage = lambda wildcards, input: resolve_path(input.lineage)
    threads:
        multiprocessing.cpu_count()
    singularity:
        busco_container
    shell:
        'cd {params.wd} || exit 1 ; '
        'run_BUSCO.py '
        '--force '
        '--in {params.fasta} '
        '--out {params.name} '
        '--lineage {params.lineage} '
        '--cpu {threads} '
        '--species honeybee1 '
        '--mode genome '
        '&> {log}'



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


rule generic_gunzip:
    input:
        '{filepath}/{filename}.{ext}.gz'
    output:
        temp('{filepath}/{filename}.{ext}')
    wildcard_constraints:
        ext = '(?!gz)'      # don't recurse
    singularity:
        bbduk_container
    shell:
        'gunzip -c {input} > {output}'

