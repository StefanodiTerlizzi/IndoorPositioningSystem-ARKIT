import open3d as o3d
import numpy as np
import json
import math

from enum import Enum

class TRANSFORMATION(Enum):
    GLOBALTOLOCAL = 1
    LOCALTOGLOBAL = 2

transformations = {}

def createPositionPointsFromElement(e):
    array = []
    rowColumns = [(3,0),(3,1),(3,2)]
    point = [e["position"][r][c] for r,c in rowColumns]
    #print(point)
    array.append(np.array(point)) #anchor
    #front
    #array.append(np.array([ e["position"][0] - e["scale"][0] / 2, e["position"][1] + e["scale"][1] / 2, e["position"][2] + e["scale"][2] / 2 ])) #bounding box left high - LH
    #array.append(np.array([ e["position"][0] - e["scale"][0] / 2, e["position"][1] - e["scale"][1] / 2, e["position"][2] + e["scale"][2] / 2  ])) #bounding box left down - LD
    #array.append(np.array([ e["position"][0] + e["scale"][0] / 2, e["position"][1] + e["scale"][1] / 2, e["position"][2] + e["scale"][2] / 2  ])) #bounding box right high - RH
    #array.append(np.array([ e["position"][0] + e["scale"][0] / 2, e["position"][1] - e["scale"][1] / 2, e["position"][2] + e["scale"][2] / 2  ])) #bounding box right down - RD
    #rear
    #array.append(np.array([ e["position"][0] - e["scale"][0] / 2, e["position"][1] + e["scale"][1] / 2, e["position"][2] - e["scale"][2] / 2 ])) #bounding box left high - LH
    #array.append(np.array([ e["position"][0] - e["scale"][0] / 2, e["position"][1] - e["scale"][1] / 2, e["position"][2] - e["scale"][2] / 2  ])) #bounding box left down - LD
    #array.append(np.array([ e["position"][0] + e["scale"][0] / 2, e["position"][1] + e["scale"][1] / 2, e["position"][2] - e["scale"][2] / 2  ])) #bounding box right high - RH
    #array.append(np.array([ e["position"][0] + e["scale"][0] / 2, e["position"][1] - e["scale"][1] / 2, e["position"][2] - e["scale"][2] / 2  ])) #bounding box right down - RD
    return array

def alignPointToPointICP(data):
    #Open3D PointCloud objects
    localRef = o3d.geometry.PointCloud()
    globalRef = o3d.geometry.PointCloud()

    # Now, 'data' contains the contents of the JSON file as a Python dictionary
    #elementToAlign = data[0]
    localPointsArray = []
    globalPointsArray = []
    for elementToAlign in data:
        localPointsArray.extend(createPositionPointsFromElement(elementToAlign["local"]))
        globalPointsArray.extend(createPositionPointsFromElement(elementToAlign["global"]))

    localRef.points = o3d.utility.Vector3dVector(np.array(localPointsArray))
    globalRef.points = o3d.utility.Vector3dVector(np.array(globalPointsArray))

    print(localRef)
    print(np.asarray(localRef.points))
    print(globalRef)
    print(np.asarray(globalRef.points))

    o3d.visualization.draw_geometries([globalRef, localRef])



    #o3d.visualization.draw_geometries([localRef])
    #o3d.visualization.draw_geometries([globalRef])
    # Perform Point-to-Point ICP with known correspondences
    reg_p2p = o3d.pipelines.registration.registration_icp(
        source=globalRef,
        target=localRef,
        max_correspondence_distance=100,  # Maximum correspondence distance
        estimation_method=o3d.pipelines.registration.TransformationEstimationPointToPoint(),
        criteria=o3d.pipelines.registration.ICPConvergenceCriteria(relative_fitness=1e-6, relative_rmse=1e-6, max_iteration=500),
    )

    print(reg_p2p.transformation)
    print(reg_p2p)

    # Apply the transformation to align the point clouds
    globalRef.transform(reg_p2p.transformation)

    print(localRef)
    print(np.asarray(localRef.points))
    print(globalRef)
    print(np.asarray(globalRef.points))

    # Visualize the aligned point clouds
    o3d.visualization.draw_geometries([globalRef, localRef])

def alignRansac(data, transformation):
    #Open3D PointCloud objects
    localRef = o3d.geometry.PointCloud()
    globalRef = o3d.geometry.PointCloud()

    # Now, 'data' contains the contents of the JSON file as a Python dictionary
    #elementToAlign = data[0]
    localPointsArray = []
    globalPointsArray = []
    for elementToAlign in data:
        localPointsArray.extend(createPositionPointsFromElement(elementToAlign["local"]))
        globalPointsArray.extend(createPositionPointsFromElement(elementToAlign["global"]))

    localRef.points = o3d.utility.Vector3dVector(np.array(localPointsArray))
    globalRef.points = o3d.utility.Vector3dVector(np.array(globalPointsArray))

    #print(localRef)
    #print(np.asarray(localRef.points))
    #print(globalRef)
    #print(np.asarray(globalRef.points))

    #o3d.visualization.draw_geometries([globalRef, localRef])
    
    # RANSAC parameters
    ransac_dist_threshold = 0.1  # Adjust this threshold based on your data and accuracy requirements
    max_iterations = 10000

    corres_range = np.arange(3).astype(np.int32)
    o3d_corres = np.stack((corres_range, corres_range), axis=1)
    o3d_corres = o3d.utility.Vector2iVector(o3d_corres)
    distance_threshold = 0.1


    # Apply RANSAC to find the transformation
    reg_result = o3d.pipelines.registration.registration_ransac_based_on_correspondence(
        globalRef if transformation == TRANSFORMATION.GLOBALTOLOCAL else localRef,
        localRef if transformation == TRANSFORMATION.GLOBALTOLOCAL else globalRef,
        o3d_corres,
        distance_threshold,
        o3d.pipelines.registration.TransformationEstimationPointToPoint(True),
        ransac_n=3,
        criteria=o3d.pipelines.registration.RANSACConvergenceCriteria(10000, 500),
    )

    # Get the refined transformation
    transformation = reg_result.transformation


    #print("trnasformation matrix for position, global -> local")
    #print(reg_result)
    #print(transformation)

    # Apply the transformation to cloud2
    globalRef.transform(transformation)

    # Visualize the aligned point clouds
    #o3d.visualization.draw_geometries([globalRef, localRef])
    return reg_result

def YrotationMatrix(data, transformation):
    PosCos, PosSin, NegSin = (0,0), (0,2), (2,0)
    YdegreeRotation = []
    for element in data:
        cosAlpha = element["global" if transformation == TRANSFORMATION.GLOBALTOLOCAL else "local"]["position"][PosCos[0]][PosCos[1]]
        alpha = math.acos(cosAlpha)
        #print(f"alpha {alpha}")

        cosBeta = element["local" if transformation == TRANSFORMATION.GLOBALTOLOCAL else "global"]["position"][PosCos[0]][PosCos[1]]
        beta = math.acos(cosBeta)
        #print(f"beta {beta}")

        sinAlpha = element["global" if transformation == TRANSFORMATION.GLOBALTOLOCAL else "local"]["position"][PosSin[0]][PosSin[1]]

        sinBeta = element["local" if transformation == TRANSFORMATION.GLOBALTOLOCAL else "global"]["position"][PosSin[0]][PosSin[1]]

        cosAlphaMinusBeta = cosAlpha*cosBeta+sinAlpha*sinBeta

        AlphaMinusBetainDegree = math.acos(cosAlphaMinusBeta) * (180/math.pi)

        #print(f"cosAlphaMinusBeta {cosAlphaMinusBeta}, AlphaMinusBeta {AlphaMinusBetainDegree}")

        YdegreeRotation.append(AlphaMinusBetainDegree)
    # Convert the angle from degrees to radians
    angle_radians = math.radians(np.mean(YdegreeRotation))

    # Create the 4x4 rotation matrix around the Y-axis
    cos_theta = math.cos(angle_radians)
    sin_theta = math.sin(angle_radians)

    return np.array([
        [cos_theta, 0, sin_theta, 0],
        [0, 1, 0, 0],
        [-sin_theta, 0, cos_theta, 0],
        [0, 0, 0, 1]
    ])

def printDifferencesMatrix(room, traslation, rotationY, transformation):
    for e in room:
        alpha = np.array(e['local' if transformation == TRANSFORMATION.GLOBALTOLOCAL else 'global']['position'])
        # print(f"localPoint\n{localPoint}")
        beta = np.array(e['global' if transformation == TRANSFORMATION.GLOBALTOLOCAL else 'local']["position"])
        # print(f"globalPoint before transformation\n{globalPoint}")
        beta[3] = np.dot(traslation, beta[3])
        # print(f"globalPoint after traslation\n{globalPoint}")
        beta[:3, :3] = np.dot(rotationY[:3, :3], beta[:3, :3])
        # print(f"globalPoint after rotation\n{globalPoint}")

        diffMatrix = []
        for r in range(4):
            diffMatrix.append(np.array([round(alpha[r,c] - beta[r,c], 5) for c in range(4)])) # round(localPoint[r,c] - globalPoint[r,c], 5)

        print(np.array(diffMatrix))
    
# Open and read the JSON file
with open('./jsonMatching.json', 'r') as file:
    rooms = json.load(file)



for k in rooms:
    #alignPointToPointICP(room)
    print(f"align {k} {TRANSFORMATION.GLOBALTOLOCAL}")
    reg_result = alignRansac(data=rooms[k], transformation=TRANSFORMATION.GLOBALTOLOCAL)
    print(reg_result)
    R_y = YrotationMatrix(data=rooms[k], transformation=TRANSFORMATION.GLOBALTOLOCAL)
    transformations[f"{k}_{TRANSFORMATION.GLOBALTOLOCAL}"] = (reg_result.transformation, R_y)
    # print(reg_result.transformation)
    # print(f"Rotation Matrix around Y-axis (4x4): {R_y}")
    print("difference matrix")
    printDifferencesMatrix(room=rooms[k], traslation=reg_result.transformation, rotationY=R_y, transformation=TRANSFORMATION.GLOBALTOLOCAL)

    print(f"invert {k} {TRANSFORMATION.LOCALTOGLOBAL}")
    if np.linalg.det(reg_result.transformation) != 0 and np.linalg.det(R_y) != 0:
        inverted_translation = np.linalg.inv(reg_result.transformation)
        inverted_R_Y = np.linalg.inv(R_y)
        print("difference matrix")
        printDifferencesMatrix(room=rooms[k], traslation=inverted_translation, rotationY=inverted_R_Y, transformation=TRANSFORMATION.LOCALTOGLOBAL)
        transformations[f"{k}_{TRANSFORMATION.LOCALTOGLOBAL}"] = (inverted_translation, inverted_R_Y)
    else:
        print("matrix not invertible")
    # print(f"align {k} {TRANSFORMATION.LOCALTOGLOBAL}")
    # reg_result = alignRansac(data=rooms[k], transformation=TRANSFORMATION.LOCALTOGLOBAL)
    # R_y = YrotationMatrix(data=rooms[k], transformation=TRANSFORMATION.LOCALTOGLOBAL)
    # print(reg_result)
    # # print(reg_result.transformation)
    # # print(f"Rotation Matrix around Y-axis (4x4): {R_y}")
    # print("difference matrix")
    # printDifferencesMatrix(room=rooms[k], traslation=reg_result.transformation, rotationY=R_y, transformation=TRANSFORMATION.LOCALTOGLOBAL)


# for k in transformations:
    # print(k)
    # print("translation")
    # print(transformations[k][0])
    # print("rotation Y")
    # print(transformations[k][1])

    # cone = np.array([[-4.371138828673792887e-08, 3.420201241970062256e-01, 9.396926164627075195e-01, 8.947908878326416016e-01],[0.000000000000000000e+00, 9.396926164627075195e-01, -3.420201241970062256e-01, 5.539657592773437500e+00],[-1.000000000000000000e+00, -1.495017620811722736e-08, -4.107527118435427838e-08, 1.714878320693969727e+00],[0.000000000000000000e+00, 0.000000000000000000e+00, 0.000000000000000000e+00, 1.000000000000000000e+00]])
    # cone[3] = np.dot(transformations[k][0], cone[3])
        # # print(f"globalPoint after traslation\n{globalPoint}")
    # cone[:3, :3] = np.dot(transformations[k][1][:3, :3], cone[:3, :3])

    # print(cone)