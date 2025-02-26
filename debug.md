output from aga:

[
  [
  "work/SAMPLE_B_CDS_AA_27K-protein-premature-termination.fasta", 
  "work/SAMPLE_B_CDS_AA_R-ORF-protein.fasta", 
  "work/SAMPLE_B_CDS_AA_envelope-polyprotein.fasta", 
  "work/SAMPLE_B_CDS_AA_gag.fasta, work/SAMPLE_B_CDS_AA_pol-nh2-terminus-uncertain.fasta", 
  "work/SAMPLE_B_CDS_AA_sor-23K-protein.fasta", 
  "work/SAMPLE_B_CDS_AA_tat-protein.fasta", 
  "work/SAMPLE_B_CDS_AA_trs-protein.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50256.1.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50257.1.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50258.1.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50259.1.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50260.1.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50261.1.fasta", 
  "work/SAMPLE_B_PROT_AA_AAB50262.1.fasta",
  "work/SAMPLE_B_PROT_AA_AAB50263.1.fasta"
  ], 
  "work/SAMPLE_B_report.csv",  
  ["sample_id":"SAMPLE_B", "cap_name":1,"visit_id":2, "sequencing_pool":"one", "reference":"None", "cds_name":"7_envelope_polyprotein"]
  ]



  [
  [
  "work/SAMPLE_A_CDS_AA_27K-protein-premature-termination.fasta", 
  "work/SAMPLE_A_CDS_AA_R-ORF-protein.fasta", 
  "work/SAMPLE_A_CDS_AA_envelope-polyprotein.fasta", 
  "work/SAMPLE_A_CDS_AA_gag.fasta, work/SAMPLE_A_CDS_AA_pol-nh2-terminus-uncertain.fasta", 
  "work/SAMPLE_A_CDS_AA_sor-23K-protein.fasta", 
  "work/SAMPLE_A_CDS_AA_tat-protein.fasta", 
  "work/SAMPLE_A_CDS_AA_trs-protein.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50256.1.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50257.1.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50258.1.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50259.1.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50260.1.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50261.1.fasta", 
  "work/SAMPLE_A_PROT_AA_AAB50262.1.fasta",
  "work/SAMPLE_A_PROT_AA_AAB50263.1.fasta"
  ], 
  "work/SAMPLE_A_report.csv",  
  ["sample_id":"SAMPLE_A", "cap_name":1,"visit_id":2, "sequencing_pool":"one", "reference":"None", "cds_name":"7_envelope_polyprotein"]
  ]


output after list function

[
  work/SAMPLE_A_CDS_AA_envelope-polyprotein.fasta,
  work/SAMPLE_A_report.csv,
  
  [sample_id:SAMPLE_A, cap_name:1, visit_id:1, sequencing_pool:two, reference:None, cds_name:7_envelope_polyprotein, region:envelope-polyprotein, seq_type:AA, region_type:CDS]
]

[
  work/SAMPLE_B_CDS_AA_envelope-polyprotein.fasta,
  work/SAMPLE_B_report.csv, 
  
  [sample_id:SAMPLE_B, cap_name:1, visit_id:2, sequencing_pool:one, reference:None, cds_name:7_envelope_polyprotein, region:envelope-polyprotein, seq_type:AA, region_type:CDS]

]