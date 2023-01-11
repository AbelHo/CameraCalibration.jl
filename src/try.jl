using Pkg
Pkg.activate("/Users/abel/Documents/Github/CameraCalibration.jl")
using OpenCV, CxxWrap
cv = OpenCV

# config=[4,5] for aspod small portable checkboard, [6,9] for big checkerboard in Hong Kong; [column, row] of intersecting points
function cal_imgsfol(fol, config=[4,5]; createResultFolder=false)
    corners_list = []
    fname_list = []

    config = cv.Size(Int32(config[1]),Int32(config[2]))
    createResultFolder && (isdir(fol*"_res")  || mkdir(fol*"_res") )

    img_cum = [] # accumulate drawing of detected checkerboard points
    for (root, dirs, files) in walkdir(fol)
        println(stdout, "Files in $root")
        for file in files
            @debug file
            img = cv.imread(joinpath(root,file))
            gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)

            if isempty(img_cum)
                img_cum=img
            end

            ret, corners = cv.findChessboardCorners(gray, config, flags=cv.CALIB_CB_EXHAUSTIVE) 
            @debug ret

            if createResultFolder && ret
                img_new = cv.drawChessboardCorners(img, config, corners, ret)
                cv.imwrite(joinpath(root*"_res", file), img_new)
                push!(corners_list, corners[:,1,:])
                push!(fname_list, joinpath(root,file))
                img_cum =  cv.drawChessboardCorners(img_cum, config, corners, ret)
            end
        end
    end
    createResultFolder && cv.imwrite(fol*"_res__summary.png", img_cum)
    return fname_list, corners_list
end

# f,c_2 = cal_imgsfol("/Users/abel/Documents/data_res/aspod/aspod2_20220513_nuspool", [4,5]; createResultFolder=true)


# fpath = "/Users/abel/Documents/data_res/aspod/2022.03.04/cam_calib/image-000024.png"
# img = cv.imread(fpath)
# gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
# ret, corners = cv.findChessboardCorners(gray, cv.Size(Int32(4),Int32(5)) , flags=cv.CALIB_CB_EXHAUSTIVE) 

# img_new = cv.drawChessboardCorners(img, cv.Size(Int32(4),Int32(5)), corners, ret)
# isdir(dirname(fpath)*"_res")  || mkdir(dirname(fpath)*"_res") 
# cv.imwrite(joinpath(dirname(fpath)*"_res", basename(fpath)), img_new)

# if ret
#     push!(corners_list, corners[:,1,:])
# end

# corners_list = []
# fname_list = []




