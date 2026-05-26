function [imgsHeight,imgsWidth]=convert_frames_to_bin(imgs_name,imgs_extension,indir,outdir,isRGB,outchannels)
%Script to save input frames AS BINARY, into a dedicated folder. 
%
%IF the frames are RGB, then set the variable "isRGB" to 1. You will need to
%decide which channels you want to average over, using the array
%"outchannels" (outchannels=[2] means "keep only the G channel";
%outchannels=[2,3] means "average channels G and B", etc.).
%
%INPUT:  
%   [imgs_name, imgs_extension] : basename and extension of the images
%   (e.g. if the images are called "myimage_234.png", then imgs_name would
%   be equal to "myimage_", while imgs_extension would be equal to ".png") 
%
%   indir : complete path to the input images directory
%
%   outdir : output directory where the binary files will be stored
%
%   isRGB : 1 if the images are RGB, 0 otherwise
%
%   outchannels : array with the channels to be averaged over.(e.g.
%   outchannels=[2] means "keep only the G channel"; outchannels=[2,3]
%   means "average channels G and B", etc.).  
%
%OUTPUT: 
%   [imgsHeight,imgsWidth]: number of rows and columns of the images.
%   ->The program creates a directory containing binary files.
%
%HISTORY:
%   27 Nov 2024. MP: Created from extract_frames_bin. Saving files as
%   binary allows them to be read as binary with the function "fread",
%   which is faster than e.g. reading a TIFF file with imread.


myimages = dir([indir,imgs_name,'*',imgs_extension]);
NumFrames = size(myimages,1);
[~,startnum,~] = fileparts(myimages(1).name);
startnum = str2num(startnum(length(imgs_name)+1:end)); %this is the initial number of the series of images
myformat = ['%0',num2str(ceil(log10(NumFrames))),'.f'];

if isRGB==1
    for ii=1:NumFrames
        if mod(ii,200)==0
            disp(['Binary frames extraction. Done ',num2str(ii),' out of ',num2str(NumFrames)]);
        end
        frame = imread([indir,myimages(ii).name]);
        imgseq_number = ii-1+startnum; %if the original images start at "startnum" and end at "startnum+NumFrames-1", I want the files that I save to keep those numerals
        fileID = fopen([outdir,imgs_name,'_',num2str(imgseq_number,myformat),'.bin'],'w');
        fwrite(fileID,uint8(mean(frame(:,:,outchannels),3)));
        fclose(fileID);
    end

else
    for ii=1:NumFrames
        if mod(ii,200)==0
            disp(['Binary frames extraction. Done ',num2str(ii),' out of ',num2str(NumFrames)]);
        end
        frame = imread([indir,myimages(ii).name]);
        imgseq_number = ii-1+startnum;%if the original images start at "startnum" and end at "startnum+NumFrames-1", I want the files that I save to keep those numerals
        fileID = fopen([outdir,imgs_name,'_',num2str(imgseq_number,myformat),'.bin'],'w');
        fwrite(fileID,uint8(mean(frame(:,:,outchannels),3)));
        fclose(fileID);
    end

end

[imgsHeight,imgsWidth]=size(frame);
disp('Binary frames extraction completed.');

end




