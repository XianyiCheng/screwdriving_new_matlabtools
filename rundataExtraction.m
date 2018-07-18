function rundataExtraction(directory, savedirectory)

bagdirs = dir(fullfile(directory,'*run*'));
for k = 1:numel(bagdirs)
    bagdir = strcat(directory,'/',bagdirs(k).name);
    savedir = strcat(savedirectory, '/', bagdirs(k).name);
    mkdir(savedir);
    bagfiles = dir(fullfile(bagdir,'*.bag'));
    for i = 1:numel(bagfiles)
        bagpath = bagfiles(i).name;
        if exist(strcat(savedir,'/',bagpath(1:end-4),'_info.json'),'file')
            continue;
        end
        bagdataExtraction(bagdir, bagpath, savedir);
    end

end

