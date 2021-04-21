%Description: 
% Pass an image and encodes it to baseline JPEG. 
% This also writes the file as a JFIF compliant JPEG. 
% If JPEG image is passed, it will do lossy JPEG compression again. 
% If you want to just optimize, use jpg2jpgencoder.m
%Input: image file readable by matlab. h_optimize_flag=1: optimizes huffman table
%Output: JPEG baseline JFIF compliant image. Readable anywhere
%Example usage: see main.m for example
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function [JFIF_stream]=pxl2jpgencoder(original_image,h_optimize_flag,q_table,s_factors)

%Preprocess image
[image_height,image_width,number_of_components]=size(original_image);
if number_of_components==3
    original_image = jpeg_ycbcr(original_image); %Note: do not use matlab-built in ycbcr code as it is different than the one specified in the stanadard
end

%% intialize variables
% Quantization table
if isempty(q_table)
    temp=load('recommended_q_table.mat');
    q_table=temp.q_table;
end

if isempty(q_table) && number_of_components == 3
    temp=load('recommended_q_table_chm.mat');
    q_table(:,:,2)=temp.q_table_chm;
end

% Chroma Sampling factors
% This scheme supports:
% s_factors =[Lum_H,Lum_V;Cb_H,Cb_V;Cr_H,Cr_V] default is [2,2;1,1;1,1]
if number_of_components == 1
    s_factors=[1 1];
else
    q_table(:,:,3)=q_table(:,:,2);
    if isempty(s_factors)
        s_factors=[2,2;1,1;1,1];
    end
end

%% Chroma subsampling [h v] h=horizontal v=vertical
h_max = max(s_factors(:,1));
v_max = max(s_factors(:,2));
image_encoded_size=zeros(3,2);
encoded_image=cell(number_of_components,1);
for channel = 1: number_of_components
    image_encoded_size(channel,1)=ceil(image_height*s_factors(channel,2)/v_max);
    image_encoded_size(channel,2)=ceil(image_width*s_factors(channel,1)/h_max);
    % subsampling chroma components based on the sampling factor
    if not(isequal(size(original_image(:,:,channel)),image_encoded_size(channel,:)))
        encoded_image{channel}=chroma_sampling(original_image(:,:,channel),image_encoded_size(channel,:));
    else
        encoded_image{channel}=original_image(:,:,channel);
    end
end


%% image resize: Determine the image sizes and add columns and rows to make the blocksize divisible by 8 by 8
for channel=1:number_of_components
    if mod(image_encoded_size(channel,1),8)~=0
        encoded_image{channel}=[encoded_image{channel};repmat(encoded_image{channel}(end,:),8-mod(image_encoded_size(channel,1),8),1)];
    end
    if mod(image_encoded_size(channel,2),8)~=0
        encoded_image{channel}=[encoded_image{channel} repmat(encoded_image{channel}(:,end),1,8-mod(image_encoded_size(channel,2),8))];
    end
    %Calculate the new size of the images
    [image_encoded_size(channel,1), image_encoded_size(channel,2)]=size(encoded_image{channel});
end

%% Levelshift by 128
for channel=1:number_of_components
    encoded_image{channel}=double(encoded_image{channel})-128;
end
quantized_coeff=cell(number_of_components,1);

%% DCT quantization
for channel = 1:number_of_components
    quantized_coeff{channel}=dct_quantization(encoded_image{channel},q_table(:,:,channel));
end

%% Partial mcu completion
if number_of_components ==3
    % Partial mcu completion
    % horizontal/width
    for channel = 1:number_of_components
        if s_factors(channel,1)>1 
            number_replications=8*s_factors(channel,1)-mod(image_encoded_size(channel,2),8*s_factors(channel,1));
            if number_replications~=8*s_factors(channel,1)
                blocks_for_replication=repmat(zeros(image_encoded_size(channel,1),8),1,number_replications/8);
                quantized_coeff{channel}=[quantized_coeff{channel} blocks_for_replication];
            end
        end
        %Recalculate the size before creating more partial MCUs relative to
        %vertical/height
        [image_encoded_size(channel,1),image_encoded_size(channel,2),~]=size(quantized_coeff{channel});
    end
    
    % Partial mcu completion
    % vertrical/height
    for channel = 1:number_of_components
        if s_factors(channel,2)>1 %vertical/height
            number_replications=8*s_factors(channel,2)-mod(image_encoded_size(channel,1),8*s_factors(channel,2));
            if number_replications~=8*s_factors(channel,2)
                blocks_for_replication=repmat(zeros(8,image_encoded_size(channel,2)),number_replications/8,1);
                quantized_coeff{channel}=[quantized_coeff{channel}; blocks_for_replication];
            end
        end
        %Recalculate the size vertical/height after partial mcus have been
        %added
        [image_encoded_size(channel,1),image_encoded_size(channel,2),~]=size(quantized_coeff{channel});
    end
end

%% Zig-zag reordering
% For chroma subsampled channels, MCU formation is different than grayscaled version, so the ordering needs to change based on the sampling factor
zig_zag_coeff=cell(number_of_components,1);
if number_of_components ==1
    %zigzag reshape 
    zig_zag_coeff{1}=zig_zag_reshape(quantized_coeff{1});
    %dpcm
    zig_zag_coeff{1}(:,1)=zig_zag_coeff{1}(:,1)-[0;zig_zag_coeff{1}(1:end-1,1)]; %no need to chromasample for bw version
elseif number_of_components ==3
    for channel =1:number_of_components
        %zigzag reshape
        zig_zag_coeff{channel}=zig_zag_reshape(quantized_coeff{channel});
        %reordering based on chroma sampling
        zig_zag_coeff{channel}=chroma_sampling_reorder(zig_zag_coeff{channel},image_encoded_size(channel,1),image_encoded_size(channel,2),s_factors(channel,:));
        %dpcm
        zig_zag_coeff{channel}(:,1)=zig_zag_coeff{channel}(:,1)-[0;zig_zag_coeff{channel}(1:end-1,1)];
    end
end

%% Huffman encoding preprocessing
if number_of_components ==1
    zig_zag_coeff_lu=zig_zag_coeff{1};
    [DC_categories_freq, DC_categories, DC_values]=category_tabulate(zig_zag_coeff_lu(:,1));
    [AC_categories_freq, AC_categories, AC_values]=run_length_tabulate(zig_zag_coeff_lu(:,2:end));
elseif number_of_components ==3
    zig_zag_coeff_lu=zig_zag_coeff{1};
    zig_zag_coeff_cb=zig_zag_coeff{2};
    zig_zag_coeff_cr=zig_zag_coeff{3};
    %luminance statistics
    [DC_categories_freq, DC_categories, DC_values]=category_tabulate(zig_zag_coeff_lu(:,1));
    [AC_categories_freq, AC_categories, AC_values]=run_length_tabulate(zig_zag_coeff_lu(:,2:end));
    %chrominance statistics
    [DC_chm_categories_freq, DC_chm_categories, DC_chm_values]=category_tabulate([zig_zag_coeff_cb(:,1); zig_zag_coeff_cr(:,1)]);
    DC_cb_categories=DC_chm_categories(1:length(zig_zag_coeff_cb(:,1)));
    DC_cr_categories=DC_chm_categories(length(zig_zag_coeff_cb(:,1))+1:end);
    DC_cb_values=DC_chm_values(1:length(zig_zag_coeff_cb(:,1)));
    DC_cr_values=DC_chm_values(length(zig_zag_coeff_cb(:,1))+1:end);
    [AC_chm_categories_freq, AC_chm_categories, AC_chm_values]=run_length_tabulate([zig_zag_coeff_cb(:,2:end);zig_zag_coeff_cr(:,2:end)]);
    AC_cb_categories=AC_chm_categories(1:length(zig_zag_coeff_cb(:,1)),:);
    AC_cr_categories=AC_chm_categories(length(zig_zag_coeff_cb(:,1))+1:end,:);
    AC_cb_values=AC_chm_values(1:length(zig_zag_coeff_cb(:,1)),:);
    AC_cr_values=AC_chm_values(length(zig_zag_coeff_cb(:,1))+1:end,:);
end

% Generate optimized huffman table or use existing tables
if h_optimize_flag == 1
    [h_table_DC_lum] = h_table_gen(DC_categories_freq);
    [h_table_AC_lum] = h_table_gen(AC_categories_freq);
    if number_of_components ==3
        [h_table_DC_chm] = h_table_gen(DC_chm_categories_freq);
        [h_table_AC_chm] = h_table_gen(AC_chm_categories_freq);
    end
elseif h_optimize_flag == 0
    temp=load('recommended_h_table_DC_lum.mat');
    h_table_DC_lum=temp.h_table_DC_lum;
    temp=load('recommended_h_table_AC_lum.mat');
    h_table_AC_lum=temp.h_table_AC_lum;
    if number_of_components ==3
        temp=load('recommended_h_table_DC_chm.mat');
        h_table_DC_chm=temp.h_table_DC_chm;
        temp=load('recommended_h_table_AC_chm.mat');
        h_table_AC_chm=temp.h_table_AC_chm;
    end
end

% Huffman encoding
% scheme based on chroma sampling factor
image_stream=[];
if number_of_components ==1
    image_stream = strings(1,length(zig_zag_coeff_lu(:,1)));
    for i1 = 1:length(zig_zag_coeff_lu(:,1))
        image_stream(i1) = string([char(huffman_encode(DC_categories(i1),DC_values(i1),h_table_DC_lum)) char(huffman_encode(AC_categories(i1,:),AC_values(i1,:),h_table_AC_lum))]);
    end
elseif number_of_components ==3
    % minimum coding unit (mcu)
    image_stream = strings(1,length(zig_zag_coeff_lu(:,1))/s_factors(1,1)/s_factors(1,2));
    i2=0;
    i3=0;
    i4=0;
    
    for i1=1:s_factors(1,1)*s_factors(1,2):length(zig_zag_coeff_lu(:,1))
        mcu_l='';
        for j1=1:s_factors(1,1)*s_factors(1,2)
            mcu_l=[mcu_l char(huffman_encode(DC_categories(i1+j1-1),DC_values(i1+j1-1),h_table_DC_lum)) char(huffman_encode(AC_categories(i1+j1-1,:),AC_values(i1+j1-1,:),h_table_AC_lum))];
        end
        mcu_cb='';
        for j1=1:s_factors(2,1)*s_factors(2,2)
            i2=i2+1;
            mcu_cb=[mcu_cb char(huffman_encode(DC_cb_categories(i2),DC_cb_values(i2),h_table_DC_chm)) char(huffman_encode(AC_cb_categories(i2,:),AC_cb_values(i2,:),h_table_AC_chm))];
        end
        mcu_cr='';
        for j1=1:s_factors(3,1)*s_factors(3,2)
            i3=i3+1;
            mcu_cr=[mcu_cr char(huffman_encode(DC_cr_categories(i3),DC_cr_values(i3),h_table_DC_chm)) char(huffman_encode(AC_cr_categories(i3,:),AC_cr_values(i3,:),h_table_AC_chm))];
        end
        i4=i4+1;
        image_stream(i4) =string([mcu_l, mcu_cb, mcu_cr]);
    end
end

%% Change image_stream from vector of strings to vector of chars
image_stream=char(strjoin(image_stream));
image_stream(image_stream==' ')=[];

%% Byte alignment
if mod(length(image_stream),8) ~=0
    alignment=num2str(ones(1,8-mod(length(image_stream),8)));
    alignment(alignment==' ')=[];
    image_stream= [image_stream,alignment];
end

%% Convert binary to unsigned 8bit
numbytes=length(image_stream)/8;
image_stream_8_bit_code= zeros(1,numbytes);
s=0;
for count2=1:8:numbytes*8
    s=s+1;
    image_stream_8_bit_code(1,s)=bin2dec(image_stream(count2:count2+7));
end


%% JFIF encoding
if number_of_components == 1 %grayscaled image, remove huffmantable and quantization table for the chrominance signal
    JFIF_stream=JFIF_encoder(image_stream_8_bit_code,image_height,image_width,number_of_components,q_table(:,:,1),[],h_table_DC_lum,h_table_AC_lum,[],[], s_factors);
else %color image
    JFIF_stream=JFIF_encoder(image_stream_8_bit_code,image_height,image_width,number_of_components,q_table(:,:,1),q_table(:,:,2),h_table_DC_lum,h_table_AC_lum,h_table_DC_chm,h_table_AC_chm, s_factors);
end

end





