% This script puts together a pipeline to do the subtraction of a global
% median frame from the frames of an experiment. The raw frames are assumed to
% be of datatype uint8. If this is not the case, there are a few places
% where this script and the functions called by it need to be modified.
% After declaration of variables
% (see specifications below) the script creates the necessary directories. One of
% these is an auxiliary directory, which is used during the script
% execution and is removed at the end. The program first converts the
% images as binary files in the auxiliary directory, then calculates the
% global median and saves it in the directory "meddir". This file is saved
% as a uint8 with extension specified 
% by the variable "medimg_extension". Finally, the median is removed from
% each individual image, and the resulting frame is saved in the directory
% "diffdir". Specify the datatype for the median-subtracted images with the
% variable "diffimage_datatype". For more info, read the preamble of the
% function "remove_median.m". At the end of the operation, the auxiliary
% directory is emptied and removed.
%
%HISTORY:
%   20 Feb, 2024. Marco Polin: Created.
%   27 Nov, 2024. MP: Adapted to use as input a folder with an ordered list
%   of images. Added also the possibility to re-name the image files, as
%   some softwares (e.g. uEye) don't format the file names correctly.

tic

%% input variables
basepath='E:/data_analysis_kubra/'; %path to the parent directory of the movie dir
basedir='photokinesis/'; %name of the directory where the raw experiments are stored
imgsdir = 'control2/'; %name of the directory with the images to analyse
imgs_name = 'image_'; %base name of the images
imgs_extension = '.png';
medimg_extension = '.png'; %extension to save the median images
diffimg_extension = '.bin'; %extension to save the median-subtracted images
diffimg_datatype = 'uint8'; %set the datatype required for the median-subtracted images
isRGB = 0; %set to 1 if the original recorded image is RGB; 0 otherwise
bpp = 8; %bytes per pixel in the binary images
maxmem = 1; %max memory occupancy to be used in the median analysis (in Gb. Slightly approximate).
outchannels = [1]; %indicate which channels you want to average over, for the output (1=red, 2=green, 3=blue)
maxframes = -1; %number of frames we want to remove the median from. Set to negative to ensure the median is removed from all of the frames
reordering_files = 1; %set to 1 if you need to reorder the file names; set to 0 if the file names are already well formatted

indir = [basepath,basedir,imgsdir];
auxdir = [basepath,basedir,imgsdir,'tmp/'];
meddir = [basepath,'medians/',imgsdir];
diffdir = [basepath,'diffimgs/',imgsdir,'/']; %save the median-subtracted images here


%% Reorder the frames if needed (e.g. the uEye software appends a file number to the images, which does not contain left-zero-padding of the number)

if reordering_files
    order_files_uEye(indir,imgs_name,imgs_extension);
end

%% make sure the movie is there and the tmp/ directory is not there

if ~exist(auxdir, 'dir')
    statusmk = mkdir(auxdir);
else 
    disp('Auxiliary dir already present. Remove it and rerun the program.');
    return
end

if ~exist(meddir, 'dir')
    statusmkmed = mkdir(meddir);
end

if ~exist(diffdir, 'dir')
    statusmkmed = mkdir(diffdir);
else 
    disp('Folder of median-subtracted images already present. You might want to make sure that this is fine.');
end

%% Save the binary images in the auxdir folder

[imgsHeight,imgsWidth]=convert_frames_to_bin(imgs_name,imgs_extension,indir,auxdir,isRGB,outchannels);


%% Calculate the median and save it
disp('Calculating the median');
medimg = movie_median(imgs_name,auxdir,imgsHeight,imgsWidth,bpp,maxmem);
imwrite(uint8(medimg),[meddir,imgs_name,'_median',medimg_extension]);

%% Remove the median from the movie frames and save them as individual files
% 
disp('Removing the median');
remove_median(imgs_name,auxdir,diffdir,medimg,diffimg_datatype,diffimg_extension,maxframes);
% 
%% At the end of the script, remove the auxdir folder
delete([auxdir,'*']); %delete all files in the directory auxdir
statusrm = rmdir(auxdir); %delete the directory auxdir

if statusrm
    disp('Script successfully completed');
else 
    disp('There has been a problem with removal of the auxiliary directory');
end


toc
