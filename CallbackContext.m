classdef CallbackContext < handle
    
    properties
        state
        time_regions
        
        active_index;
        start_time;
        
        lines;
        lines_listeners;
        
        bagdata;
        
        commentsbox;
        tstoggle;
        tslist;
        timedisplay;
    end
    
    methods
        function obj = CallbackContext(bagdata)
            obj.state = 'normal';
            obj.time_regions = TimeRegion.empty;
            obj.active_index = -1;
            
            obj.bagdata = bagdata;
            
            obj.lines_listeners = event.proplistener.empty;

            for ts=obj.bagdata.label.labels.timeseries
                obj.insertTimeRegion(TimeRegion.load(obj.bagdata.dispdata.plots.axes, ...
                    obj.bagdata.label.context.timeseries.labels, ts{1}));
            end
        
            % Set up the global ui controls
            obj.timedisplay = uicontrol('Style', 'text', 'Parent', obj.bagdata.dispdata.figure, ...
                'Units', 'normalized', 'FontSize', 16, ...
                'Position', [0.4 0.3 0.2 0.05], 'String', ' s', ...
                'HorizontalAlignment', 'center');
            hbox = uix.HBox('Parent', obj.bagdata.dispdata.figure, ...
                'Units', 'normalized', 'Position', [0 0.1 1 0.15]);
            panel = uix.BoxPanel('Parent', hbox, 'Title', 'Timeseries info');
            box = uix.VBox('Parent', panel);
            obj.tstoggle = uicontrol(box, 'Style', 'togglebutton', 'Min', 0, 'Max', 1, ...
                'Value', 1, 'Callback', @obj.toggleOverlays, 'String', 'Timeseries overlays');
            obj.tslist = uicontrol(box, 'Style', 'listbox', 'Max', 2, 'Min', 0, ...
                'String', obj.time_regions.toString(), ...
                'KeyPressFcn', @obj.tsListKeyCallback, 'Value', [], ...
                'Callback', @obj.tsListCallback);
            
       
            for fn=fieldnames(obj.bagdata.label.context.globals)
                box = uix.BoxPanel('Parent', hbox, 'Title', fn);
                if isfield(obj.bagdata.label.labels, fn{1})
                    index = 1+find(strcmp(obj.bagdata.label.labels.(fn{1}), ...
                        obj.bagdata.label.context.globals.(fn{1})));
                else
                    index = 1;
                end
                uicontrol(box, 'Style', 'popup', 'String', ...
                    ['<uncategorized>' obj.bagdata.label.context.globals.(fn{1})], ...
                    'UserData', fn{1}, 'Callback', @obj.globalSettingsCallback, ...
                    'Value', index);
            end
          
            box = uix.BoxPanel('Parent', hbox, 'Title', 'Comments');
            if isfield(obj.bagdata.label.labels, 'comments')
                comment = obj.bagdata.label.labels.comments; 
            else
                comment = ''; 
            end
            obj.commentsbox = uicontrol(box, 'Style', 'edit', 'Max', 3, 'Min', 1, ...
                'String', comment, 'HorizontalAlignment', 'left');
                
                
        end
        
        function toggleOverlays(obj, src, data)
            for ts = obj.time_regions
                ts.setVisible(src.Value);
            end
            if ~src.Value
                switch obj.state
                    case 'creating'
                        obj.cancelCreating();
                    case 'selected'
                        obj.cancelSelected();
                end
            end
                
        end
        
        function clickCallback(obj, src, data)
            
            % Get the clicked-on time
            [time, axindex] = get_time_choice_from_axes(obj.bagdata.dispdata.figure,...
                obj.bagdata.dispdata.plots.axes);
            
            if ~obj.tstoggle.Value
                return;
            end
            
            switch obj.state
                case 'normal'
                    if ~isempty(time)
                        [found, ~, index] = obj.isInTimeSpan(time);
                        if found
                            obj.selectRegion(index, axindex);
                        else
                            % We clicked on a valid time, so initiate a region
                            obj.active_index = obj.addTimeRegion([time time]);
                            obj.state = 'creating';
                            obj.start_time = time;
                        end
                    end
                case 'creating'
                    obj.time_regions(obj.active_index).create();
                    if iscell(obj.tslist.String)
                       obj.tslist.String = {obj.tslist.String{1:obj.active_index-1} ...
                            obj.time_regions(obj.active_index).toString() ...
                            obj.tslist.String{obj.active_index:end}};
                    elseif obj.active_index == 0
                       obj.tslist.String = { ...
                            obj.time_regions(obj.active_index).toString() ...
                            obj.tslist.String};
                    else
                       obj.tslist.String = {obj.tslist.String ...
                            obj.time_regions(obj.active_index).toString()};
                    end
                       
                        
                    addlistener(obj.time_regions(obj.active_index), 'label', ...
                        'PostSet', @obj.refreshTsListSelect);
                    obj.active_index = -1;
                    obj.state = 'normal';
                    
                case 'selected'
                    
                    if ~isempty(time)
                        [found, ~, index] = obj.isInTimeSpan(time);
                        if ~found || index ~= obj.active_index
                            obj.cancelSelected();
                        end
                    else
                        obj.cancelSelected();
                    end
                                        
            end
        end
        
        function moveCallback(obj, src, data)
            
            if isMultipleCall()
                disp('aborted');
                return; 
            end
            
            % Get the clicked-on time
            time = get_time_choice_from_axes(obj.bagdata.dispdata.figure,...
                obj.bagdata.dispdata.plots.axes);
            
            obj.updateImage(time);
            set(obj.timedisplay, 'String', sprintf('%0.3f s', time));
            
            switch obj.state
                case 'normal'
                    if ~isempty(time)
                        
                        % Update the lines    
                        if ~isempty(obj.lines)
                            set(obj.lines, 'XData', [time time]);
                        else
                            for ax=obj.bagdata.dispdata.plots.axes
                                ylims = get(ax, 'YLim');
                                hold(ax, 'on');
                                line = plot(ax, [time time], ylims, '-k', 'HandleVisibility','off');
                                obj.lines(end+1) = line;
                                obj.lines_listeners(end+1) = addlistener(ax, 'YLim', 'PostSet', ...
                                    @(s,d) set(line, 'YData', get(ax, 'YLim')));
                            end
                        end
                        % Make dashed if in existing region
                        if obj.isInTimeSpan(time) && obj.tstoggle.Value
                            set(obj.lines, 'LineStyle', '--');
                        else
                            set(obj.lines, 'LineStyle', '-');
                        end
                    end
                case 'creating'
                    if isempty(time)
                        if find(obj.time_regions(obj.active_index).time == obj.start_time) == 1
                            time = obj.bagdata.duration;
                        else
                            time = 0;
                        end
                    end
                    ts = obj.getTimeSpans();
                    ts = ts';
                    ts = ts(:);
                    
                    [timeseries, sorted_indices] = sort([obj.start_time; time; ts]);
                    start_index = find(sorted_indices == 1);
                    if obj.start_time >= time
                        if start_index > 1
                            times = timeseries([start_index-1 start_index])';
                        else
                            times = timeseries([start_index start_index])';
                        end
                    else
                        if start_index < numel(ts)+2
                            times = timeseries([start_index start_index+1])';
                        else
                            times = timeseries([start_index start_index])';
                        end
                    end
                    
                    obj.time_regions(obj.active_index).setTime(times);
            end
            
        end
            
        function keyCallback(obj, src, data)
            switch obj.state
                case 'creating'
                    switch data.Key
                        case 'escape'
                            obj.cancelCreating();
                    end
                case 'selected'
                    switch data.Key
                        case 'escape'
                            obj.cancelSelected();
                        case {'delete', 'backspace'}
                            obj.deleteTimeseries(obj.active_index);
                    end
                
            end
            
        end
        
        function globalSettingsCallback(obj, src, data)
            if src.Value > 1
                obj.bagdata.label.setGlobalLabel(src.UserData, src.String{src.Value});
            else
                obj.bagdata.label.clearGlobalLabel(src.UserData);
            end
        end
        
        function tsListCallback(obj, src, data)
            if numel(obj.tslist.Value) == 1
                switch obj.state
                    case 'creating'
                        obj.cancelCreating();
                    case 'selected'
                        if obj.active_index == obj.tslist.Value
                            return;
                        else
                            obj.cancelSelected()
                        end
                end
                obj.selectRegion(obj.tslist.Value, 1);
            end
        end
        
        function tsListKeyCallback(obj, src, data)
            switch data.Key
                case 'delete'
                    obj.deleteTimeseries(src.Value);
            end
        end
        
        function refreshTsListSelect(obj, src, data)
            elems = obj.time_regions.toString();
            if iscell(elems)
                obj.tslist.String = elems;
            else
                obj.tslist.String = {elems};
            end
        end
        
        function nextCallback(obj, src, data, close_callback)
            obj.save();
            close(src.Parent)
            close_callback();
        end
        
        function skipCallback(obj, src, data, close_callback)
            close(src.Parent)
            close_callback();
        end
        
        function save(obj)
            fprintf('Saving values...');
            % Stack all the timeseries into the label
            obj.bagdata.label.clearTimeseries();

            for ts=obj.time_regions(obj.time_regions.hasLabel())
                if ~obj.bagdata.label.addTimeseriesLabel(char(ts.label), ts.time)
                    fprintf('Failed to add timeseries object: %s [%0.2f %0.2f]\n', ts.label, ts.time(1), ts.time(2));
                end
            end
            
            obj.bagdata.label.setComments(obj.commentsbox.String);
            
            obj.bagdata.savelabel();
            fprintf('done.\n');
        end
        
    end
    
    methods (Access = private)
        
        function updateImage(obj, time)
            if ~isempty(time) && ~isempty(obj.bagdata.image)
                image_times = obj.bagdata.image.time - time;
                [~, image_index] = max(image_times(image_times <= 0));
                if isempty(image_index)
                    image_index = 1;
                end
                data = obj.bagdata.image.data{image_index};
                set(obj.bagdata.dispdata.image.image, 'CData', data);
            end
        end
        
        function cancelCreating(obj)
            delete(obj.time_regions(obj.active_index));
            obj.time_regions(obj.active_index) = [];
            obj.active_index = -1;
            obj.state = 'normal';
            
            % Reset the pointer position
            obj.moveCallback(obj.bagdata.dispdata.figure, []);
        end
        
        function selectRegion(obj, index, axindex)
            
            % We selected a region
            obj.active_index = index;
            obj.time_regions(index).select(obj.bagdata.dispdata.plots.axes(axindex));
            obj.state = 'selected';
            obj.tslist.Value = index;
            
            % Clear the lines
            delete(obj.lines)
            obj.lines = [];
        end
        
        function cancelSelected(obj)
            obj.time_regions(obj.active_index).unselect();
            obj.active_index = -1;
            obj.state = 'normal';
            
            % Reset the pointer position
            obj.moveCallback(obj.bagdata.dispdata.figure, []);
        end
        
        function deleteTimeseries(obj, index)
            delete(obj.time_regions(index));
            obj.time_regions(index) = [];
            obj.tslist.String(index) = [];
            obj.tslist.Value = [];
            obj.active_index = -1;
            obj.state = 'normal';
            
            % Reset the pointer position
            obj.moveCallback(obj.bagdata.dispdata.figure, []);
        end
        
        function ts = getTimeSpans(obj)
            idx = 1:length(obj.time_regions);
            if obj.active_index > 0 && strcmp(obj.state, 'creating')
                idx(obj.active_index) = [];
            end
            ts = cell2mat({obj.time_regions(idx).time}');
            if isempty(ts)
                ts = [-1 -1];
            end
        end
        
        function [found, span, index] = isInTimeSpan(obj, time)
            ts = obj.getTimeSpans();
            in_spans = (ts(:,1) <= time & ts(:,2) >= time);
            if any(in_spans)
                found = true;
                span = ts(in_spans, :);
                index = find(in_spans);
            else
                found = false;
                span = [];
                index = -1;
            end
        end
         
        function index = addTimeRegion(obj, time)
            index = obj.insertTimeRegion(...
                TimeRegion(obj.bagdata.dispdata.plots.axes, ...
                time, obj.bagdata.label.context.timeseries.labels));
        end
        
        function index = insertTimeRegion(obj, region)
            if isempty(obj.time_regions)
                obj.time_regions = region;
                index = 1;
            else
                ts = obj.getTimeSpans();
                [~, idx] = sort([region.time(1); ts(:,1)]);
                index = find(idx == 1);
                obj.time_regions = [obj.time_regions(1:index-1) region obj.time_regions(index:end)];
            end
        end
    end
        
        
end
