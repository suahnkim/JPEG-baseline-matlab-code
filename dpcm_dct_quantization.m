function zig_zag_coeff = dpcm_dct_quantization(image,q_table)
% zig zag ordering
zig_zag=[...
    1 9 2 3 10 17 25 18 11 4 5 12 19 26 ...
    33 41 34 27 20 13 6 7 14 21 28 35 ...
    42 49 57 50 43 36 29 22 15 8 16 23 ...
    30 37 44 51 58 59 52 45 38 31 24 32 ...
    39 46 53 60 61 54 47 40 48 55 62 63 56 64];

[image_height,image_width]=size(image);
quantized_coeff=zeros(image_height,image_width);
zig_zag_coeff=zeros(image_height*image_width/64,64);
dctmtx_8=dctmtx(8);
k=0;
for i1=1:8:image_height
    for j1=1:8:image_width
        quantized_coeff(i1:i1+7,j1:j1+7)=round(dctmtx_8*(image(i1:i1+7,j1:j1+7))*dctmtx_8'./q_table);
%         k=k+1;
%         zig_zag_coeff(k,:)=TQ(zig_zag);
    end
end

% Apply DPCM
zig_zag_coeff(:,1)=zig_zag_coeff(:,1)-[0;zig_zag_coeff(1:end-1,1)];
end