clone the file to catkin workspace ;

clone pid controller and robot pose efk and asv_wave_sim for gazebo 11 supported to src folder

sudo apt-get install ros-neotic-pid
https://github.com/srmainwaring/asv_wave_sim.git

place ocean_top_view.world into src/asv_wave_sim/asv_wave_sim_gazebo/worlds folder
and place ocean_world_top.launch into src/asv_wave_sim/asv_wave_sim_gazebo/launch folder.

cd ~/catkin_ws

catkin_make_isolated --install

source install_isolated/setup.bash

to launch three times scenario;

roslaunch sailboat_sim turning_circle.launch scenario:=three_times turn_direction:=starboard

to launch two times scenario;

roslaunch sailboat_sim turning_circle.launch scenario:=two_times turn_direction:=starboard
