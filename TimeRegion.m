classdef TimeRegion < handle
    properties
        state
        time
        allaxes;
        
        
        patches
        patch_listeners
        label_text
        popup
        
        all_labels
    end
    
    properties (SetObservable)
        label
    end
    
    properties (Constant)
        states = {'creating', 'unlabeled', 'normal', 'selected'};
        colors = struct('creating', [0.4 0.4 0.4], 'unlabeled', 'r', 'normal', 'g', 'selected', 'b');
        alpha = 0.2;
    end
    
    methods
        function obj = TimeRegion(allaxes, time, all_labels)
            obj.state = 'creating';
            obj.time = time;
            obj.label = [];
            obj.allaxes = allaxes;
            obj.label_text = [];
            obj.all_labels = all_labels;
            obj.popup = [];
            obj.patch_listeners = event.proplistener.empty;
            
            obj.patches = matlab.graphics.primitive.Patch.empty;
            for ax=allaxes
                yvals = get(ax, 'YLim');
                p = patch([time(1) time(1) time(2) time(2)], [yvals(1) yvals(2) yvals(2) yvals(1)], TimeRegion.colors.(obj.state), 'Parent', ax);
                p.FaceAlpha = TimeRegion.alpha;
                obj.patches(end+1) = p;
                obj.patch_listeners(end+1) = addlistener(ax, 'YLim', 'PostSet', @(s,d) obj.updatePatchYVals(s,d,p));
            end
        end
        
        function create(obj)
            obj.state = 'unlabeled';
            
            set(obj.patches, 'FaceColor', TimeRegion.colors.(obj.state));
        end
        
        function s = toString(obj)
            if numel(obj) == 1
                if ~isempty(obj.label)
                    s = sprintf('%s: [%0.2f %0.2f]', obj.label, obj.time(1), obj.time(2));
                else
                    s = sprintf('<unlabeled>: [%0.2f %0.2f]', obj.time);
                end
            else
                s = arrayfun(@(t) t.toString(), obj, 'UniformOutput', false);
            end
        end
        
        function updatePatchYVals(obj, src, data, patch)
            yvals = get(data.AffectedObject, 'YLim');
            patch.Vertices(:,2) = [yvals(1) yvals(2) yvals(2) yvals(1)]';
        end
        
        function ok = hasLabel(obj)
            ok = cellfun(@(x) ~isempty(x), {obj.label} );
        end
        
        function setLabel(obj, label, set_state)
            if nargin < 3
                set_state = false;
            end
            if ~isempty(label)
                obj.label = label;
                
                if isempty(obj.label_text)
                    for ax=obj.allaxes
                        yvals = get(ax, 'YLim');
                        obj.label_text(end+1) = text(mean(obj.time), dot([0.3 0.7], yvals), 1, ...
                            obj.label, 'Parent', ax, 'HorizontalAlignment', 'center', ...
                            'FontSize', 12, 'BackgroundColor', 'none', 'Interpreter', 'none', ...
                            'Rotation', 90);
                    end
                else
                    set(obj.label_text, 'String', obj.label);
                end
                
                if set_state
                    obj.state = 'normal';
                    obj.updatePatchColors();
                end
            else
                obj.label = [];
                
                if ~isempty(obj.label_text)
                    delete(obj.label_text);
                    obj.label_text = [];
                end
                
                if set_state
                    obj.state = 'unlabeled';
                    obj.updatePatchColors();
                end
            end
        end
        
        function setTime(obj, time)
            for p=obj.patches
                p.Vertices(:,1) = [time(1) time(1) time(2) time(2)]';
            end
            obj.time = time;
        end
        
        function select(obj, active_axes)
            obj.state = 'selected';
            obj.updatePatchColors();
            
            % Draw a dropdown
            fig = get(active_axes, 'Parent');
            obj.popup = uicontrol(fig, 'Style', 'popup', ...
                'String', obj.all_labels, ...
                'Callback', @obj.popupCallback, ...
                'Units', 'normalized');
            
            axbounds = get(active_axes, 'Position');
            xlim = get(active_axes, 'XLim');
            center_x = axbounds(1) + axbounds(3)*(mean(obj.time) - xlim(1))/(xlim(2) - xlim(1));
            center_y = axbounds(2) + axbounds(4)/2;
            
            set(obj.popup, 'Position', [center_x - obj.popup.Extent(3)/2, ...
                center_y - obj.popup.Extent(4)/2, ...
                obj.popup.Extent(3:4)]);
                
            for l=obj.label_text
                cp = get(l, 'Position');
                set(l, 'Position', [cp(1) cp(2) 2]);
            end
            
        end
        
        function popupCallback(obj, src, data)
            obj.setLabel(obj.all_labels{obj.popup.Value});
        end
        
        function unselect(obj)
            if isempty(obj.label)
                obj.state = 'unlabeled';
            else
                obj.state = 'normal';
            end
            if ~isempty(obj.popup)
                delete(obj.popup);
                obj.popup = [];
            end
            obj.updatePatchColors();
            for l=obj.label_text
                cp = get(l, 'Position');
                set(l, 'Position', [cp(1) cp(2) 1]);
            end
        end
        
        function setVisible(obj, b)
            if b
                vis = 'on';
            else
                vis = 'off';
            end
            for p=obj.patches
                set(p, 'Visible', vis);
            end
            for l = obj.label_text
                set(l, 'Visible', vis);
            end
            for pp = obj.popup
                set(pp, 'Visible', vis);
            end
        end
        
        function delete(obj)
            if ~isempty(obj.allaxes) && ~any(cellfun(@(x) strcmp(x, 'on'), get(obj.allaxes, 'BeingDeleted')))
                delete(obj.patches);
                delete(obj.label_text);
                delete(obj.popup);
                delete(obj.patch_listeners);
            end
        end
        
        function setColor(obj, color)
            for p=obj.patches
                p.FaceColor = color;
            end 
        end
    end
    
    methods (Static = true)
        
        function obj = load(allaxes, all_labels, data)
            obj = TimeRegion(allaxes, [0 0], all_labels);
            obj.setTime(data.time);
            obj.setLabel(data.label, true);
        end
        
    end
    
    methods (Access = private)
        function updatePatchColors(obj)
            for p=obj.patches
                p.FaceColor = TimeRegion.colors.(obj.state);
            end
        end
    end
    
end
