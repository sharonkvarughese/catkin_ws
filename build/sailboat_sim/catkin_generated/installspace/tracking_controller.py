#!/usr/bin/env python3

import rospy
import math
from geometry_msgs.msg import Twist, Point
from gazebo_msgs.msg import ModelStates
from nav_msgs.msg import Path
from visualization_msgs.msg import Marker, MarkerArray
from geometry_msgs.msg import PoseStamped

class SimpleTracker:
    def __init__(self):
        rospy.init_node('simple_tracker')
        
        # Parameters
        self.radius = rospy.get_param('~radius', 40.0)
        self.linear_speed = rospy.get_param('~linear_speed', 20.0)
        self.frame_id = rospy.get_param('~frame_id', 'map')
        
        # Publishers
        self.marker_pub = rospy.Publisher('/visualization_markers', MarkerArray, queue_size=1)
        self.path_pub = rospy.Publisher('/trajectory_path', Path, queue_size=1)
        
        # Initialize markers
        self.markers = MarkerArray()
        self.init_markers()
        
        # Path initialization
        self.path = Path()
        self.path.header.frame_id = self.frame_id
        
        self.rate = rospy.Rate(20)
        self.angle = 0.0
        
    def init_markers(self):
        # Create circle marker
        circle = Marker()
        circle.header.frame_id = self.frame_id
        circle.id = 0
        circle.type = Marker.LINE_STRIP
        circle.action = Marker.ADD
        circle.scale.x = 0.5
        circle.color.g = 1.0
        circle.color.a = 1.0
        
        # Generate circle points
        points = []
        for i in range(50):
            angle = 2 * math.pi * i / 49
            x = self.radius * math.cos(angle)
            y = self.radius * math.sin(angle)
            points.append(Point(x, y, 0))
        points.append(points[0])  # Close the circle
        circle.points = points
        
        self.markers.markers.append(circle)
        
    def run(self):
        while not rospy.is_shutdown():
            # Update markers header
            for marker in self.markers.markers:
                marker.header.stamp = rospy.Time.now()
            
            # Add current position to path
            pose = PoseStamped()
            pose.header.frame_id = self.frame_id
            pose.header.stamp = rospy.Time.now()
            pose.pose.position.x = self.radius * math.cos(self.angle)
            pose.pose.position.y = self.radius * math.sin(self.angle)
            self.path.poses.append(pose)
            
            # Keep path length reasonable
            if len(self.path.poses) > 100:
                self.path.poses.pop(0)
            
            # Publish
            self.marker_pub.publish(self.markers)
            self.path_pub.publish(self.path)
            
            # Update angle
            self.angle += 0.05
            if self.angle > 2 * math.pi:
                self.angle -= 2 * math.pi
            
            self.rate.sleep()

if __name__ == '__main__':
    try:
        tracker = SimpleTracker()
        tracker.run()
    except rospy.ROSInterruptException:
        pass
