# affine transformation parameter for masking (for reg_aladin)
# -nac: initialize transformation with nifty header (default: centre of image)
# -cog: centor of mass/gravity of mask to initialize transformation (default: centre of image)
affine_param="" # e.g. -rigOnly -nac

# parameter for reg_resample
resamp_param=""

# parameter for seg_LabFusion in mas_masking
labfusion_param=""

# parameter for reg_f3d in mas_mapping
nrr_param=""


################################################################
# AVOID define parameters for the following internal variable:
# -mas_mapping_param, mas_fusion_param, mas_parcell_fusion_param
# Otherwise, may cause program error
################################################################