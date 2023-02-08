using ImageProjectiveGeometry
using JLD2
using LinearAlgebra

function Camera(camera_params)
    Camera(
        fx  = camera_params["mtx"][1,1],
        fy  = camera_params["mtx"][2,2],
        ppx = camera_params["mtx"][3,1],
        ppy = camera_params["mtx"][3,2],
        k1  = camera_params["dist"][1],
        k2  = camera_params["dist"][2],
        k3  = camera_params["dist"][5],
        p1  = camera_params["dist"][3],
        p2  = camera_params["dist"][4],
        skew= camera_params["mtx"][2,1],
        cols= camera_params["imsize"][1],
        rows= camera_params["imsize"][2]
    )
end

vect_angle(a,b) = acos(clamp(a⋅b/(norm(a)*norm(b)), -1, 1))
vect_angled(a,b) = acosd(clamp(a⋅b/(norm(a)*norm(b)), -1, 1))

# sph2cart(r, θ, ϕ) = r. [; ; ] 

# function test()
    camera_params = load("/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_s30.h5")
    cam = Camera(camera_params)

    horizontal_angle = vect_angled( imagept2ray(cam, cam.rows/2, 1), imagept2ray(cam, cam.rows/2, cam.cols) ) # 62.61721188568244
    vertical_angle = vect_angled( imagept2ray(cam, 1, cam.cols/2), imagept2ray(cam, cam.rows, cam.cols/2) ) # 35.793211268714096
    diagonal_angle = vect_angled( imagept2ray(cam, 1, 1), imagept2ray(cam, cam.rows, cam.cols)) # 71.6855447884958

    
# end
