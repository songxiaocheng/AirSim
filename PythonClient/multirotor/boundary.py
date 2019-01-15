# Python client example to get Lidar data from a drone
#

import setup_path 
import airsim
from airsim.types import *

import sys
import math
import time
import argparse
import pprint
import numpy

# Makes the drone fly and get Lidar data
class BoundaryTest:

    def __init__(self):

        # connect to the AirSim simulator
        self.client = airsim.MultirotorClient()
        self.client.confirmConnection()
        self.client.enableApiControl(True)

    def execute(self):

        print("arming the drone...")
        self.client.armDisarm(True)

        state = self.client.getMultirotorState()
        s = pprint.pformat(state)
        #print("state: %s" % s)

        airsim.wait_key('Press any key to takeoff')
        self.client.takeoffAsync().join()

        state = self.client.getMultirotorState()
        #print("state: %s" % pprint.pformat(state))

        self.client.hoverAsync().join()

        airsim.wait_key('Press any key to get Boundary readings')
        boundary = self.client.simGetBoundary()
        print(boundary)
        
        airsim.wait_key('Press any key to set Boundary')
        self.client.simEnableCustomBoundaryData(True)
        boundary = Boundary()
        boundary.pos = state.kinematics_estimated.position
        boundary.boundary = [Vector3r(10,-10,10),
                             Vector3r(-10,10,10),
                             Vector3r(10,10,10),
                             Vector3r(-10,-10,10)]
        self.client.simSetBoundary(boundary)

        for i in range(1,5):
            #lidarData = self.client.getLidarData();
            time.sleep(5)

    def stop(self):

        airsim.wait_key('Press any key to reset to original state')

        self.client.armDisarm(False)
        self.client.reset()

        self.client.enableApiControl(False)
        print("Done!\n")

# main
if __name__ == "__main__":
    boundaryTest = BoundaryTest()
    try:
        boundaryTest.execute()
    finally:
        boundaryTest.stop()
