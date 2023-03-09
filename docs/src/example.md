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

# Example output of checkerboard detection
[example_results/Vid_20131219_105014_small_180p_s10](example_results/Vid_20131219_105014_small_180p_s10)  
<p float="left">
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000001.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000002.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000003.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000004.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000005.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000006.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000007.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000008.png" width="100" />
</p>
<p float="left">
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000009.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000010.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000011.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000012.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000013.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000014.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000015.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000016.png" width="100" />
</p>
<p float="left">
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000017.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000018.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000019.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000020.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000021.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000022.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000023.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10/image-00000024.png" width="100" />
</p>

# Example of checkboard detected without drawing overlay
[example_results/Vid_20131219_105014_small_180p_s10_raw](example_results/Vid_20131219_105014_small_180p_s10_raw) 
<p float="left">
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000001.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000002.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000003.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000004.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000005.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000006.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000007.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000008.png" width="100" />
</p>
<p float="left">
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000009.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000010.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000011.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000012.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000013.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000014.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000015.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000016.png" width="100" />
</p>
<p float="left">
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000017.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000018.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000019.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000020.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000021.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000022.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000023.png" width="100" />
  <img src="example_results/Vid_20131219_105014_small_180p_s10_raw/image-00000024.png" width="100" />
</p>
