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
bbduk_container = 'shub://TomHarrop/singularity-containers:bbmap_38.50b'
busco_container = 'shub://TomHarrop/singularity-containers:busco_3.0.2'
kraken_container = 'shub://TomHarrop/singularity-containers:kraken_2.0.7beta'


#########
# RULES #
#########

rule target:
    input:
        # expand('output/010_busco/run_{assembly}/full_table_{assembly}.tsv',
        #        assembly=list(genome_files.keys())),
        expand('output/020_stats/{assembly}.tsv',
               assembly=list(genome_files.keys())),
        expand('output/030_kraken/{assembly}/kraken_out.txt',
               assembly=list(genome_files.keys())),

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

rule assembly_stats:
    input:
        'data/{assembly}.fasta',
    output:
        'output/020_stats/{assembly}.tsv'
    log:
        'output/logs/stats_{assembly}.log'
    threads:
        1
    singularity:
        bbduk_container
    shell:
        'stats.sh '
        'in={input} '
        'minscaf=1000 '
        'format=3 '
        'threads={threads} '
        '> {output} '
        '2> {log}'


rule kraken:
    input:
        fasta = 'data/{assembly}.fasta',
        db = 'data/20180917-krakendb'
    output:
        out = 'output/030_kraken/{assembly}/kraken_out.txt',
        report = 'output/030_kraken/{assembly}/kraken_report.txt'
    log:
        'output/logs/030_kraken/{assembly}_kraken.log'
    threads:
        multiprocessing.cpu_count()
    singularity:
        kraken_container
    shell:
        'kraken2 '
        '--threads {threads} '
        '--db {input.db} '
        # '--report-zero-counts '
        '--output {output.out} '
        '--report {output.report} '
        '--use-names '
        '{input.fasta} '
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

