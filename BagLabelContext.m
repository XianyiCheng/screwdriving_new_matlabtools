classdef BagLabelContext < handle
   
    properties
        globals;
        timeseries_labels;       
        
    end
    
    methods
        function obj = BagLabelContext()
            obj.globals = struct();
            obj.timeseries_labels = {};
        end
        
        function save(obj, filename)
            data = struct('globals', obj.globals, 'timeseries', struct('labels', {obj.timeseries_labels}));
            savejson('', data, filename);
        end
        
        function ok = validateGlobal(obj, key, value)
            if ~isfield(obj.globals, key)
                ok = false;
                return;
            end
            
            if ~any(strcmp(value, obj.globals.(key)))
                ok = false;
                return
            end
            
            ok = true;
        end
        
        function ok = validateTimeseries(obj, label)
             
            if ~any(strcmp(label, obj.timeseries_labels))
                ok = false;
                return
            end
            
            ok = true;
        end
        
        function idx = getGlobalIndex(obj, key, value)
            idx = find(strcmp(obj.globals.(key), value));
        end
        
        function idx = getTimeseriesIndex(obj, value)
            if iscell(value) && numel(value) > 1
                idx = cellfun(@(v) obj.getTimeseriesIndex(v), value);
            else
               idx = find(strcmp(obj.timeseries_labels, value)); 
            end
        end
                
    end
    
    methods (Static)
        function obj = load(filename)
            obj = BagLabelContext();
            json = loadjson(filename);
            obj.globals = json.globals;
            obj.timeseries_labels = json.timeseries.labels;
        end
    end
    
    methods (Access = private)
    end
    
    
end