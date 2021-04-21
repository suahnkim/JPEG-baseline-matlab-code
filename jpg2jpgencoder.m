function [JFIF_stream]=jpg2jpgencoder(quantized_coeff,q_table,image_height,image_width,h_optimize_flag,s_factors,dpcm_bypassmode)
% Input: quantized coefficients in the original size. h_optimize_flag=1: optimizes huffman table.
% Output: JPEG baseline JFIF compliant image. Readable anywhere.
% Written by Suah Kim, @iaslab.org

%Read image
number_of_components=length(quantized_coeff);
%image size (height,width)

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
% chroma_sampling => 4:4:4;
% s_factors =[Lum_H,Lum_V;Cb_H,Cb_V;Cr_H,Cr_V] default is 4:4:4

if number_of_components == 1
    s_factors=[1 1];
else
    image_encoded_size=zeros(3,2);
    for channel=1:3
        [image_encoded_size(channel,1),image_encoded_size(channel,2),~]=size(quantized_coeff{channel});
    end
%     s_factors=zeros(3,2);
%     for channel=1:3
%         s_factors(channel,:)=[round(image_encoded_size(channel,2)/min(image_encoded_size(:,2))), round(image_encoded_size(channel,1)/min(image_encoded_size(:,1)))];
%     end
end


%% Baseline JPEG

% Partial mcu completion
if number_of_components ==3
    % Partial mcu completion
    % horizontal/width
    for channel = 1:number_of_components
        if s_factors(channel,1)>1
            number_replications=8*s_factors(channel,1)-mod(image_encoded_size(channel,2),8*s_factors(channel,1));
            if number_replications~=8*s_factors(channel,1)
%                 blocks_for_replication=repmat(quantized_coeff{channel}(:,end-7:end,channel),1,number_replications/8);
                blocks_for_replication=repmat(zeros(image_encoded_size(channel,1),8),1,number_replications/8);
                quantized_coeff{channel}=[quantized_coeff{channel} blocks_for_replication];
            end
        end
        %Recalculate the size before creating more partial MCUs relative to
        %vertical/height
        [image_encoded_size(channel,1),image_encoded_size(channel,2),~]=size(quantized_coeff{channel});
    end
    
    zig_zag_coeff=cell(number_of_components,1);
    % Partial mcu completion
    % vertrical/height
    for channel = 1:number_of_components
        if s_factors(channel,2)>1 %vertical/height
            number_replications=8*s_factors(channel,2)-mod(image_encoded_size(channel,1),8*s_factors(channel,2));
            if number_replications~=8*s_factors(channel,2)
%                 blocks_for_replication=repmat(quantized_coeff{channel}(end-7:end,:,channel),number_replications/8,1);
                blocks_for_replication=repmat(zeros(8,image_encoded_size(channel,2)),number_replications/8,1);
                quantized_coeff{channel}=[quantized_coeff{channel}; blocks_for_replication];
            end
        end
        %Recalculate the size vertical/height after partial mcus have been
        %added
        [image_encoded_size(channel,1),image_encoded_size(channel,2),~]=size(quantized_coeff{channel});
    end
end

if number_of_components ==1
    %zigzag reshape
    zig_zag_coeff{1}=zig_zag_reshape(quantized_coeff{1});
    %dpcm
    if dpcm_bypassmode ~= 1
        zig_zag_coeff{1}(:,1)=zig_zag_coeff{1}(:,1)-[0;zig_zag_coeff{1}(1:end-1,1)]; %no need to chromasample for bw version
    end
elseif number_of_components ==3
    for channel =1:number_of_components
        %zigzag reshape
        zig_zag_coeff{channel}=zig_zag_reshape(quantized_coeff{channel});
        %reordering based on chroma sampling
        zig_zag_coeff{channel}=chroma_sampling_reorder(zig_zag_coeff{channel},image_encoded_size(channel,1),image_encoded_size(channel,2),s_factors(channel,:));
        %dpcm
        if dpcm_bypassmode ~= 1
            zig_zag_coeff{channel}(:,1)=zig_zag_coeff{channel}(:,1)-[0;zig_zag_coeff{channel}(1:end-1,1)];
        end
    end
end

% Huffman encoding preprocessing
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
    list_of_categories_DC=(h_table_DC_lum(:,1));
    list_of_categories_AC=(h_table_AC_lum(:,1));
    for i1 = 1:length(zig_zag_coeff_lu(:,1))
        image_stream(i1) = string([char(huffman_encode(DC_categories(i1),DC_values(i1),h_table_DC_lum,list_of_categories_DC)) char(huffman_encode(AC_categories(i1,:),AC_values(i1,:),h_table_AC_lum,list_of_categories_AC))]);
    end
elseif number_of_components ==3
    % minimum coding unit (mcu)
    image_stream = strings(1,length(zig_zag_coeff_lu(:,1))/s_factors(1,1)/s_factors(1,2));
    list_of_categories_DC=(h_table_DC_lum(:,1));
    list_of_categories_AC=(h_table_AC_lum(:,1));
    list_of_categories_DC_chm=(h_table_DC_chm(:,1));
    list_of_categories_AC_chm=(h_table_AC_chm(:,1));
    i2=0;
    i3=0;
    i4=0;
    
    for i1=1:s_factors(1,1)*s_factors(1,2):length(zig_zag_coeff_lu(:,1))
        mcu_l='';
        for j1=1:s_factors(1,1)*s_factors(1,2)
            mcu_l=[mcu_l char(huffman_encode(DC_categories(i1+j1-1),DC_values(i1+j1-1),h_table_DC_lum,list_of_categories_DC)) char(huffman_encode(AC_categories(i1+j1-1,:),AC_values(i1+j1-1,:),h_table_AC_lum,list_of_categories_AC))];
        end
        mcu_cb='';
        for j1=1:s_factors(2,1)*s_factors(2,2)
            i2=i2+1;
            mcu_cb=[mcu_cb char(huffman_encode(DC_cb_categories(i2),DC_cb_values(i2),h_table_DC_chm,list_of_categories_DC_chm)) char(huffman_encode(AC_cb_categories(i2,:),AC_cb_values(i2,:),h_table_AC_chm,list_of_categories_AC_chm))];
        end
        mcu_cr='';
        for j1=1:s_factors(3,1)*s_factors(3,2)
            i3=i3+1;
            mcu_cr=[mcu_cr char(huffman_encode(DC_cr_categories(i3),DC_cr_values(i3),h_table_DC_chm,list_of_categories_DC_chm)) char(huffman_encode(AC_cr_categories(i3,:),AC_cr_values(i3,:),h_table_AC_chm,list_of_categories_AC_chm))];
        end
        i4=i4+1;
        image_stream(i4) =string([mcu_l, mcu_cb, mcu_cr]);
    end
end

%Change image_stream from vector of strings to vector of chars
image_stream=char(strjoin(image_stream));
image_stream(image_stream==' ')=[];

% byte alignment
if mod(length(image_stream),8) ~=0
    alignment=num2str(ones(1,8-mod(length(image_stream),8)));
    alignment(alignment==' ')=[];
    image_stream= [image_stream,alignment];
end


%convert binary to unsigned 8bit
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




