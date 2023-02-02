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
function cal_imgsVideo(vidfname, config=[4,5];
    resImageFilepath=false, res_postfix="_res_"*replace( string(config), '['=>'(', ']'=>')', ','=>'.' ),
    numskipframe=0,
    createResultFolder=false
    )
    
    vid = VideoIO.openvideo(vidfname) #"/Users/abel/Documents/aspod/data/2022-05-13_nus-pool/0015/Vid_20131219_101550.mkv")

    config = cv.Size(Int32(config[1]),Int32(config[2]))
    dot_size = 25

    @info "counting total frames..."
    # totalframe = counttotalframes(vid)
    totalframe = missing
    try
        totalframe = readchomp(`ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 $vidfname`)
        @info "Total Frame: $totalframe"
        totalframe = parse(Int, totalframe)
    catch err
        try 
            @error "Couldn't detect fps fast, ffmmpeg not in path, revert to using julia's VideoIO to find fps(slower)"
            totalframe = counttotalframes(vid)
        catch err
            totalframe = missing
            @error "[ERR]unable to get total number of frame"
        end

        # totalframe = missing
        # @error "[ERR]unable to get total number of frame"
    end

    fps = missing
    try 
        fps = split(readchomp(`ffprobe -v 0 -of compact=p=0 -select_streams 0 -show_entries stream=r_frame_rate $vidfname`), '=')[2] #`ffmpeg -i $vidfname 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p"`)
        try 
            fps = parse(Float64,fps)
        catch err
            fps = round(reduce(/, parse.(Float64, split(fps,'/')) ), digits=3)
        end
        
        @info "fps: " * string(fps)
    catch err
        fps = missing
        @error "[ERR]unable to get fps"
    end

    corners_list = []; frame_list = []
    counts=1
    img = []
    while !eof(vid)
        try
            img = read(vid);
        catch err
            @error "cant read video"
            break
        end


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
        t_inS = (counts-1)/fps
        @debug(string(counts)* "/" *string(totalframe) *" "*string(floor(Int,t_inS/60))*":" * string(round(mod(t_inS,60), digits=3) )*"\t"* string(ret) )
        # @debug(string(counts)* "/" *string(totalframe) *" "*string(floor(Int,(counts-1)/fps))*":" * string(round(mod((counts-1),fps)/fps*60, digits=3) )*"\t"* string(ret) )
        
        if numskipframe==0
            counts += 1
        else
            try
                skipframes(vid, numskipframe)
            catch err
                @info "no more frames"
                break
            end
            counts += numskipframe
        end
    end
    
    seekstart(vid)
    img = read(vid)
    try
        display_corners!(img, corners_list; dot_size=dot_size)
        display(img)
    catch err
        @error "[Err] Can't plot detected checkerboard points"
    end
    # len_cl = length(corners_list)
    # try
    #     for j in 1:len_cl
    #         corner = corners_list[j]
    #         for i in 1:size(corner,2)
    #             draw!(img, Ellipse(CirclePointRadius(corner[1,i], corner[2,i],dot_size)), RGB{N0f8}(1,j/len_cl,0))
    #             #@debug [corner[1,i], corner[2,i]]
    #         end
    #     end
    # catch err
    #     @error "Failed to plot detected points"
    # end

    return img, corners_list, frame_list
end


function display_corners!(img, corners_list; dot_size=25)
    len_cl = length(corners_list)
    for j in 1:len_cl
        corner = corners_list[j]
        for i in 1:size(corner,2)
            draw!(img, Ellipse(CirclePointRadius(corner[1,i], corner[2,i],dot_size)), typeof(img[1])(1,j/len_cl,0))
            #@debug [corner[1,i], corner[2,i]]
        end
    end
    return img
end



# function display_corners!(img,corners_list; dot_size=25)
#     for j in 1:length(corners_list)
#         corner = corners_list[j]
#         for i in 1:size(corner,2)
#             @show typeof(img)
#             @show [corner[1,i], corner[2,i]]
#             @show typeof( Ellipse(CirclePointRadius(corner[1,i], corner[2,i],dot_size)) )
#             @show typeof( RGB{N0f8}(1,0,0) )
#             draw!(img, Ellipse(CirclePointRadius(corner[1,i], corner[2,i],dot_size)), RGB{N0f8}(1,0,0))
#             #@debug [corner[1,i], corner[2,i]]
#         end
#     end
#     return img
# end

# save("/Users/abel/Documents/data_res/aspod/aspod2_20220513_nuspool_r-full.png", ii)

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




