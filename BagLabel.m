classdef BagLabel < handle
    
    properties
        
        labels;
        
        context;
        
    end
    
    methods
        function obj = BagLabel(context, labelpath)
            if nargin < 2
                obj.labels = struct('timeseries', {{}});
            else
                obj.labels = loadjson(labelpath);
            end
            obj.context = context;
        end
        
        function ok = setGlobalLabel(obj, key, value)
            %if obj.context.validateGlobal(key, value)
                obj.labels.(key) = value;
                ok = true;
            %else
            %    ok = false;
            %end
        end
        
        function ok = setComments(obj, text)
            obj.labels.comments = text;
            ok = true;
        end
        
        function ok = clearGlobalLabel(obj, key)
            if isfield(obj.labels, key)
                obj.labels = rmfield(obj.labels, key);
                ok = true;
            else
                ok = false;
            end
        end
        
        function res = getGlobalLabel(obj, key)
            res = cell(size(obj));
            ok = arrayfun(@(o) isfield(o.labels, key), obj);
            okl = [obj(ok).labels];
            res(ok) = {okl.(key)};
            res(~ok) = {'unknown'};
        end
        
        function ok = addTimeseriesLabel(obj, label, time)
            %if obj.context.validateTimeseries(label) && obj.validateTimeRange(time)
                obj.labels.timeseries{end+1} = struct('label', label, 'time', time(:)');
                ok = true;
            %else
             %   ok = false;
            %end
        end
        
        
        function label = getTimeseriesByLabel(obj, label_name)
            found = cellfun(@(ts) strcmp(ts.label, label_name), obj.labels.timeseries);
            if sum(found) == 0
                warning('BagLabel:noTimeseries', 'No timeseries found with label "%s"', label_name);
                label = struct('label', label_name, 'time', []);
            elseif sum(found) > 2
                warning('BagLabel:multipleTimeseries', 'Multiple timeseries found with label "%s"', label_name);
                label = struct('label', label_name, 'time', []);
            else
                label = obj.labels.timeseries{found};
            end
        end
        
        function label = getLabelForTime(obj, time)
            if numel(time) > 1
                label = cell2mat(arrayfun(@(t) obj.getLabelForTime(t), time, ...
                    'UniformOutput', false));
            else
                ts = [obj.labels.timeseries{:}];
                times = vertcat(ts.time);
                label = ts(times(:,1) <= time & times(:,2) > time);
            end
        end
        
        function labels = getLabelForTimeBatch(obj, times)
            idx = zeros(size(times));
            ts = [obj.labels.timeseries{:}];
            edges = vertcat(ts.time);
            for i=1:size(edges, 1)
                idx(times >= edges(i,1) & times < edges(i,2)) = i;
            end
            vals = {ts.label 'complete' 'NA'};
            idx(times > edges(end,2)) = numel(vals)-1;
            idx(idx == 0) = numel(vals);
            labels = vals(idx);
        end
        
        function clearTimeseries(obj)
            obj.labels.timeseries = {};
        end
        
        function save(obj, path)
            % Clear out empty fields
            was_cleared = false;
            if isempty(obj.labels.timeseries)
                obj.labels = rmfield(obj.labels, 'timeseries');
                was_cleared = true;
            end
            
            savejson('', obj.labels, path);
            
            if was_cleared
                obj.clearTimeseries();
            end
        end
        
    end
    
    methods (Static)
        
        function filter = makeGlobalChecker(key, desired)
            if nargin > 1
                filter = @(l) isfield(l.labels, key) && strcmp(l.labels.(key), desired);
            else
                filter = @(l) isfield(l.labels, key);
            end
        end
        
        function filter = makeTimeseriesStageChecker(key)
            filter = @(l) any(cellfun(@(s) strcmp(s.label, key), l.labels.timeseries));
        end
       
        
        function ok = validate(label)
            ok = true;
            if ~isfield(label.labels, 'Result')
                ok = false;
            else
                times = cellfun(@(s) s.time(1), label.labels.timeseries);
                [~, ind] = sort(times);
                stages = cellfun(@(s) s.label, label.labels.timeseries(ind), 'UniformOutput', false);
%                 disp(stages)
                switch label.labels.Result
                    case 'success'
                        if numel(stages) < 3 || ...
                                numel(stages) > 5 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                ~strcmp(stages{end-1}, 'rundown') || ...
                                ~strcmp(stages{end}, 'tightening') || ...
                                (numel(stages) == 4 && ~any(strcmp(stages{2}, {'initial_mating', 'hole_finding'}))) || ...
                                (numel(stages) == 5 && ~(strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating')))
%                             disp('err: success')
                            ok = false;
                        end
                    case 'crossthread'
                        if numel(stages) < 2 || ...
                                numel(stages) > 5 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                ~strcmp(stages{end}, 'tightening') || ...
                                (numel(stages) == 3 && ~any(strcmp(stages{2}, {'hole_finding', 'initial_mating'}))) || ...
                                (numel(stages) == 4 && ~((any(strcmp(stages{2}, {'hole_finding', 'initial_mating'})) && strcmp(stages{3}, 'rundown')) || ...
                                        strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating'))) || ...
                                (numel(stages) == 5 && ~(strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating') && strcmp(stages{4}, 'rundown')))
                            ok = false;
%                             disp('err: crossthread')
                        end
                    case 'noscrew'
                        if numel(stages) ~= 2 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                ~strcmp(stages{2}, 'no_screw_spinning')
                            ok = false;
%                             disp('err: noscrew');
                        end
                    case 'partial'
                        if numel(stages) < 3 || ...
                                numel(stages) > 4 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                ~strcmp(stages{end}, 'rundown') || ...
                                (numel(stages) == 3 && ~any(strcmp(stages{2}, {'hole_finding', 'initial_mating'}))) || ...
                                (numel(stages) == 4 && ~(strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating')))
                            ok = false;
%                             disp('err: partial')
                        end
                    case 'stripped'
                        if numel(stages) < 2 || ...
                                numel(stages) > 6 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                ~strcmp(stages{end}, 'stripped_tightening') || ...
                                (numel(stages) == 3 && ~any(strcmp(stages{2}, {'hole_finding', 'initial_mating'}))) || ...
                                (numel(stages) == 4 && ~(any(strcmp(stages{2}, {'hole_finding', 'initial_mating'})) && any(strcmp(stages{3}, {'rundown', 'stripped_rundown'})))) || ...
                                (numel(stages) == 5 && ~((strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating') && any(strcmp(stages{4}, {'rundown', 'stripped_rundown'}))) || ...
                                        (any(strcmp(stages{2}, {'hole_finding', 'initial_mating'})) && any(strcmp(stages{3}, {'rundown', 'stripped_rundown'})) && strcmp(stages{4}, 'tightening')))) || ...
                                (numel(stages) == 6 && ~(strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating') && any(strcmp(stages{4}, {'rundown', 'stripped_rundown'})) && strcmp(stages{5}, 'tightening')))
                            ok = false;
%                             disp('err: stripped')
                        end
                    case 'no_hole_found'
                        if numel(stages) < 2 || ...
                                numel(stages) > 3 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                (numel(stages) == 2 && ~any(strcmp(stages{2}, {'hole_finding', 'screw_fallen'}))) || ...
                                (numel(stages) == 3 && ~(strcmp(stages{2}, 'hole_finding') && any(strcmp(stages{3}, {'screw_fallen', 'no_screw_spinning'}))))
                            ok = false;
%                             disp('err: no_hole_found')
                        end
                    case 'stripped_no_engage'
                        if numel(stages) < 2 || ...
                                numel(stages) > 4 || ...
                                ~strcmp(stages{1}, 'approach') || ...
                                ~strcmp(stages{end}, 'stripped_engaging') || ...
                                (numel(stages) == 3 && ~any(strcmp(stages{2}, {'hole_finding', 'initial_mating'}))) || ...
                                (numel(stages) == 4 && ~(strcmp(stages{2}, 'hole_finding') && strcmp(stages{3}, 'initial_mating')))
                            ok = false;
%                             disp('err: stripped_no_engage')
                        end
                end
            end
        end
    end
    
    methods (Access = private)
        function ok = validateTimeRange(obj, time)
            % Make sure it is a valid time range first
            if length(time) ~= 2 || ~all(isnumeric(time)) || any(time < 0) || time(1) >= time(2)
                ok = false;
                return;
            end
            
            % Make sure it doesn't overlap with any other time
            for other_ts=obj.labels.timeseries
                otherRange = other_ts{1}.time;
                if (time(1) > otherRange(1) && time(1) < otherRange(2)) || ...  % t1 in [p1, p2]
                        (time(2) > otherRange(1) && time(2) < otherRange(2)) || ... % t2 in [p1, p2]
                        (time(1) <= otherRange(1) == time(2) >= otherRange(2)) % [t1,t2] either < p1 or > p2
                    ok = false;
                    return;
                end
            end
            
            ok = true;
            
        end
    end
end
