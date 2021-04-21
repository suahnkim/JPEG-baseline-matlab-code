%Description: 
% Reorder quantized DCT coefficients in a zig-zag ordering
%Input: quantized DCT coefficients
%Output: zig-zagged quantized DCT coefficients 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function zig_zag_coeff=zig_zag_reshape(quantized_coeff)
zig_zag=[...
    1 9 2 3 10 17 25 18 11 4 5 12 19 26 ...
    33 41 34 27 20 13 6 7 14 21 28 35 ...
    42 49 57 50 43 36 29 22 15 8 16 23 ...
    30 37 44 51 58 59 52 45 38 31 24 32 ...
    39 46 53 60 61 54 47 40 48 55 62 63 56 64];

[image_height,image_width]=size(quantized_coeff);
zig_zag_coeff=zeros(image_height*image_width/64,64);
k=0;
for i1=1:8:image_height
    for j1=1:8:image_width
        QC=quantized_coeff(i1:i1+7,j1:j1+7);
        k=k+1;
        zig_zag_coeff(k,:)=QC(zig_zag);
    end
end