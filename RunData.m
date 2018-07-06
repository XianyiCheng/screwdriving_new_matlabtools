classdef RunData  < matlab.mixin.Copyable
    
    properties
        image
        screwdriver
        wrench
        start_time
        duration
        position_error
        angular_error
        
        bagdir %directory of the bagdata, without extra '/'
        bagname % delete '.bag' string
        label
        dispdata
        prediction
        
    end
    
    methods
        function obj = RunData(dir,name)
            
            obj.wrench = struct('time', [], 'force', [], 'torque', []);
            obj.screwdriver = struct('time', [], 'position', [], 'current', [], 'velocity', [], 'potentiometer', []);
            obj.start_time = [];
            obj.duration = [];
            obj.position_error = [];
            obj.angular_error = [];
            obj.image = struct('time', [], 'data', {{}});
            obj.bagdir = dir;
            obj.bagname = name;
            obj = obj.loadData();
        end
        
        function obj = loadData(obj)
            wrench_data = csvread(strcat(obj.bagdir,'/',obj.bagname,'_ft.csv'),1,0);
            obj.wrench.time = wrench_data(:,1);
            obj.wrench.force = wrench_data(:,2:4);
            obj.wrench.torque = wrench_data(:,5:7);
            screwdriver_data = csvread(strcat(obj.bagdir,'/',obj.bagname,'_screwdriver.csv'),1,0);
            obj.screwdriver = struct('time', screwdriver_data(:,1), 'position', screwdriver_data(:,2),...
            'current', screwdriver_data(:,3), 'velocity', screwdriver_data(:,4), 'potentiometer', screwdriver_data(:,5));
            video = VideoReader(strcat(obj.bagdir, '/', obj.bagname, '.avi'));
            frame_ind = 1;
            while hasFrame(video)
                image_data{frame_ind} = readFrame(video);
                frame_ind = frame_ind+1;
            end
            labels = loadjson(strcat(obj.bagdir, '/', obj.bagname, '_info.json'));
            obj.start_time = labels.StartTime;
            obj.duration = labels.EndTime - labels.StartTime;
            obj.position_error = labels.position_error;
            obj.angular_error = labels.angular_error;
            
            obj.image.time = [labels.videoStartTime:1/video.FrameRate:labels.videoEndTime]';
            obj.image.data = image_data';
            
            label_file = strcat(obj.bagdir,'/', obj.bagname, '_label.json');
            if exist(label_file, 'file')
                obj.label = BagLabel([], label_file);
            else
                obj.label = BagLabel([]);
            end
            
        end
        
        function plot(obj)
            line_width = 2;
            obj.dispdata.figure = figure('Name', obj.bagname, 'NumberTitle', 'off', ...
                'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            
            obj.dispdata.image.axes = subplot(3,3,1);
            if ~isempty(obj.image)    
                obj.dispdata.image.image = imshow(obj.image.data{36}, 'Border','tight');
            end
            discrip = {strcat(replace(obj.bagdir(end-5:end),'_','\_'),'/', replace(obj.bagname,'_','\_'));...
                strcat('position error: ', string(obj.position_error(1)),', ', string(obj.position_error(2)));...
                strcat('angular error: ', string(obj.angular_error(1)),', ',string(obj.angular_error(2)))};
            %obj.dispdata.text = text(0,-50,discrip);
            
            obj.dispdata.plots.axes = [];
            xlabel(discrip);
            obj.dispdata.plots.axes(1) = subplot(3,3,2);
            plot(obj.screwdriver.time, obj.screwdriver.current, 'LineWidth', line_width);
            %hold on
            %plot(obj.wrench.time, obj.wrench.torque(3,:), 'LineWidth', BagData.line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Current (A)');
            
            obj.dispdata.plots.axes(2) = subplot(3,3,3);
            plot(obj.screwdriver.time, obj.screwdriver.velocity, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Velocity (rpm)');
            
            obj.dispdata.plots.axes(3) = subplot(3,3,4);
            plot(obj.screwdriver.time, obj.screwdriver.potentiometer, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            ylim([0 1]);
            xlabel('Time (s)');
            ylabel('Potentiometer');
            
            obj.dispdata.plots.axes(4) = subplot(3,3,5);
            p1 = plot(obj.wrench.time, obj.wrench.torque, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Torque(Nm)');
            legend(p1,{'X','Y','Z'});
            
            obj.dispdata.plots.axes(5) = subplot(3,3,6);
            p2 = plot(obj.wrench.time, obj.wrench.force, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Force (N)');
            legend(p2, {'X','Y','Z'});
            
            linkaxes(obj.dispdata.plots.axes, 'x');
            
        end
        
        function view(obj)
            line_width = 2;
            obj.dispdata.figure = figure('Name', obj.bagname, 'NumberTitle', 'off', ...
                'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            
            if ~isempty(obj.image)
                obj.dispdata.image.axes = subplot(3,3,1);
                obj.dispdata.image.image = imshow(obj.image.data{1});
            end
            
            obj.dispdata.plots.axes = [];
            
            obj.dispdata.plots.axes(1) = subplot(3,3,2);
            plot(obj.screwdriver.time, obj.screwdriver.current, 'LineWidth', line_width);
            %hold on
            %plot(obj.wrench.time, obj.wrench.torque(3,:), 'LineWidth', BagData.line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Current (A)');
            
            obj.dispdata.plots.axes(2) = subplot(3,3,3);
            plot(obj.screwdriver.time, obj.screwdriver.velocity, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Velocity (rpm)');
            
            obj.dispdata.plots.axes(3) = subplot(3,3,4);
            plot(obj.screwdriver.time, obj.screwdriver.potentiometer, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            ylim([0 1]);
            xlabel('Time (s)');
            ylabel('Potentiometer');
            
            obj.dispdata.plots.axes(4) = subplot(3,3,5);
            p1 = plot(obj.wrench.time, obj.wrench.torque, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Torque(Nm)');
            legend(p1,{'X','Y','Z'});
            
            obj.dispdata.plots.axes(5) = subplot(3,3,6);
            p2 = plot(obj.wrench.time, obj.wrench.force, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Force (N)');
            legend(p2, {'X','Y','Z'});
            
            linkaxes(obj.dispdata.plots.axes, 'x');
            
            context = CallbackContext(obj);
            set(gcf, 'WindowButtonMotionFcn', @context.moveCallback);     
        end
        
        function savelabel(obj)
            obj.label.save(strcat(obj.bagdir,'/',obj.bagname,'_label.json'));
        end
        
       function savefig(obj,directory)
            line_width = 1.5;
            obj.dispdata.figure = figure('Name', obj.bagname, 'NumberTitle', 'off', ...
                'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            
            obj.dispdata.image.axes = subplot(2,3,1);
            if ~isempty(obj.image)    
                obj.dispdata.image.image = imshow(obj.image.data{30}, 'Border','tight');
            end
            discrip = {strcat(replace(obj.bagdir(end-5:end),'_','\_'),'/', replace(obj.bagname,'_','\_'));...
                strcat('position error: ', string(obj.position_error(1)),', ', string(obj.position_error(2)));...
                strcat('angular error: ', string(obj.angular_error(1)),', ',string(obj.angular_error(2)))};
            %obj.dispdata.text = text(0,-50,discrip);
            
            obj.dispdata.plots.axes = [];
            xlabel(discrip, 'FontSize',14);
            obj.dispdata.plots.axes(1) = subplot(2,3,2);
            plot(obj.screwdriver.time, obj.screwdriver.current, 'LineWidth', line_width);
            %hold on
            %plot(obj.wrench.time, obj.wrench.torque(3,:), 'LineWidth', BagData.line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Current (A)');
            
            obj.dispdata.plots.axes(2) = subplot(2,3,3);
            plot(obj.screwdriver.time, obj.screwdriver.velocity, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Velocity (rpm)');
            
            obj.dispdata.plots.axes(3) = subplot(2,3,4);
            plot(obj.screwdriver.time, obj.screwdriver.potentiometer, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            ylim([0 1]);
            xlabel('Time (s)');
            ylabel('Potentiometer');
            
            obj.dispdata.plots.axes(4) = subplot(2,3,5);
            p1 = plot(obj.wrench.time, obj.wrench.torque, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Torque(Nm)');
            %legend(p1,{'X','Y','Z'});
            
            obj.dispdata.plots.axes(5) = subplot(2,3,6);
            p2 = plot(obj.wrench.time, obj.wrench.force, 'LineWidth', line_width);
            xlim([0 obj.duration]);
            xlabel('Time (s)');
            ylabel('Force (N)');
            %legend(p2, {'X','Y','Z'});
            
            linkaxes(obj.dispdata.plots.axes, 'x');
            saveas(obj.dispdata.figure, strcat(directory,'/',obj.bagname,'.jpg'))
            close;
        end

    end
end

