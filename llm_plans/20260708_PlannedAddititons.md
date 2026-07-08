This document details a set of modifications and additions to this nextflow pipeline. In a nutshell:

1. Add a "renaming" module, where sequence files are renamed according to ELLPACA rules.
2. Add a start and stop codon check. 
3. Add the ability to add sequences into the pipeline at certain steps. E.G sequences in file A get sent through trimming etc. but file B get added to file A after that trimming.  
4. Add an IQTree module to build trees from the alignments. Need to allow for specific params to be supplied.
5. Add the tree image drawing? 

---
plan for ellpaca data:

1. Start from contam files. Do not add LANL, rename sequences correctly.
2. Label LANL files correctly. 
3. Hopefully using the pipeline:
    a) Trim ELLPACA seqs. 
    b) maybe translate the lanl seqs?
    c) add the lanl seqs to the trimmed ellpaca seqs
    d) filter looking for start codon, stop codon, and using length filter (only allowed to lose 5 amino acids)
    e) align filtered sequences (and rev trans and all that)
    f) build trees

4. Get mindist sequence.
5. Draw trees, rooting on mindist seq.
6. Draw highliter plot with consensus as ref, mindist as ref
7. Output 