# CameraCalibration

[![Build Status](https://github.com/AbelHo/CameraCalibration.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AbelHo/CameraCalibration.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Requirements
- Required to use Julia 1.7.2 or lower, newer Julia have been tested to fail

## Installation
1. Install Julia 1.7.2 (https://julialang.org/downloads/oldreleases/)
1. Install CameraCalibration.jl
```
using Pkg
Pkg.add(url="https://github.com/AbelHo/CameraCalibration.jl")
```


## Usage
1. Create directory called ```CameraCalibration``` on your desktop
1. Put all the videos you want to analyse in that director
2. Load CameraCalibration library to initialize
```
using CameraCalibration
```
1. This command will automatically search for that folder and process all the videos in it
```
calibrate_video_checkerboard()
```

# Test if everything works
```
calibrate_video_checkerboard([4,6], joinpath(dirname(dirname(pathof(CameraCalibration))), "test", "Vid_20131219_105014_small_180p.mp4") ; numskipframe=10)
```

## Other Details
### Example Instructions
[docs/src/example.md](docs/src/example.md)
### Example Video
[test/Vid_20131219_105014_small_180p.mp4](test/Vid_20131219_105014_small_180p.mp4?raw=true)
