%Description: 
% Chroma subsampling method. This is not part of the standard, but they
% recommend to take average of two neighboring values. However, there
% should be a better subsampling method than simply averaging.
%Input: single chroma channel image to be subsampled, and target size it needs to reduce to  
%Output: single subsampled chroma channel image
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function down_sampled_image=chroma_sampling(image,target_image_size)
[org_height, org_width]=size(image);
target_height=target_image_size(1,1);
target_width =target_image_size(1,2);
image=double(image);
down_sampled_image=zeros(target_height,target_width);
h_min= round(org_width/target_width);
v_min= round(org_height/target_height);

for i1=1:target_height
    for j1=1:target_width
        i1_limit_1=i1+(v_min-1)*(i1-1);
        i1_limit_2=i1+(v_min-1)*(i1-1)+v_min-1;
        j1_limit_1=j1+(h_min-1)*(j1-1);
        j1_limit_2=j1+(h_min-1)*(j1-1)+h_min-1;
        if i1_limit_2 <= org_height &&j1_limit_2 <=org_width
            down_sampled_image(i1,j1)=round(mean(reshape(image(i1_limit_1:i1_limit_2,j1_limit_1:j1_limit_2),1,[])));
        elseif i1_limit_2 > org_height && j1_limit_2 <=org_width
            down_sampled_image(i1,j1)=round(mean(reshape(image(i1_limit_1,j1_limit_1:j1_limit_2),1,[])));
        elseif i1_limit_2 <= org_height && j1_limit_2 > org_width
            down_sampled_image(i1,j1)=round(mean(reshape(image(i1_limit_1:i1_limit_2,j1_limit_1),1,[])));
        elseif i1_limit_2 > org_height && j1_limit_2 > org_width
              down_sampled_image(i1,j1)=image(i1,j1);
        end
    end
end
