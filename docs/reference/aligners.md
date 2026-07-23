---
icon: lucide/scale
---

# Aligner Reference

The homepage gives a brief summary of supported aligners. This page discusses which to
select and why, based on a benchmark of 9 of the 13 aligners against curated HIV-1 *env*
reference alignments, conducted as part of the author's M.Sc. thesis.

## Choosing an aligner

On the standard alignment-quality metrics (fD, fM, CSS, TC), all 9 benchmarked aligners
scored similarly (0.96–0.98 on fD/fM/CSS), indicating that these metrics do not
meaningfully separate the tools. What does separate them is how similar their *output
alignments* are to one another, measured pairwise and independent of any reference. Two
groups emerge from this comparison:

- MAFFT, MUSCLE, PROBCONS, Clustal Omega, and T-Coffee (in its default and regressive
  modes) produce alignments that are close to each other and to the curated reference; any
  of these can reasonably be chosen on the basis of speed or familiarity, since the choice
  has little effect on the resulting alignment.
- ClustalW, PRANK, and T-Coffee's `fmcoffee`/`quickaln` modes produce alignments that
  diverge noticeably from the main group and from each other, and should only be selected
  where there is a specific reason to do so, such as PRANK's phylogeny-aware indel
  placement.

`MAFFT` is the pipeline default and a reasonable choice for most datasets. Where the effect
of aligner choice on downstream results is a concern, alignment with one tool from the main
group alongside one of the outliers, followed by comparison of the two results, is
recommended.

## Aligner comparison table

| Aligner | Notes |
|---|---|
| MAFFT *(default)* | Fast, well-tested, recommended starting point. |
| MUSCLE | MUSCLE 5 reimplements the PROBCONS algorithm, so its output tends to closely resemble PROBCONS. |
| PROBCONS | Similar output to MUSCLE. Slower. |
| Clustal Omega | Fast and accurate, uses HMMs. |
| T-Coffee (default, regressive) | Other T-Coffee modes (`fmcoffee`, a meta-method combining several aligners; `quickaln`, a faster heuristic mode) can produce noticeably different alignments — see below. |
| ClustalW | Legacy aligner; use only with a clear understanding of the tradeoffs involved. |
| PRANK | Phylogeny-aware; attempts real alignment of variable regions, producing much longer alignments than other tools. |
| VIRULIGN | Modifies and discards sequences during alignment (frameshift handling) — see [caveats](#caveats). |
| MACSE | Also modifies sequences during alignment, though less aggressively than VIRULIGN and without discarding sequences. |
| MAFFT-SEED | Appropriate when seeding alignment with a curated `panel_alignment`. |
| MUSCLE-FAST | MUSCLE's Super5 mode — faster, for large datasets. |
| PAGAN | Phylogeny-Aware graph alignments. Not thoroughly tested.|

## Evaluation methodology

Five curated LANL reference alignments of HIV-1 *env* (subtype M, no recombinants) were split
by subtype and by batch (200 sequences max per file) into 134 reference sub-alignments, gaps
stripped, and realigned using 22 aligner/parameter combinations across the 9 tools above.

Two kinds of comparison were made:

- **Against the reference** — `qscore` was used to compute fD, fM, CSS, and TC scores
  between each inferred alignment and its curated reference.
- **Between aligners** — the `d_pos` distance ([Blackburne & Whelan
  2012](https://doi.org/10.1093/bioinformatics/btr701)) was computed pairwise between
  alignments inferred from the same input sequences (31,767 pairwise comparisons), and the
  result visualized with a Principal Coordinate Analysis (PCoA) to produce the clustering
  described above.

## Caveats

- **VIRULIGN and MACSE alter their input during alignment**, removing or translating
  sequence content beyond the addition of gaps; VIRULIGN can discard entire sequences it
  judges to be frameshifted. This makes reference-free (`d_pos`) comparison unreliable for
  both tools, and VIRULIGN's benchmark numbers rest on a smaller, less variable dataset
  than the other tools. Their scores should therefore be treated as indicative rather than
  definitive.
- **The benchmark was conducted using HIV-1 *env* sequences only**, and results may not
  generalize to other organisms or gene regions.
