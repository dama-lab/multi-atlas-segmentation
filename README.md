Multi Atlas Segmentation (MAS) for mouse brain MRI
================================================

Author: Da Ma d.ma.11@ucl.ac.uk, da_ma@sfu.ca

**Description**

This bash scripts is created for "Multi-atlas based automatic brain structural parcellation", mainly for mouse brain MRI.

- [Respsitory](https://github.com/dancebean/mouse-brain-atlas) of mouse brain MRI atlas is also downloadable.

- Pre-requisite package installation: [NityReg](https://sourceforge.net/projects/niftyreg/), [NitySeg](https://sourceforge.net/projects/niftyseg/), and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki).

The bash script is compatible to Linux/Windows/Mac. For detailed description of the pipeline, with proper setup, and download link for the mouse brain atlas, please refer to the papers [[1]](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0086576) [[2]](https://www.frontiersin.org/articles/10.3389/fnins.2019.00011). Citation of the two papers are listed at the bottom of this page.

(This script is also capable of handelling for multi-atlas-based human brain parcellation, with appropriate human-brain atlas.)

**Usage**

There is only one main script: *MASHelperFunctions.sh* which is capable of handling batch brain parcellation (functions with suffix `_batch`) either on the local workstation or on PBS cluster by simply specifying the `-e` flag as either `local` or `cluster`).  (suport for Slurm cluster is also under development.)
To load the script, simply type `source MASHelperFunctions.sh` to load all corresponding functions.

To get help for each function, type `function_name -h`.
For example: `mas_mapping -h`

**Pipeline**
1. Brain extraction (masking)

**List of functions**

[Basic functions]
- `check_image_file`
- `check_atlas_file`
- `check_mapping_file`
- `check_label_fusion_file`

[Single image processing functions]
- `mas_masking` (prerequisite: NiftyReg): single atlas brain masking (affine image registration)
- `mas_masking_fusion` (prerequisite: NiftySeg): multi atlas brain masking (fuse the result from mas_masking)
- `mas_mapping` (prerequisite: NiftyReg): single atlas label propagation
- `mas_fusion` (prerequisite: NiftySeg): multi atlas label fusion
- `mas_quickcheck` (prerequisite: FSL): quality control (quickcheck) image generator
- `mas_label_volume` (prerequisite: NiftySeg): extract label volume (into a .csv file)
- `mas_template_function`: template functions for advanced user to develop your own additional functions

[Batch image processing functions]:
- `mas_masking_batch`
- `mas_mask_dilate_batch`
- `mas_mapping_batch`
- `mas_fusion_batch`
- `mas_parcellation_batch` (label propogations + label fusions)
- `mas_quickcheck_batch`
(The parallel brain structure parcellation on PBS cluster is achieved through PBS array and PBS dependency.)

[ Pre-processing functions ]:
- `mas_fix_header_info`
- `mas_smooth_batch`
- `mas_N4_batch` (prerequisite: ANT)

[ Post-processing functions ]:
- `mas_extract_label`
- `mas_extract_label_batch`
- `mas_extract_volume`
- `mas_extract_volume_batch`
- `mas_quickcheck_panorama`

[![Sample output](docs/quickcheckdemo.png) "Click for sample quality control image of the parcellation output (generated using mas_quickcheck). The similar color between the olfactory bulb and the cortex is due to the limited colormap of `jet`."](docs/quickcheckdemo.png)

**Older implementation in previous version (will be removed in future release)**

- for_single_workstation: to be used on a single PC.
- for_cluster: to be run on computer cluster, use parallel image registration to speed-up the process.
- parameter_samples: sample parameter files that can be fed to the command when running the script [optional].

**Q/A**

- Q. What image orientation should my test image be?

  A. The orientation of the default atlas is: RAS.
  If you have FreeSurfer installed, `use mri_convert --in_orientation $input_orientation --out_orientation $output_orientation -ot nifti -odt float $input_image $output_image`.
  Alternatively, if you use matlab, the script orient_nii.m uses the Matlab NIfTI toolbox (https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image) to visualize and determine the orientation, as well as reorient it. 

- Q. Why is my parcellation not properly overlayed with the original image?

  A. Check if your MR image has been properly oriented to RAS (See the Q/A above). If that's not the problem, then make sure your MR image has been preprocessed to correct the bias field correction (also called bias field). There are several tools that can perform the bias field correction:
    
    (1) The FreeSurfer package (https://surfer.nmr.mgh.harvard.edu/) provide a tool (**nu_correct**) which uses N3 bias field correction algorithm.
    
    (2) The NiftySeg package (http://cmic.cs.ucl.ac.uk/staff/da_ma/Multi_Atlas/) provide bias field correction using automatic tissue segmentation (**seg_EM**).
    
    (3) The ANTs tools (http://stnava.github.io/ANTs/) provide a handy bias field correction function (**N4BiasFieldCorrection**) which used an upgrade version of the N3 algorithm as used in the FreeSurfer's nu_correct, and it can handle the nifti format out-of-the-box as it's using the ITK framework.
    
    (4) The 3D-slicer (https://www.slicer.org/wiki/Documentation/4.3/Modules/N4ITKBiasFieldCorrection) also provide the N4ITK through command line interface (CLI) (**N4BiasFieldCorrection**).

**Citation**

We ask you to kindly cite the following papers when you used our code in your study:

Ma D, Holmes HE, Cardoso MJ, Modat M, Harrison IF, Powell NM, O'Callaghan J, Ismail O, Johnson RA, O’Neill MJ, Collins EC. **Study the longitudinal in vivo and cross-sectional ex vivo brain volume difference for disease progression and treatment effect on mouse model of tauopathy using automated MRI structural parcellation.** Frontiers in Neuroscience. 2019;13:11.
https://www.frontiersin.org/articles/10.3389/fnins.2019.00011

Ma D, Cardoso MJ, Modat M, Powell N, Wells J, Holmes H, Wiseman F, Tybulewicz V, Fisher E, Lythgoe MF, Ourselin S. **Automatic structural parcellation of mouse brain MRI using multi-atlas label fusion.** PloS one. 2014 Jan 27;9(1):e86576.
http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0086576

