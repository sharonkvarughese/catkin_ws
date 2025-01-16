#!/usr/bin/env python3
import rospy
import math
import numpy as np
from geometry_msgs.msg import Twist, PoseStamped, Point
from gazebo_msgs.msg import ModelStates
from std_msgs.msg import Float64, Bool
from nav_msgs.msg import Path
from tf.transformations import euler_from_quaternion

class TurningCircleController:
    def __init__(self):
        rospy.init_node('turning_circle_controller')
        
        # Fixed parameters
        self.boat_length = 4.06
        self.scenario = rospy.get_param('~scenario', 'three_times')
        self.turn_direction = rospy.get_param('~turn_direction', 'port')
        
        # IMO Rudder Standards
        self.max_rudder_angle = 35  # Maximum angle
        self.initial_turn_angle = 15  # Initial turning
        self.steady_turn_angle = 25  # Steady turning
        self.max_rudder_rate = 2.32  # degrees/second
        
        # Convert to radians
        self.max_rudder_rad = math.radians(self.max_rudder_angle)
        self.initial_turn_rad = math.radians(self.initial_turn_angle)
        self.steady_turn_rad = math.radians(self.steady_turn_angle)
        self.max_rate_rad = math.radians(self.max_rudder_rate)
        
        # Scenario specific parameters
        if self.scenario == 'three_times':
            self.straight_line_length = self.boat_length * 3
            self.tactical_diameter = self.boat_length * 3
        else:
            self.straight_line_length = self.boat_length * 2
            self.tactical_diameter = self.boat_length * 2

        # Calculate turn radius
        self.turn_radius = self.tactical_diameter / 2
        
        # Control parameters
        self.cruise_speed = 3.0
        base_turn_rate = (self.cruise_speed / self.turn_radius)
        self.turn_rate = base_turn_rate if self.turn_direction == 'port' else -base_turn_rate
        
        # State variables
        self.phase = 'STRAIGHT'
        self.distance_traveled = 0.0
        self.turn_angle = 0.0
        self.start_pos = None
        self.turn_start_pos = None
        self.last_heading = None
        self.total_angle_turned = 0.0
        self.current_diameter = 0.0
        
        # Initialize PID states
        self.heading_control = 0.0
        self.speed_control = 0.0

        # Publishers
        self.cmd_vel_pub = rospy.Publisher('/cmd_vel', Twist, queue_size=1)
        self.model_states_sub = rospy.Subscriber('/gazebo/model_states', ModelStates, self.model_states_callback)
        
        # Set up control rate
        self.rate = rospy.Rate(10)
        
        rospy.loginfo(f"Initialized for {self.scenario} scenario with {self.turn_direction} turn")
        rospy.loginfo(f"Target Tactical Diameter: {self.tactical_diameter}m")
        rospy.loginfo(f"Turn Radius: {self.turn_radius}m")
        rospy.loginfo(f"Turn Rate: {math.degrees(abs(self.turn_rate))} deg/s")

    def normalize_angle(self, angle):
        """Normalize angle to [-pi, pi]"""
        while angle > math.pi:
            angle -= 2 * math.pi
        while angle < -math.pi:
            angle += 2 * math.pi
        return angle

    def get_yaw(self, orientation):
        """Extract yaw from quaternion"""
        quaternion = [orientation.x, orientation.y, orientation.z, orientation.w]
        roll, pitch, yaw = euler_from_quaternion(quaternion)
        return yaw

    def update_turn_angle(self, current_heading):
        if self.last_heading is not None:
            # Calculate heading difference
            diff = self.normalize_angle(current_heading - self.last_heading)
            self.total_angle_turned += diff
            
        self.last_heading = current_heading

    def update_measurements(self, current_pos):
        """Update measurements during turning phase"""
        if self.turn_start_pos is not None:
            # Calculate distance from turn start position
            dx = current_pos.x - self.turn_start_pos.x
            dy = current_pos.y - self.turn_start_pos.y
            self.current_diameter = 2 * math.sqrt(dx*dx + dy*dy)
            
            # Log measurements at specific angles
            angle_deg = math.degrees(abs(self.total_angle_turned))
            
            if 89 <= angle_deg <= 91 and not hasattr(self, 'logged_90'):
                rospy.loginfo(f"=== 90° Turn Measurements ===")
                rospy.loginfo(f"Advance: {abs(dx):.2f}m")
                rospy.loginfo(f"Transfer: {abs(dy):.2f}m")
                self.logged_90 = True
                
            if 179 <= angle_deg <= 181 and not hasattr(self, 'logged_180'):
                rospy.loginfo(f"=== 180° Turn Measurements ===")
                rospy.loginfo(f"Tactical Diameter: {self.current_diameter:.2f}m")
                self.logged_180 = True
                
            if 359 <= angle_deg <= 361 and not hasattr(self, 'logged_360'):
                rospy.loginfo(f"=== 360° Turn Measurements ===")
                rospy.loginfo(f"Final Diameter: {self.current_diameter:.2f}m")
                rospy.loginfo(f"Total Angle: {angle_deg:.1f}°")
                self.logged_360 = True

    def model_states_callback(self, msg):
        try:
            idx = msg.name.index('wamv')
            pose = msg.pose[idx]
            twist = msg.twist[idx]
            
            current_pos = pose.position
            current_heading = self.get_yaw(pose.orientation)
            
            # Initialize start position
            if self.start_pos is None:
                self.start_pos = current_pos
                self.last_heading = current_heading
            
            # Update distances and angles
            if self.phase == 'STRAIGHT':
                self.distance_traveled = abs(current_pos.x - self.start_pos.x)
                
            elif self.phase == 'TURN':
                if self.turn_start_pos is None:
                    self.turn_start_pos = current_pos
                    self.total_angle_turned = 0.0
                    rospy.loginfo(f"Starting {self.turn_direction} turn at x={current_pos.x}, y={current_pos.y}")
                    
                self.update_turn_angle(current_heading)
                self.update_measurements(current_pos)
            
            # Check phase transitions
            self.update_phase(current_pos, current_heading)
            
        except ValueError:
            rospy.logwarn_throttle(5, "WAM-V not found in model states")

    def update_phase(self, current_pos, current_heading):
        if self.phase == 'STRAIGHT' and self.distance_traveled >= self.straight_line_length:
            self.phase = 'TURN'
            self.turn_start_pos = current_pos
            rospy.loginfo(f"=== Starting {self.turn_direction.capitalize()} Turn ===")
            rospy.loginfo(f"Turn Start Position: x={current_pos.x:.2f}, y={current_pos.y:.2f}")

    def run(self):
        while not rospy.is_shutdown():
            cmd = Twist()
            
            if self.phase == 'STRAIGHT':
                cmd.linear.x = self.cruise_speed
                cmd.angular.z = 0.0
                
            elif self.phase == 'TURN':
                cmd.linear.x = self.cruise_speed
                cmd.angular.z = self.turn_rate
            
            self.cmd_vel_pub.publish(cmd)
            self.rate.sleep()

if __name__ == '__main__':
    try:
        controller = TurningCircleController()
        controller.run()
    except rospy.ROSInterruptException:
        pass
