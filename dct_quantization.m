%Description: 
% 2D type 3 DCT transform with quantization. DCT matrix is generated and is
% matrix multiplied to acheive the same result. This results in significantly faster
% calculation, but with slightly reduced accuracy.
%Input: single channel of the image, and the quantization table to be used 
%Output: quantized DCT coefficients %Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021
function quantized_coeff = dct_quantization(image,q_table)
[image_height,image_width]=size(image);
quantized_coeff=zeros(image_height,image_width);
dctmtx_8=dctmtx(8);
for i1=1:8:image_height
    for j1=1:8:image_width
        quantized_coeff(i1:i1+7,j1:j1+7)=round(dctmtx_8*(image(i1:i1+7,j1:j1+7))*dctmtx_8'./q_table);
%         quantized_coeff(i1:i1+7,j1:j1+7)=round(dct2(image(i1:i1+7,j1:j1+7))./q_table);
    end
end

