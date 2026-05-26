% This script load the image files and output a movie showing tracks of the
% each cell in the frame. The duration of the movie can be adjused by
% provding appropriate number of frames.

%% Clear all variables and close all figures; declaration of auxiliary variables
close all;
clear;

%%Image processing parameters (these parameters will be used for particle's position)
% One should run the code for a single frame and adjust these parameter. After that run for all frames.
b_thres = 1;
b_object_d=19;
pk_thres = 30;
pk_object_d = 19;
cnt_object_d = 21;

%% Folder management
%%Path of the folder containing images (Data input folder)
InputFolder = 'E:\data_analysis_kubra\photokinesis\control1';

%%Path of the folder to save the output data (Data output folder)
OutputFolder = 'E:\data_analysis_kubra\photokinesis\movies';

%% Get the total number of images
ImgFile=dir(fullfile(InputFolder,'*.png'));
numImages =size(ImgFile,1);


%% sorting the image file name frame-wise

ImgFiles0=cell(1, numImages);
for i = 1:numImages
    ImgFiles0{i} = erase(ImgFile(i).name,'.png');
end

[~,ix] = sort(str2double(extract(ImgFiles0,digitsPattern+textBoundary)));
ImgFiles1= ImgFiles0(ix);
ImgFilesSrt=cell(1, numImages);
for i = 1:numImages
    ImgFilesSrt(i) = append(ImgFiles1(i)','.png');
end

files = cell(1, numImages);
for i = 1:numImages
    files{i} = strcat(InputFolder,'\',ImgFilesSrt{1,i});
end
%% image processing and position finding

tic %tic toc command shows the elapsed time in the  execution of the code lies within
N=1;
frame = 0;
for k=1:1:100 %% provide appropriate number of frames for the duration of the movie
    disp(k);
    clearvars I1 b pk cnt I11
    I11 = imread(files{k});
    %I11 = imread(strcat(InputFolder,'\image_',num2str(frame),'.tiff'));
    %figure(1); imshow(I11); hold on;
    I1 = imcomplement(I11);%65536-I11;
    %figure(2);imshow(I1);
    %%
    b = bpass(I1,b_thres,b_object_d);
    %figure (3);colormap('gray'), image(b);
    pk = pkfnd(b,pk_thres,pk_object_d);
    cnt = cntrd(b,pk,cnt_object_d);
    %figure(4); imshow(I11); hold on; plot(pk(:,1),pk(:,2),'bo'); hold on;plot(cnt(:,1),cnt(:,2),'ro');
    %figure(5);colormap('gray'), imagesc(I11); hold on;plot(pk(:,1),pk(:,2),'bo'); hold on;plot(cnt(:,1),cnt(:,2),'ro');
    %figure(6);histogram(mod(cnt(:,1),1),10);
    %%

    length1 = size(cnt,1);

    M(N:N+length1-1,1) = cnt(:,1);
    M(N:N+length1-1,2) = cnt(:,2);
    M(N:N+length1-1,3)= frame;
    N=N+length1;

    %% Save frames for the movie (this will save as image stacks, to view it as a movie use ImageJ/Fiji software)

    figure ('visible', 'off');
    colormap('gray'), imagesc(I11); hold on;
    plot(M(:,1),M(:,2),'ko','LineWidth',0.2,'MarkerEdgeColor','r','MarkerFaceColor',[.49 1 .63],'MarkerSize',1) ;
    plot(cnt(:,1),cnt(:,2),'bo','LineWidth',0.2,'MarkerSize',6);
    printname=strcat('\image_',num2str(k));fullname=fullfile(OutputFolder,printname);
    saveas(gcf,strcat(fullname,'.png'));
    close;

    %%

    frame = frame+1;
end

toc
