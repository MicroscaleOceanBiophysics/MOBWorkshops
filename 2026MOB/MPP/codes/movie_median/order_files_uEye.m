function order_files_uEye(indir,imgs_name,imgs_extension)
%Function to rename the files in a directory so that they are then ordered
%correctly when read with dir(). The program assumes that the files have
%names like "myfile_123.extension". It renames the files so that the
%numerical part is left-padded with enough zeros to guaranteed that
%alphanumeric ordering will order them in the correct way (increasing
%numbers).
%
%INPUT
%   indir : complete path to the input images directory
%
%   [imgs_name, imgs_extension] : basename and extension of the images
%   (e.g. if the images are called "myimage_234.png", then imgs_name would
%   be equal to "myimage_", while imgs_extension would be equal to ".png") 
%
%OUTPUT
% ---> It modifies the names of files in the directory "indir"
%
%HISTORY
%   27 Nov 2024. MP: Created.


myimages = dir([indir,imgs_name,'*',imgs_extension]);
NumFrames = size(myimages,1);
myformat = ['%0',num2str(ceil(log10(NumFrames))),'.f'];

for ii=1:NumFrames
    [~,img_num,~] = fileparts(myimages(ii).name);
    img_num = str2num(img_num(length(imgs_name)+1:end));
    newname = [imgs_name,num2str(img_num,myformat),imgs_extension];
    if not(strcmp(newname,myimages(ii).name))
        movefile([indir,myimages(ii).name],[indir,newname]);
    end
end


end









