using Pkg
Pkg.activate("/Users/abel/Documents/Github/CameraCalibration.jl")
using OpenCV, CxxWrap
cv = OpenCV

# config=[4,5] for aspod small portable checkboard, [6,9] for big checkerboard in Hong Kong; [column, row] of intersecting points
function cal_imgsfol(fol, config=[4,5]; createResultFolder=false, res_postfix="_res_"*replace( string(config), '['=>'(', ']'=>')', ','=>'.' ) )
    corners_list = []
    fname_list = []

    config = cv.Size(Int32(config[1]),Int32(config[2]))
    createResultFolder && (isdir(fol*res_postfix)  || mkdir(fol*res_postfix) )

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
                cv.imwrite(joinpath(root*res_postfix, file), img_new)
                push!(corners_list, corners[:,1,:])
                push!(fname_list, joinpath(root,file))
                img_cum =  cv.drawChessboardCorners(img_cum, config, corners, ret)
            end
        end
    end
    createResultFolder && cv.imwrite(fol*res_postfix*"__summary.png", img_cum)
    return fname_list, corners_list
end

using VideoIO, Images, ImageDraw
function cal_imgsVideo(vidfname, config=[4,5]; resImageFilepath=false, res_postfix="_res_"*replace( string(config), '['=>'(', ']'=>')', ','=>'.' ) )
    vid = VideoIO.openvideo(vidfname) #"/Users/abel/Documents/aspod/data/2022-05-13_nus-pool/0015/Vid_20131219_101550.mkv")

    config = cv.Size(Int32(config[1]),Int32(config[2]))
    @info "counting total frames..."
    # totalframe = counttotalframes(vid)
    try
        totalframe = readchomp(`ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1  $vidfname`)
        totalframe = parse(Int, totalframe)
    catch err
        totalframe = missing
        @info "[ERR]unable to get total number of frame"
    end
    corners_list = []; frame_list = []
    counts=1
    while !eof(vid)
        img = read(vid);

        config = cv.Size(Int32(4),Int32(5))
        dot_size = 25

        img_cv = permutedims(channelview(img), (1,3,2))
        img_cv = cv.Mat{UInt8}(Any, UInt8.(round.(img_cv.*255)) )
        gray = cv.cvtColor(img_cv, cv.COLOR_BGR2GRAY);
        ret, corners = cv.findChessboardCorners(gray, config, flags=cv.CALIB_CB_EXHAUSTIVE)
        if ret
            corners_jl = Int.(round.(corners))
            # for i in 1:size(corners_jl,3)
            #     draw!(img, Ellipse(CirclePointRadius(corners_jl[1,1,i], corners_jl[2,1,i],dot_size)), RGB{N0f8}(1,0,0))
            # end
            push!(corners_list, corners_jl[:,1,:])
            push!(frame_list, counts)
        end
        @debug(string(counts) * "/" * string(totalframe) *"\t"* string(ret) )
        counts += 1
    end

    img
    for j in 1:length(corners_list)
        corner = corners_list[j]
        for i in 1:size(corner,2)
            draw!(img, Ellipse(CirclePointRadius(corner[1,i], corner[2,i],dot_size)), RGB{N0f8}(1,0,0))
            #@debug [corner[1,i], corner[2,i]]
        end
    end
    display(img)
    
    return img, corners_list
end

@info ("fully loaded")


# f,c_2 = cal_imgsfol("/Users/abel/Documents/data_res/aspod/aspod2_20220513_nuspool", [4,5]; createResultFolder=true)
# f,c = cal_imgsfol("/Users/abel/Documents/data_res/calf/HK_camcalib", [6,9]; createResultFolder=true)
# /Users/abel/Documents/data/calf/Calibration/Checkerboard_Calibration/20191128/20191128_14.40.35_log.mkv


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




