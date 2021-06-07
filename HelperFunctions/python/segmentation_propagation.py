import os, subprocess, multiprocessing
import nipype
from med_deeplearning.HelperFunctions import bash_function_generators as slurm

#%% Change this to your local location that store MASHelperFunctions.sh
mas_helpfunctions_path = f'../../MASHelperFunctions.sh'

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
  
#%% ===================
# [slurm] affine mask propagation
def slurm_affine_mask_propagation(target_dir, target_id, atlas_dir, result_dir, job_dir=None, verbose=False, mas_helpfunctions_path=mas_helpfunctions_path, **kwargs):
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
def slurm_affine_label_fusion(target_dir, target_id, result_dir, atlas_dir, exe_mode='local', job_dir=None, mas_helpfunctions_path=mas_helpfunctions_path, **kwargs):
  '''[SLURM] affine label fusion (after slurm_affine_mask_propagation)'''
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null'  
    
  mas_masking_fusion_cmd = f"{src_line}; mas_masking_fusion {target_dir} {target_id} {result_dir} {atlas_dir}"
  if exe_mode == 'local':
    returned_value = subprocess.call(mas_masking_fusion_cmd, shell=True)
    print('returned value:', returned_value)
    return mas_masking_fusion_cmd
  elif exe_mode == 'slurm':
    cmd_path = None
    if not job_dir is None:
      Path(job_dir).mkdir(exist_ok=True, parents=True)
      cmd_path = f'{job_dir}/{target_id}_mask_labelfusion.sh'
      slurm.write_slurm_script(mas_masking_fusion_cmd, cmd_path, slurm=True, **kwargs)
    return cmd_path, mas_masking_fusion_cmd
  
#%% =================
# non-rigid label propagation
def slurm_nonrigid_label_propagation(target_dir, target_id, target_mask, atlas_dir, result_dir, exe_mode='slurm', job_dir=None, verbose=False, mas_helpfunctions_path=mas_helpfunctions_path, **kwargs):
  '''[SLURM] nonrigid label fusion
  '''
  # get template list
  templatelist = os.listdir(f'{atlas_dir}/template/')
  templatelist  = [t.split('.')[0] for t in templatelist]
  
  # initialize slurm cmd
  slurm_cmd = slurm.generate_slurm_boilerplate(array=f'0-{len(templatelist)}', **kwargs)
  
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
    slurm_cmd_path = f'{job_dir}/{target_id}_nonrigid_label.sh'
    slurm.write_slurm_script(slurm_cmd, slurm_cmd_path)
  
  return slurm_cmd_path, slurm_cmd

#%% ===================
# [slurm] affine label/mask fusion
def slurm_nonrigid_label_fusion(target_dir, target_id, atlas_name, atlas_list, result_dir, target_mask, exe_mode='local', job_dir=None, mas_helpfunctions_path=mas_helpfunctions_path, verbose=False, **kwargs):
  '''[SLURM] nonrigid label fusion (after slurm_nonrigid_label_propagation)'''
  # MASHelpfunction-specific lines
  src_line = f'source {mas_helpfunctions_path} > /dev/null'  
    
  slurm_cmd = f"{src_line}; mas_fusion -T {target_dir} -t {target_id} -A {atlas_name} -a {atlas_list} -r {result_dir} -m {target_mask}"
  if exe_mode == 'local':
    returned_value = subprocess.call(slurm_cmd , shell=True)
    print('returned value:', returned_value)
    return slurm_cmd 
  elif exe_mode == 'slurm':
    cmd_path = None
    if not job_dir is None:
      Path(job_dir).mkdir(exist_ok=True, parents=True)
      cmd_path = f'{job_dir}/{target_id}_mask_labelfusion.sh'
      # print command
      if verbose is True:
        print(slurm_cmd)
      slurm.write_slurm_script(slurm_cmd , cmd_path, slurm=True, **kwargs)
    return cmd_path, slurm_cmd 
  


