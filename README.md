Multi Atlas Segmentation (MAS) for mouse brain MRI
================================================

Author: Da Ma d.ma.11@ucl.ac.uk, da_ma@sfu.ca

**Description**

This bash scripts is created for "Multi-atlas based automatic brain structural parcellation", mainly for mouse brain MRI.

- This script achieve automatic brain MRI image segmentation with given __mouse brain MRI atlases__ - which is a set of pairs of template images along with their manually labells. Sample atlases can be downloadable from the Github respsitory [here](https://github.com/dancebean/mouse-brain-atlas). (This script should also be capable of handelling for multi-atlas-based human brain parcellation, providing appropriate human-brain atlases are givien.)

- Pre-requisite package installation: [NityReg](https://github.com/KCL-BMEIS/niftyreg/wiki), [NitySeg](https://github.com/KCL-BMEIS/NiftySeg), and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki). (Please make sure you've added into the system `$PATH` variable the directories of the executable files for all thre packages - which is the *bin* subdirectory within directory where ther packages are installed)

- The bash script is compatible with Linux/Windows/Mac system. For detailed description of the pipeline, please refer to the papers [[1]](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0086576) [[2]](https://www.frontiersin.org/articles/10.3389/fnins.2019.00011). Citation of the two papers are listed at the bottom of this page.


**Usage**

There is only one main script: *MASHelperFunctions.sh*, which is capable of handling batch brain parcellation (functions with suffix `_batch`) either on the local workstation or on PBS cluster by simply specifying the `-e` flag as either `local` or `cluster`).
To load the script, simply type `source MASHelperFunctions.sh` to load all corresponding functions.

To get help for each function, type `function_name -h`.
For example: `mas_mapping -h`

**[Important] Please make sure the orientation information in the header of your test image is correct before process**. Sometimes, it is a bit tricky to get the correct orientation for nifty images (please see the detailed explanation at FSL website [Ref1](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Orientation%20Explained) and [Ref 2](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Fslutils#Orientation-related_Utilities). Additional information in the answer of the first question in the Q/A session.

**Pipeline example**
- Load script:

  `source MASHelperFunctions.sh`

- Step 1: __*brain extraction*__ (masking)

  `mas_masking_batch -T “targe  t_dir” -t “target_list” -A “atlas_dir” -r “result_dir”`
  - `-h`: Use mas_masking_batch -h to show help for usage
  - `-T`: specify folder contain the target image to be segmented (images should be in nifty format: nii or nii.gz. The image orientation should be correctly indicated in the nifti header. Please refer to the Q&A section *What image orientation should my test image be?* for more details about image orientation.) 
  - `-t`: specify text file contain a list of target image file names inside the target_dir. (Each line contains the name of one image file. User can just provide file name without the `.nii` or '.nii.gz' extension. The algorithm will automatically figure out the correct file extension.) 
  - `-A`: folder contains the atlas (sample atlas containing multiple templates can be downloaded here)
  
    [Optional argument]
  - `-a`: text file list the templates inside the atlas folder to be used (default:  `template_list.cfg` file within the atlas folder)
  - `-p`: configuration file to tune the parameters for the registration and label fusion algorithms
  - `-e`: specify to run locally (`local`) on on `cluster` . Specify `cluster` will submit parallel pbs jobs to cluster; specify `local` will run job sequentially on local machine. cluster is set by default

- Step 2. __*brain structure parcellation*__

  `mas_parcellation_batch -T "target_dir" -t "target_list" -A "atlas_dir" -r "result_dir" -M "targetmask_dir"`
  - `-h`: Use mas_masking_batch -h to show help for usage
  - `-T`: specify folder contain the test image to be segmented
  - `-t`: specify text file contain a list of target image file names inside the target_dir (in nifty format: nii or nii.gz, can only provide file name without extension)
  - `-A`: folder contains the atlas (sample atlas containing multiple templates can be downloaded here)
  
  [optional argument]
  - `-M`: folder containing the brainmask file of the test images
  - `-m`: suffix (e.g. for `test1.nii.gz` with mask file `test1.mask.nii.gz`: `-m ".mask"`)
  - `-a`: text file list the templates inside the atlas folder to be used (default:  `template_list.cfg` file within the atlas folder)
  - `-p`: configuration file to tune the parameters for the registration and label fusion algorithms
  - `-a`: text file list the templates inside the atlas folder to be used (default:  `template_list.cfg` file within the atlas folder)
  - `-p`: configuration file to tune the parameters for the registration and label fusion algorithms

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
- `mas_parcellation_batch` (label propogations + fusions)
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

**Sample image of the pipeline output**
[![Sample output](docs/quickcheckdemo.png) "Click for sample quality control image of the parcellation output (generated using mas_quickcheck)."](docs/quickcheckdemo.png) The similar color between the olfactory bulb and the cortex is due to the limited colormap of `jet`.

**History and Roadmap**
- Older implementation in previous version (will be removed in future release)
  (Code repository move from the [original page](http://cmic.cs.ucl.ac.uk/staff/da_ma/multi_atlas/) that is stated in the paper.)
  - for_single_workstation: to be used on a single PC.
  - for_cluster: to be run on computer cluster, use parallel image registration to speed-up the process.
  - parameter_samples: sample parameter files that can be fed to the command when running the script [optional].
- Future release will also provide suport for Slurm-based clusters.

**Q/A**

- Q. What image orientation should my test image be?

  A. The orientation of the default atlas is: RAS, although the algorithms should be able to identify any correctly oriented images.
  
  **Check image orientation**:
  - If you have FSL installed, use `fslorient` to check the image orientation
  - If you have FreeSurfer installed, use `mri_info` to check the image orientations in the nifti header
  
  **Convert image orientation**:
  - If you have FSL installed, use `fslswapdim` to change the image orientation
  - If you have FreeSurfer installed, use `mri_convert --in_orientation $input_orientation --out_orientation $output_orientation -ot nifti -odt float $input_image $output_image`.
  
  Alternatively, if you use matlab, the script `orient_nii.m` uses the Matlab NIfTI toolbox (https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image) to interactively visualize and determine the orientation, as well as reorient it. 

- Q. Why is my parcellation not properly overlayed with the original image?

  A. Check if your MR image has been properly oriented to RAS (See the Q/A above). If that's not the problem, then make sure your MR image has been preprocessed to correct the bias field correction (also called bias field). There are several tools that can perform the bias field correction:
    
    (1) If you have the [ANTs](http://stnava.github.io/ANTs/) tools installed, the function `mas_N4_batch` used the handy bias field correction function `N4BiasFieldCorrection`  provide by ANTs package, which used an upgrade version of the N3 algorithm as used in the FreeSurfer's nu_correct, and it can handle the nifti format out-of-the-box as it's using the ITK framework.

    (2) If you have have [3D-slicer](https://www.slicer.org/wiki/Documentation/4.3/Modules/N4ITKBiasFieldCorrection) installed, it also provide  the N4ITK implementation of function `N4BiasFieldCorrection` through command line interface (CLI).
    
    (3) The [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/) package provide a tool `nu_correct` which uses N3 bias field correction algorithm.
    
    (4) The [NiftySeg](http://cmic.cs.ucl.ac.uk/staff/da_ma/Multi_Atlas/) package provide bias field correction using automatic tissue segmentation (**seg_EM**).

**Citation**

If you used our code in your study, we ask you to kindly cite the following papers:

- Ma D, Holmes HE, Cardoso MJ, Modat M, Harrison IF, Powell NM, O'Callaghan J, Ismail O, Johnson RA, O’Neill MJ, Collins EC. **Study the longitudinal in vivo and cross-sectional ex vivo brain volume difference for disease progression and treatment effect on mouse model of tauopathy using automated MRI structural parcellation.** Frontiers in Neuroscience. 2019;13:11.
https://www.frontiersin.org/articles/10.3389/fnins.2019.00011

- Ma D, Cardoso MJ, Modat M, Powell N, Wells J, Holmes H, Wiseman F, Tybulewicz V, Fisher E, Lythgoe MF, Ourselin S. **Automatic structural parcellation of mouse brain MRI using multi-atlas label fusion.** PloS one. 2014 Jan 27;9(1):e86576.
http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0086576

