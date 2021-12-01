import os, subprocess, multiprocessing
import nipype, pandas as pd
import bash_function_generators as slurm
from pathlib import Path
import SimpleITK as sitk

#%% Change this to your local location that store MASHelperFunctions.sh
mas_helpfunctions_path = f'../../MASHelperFunctions.sh'
mas_helpfunctions_path = f'/project/6003102/dma73/Code/multi-atlas-segmentation/MASHelperFunctions.sh'

#%%
def reg_aladin(ref_file, flo_file, res_file, aff_file=None, fmask_file=None, verbose=False, n_cpu=None, args='', **kwargs):
  '''  affine registration using NiftyReg package
  > ref: https://nipype.readthedocs.io/en/latest/api/generated/nipype.interfaces.niftyreg.regutils.html
  Parameters
  ----------

  Returns
  -------
  None.

  '''
  node = nipype.interfaces.niftyreg.RegAladin()
  node.inputs.ref_file = ref_file
  node.inputs.flo_file = flo_file
  node.inputs.res_file = res_file

  if not aff_file is None:
    node.inputs.aff_file = aff_file
  if not fmask_file is None:
    node.inputs.fmask_file = fmask_file
  if not args is None:
    node.inputs.args = args # ' '.join([arg for arg in args])
  if n_cpu is None:
    node.inputs.omp_core_val = multiprocessing.cpu_count()
  if verbose is True: print(node.cmdline)

  return node

#%%
def reg_resample(ref_file, flo_file, trans_file, res_file, inter=0, verbose=False, n_cpu=None, args='', **kwargs):
  '''
  -inter <int>
		Interpolation order (0, 1, 3, 4)[3] (0=NN, 1=LIN; 3=CUB, 4=SINC)
  Parameters
  ----------

    DESCRIPTION.

  Returns
  -------
  None.

  '''
  node = nipype.interfaces.niftyreg.RegResample()
  node.inputs.ref_file = ref_file
  node.inputs.flo_file = flo_file
  node.inputs.trans_file = trans_file
  node.inputs.out_file = res_file
  node.inputs.inter = inter
  
  if not args is None:
    node.inputs.args = args # ' '.join([arg for arg in args])
  if n_cpu is None:
    node.inputs.omp_core_val = multiprocessing.cpu_count()
  if verbose is True: print(node.cmdline)
  
  return node

def reorient(src_fname, dest_fname, old_orient="PIR", new_orient="RAS", verbose=False):
  # skip if result file already exist
  if os.path.isfile(dest_fname):
    if verbose==True: print(f"  --  {dest_fname} exist, skipping ...")
    return
  # load the raw volume
  vol_nii = nib.load(src_fname)
  # reorient the image
  vol_reorient = image_io.reorient_vol(vol_nii.get_fdata(), old_orient,new_orient)
  # save the reoriented images
  #%% save reoriented images # https://bic-berkeley.github.io/psych-214-fall-2016/saving_images.html
  vol_reorient_nii = nib.Nifti1Image(vol_reorient, vol_nii.affine, vol_nii.header)
  vol_reorient_nii.to_filename(dest_fname)
  return

def N4_correction(input_fname, n4_fname, mask_fname=None, exe=True, verbose=True, **kwargs):
  '''N4 Bias Field Correction using nipype
  # Ref: https://nipype.readthedocs.io/en/latest/api/generated/nipype.interfaces.ants.segmentation.html
  # Parameter options: https://www.programcreek.com/python/example/122771/nipype.interfaces.ants.N4BiasFieldCorrection
  # kwarg exsample:
    n4.inputs.dimension = 3
    n4.inputs.bspline_fitting_distance = 10
    n4.inputs.bspline_order = 4
    n4.inputs.shrink_factor = 3
    n4.inputs.n_iterations = [150,100,50,30]
    n4.inputs.convergence_threshold = 1e-11
  '''
  from nipype.interfaces.ants import N4BiasFieldCorrection
  # skip if result file already exist
  if os.path.isfile(n4_fname):
    if verbose==True: print(f"  --  {n4_fname} exist, skipping ...")
    return
  n4 = N4BiasFieldCorrection()
  n4.inputs.input_image = input_fname
  n4.inputs.output_image = n4_fname
  # use mask if specified
  if mask_fname is not None:
    n4.inputs.mask_image = mask_fname
  # add other specified keywords
  for key,value in kwargs.items():
    setattr(n4.inputs, key, value)

  if exe == True: 
    n4.run()
  
  return n4.cmdline

def N4_correction_slicer(input_fname, n4_fname, mask_fname=None, exe=True, verbose=False):
  '''N4 Bias Field Correction using nipype
  # Ref: https://nipype.readthedocs.io/en/latest/api/generated/nipype.interfaces.slicer.filtering.n4itkbiasfieldcorrection.html
  '''
  from nipype.interfaces.slicer.filtering import n4itkbiasfieldcorrection
  # skip if result file already exist
  if os.path.isfile(n4_fname):
    if verbose==True: print(f"  --  {n4_fname} exist, skipping ...")
    return

  if mask_fname is not None: n4.inputs.mask_image = mask_fname
  if exe == True: n4.run()
  return n4.cmdline

def N4_correction_itk(input_fname, n4_fname, mask_fname=None, exe=True, verbose=False, image_type=sitk.sitkFloat64, mask_type=sitk.sitkUInt8):
  '''N4 bias field correction with ITK
  # Parameter options: https://www.programcreek.com/python/example/122771/nipype.interfaces.ants.N4BiasFieldCorrection
  '''
  import SimpleITK as sitk
  # skip if result file already exist
  if os.path.isfile(n4_fname):
    if verbose==True: print(f"  --  {n4_fname} exist, skipping ...")
    return

  input_image = sitk.ReadImage(input_fname, outputPixelType=image_type)
  input_image = sitk.Cast(input_image,sitk.sitkFloat32)

  if mask_fname == None:
    output_image = sitk.N4BiasFieldCorrection(input_image)
  else:
    mask_image = sitk.ReadImage(mask_fname, outputPixelType=mask_type)
    output_image = sitk.N4BiasFieldCorrection(input_image, mask_image)

    corrector = sitk.N4BiasFieldCorrectionImageFilter()
    output = corrector.Execute(input_image, mask_image)

  sitk.WriteImage(output_image, n4_fname)
  return os.path.abspath(n4_fname)

#%% ===================

def mas_quickcheck(bg_img, qc_dir, qc_filename=None, overlay_img="''", exe=True, exe_mode='local'):
  '''generate quickcheck files'''
  # initialize slurm cmd

  if qc_filename == None:
    bg_name = ".".join(bg_img.split('/')[-1].split('.')[:-1])
    qc_filename = f"{bg_name}"
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null'  
  mas_quickcheck_cmd = f"{src_line}; mas_quickcheck {bg_img} {overlay_img} {qc_dir} {qc_filename}"

  if exe == True:
    if exe_mode == 'local':
      returned_value = subprocess.call(mas_quickcheck_cmd, shell=True)
      print('returned value:', returned_value)
      
  return mas_quickcheck_cmd


# [slurm] affine mask propagation
def affine_mask_propagation(target_dir, target_id, atlas_dir, result_dir, job_dir=None, verbose=False, mas_helpfunctions_path=mas_helpfunctions_path, **kwargs):
  '''generate slurm sbatch file for affine mask mask propagation
  - target_dir
  - target_id
  - atlas_dir
  - job_dir
  '''
  # get template list
  templatelist = os.listdir(f'{atlas_dir}/template/')
  templatelist  = [t.split('.')[0] for t in templatelist]
  
  # initialize slurm cmd
  slurm_cmd = slurm.generate_slurm_boilerplate(array=f'0-{len(templatelist)}', **kwargs)
  if job_dir is not None:
    job_out_dir = f"{job_dir}/output"
    Path(job_out_dir).mkdir(exist_ok=True, parents=True)
    slurm_cmd += f"#SBATCH --output={job_out_dir}/{target_id}_%j_%a.out\n"
    slurm_cmd += f"#SBATCH --error={job_out_dir}/{target_id}_%j_%a.error\n\n"
    
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null\n\n'  
  slurm_cmd += src_line
  
  # job array
  templatelist_str = ' '.join([t.split('.')[0] for t in templatelist])
  slurm_cmd += f"templatelist=({templatelist_str})\n"
  slurm_cmd += "atlas_id=${templatelist[$SLURM_ARRAY_TASK_ID]}\n"
  
  # command line
  slurm_cmd += f"mas_masking -T {target_dir} -t {target_id} -A {atlas_dir} -a $atlas_id -r {result_dir}"
  
  # print command
  if verbose is True:
    print(slurm_cmd)
  
  # write command
  slurm_cmd_path = None
  if not job_dir is None:
    slurm_cmd_path = f'{job_dir}/{target_id}_affine_mask.sh'
    slurm.write_slurm_script(slurm_cmd, slurm_cmd_path)
  
  return slurm_cmd_path, slurm_cmd


#%% ===================
# [slurm] affine label/mask fusion
def affine_label_fusion(target_dir, target_id, atlas_dir, result_dir, exe_mode='local', parallel=False, job_dir=None, verbose=False, mas_helpfunctions_path=mas_helpfunctions_path, **kwargs):
  '''[SLURM] affine label fusion (after slurm_affine_mask_propagation)
  parallel: (only for local run) 
    - True: call subprocess.Popen to run cmds in parallel
    - False: call subprocess.call to run cmds in sequential
  '''
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null'  
    
  mas_masking_fusion_cmd = f"{src_line}; mas_masking_fusion {target_dir} {target_id} {result_dir} {atlas_dir}"

  # print command
  if verbose is True:
    print(mas_masking_fusion_cmd)

  # execute the command
  if exe_mode == 'local':
    print("=== running locally ===")
    if parallel is True:
      returned_value = subprocess.Popen(mas_masking_fusion_cmd, shell=True)
    else: # run things in sequential order
      returned_value = subprocess.call(mas_masking_fusion_cmd, shell=True)
      print('returned value:', returned_value)
    return mas_masking_fusion_cmd
  elif exe_mode == 'slurm':
    cmd_path = None
    if job_dir is not None:
      Path(job_dir).mkdir(exist_ok=True, parents=True)
    cmd_path = f'{job_dir}/{target_id}_mask_labelfusion.sh'
    slurm_output=f"{job_dir}/{target_id}_%j.out\n"
    slurm_error=f"{job_dir}/{target_id}_%j.error\n"
    print(f"=== writing cmd to {cmd_path} ===")
    slurm.write_slurm_script(mas_masking_fusion_cmd, cmd_path, slurm=True,
                              output=slurm_output, error=slurm_error, **kwargs)
    return mas_masking_fusion_cmd, cmd_path 

  
#%% =================
# non-rigid label propagation
def nonrigid_label_propagation(target_dir, target_id, target_mask, atlas_dir, result_dir, exe_mode='slurm', job_dir=None, verbose=False, mas_helpfunctions_path=mas_helpfunctions_path, **kwargs):
  '''[SLURM] nonrigid label fusion
  '''
  # get template list
  templatelist = os.listdir(f'{atlas_dir}/template/')
  templatelist  = [t.split('.')[0] for t in templatelist]
  
  # initialize slurm cmd
  slurm_cmd = slurm.generate_slurm_boilerplate(array=f'0-{len(templatelist)}', **kwargs)
  if job_dir is not None:
    job_out_dir = f"{job_dir}/output"
    Path(job_out_dir).mkdir(exist_ok=True, parents=True)
    slurm_cmd += f"#SBATCH --output={job_out_dir}/{target_id}_%j_%a.out\n"
    slurm_cmd += f"#SBATCH --error={job_out_dir}/{target_id}_%j_%a.error\n\n"
    
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null\n\n'  
  slurm_cmd += src_line
  
  # job array
  templatelist_str = ' '.join([t.split('.')[0] for t in templatelist])
  slurm_cmd += f"templatelist=({templatelist_str})\n\n"
  slurm_cmd += "atlas_id=${templatelist[$SLURM_ARRAY_TASK_ID]}\n\n"
  
  # command line
  slurm_cmd += f"mas_mapping -T {target_dir} -t {target_id} -m {target_mask} -A {atlas_dir} -a $atlas_id -r {result_dir}"
  
  # print command
  if verbose is True:
    print(slurm_cmd)
  
  # write command
  slurm_cmd_path = None
  if not job_dir is None:
    Path(job_dir).mkdir(exist_ok=True, parents=True)
    slurm_cmd_path = f'{job_dir}/{target_id}_nonrigid_label.sh'
    slurm.write_slurm_script(slurm_cmd, slurm_cmd_path)
  
  return slurm_cmd_path, slurm_cmd

#%% ===================
# [slurm] affine label/mask fusion
def nonrigid_label_fusion(target_dir, target_id, atlas_name, atlas_list, result_dir, target_mask=None, exe_mode='local', parallel = False, job_dir=None, mas_helpfunctions_path=mas_helpfunctions_path, verbose=False, **kwargs):
  '''[SLURM] nonrigid label fusion (after slurm_nonrigid_label_propagation)'''
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null'  
    
  slurm_cmd = f"{src_line}; mas_fusion -T {target_dir} -t {target_id} -A {atlas_name} -a {atlas_list} -r {result_dir}"
  if target_mask is not None: slurm_cmd += f" -m {target_mask}"
  if exe_mode == 'local':
    print("=== running locally ===")
    if parallel == True:
      returned_value = subprocess.Popen(slurm_cmd , shell=True)
    elif parallel == False:
      returned_value = subprocess.call(slurm_cmd , shell=True)
    print('returned value:', returned_value)
    return slurm_cmd, returned_value
  elif exe_mode == 'slurm':
    cmd_path = None
    if not job_dir is None:
      job_out_dir = f"{job_dir}/output"
      Path(job_out_dir).mkdir(exist_ok=True, parents=True)
    cmd_path = f'{job_dir}/{target_id}_labelfusion.sh'
    slurm_output=f"{job_dir}/{target_id}_%j.out\n"
    slurm_error=f"{job_dir}/{target_id}_%j.error\n"
    print(f"=== writing cmd to {cmd_path} ===")
    if verbose is True:
      print(slurm_cmd)

    return cmd_path, slurm_cmd 
  

  
def extract_label_volumes(label_dir, targetlist, vol_dir, vol_csv_fname, ext='.nii.gz', tmp_subdir="tmp", structure_list=None):
  '''extract label volumes
  tmp_subdir: temp directory to save individual ccsv volumetrics files'''
  # make directory for individual volume csv
  vol_individuals = f"{vol_dir}/{tmp_subdir}"
  Path(vol_individuals).mkdir(exist_ok=True, parents=True)
  # remove result file if already exist
  vol_csv = f"{vol_dir}/{vol_csv_fname}"
  if os.path.isfile(vol_csv): os.remove(vol_csv)

  # add invidual volme one at a time
  for target_id in targetlist:
    vol_csv_individual = f"{vol_individuals}/{target_id}.csv"
    # extract the volume for single structure
    cmd = f"seg_stats {label_dir}/{target_id}{ext} -Vl {vol_csv_individual}"
    returned_value = subprocess.call(cmd, shell=True)
    # print('returned value:', returned_value)
    # write to master csv
    cmd = f'echo -e "{target_id},$(cat {vol_csv_individual})" >> {vol_csv}'
    returned_value = subprocess.call(cmd, shell=True)
    # break

  # read structure list if it's a file path
  if isinstance(structure_list, (str,Path)):
    structure_list = pd.read_csv(structure_list).structure_name
    # adding structural title to volume list  if structure_list is not None:
    volume_df = pd.read_csv(vol_csv, names=structure_list, header=None, index_col=0)
    volume_df.to_csv(vol_csv)
  else:
    volume_df = pd.read_csv(vol_csv, header=None, index_col=0)

  return volume_df


