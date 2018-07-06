function bagdataExtraction(bagdir, bagpath, savedir)

fprintf(strcat('loading from: ',bagdir,'./',bagpath, '\n'));
bag = rosbag(strcat(bagdir, '/',bagpath));

bagname = bagpath(1:end-4);

%extract force torque data
%fprintf('loading ft data...');
wrench_msgs = select(bag,'Topic','netft');
wrench = timeseries(wrench_msgs, 'Wrench.Force.X', 'Wrench.Force.Y', 'Wrench.Force.Z', 'Wrench.Torque.X', 'Wrench.Torque.Y', 'Wrench.Torque.Z'); 
wrench.Time = wrench.Time - bag.StartTime;

% extract motor data
%fprintf('loading motor data...');
motor_msgs = select(bag,'Topic','feedback');
motor = timeseries(motor_msgs, 'Feedback.Position', 'Feedback.Velocity', 'Feedback.Current','Feedback.Potentiometer');
motor.Time = motor.Time - bag.StartTime;

%extract foxbot trajectory
foxbot_msgs = select(bag,'Topic','foxbot');
foxbot = timeseries(foxbot_msgs, 'Pose.Position.X', 'Pose.Position.Y', 'Pose.Position.Z', 'Pose.Orientation.X', 'Pose.Orientation.Y', 'Pose.Orientation.Z', 'Pose.Orientation.W'); 
foxbot.Time = foxbot.Time - bag.StartTime;

%extrac images
%fprintf('loading images...');
images_msgs =  select(bag,'Topic','hs_image');
images = readMessages(images_msgs);
image_width = images{1}.Width;
image_height = images{1}.Height;

%extract inserted error
error_msgs =  readMessages(select(bag,'Topic','error'));
error = error_msgs{1}.Data;

%extract hole location
hole_location_msgs = readMessages(select(bag,'Topic','hole_location'));
hole_location = [hole_location_msgs{1}.Location.Point.X, hole_location_msgs{1}.Location.Point.Y, hole_location_msgs{1}.Location.Point.Z];

%write video
%fprintf('saving video...');
video_writer = VideoWriter(strcat(savedir,'/',bagname,'.avi'));%, 'Grayscale AVI');
video_writer.FrameRate = 25;

open(video_writer);
for i = 1:numel(images)
    cur_frame = reshape(images{i}.Data,[image_width image_height]);
    cur_frame = imrotate(cur_frame,90);
    cur_frame = demosaic(cur_frame,'rggb');
    %cur_frame = rgb2gray(demosaic(cur_frame,'rggb'));
    writeVideo(video_writer, cur_frame);
end
close(video_writer);

% write ft.csv
%fprintf('writing ft data...');
ft_filename = strcat(savedir,'/',bagname,'_ft','.csv');
ft_headers = {'time', 'fx', 'fy', 'fz', 'tx', 'ty', 'tz'};
fid = fopen(ft_filename, 'w');
fprintf(fid, '%s\n', strjoin(ft_headers, ','));
fclose(fid);
dlmwrite(ft_filename,[wrench.Time, wrench.Data], '-append');

%write motor.csv
%fprintf('writing motor data...');
motor_filename = strcat(savedir,'/',bagname,'_screwdriver','.csv');
motor_headers = {'time', 'position', 'velocity', 'current', 'potentiometer'};
fid = fopen(motor_filename , 'w');
fprintf(fid, '%s\n', strjoin(motor_headers, ','));
fclose(fid);
dlmwrite(motor_filename, [motor.Time, motor.Data], '-append');

%write foxbot.csv
foxbot_filename = strcat(savedir,'/',bagname,'_foxbot','.csv');
foxbot_headers = {'time', 'x', 'y', 'z', 'qx', 'qy', 'qz', 'qw'};
fid = fopen(foxbot_filename , 'w');
fprintf(fid, '%s\n', strjoin(foxbot_headers, ','));
fclose(fid);
dlmwrite(foxbot_filename, [foxbot.Time, foxbot.Data], '-append');

%write label file
%fprintf('writing decription file...');
label_filename = strcat(savedir,'/',bagname, '_info','.json');
descriptions = struct('StartTime', bag.StartTime - bag.StartTime,'EndTime',bag.EndTime - bag.StartTime, ...
 'videoStartTime',images_msgs.StartTime - bag.StartTime, 'videoEndTime', images_msgs.EndTime - bag.StartTime,...
 'hole_location', hole_location,'position_error', error(1:2), 'angular_error', error(3:4));

savejson('', descriptions, label_filename);
     
end

