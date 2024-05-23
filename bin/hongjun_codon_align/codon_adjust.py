#!/usr/bin/env python

# Author: Hongjun Bai @ VGS (Rolland Lab), MHRP, HJF (hbai@hivresearch.org)

import sys
import argparse
import re
import math
import collections
import itertools as it
from enum import Enum

def codon_adjust(input_seqs):
    ''' not pretty, but functional '''
    cons = get_cons(input_seqs, use_most_common=True).upper()
    n_incomplete = len(cons.replace('-', '')) % 3 
    if n_incomplete > 0:
        n_padding  = 3 - n_incomplete
        cons += 'N'*n_padding
        na_seqs = []
        for s in input_seqs:
            na_seqs.append(s + 'N'*n_padding)
    else:
        na_seqs = input_seqs
    assert(len(cons.replace('-', ''))%3 == 0) # sanity check, length of na sequence must be n x 3
    adjusted_t = [] 
    i = 0
    class Pos(Enum):
        Leading = 1
        Tailing = 2
    while i < len(cons):
        # Get 3 positions from the consensus
        triplet = cons[i:i+3]
        n_gap = triplet.count('-')
        if n_gap % 3 == 0:  # No frameshift / frameshift has been handled
            for j in range(3):
                adjusted_t.append(''.join(s[i+j] for s in na_seqs))
            i += 3
        else:
            if triplet[0] == '-':  # Insertion(s) at leading position
                n_leading_gap = 2 if triplet[0:2] == '--' else 1
                for j in range(n_leading_gap):
                    adjusted_t.append(''.join(s[i+j] for s in na_seqs))
                for j in range(3-n_leading_gap): # Make it 3
                    adjusted_t.append('-'*len(na_seqs))
                i += n_leading_gap
            else:  # '-' not at leading position, 
                # collect sites till it has 3 non-gap chars
                iend = 3 + n_gap
                na_chars = cons[i:iend].replace('-','')
                while len(na_chars) < 3: 
                    iend += 1
                    na_chars = cons[i:iend].replace('-','')
                # identify segs have insertion(s)
                n_lead, n_tail = 0, 0
                insertions = {}
                for j, s in enumerate(na_seqs):
                    na_chars_j = s[i:iend].replace('-','')
                    if len(na_chars_j) > 3:
                        # decide gap at the leading or tailing position
                        hamming_leading = hamming(na_chars, na_chars_j[:3])
                        hamming_tailing = hamming(na_chars, na_chars_j[-3:])
                        if hamming_leading > hamming_tailing: # add gaps leading position
                            n_lead = max(n_lead, math.ceil(len(na_chars_j)/3) - 1)
                            insertions[j] = Pos.Leading
                        else:  # add gaps tailing position
                            n_tail = max(n_tail, math.ceil(len(na_chars_j)/3) - 1)
                            insertions[j] = Pos.Tailing
                    #print(na_chars, na_chars_j, n_lead, n_tail)
                #print(i, iend, n_lead, n_tail)
                #flattened_segs after adjustment
                flattened_segs = []
                for j, s in enumerate(na_seqs):
                    na_chars_j = s[i:iend].replace('-', '')
                    if j in insertions:
                        if insertions[j] == Pos.Leading:
                            flattened_segs.append(na_chars_j[:-3].ljust(3*n_lead, '-') + na_chars_j[-3:] + '-'*3*n_tail)
                        else:
                            flattened_segs.append('-'*3*n_lead + na_chars_j[:3] + na_chars_j[3:].ljust(3*n_tail, '-'))
                    else:
                        # Sequences have no insertion
                        if len(na_chars_j) == 3:    # no deletion
                            flattened_segs.append('-'*3*n_lead + na_chars_j + '-'*3*n_tail)
                        elif len(na_chars_j) == 0:  # 3 deletions
                            flattened_segs.append('-'*3*(n_lead + 1 + n_tail))
                        elif len(na_chars_j) == 1:  # 2 deletions 
                            if na_chars_j == na_chars[-1]:
                                flattened_segs.append('-'*3*n_lead + na_chars_j.rjust(3, '-') + '-'*3*n_tail)
                            else:
                                flattened_segs.append('-'*3*n_lead + na_chars_j.ljust(3, '-') + '-'*3*n_tail)
                        elif len(na_chars_j) == 2:  # 1 deletion
                            hamming_leading = hamming(na_chars[:len(na_chars_j)], na_chars_j)
                            hamming_tailing = hamming(na_chars[-len(na_chars_j):], na_chars_j)
                            hamming_headtail = hamming(na_chars[0]+na_chars[-1], na_chars_j)
                            three_dist = (hamming_leading, hamming_tailing, hamming_headtail)
                            if min(three_dist) ==  hamming_leading:
                                flattened_segs.append('-'*3*n_lead + na_chars_j.ljust(3, '-') + '-'*3*n_tail)
                            elif min(three_dist) == hamming_tailing:
                                flattened_segs.append('-'*3*n_lead + na_chars_j.rjust(3, '-') + '-'*3*n_tail)
                            else:
                                flattened_segs.append('-'*3*n_lead + na_chars_j[0]+'-'+na_chars_j[1] +  '-'*3*n_tail)
                        else:
                            assert(False)
                # adjust them
                for j in range((n_lead+1+n_tail)*3):
                    adjusted_t.append(''.join(seg[j] for seg in flattened_segs))
                # update i
                i = iend
    return transpose(adjusted_t)

def fix_2frameshift(na_seq, na_cons):
    # locate frame shift
    na_list = list(na_seq)
    aa_seq = translate(na_seq)
    p_2frames = re.compile('#-*#')
    for m in p_2frames.finditer(aa_seq):
        s =  m.start() * 3
        e = m.end() * 3
        na_chars = na_seq[s:e].replace('-', '')
        #print(s, e, aa_seq[m.start():m.end()], na_chars)
        #print(''.join(na_list[s:e]))
        if len(na_chars) == 3:
            hamming_s = hamming(na_chars, na_cons[s:e][:3])
            hamming_e = hamming(na_chars, na_cons[s:e][-3:])
            if hamming_s > hamming_e:
                na_list[s:e] = na_chars.rjust(e-s, '-')
            else:
                na_list[s:e] = na_chars.ljust(e-s, '-')
        elif len(na_chars) == 2:
            hamming_s = hamming(na_chars, na_cons[s:e][:2])
            hamming_e = hamming(na_chars, na_cons[s:e][-2:])
            if hamming_s == 0:
                na_list[s:e] = na_chars.rjust(e-s, '-')
            elif hamming_e == 0:
                na_list[s:e] = na_chars.ljust(e-s, '-')
            else:
                # will be manually handeled
                pass
        elif len(na_chars) == 4:
            hamming_s = hamming(na_chars[:3], na_cons[s:e][:3])
            hamming_e = hamming(na_chars[-3:], na_cons[s:e][-3:])
            if hamming_s == 0:
                na_list[s:e] = na_chars[:3].ljust(e-s-3, '-') + na_chars[3:].rjust(3, '-')
            elif hamming_e == 0:
                na_list[s:e] = na_chars[:-3].ljust(e-s-3, '-') + na_chars[-3:]
            else:
                # will be manually handeled
                pass
        else:
            assert(False)  # '#--#' cannot be caused by na_chars of length not 2, 3 and 4
        #print(''.join(na_list[s:e]))
    return ''.join(na_list)

def hamming(seqa, seqb):
    return sum(1 if a!=b else 0 for a, b in zip(seqa, seqb))

def next_n(seq, i, n, gap='-'):
    # collect sites till it has n non-gap chars
    iend = i + n
    chars = seq[i:iend].replace(gap, '')
    while len(chars) < n and iend < len(seq): 
        iend += 1
        chars = seq[i:iend].replace(gap, '')
        #print(chars, iend, len(seq))
    return (chars, iend-i)

def cleaned(instream, comment='#'):
    """ Remove comments(starts with #) or empty lines """
    for line in instream:
        cleaned_line = line.strip().split(comment)[0]
        if cleaned_line:
            yield cleaned_line.strip()

def translate(na_seq):
    assert(len(na_seq) % 3 == 0)
    return ''.join(na2aa(triplet) for triplet in chunkstring(na_seq, 3))

def init_NA2AA():
    NA2AA = {}
    _aa_na_correspondence = '''
        # Amino_acid	Codons	Compressed_Codons
        Ala/A	GCT,GCC,GCA,GCG	GCN
        Arg/R	CGT,CGC,CGA,CGG,AGA,AGG	CGN,MGR
        Asn/N	AAT,AAC	AAY
        Asp/D	GAT,GAC	GAY
        Cys/C	TGT,TGC	TGY
        Gln/Q	CAA,CAG	CAR
        Glu/E	GAA,GAG	GAR
        Gly/G	GGT,GGC,GGA,GGG	GGN
        His/H	CAT,CAC	CAY
        Ile/I	ATT,ATC,ATA	ATH
        Leu/L	TTA,TTG,CTT,CTC,CTA,CTG	YTR,CTN
        Lys/K	AAA,AAG	AAR
        Met/M	ATG
        Phe/F	TTT,TTC	TTY
        Pro/P	CCT,CCC,CCA,CCG	CCN
        Ser/S	TCT,TCC,TCA,TCG,AGT,AGC	TCN,AGY
        Thr/T	ACT,ACC,ACA,ACG	ACN
        Trp/W	TGG
        Tyr/Y	TAT,TAC	TAY
        Val/V	GTT,GTC,GTA,GTG	GTN
        STOP/*	TAA,TGA,TAG	TAR,TRA
        #START	ATG

        # From inverse table of "http://en.wikipedia.org/wiki/DNA_codon_table". Converted by
        #> gawk -v FS="[,\t /]" -v format="'%s':'%s'," '{if ($0!~/^#/){for (i=3;i<=NF;i++) {printf(format, $i, $2) } print();}}' aa2na.txt
    '''
    for line in cleaned(_aa_na_correspondence.split('\n')):
        fields = line.split('\t')
        aa3char, aa1char = fields[0].split('/')
        NA2AA.update((codon, aa1char) for codons in fields[1:] for codon in codons.split(','))
    return NA2AA

NA2AA = init_NA2AA()

def na2aa(triplet, spacer='-'):
    try:
        return NA2AA[triplet.upper()]
    except KeyError:
        if triplet.count(spacer) == 3:
            return '-'
        elif triplet.count(spacer) > 0:
            return '#'
        else:
            return 'X'

# PDB ID < 50% subset, 20230127
AAFreq = {'L': 0.0945, 'A': 0.0794, 'G': 0.0695, 'E': 0.0680, 'V': 0.0671,
          'S': 0.0658, 'K': 0.0593, 'D': 0.0570, 'I': 0.0557, 'T': 0.0539,
          'R': 0.0523, 'P': 0.0464, 'N': 0.0435, 'F': 0.0396, 'Q': 0.0389,
          'Y': 0.0332, 'H': 0.0271, 'M': 0.0227, 'C': 0.0132, 'W': 0.0129}

def get_cons(msa, unanimous=0.99, majority=0.5, use_most_common=False, ignore_space=False, breaking_aa_tie=False):
    msa_t = transpose(msa)
    aa_cnt = [collections.Counter(col) for col in msa_t]
    result = []
    for col in aa_cnt:
        cnt_all = sum(col.values())
        most_common_char, num = col.most_common(1)[0]
        if most_common_char == '-' and ignore_space and len(col) > 1:
            most_common_char, num = col.most_common(2)[1]

        # Break tie by frequency in proteins if there are other AA tie with the most_common AA
        if breaking_aa_tie:
            most_common_aas = [(aa, AAFreq[aa]) if aa in AAFreq else (aa, 0.0) for aa, cnt in col.items() if cnt == num] 
            most_common_char, aafreq = max(most_common_aas, key=lambda x: x[1])
        
        if 'X' in col:
            num += col['X']/20
        if num >= cnt_all * unanimous:
            result.append(most_common_char.upper())
        if num < cnt_all * unanimous and num >= cnt_all * majority:
            result.append(most_common_char.lower())
        if num < cnt_all * majority:
            if use_most_common:
                result.append(most_common_char.lower())
            else:
                result.append('?')
    return ''.join(result)

def eliminate_gaps(msa, th=0.2, gap_chars='-', triplet=False):
    """Eliminate cols have high fraction of gaps

    Return: modified_msa, the alignment with gaps removed

    Keyword arguments:
    msa -- the input alignment, [s1, s2, s3, ...]
    th -- the threshold of gap ratio, above which the column will be removed
    gap_chars -- chars in the alignmen be considered as gaps
    """
    spacer = set(gap_chars)
    n_seqs = len(msa)
    msa_t = transpose(msa)
    step = 1 if not triplet else 3
    result_t = []
    for i in range(0, len(msa_t), step):
        n_gaps = 0.0
        for j in range(n_seqs):
            is_gap = all(msa_t[i+k][j] in spacer for k in range(step))
            n_gaps += 1.0 if is_gap else 0.0
        gap_ratio = n_gaps / n_seqs
        if gap_ratio < th:
            result_t += [msa_t[i+k] for k in range(step)]
    return transpose(result_t)

def transpose(msa):
    try:
        msa_t = []  # Transposed msa
        for j in range(len(msa[0])):
            msa_t.append(''.join(x[j] for x in msa))
    except KeyError:
        #print('Check whether the MSA is empty or not same lengh.', file=sys.stderr)
        assert(False)
    return msa_t

def zopen(fname, specifications='rt', msg=None):
    " open compressed files "
    if fname.endswith('.gz'):
        import gzip
        open_fun = gzip.open
    elif fname.endswith('.bz2'):
        import bz2
        open_fun = bz2.open
    else:
        open_fun = open
    try:
        return open_fun(fname, specifications)
    except IOError:
        print('File open error. %s cannot be opened' %(fname))
        if msg is not None: print(msg)
        sys.exit()

def fasta_iter(filestream):
    faiter = (x[1] for x in it.groupby(filestream, lambda line: line[0] == ">"))
    for header in faiter:
        header_str = header.__next__()[1:].strip()
        seq = "".join(s.strip() for s in faiter.__next__())
        yield header_str, seq

def read_fasta(filestream):
    headers = []
    sequences = []
    for h, s in fasta_iter(filestream):
        headers.append(h)
        sequences.append(s)
    #for line in filestream.readlines():
    #    if type(line) is bytes:
    #        s = line.strip().decode()
    #    else:
    #        s = line.strip()
    #    if s.startswith('>'):
    #        headers.append(s[1:])
    #        sequences.append([])
    #    else:
    #        sequences[-1].append(s)
    #sequences = [''.join(seqs).replace(' ', '') for seqs in sequences]
    return (headers, sequences)

def write_fasta(filestream, head, seq, length=60):
    filestream.write('>{}\n'.format(head))  # filestream must be text mode ('wt')
    for chunk in chunkstring(seq, length):
        filestream.write('{}\n'.format(chunk))

def chunkstring(string, length):
    return (string[0+i:length+i] for i in range(0, len(string), length))

def parse():
    parser = argparse.ArgumentParser(description="Adjust the original aligned NA sequences under the assumption that the consensus is always in frame")
    parser.add_argument('in_na', help='original NA MSA (fasta format, can be compressed (.gz))')
    parser.add_argument('out_na', help='output NA alignment with codon adjusted')
    return parser.parse_args()

def main():
    para = parse()
    # Read seqs
    # original NA MSA
    with zopen(para.in_na) as infile:
        orig_names, orig_seqs = read_fasta(infile)

    # codon adjust the alignment
    codon_adjusted_seqs = codon_adjust(orig_seqs)
    codon_adjusted_seqs = eliminate_gaps(codon_adjusted_seqs, th=1.0, triplet=True)

    # '#-*#': two consective frame shifts -> one frame shift if possible
    na_cons = get_cons(codon_adjusted_seqs, use_most_common=True).upper()
    frame_shift_fixed = [fix_2frameshift(na_seq, na_cons) for na_seq in codon_adjusted_seqs]

    # output
    with zopen(para.out_na, 'wt') as outfile:
        for h, s in zip(orig_names, frame_shift_fixed):
            write_fasta(outfile, h, s)

if __name__ == "__main__":
    main()

