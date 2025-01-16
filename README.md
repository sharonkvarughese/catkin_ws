clone the file to catkin workspace 

cd ~/catkin_ws

catkin_make_isolated --install

source install_isolated/setup.bash

to launch three times scenario

roslaunch sailboat_sim turning_circle.launch scenario:=three_times turn_direction:=starboard

to launch two times scenario

roslaunch sailboat_sim turning_circle.launch scenario:=two_times turn_direction:=starboard
