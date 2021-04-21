%Description: 
% Re-orders the quantized DC coefficients before DPCM based on sampling
% factor. This is a required step due to how MCUs are formed based on the
% sampling factor for color images. Note that there are sampling factor which does not the ordering. 
%Input: zig-zag ordered quantized DCT coefficients
%Output: Re-ordered version based on the sampling factor
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function zig_zag_coeff=chroma_sampling_reorder(zig_zag_coeff,height,width,sampling_factor)
temp_pos=[];
height=height/8;
width=width/8;
if isequal(sampling_factor,[2,2])
    for i1=0:(height-2)/2
        for j1=0:(width-2)/2
            temp_pos=[temp_pos; 2*i1*width+2*j1+1;2*i1*width+2*j1+2;(2*i1+1)*width+2*j1+1;(2*i1+1)*width+2*j1+2];
        end
    end
    zig_zag_coeff=zig_zag_coeff(temp_pos,:);
elseif isequal(sampling_factor,[1,2])
    for i1=0:(height-2)/2
        for j1=0:(width-1)
            temp_pos=[temp_pos; 2*i1*width+j1+1;(2*i1+1)*width+j1+1];
        end
    end
        zig_zag_coeff=zig_zag_coeff(temp_pos,:);
end