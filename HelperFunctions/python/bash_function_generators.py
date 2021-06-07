# -*- coding: utf-8 -*-
import os

#%% function to write to a sbatch file
def get_default_conda_env(conda_env_sh):
  conda_lines = f'''## activate the virtual environment
source {conda_env_sh}
conda_init              > /dev/null 2>&1
conda deactivate        > /dev/null 2>&1
conda activate fastai   > /dev/null 2>&1
  '''
  return conda_lines

#%%
def generate_slurm_boilerplate(time="3:00:00", ntasks=1, account='rrg-mfbeg-ad', mem=8000, singleline=False, **kwargs):
  '''
  Generate slurm sbatch job submission biolerplate
  kwargs:
    - mem-per-cpu="8000"
    - array="1-4"
  -------------
  bol: begin-of-line
  eol: end-of-line
  '''
  
  if singleline is False:
    sbatch_str = "#!/bin/bash\n"
    bol = '#SBATCH'
    eol = '\n'
  else:
    sbatch_str = "sbatch"
    bol = ''
    eol = ' '
  
  # if speficied account as None, use user's own linux group
  if account is None:
    account = os.getenv('USER')
  
  args = ['time','ntasks','account', 'mem']
  vals = [ time , ntasks , account , mem]
  #% add default sbatch arguments (convert '_' to '-')
  for i,arg in enumerate(args):
    sbatch_str += f"{bol} --{arg.replace('_','-')}={vals[i]}{eol}"
  #% add other sbatch arguments
  for key in kwargs.keys():
    sbatch_str += (f"{bol} --{key.replace('_','-')}={kwargs[key]}{eol}")
    
  sbatch_str += eol
  return sbatch_str


def generate_slurm_conda_boilerplate(**kwargs):
  sbatch_str = generate_slurm_boilerplate(**kwargs) + get_default_conda_env()
  return sbatch_str

#%%
def write_slurm_script(cmd_lines, cmd_path, slurm=False, conda=False, **kwargs):
  with open(cmd_path, "w") as f:
    if slurm is True:
      f.write(generate_slurm_boilerplate(**kwargs))
    if conda is True:
      f.write(get_default_conda_env())
    for line in cmd_lines:
      f.write(line)
  
