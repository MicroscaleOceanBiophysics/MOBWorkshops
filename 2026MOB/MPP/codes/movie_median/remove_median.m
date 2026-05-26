function remove_median(imgs_name,indir,outdir,medimg,datatype,format,maxframes)
%Function to remove an image (medimg, uint8) from a series of other images
%(uint8). All of the arrays are of uint8 data type. The series of images
%should be *saved as binary files*. This means that they are read as 1D
%arrays of number of elements equal to the total number of elements of the
%image "medimg". 
%Before subtracting, the arrays are converted to datatype double. This is
%done to avoid clipping. The difference array is then shifted to nonnegative
%values by adding 255 to all the pixels. It is then either saved as a
%uint16, or resampled to a uint8. Notice that the latter means losing
%information. The arrays is either saved as a binary, in which case the
%saved file does not contain itself information on the shape of the
%original image, or as other format (TIFF, PNG, JPG...). This image format
%should be compatible with the Matlab function "imwrite".
%
%
%
%INPUT: 
%   movie: name of the movie, without extension (e.g. for "mymovie.avi" it
%   would be "mymovie").
%   indir: directory where the bin image files are stored. The program
%   expects that the names of the image files starts with the value of the
%   variable "movie" and ends with ".bin". These should be of datatype
%   uint8.
%   outdir : output directory where the difference files will be stored
%   medimg: median image (nrowsXncols, datatype uint8)
%   datatype:
%   format: format for the saved images. Should be either ".bin" if you
%   want to save the files in binary, or one of the formats thatcan be
%   written by imwrite (e.g. ".tiff").
%   maxframes = number of frames from which to remove the median. Choose a
%   value <0 to set to "all frames". This is used in case one wants to
%   limit this step to a smaller number of frames (imwrite is slow!)
%
%
%OUTPUT:
%   The function saves the images in the folder "outdir"
%
%
%HISTORY:
%   19 Feb 2024. Marco Polin: Created.
%   27 Nov 2024. MP: Adapted to be used with a list of image files from the
%   beginning (so... no initial .avi movie); added input variable
%   "maxframes" in case one wants to remove the median only from a subset
%   of the whole movie.
%


[nrows,ncols] = size(medimg); %get the size of the images
npxls = nrows*ncols;    %number of pixels in the individual image
medimg = double(medimg);    %we will do the subtractionusing double datatype
medimg = reshape(medimg,[npxls,1]); %the images we read are binary, which means that they are read as 1D arrays. Instead of reshaping each of them to their 2D shape, we reshape the median image to the same 1D format and subtract that

infiles = dir([indir,imgs_name,'*.bin']); %get the list of frames
nframes = length(infiles); %number of frames in the movie
if maxframes<0
    maxframes=nframes;
end

myformat = ['%0',num2str(ceil(log10(nframes))),'.f']; %format for the numeral portion of the name of the output file. E.g., for a file "mymovie_0001.tiff" it would be the formatting of the "0001" part. the log10() part, calculates how many digits I need in the numeral format, in order to accommodate all of the frames.

%% If I want to save with datatype uint16
if datatype == "uint16"
    if format == ".bin" %if I want to save my data in binary, the variable "format" should be equal to the string ".bin"
        for ii=1:maxframes
            if mod(ii,50)==0
                disp(['Median removal. Done ',num2str(ii),' out of ',num2str(nframes)]);
            end
            fileID = fopen([indir,infiles(ii).name],'r');
            tmpimg = fread(fileID);
            fclose(fileID);
            diffimg = (double(tmpimg)-medimg);
            diffimg =(diffimg+255);
            fileID = fopen([outdir,'diff_',imgs_name,num2str(ii,myformat),format],'w');
            fwrite(fileID,uint16(diffimg));
            fclose(fileID);
        end
    else %if I want to save my data in another format (not bin). E.g. to save the images as TIFF, the variable "format" should be equal to the string ".tiff"
        for ii=1:maxframes
            if mod(ii,50)==0
                disp(['Median removal. Done ',num2str(ii),' out of ',num2str(nframes)]);
            end
            fileID = fopen([indir,infiles(ii).name],'r');
            tmpimg = fread(fileID);
            fclose(fileID);
            diffimg = reshape(double(tmpimg)-medimg,[nrows,ncols]);
            diffimg =(diffimg+255);
            imwrite(uint16(diffimg),[outdir,'diff_',imgs_name,num2str(ii,myformat),format]);
        end
    end
%% If I want to save as datatype uint8
elseif datatype == "uint8"
    if format == ".bin"
        for ii=1:maxframes
            if mod(ii,50)==0
                disp(['Median removal. Done ',num2str(ii),' out of ',num2str(nframes)]);
            end
            fileID = fopen([indir,infiles(ii).name],'r');
            tmpimg = fread(fileID);
            fclose(fileID);
            diffimg =(double(tmpimg)-medimg);
            diffimg =(diffimg+255)/512.0; %assumes that the original images were uint8
            fileID = fopen([outdir,'diff_',imgs_name,num2str(ii,myformat),format],'w');
            fwrite(fileID,im2uint8(diffimg));
            fclose(fileID);
        end
    else
        for ii=1:maxframes
            if mod(ii,50)==0
                disp(['Median removal. Done ',num2str(ii),' out of ',num2str(nframes)]);
            end
            fileID = fopen([indir,infiles(ii).name],'r');
            tmpimg = fread(fileID);
            fclose(fileID);
            diffimg = reshape(double(tmpimg)-medimg,[nrows,ncols]);
            diffimg =(diffimg+255)/512.0; %assumes that the original images were uint8
            imwrite(im2uint8(diffimg),[outdir,'diff_',imgs_name,num2str(ii,myformat),format]);
        end
    end
else
    disp("Review datatype. It currently can only be uint8 or uint16");
    return
end


end
