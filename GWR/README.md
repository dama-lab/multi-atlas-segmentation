# This is the Group-wise Registration (Average Template Creation) pipeline.

It's modified from NiftyReg's original groupwise registration pipeline, which was designed for SGE pbs cluster architecture, and added the SLURM cluster compatibility

This script can be run either locally or on SLURM cluster.


#Reference:
Original NiftyReg Groupwise registration pipeline:
- http://cmictig.cs.ucl.ac.uk/wiki/index.php/Niftyreg_Groupwise
Python wrapper using Nipype:
- https://nipype.readthedocs.io/en/1.1.7/interfaces/generated/workflows.smri/niftyreg.groupwise.html
