% turning_circle_plotter.m
clear all;
close all;

% Read the bag file
bag = rosbag('turning_circle_data_2.bag');

% Extract messages
odomMsgs = select(bag, 'Topic', '/wamv/odom');
imuMsgs = select(bag, 'Topic', '/wamv/imu');
ekfMsgs = select(bag, 'Topic', '/robot_pose_ekf/odom_combined');

% Convert to timeseries
odomData = readMessages(odomMsgs);
imuData = readMessages(imuMsgs);
ekfData = readMessages(ekfMsgs);

% Get scenario parameters
boat_length = 4.06;
scenario = 'two_times';  % Change this manually if needed
turn_direction = 'starboard';   % Change this manually if needed

if strcmp(scenario, 'three_times')
    straight_line_length = boat_length * 3;
    tactical_diameter = boat_length * 3;
else
    straight_line_length = boat_length * 2;
    tactical_diameter = boat_length * 2;
end
turn_radius = tactical_diameter / 2;

% Initialize arrays for trajectory
x_actual = [];
y_actual = [];
t_traj = [];

% Process trajectory data from EKF
for i = 1:length(ekfData)
    curr_time = ekfData{i}.Header.Stamp.Sec + ekfData{i}.Header.Stamp.Nsec*1e-9;
    if i == 1
        startTime = curr_time;
    end
    t_traj(i) = curr_time - startTime;
    
    x_actual(i) = ekfData{i}.Pose.Pose.Position.X;
    y_actual(i) = ekfData{i}.Pose.Pose.Position.Y;
end

% Generate ideal path
% Straight line segment
num_straight_points = 50;
x_ideal_straight = linspace(0, straight_line_length, num_straight_points);
y_ideal_straight = zeros(1, num_straight_points);

% Circle segment
num_circle_points = 100;
center_x = straight_line_length;
if strcmp(turn_direction, 'port')
    center_y = turn_radius;
    angles = linspace(-pi/2, 3*pi/2, num_circle_points);
else
    center_y = -turn_radius;
    angles = linspace(pi/2, -3*pi/2, num_circle_points);
end

x_ideal_circle = center_x + turn_radius * cos(angles);
y_ideal_circle = center_y + turn_radius * sin(angles);

% Combine ideal path segments
x_ideal = [x_ideal_straight, x_ideal_circle];
y_ideal = [y_ideal_straight, y_ideal_circle];

% Rotate ideal path 180 degrees
rotation_angle = pi; % 180 degrees in radians
rotation_matrix = [cos(rotation_angle) -sin(rotation_angle);
                  sin(rotation_angle)  cos(rotation_angle)];
                  
% Apply rotation to ideal path
rotated_points = rotation_matrix * [x_ideal; y_ideal];
x_ideal = rotated_points(1, :);
y_ideal = rotated_points(2, :);

% Process velocity and acceleration data
t = [];
vx = []; vy = []; v_mag = [];
ax = []; ay = []; a_mag = [];

% Process velocity data
for i = 1:length(odomData)
    curr_time = odomData{i}.Header.Stamp.Sec + odomData{i}.Header.Stamp.Nsec*1e-9;
    t(i) = curr_time - startTime;
    
    vx(i) = odomData{i}.Twist.Twist.Linear.X;
    vy(i) = odomData{i}.Twist.Twist.Linear.Y;
    v_mag(i) = sqrt(vx(i)^2 + vy(i)^2);
end

% Process acceleration data
t_imu = [];
for i = 1:length(imuData)
    curr_time = imuData{i}.Header.Stamp.Sec + imuData{i}.Header.Stamp.Nsec*1e-9;
    t_imu(i) = curr_time - startTime;
    
    % Get orientation
    quat = [imuData{i}.Orientation.X, imuData{i}.Orientation.Y, ...
            imuData{i}.Orientation.Z, imuData{i}.Orientation.W];
    [roll, pitch, yaw] = quat2angle(quat);
    
    % Remove gravity and transform accelerations
    g = 9.81;
    ax_raw = imuData{i}.LinearAcceleration.X;
    ay_raw = imuData{i}.LinearAcceleration.Y;
    
    ax(i) = ax_raw + g * sin(pitch);
    ay(i) = ay_raw - g * sin(roll) * cos(pitch);
    a_mag(i) = sqrt(ax(i)^2 + ay(i)^2);
end

% Apply filtering to acceleration
windowSize = 10;
ax = movmean(ax, windowSize);
ay = movmean(ay, windowSize);
a_mag = movmean(a_mag, windowSize);

% Create figures
% Figure 1: Trajectory and Path Error
figure('Position', [100 100 1200 400]);

% Plot trajectory
subplot(1,2,1);
plot(x_actual, y_actual, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Actual Path');
hold on;
plot(x_ideal, y_ideal, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Ideal Path');
grid on;
xlabel('X (m)');
ylabel('Y (m)');
title('Trajectory Comparison');
legend('Location', 'best');
axis equal;
xlim([-20 20]);
ylim([-20 20]);

% Plot path error
subplot(1,2,2);
% Calculate error (minimum distance to ideal path)
error = zeros(size(x_actual));
for i = 1:length(x_actual)
    distances = sqrt((x_actual(i) - x_ideal).^2 + (y_actual(i) - y_ideal).^2);
    error(i) = min(distances);
end

plot(t_traj, error, 'r-', 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('Error (m)');
title('Path Error');
set(gcf, 'Color', 'white');
sgtitle('WAM-V Trajectory During Turning Circle Maneuver');

% Figure 2: Dynamics
figure('Position', [100 550 1200 400]);

% Plot velocity
subplot(1,2,1);
plot(t, vx, 'b-', 'LineWidth', 1.5, 'DisplayName', 'X');
hold on;
plot(t, vy, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Y');
plot(t, v_mag, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Magnitude');
grid on;
xlabel('Time (s)');
ylabel('Velocity (m/s)');
title('Translational Velocity');
legend('Location', 'best');
ylim([-2 2]);
xlim([-1 max(t)+1]);

% Plot acceleration
subplot(1,2,2);
plot(t_imu, ax, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Surge (X)');
hold on;
plot(t_imu, ay, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Sway (Y)');
plot(t_imu, a_mag, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Total');
grid on;
xlabel('Time (s)');
ylabel('Acceleration (m/s²)');
title('Translational Acceleration');
legend('Location', 'best');
ylim([-2 2]);
xlim([-1 max(t_imu)+1]);

set(gcf, 'Color', 'white');
sgtitle('WAM-V Dynamics During Turning Circle Maneuver');

% Save plots
saveas(1, 'turning_circle_trajectory.png');
saveas(1, 'turning_circle_trajectory.fig');
saveas(2, 'turning_circle_dynamics.png');
saveas(2, 'turning_circle_dynamics.fig');