%This style of particle tracking requires setting a few parameters to
%recognise the features. This script can be used for that. The featuring
%step is composed of three parts: 1) band-pass the image to enhance the
%features of a certain size; 2) finding putative features by looking at
%pixels that are sufficiently bright and whittle putative features that are
%too cose to each other; 3) refinement of the features by local intensity
%averaging. Additionally, after step 3 we include a threshold in the total
%intensity (the "mass") of the feature. The parameters that are selected
%here will then be used in the batch-featuring step.
%You should play around with the parameters and select those that could be
%good for you. A potentially good strategy is to set first the parameters
%for step 1), then for step 2) and then for step 3). Then increase the
%masscut threshold to keep only (or mostly) the features you would like.
%Once you are satisfied, it is a good idea to try the same parameters on
%different frames. This might lead to some minor parameter adjustment.
%
%Notice that this version of the script is adapted to work with images that
%are saved as binary files. For this reason we need to provide the number
%of rows and columns and of the original image, as well as the bit depth.
%
%HISTORY
%   28 Nov. 2024. SKC & MP: Created.

%% Clear all variables and close all figures; declaration of auxiliary variables
close all;
clear;

%%input variables
basepath='E:/data_analysis_kubra/'; %path to the parent directory of the movie dir
basedir='diffimgs/'; %name of the directory where the raw experiments are stored
imgsdir = 'control2/'; %name of the directory with the images to analyse
imgs_name = 'diff_image'; %base name of the images
use_image = 1; %this is the image that will be analysed

%%Image parameters. We need to specify these if we use binary files
Nrows = 2048;
Ncols = 2048;
bit_depth = 8;

%% Image processing parameters (these parameters will be used for locating particle's position)
% One should run the code for a single frame and adjust these parameter. After that run for all frames.
invert = 1; %Set to 0 if your features are bright on a dark background. Set to 1 if your features are dark on a bright background
b_lnoise = 1; %correlation span of the pixel noise (usually 1 pixel, meaning that the noise is not correlated across pixels of the camera)
b_object_d=21; %set to slightly larger than the apparent size of the features. This parameter sets the bandpass
b_threshold = 0; %after the convolution, any negative pixels are reset to 0. Threshold changes the threshhold for setting pixels to 0. Positive values may be useful for removing stray noise or small particles. 
pk_thres = 6; %the minimum brightness of a pixel that might be local maximum
pk_object_d = 19; %if multiple peaks are found withing a radius of pk_object_d/2 then the code will keep only the brightest.  Also gets rid of all peaks within pk_object_d of boundary
cnt_object_d = 21; %diamter of the window over which to average to calculate the centroid.
masscut = 200; %threshold total intensity for a good feature
show_features = 0; % Set to 1 to scroll through all of the features considered during peak refining

%% Folder management and input files list
%Path of the folder containing images (Data input folder)
InputFolder = [basepath,basedir,imgsdir];
%get the list of images
infiles = dir([InputFolder,imgs_name,'*.bin']);

%% image processing and position finding
%read the image (binary) and reshape it into the correct shape
fileID = fopen([InputFolder,infiles(use_image).name],'r');
trialimg = fread(fileID);
fclose(fileID);
trialimg = reshape(trialimg,[Nrows,Ncols]);
%invert the image if necessary (the peakfinding routine looks for bright
%features on a dark background)
if invert
    trialimg = (2^bit_depth -1)-trialimg;
end

%band-pass the image
bpimg = bpass(trialimg,b_lnoise,b_object_d,b_threshold);
%coarse peak finding
pk = pkfnd(bpimg,pk_thres,pk_object_d);
%fine peak finding
cnt = cntrd(bpimg,pk,cnt_object_d,show_features);
%mass-cut feature: remove features that have an integrated intensity (a "mass") smaller than a certain threshold
mcfeat = cnt(:,3)>masscut; 
cnt = cnt(mcfeat,:);

%% Check the output

% figure(2);colormap('gray'), image(bpimg);
% figure(3);plot(cnt(:,3),cnt(:,4),'ro'); %Check the scatterplot of feature mass vs feature radius of gyration. It can be useful to decide on the threshold values, e.g. masscut
% figure(4);histogram(mod(cnt(:,1),1),10);

imagesc(trialimg); colormap gray
hold on
plot(cnt(:,1),cnt(:,2),'*r')
hold off











