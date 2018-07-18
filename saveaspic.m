function saveaspic(datadir, savedir, context_file)

bagdirs =  dir(fullfile(datadir,'*run_*'));
N = numel(bagdirs);

for k = 1:N
     dataset = Dataset(strcat(bagdirs(k).folder,'/',bagdirs(k).name), context_file);
     bagpicdir = strcat(savedir,'/',bagdirs(k).name);
     mkdir(bagpicdir);
     for i = 1:dataset.total
         if exist(strcat(bagpicdir, '/', dataset.files(i).name(1:end-4),'.jpg'),'file')
             continue;
         end
         dataset.load(i);
         dataset.cur_data.savefig(bagpicdir);
     end

end

