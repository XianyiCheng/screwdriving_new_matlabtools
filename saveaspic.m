function saveaspic(datadir, savedir, context_file)

bagdirs =  dir(fullfile(datadir,'*run_*'));
N = numel(bagdirs);

parfor k = 1:N
     dataset = Dataset(strcat(bagdirs(k).folder,'/',bagdirs(k).name), context_file);
     bagpicdir = strcat(savedir,'/',bagdirs(k).name);
     mkdir(bagpicdir);
     for i = 1:dataset.total
         dataset.load(i);
         if exist(strcat(bagpicdir, '/', dataset.cur_data.bagname,'.jpg'),'file')
             continue;
         end
         dataset.cur_data.savefig(bagpicdir);
     end

end

