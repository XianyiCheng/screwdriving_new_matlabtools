classdef Dataset < matlab.mixin.Copyable
    
    properties
        directory
        files
        total
        cur_index
        cur_data
        context
    end
    
    methods
        function obj = Dataset(directory,context_path)
            obj.directory = directory;
            obj.context = loadjson(context_path);
            obj.files = dir(fullfile(directory,'*.avi'));
            obj.total = numel(obj.files);
            obj.cur_index = 1;

        end
        
        function rundata = load(obj,index)
            obj.cur_index = index;
            runname = obj.files(obj.cur_index).name(1:end-4);
            obj.cur_data = RunData(obj.directory,runname);
            obj.cur_data.label.context = obj.context;
            rundata = obj.cur_data;
        end
        
        function labeldata(obj, index)
            %{
            obj.cur_index = index;
            runname = obj.files(obj.cur_index).name(1:end-4);
            obj.cur_data = RunData(obj.directory,runname);
            obj.cur_data.label.context = obj.context;
            %}
            obj.load(index);
            obj.cur_data.plot();
            callbacks = CallbackContext(obj.cur_data);

            % Window callbacks
            set(gcf, 'WindowButtonMotionFcn', @callbacks.moveCallback);
            set(gcf, 'WindowButtonDownFcn', @callbacks.clickCallback);
            set(gcf, 'KeyPressFcn', @callbacks.keyCallback);

            % Data set navigation
            uicontrol(gcf, 'Units', 'normalized', 'Position', [0.4 0.03 0.1 0.05], ...
                'String', '< Skip', 'Callback', {@callbacks.skipCallback, @obj.labelprev});
            uicontrol(gcf, 'Units', 'normalized', 'Position', [0.3 0.03 0.1 0.05], ...
                'String', '< Prev', 'Callback', {@callbacks.nextCallback, @obj.labelprev});
            uicontrol(gcf, 'Units', 'normalized', 'Position', [0.5 0.03 0.1 0.05], ...
                'String', 'Skip >', 'Callback', {@callbacks.skipCallback, @obj.labelnext});
            uicontrol(gcf, 'Units', 'normalized', 'Position', [0.6 0.03 0.1 0.05], ...
                'String', 'Next >', 'Callback', {@callbacks.nextCallback, @obj.labelnext});
            
            % Make the bag data accessible from the workspace
            assignin('base', 'rundata', obj.cur_data);
        end
        
        function labelnext(obj)
            if obj.cur_index >= obj.total
                return
            end
            obj.labeldata(obj.cur_index +1);
        end
        
        function labelprev(obj)
            if obj.cur_index <=1
                return
            end
            obj.labeldata(obj.cur_index - 1);
        end
        
    end
end

