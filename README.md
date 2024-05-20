# IMPLEMENTATION
## The aim of this project is to create an Indoor Positioning System. In particular, the app consists of three main functionalities:
- ### Scanning the environment:
    This function provides a simple way to scan the environment. Thanks to the RoomPlan API exposed by Apple, it is possible to create a 3D mesh and save it in a file.usdz and an ARWorldMap file that contains the information about all the feature points captured during the scanning. 
    
    These files are saved under the directories “Maps” and “MapsUSDZ”. Thanks to this couple of files, it is possible to load a new ARSession initialized by the ARWorldMap. The global map is generated in the same way and moved under the “ExportCombined” folder.

- ### Maps alignment:
    Given two 3D meshes, “LocalMap” and “GlobalMap”, you have to choose three couples of points [(PL1, PG1), …]. PL1 is a point in the “LocalMap” and PG1 is the same point in the “GlobalMap”.
    
    After that, it is possible to call the endpoint (POST) “https://develop.ewlab.di.unimi.it/musajapan/navigation/api/ransacalignment”. This endpoint executes a Ransac alignment Point to Point and returns a JSON formed as follows:

        {
            “R_Y”: [[Float4x4]],
            “translation”: [[Float4x4]],
            “diffMatrix”: [[Float4x4]],
            “reg_result”: String
        }

    - reg_result: Describes the result of Ransac alignment. In particular, the fitness value is between [0,1] where 1 is a perfect score, and a measure of error, inlier_rmse=3.051323e-02.
    - translation: Is the translation matrix calculated to project a POS from the local space to the global space.
    - R_Y: Describes the rotation to project the orientation of a POS from the local space to the global space. (This is calculated as the difference between the Y rotation of PL1 and the Y rotation of PG1)
    - diffMatrix: Describes how precise the result was. In particular, you can read this as follows: Given a POS in the local space, and applied the transformation and rotation, how close is it to the correct projection on the global space? Where a zero matrix means that the projection is perfect.
- Navigation: In this section, it is possible to navigate by loading an ARSession. In particular, the first time you have to choose one of the local maps previously scanned (e.g., “Room1”).
    
    At this moment, you are in “relocalizing” status, and your position is at [0,0,0]. After that, you can start to walk in the environment, and hopefully soon, the system recognizes some points and moves to “normal” status and corrects your position.
    
    When your position is outside the zone covered by “Room1” but is covered by another scanned local map (e.g., Room2), the system notifies you and asks for permission to change the local map and the ARSession.
    
    During this process, the known global POS is used to calculate where the origin of the “Room2” is with respect to your POS and initialize the ARSession specifying the relative POS of the “Room2”'s origin.
    
    Now, the system goes to “relocalizing” status, but your position is correct and not initialized at [0,0,0] as a normal ARSession loading.
    
    The implementation of the recognition of the local zones limit is done by calculating the bounding boxes (BB) of each local zone and projecting the 4 BB descriptor point of each of them to the global space reference system. During all the navigation, you can see your position in the “local space” and in the “global space” projected by the previously calculated transformations.

# TODO
- ### Investigate the generalization problem of calculating “R_Y”.
    Now it is a really naive way to do it and is not robust with all environment scans. A new system can take the rotation directly from the Ransac alignment matrix, probably.
- ### RoomPlanAPI API dependancy
    This system is based on the RoomPlanAPI API and 3D meshes created from that. The first thing to do is to try to create a “global” planimetry without this API and connect the “locals ARWorldMap” through 3 points inserted in the 2 systems.
- ### bounding boxes to Covnex Hull
    The bounding boxes calculated as that do not allow a perfect zone separation. It is more useful to take the convex hull generated starting by all the feature points extracted by the local ARWorldMap
