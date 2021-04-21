%Description: 
% This file demonstrates converting 4.2.07.tiff image to Huffman optimized
% JPEG baseline complaint image using pxl2jpgencoder, and save the result
% in the result folder
%Example usage: main
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function main
%% Quantization table definition
s_factors= [2,2;1,1;1,1]; % sub sampling factor: s_factors =[Lum_H,Lum_V;Cb_H,Cb_V;Cr_H,Cr_V] default is [2,2;1,1;1,1]
q_factor = 50; % quantization factor which can vary between 1~100, where 100=highest quality and 1=lowest quality
temp=load('recommended_q_table.mat');
q_table=temp.q_table;
temp=load('recommended_q_table_chm.mat');
q_table_chm=temp.q_table_chm;
if q_factor <50
    scaling_factor = 5000/q_factor;   
else
    scaling_factor = 200 - q_factor*2;
end
q_table = floor(q_table*scaling_factor/100 + 0.5);
q_table(:,:,2) = floor(q_table_chm*scaling_factor/100 + 0.5);
q_table(:,:,3) =q_table(:,:,2);
if q_factor == 100
    q_table=ones(8);
    q_table(:,:,2) =ones(8);
end

%% Prepare image input
image_fullname='4.2.07.tiff'; %use image from test_image folder
optimize_flag=1; %Huffman table optimization flag
original_image=imread(image_fullname);
JFIF_stream=pxl2jpgencoder(original_image,optimize_flag,q_table,s_factors);

%% Write JFIF_stream
[~, name,fmt]=fileparts(image_fullname);
if isequal(lower(fmt),'.jpg') || isequal(lower(fmt),'.jpeg')
        fid = fopen([ name '_re_encoded.jpg'], 'w'); % if a jpeg file has been compressed again, don't save it as the same name to prevent overwriting the original
else
        fid = fopen([ name  '.jpg'], 'w');
end
if fid < 0
    error('Failed to open data file for write');
end
fwrite(fid,JFIF_stream,'uint8');
fclose(fid);

