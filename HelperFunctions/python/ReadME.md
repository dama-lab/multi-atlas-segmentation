# Python Helper Fuction for the `MASMAT` toolbox

## Main functions
Main functions are stored in `segmentatiom_propagation.py`:

### `reg_aladin`:
> affine registration using NiftyReg package

### `reg_resample`:
> resample nifti image using NiftyReg package

### `reorient`
> reorient nifti image using nibabel library

### `N4_correction`
> N4 Bias Field Correction using nipype

### `N4_correction_slicer`
> N4 Bias Field Correction using 3D Slicer

### `N4_correction_itk`
> N4 Bias Field Correction using SimpleITK

### `mas_quickcheck`
> generate quickcheck files using FSL

### `affine_mask_propagation`
> generate slurm sbatch file for affine mask mask propagation

### `affine_label_fusion`
> [SLURM] affine label fusion (after slurm_affine_mask_propagation)

### `nonrigid_label_propagation`
> [SLURM] nonrigid label fusion

### `nonrigid_label_fusion`
> [SLURM] nonrigid label/brain-mask fusion (after slurm_nonrigid_label_propagation)

### `extract_label_volumes`
> extract label volumes from nifti files of segmentation labels





