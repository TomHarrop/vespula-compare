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
    'vger_scaffolded': 'data/vger_scaffolded.fasta',
    'vvul_scaffolded': 'data/vvul_scaffolded.fasta'}

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
        ('output/010_busco/run_{assembly}/'
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

rule generic_gunzip:
    input:
        '{filepath}.gz'
    output:
        temp('{filepath}')
    wildcard_constraints:
        filepath = '.*(?!gz)$'      # not gz files
    singularity:
        bbduk_container
    shell:
        'gunzip -c {input} > {output}'

