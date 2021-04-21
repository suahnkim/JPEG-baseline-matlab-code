%Description: 
% This file demonstrates how to read JPEG and encodes it again as a Huffman optimized JPEG baseline complaint image using jpg2jpgencoder
%Example usage: main
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021
function main_jpg2jpg
%non-JPEG to JPEG

image_fullname='4.2.07.tiff';
optimize=1;
q_factor = 70;

temp=load('recommended_q_table.mat');
q_table=temp.q_table;
temp=load('recommended_q_table_chm.mat');
q_table_chm=temp.q_table_chm;

if q_factor <50
    s_factor = 5000/q_factor;   
else
    s_factor = 200 - q_factor*2;
end
q_table = ceil(q_table*s_factor/100 + 0.5);
q_table_chm = ceil(q_table_chm*s_factor/100 + 0.5);

JFIF_stream=jpg2jpgencoder(image_fullname,optimize,q_table,[],[],q_table_chm,[],[]);

%% Write JFIF_stream
[filepath, name,fmt]=fileparts(image_fullname);
if isequal(lower(fmt),'.jpg') || isequal(lower(fmt),'.jpeg')
    if isempty(filepath)
        fid = fopen([name '_re_encoded.jpg'], 'w'); % if a jpeg file has been compressed again, don't save it as the same name to prevent overwriting the original
    else
        fid = fopen([filepath '/' name '_re_encoded.jpg'], 'w'); % if a jpeg file has been compressed again, don't save it as the same name to prevent overwriting the original
    end
else
    if isempty(filepath)
        fid = fopen([name '.jpg'], 'w');
    else
        fid = fopen([filepath '/' name '.jpg'], 'w');
    end
end
if fid < 0
    error('Failed to open data file for write');
end
fwrite(fid,JFIF_stream,'uint8');
fclose(fid);