#!/usr/bin/env python3
import rospy
import matplotlib.pyplot as plt
from std_msgs.msg import Float64MultiArray
import numpy as np

class MotionPlotter:
    def __init__(self):
        rospy.init_node('motion_plotter')
        
        # Data storage
        self.time_data = []
        self.linear_vel = []
        self.angular_vel = []
        self.linear_acc = []
        self.angular_acc = []
        self.start_time = rospy.Time.now().to_sec()
        
        # Create figures
        plt.ion()
        self.fig, (self.ax1, self.ax2) = plt.subplots(2, 1, figsize=(10, 8))
        
        # Initialize plots
        self.setup_plots()
        
        # Subscribe to data
        self.data_sub = rospy.Subscriber('/boat_data', Float64MultiArray, self.data_callback)
        
    def setup_plots(self):
        self.ax1.set_title('Velocities')
        self.ax1.set_xlabel('Time (s)')
        self.ax1.set_ylabel('Velocity (m/s, rad/s)')
        self.ax1.grid(True)
        
        self.ax2.set_title('Accelerations')
        self.ax2.set_xlabel('Time (s)')
        self.ax2.set_ylabel('Acceleration (m/s², rad/s²)')
        self.ax2.grid(True)
    
    def data_callback(self, msg):
        current_time = rospy.Time.now().to_sec() - self.start_time
        
        self.time_data.append(current_time)
        self.linear_vel.append(msg.data[0])
        self.angular_vel.append(msg.data[1])
        self.linear_acc.append(msg.data[2])
        self.angular_acc.append(msg.data[3])
        
        # Keep last 1000 points
        if len(self.time_data) > 1000:
            self.time_data.pop(0)
            self.linear_vel.pop(0)
            self.angular_vel.pop(0)
            self.linear_acc.pop(0)
            self.angular_acc.pop(0)
        
        self.update_plots()
    
    def update_plots(self):
        # Clear previous plots
        self.ax1.clear()
        self.ax2.clear()
        
        # Plot velocities
        self.ax1.plot(self.time_data, self.linear_vel, 'b-', label='Linear')
        self.ax1.plot(self.time_data, self.angular_vel, 'r-', label='Angular')
        self.ax1.legend()
        self.ax1.grid(True)
        self.ax1.set_title('Velocities')
        
        # Plot accelerations
        self.ax2.plot(self.time_data, self.linear_acc, 'b-', label='Linear')
        self.ax2.plot(self.time_data, self.angular_acc, 'r-', label='Angular')
        self.ax2.legend()
        self.ax2.grid(True)
        self.ax2.set_title('Accelerations')
        
        plt.pause(0.01)
    
    def run(self):
        rospy.spin()

if __name__ == '__main__':
    try:
        plotter = MotionPlotter()
        plotter.run()
    except rospy.ROSInterruptException:
        pass
