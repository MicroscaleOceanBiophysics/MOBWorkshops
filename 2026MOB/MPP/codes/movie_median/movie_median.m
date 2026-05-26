function medimg = movie_median(movie,imgsdir,nrows,ncols,bpp,maxmem)
%Function to extract the median from a collection of frames, saved as
%binary arrays. The program gets the list of files, which corresponds to
%the number of frames (nframes), divides the images in an appropriate
%number of blocks, and calculates the median in time for each block. This
%is then saved in the corresponding block of the median image. This is done
%to make sure that the memory usage does not exceed a set threshold (approx
% "maxmem" number of Gbits). Note that the binarised images are saved as 1D
% arrays. The median calculation is done on these 1D arrays and the median
% array is then reshaped into the correct shape at the end of the program.
%
%INPUT:
%
%   movie: name of the movie, without extension (e.g. for "mymovie.avi" it
%   would be "mymovie").
%
%   imgsdir: directory where the bin image files are stored. The program
%   expects that the names of the image files starts with the value of the
%   variable "movie" and ends with ".bin"
%
%   nrows, ncols: number of rows and columns of the actual images.
%
%   bpp: bits per pxl (e.g. for a uint8 image, bpp would be equal to 8).
%
%   maxmem: maximum number of Gbits that can be used (approximate)
%
%
%OUTPUT: 
%   
%   medimg: median image (nrowsXncols, same data type as the binary
%   arrays).
%
%
%HISTORY:
%   12 Feb 2024. MP: Created.
%  

datatype = 'uint8'; %data type of the binary files.
infiles = dir([imgsdir,movie,'*.bin']); %get the list of frames
npxls = nrows*ncols;    %number of elements in the binary arrays (individual images)
medimg = zeros([1,npxls]);    %set the storage for the median image
nframes = length(infiles); %number of frames in the movie

%% Set the boundaries of the blocks of pixels. 
winsz = floor(bpp*maxmem*10^9./nframes); %Sets the sizw of the block of pixels such that storing in memory that block for all the frames altogether, occupies at most maxmem Gbits
blocks = [1:winsz:npxls]; 
% Given the way the for loop below works, we need the array "blocks" to
% either end with the value "npxls+1". If by any chance npxls is a multiple
% of winsz, then we set that value to npxls+1. If npxls is NOT a multiple
% of winsiz, then this means that the array blocks ends with a value that
% is smaller than npxls. We then append at the end the value "npxls+1". In
% both cases, this ensures that in the for loop that cycles through the
% blocks, the last block ends at the end of the array (array position
% "npxls").
if blocks(end)==npxls
    blocks(end)=npxls+1;
else
    blocks = [blocks,npxls+1];
end

%% Calculate the median
for ii = 1:(length(blocks)-1) %cycle through the different blocks
    tmpblock = zeros(nframes,(blocks(ii+1)-blocks(ii)),datatype); %storage for the block on which we will calculate the median
    for tt = 1:nframes %cycle through the frames to read the corresponding block for each frame
        if mod(tt,250)==0
            disp(['Done ',num2str(tt),' out of ',num2str(nframes),' for block ',num2str(ii),' of ',num2str(length(blocks)-1)]);
        end
        %Operating with binary files, one needs to open them for reading,
        %read them, and then close the files
        fileID = fopen([imgsdir,infiles(tt).name],'r'); %open the file for reading
        tmparray = fread(fileID); %read the array (the individual image)
        fclose(fileID); %close the file that has been previously opened for reading 
        tmpblock(tt,:) = tmparray(blocks(ii):(blocks(ii+1)-1)); %copy the relevant block in the correct position in the storage array tmparray
    end
    disp(['Calculating median for block ',num2str(ii),' of ',num2str(length(blocks)-1)]);
    medimg(blocks(ii):(blocks(ii+1)-1)) = median(tmpblock,1);
    disp(['Completed median for block ',num2str(ii),' of ',num2str(length(blocks)-1)]);
end

medimg = reshape(medimg,[nrows,ncols]); %reshape the median array to the shape of the original image (the one in the movie... not the binary image file)

end
