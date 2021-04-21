%Description: 
% Pass an RGB matrix (n x m x 3) and converts it to YCbCr matrix (n x m x 3).  
% Note that JPEG uses a specific YCbCr conversion which is different from
% built-in MATLAB function ycbcr. 
%Input: RGB matrix
%Output: YCbCr matrix
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function ycbcr=jpeg_ycbcr(rgb)
rgb=double(rgb);
ycbcr(:,:,1)=(0.299*rgb(:,:,1))+(0.587*rgb(:,:,2))+(0.114*rgb(:,:,3))+0.5;
ycbcr(:,:,2)=-0.168735892*rgb(:,:,1)-0.331264108*rgb(:,:,2)+0.5*rgb(:,:,3)+128-0.5;
ycbcr(:,:,3)=0.5*rgb(:,:,1)-0.418687589*rgb(:,:,2)-0.081312411*rgb(:,:,3)+128-0.5;
ycbcr=floor(ycbcr);
