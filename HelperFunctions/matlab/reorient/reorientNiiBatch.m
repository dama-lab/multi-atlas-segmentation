function reorientNiiBatch(inNiiDir,outNiiDir)
    targetlist = dir(fullfile(inNiiDir,'*_degibb.nii'));
    for id = 1:length(targetlist)
        target = targetlist(id);
        reoriented_path = fullfile(outNiiDir,target.name);
        if exist(reoriented_path,'file')
            fprintf("%s exist, skippping ...", target.name);
            continue
        end
        target = targetlist(id);
        target_path = fullfile(target.folder, target.name);
        reorientNii(target_path, outNiiDir);
    end