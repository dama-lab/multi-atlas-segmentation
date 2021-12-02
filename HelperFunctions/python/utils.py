# %%
import os
import numpy as np
import nibabel as nib

# %%
def get_nii_orientation(target):
  affine = nib.load(target).header.get_best_affine()
  orient = nib.orientations.aff2axcodes(affine)
  orient = ''.join(orient)
  return orient

# %%  
def reorient_vol(vol:np.ndarray, old_orient:(str,tuple), new_orient:(str,tuple)='LPS'):
  '''reorient volume according to orientation change'''
  # convert old_orient/new_orient from str ('LPS') into tuple: ('L', 'P', 'S')
  # if isinstance(new_orient, str): old_orient = tuple(old_orient) = src_axcode
  # if isinstance(new_orient, str): new_orient = tuple(new_orient) = des_axcode

  # convert source axcode into orientation array (with respect to standard RAS)
  src_ornt = nib.orientations.axcodes2ornt(tuple(old_orient)) # labels = (('L','R'), ('P','A'), ('I','S')) # =RAS
  # convert new_orient into dest_ornt orientation array
  dest_ornt = nib.orientations.axcodes2ornt(tuple(new_orient))
  # derive transform array from src_ornt to dest_ornt
  ornt_trans = nib.orientations.ornt_transform(src_ornt, dest_ornt)
  # apply the orientation transform array on the loaded volume
  vol_reoriented = nib.orientations.apply_orientation(vol, ornt_trans)
  return vol_reoriented

def reorient_nii(src_fname, dest_fname, old_orient="PIR", new_orient="RAS", verbose=False):
  # skip if result file already exist
  if os.path.isfile(dest_fname):
    if verbose==True: print(f"  --  {dest_fname} exist, skipping ...")
    return
  # load the raw volume
  vol_nii = nib.load(src_fname)
  # reorient the image
  vol_reorient = reorient_vol(vol_nii.get_fdata(), old_orient,new_orient)
  # save the reoriented images
  #%% save reoriented images # https://bic-berkeley.github.io/psych-214-fall-2016/saving_images.html
  vol_reorient_nii = nib.Nifti1Image(vol_reorient, vol_nii.affine, vol_nii.header)
  vol_reorient_nii.to_filename(dest_fname)
  return