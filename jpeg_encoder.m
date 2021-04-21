function jpeg_encoder(image_fullname,
image=zeros(8,8);
[image_height, image_width, number_of_components]=size(image);
image_stream = [];

%% JFIF data;

% SOI
SOI = hex2dec(["FF" "D8"]);

% APP segment data
% This does not change unless explicit thumbnails are required =>
% not supported anymore
APP_segment = hex2dec(["FF" "E0", "00" "10" "4A" "46" "49" "46" "00" "01" "01" "00" "00" "01" "00" "01" "00" "00"]);

% Quantization table
q_table=zeros(8,8);
q_table_precision_id = "00"; %(xy), where x is 8 bit precision=0 16 bit precision=1, and y is q_table id 0~3
q_table_segment=q_table_JIFF(q_table_precision_id,q_table);
if number_of_components == 3
    % Chrominance quantization table
    q_table_chm=zeros(8,8);
    q_table_precision_id_chm = "01"; %(xy), where x is 8 bit precision=0 16 bit precision=1, and y is q_table id 0~3
    q_table_segment=[q_table_segment q_table_JIFF(q_table_precision_id_chm,q_table_chm)];
end

% DC Huffman table
h_table_DC_lum_id="00"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
h_table_DC_lum=zeros(1,8);
h_table_segment=h_table_JIFF(h_table_DC_lum_id,h_table_DC_lum);

% AC Huffman table
h_table_AC_lum_id="10"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
h_table_AC_lum=zeros(1,8);
h_table_segment=[h_table_segment h_table_JIFF(h_table_AC_lum_id,h_table_AC_lum)];

if number_of_components == 3
    % Chrominance DC Huffman table
    h_table_DC_chm_id="01"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
    h_table_DC_chm=zeros(1,8);
    h_table_segment=[h_table_segment h_table_JIFF(h_table_DC_chm_id,h_table_DC_chm)];
    
    % Chrominance AC Huffman table
    h_table_AC_chm_id="11"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
    h_table_AC_chm=zeros(1,8);
    h_table_segment=[h_table_segment h_table_JIFF(h_table_AC_chm_id,h_table_AC_chm)];
end

% SOF
bits_precision=8; %baseline is 8
% number_of_components=1; % 1 or 3
if number_of_components==1
    component_q_info=["01" "11" "00"]; % [x y z], where x is Y=01 Cb=02 Cr=03, y is sampling factor, z is q_table id(not q_table_precision_id)
else
    component_q_info=["01" "22" "00", "02" "11" "01", "03" "11" "01"];
end
SOF_segment_length = 2+1+2+2+1+number_of_components*3;
SOF_segment=[hex2dec(["FF" "C0"]) dec2uint8(SOF_segment_length,2) bits_precision dec2uint8(image_height,2) dec2uint8(image_width,2) number_of_components hex2dec(component_q_info)];

% SOS
SOS_segment_length = 2+1+number_of_components*2+3;
component_huffman_info=["01" "00"]; % [x yz], where x is Y=01 Cb=02 Cr=03, y is huffmantable id for DC, and Z is huffmantable id for AC
component_huffman_info_color=["01" "00", "02" "11", "03" "11"];
SOS_segment=[hex2dec(["FF" "DA"]) dec2uint8(SOS_segment_length,2) number_of_components hex2dec(component_huffman_info) hex2dec(["00" "3F" "00"])];

% JFIF
JFIF_stream = [SOI APP_segment q_table_segment h_table_segment SOF_segment SOS_segment bytestuffing(image_stream)];

%% Write JFIF_stream
fid = fopen([img_name '.jpg'], 'w');
if fid < 0
    error('Failed to open data file for write');
end
fwrite(fid,JFIF_stream,'uint8');
fclose(fid);

end

function q_table_segment=q_table_JIFF(q_table_number,q_table)
v_quantization_table=reshape(q_table,1,[]);
quantization_table_segment_length = 2 + 1 + length(v_quantization_table);
q_table_segment=[hex2dec(["FF" "DB"]) dec2uint8(quantization_table_segment_length,2) hex2dec(q_table_number) v_quantization_table];
end

function h_table_segment=h_table_JIFF(h_table_number,h_table)
huffmantable_code = reshape(h_table,1,[]);
huffmantable_frequency = reshape(h_table,1,[]);
huffman_table_segment_length = 2 + 1 + length(huffmantable_code) + length(huffmantable_frequency);
h_table_segment=[hex2dec(["FF" "C4"]) dec2uint8(huffman_table_segment_length,2) hex2dec(h_table_number) huffmantable_frequency huffmantable_code];
end



% function SOS_segment=SOS_JIFF
%  SOS_segment_length =
%  SOS_segment=
% end

function uint8_number = dec2uint8(decimal_number,max_digits)
x=decimal_number;
uint8_number = zeros(1,max_digits);
remainder=mod(x,256);
quotient=(x-remainder)/256;
digits=1;
uint8_number(digits)=remainder;
x=quotient;
while quotient ~=0
    remainder=mod(quotient,256);
    quotient=(x-remainder)/256;
    x=quotient;
    digits=digits+1;
    uint8_number(digits)=remainder;
end
uint8_number=uint8(uint8_number(end:-1:1));
if max_digits < length(uint8_number)
    disp('max digits exceeded')
end
end

function new_stream=bytestuffing(stream)
new_stream=zeros(1,length(stream)+sum(stream==255));
j=0;
for i=1:length(stream)
    new_stream(i+j) = stream(i);
    if stream(i) == 255
        j=j+1;
    end
end
end