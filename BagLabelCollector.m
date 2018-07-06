classdef BagLabelCollector < handle
    
   properties
      label_counts
      result_counts
      total
   end
   
   methods
       function obj = BagLabelCollector()
           obj.label_counts = struct();
           obj.result_counts = struct();
           obj.total = 0;
       end
       function update(obj, label)
           obj.total = obj.total + 1;
           
           ts = [label.labels.timeseries{:}];
           for stage={ts.label}
               st = stage{1};
               if isfield(obj.label_counts, st)
                   obj.label_counts.(st) = obj.label_counts.(st)+1;
               else
                   obj.label_counts.(st) = 1;
               end
           end
           
           res = label.labels.Result;
           if isfield(obj.result_counts, res)
               obj.result_counts.(res) = obj.result_counts.(res) + 1;
           else
               obj.result_counts.(res) = 1;
           end
       end
       
       function res = getResultInfo(obj)
           cts = struct2cell(obj.result_counts);
           res = sortrows(table(cts, cellfun(@(x) x/obj.total, cts, 'UniformOutput', false), ...
               'VariableNames', {'Count', 'Percent'}, ...
               'RowNames', fieldnames(obj.result_counts)), 1, 'descend');           
       end
       
       function res = getStageInfo(obj)
           cts = struct2cell(obj.label_counts);
           res = sortrows(table(cts, cellfun(@(x) x/obj.total, cts, 'UniformOutput', false), ...
               'VariableNames', {'Count', 'Percent'}, ...
               'RowNames', fieldnames(obj.label_counts)), 1, 'descend'); 
       end
   end
       
end