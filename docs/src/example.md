# Calibrate specific file
## Input Arguments
- [4 rows, 6 columns]
- inpput video filepath
- results directory  
;  
- skipnumber of image frame in the video
```
calibrate_video_checkerboard([4,6],"Vid_20131219_105014_small_180p.mp4","/Users/USERNAME/Desktop/CameraCalibration/results"; numskipframe=10);
```

# Calibrate and send result to default CameraCalibration directory
without skipping any video frame
```
calibrate_video_checkerboard([4,6],"Vid_20131219_105014_small_180p.mp4");
```

# Calibrate and send result to default CameraCalibration directory
- without skipping any video frame
- calibrate all video files in directory username/Desktop/CameraCalibration
```
calibrate_video_checkerboard([4,6]);
```

# Test if everything works
```
calibrate_video_checkerboard([4,6], joinpath(dirname(dirname(pathof(CameraCalibration))), "test", "Vid_20131219_105014_small_180p.mp4") ; numskipframe=10)
```