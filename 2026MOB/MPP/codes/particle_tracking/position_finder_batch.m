% This script load the image files and generate a matrix
% 'Trajectories.mat'containing trajectories of all cells.The 1st, 2nd, 3rd
% and 4th coloumn in 'Trajectories.mat' represents the x, y, frame number and cell id
% respectively.

%% Clear all variables and close all figures; declaration of auxiliary variables
close all;
clear;

%%input variables
basepath='E:/data_analysis_kubra/'; %path to the parent directory of the movie dir
basedir='diffimgs/'; %name of the directory where the raw experiments are stored
imgsdir = 'control2/'; %name of the directory with the images to analyse
imgs_name = 'diff_image'; %base name of the images
resultsdir = 'tracking/';

%%Image parameters. We need to specify these if we use binary files
Nrows = 2048;
Ncols = 2048;
bit_depth = 8;

%Storage variables
NP = []; %This will store the number of particles for the different frames
all_positions = [];

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

%% Particle Tracking parameters
Max_Disp_pixel = 5;% Maximum distance a cell can move from one frame to the next
param.mem =0; %Number of frames a feature can disappear for, and still be remembered. 
param.good=250; %Minimum length of a good trajectory
param.dim=2; %dimensionality of the space where the features move (for a movie, this is 2 dimensions)
param.quiet=0; %Set to 0 to mute the command-line output of the tracking routine.


%% Folder management and input files list
%Path of the folder containing images (Data input folder)
InputFolder = [basepath,basedir,imgsdir];
OutputFolder = [basepath,resultsdir,imgsdir];
if ~exist(OutputFolder, 'dir')
    statusmk = mkdir(OutputFolder);
else
    disp('Output Folder already present. You might be overwriting the results.');
end

%get the list of images
infiles = dir([InputFolder,imgs_name,'*.bin']);
numImages = length(infiles);

%% Featuring Step

for kk=1:numImages
    if mod(kk,100)==0
        disp(['Doing featuring step for image ',num2str(kk),' out of ',num2str(numImages)]);
    end
    fileID = fopen([InputFolder,infiles(kk).name],'r');
    tmpimg = fread(fileID);
    fclose(fileID);
    tmpimg = reshape(tmpimg,[Nrows,Ncols]);
    if invert
        tmpimg = (2^bit_depth -1)-tmpimg;
    end
    %band-pass the image
    bpimg = bpass(tmpimg,b_lnoise,b_object_d,b_threshold);
    %coarse peak finding
    pk = pkfnd(bpimg,pk_thres,pk_object_d);
    %fine peak finding
    cnt = cntrd(bpimg,pk,cnt_object_d,show_features);
    %mass-cut feature: remove features that have an integrated intensity (a "mass") smaller than a certain threshold
    mcfeat = cnt(:,3)>masscut;
    cnt = cnt(mcfeat,:);

    %store the number of particles in the current frame
    NP = [NP;[kk,size(cnt,1)]];
    %append centroid of all cells in a frame to a single matrix
    all_positions = [all_positions;[cnt,0*cnt(:,1)+double(kk)]];
end

%% Tracking
Trajectories = track(all_positions(:,[1,2,5]),Max_Disp_pixel,param);% use if track.m function to link the position of cells to create trajectory

%% Save the results
save([OutputFolder,'cells_per_frame.mat'],"NP");
save([OutputFolder,'positions.mat'],"all_positions");
save([OutputFolder,'trajectories.mat'],'Trajectories');% save the main matrix containing all trajectories

disp(strcat('Average number of cells in a frame',':', num2str(mean(NP(:,2)))));


