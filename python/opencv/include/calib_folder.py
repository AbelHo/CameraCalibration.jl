import numpy as np
import cv2 as cv
import glob
import os

# config = (4,6)
# dirname = "/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_1fps_raw"

def calibrate_folder(dirname, config=(4,6), plotImage=False):
    # termination criteria
    criteria = (cv.TERM_CRITERIA_EPS + cv.TERM_CRITERIA_MAX_ITER, 30, 0.001)
    # prepare object points, like (0,0,0), (1,0,0), (2,0,0) ....,(6,5,0)
    objp = np.zeros((config[1]*config[0],3), np.float32)
    objp[:,:2] = np.mgrid[0:config[0],0:config[1]].T.reshape(-1,2)
    # Arrays to store object points and image points from all the images.
    objpoints = [] # 3d point in real world space
    imgpoints = [] # 2d points in image plane.
    images = glob.glob( os.path.join(dirname,'*.png'))
    for fname in images:
        img = cv.imread(fname)
        gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
        # Find the chess board corners
        ret, corners = cv.findChessboardCorners(gray, (4,6), None)
        # If found, add object points, image points (after refining them)
        if ret == True:
            objpoints.append(objp)
            corners2 = cv.cornerSubPix(gray,corners, (11,11), (-1,-1), criteria)
            imgpoints.append(corners2)
            # Draw and display the corners
            if plotImage:
                if not os.path.exists(plotImage):
                    os.mkdir(plotImage)
                img = cv.drawChessboardCorners(img, config, corners2, ret)
                cv.imwrite(os.path.join(plotImage, os.path.basename(fname)), img)
            #cv.imshow('img', img)
            #cv.waitKey(500)
    #cv.destroyAllWindows()

    ret, mtx, dist, rvecs, tvecs = cv.calibrateCamera(objpoints, imgpoints, gray.shape[::-1], None, None)

    img = cv.imread(images[0])
    h,  w = img.shape[:2]
    newcameramtx, roi = cv.getOptimalNewCameraMatrix(mtx, dist, (w,h), 1, (w,h))
    return newcameramtx, roi, ret, mtx, dist, rvecs, tvecs


def write_undistort(dirname_filetype, newcameramtx, mtx, dist):
    images = glob.glob( dirname_filetype )
    for fname in images:
        img = cv.imread(fname)
        dst = cv.undistort(img, mtx, dist, None, newcameramtx)

        # # crop image
        # x, y, w, h = roi
        # dst = dst[y:y+h, x:x+w]

        # mapx, mapy = cv.initUndistortRectifyMap(mtx, dist, None, newcameramtx, (w,h), 5)
        # dst = cv.remap(img, mapx, mapy, cv.INTER_LINEAR)
        # # crop the image
        # x, y, w, h = roi
        # dst = dst[y:y+h, x:x+w]


        cv.imwrite(fname[:-4]+'_undistort'+fname[-4:], dst)

def example():
    import calib_folder
    import h5py
    camera_params = "/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_s30.h5"
    newcameramtx, roi, ret, mtx, dist, rvecs, tvecs = calib_folder.calibrate_folder("/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_s30_raw",(4,6))


    hf = h5py.File(camera_params, 'w')
    hf.create_dataset('cameramtx', data=newcameramtx)
    hf.create_dataset('roi', data=roi)
    hf.create_dataset('ret', data=ret)
    hf.create_dataset('mtx', data=mtx)
    hf.create_dataset('dist', data=dist)
    hf.create_dataset('rvecs', data=rvecs)
    hf.create_dataset('tvecs', data=tvecs)
    hf.close()

    calib_folder.write_undistort('/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_s30_raw/*.png', newcameramtx, mtx, dist)
