function quantized_coeff=dpcm(quantized_coeff)
[image_height,image_width]=size(quantized_coeff);
previous_value=0;
for i1=1:8:image_height
    for j1=1:8:image_width
        quantized_coeff(i1,j1)=quantized_coeff(i1,j1)-previous_value;
        previous_value=quantized_coeff(i1,j1);
    end
end
