using Pkg
Pkg.activate("/Users/abel/Documents/Github/CameraCalibration.jl")
using Printf
using OpenCV, CxxWrap
cv = OpenCV
using JLD2

export cal_imgsfol, cal_imgsVideo

function extend_dims(A,which_dim)
    s = [size(A)...]
    insert!(s,which_dim,1)
    return reshape(A, s...)
end

mat_jl2mat_cv(x) = cv.Mat{Float32}(Any, extend_dims(x, 2) )
mat_jl2mat_cvCxxMat(x) = cv.CxxMat{Float32}(Any, extend_dims(x, 2) )

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
                corners2 = cv.cornerSubPix(gray,corners, cv.Size(Int32(11),Int32(11)), cv.Size(Int32(-1),Int32(-1)), criteria)
                corners = corners2

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
# ii, cl, fl= cal_imgsVideo(fname, [4,6]; numskipframe=30)
function cal_imgsVideo(vidfname, config=[4,5];
    resImageFilepath=false, res_postfix="_res_"*replace( string(config), '['=>'(', ']'=>')', ','=>'.' ),
    numskipframe=0,
    createResultFolder=false
    )
    criteria = cv.TermCriteria( Int32(cv.TERM_CRITERIA_EPS + cv.TERM_CRITERIA_MAX_ITER), Int32(30), 0.001)
    corner_winsize = cv.Size(Int32(11),Int32(11))
    corner_zerozone = cv.Size(Int32(-1),Int32(-1))

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
            corners = cv.cornerSubPix(gray,corners, corner_winsize, corner_zerozone, criteria)
            # corners_jl = Int.(round.(corners))
            # for i in 1:size(corners_jl,3)
            #     draw!(img, Ellipse(CirclePointRadius(corners_jl[1,1,i], corners_jl[2,1,i],dot_size)), RGB{N0f8}(1,0,0))
            # end
            # push!(corners_list, corners_jl[:,1,:])
            push!(corners_list, corners[:,1,:])
            push!(frame_list, counts)
            # save(joinpath("/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_res_good", "image-" *@sprintf("%08d", counts)* ".png"), img)
        end
        t_inS = (counts-1)/fps
        @debug(string(counts)* "/" *string(totalframe) *" "*string(floor(Int,t_inS/60))*":" * string(round(mod(t_inS,60), digits=3) )*"\t"* string(ret) )
        # @debug(string(counts)* "/" *string(totalframe) *" "*string(floor(Int,(counts-1)/fps))*":" * string(round(mod((counts-1),fps)/fps*60, digits=3) )*"\t"* string(ret) )
        
        if numskipframe==0
            counts += 1
        else
            try
                skipframes(vid, numskipframe-1)
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
            draw!(img, Ellipse(CirclePointRadius(Int(round(corner[1,i])), Int(round(corner[2,i])), dot_size)), typeof(img[1])(1,j/len_cl,0))
            #@debug [corner[1,i], corner[2,i]]
        end
    end
    return img
end

function display_corners(img, corners_list; dot_size=25)
    ii = deepcopy(img)
    len_cl = length(corners_list)
    for j in 1:len_cl
        corner = corners_list[j]
        for i in 1:size(corner,2)
            draw!(ii, Ellipse(CirclePointRadius(Int(round(corner[1,i])), Int(round(corner[2,i])), dot_size)), typeof(img[1])(1,j/len_cl,0))
            #@debug [corner[1,i], corner[2,i]]
        end
    end
    return ii
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


############################################################
# load_fname = "/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014.jld2"
# calib_params = load(load_fname)
# vid = VideoIO.openvideo(fname)
# ii = read(vid)

function select_good_corners(calib_fname::String, fname::String)
    calib_params = load(calib_fname)
    select_good_corners(calib_params, img::PermutedDimsArray)
end

function select_good_corners(calib_params, fname::String)
    vid = VideoIO.openvideo(fname)
    img = read(vid)
    select_good_corners(calib_params, img::PermutedDimsArray)
end


function select_good_corners(calib_params, img::PermutedDimsArray)
    imsize = size(img)
    nearest_indices_list, nearest_val_list, frame_good = select_good_corners(calib_params, imsize)
    img_new = display_corners(img, calib_params["corners_list"][nearest_indices_list])
    nearest_indices_list, nearest_val_list, frame_good, img_new
end

function select_good_corners(calib_params, imsize::Tuple)
    im_h, im_w = imsize
    grid_h = 4
    grid_w = floor(im_w / im_h * grid_h) |> Int

    gridW = 1:im_w/(grid_w-1):im_w+1 |> collect
    gridW[end] = gridW[end] - 1
    gridH = 1:im_h/(grid_h-1):im_h+1 |> collect
    gridH[end] = gridH[end] - 1

    grid = Matrix{eltype(gridH)}(undef, 2, length(gridH)*length(gridW))
    counter = 1 
    for w in gridW
        for h in gridH
            grid[1,counter] = w
            grid[2,counter] = h
            counter += 1
        end
    end

    cls = calib_params["corners_list"]
    nearest_indices_list = Array{Int}(undef, length(gridH)*length(gridW))
    nearest_val_list = Array{Float64}(undef, length(gridH)*length(gridW))
    for i in 1:size(grid,2)
        nearest_val = Inf
        g = grid[:,i]
        for j in 1:size(cls,1)
            dist = mapslices( norm, cls[j] .- g; dims=1) |> minimum
            if dist < nearest_val
                nearest_indices_list[i] = j
                nearest_val_list[i] = dist
                nearest_val = dist
            end
        end
    end
    nearest_indices_list = unique(nearest_indices_list) |> sort
    # img_new = display_corners(ii, cls[nearest_indices_list])

    frame_good = calib_params["file_list"][nearest_indices_list]

    nearest_indices_list, nearest_val_list, frame_good

end
# #######################################################

function vid_frame2img(vidfname, framelist, func, args=nothing)
    vid = VideoIO.openvideo(vidfname)
    index = 1
    ind = 1
    output_list = []
    for frame_ind in framelist
        if frame_ind == 1
            img = read(vid)
        else
            # @debug frame_ind-index
            skipframes(vid, frame_ind-index)
            img = read(vid)
        end
        index = frame_ind+1

        push!(output_list, func(img, ind, frame_ind, args))
        ind += 1
    end
    return output_list
end

function save_img(img, ind, index, dirpath) 
    # @debug(  joinpath(dirpath, "image-" *@sprintf("%08d", ind)* ".png") )
    # @debug size(img)
    isdir(dirpath) || mkdir(dirpath)
    save(joinpath(dirpath, "image-" *@sprintf("%08d", ind)* ".png"), img)
    return index
end
function save_imgCorners!(img, ind, index, dirpath__calib_params__nearest_indices_list) 
    # @debug(  joinpath(dirpath, "image-" *@sprintf("%08d", ind)* ".png") )
    # @debug size(img)
    dirpath, calib_params, nearest_indices_list = dirpath__calib_params__nearest_indices_list
    display_corners!(img, [calib_params["corners_list"][nearest_indices_list[ind]]] )

    isdir(dirpath) || mkdir(dirpath)
    save(joinpath(dirpath, "image-" *@sprintf("%08d", ind)* ".png"), img)
    return index
end
function save_imgCorners__save_img!(img, ind, index, dirpath__calib_params__nearest_indices_list)
    dirpath, _, _ = dirpath__calib_params__nearest_indices_list
    save_img(img, ind, index, dirpath*"_raw") 
    save_imgCorners!(img, ind, index, dirpath__calib_params__nearest_indices_list)
end


# save("/Users/abel/Documents/data_res/aspod/aspod2_20220513_nuspool_r-full.png", ii)
ENV["JULIA_DEBUG"] = all
@info ("fully loaded")

#= USAGE
fname = "/Users/abel/Documents/data/aspod/2023-01-20_labtank_checkerboard/Vid_20131219_105014.mkv"
res_fol = "/Users/abel/Documents/data_res/aspod/cam_calib/aspod2"
ii, cl, fl= cal_imgsVideo(fname, [4,6]; numskipframe=30)
calib_params = Dict(
       "fname" => fname,
       "corners_list" => cl,
       "file_list" => fl
       )
save_postfix = "_s30" # ""

save(joinpath(res_fol, split(splitext(fname)[1],'/')[end]*"$save_postfix.jld2"), Dict(
       "fname" => fname,
       "corners_list" => cl,
       "file_list" => fl
       ) )
save(joinpath(res_fol, split(splitext(fname)[1],'/')[end]*"$save_postfix.jpg"), ii)

calib_params = load("/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014.jld2")

nearest_indices_list, nearest_val_list, frame_good, img_new = select_good_corners(calib_params, fname)
vid_frame2img(calib_params["fname"], frame_good, save_imgCorners__save_img!, (joinpath(res_fol,splitext(basename(fname))[1]*save_postfix), calib_params, nearest_indices_list))

#vid_frame2img(calib_params["fname"], frame_good, save_imgCorners!, ("/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014$save_postfix", calib_params, nearest_indices_list))
#vid_frame2img(calib_params["fname"], frame_good, save_img, "/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014$save_postfix_raw")

d = load("/Users/abel/Documents/data_res/aspod/cam_calib/aspod2/Vid_20131219_105014_s30.h5")
=#
# imgpoints = calib_params["corners_list"][nearest_indices_list] .|> mat_jl2mat_cv
# objpoints = deepcopy(imgpoints)


#~ show one frame result
# i=3
# seekstart(vid); skipframes(vid, calib_params["file_list"][i]-1); 
# ii = read(vid)
# display_corners(ii, [calib_params["corners_list"][i]] )

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




